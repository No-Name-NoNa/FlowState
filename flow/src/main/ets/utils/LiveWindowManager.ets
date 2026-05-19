import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_DOMAIN = 0x0001;
const TAG = 'LiveWindowManager';

export class LiveWindowManager {
  private static isActive: boolean = false;
  private static currentTaskName: string = '';
  private static remainingTime: number = 0;

  static async startLiveWindow(taskName: string, durationMinutes: number): Promise<void> {
    try {
      LiveWindowManager.currentTaskName = taskName;
      LiveWindowManager.remainingTime = durationMinutes * 60;
      LiveWindowManager.isActive = true;
      hilog.info(LOG_DOMAIN, TAG, 'Focus live state started: %{public}s', taskName);
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to start focus live state: %{public}s', JSON.stringify(err));
    }
  }

  static async updateLiveWindow(remainingSeconds: number): Promise<void> {
    if (!LiveWindowManager.isActive) return;

    try {
      LiveWindowManager.remainingTime = remainingSeconds;
      hilog.info(LOG_DOMAIN, TAG, 'Focus live state updated: %{public}d seconds remaining', remainingSeconds);
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to update focus live state: %{public}s', JSON.stringify(err));
    }
  }

  static async stopLiveWindow(): Promise<void> {
    if (!LiveWindowManager.isActive) return;

    try {
      LiveWindowManager.isActive = false;
      LiveWindowManager.currentTaskName = '';
      LiveWindowManager.remainingTime = 0;
      hilog.info(LOG_DOMAIN, TAG, 'Focus live state stopped');
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to stop focus live state: %{public}s', JSON.stringify(err));
    }
  }

  static isLiveWindowActive(): boolean {
    return LiveWindowManager.isActive;
  }

  static getCurrentTaskInfo(): { taskName: string, remainingTime: number } {
    return {
      taskName: LiveWindowManager.currentTaskName,
      remainingTime: LiveWindowManager.remainingTime
    };
  }
}
