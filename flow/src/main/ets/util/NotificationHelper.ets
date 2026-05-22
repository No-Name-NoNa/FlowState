/**
 * NotificationHelper.ets
 * 通知发送与调度的静态工具类。
 *
 * 功能：
 *  1. publishTaskDone(task, globalMsg)     — 任务计时完成时发即时通知，附带 WantAgent 与归档操作按钮
 *  2. scheduleDeadlineReminder(task)       — 为有截止时间的任务计划截止提醒（setTimeout + notificationManager）
 *  3. scheduleStartReminder(task)          — 为区间任务的开始时间计划开始提醒（setTimeout + notificationManager）
 *  4. cancelReminder(reminderId)           — 取消已计划的提醒定时器
 *  5. cancelAllReminders()                 — 取消全部提醒定时器并清理遗留的代理提醒
 *
 * 提醒类型映射（TaskReminderType → 通知频道）：
 *  NONE  → 不发送任何通知
 *  POPUP → 静默通知（CONTENT_INFORMATION 频道，无声音）
 *  SOUND → 带音效通知（SOCIAL_COMMUNICATION 频道，有声音）
 *
 * 提醒 ID 约定（reminderId 字段语义）：
 *  截止提醒已计划 → reminderId = task.id（非零即表示已计划）
 *  开始提醒已计划 → startReminderId = task.id + 1000000（偏移量区分两类提醒）
 *  0 → 未计划
 *
 * 注意：此方案使用内存定时器，应用存活时可靠触发；
 *       应用被系统彻底杀死后定时器失效，重新打开应用将重新调度。
 */
import { notificationManager } from '@kit.NotificationKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  KEY_APP_LANGUAGE, LANG_ZH_CN, LOG_DOMAIN,
} from '../constants/AppConstants';
import {
  getNextDeadline,
  getStartTime,
  TaskEntry,
  TaskReminderType,
  TaskScheduleType,
  TaskStatus,
} from '../model/TaskEntry';
import { PreferencesHelper } from '../util/PreferencesHelper';

/** 应用包名，用于 WantAgent 与 reminderAgentManager 的配置 */
const BUNDLE_NAME: string = 'moe.gensoukyo.flowmark';
/** 应用主 Ability 名称 */
const ABILITY_NAME: string = 'FlowAbility';
/** 通知日志标签 */
const TAG: string = 'NotificationHelper';
/** 点击任务完成通知后跳转的任务列表 Tab 索引 */
const TASK_TAB_INDEX: number = 1;
/** 归档操作 WantAgent 的请求码偏移量（避免与主 WantAgent 冲突） */
const ARCHIVE_REQUEST_CODE_OFFSET: number = 10000;

export class NotificationHelper {
  /**
   * 截止提醒定时器 Map：taskId → setTimeout 句柄
   * 与 startTimers 分开存储，避免 ID 冲突。
   */
  private static deadlineTimers: Map<number, number> = new Map<number, number>();
  /**
   * 开始提醒定时器 Map：taskId → setTimeout 句柄
   */
  private static startTimers: Map<number, number> = new Map<number, number>();
  /**
   * 错过提醒的补发容忍窗口（毫秒）。
   * 若提醒触发时刻在此窗口内刚刚过去（如应用刚冷启动），则立即补发通知；
   * 超出此窗口的过期提醒则直接跳过，不再打扰用户。
   */
  private static readonly MISSED_WINDOW_MS: number = 5 * 60 * 1000;

  /**
   * 任务计时完成时发即时系统通知。
   * 根据任务的 reminderType 选择对应频道：
   *  - NONE  → 跳过
   *  - POPUP → 静默通知（CONTENT_INFORMATION）
   *  - SOUND → 带音效通知（SOCIAL_COMMUNICATION）
   * 通知携带 WantAgent：点击正文跳转任务列表页；展开后可点击「归档」操作按钮。
   *
   * @param task      已完成的任务条目
   * @param globalMsg 全局默认通知消息文字（任务未配置 reminderMessage 时用作兜底）
   */
  static async publishTaskDone(task: TaskEntry, globalMsg: string): Promise<void> {
    if (task.reminderType === TaskReminderType.NONE) {
      return;
    }

    // 消息文字：任务自定义 > 全局兜底 > 「标题 已完成」
    const msgText: string = task.reminderMessage !== ''
      ? task.reminderMessage
      : (globalMsg !== '' ? globalMsg : (task.title + ' 已完成'));

    // 根据提醒类型选择频道
    let slotType: notificationManager.SlotType = notificationManager.SlotType.SOCIAL_COMMUNICATION;
    if (task.reminderType === TaskReminderType.POPUP) {
      slotType = notificationManager.SlotType.CONTENT_INFORMATION;
    }

    // 构建点击通知正文时跳转到任务列表 Tab 的 WantAgent
    let tapWantAgent: WantAgent | null = null;
    try {
      tapWantAgent = await wantAgent.getWantAgent({
        wants: [{
          bundleName: BUNDLE_NAME,
          abilityName: ABILITY_NAME,
          parameters: { notifyTabIndex: TASK_TAB_INDEX },
        }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: task.id,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      });
    } catch (err) {
      hilog.warn(LOG_DOMAIN, TAG, '创建点击跳转 WantAgent 失败（taskId=%{public}d）：%{public}s',
        task.id, JSON.stringify(err));
    }

    // 构建「归档」操作按钮的 WantAgent
    let archiveWantAgent: WantAgent | null = null;
    try {
      archiveWantAgent = await wantAgent.getWantAgent({
        wants: [{
          bundleName: BUNDLE_NAME,
          abilityName: ABILITY_NAME,
          parameters: { archiveTaskId: task.id },
        }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: task.id + ARCHIVE_REQUEST_CODE_OFFSET,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      });
    } catch (err) {
      hilog.warn(LOG_DOMAIN, TAG, '创建归档 WantAgent 失败（taskId=%{public}d）：%{public}s',
        task.id, JSON.stringify(err));
    }

    // 根据当前语言设置操作按钮文字
    const currentLang: string = AppStorage.get<string>(KEY_APP_LANGUAGE) ?? LANG_ZH_CN;
    const archiveBtnTitle: string = currentLang.startsWith('zh') ? '归档' : 'Archive';

    // 组装通知请求
    const request: notificationManager.NotificationRequest = {
      id: task.id,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: task.title,
          text: msgText,
        },
      },
      notificationSlotType: slotType,
    };

    // 注入 WantAgent（若创建成功）
    if (tapWantAgent !== null) {
      request.wantAgent = tapWantAgent;
    }

    // 注入归档操作按钮（若 WantAgent 创建成功）
    if (archiveWantAgent !== null) {
      request.actionButtons = [{
        title: archiveBtnTitle,
        wantAgent: archiveWantAgent,
      }];
    }

    notificationManager.publish(request).catch((err: Error) => {
      hilog.error(LOG_DOMAIN, TAG, '发送即时通知失败（taskId=%{public}d）：%{public}s',
        task.id, JSON.stringify(err));
    });
  }

  /**
   * 为有截止时间的任务计划截止提醒。
   * 通过 setTimeout + notificationManager.publish() 实现，与 publishTaskDone 使用相同的通知机制。
   * 触发时刻 = 任务截止时间戳 - reminderOffset 分钟。
   * 若触发时刻已过（超出 MISSED_WINDOW_MS 容忍窗口）或任务无截止时间，返回 0（不计划）。
   * 5 分钟内刚刚错过的提醒会立即补发。
   *
   * @param task 任务条目
   * @returns Promise<number> task.id（非零表示已成功计划）；0 表示未计划
   */
  static async scheduleDeadlineReminder(task: TaskEntry): Promise<number> {
    if (task.reminderType === TaskReminderType.NONE) {
      hilog.debug(LOG_DOMAIN, TAG, '跳过截止提醒：类型为 NONE（taskId=%{public}d）', task.id);
      return 0;
    }
    if (task.status === TaskStatus.COMPLETED || task.status === TaskStatus.ARCHIVED) {
      hilog.debug(LOG_DOMAIN, TAG, '跳过截止提醒：任务已完成/归档（taskId=%{public}d）', task.id);
      return 0;
    }
    const deadlineMs: number = getNextDeadline(task);
    if (deadlineMs === 0) {
      hilog.debug(LOG_DOMAIN, TAG, '跳过截止提醒：无截止时间（taskId=%{public}d）', task.id);
      return 0;
    }

    const triggerMs: number = deadlineMs - task.reminderOffset * 60000;
    const delay: number = triggerMs - Date.now();

    // 清除同任务的旧截止定时器
    const oldHandle: number | undefined = NotificationHelper.deadlineTimers.get(task.id);
    if (oldHandle !== undefined) {
      clearTimeout(oldHandle);
    }
    NotificationHelper.deadlineTimers.delete(task.id);

    // 超出容忍窗口的过期提醒直接跳过
    if (delay < -NotificationHelper.MISSED_WINDOW_MS) {
      hilog.warn(LOG_DOMAIN, TAG, '跳过截止提醒：触发时刻已过（taskId=%{public}d, delay=%{public}dms）',
        task.id, delay);
      return 0;
    }

    // delay <= 0 但在容忍窗口内时立即触发（delay > 0 时按正常延迟触发）
    const effectiveDelay: number = delay > 0 ? delay : 0;
    const taskRef: TaskEntry = task;
    const handle: number = setTimeout(() => {
      NotificationHelper.deadlineTimers.delete(taskRef.id);
      NotificationHelper.publishDeadlineNotification(taskRef);
    }, effectiveDelay);
    NotificationHelper.deadlineTimers.set(task.id, handle);

    hilog.info(LOG_DOMAIN, TAG, '截止提醒已计划（taskId=%{public}d, 延迟=%{public}d秒）',
      task.id, Math.ceil(effectiveDelay / 1000));
    // 返回 task.id 作为"提醒 ID"，供 cancelReminder 识别
    return task.id;
  }

  /**
   * 为区间任务的「开始时间」计划开始提醒。
   * 通过 setTimeout + notificationManager.publish() 实现，与 publishTaskDone 使用相同的通知机制。
   * 触发时刻 = 任务开始时间戳（timeNodes[0]）。
   * 若开始时间已过（超出 MISSED_WINDOW_MS 容忍窗口）或 startReminderType 为 NONE，返回 0。
   *
   * @param task 区间任务条目
   * @returns Promise<number> task.id + 1000000（非零表示已成功计划）；0 表示未计划
   */
  static async scheduleStartReminder(task: TaskEntry): Promise<number> {
    if (task.scheduleType !== TaskScheduleType.INTERVAL) {
      return 0;
    }
    if (task.startReminderType === TaskReminderType.NONE) {
      hilog.debug(LOG_DOMAIN, TAG, '跳过开始提醒：类型为 NONE（taskId=%{public}d）', task.id);
      return 0;
    }
    if (task.status === TaskStatus.COMPLETED || task.status === TaskStatus.ARCHIVED) {
      hilog.debug(LOG_DOMAIN, TAG, '跳过开始提醒：任务已完成/归档（taskId=%{public}d）', task.id);
      return 0;
    }
    const startMs: number = getStartTime(task);
    if (startMs === 0) {
      hilog.warn(LOG_DOMAIN, TAG, '跳过开始提醒：无开始时间（taskId=%{public}d）', task.id);
      return 0;
    }

    const delay: number = startMs - Date.now();

    // 清除同任务的旧开始定时器
    const oldHandle: number | undefined = NotificationHelper.startTimers.get(task.id);
    if (oldHandle !== undefined) {
      clearTimeout(oldHandle);
    }
    NotificationHelper.startTimers.delete(task.id);

    // 超出容忍窗口的过期提醒直接跳过
    if (delay < -NotificationHelper.MISSED_WINDOW_MS) {
      hilog.warn(LOG_DOMAIN, TAG, '跳过开始提醒：触发时刻已过（taskId=%{public}d, delay=%{public}dms）',
        task.id, delay);
      return 0;
    }

    const effectiveDelay: number = delay > 0 ? delay : 0;
    const taskRef: TaskEntry = task;
    const handle: number = setTimeout(() => {
      NotificationHelper.startTimers.delete(taskRef.id);
      NotificationHelper.publishStartNotification(taskRef);
    }, effectiveDelay);
    NotificationHelper.startTimers.set(task.id, handle);

    hilog.info(LOG_DOMAIN, TAG, '开始提醒已计划（taskId=%{public}d, 延迟=%{public}d秒）',
      task.id, Math.ceil(effectiveDelay / 1000));
    // 返回 task.id + 1000000 作为"提醒 ID"，cancelReminder 通过偏移量区分截止/开始提醒
    return task.id + 1000000;
  }

  /**
   * 取消已计划的提醒定时器。
   * reminderId = 0 时直接返回；
   * reminderId >= 1000000 视为开始提醒（taskId = reminderId - 1000000）；
   * reminderId < 1000000 视为截止提醒（taskId = reminderId）。
   *
   * @param reminderId 由 scheduleDeadlineReminder 或 scheduleStartReminder 返回的提醒 ID
   */
  static async cancelReminder(reminderId: number): Promise<void> {
    if (reminderId === 0) {
      return;
    }
    if (reminderId >= 1000000) {
      // 开始提醒：startReminderId = taskId + 1000000
      const taskId: number = reminderId - 1000000;
      const handle: number | undefined = NotificationHelper.startTimers.get(taskId);
      if (handle !== undefined) {
        clearTimeout(handle);
        NotificationHelper.startTimers.delete(taskId);
        hilog.info(LOG_DOMAIN, TAG, '开始提醒定时器已取消（taskId=%{public}d）', taskId);
      }
    } else {
      // 截止提醒：reminderId = taskId
      const handle: number | undefined = NotificationHelper.deadlineTimers.get(reminderId);
      if (handle !== undefined) {
        clearTimeout(handle);
        NotificationHelper.deadlineTimers.delete(reminderId);
        hilog.info(LOG_DOMAIN, TAG, '截止提醒定时器已取消（taskId=%{public}d）', reminderId);
      }
    }
  }

  /**
   * 取消全部内存提醒定时器，并清理遗留的 reminderAgentManager 代理提醒（兼容旧版本）。
   * 在 reconcileReminders 重新调度前调用，确保无重复触发。
   */
  static async cancelAllReminders(): Promise<void> {
    // 清除全部截止提醒定时器
    const deadlineCount: number = NotificationHelper.deadlineTimers.size;
    NotificationHelper.deadlineTimers.forEach((handle: number) => {
      clearTimeout(handle);
    });
    NotificationHelper.deadlineTimers.clear();

    // 清除全部开始提醒定时器
    const startCount: number = NotificationHelper.startTimers.size;
    NotificationHelper.startTimers.forEach((handle: number) => {
      clearTimeout(handle);
    });
    NotificationHelper.startTimers.clear();

    hilog.info(LOG_DOMAIN, TAG, '已清除全部内存提醒定时器（%{public}d 个）', deadlineCount + startCount);

    // 清理遗留的 reminderAgentManager 代理提醒（旧版本可能残留）
    try {
      await reminderAgentManager.cancelAllReminders();
      hilog.info(LOG_DOMAIN, TAG, '已清除本应用全部遗留代理提醒');
    } catch (err) {
      hilog.warn(LOG_DOMAIN, TAG, '清除遗留代理提醒失败（可忽略）：%{public}s', JSON.stringify(err));
    }
  }

  /**
   * 发送截止时间到达通知。
   * 实现方式与 publishTaskDone 一致（notificationManager.publish + WantAgent）。
   * notificationId = task.id，避免与开始提醒通知（task.id + 1000000）冲突。
   */
  private static async publishDeadlineNotification(task: TaskEntry): Promise<void> {
    if (task.reminderType === TaskReminderType.NONE) {
      return;
    }

    const globalEndMsg: string = PreferencesHelper.getNotifMessage();
    const currentLang: string = AppStorage.get<string>(KEY_APP_LANGUAGE) ?? LANG_ZH_CN;
    const deadlineSuffix: string = currentLang.startsWith('zh') ? ' 已截止' : ' is now due';
    const msgText: string = task.reminderMessage !== ''
      ? task.reminderMessage
      : (globalEndMsg !== '' ? globalEndMsg : (task.title + deadlineSuffix));

    const slotType: notificationManager.SlotType = task.reminderType === TaskReminderType.POPUP
      ? notificationManager.SlotType.CONTENT_INFORMATION
      : notificationManager.SlotType.SOCIAL_COMMUNICATION;

    let tapWantAgent: WantAgent | null = null;
    try {
      tapWantAgent = await wantAgent.getWantAgent({
        wants: [{
          bundleName: BUNDLE_NAME,
          abilityName: ABILITY_NAME,
          parameters: { notifyTabIndex: TASK_TAB_INDEX },
        }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: task.id,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      });
    } catch (err) {
      hilog.warn(LOG_DOMAIN, TAG, '截止通知 WantAgent 创建失败（taskId=%{public}d）：%{public}s',
        task.id, JSON.stringify(err));
    }

    const request: notificationManager.NotificationRequest = {
      id: task.id,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: task.title,
          text: msgText,
        },
      },
      notificationSlotType: slotType,
    };
    if (tapWantAgent !== null) {
      request.wantAgent = tapWantAgent;
    }

    notificationManager.publish(request).then(() => {
      hilog.info(LOG_DOMAIN, TAG, '截止通知已发送（taskId=%{public}d）', task.id);
    }).catch((err: Error) => {
      hilog.error(LOG_DOMAIN, TAG, '发送截止通知失败（taskId=%{public}d）：%{public}s',
        task.id, JSON.stringify(err));
    });
  }

  /**
   * 发送开始时间到达通知。
   * 实现方式与 publishTaskDone 一致（notificationManager.publish + WantAgent）。
   * notificationId = task.id + 1000000，避免与截止提醒通知（task.id）冲突。
   */
  private static async publishStartNotification(task: TaskEntry): Promise<void> {
    if (task.startReminderType === TaskReminderType.NONE) {
      return;
    }

    const globalStartMsg: string = PreferencesHelper.getNotifStartMessage();
    const currentLang: string = AppStorage.get<string>(KEY_APP_LANGUAGE) ?? LANG_ZH_CN;
    const startedSuffix: string = currentLang.startsWith('zh') ? ' 已开始' : ' has started';
    const msgText: string = task.startReminderMessage !== ''
      ? task.startReminderMessage
      : (globalStartMsg !== '' ? globalStartMsg : (task.title + startedSuffix));

    const slotType: notificationManager.SlotType = task.startReminderType === TaskReminderType.POPUP
      ? notificationManager.SlotType.CONTENT_INFORMATION
      : notificationManager.SlotType.SOCIAL_COMMUNICATION;

    let tapWantAgent: WantAgent | null = null;
    try {
      tapWantAgent = await wantAgent.getWantAgent({
        wants: [{
          bundleName: BUNDLE_NAME,
          abilityName: ABILITY_NAME,
          parameters: { notifyTabIndex: TASK_TAB_INDEX },
        }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: task.id + ARCHIVE_REQUEST_CODE_OFFSET * 2,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      });
    } catch (err) {
      hilog.warn(LOG_DOMAIN, TAG, '开始通知 WantAgent 创建失败（taskId=%{public}d）：%{public}s',
        task.id, JSON.stringify(err));
    }

    const request: notificationManager.NotificationRequest = {
      id: task.id + 1000000,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: task.title,
          text: msgText,
        },
      },
      notificationSlotType: slotType,
    };
    if (tapWantAgent !== null) {
      request.wantAgent = tapWantAgent;
    }

    notificationManager.publish(request).then(() => {
      hilog.info(LOG_DOMAIN, TAG, '开始通知已发送（taskId=%{public}d）', task.id);
    }).catch((err: Error) => {
      hilog.error(LOG_DOMAIN, TAG, '发送开始通知失败（taskId=%{public}d）：%{public}s',
        task.id, JSON.stringify(err));
    });
  }
}
