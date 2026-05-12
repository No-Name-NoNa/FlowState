/**
 * 专注页
 */

import { router } from '@kit.ArkUI';
import { DataManager } from '../utils/DataManager';
import { TimeFormatter } from '../utils/TimeFormatter';
import { FocusSession } from '../models/DataModels';

@Entry
@Component
struct FocusPage {
  @State duration: number = 25;
  @State scheduleId: string = '';
  @State taskId: string = '';
  @State remainingSeconds: number = 0;
  @State isRunning: boolean = false;
  @State isPaused: boolean = false;
  @State isCountdown: boolean = true;
  @State pauseCount: number = 0;
  @State startTime: number = 0;
  @State timerInterval: number = -1;
  @State showCompletionDialog: boolean = false;
  @State reflection: string = '';
  @State currentSessionId: string = '';

  async aboutToAppear() {
    const state = router.getState();
    const params = state.params as Record<string, Object>;

    if (params) {
      this.duration = (params['duration'] as number) || 25;
      this.scheduleId = (params['scheduleId'] as string) || '';
      this.taskId = (params['taskId'] as string) || '';
    }

    this.remainingSeconds = this.duration * 60;
  }

  aboutToDisappear() {
    this.stopTimer();
  }

  startTimer() {
    if (this.isRunning) return;

    this.isRunning = true;
    this.isPaused = false;

    if (!this.startTime) {
      this.startTime = Date.now();
      this.currentSessionId = `focus_${this.startTime}`;
    }

    this.timerInterval = setInterval(() => {
      if (this.isCountdown) {
        this.remainingSeconds--;
        if (this.remainingSeconds <= 0) {
          this.completeSession();
        }
      } else {
        this.remainingSeconds++;
      }
    }, 1000);
  }

  pauseTimer() {
    if (!this.isRunning) return;

    this.isRunning = false;
    this.isPaused = true;
    this.pauseCount++;

    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval);
      this.timerInterval = -1;
    }
  }

  stopTimer() {
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval);
      this.timerInterval = -1;
    }
    this.isRunning = false;
  }

  async completeSession() {
    this.stopTimer();
    if (!this.startTime) {
      this.startTime = Date.now();
      this.currentSessionId = `focus_${this.startTime}`;
    }
    this.showCompletionDialog = true;
  }

  async saveSession(completed: boolean) {
    const start = this.startTime || Date.now();
    const endTime = Date.now();
    const actualDuration = Math.max(0, Math.floor((endTime - start) / 60000));

    const session: FocusSession = {
      id: this.currentSessionId || `focus_${Date.now()}`,
      scheduleId: this.scheduleId || undefined,
      taskId: this.taskId || undefined,
      startTime: start,
      endTime: endTime,
      duration: actualDuration,
      mode: this.isCountdown ? 'pomodoro' : 'continuous',
      completed: completed,
      pauseCount: this.pauseCount,
      reflection: this.reflection
    };

    await DataManager.saveFocusSession(session);
  }

  async handleComplete() {
    await this.saveSession(true);
    router.back();
  }

  async handleCancel() {
    await this.saveSession(false);
    router.back();
  }

  toggleMode() {
    this.isCountdown = !this.isCountdown;
    if (!this.isCountdown) {
      this.remainingSeconds = 0;
    } else {
      this.remainingSeconds = this.duration * 60;
    }
  }

  getModeLabel(): string {
    return this.isCountdown ? '倒计时' : '正计时';
  }

  getPrimaryActionText(): string {
    if (!this.isRunning && !this.isPaused) return '开始';
    if (this.isRunning) return '暂停';
    return '继续';
  }

  getPrimaryActionColor(): string {
    if (this.isRunning) return '#8EA1AE';
    return '#58B7AE';
  }

  getProgressValue(): number {
    if (!this.isCountdown) return Math.min(this.remainingSeconds / 60, 100);
    const total = this.duration * 60;
    if (total <= 0) return 0;
    return Math.max(0, Math.min(100, (total - this.remainingSeconds) * 100 / total));
  }

  handlePrimaryAction() {
    if (!this.isRunning && !this.isPaused) {
      this.startTimer();
    } else if (this.isRunning) {
      this.pauseTimer();
    } else {
      this.startTimer();
    }
  }

  @Builder
  Header() {
    Row() {
      Button() {
        Text('<')
          .fontSize(22)
          .fontColor('#FFFFFF')
      }
      .width(42)
      .height(42)
      .borderRadius(8)
      .backgroundColor('#26323A')
      .onClick(() => {
        if (this.isRunning || this.isPaused) {
          this.handleCancel();
        } else {
          router.back();
        }
      })

      Blank()

      Text(this.getModeLabel())
        .fontSize(13)
        .fontColor('#AAB7BE')
        .padding({ left: 12, right: 12, top: 7, bottom: 7 })
        .backgroundColor('#26323A')
        .borderRadius(8)
        .onClick(() => {
          if (!this.isRunning) {
            this.toggleMode();
          }
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 8 })
  }

  @Builder
  TimerPanel() {
    Column() {
      Text('Focus Session')
        .fontSize(13)
        .fontColor('#9BAAB2')
        .fontWeight(FontWeight.Medium)

      Stack({ alignContent: Alignment.Center }) {
        Progress({ value: this.getProgressValue(), total: 100, type: ProgressType.Ring })
          .width(220)
          .height(220)
          .color('#58B7AE')

        Column() {
          Text(TimeFormatter.formatSeconds(this.remainingSeconds))
            .fontSize(54)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          Text(`${this.duration} 分钟计划`)
            .fontSize(12)
            .fontColor('#AAB7BE')
            .margin({ top: 8 })
        }
      }
      .width(240)
      .height(240)
      .margin({ top: 34, bottom: 34 })

      Button(this.getPrimaryActionText())
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(112)
        .height(112)
        .borderRadius(56)
        .backgroundColor(this.getPrimaryActionColor())
        .onClick(() => {
          this.handlePrimaryAction();
        })

      Row() {
        Button('完成')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#2F6F86')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.completeSession();
          })

        Button('放弃')
          .fontSize(14)
          .fontColor('#AAB7BE')
          .backgroundColor('#26323A')
          .borderRadius(8)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.handleCancel();
          })
      }
      .width('100%')
      .padding({ left: 34, right: 34 })
      .margin({ top: 34 })

      if (this.pauseCount > 0) {
        Text(`已暂停 ${this.pauseCount} 次`)
          .fontSize(12)
          .fontColor('#8EA1AE')
          .margin({ top: 18 })
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  CompletionDialog() {
    if (this.showCompletionDialog) {
      Column() {
        Text('专注完成')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')
          .margin({ bottom: 10 })

        Text(`本次专注 ${TimeFormatter.formatMinutes((Date.now() - this.startTime) / 60000)} 分钟`)
          .fontSize(13)
          .fontColor('#6C7A84')
          .margin({ bottom: 18 })

        TextArea({ placeholder: '记录一点复盘，例如完成了什么、下次怎么开始', text: this.reflection })
          .width('100%')
          .height(116)
          .backgroundColor('#F4F7F8')
          .borderRadius(8)
          .onChange((value: string) => {
            this.reflection = value;
          })

        Button('保存记录')
          .width('100%')
          .height(46)
          .fontColor('#FFFFFF')
          .backgroundColor('#2F6F86')
          .borderRadius(8)
          .margin({ top: 18 })
          .onClick(() => {
            this.handleComplete();
          })
      }
      .width('90%')
      .padding({ left: 20, right: 20, top: 24, bottom: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
    }
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.TimerPanel()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#17212A')

      if (this.showCompletionDialog) {
        Column() {
          this.CompletionDialog()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#17212ACC')
      }
    }
  }
}
