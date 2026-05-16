/**
 * Inbox capture and triage surface.
 */

import { DataManager } from '../utils/DataManager';
import { NavigationManager } from '../utils/NavigationManager';
import { PickerDateTime } from '../utils/PickerDateTime';
import { TimeFormatter } from '../utils/TimeFormatter';
import { Priority, Schedule, Task, TaskStep } from '../models/DataModels';

interface DateOption {
  label: string;
  subLabel: string;
  value: number;
}

interface TimeOption {
  label: string;
  value: string;
}

@Component
export struct InboxPage {
  @State tasks: Task[] = [];
  @State inboxTasks: Task[] = [];
  @State quickTitle: string = '';
  @State selectedPriority: Priority = 'P2';
  @State showTriageSheet: boolean = false;
  @State triageTask: Task | null = null;
  @State triageTitle: string = '';
  @State triageNote: string = '';
  @State triagePriority: Priority = 'P2';
  @State triageDuration: number = 25;
  @State triageDate: number = new Date().setHours(0, 0, 0, 0);
  @State triageTime: string = '09:00';
  @State triageSteps: TaskStep[] = [];
  @State triageNewStepTitle: string = '';
  @State defaultFocusMinutes: number = 25;
  @State lastScheduledTitle: string = '';
  @State lastScheduledMeta: string = '';

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    const settings = await DataManager.getUserSettings();
    this.defaultFocusMinutes = settings.defaultFocusTime || 25;
    this.tasks = await DataManager.getAllTasks();
    this.inboxTasks = [];
    for (let task of this.tasks) {
      task.schedules = await DataManager.getTaskSchedules(task.id);
      if (task.schedules.length === 0) {
        this.inboxTasks.push(task);
      }
    }
    this.inboxTasks.sort((a: Task, b: Task) => b.createdAt - a.createdAt);
  }

  async captureTask() {
    if (!this.quickTitle.trim()) return;
    const task: Task = {
      id: `task_${Date.now()}`,
      title: this.quickTitle.trim(),
      color: 'slate',
      priority: this.selectedPriority,
      schedules: [],
      createdAt: Date.now(),
      updatedAt: Date.now(),
      note: '',
      steps: [],
      isExpanded: false
    };
    await DataManager.saveTask(task);
    this.quickTitle = '';
    this.selectedPriority = 'P2';
    await this.loadData();
  }

  async scheduleTask(task: Task, dayOffset: number) {
    const scheduledDate = this.getScheduledDate(dayOffset);
    const scheduledTime = dayOffset === 0 ? this.getNextTimePoint() : '09:00';
    const schedule: Schedule = {
      id: `schedule_${Date.now()}`,
      taskId: task.id,
      title: task.title,
      estimatedTime: this.getDefaultFocusMinutes(),
      priority: task.priority,
      scheduledDate,
      scheduledTime,
      dueAt: this.buildDueAt(scheduledDate, scheduledTime),
      reminderMinutes: -1,
      createdAt: Date.now(),
      stats: [0, 0, 0, 0, 0, 0],
      changeHistory: [],
      state: 'planned'
    };
    await DataManager.saveSchedule(schedule);
    this.setScheduleFeedback(task.title, scheduledDate, scheduledTime);
    await this.loadData();
  }

  openTriageSheet(task: Task) {
    this.triageTask = task;
    this.triageTitle = task.title;
    this.triageNote = task.note || '';
    this.triagePriority = task.priority;
    this.triageDuration = this.getDefaultFocusMinutes();
    this.triageDate = new Date().setHours(0, 0, 0, 0);
    this.triageTime = this.getNextTimePoint();
    this.triageSteps = this.cloneTaskSteps(task.steps || []);
    this.triageNewStepTitle = '';
    this.showTriageSheet = true;
  }

  closeTriageSheet() {
    this.showTriageSheet = false;
    this.triageTask = null;
    this.triageTitle = '';
    this.triageNote = '';
    this.triagePriority = 'P2';
    this.triageDuration = this.getDefaultFocusMinutes();
    this.triageDate = new Date().setHours(0, 0, 0, 0);
    this.triageTime = '09:00';
    this.triageSteps = [];
    this.triageNewStepTitle = '';
  }

  getSafeTriageDuration(): number {
    if (this.triageDuration < 5) return 5;
    if (this.triageDuration > 240) return 240;
    return this.triageDuration;
  }

  getDefaultFocusMinutes(): number {
    return this.defaultFocusMinutes > 0 ? this.defaultFocusMinutes : 25;
  }

  setTriageDuration(value: string) {
    const parsed = parseInt(value);
    if (!isNaN(parsed)) {
      this.triageDuration = parsed;
    }
  }

  adjustTriageDuration(delta: number) {
    const next = this.getSafeTriageDuration() + delta;
    if (next < 5) {
      this.triageDuration = 5;
    } else if (next > 240) {
      this.triageDuration = 240;
    } else {
      this.triageDuration = next;
    }
  }

  cloneTaskSteps(steps: TaskStep[]): TaskStep[] {
    const next: TaskStep[] = [];
    for (let step of steps) {
      next.push({
        id: step.id,
        title: step.title,
        completed: step.completed,
        createdAt: step.createdAt
      });
    }
    return next;
  }

  getTriageStepSummary(): string {
    if (this.triageSteps.length === 0) return '0/0';
    let completed = 0;
    for (let step of this.triageSteps) {
      if (step.completed) {
        completed++;
      }
    }
    return `${completed}/${this.triageSteps.length}`;
  }

  addTriageStep() {
    const title = this.triageNewStepTitle.trim();
    if (title.length === 0) return;
    const next = this.cloneTaskSteps(this.triageSteps);
    next.push({
      id: `step_${Date.now()}`,
      title,
      completed: false,
      createdAt: Date.now()
    });
    this.triageSteps = next;
    this.triageNewStepTitle = '';
  }

  toggleTriageStep(stepId: string) {
    const next: TaskStep[] = [];
    for (let step of this.triageSteps) {
      next.push({
        id: step.id,
        title: step.title,
        completed: step.id === stepId ? !step.completed : step.completed,
        createdAt: step.createdAt
      });
    }
    this.triageSteps = next;
  }

  deleteTriageStep(stepId: string) {
    const next: TaskStep[] = [];
    for (let step of this.triageSteps) {
      if (step.id !== stepId) {
        next.push(step);
      }
    }
    this.triageSteps = next;
  }

  async saveTriageTaskOnly() {
    if (!this.triageTask || !this.triageTitle.trim()) return;
    const updated: Task = {
      id: this.triageTask.id,
      title: this.triageTitle.trim(),
      color: this.triageTask.color,
      priority: this.triagePriority,
      schedules: this.triageTask.schedules,
      createdAt: this.triageTask.createdAt,
      updatedAt: Date.now(),
      note: this.triageNote,
      steps: this.cloneTaskSteps(this.triageSteps),
      isExpanded: this.triageTask.isExpanded
    };
    await DataManager.saveTask(updated);
    this.triageTask = updated;
    await this.loadData();
  }

  async scheduleTriageTask() {
    if (!this.triageTask || !this.triageTitle.trim()) return;
    await this.saveTriageTaskOnly();
    if (!this.triageTask) return;

    const schedule: Schedule = {
      id: `schedule_${Date.now()}`,
      taskId: this.triageTask.id,
      title: this.triageTitle.trim(),
      estimatedTime: this.getSafeTriageDuration(),
      priority: this.triagePriority,
      scheduledDate: this.triageDate,
      scheduledTime: this.triageTime,
      dueAt: this.buildDueAt(this.triageDate, this.triageTime),
      reminderMinutes: -1,
      createdAt: Date.now(),
      stats: [0, 0, 0, 0, 0, 0],
      changeHistory: [],
      state: 'planned'
    };
    await DataManager.saveSchedule(schedule);
    this.setScheduleFeedback(schedule.title, schedule.scheduledDate || this.triageDate, schedule.scheduledTime || this.triageTime);
    this.closeTriageSheet();
    await this.loadData();
  }

  async deleteTriageTask() {
    if (!this.triageTask) return;
    await DataManager.deleteTask(this.triageTask.id);
    const schedules = await DataManager.getTaskSchedules(this.triageTask.id);
    for (let schedule of schedules) {
      await DataManager.deleteSchedule(schedule.id);
    }
    this.closeTriageSheet();
    await this.loadData();
  }

  getScheduledDate(dayOffset: number): number {
    const date = new Date();
    date.setHours(0, 0, 0, 0);
    date.setDate(date.getDate() + dayOffset);
    return date.getTime();
  }

  getNextTimePoint(): string {
    const now = new Date();
    let hour = now.getHours() + 1;
    if (hour < 9) hour = 9;
    if (hour > 21) hour = 21;
    return `${String(hour).padStart(2, '0')}:00`;
  }

  buildDueAt(date: number, time: string): number {
    const parts = time.split(':');
    const hour = parseInt(parts[0]) || 0;
    const minute = parseInt(parts[1]) || 0;
    const due = new Date(date);
    due.setHours(hour, minute, 0, 0);
    return due.getTime();
  }

  setScheduleFeedback(title: string, date: number, time: string) {
    this.lastScheduledTitle = title;
    this.lastScheduledMeta = `${this.getScheduleDayLabel(date)} ${time} · 已移入时间线`;
  }

  getScheduleDayLabel(date: number): string {
    if (date === this.getScheduledDate(0)) return '今天';
    if (date === this.getScheduledDate(1)) return '明天';
    return TimeFormatter.formatDate(date);
  }

  navigateTo(url: string) {
    NavigationManager.push(this.getUIContext(), url);
  }

  getDateOptions(): DateOption[] {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const weekDays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const options: DateOption[] = [];
    for (let i = 0; i < 7; i++) {
      const date = new Date(today.getTime() + i * 24 * 60 * 60 * 1000);
      let label = weekDays[date.getDay()];
      if (i === 0) label = '今天';
      if (i === 1) label = '明天';
      options.push({
        label,
        subLabel: `${date.getMonth() + 1}/${date.getDate()}`,
        value: date.getTime()
      });
    }
    return options;
  }

  getTimeOptions(): TimeOption[] {
    return [
      { label: '08:00', value: '08:00' },
      { label: '09:00', value: '09:00' },
      { label: '10:30', value: '10:30' },
      { label: '12:00', value: '12:00' },
      { label: '14:00', value: '14:00' },
      { label: '15:30', value: '15:30' },
      { label: '18:00', value: '18:00' },
      { label: '20:00', value: '20:00' }
    ];
  }

  getPickerStartDate(): Date {
    return PickerDateTime.getStartDate();
  }

  getPickerEndDate(): Date {
    return PickerDateTime.getEndDate();
  }

  getTriageSelectedDate(): Date {
    return PickerDateTime.getSelectedDate(this.triageDate);
  }

  getTriageSelectedTime(): Date {
    return PickerDateTime.getSelectedTime(this.triageDate, this.triageTime);
  }

  applyTriageDate(value: Date) {
    this.triageDate = PickerDateTime.dateFromSelectedDate(value);
  }

  applyTriageTime(value: TimePickerResult) {
    this.triageTime = PickerDateTime.timeFromPickerResult(this.triageTime, value);
  }

  getPriorityColor(priority: Priority): string {
    if (priority === 'P0') return '#D96B5F';
    if (priority === 'P1') return '#D59A45';
    return '#607385';
  }

  getPriorityLabel(priority: Priority): string {
    if (priority === 'P0') return '优先';
    if (priority === 'P1') return '重要';
    return '常规';
  }

  @Builder
  Header() {
    Column() {
      Text('收集')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182126')

      Text('先捕捉，再整理。不要让想法打断当前的时间线。')
        .fontSize(12)
        .fontColor('#62727A')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 8 })
  }

  @Builder
  CapturePanel() {
    Column() {
      TextInput({ placeholder: '输入一个想法、任务或待办', text: this.quickTitle })
        .width('100%')
        .height(48)
        .backgroundColor('#F7F8F6')
        .borderRadius(10)
        .onChange((value: string) => {
          this.quickTitle = value;
        })

      Row() {
        this.CapturePriorityChip('P0')
        this.CapturePriorityChip('P1')
        this.CapturePriorityChip('P2')

        Blank()

        Button(this.quickTitle.trim().length > 0 ? '收集' : '输入后收集')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .height(40)
          .borderRadius(10)
          .backgroundColor(this.quickTitle.trim().length > 0 ? '#256D85' : '#8A969B')
          .onClick(() => {
            this.captureTask();
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
  }

  @Builder
  ScheduleFeedbackBanner() {
    if (this.lastScheduledTitle.length > 0) {
      Column() {
        Row() {
          Text()
            .width(4)
            .height(46)
            .backgroundColor('#46AFA5')
            .borderRadius(2)
            .margin({ right: 12 })

          Column() {
            Text(`已安排：${this.lastScheduledTitle}`)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182126')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.lastScheduledMeta)
              .fontSize(12)
              .fontColor('#62727A')
              .margin({ top: 5 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Button('查看时间线')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .height(38)
            .backgroundColor('#256D85')
            .borderRadius(10)
            .layoutWeight(1)
            .onClick(() => {
              this.navigateTo('pages/TodayPage');
            })

          Button('继续收集')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#256D85')
            .height(38)
            .backgroundColor('#EAF2F5')
            .borderRadius(10)
            .layoutWeight(1)
            .margin({ left: 10 })
            .onClick(() => {
              this.lastScheduledTitle = '';
              this.lastScheduledMeta = '';
            })
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
      .margin({ top: 12 })
    }
  }

  @Builder
  CapturePriorityChip(priority: Priority) {
    Text(this.getPriorityLabel(priority))
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.selectedPriority === priority ? '#FFFFFF' : this.getPriorityColor(priority))
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(this.selectedPriority === priority ? this.getPriorityColor(priority) : '#F0F4F3')
      .borderRadius(8)
      .margin({ right: 8 })
      .onClick(() => {
        this.selectedPriority = priority;
      })
  }

  @Builder
  TriagePriorityChip(priority: Priority) {
    Text(this.getPriorityLabel(priority))
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.triagePriority === priority ? '#FFFFFF' : this.getPriorityColor(priority))
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(this.triagePriority === priority ? this.getPriorityColor(priority) : '#F0F4F3')
      .borderRadius(8)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.triagePriority = priority;
      })
  }

  @Builder
  InboxList() {
    Column() {
      Row() {
        Text('待整理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182126')
          .layoutWeight(1)

        Text(`${this.inboxTasks.length} 个`)
          .fontSize(12)
          .fontColor('#8A7CC3')
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.inboxTasks.length === 0) {
        Column() {
          Text('收集箱是空的')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182126')
          Text('这里仅显示未安排任务。点“今天/明天”后，它会进入时间线，不会继续留在收集箱。')
            .fontSize(12)
            .fontColor('#62727A')
            .lineHeight(18)
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 14, right: 14, top: 22, bottom: 22 })
        .backgroundColor('#F7F8F6')
        .borderRadius(10)
      } else {
        ForEach(this.inboxTasks, (task: Task) => {
          this.InboxItem(task)
        }, (task: Task) => task.id)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
    .margin({ top: 12, bottom: 24 })
  }

  @Builder
  InboxItem(task: Task) {
    Column() {
      Row() {
        Text()
          .width(4)
          .height(44)
          .backgroundColor(this.getPriorityColor(task.priority))
          .borderRadius(2)
          .margin({ right: 12 })

        Column() {
          Text(task.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182126')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`${this.getPriorityLabel(task.priority)} · 等待安排${task.note ? ' · 有备注' : ''}${(task.steps || []).length > 0 ? ` · 子任务 ${this.getTaskStepSummary(task)}` : ''}`)
            .fontSize(11)
            .fontColor('#62727A')
            .margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('整理')
          .fontSize(11)
          .fontColor('#256D85')
          .backgroundColor('#EAF2F5')
          .borderRadius(8)
          .height(32)
          .onClick(() => {
            this.openTriageSheet(task);
          })
      }
      .width('100%')

      Row() {
        Button('今天')
          .fontSize(11)
          .fontColor('#FFFFFF')
          .backgroundColor('#256D85')
          .borderRadius(8)
          .height(30)
          .layoutWeight(1)
          .onClick(() => {
            this.scheduleTask(task, 0);
          })

        Button('明天')
          .fontSize(11)
          .fontColor('#256D85')
          .backgroundColor('#EAF2F5')
          .borderRadius(8)
          .height(30)
          .layoutWeight(1)
          .margin({ left: 8 })
          .onClick(() => {
            this.scheduleTask(task, 1);
          })
      }
      .width('100%')
      .margin({ top: 10, left: 16 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  DateChip(option: DateOption) {
    Column() {
      Text(option.label)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.triageDate === option.value ? '#FFFFFF' : '#182126')
      Text(option.subLabel)
        .fontSize(10)
        .fontColor(this.triageDate === option.value ? '#EAF2F5' : '#62727A')
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
    .width(54)
    .padding({ top: 8, bottom: 8 })
    .backgroundColor(this.triageDate === option.value ? '#256D85' : '#F0F4F3')
    .borderRadius(10)
    .margin({ right: 8, bottom: 8 })
    .onClick(() => {
      this.triageDate = option.value;
    })
  }

  @Builder
  TimeChip(option: TimeOption) {
    Text(option.label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.triageTime === option.value ? '#FFFFFF' : '#182126')
      .padding({ left: 12, right: 12, top: 9, bottom: 9 })
      .backgroundColor(this.triageTime === option.value ? '#256D85' : '#F0F4F3')
      .borderRadius(10)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.triageTime = option.value;
      })
  }

  @Builder
  TriageSheet() {
    Column() {
      Row() {
        Column() {
          Text('整理任务')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182126')
          Text(`编辑任务深度 · 子任务 ${this.getTriageStepSummary()}`)
            .fontSize(12)
            .fontColor('#62727A')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('关闭')
          .fontSize(12)
          .fontColor('#607385')
          .backgroundColor('#F0F4F3')
          .borderRadius(9)
          .height(34)
          .onClick(() => {
            this.closeTriageSheet();
          })
      }
      .width('100%')

      TextInput({ placeholder: '任务标题', text: this.triageTitle })
        .width('100%')
        .height(46)
        .backgroundColor('#F7F8F6')
        .borderRadius(10)
        .margin({ top: 16 })
        .onChange((value: string) => {
          this.triageTitle = value;
        })

      TextArea({ placeholder: '备注、背景、链接或下一步', text: this.triageNote })
        .width('100%')
        .height(72)
        .backgroundColor('#F7F8F6')
        .borderRadius(10)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.triageNote = value;
        })

      Text('优先级')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#182126')
        .margin({ top: 14, bottom: 8 })

      Row() {
        this.TriagePriorityChip('P0')
        this.TriagePriorityChip('P1')
        this.TriagePriorityChip('P2')
      }
      .width('100%')

      Row() {
        Text('子任务')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182126')
          .layoutWeight(1)

        Text(this.getTriageStepSummary())
          .fontSize(12)
          .fontColor('#607385')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#F0F4F3')
          .borderRadius(8)
      }
      .width('100%')
      .margin({ top: 18 })

      if (this.triageSteps.length === 0) {
        Text('还没有子任务。可以把一个大任务拆成 2-5 个可执行步骤。')
          .fontSize(12)
          .fontColor('#8A969B')
          .lineHeight(18)
          .margin({ top: 8 })
      } else {
        ForEach(this.triageSteps, (step: TaskStep) => {
          this.TriageStepRow(step)
        }, (step: TaskStep) => step.id)
      }

      Row() {
        TextInput({ placeholder: '添加一个子任务', text: this.triageNewStepTitle })
          .height(40)
          .layoutWeight(1)
          .backgroundColor('#F7F8F6')
          .borderRadius(10)
          .onChange((value: string) => {
            this.triageNewStepTitle = value;
          })

        Button('添加')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .width(66)
          .height(40)
          .backgroundColor(this.triageNewStepTitle.trim().length > 0 ? '#256D85' : '#A8B2B6')
          .borderRadius(10)
          .margin({ left: 10 })
          .onClick(() => {
            this.addTriageStep();
          })
      }
      .width('100%')
      .margin({ top: 10 })

      Row() {
        Text('时长')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#182126')
          .layoutWeight(1)

        Button('-10')
          .fontSize(12)
          .fontColor('#256D85')
          .backgroundColor('#EAF2F5')
          .borderRadius(8)
          .height(34)
          .onClick(() => {
            this.adjustTriageDuration(-10);
          })

        TextInput({ text: this.triageDuration.toString() })
          .type(InputType.Number)
          .width(72)
          .height(34)
          .backgroundColor('#F7F8F6')
          .borderRadius(8)
          .margin({ left: 8, right: 8 })
          .onChange((value: string) => {
            this.setTriageDuration(value);
          })

        Button('+10')
          .fontSize(12)
          .fontColor('#256D85')
          .backgroundColor('#EAF2F5')
          .borderRadius(8)
          .height(34)
          .onClick(() => {
            this.adjustTriageDuration(10);
          })

        Text('分钟')
          .fontSize(12)
          .fontColor('#62727A')
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ top: 8 })

      Text('日期')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#182126')
        .margin({ top: 16, bottom: 8 })

      DatePicker({ start: this.getPickerStartDate(), end: this.getPickerEndDate(), selected: this.getTriageSelectedDate() })
        .width('100%')
        .height(118)
        .backgroundColor('#F7F8F6')
        .borderRadius(10)
        .onDateChange((value: Date) => {
          this.applyTriageDate(value);
        })
      .width('100%')

      Text('结束时间')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#182126')
        .margin({ top: 8, bottom: 8 })

      TimePicker({ selected: this.getTriageSelectedTime(), format: TimePickerFormat.HOUR_MINUTE })
        .width('100%')
        .height(112)
        .backgroundColor('#F7F8F6')
        .borderRadius(10)
        .onChange((value: TimePickerResult) => {
          this.applyTriageTime(value);
        })
      .width('100%')

      Row() {
        Button(this.triageTitle.trim().length > 0 ? '仅保存' : '先填标题')
          .fontSize(12)
          .fontColor(this.triageTitle.trim().length > 0 ? '#256D85' : '#8A969B')
          .backgroundColor(this.triageTitle.trim().length > 0 ? '#EAF2F5' : '#F0F4F3')
          .borderRadius(10)
          .height(40)
          .layoutWeight(1)
          .onClick(() => {
            this.saveTriageTaskOnly();
          })

        Button('删除')
          .fontSize(12)
          .fontColor('#D96B5F')
          .backgroundColor('#F9EAE7')
          .borderRadius(10)
          .height(40)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.deleteTriageTask();
          })
      }
      .width('100%')
      .margin({ top: 12 })

      Button(this.triageTitle.trim().length > 0 ? '安排到时间线' : '先填写标题')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .height(46)
        .width('100%')
        .borderRadius(12)
        .backgroundColor(this.triageTitle.trim().length > 0 ? '#256D85' : '#A8B2B6')
        .margin({ top: 12 })
        .onClick(() => {
          this.scheduleTriageTask();
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 22 })
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
    .shadow({ radius: 24, color: '#18212622', offsetX: 0, offsetY: -8 })
  }

  getTaskStepSummary(task: Task): string {
    const steps = task.steps || [];
    if (steps.length === 0) return '0/0';
    let completed = 0;
    for (let step of steps) {
      if (step.completed) {
        completed++;
      }
    }
    return `${completed}/${steps.length}`;
  }

  @Builder
  TriageStepRow(step: TaskStep) {
    Row() {
      Text(step.completed ? '✓' : '')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(22)
        .height(22)
        .textAlign(TextAlign.Center)
        .backgroundColor(step.completed ? '#46AFA5' : '#DDE5E3')
        .borderRadius(11)
        .margin({ right: 10 })
        .onClick(() => {
          this.toggleTriageStep(step.id);
        })

      Text(step.title)
        .fontSize(13)
        .fontColor(step.completed ? '#8A969B' : '#182126')
        .decoration({ type: step.completed ? TextDecorationType.LineThrough : TextDecorationType.None })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Text('删除')
        .fontSize(11)
        .fontColor('#D96B5F')
        .padding({ left: 8, right: 8, top: 5, bottom: 5 })
        .backgroundColor('#F9EAE7')
        .borderRadius(8)
        .onClick(() => {
          this.deleteTriageStep(step.id);
        })
    }
    .width('100%')
    .padding({ left: 10, right: 8, top: 8, bottom: 8 })
    .backgroundColor('#F7F8F6')
    .borderRadius(10)
    .margin({ top: 8 })
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        Scroll() {
          Column() {
            this.CapturePanel()
            this.ScheduleFeedbackBanner()
            this.InboxList()
          }
          .padding({ left: 16, right: 16, top: 8 })
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8F6')

      if (this.showTriageSheet) {
        Column() {
          Blank()
          this.TriageSheet()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#18212666')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8F6')
  }
}

@Entry
@Component
struct InboxPageEntry {
  build() {
    Column() {
      InboxPage()
    }
    .width('100%')
    .height('100%')
  }
}
