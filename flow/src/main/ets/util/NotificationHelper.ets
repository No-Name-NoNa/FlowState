/**
 * NotificationHelper.ets
 * 通知发送与调度代理提醒的静态工具类。
 *
 * 功能：
 *  1. publishTaskDone(task, globalMsg)  — 任务计时完成时发即时通知，附带 WantAgent 与归档操作按钮
 *  2. scheduleDeadlineReminder(task)    — 为有截止时间的任务注册后台提醒代理
 *  3. cancelReminder(reminderId)        — 取消已注册的提醒代理
 *
 * 提醒类型映射（TaskReminderType）：
 *  NONE  → 不发送任何通知
 *  POPUP → 静默通知（CONTENT_INFORMATION 频道，无声音）
 *  SOUND → 带音效通知（SOCIAL_COMMUNICATION 频道）
 */
import { notificationManager } from '@kit.NotificationKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  KEY_APP_LANGUAGE, LANG_ZH_CN, LOG_DOMAIN,
} from '../constants/AppConstants';
import { getNextDeadline, TaskEntry, TaskReminderType } from '../model/TaskEntry';

/** 应用包名，用于 WantAgent 与 reminderAgentManager 的配置 */
const BUNDLE_NAME: string = 'moe.gensoukyo.flowmark';
/** 应用主 Ability 名称 */
const ABILITY_NAME: string = 'FlowAbility';
/** 通知日志标签 */
const TAG: string = 'NotificationHelper';
/** 点击通知后跳转的历史 Tab 索引 */
const HISTORY_TAB_INDEX: number = 2;
/** 归档操作 WantAgent 的请求码偏移量（避免与主 WantAgent 冲突） */
const ARCHIVE_REQUEST_CODE_OFFSET: number = 10000;

export class NotificationHelper {
  /**
   * 任务计时完成时发即时系统通知。
   * 根据任务的 reminderType 选择对应频道：
   *  - NONE  → 跳过
   *  - POPUP → 静默通知（CONTENT_INFORMATION）
   *  - SOUND → 带音效通知（SOCIAL_COMMUNICATION）
   * 通知携带 WantAgent：点击正文跳转历史页；展开后可点击「归档」操作按钮。
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

    // 构建点击通知正文时跳转到历史 Tab 的 WantAgent
    let tapWantAgent: WantAgent | null = null;
    try {
      tapWantAgent = await wantAgent.getWantAgent({
        wants: [{
          bundleName: BUNDLE_NAME,
          abilityName: ABILITY_NAME,
          parameters: { notifyTabIndex: HISTORY_TAB_INDEX },
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
   * 为有截止时间的任务注册 reminderAgentManager 后台提醒。
   * 触发时刻 = 任务截止时间戳 - reminderOffset 分钟。
   * 若触发时刻已过或任务无截止时间，返回 0（不注册）。
   *
   * @param task 任务条目（需有截止时间且 reminderType != NONE）
   * @returns Promise<number> 系统分配的 reminderId；0 表示未注册
   */
  static async scheduleDeadlineReminder(task: TaskEntry): Promise<number> {
    if (task.reminderType === TaskReminderType.NONE) {
      return 0;
    }
    const deadlineMs: number = getNextDeadline(task);
    if (deadlineMs === 0) {
      return 0;
    }

    // 提前提醒时刻（ms）
    const triggerMs: number = deadlineMs - task.reminderOffset * 60000;
    if (triggerMs <= Date.now()) {
      // 触发时刻已在过去，不注册
      return 0;
    }

    // 将 ms 时间戳转为本地日历时间
    const triggerDate: Date = new Date(triggerMs);
    const localDateTime: reminderAgentManager.LocalDateTime = {
      year: triggerDate.getFullYear(),
      month: triggerDate.getMonth() + 1,
      day: triggerDate.getDate(),
      hour: triggerDate.getHours(),
      minute: triggerDate.getMinutes(),
      second: triggerDate.getSeconds(),
    };

    // 消息文字
    const msgText: string = task.reminderMessage !== '' ? task.reminderMessage : task.title;

    const reminderReq: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: localDateTime,
      title: task.title,
      content: msgText,
      ringDuration: 5,
      tapDismissed: true,
      wantAgent: {
        pkgName: BUNDLE_NAME,
        abilityName: ABILITY_NAME,
      },
      actionButton: [
        {
          title: '关闭',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
        },
      ],
    };

    try {
      const reminderId: number = await reminderAgentManager.publishReminder(reminderReq);
      hilog.info(LOG_DOMAIN, TAG, '截止提醒注册成功（taskId=%{public}d, reminderId=%{public}d）',
        task.id, reminderId);
      return reminderId;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, '注册截止提醒失败（taskId=%{public}d）：%{public}s',
        task.id, JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 取消已注册的 reminderAgentManager 提醒。
   * reminderId = 0 时直接返回，不执行取消操作。
   *
   * @param reminderId 由 scheduleDeadlineReminder 返回的提醒 ID
   */
  static async cancelReminder(reminderId: number): Promise<void> {
    if (reminderId === 0) {
      return;
    }
    try {
      await reminderAgentManager.cancelReminder(reminderId);
      hilog.info(LOG_DOMAIN, TAG, '提醒已取消（reminderId=%{public}d）', reminderId);
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, '取消提醒失败（reminderId=%{public}d）：%{public}s',
        reminderId, JSON.stringify(err));
    }
  }
}
