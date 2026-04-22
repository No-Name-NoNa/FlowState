/**
 * Live Window 管理器
 * 用于管理鸿蒙系统级实况窗功能
 * 注意：实际实现需要配置 module.json5 中的 extensionAbilities
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_DOMAIN = 0x0001;
const TAG = 'LiveWindowManager';

export class LiveWindowManager {
  private static isActive: boolean = false;
  private static currentTaskName: string = '';
  private static remainingTime: number = 0;

  /**
   * 启动实况窗
   * 注意：HarmonyOS 6.0 的 Live Window API 需要在 module.json5 中配置
   * 这里提供基础实现框架
   */
  static async startLiveWindow(taskName: string, durationMinutes: number): Promise<void> {
    try {
      LiveWindowManager.currentTaskName = taskName;
      LiveWindowManager.remainingTime = durationMinutes * 60;
      LiveWindowManager.isActive = true;

      hilog.info(LOG_DOMAIN, TAG, 'Live Window started for task: %{public}s', taskName);

      // TODO: 实际实现需要调用 HarmonyOS Live Window API
      // 示例代码框架：
      // 1. 创建 Live Window ExtensionAbility
      // 2. 发送数据到 Live Window
      // 3. 更新 Live Window 显示内容

      // 这里提供基础的实现思路：
      // import { Want } from '@kit.AbilityKit';
      // const want: Want = {
      //   bundleName: 'com.flowstate.app',
      //   abilityName: 'LiveWindowExtensionAbility',
      //   parameters: {
      //     taskName: taskName,
      //     duration: durationMinutes
      //   }
      // };
      // await context.startAbility(want);

    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to start Live Window: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 更新实况窗内容
   */
  static async updateLiveWindow(remainingSeconds: number): Promise<void> {
    if (!LiveWindowManager.isActive) return;

    try {
      LiveWindowManager.remainingTime = remainingSeconds;

      // TODO: 更新 Live Window 显示
      // 发送更新事件到 Live Window Extension

      hilog.info(LOG_DOMAIN, TAG, 'Live Window updated: %{public}d seconds remaining', remainingSeconds);

    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to update Live Window: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 停止实况窗
   */
  static async stopLiveWindow(): Promise<void> {
    if (!LiveWindowManager.isActive) return;

    try {
      LiveWindowManager.isActive = false;
      LiveWindowManager.currentTaskName = '';
      LiveWindowManager.remainingTime = 0;

      // TODO: 关闭 Live Window
      // 发送停止事件到 Live Window Extension

      hilog.info(LOG_DOMAIN, TAG, 'Live Window stopped');

    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to stop Live Window: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 检查实况窗是否活跃
   */
  static isLiveWindowActive(): boolean {
    return LiveWindowManager.isActive;
  }

  /**
   * 获取当前任务信息
   */
  static getCurrentTaskInfo(): { taskName: string, remainingTime: number } {
    return {
      taskName: LiveWindowManager.currentTaskName,
      remainingTime: LiveWindowManager.remainingTime
    };
  }
}

/**
 * 实况窗扩展能力
 *
 * 使用方法：
 * 1. 在 module.json5 中添加 extensionAbilities 配置：
 *
 * "extensionAbilities": [
 *   {
 *     "name": "LiveWindowExtension",
 *     "srcEntry": "./ets/livewindow/LiveWindowExtension.ets",
 *     "type": "liveView",
 *     "exported": true
 *   }
 * ]
 *
 * 2. 创建 LiveWindowExtension.ets 实现实况窗UI
 *
 * 3. 在 FocusPage 中调用：
 *    - 开始专注时：LiveWindowManager.startLiveWindow(taskName, duration)
 *    - 更新倒计时：LiveWindowManager.updateLiveWindow(remainingSeconds)
 *    - 结束专注时：LiveWindowManager.stopLiveWindow()
 */

/**
 * 注意事项：
 * - Live Window 是 HarmonyOS 系统级特性，需要正确配置权限
 * - 实况窗会在锁屏界面和负一屏显示
 * - 需要保证后台任务不被系统杀死
 * - 建议配合 BackgroundTaskManager 使用
 */
