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
  @State duration: number = 25; // 分钟
  @State scheduleId: string = '';
  @State taskId: string = '';
  @State remainingSeconds: number = 0;
  @State isRunning: boolean = false;
  @State isPaused: boolean = false;
  @State isCountdown: boolean = true; // true: 倒计时, false: 正计时
  @State pauseCount: number = 0;
  @State startTime: number = 0;
  @State timerInterval: number = -1;
  @State showCompletionDialog: boolean = false;
  @State reflection: string = '';
  @State currentSessionId: string = '';

  async aboutToAppear() {
    const params = router.getState() as Record<string, Object>;
    if (params) {
      this.duration = params['duration'] as number || 25;
      this.scheduleId = params['scheduleId'] as string || '';
      this.taskId = params['taskId'] as string || '';
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
    this.showCompletionDialog = true;
  }

  async saveSession(completed: boolean) {
    const endTime = Date.now();
    const actualDuration = Math.floor((endTime - this.startTime) / 60000); // 转换为分钟

    const session: FocusSession = {
      id: this.currentSessionId,
      scheduleId: this.scheduleId || undefined,
      taskId: this.taskId || undefined,
      startTime: this.startTime,
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
      this.remainingSeconds = 0; // 正计时从0开始
    } else {
      this.remainingSeconds = this.duration * 60; // 倒计时重置
    }
  }

  @Builder
  TimerDisplay() {
    Column() {
      // 模式切换
      Row() {
        Text(this.isCountdown ? '倒计时模式' : '正计时模式')
          .fontSize($r('app.float.body_font_size'))
          .fontColor($r('app.color.text_secondary'))
          .onClick(() => {
            if (!this.isRunning) {
              this.toggleMode();
            }
          })
      }
      .margin({ bottom: 32 })

      // 时间显示
      Text(TimeFormatter.formatSeconds(this.remainingSeconds))
        .fontSize(72)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary_color'))
        .margin({ top: 60, bottom: 60 })

      // 控制按钮
      Row() {
        if (!this.isRunning && !this.isPaused) {
          Button('开始')
            .fontSize($r('app.float.subtitle_font_size'))
            .width(120)
            .height(120)
            .borderRadius(60)
            .backgroundColor($r('app.color.accent_color'))
            .onClick(() => {
              this.startTimer();
            })
        } else if (this.isRunning) {
          Button('暂停')
            .fontSize($r('app.float.subtitle_font_size'))
            .width(120)
            .height(120)
            .borderRadius(60)
            .backgroundColor($r('app.color.warning_color'))
            .onClick(() => {
              this.pauseTimer();
            })
        } else if (this.isPaused) {
          Button('继续')
            .fontSize($r('app.float.subtitle_font_size'))
            .width(120)
            .height(120)
            .borderRadius(60)
            .backgroundColor($r('app.color.accent_color'))
            .onClick(() => {
              this.startTimer();
            })
        }
      }

      // 次要操作按钮
      Row() {
        if (this.isRunning || this.isPaused) {
          Button('完成')
            .fontSize($r('app.float.body_font_size'))
            .backgroundColor($r('app.color.success_color'))
            .margin({ right: 12 })
            .onClick(() => {
              this.completeSession();
            })

          Button('放弃')
            .fontSize($r('app.float.body_font_size'))
            .backgroundColor($r('app.color.error_color'))
            .onClick(() => {
              this.handleCancel();
            })
        }
      }
      .margin({ top: 32 })

      // 暂停次数
      if (this.pauseCount > 0) {
        Text(`已暂停 ${this.pauseCount} 次`)
          .fontSize($r('app.float.caption_font_size'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  CompletionDialog() {
    if (this.showCompletionDialog) {
      Column() {
        Text('🎉 专注完成')
          .fontSize($r('app.float.title_font_size'))
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 24 })

        Text(`专注时长: ${TimeFormatter.formatMinutes((Date.now() - this.startTime) / 60000)}`)
          .fontSize($r('app.float.subtitle_font_size'))
          .margin({ bottom: 16 })

        Text('记录本次专注心得')
          .fontSize($r('app.float.body_font_size'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 12 })

        TextArea({ placeholder: '写下你的感受...', text: this.reflection })
          .width('100%')
          .height(120)
          .onChange((value: string) => {
            this.reflection = value;
          })

        Button('完成并保存')
          .width('100%')
          .margin({ top: 24 })
          .backgroundColor($r('app.color.primary_color'))
          .onClick(() => {
            this.handleComplete();
          })
      }
      .padding($r('app.float.padding_xl'))
      .backgroundColor($r('app.color.card_color'))
      .borderRadius($r('app.float.card_radius'))
      .width('90%')
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部返回按钮
        Row() {
          Text('←')
            .fontSize(32)
            .fontColor($r('app.color.text_color'))
            .onClick(() => {
              if (this.isRunning || this.isPaused) {
                // 如果正在进行，询问是否放弃
                this.handleCancel();
              } else {
                router.back();
              }
            })
        }
        .width('100%')
        .padding($r('app.float.padding_md'))

        this.TimerDisplay()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_color'))

      // 完成对话框
      if (this.showCompletionDialog) {
        Column() {
          this.CompletionDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000040')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
  }
}
