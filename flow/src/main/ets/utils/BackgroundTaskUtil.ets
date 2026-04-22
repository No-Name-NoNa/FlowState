/**
 * 后台任务管理器
 * 用于保持计时器在后台运行
 */

import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Want, wantAgent } from '@kit.AbilityKit';

const LOG_DOMAIN = 0x0001;
const TAG = 'BackgroundTaskManager';

export class BackgroundTaskUtil {
  private static requestId: number = 0;

  /**
   * 申请长时任务
   * @param context 上下文
   * @param taskType 任务类型
   */
  static async requestLongRunningTask(
    context: Context,
    taskType: backgroundTaskManager.BackgroundMode = backgroundTaskManager.BackgroundMode.TASK_KEEPING
  ): Promise<void> {
    try {
      // 创建 WantAgent 用于通知栏点击
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: context.abilityInfo.bundleName,
            abilityName: 'FlowAbility'
          } as Want
        ],
        requestCode: 0,
        actionType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };

      const agent = await wantAgent.getWantAgent(wantAgentInfo);

      // 申请长时任务
      await backgroundTaskManager.startBackgroundRunning(
        context,
        taskType,
        agent
      );

      hilog.info(LOG_DOMAIN, TAG, 'Long running task requested successfully');

    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to request long running task: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 取消长时任务
   */
  static async cancelLongRunningTask(context: Context): Promise<void> {
    try {
      await backgroundTaskManager.stopBackgroundRunning(context);
      hilog.info(LOG_DOMAIN, TAG, 'Long running task cancelled successfully');
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to cancel long running task: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 申请短时任务
   */
  static requestShortRunningTask(callback: () => void): void {
    try {
      const requestInfo: backgroundTaskManager.DelaySuspendInfo = {
        reason: 'Timer running',
        callback: callback
      };

      this.requestId = backgroundTaskManager.requestSuspendDelay(
        requestInfo.reason,
        requestInfo.callback
      );

      hilog.info(LOG_DOMAIN, TAG, 'Short running task requested: %{public}d', this.requestId);

    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to request short running task: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 取消短时任务
   */
  static cancelShortRunningTask(): void {
    if (this.requestId > 0) {
      try {
        backgroundTaskManager.cancelSuspendDelay(this.requestId);
        hilog.info(LOG_DOMAIN, TAG, 'Short running task cancelled: %{public}d', this.requestId);
        this.requestId = 0;
      } catch (err) {
        hilog.error(LOG_DOMAIN, TAG, 'Failed to cancel short running task: %{public}s', JSON.stringify(err));
      }
    }
  }

  /**
   * 获取剩余时间
   */
  static async getRemainingDelayTime(): Promise<number> {
    try {
      if (this.requestId > 0) {
        const info = await backgroundTaskManager.getRemainingDelayTime(this.requestId);
        return info;
      }
      return 0;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to get remaining delay time: %{public}s', JSON.stringify(err));
      return 0;
    }
  }
}

/**
 * 使用说明：
 *
 * 1. 在 module.json5 中申请后台任务权限：
 *
 * "requestPermissions": [
 *   {
 *     "name": "ohos.permission.KEEP_BACKGROUND_RUNNING"
 *   }
 * ]
 *
 * 2. 在 FocusPage 中使用：
 *
 * async startTimer() {
 *   // 申请长时任务
 *   await BackgroundTaskUtil.requestLongRunningTask(
 *     getContext(this),
 *     backgroundTaskManager.BackgroundMode.TASK_KEEPING
 *   );
 *
 *   // 启动计时器
 *   this.timerInterval = setInterval(() => {
 *     // 计时逻辑
 *   }, 1000);
 * }
 *
 * async stopTimer() {
 *   // 停止计时器
 *   clearInterval(this.timerInterval);
 *
 *   // 取消长时任务
 *   await BackgroundTaskUtil.cancelLongRunningTask(getContext(this));
 * }
 */
