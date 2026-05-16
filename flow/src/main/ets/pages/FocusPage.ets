/**
 * Focus execution surface.
 */

import { DataManager } from '../utils/DataManager';
import { NavigationManager } from '../utils/NavigationManager';
import { TimeFormatter } from '../utils/TimeFormatter';
import { FocusSession, Schedule, ScheduleChange, Task } from '../models/DataModels';

@Entry
@Component
struct FocusPage {
  @State duration: number = 25;
  @State scheduleId: string = '';
  @State taskId: string = '';
  @State focusTitle: string = '专注时间块';
  @State parentTitle: string = 'Flow State';
  @State plannedWindow: string = '按当前计划执行';
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
  @State autoStart: boolean = false;
  @State completionEndTime: number = 0;
  @State completionActualMinutes: number = 0;
  @State nextScheduleId: string = '';
  @State nextScheduleTaskId: string = '';
  @State nextScheduleTitle: string = '';
  @State nextScheduleWindow: string = '';
  @State nextScheduleDuration: number = 0;

  async aboutToAppear() {
    const settings = await DataManager.getUserSettings();
    this.duration = settings.defaultFocusTime || 25;
    const params = NavigationManager.getParams(this.getUIContext());

    if (params) {
      this.duration = (params['duration'] as number) || this.duration;
      this.scheduleId = (params['scheduleId'] as string) || '';
      this.taskId = (params['taskId'] as string) || '';
      this.autoStart = (params['autoStart'] as boolean) || false;
    }

    this.remainingSeconds = this.duration * 60;
    await this.loadLinkedContext();
    if (this.autoStart) {
      this.startTimer();
    }
  }

  aboutToDisappear() {
    this.stopTimer();
  }

  async loadLinkedContext() {
    const schedules = await DataManager.getAllSchedules();
    let currentSchedule: Schedule | null = null;
    if (this.scheduleId) {
      const schedule = schedules.find((item: Schedule) => item.id === this.scheduleId);
      if (schedule) {
        currentSchedule = schedule;
        this.focusTitle = schedule.title;
        this.duration = schedule.estimatedTime;
        this.remainingSeconds = schedule.estimatedTime * 60;
        this.plannedWindow = `${this.getScheduleStartText(schedule)}-${this.getScheduleEndText(schedule)} · ${schedule.estimatedTime} 分钟`;
      }
    }

    if (this.taskId) {
      const task = await DataManager.getTask(this.taskId);
      if (task) {
        this.parentTitle = task.title;
      }
    }

    this.loadNextScheduleContext(schedules, currentSchedule);
  }

  getScheduleDueAt(schedule: Schedule): number {
    if (schedule.dueAt) return schedule.dueAt;
    const date = schedule.scheduledDate || new Date().setHours(0, 0, 0, 0);
    const time = schedule.scheduledTime || '09:00';
    const parts = time.split(':');
    const hour = parseInt(parts[0]) || 0;
    const minute = parseInt(parts[1]) || 0;
    const due = new Date(date);
    due.setHours(hour, minute, 0, 0);
    return due.getTime();
  }

  getScheduleStartText(schedule: Schedule): string {
    return TimeFormatter.formatTime(this.getScheduleDueAt(schedule) - schedule.estimatedTime * 60 * 1000);
  }

  getScheduleEndText(schedule: Schedule): string {
    return TimeFormatter.formatTime(this.getScheduleDueAt(schedule));
  }

  getScheduleStartAt(schedule: Schedule): number {
    return this.getScheduleDueAt(schedule) - schedule.estimatedTime * 60 * 1000;
  }

  isScheduleActive(schedule: Schedule): boolean {
    return schedule.state !== 'completed' && schedule.state !== 'cancelled' && schedule.state !== 'deferred';
  }

  isToday(timestamp: number): boolean {
    const day = new Date();
    day.setHours(0, 0, 0, 0);
    const start = day.getTime();
    const end = start + 24 * 60 * 60 * 1000;
    return timestamp >= start && timestamp < end;
  }

  findNextSchedule(schedules: Schedule[], currentSchedule: Schedule | null): Schedule | null {
    const threshold = Math.max(Date.now(), currentSchedule ? this.getScheduleDueAt(currentSchedule) : Date.now());
    const active: Schedule[] = [];
    for (let schedule of schedules) {
      if (schedule.id !== this.scheduleId && this.isScheduleActive(schedule) && this.isToday(this.getScheduleDueAt(schedule))) {
        active.push(schedule);
      }
    }
    active.sort((a: Schedule, b: Schedule) => this.getScheduleStartAt(a) - this.getScheduleStartAt(b));
    for (let schedule of active) {
      if (this.getScheduleStartAt(schedule) >= threshold || this.getScheduleDueAt(schedule) >= threshold) {
        return schedule;
      }
    }
    return null;
  }

  loadNextScheduleContext(schedules: Schedule[], currentSchedule: Schedule | null) {
    const next = this.findNextSchedule(schedules, currentSchedule);
    if (!next) {
      this.nextScheduleId = '';
      this.nextScheduleTaskId = '';
      this.nextScheduleTitle = '';
      this.nextScheduleWindow = '';
      this.nextScheduleDuration = 0;
      return;
    }

    this.nextScheduleId = next.id;
    this.nextScheduleTaskId = next.taskId;
    this.nextScheduleTitle = next.title;
    this.nextScheduleWindow = `${this.getScheduleStartText(next)}-${this.getScheduleEndText(next)} · ${next.estimatedTime} 分钟`;
    this.nextScheduleDuration = next.estimatedTime;
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
    this.completionEndTime = Date.now();
    this.completionActualMinutes = Math.max(0, Math.floor((this.completionEndTime - this.startTime) / 60000));
    this.showCompletionDialog = true;
  }

  async saveSession(completed: boolean) {
    const start = this.startTime || Date.now();
    const endTime = this.completionEndTime > 0 ? this.completionEndTime : Date.now();
    const actualDuration = this.completionEndTime > 0 ? this.completionActualMinutes : Math.max(0, Math.floor((endTime - start) / 60000));

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
    if (completed && this.scheduleId) {
      await this.markLinkedScheduleComplete(actualDuration);
    }
  }

  async markLinkedScheduleComplete(actualDuration: number) {
    const schedules = await DataManager.getAllSchedules();
    const schedule = schedules.find((item: Schedule) => item.id === this.scheduleId);
    if (!schedule) return;

    const dueAt = this.getScheduleDueAt(schedule);
    const history: ScheduleChange[] = [];
    for (let item of schedule.changeHistory || []) {
      history.push(item);
    }
    history.push({
      id: `change_${Date.now()}`,
      type: 'complete',
      timestamp: Date.now(),
      note: this.reflection || '专注完成',
      fromDueAt: dueAt,
      toDueAt: dueAt,
      fromDuration: schedule.estimatedTime,
      toDuration: actualDuration
    });

    const updated: Schedule = {
      id: schedule.id,
      taskId: schedule.taskId,
      title: schedule.title,
      estimatedTime: schedule.estimatedTime,
      priority: schedule.priority,
      scheduledDate: schedule.scheduledDate,
      scheduledTime: schedule.scheduledTime,
      dueAt: schedule.dueAt,
      reminderMinutes: schedule.reminderMinutes,
      createdAt: schedule.createdAt,
      stats: schedule.stats,
      changeHistory: history,
      state: 'completed',
      completedAt: Date.now(),
      deferredAt: schedule.deferredAt,
      cancelledAt: schedule.cancelledAt,
      actualMinutes: actualDuration,
      stateNote: this.reflection,
      routineId: schedule.routineId
    };

    await DataManager.saveSchedule(updated);
  }

  async handleComplete() {
    await this.saveSession(true);
    this.navigateToToday();
  }

  async handleCompleteAndStartNext() {
    await this.saveSession(true);
    if (this.nextScheduleId.length === 0) {
      this.navigateToToday();
      return;
    }
    this.navigateToNextFocus();
  }

  navigateToToday() {
    NavigationManager.push(this.getUIContext(), 'pages/TodayPage');
  }

  navigateToNextFocus() {
    NavigationManager.push(this.getUIContext(), 'pages/FocusPage', {
      duration: this.nextScheduleDuration,
      scheduleId: this.nextScheduleId,
      taskId: this.nextScheduleTaskId,
      autoStart: true
    });
  }

  async handleCancel() {
    await this.saveSession(false);
    NavigationManager.back(this.getUIContext());
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
    if (this.isRunning) return '#D59A45';
    if (this.isPaused) return '#46AFA5';
    return '#46AFA5';
  }

  getProgressValue(): number {
    if (!this.isCountdown) return Math.min(this.remainingSeconds / 60, 100);
    const total = this.duration * 60;
    if (total <= 0) return 0;
    return Math.max(0, Math.min(100, (total - this.remainingSeconds) * 100 / total));
  }

  getElapsedSeconds(): number {
    if (!this.isCountdown) return this.remainingSeconds;
    return Math.max(0, this.duration * 60 - this.remainingSeconds);
  }

  getElapsedMinutesText(): string {
    return `${Math.floor(this.getElapsedSeconds() / 60)}m`;
  }

  getCompletionDeltaMinutes(): number {
    return this.completionActualMinutes - this.duration;
  }

  getCompletionDeltaText(): string {
    const delta = this.getCompletionDeltaMinutes();
    if (delta === 0) return '与计划一致';
    if (delta > 0) return `比计划多 ${delta} 分钟`;
    return `比计划少 ${Math.abs(delta)} 分钟`;
  }

  getCompletionDeltaColor(): string {
    const delta = this.getCompletionDeltaMinutes();
    if (delta > 5) return '#D59A45';
    if (delta < -5) return '#8A7CC3';
    return '#46AFA5';
  }

  hasNextSchedule(): boolean {
    return this.nextScheduleId.length > 0;
  }

  getStateText(): string {
    if (this.showCompletionDialog) return '等待复盘';
    if (this.isRunning) return '正在执行';
    if (this.isPaused) return '已暂停';
    return '准备开始';
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
          .fontColor('#EAF2F5')
      }
      .width(42)
      .height(42)
      .borderRadius(10)
      .backgroundColor('#213139')
      .onClick(() => {
        if (this.isRunning || this.isPaused) {
          this.handleCancel();
        } else {
          NavigationManager.back(this.getUIContext());
        }
      })

      Column() {
        Text('Focus')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text(this.getStateText())
          .fontSize(11)
          .fontColor('#9BAAB2')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      Text(this.getModeLabel())
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#BFD4D0')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#213139')
        .borderRadius(10)
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
  ContextCard() {
    Column() {
      Text(this.parentTitle)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#9BAAB2')

      Text(this.focusTitle)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })

      Row() {
        Text(this.plannedWindow)
          .fontSize(12)
          .fontColor('#BFD4D0')
          .layoutWeight(1)

        Text(this.scheduleId ? '来自时间线' : '自由专注')
          .fontSize(11)
          .fontColor('#46AFA5')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#203F3D')
          .borderRadius(9)
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#1B2A31')
    .borderRadius(14)
    .border({ width: 1, color: '#2A3C44' })
    .margin({ left: 20, right: 20, top: 10 })
  }

  @Builder
  TimerPanel() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Progress({ value: 100, total: 100, type: ProgressType.Ring })
          .width(254)
          .height(254)
          .color('#213139')

        Progress({ value: this.getProgressValue(), total: 100, type: ProgressType.Ring })
          .width(254)
          .height(254)
          .color('#46AFA5')

        Column() {
          Text(TimeFormatter.formatSeconds(this.remainingSeconds))
            .fontSize(54)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          Text(this.isCountdown ? '剩余时间' : '已专注')
            .fontSize(12)
            .fontColor('#9BAAB2')
            .margin({ top: 8 })

          Text(`${this.duration} 分钟计划`)
            .fontSize(11)
            .fontColor('#607885')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width(270)
      .height(270)
      .margin({ top: 22, bottom: 20 })

      this.ControlDock()
      this.RhythmStrip()
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ControlDock() {
    Column() {
      Button(this.getPrimaryActionText())
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(116)
        .height(116)
        .borderRadius(58)
        .backgroundColor(this.getPrimaryActionColor())
        .shadow({ radius: 24, color: '#46AFA544', offsetX: 0, offsetY: 10 })
        .onClick(() => {
          this.handlePrimaryAction();
        })

      Row() {
        Button('完成')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .height(42)
          .backgroundColor('#256D85')
          .borderRadius(10)
          .layoutWeight(1)
          .onClick(() => {
            this.completeSession();
          })

        Button('放弃')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#B8C6CB')
          .height(42)
          .backgroundColor('#213139')
          .borderRadius(10)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.handleCancel();
          })
      }
      .width('100%')
      .padding({ left: 34, right: 34 })
      .margin({ top: 28 })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
  }

  @Builder
  RhythmStrip() {
    Row() {
      this.FocusMetric(`${this.duration}m`, '计划')
      this.FocusMetric(this.getElapsedMinutesText(), '已投入')
      this.FocusMetric(`${this.pauseCount}`, '暂停')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    .backgroundColor('#1B2A31')
    .borderRadius(14)
    .border({ width: 1, color: '#2A3C44' })
    .margin({ left: 20, right: 20, top: 24, bottom: 20 })
  }

  @Builder
  FocusMetric(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text(label)
        .fontSize(10)
        .fontColor('#8EA1AE')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  CompletionMetric(value: string, label: string, color: string) {
    Column() {
      Text(value)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(label)
        .fontSize(10)
        .fontColor('#62727A')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  NextBlockPreview() {
    if (this.hasNextSchedule()) {
      Row() {
        Text()
          .width(4)
          .height(46)
          .borderRadius(2)
          .backgroundColor('#46AFA5')
          .margin({ right: 12 })

        Column() {
          Text('下一段')
            .fontSize(11)
            .fontColor('#62727A')

          Text(this.nextScheduleTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182126')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })

          Text(this.nextScheduleWindow)
            .fontSize(11)
            .fontColor('#62727A')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .backgroundColor('#F0F4F3')
      .borderRadius(12)
      .margin({ top: 14 })
    } else {
      Text('今天暂时没有后续时间块，可以回到 Today 检查时间线或结束工作。')
        .fontSize(12)
        .fontColor('#62727A')
        .lineHeight(18)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .backgroundColor('#F0F4F3')
        .borderRadius(12)
        .margin({ top: 14 })
    }
  }

  @Builder
  CompletionDialog() {
    if (this.showCompletionDialog) {
      Column() {
        Text('这段完成了')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182126')
          .margin({ bottom: 8 })

        Text(this.focusTitle)
          .fontSize(13)
          .fontColor('#62727A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 14 })

        Row() {
          this.CompletionMetric(`${this.duration}m`, '计划', '#182126')
          this.CompletionMetric(`${this.completionActualMinutes}m`, '实际', '#46AFA5')
          this.CompletionMetric(this.getCompletionDeltaText(), '偏差', this.getCompletionDeltaColor())
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .backgroundColor('#F7F8F6')
        .borderRadius(12)

        this.NextBlockPreview()

        TextArea({ placeholder: '记录完成了什么，或者下次从哪里继续', text: this.reflection })
          .width('100%')
          .height(96)
          .backgroundColor('#F7F8F6')
          .borderRadius(10)
          .margin({ top: 14 })
          .onChange((value: string) => {
            this.reflection = value;
          })

        Row() {
          Button('回到今天')
            .height(44)
            .fontSize(13)
            .fontColor('#256D85')
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#EAF2F5')
            .borderRadius(12)
            .layoutWeight(1)
            .onClick(() => {
              this.handleComplete();
            })

          Button(this.hasNextSchedule() ? '开始下一段' : '保存完成')
            .height(44)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#256D85')
            .borderRadius(12)
            .layoutWeight(1)
            .margin({ left: 10 })
            .onClick(() => {
              if (this.hasNextSchedule()) {
                this.handleCompleteAndStartNext();
              } else {
                this.handleComplete();
              }
            })
        }
        .width('100%')
          .margin({ top: 18 })
      }
      .width('90%')
      .padding({ left: 20, right: 20, top: 24, bottom: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 24, color: '#00000033', offsetX: 0, offsetY: 12 })
    }
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.ContextCard()
        this.TimerPanel()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#111C22')

      if (this.showCompletionDialog) {
        Column() {
          this.CompletionDialog()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#111C22CC')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#111C22')
  }
}
