/**
 * NotificationHelper.ets
 * 通知发送与调度代理提醒的静态工具类。
 *
 * 功能：
 *  1. publishTaskDone(task, globalMsg)  — 任务计时完成时发即时通知
 *  2. scheduleDeadlineReminder(task)    — 为有截止时间的任务注册后台提醒代理
 *  3. cancelReminder(reminderId)        — 取消已注册的提醒代理
 *
 * 提醒类型映射（TaskReminderType）：
 *  NONE  → 不发送任何通知
 *  POPUP → 静默通知（CONTENT_INFORMATION 频道，无声音）
 *  SOUND → 带音效通知（SOCIAL_COMMUNICATION 频道）
 *  ALARM → 强提醒（SOCIAL_COMMUNICATION 频道 + 长振铃）
 */
import { notificationManager } from '@kit.NotificationKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LOG_DOMAIN } from '../constants/AppConstants';
import { getNextDeadline, TaskEntry, TaskReminderType } from '../model/TaskEntry';

/** 应用包名，用于 reminderAgentManager 的 WantAgent 配置 */
const BUNDLE_NAME: string = 'moe.gensoukyo.flowmark';
/** 应用主 Ability 名称 */
const ABILITY_NAME: string = 'FlowAbility';

/** 通知日志标签 */
const TAG: string = 'NotificationHelper';

export class NotificationHelper {
  /**
   * 任务计时完成时发即时系统通知。
   * 根据任务的 reminderType 选择对应频道：
   *  - NONE  → 跳过
   *  - POPUP → 静默通知（CONTENT_INFORMATION）
   *  - SOUND → 带音效通知（SOCIAL_COMMUNICATION）
   *  - ALARM → 强提醒（SOCIAL_COMMUNICATION，ringDuration 由 reminderAgent 处理，此处同 SOUND）
   *
   * @param task      已完成的任务条目
   * @param globalMsg 全局默认通知消息文字（任务未配置 reminderMessage 时用作兜底）
   */
  static publishTaskDone(task: TaskEntry, globalMsg: string): void {
    if (task.reminderType === TaskReminderType.NONE) {
      return;
    }

    // 消息文字：任务自定义 > 全局兜底 > 空字符串兜底
    const msgText: string = task.reminderMessage !== '' ? task.reminderMessage
      : (globalMsg !== '' ? globalMsg : task.title);

    // 根据提醒类型选择频道
    let slotType: notificationManager.SlotType = notificationManager.SlotType.SOCIAL_COMMUNICATION;
    if (task.reminderType === TaskReminderType.POPUP) {
      slotType = notificationManager.SlotType.CONTENT_INFORMATION;
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

    // ALARM 类型使用较长振铃时长（60 秒）
    const ringDuration: number = task.reminderType === TaskReminderType.ALARM ? 60 : 5;

    const reminderReq: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: localDateTime,
      title: task.title,
      content: msgText,
      ringDuration: ringDuration,
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
