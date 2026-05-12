/**
 * 任务页
 */

import { router } from '@kit.ArkUI';
import { DataManager } from '../utils/DataManager';
import { Task, Schedule, Priority, TaskStep } from '../models/DataModels';

interface DateOption {
  label: string;
  subLabel: string;
  value: number;
}

interface TimeOption {
  label: string;
  value: string;
}

interface ReminderOption {
  label: string;
  value: number;
}

@Entry
@Component
export struct TaskPage {
  @State tasks: Task[] = [];
  @State showAddTask: boolean = false;
  @State showAddSchedule: boolean = false;
  @State selectedTask: Task | null = null;
  @State newTaskTitle: string = '';
  @State newTaskPriority: Priority = 'P2';
  @State newTaskColor: string = 'blue';
  @State newTaskScheduleTitle: string = '';
  @State newTaskScheduleDuration: number = 25;
  @State newTaskScheduleDate: number = new Date().setHours(0, 0, 0, 0);
  @State newTaskScheduleTime: string = '09:00';
  @State newTaskReminderMinutes: number = -1;
  @State newScheduleTitle: string = '';
  @State newScheduleDuration: number = 25;
  @State newScheduleDate: number = new Date().setHours(0, 0, 0, 0);
  @State newScheduleTime: string = '09:00';
  @State newScheduleReminderMinutes: number = -1;
  @State quickTaskTitle: string = '';
  @State showTaskDetail: boolean = false;
  @State detailTask: Task | null = null;
  @State detailTitle: string = '';
  @State detailNote: string = '';
  @State detailPriority: Priority = 'P2';
  @State detailNewStepTitle: string = '';
  @State detailScheduleTitle: string = '';
  @State detailScheduleDuration: number = 25;
  @State detailScheduleDate: number = new Date().setHours(0, 0, 0, 0);
  @State detailScheduleTime: string = '09:00';
  @State detailReminderMinutes: number = -1;

  async aboutToAppear() {
    await this.loadTasks();
  }

  async loadTasks() {
    this.tasks = await DataManager.getAllTasks();
    for (let task of this.tasks) {
      task.schedules = await DataManager.getTaskSchedules(task.id);
      task.schedules.sort((a: Schedule, b: Schedule) => this.getScheduleDueAt(a) - this.getScheduleDueAt(b));
    }
    this.tasks.sort((a: Task, b: Task) => {
      const dueDiff = this.getNearestTaskDue(a) - this.getNearestTaskDue(b);
      if (dueDiff !== 0) return dueDiff;
      return this.getPriorityRank(a.priority) - this.getPriorityRank(b.priority);
    });
  }

  async handleAddTask() {
    if (!this.newTaskTitle.trim()) return;

    const task: Task = {
      id: `task_${Date.now()}`,
      title: this.newTaskTitle,
      color: this.newTaskColor,
      priority: this.newTaskPriority,
      schedules: [],
      createdAt: Date.now(),
      updatedAt: Date.now(),
      note: '',
      steps: [],
      isExpanded: true
    };
    await DataManager.saveTask(task);

    if (this.newTaskScheduleTitle.trim()) {
      const schedule: Schedule = {
        id: `schedule_${Date.now()}`,
        taskId: task.id,
        title: this.newTaskScheduleTitle,
        estimatedTime: this.newTaskScheduleDuration,
        priority: this.newTaskPriority,
        scheduledDate: this.newTaskScheduleDate,
        scheduledTime: this.newTaskScheduleTime,
        dueAt: this.buildDueAt(this.newTaskScheduleDate, this.newTaskScheduleTime),
        reminderMinutes: this.newTaskReminderMinutes,
        createdAt: Date.now(),
        stats: [0, 0, 0, 0, 0, 0]
      };
      await DataManager.saveSchedule(schedule);
    }

    this.resetTaskForm();
    this.showAddTask = false;
    await this.loadTasks();
  }

  async handleAddSchedule() {
    if (!this.newScheduleTitle.trim() || !this.selectedTask) return;

    const schedule: Schedule = {
      id: `schedule_${Date.now()}`,
      taskId: this.selectedTask.id,
      title: this.newScheduleTitle,
      estimatedTime: this.newScheduleDuration,
      priority: this.selectedTask.priority,
      scheduledDate: this.newScheduleDate,
      scheduledTime: this.newScheduleTime,
      dueAt: this.buildDueAt(this.newScheduleDate, this.newScheduleTime),
      reminderMinutes: this.newScheduleReminderMinutes,
      createdAt: Date.now(),
      stats: [0, 0, 0, 0, 0, 0]
    };

    await DataManager.saveSchedule(schedule);
    this.resetScheduleForm();
    this.showAddSchedule = false;
    this.selectedTask = null;
    await this.loadTasks();
  }

  async handleQuickAddTask() {
    if (!this.quickTaskTitle.trim()) return;

    const task: Task = {
      id: `task_${Date.now()}`,
      title: this.quickTaskTitle,
      color: 'gray',
      priority: 'P2',
      schedules: [],
      createdAt: Date.now(),
      updatedAt: Date.now(),
      note: '',
      steps: [],
      isExpanded: false
    };

    await DataManager.saveTask(task);
    this.quickTaskTitle = '';
    await this.loadTasks();
  }

  openTaskDetail(task: Task) {
    this.detailTask = task;
    this.detailTitle = task.title;
    this.detailNote = task.note || '';
    this.detailPriority = task.priority;
    this.detailNewStepTitle = '';
    this.detailScheduleTitle = task.schedules.length === 0 ? task.title : '';
    this.detailScheduleDuration = 25;
    this.detailScheduleDate = new Date().setHours(0, 0, 0, 0);
    this.detailScheduleTime = '09:00';
    this.detailReminderMinutes = -1;
    this.showTaskDetail = true;
  }

  closeTaskDetail() {
    this.showTaskDetail = false;
    this.detailTask = null;
    this.detailTitle = '';
    this.detailNote = '';
    this.detailNewStepTitle = '';
    this.detailScheduleTitle = '';
  }

  async saveTaskDetail() {
    if (!this.detailTask || !this.detailTitle.trim()) return;

    const task: Task = {
      id: this.detailTask.id,
      title: this.detailTitle.trim(),
      color: this.detailTask.color,
      priority: this.detailPriority,
      schedules: this.detailTask.schedules,
      createdAt: this.detailTask.createdAt,
      updatedAt: Date.now(),
      note: this.detailNote,
      steps: this.detailTask.steps || [],
      isExpanded: this.detailTask.isExpanded
    };

    await DataManager.saveTask(task);
    await this.loadTasks();
    this.refreshDetailTask(task.id);
  }

  async saveAndCloseTaskDetail() {
    await this.saveTaskDetail();
    this.closeTaskDetail();
  }

  async handleAddDetailStep() {
    if (!this.detailTask || !this.detailNewStepTitle.trim()) return;

    const steps: TaskStep[] = [];
    for (let step of this.getTaskSteps(this.detailTask)) {
      steps.push(step);
    }
    steps.push({
      id: `step_${Date.now()}`,
      title: this.detailNewStepTitle.trim(),
      completed: false,
      createdAt: Date.now()
    });

    this.detailTask.steps = steps;
    this.detailNewStepTitle = '';
    await this.saveTaskDetail();
  }

  async toggleDetailStep(stepId: string) {
    if (!this.detailTask) return;

    const steps: TaskStep[] = [];
    for (let step of this.getTaskSteps(this.detailTask)) {
      steps.push({
        id: step.id,
        title: step.title,
        completed: step.id === stepId ? !step.completed : step.completed,
        createdAt: step.createdAt
      });
    }

    this.detailTask.steps = steps;
    await this.saveTaskDetail();
  }

  async deleteDetailStep(stepId: string) {
    if (!this.detailTask) return;

    const steps: TaskStep[] = [];
    for (let step of this.getTaskSteps(this.detailTask)) {
      if (step.id !== stepId) steps.push(step);
    }

    this.detailTask.steps = steps;
    await this.saveTaskDetail();
  }

  async handleAddDetailSchedule() {
    if (!this.detailTask) return;
    const title = this.detailScheduleTitle.trim().length > 0 ? this.detailScheduleTitle.trim() : this.detailTitle.trim();
    if (!title) return;

    await this.saveTaskDetail();
    const schedule: Schedule = {
      id: `schedule_${Date.now()}`,
      taskId: this.detailTask.id,
      title,
      estimatedTime: this.detailScheduleDuration,
      priority: this.detailPriority,
      scheduledDate: this.detailScheduleDate,
      scheduledTime: this.detailScheduleTime,
      dueAt: this.buildDueAt(this.detailScheduleDate, this.detailScheduleTime),
      reminderMinutes: this.detailReminderMinutes,
      createdAt: Date.now(),
      stats: [0, 0, 0, 0, 0, 0]
    };

    await DataManager.saveSchedule(schedule);
    this.detailScheduleTitle = '';
    this.detailScheduleDuration = 25;
    await this.loadTasks();
    this.refreshDetailTask(schedule.taskId);
  }

  async handleDeleteTask(taskId: string) {
    await DataManager.deleteTask(taskId);
    const schedules = await DataManager.getTaskSchedules(taskId);
    for (let schedule of schedules) {
      await DataManager.deleteSchedule(schedule.id);
    }
    await this.loadTasks();
  }

  async handleDeleteSchedule(scheduleId: string) {
    await DataManager.deleteSchedule(scheduleId);
    await this.loadTasks();
  }

  resetTaskForm() {
    this.newTaskTitle = '';
    this.newTaskPriority = 'P2';
    this.newTaskColor = 'blue';
    this.newTaskScheduleTitle = '';
    this.newTaskScheduleDuration = 25;
    this.newTaskScheduleDate = new Date().setHours(0, 0, 0, 0);
    this.newTaskScheduleTime = '09:00';
    this.newTaskReminderMinutes = -1;
  }

  resetScheduleForm() {
    this.newScheduleTitle = '';
    this.newScheduleDuration = 25;
    this.newScheduleDate = new Date().setHours(0, 0, 0, 0);
    this.newScheduleTime = '09:00';
    this.newScheduleReminderMinutes = -1;
  }

  getScheduleCount(): number {
    let count = 0;
    for (let task of this.tasks) {
      count += task.schedules.length;
    }
    return count;
  }

  getInboxCount(): number {
    let count = 0;
    for (let task of this.tasks) {
      if (task.schedules.length === 0) count++;
    }
    return count;
  }

  getTodaySchedules(): Schedule[] {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const start = today.getTime();
    const end = start + 24 * 60 * 60 * 1000;
    const schedules: Schedule[] = [];

    for (let task of this.tasks) {
      for (let schedule of task.schedules) {
        const due = this.getScheduleDueAt(schedule);
        if (due >= start && due < end) {
          schedules.push(schedule);
        }
      }
    }

    schedules.sort((a: Schedule, b: Schedule) => this.getScheduleDueAt(a) - this.getScheduleDueAt(b));
    return schedules;
  }

  getTaskTitle(taskId: string): string {
    for (let task of this.tasks) {
      if (task.id === taskId) return task.title;
    }
    return '未归类任务';
  }

  getTaskSteps(task: Task): TaskStep[] {
    return task.steps || [];
  }

  getStepCount(task: Task): number {
    return this.getTaskSteps(task).length;
  }

  getCompletedStepCount(task: Task): number {
    let count = 0;
    for (let step of this.getTaskSteps(task)) {
      if (step.completed) count++;
    }
    return count;
  }

  getDetailTaskSteps(): TaskStep[] {
    if (!this.detailTask) return [];
    return this.getTaskSteps(this.detailTask);
  }

  getDetailStepSummary(): string {
    if (!this.detailTask) return '0/0';
    return `${this.getCompletedStepCount(this.detailTask)}/${this.getStepCount(this.detailTask)}`;
  }

  refreshDetailTask(taskId: string) {
    for (let task of this.tasks) {
      if (task.id === taskId) {
        this.detailTask = task;
        this.detailTitle = task.title;
        this.detailNote = task.note || '';
        this.detailPriority = task.priority;
        return;
      }
    }
  }

  getTotalEstimatedMinutes(): number {
    let total = 0;
    for (let task of this.tasks) {
      for (let schedule of task.schedules) {
        total += schedule.estimatedTime;
      }
    }
    return total;
  }

  getPriorityRank(priority: Priority): number {
    if (priority === 'P0') return 0;
    if (priority === 'P1') return 1;
    return 2;
  }

  getPriorityLabel(priority: Priority): string {
    if (priority === 'P0') return '高';
    if (priority === 'P1') return '中';
    return '低';
  }

  getPriorityText(priority: Priority): string {
    if (priority === 'P0') return '优先';
    if (priority === 'P1') return '重要';
    return '常规';
  }

  getPriorityColor(priority: Priority): string {
    if (priority === 'P0') return '#2F6F86';
    if (priority === 'P1') return '#58B7AE';
    return '#7D8C96';
  }

  getPriorityBackground(priority: Priority): string {
    if (priority === 'P0') return '#E6F1F4';
    if (priority === 'P1') return '#E9F5F3';
    return '#F0F3F5';
  }

  buildDueAt(date: number, time: string): number {
    const parts = time.split(':');
    const hour = parseInt(parts[0]) || 0;
    const minute = parseInt(parts[1]) || 0;
    const due = new Date(date);
    due.setHours(hour, minute, 0, 0);
    return due.getTime();
  }

  getScheduleDueAt(schedule: Schedule): number {
    if (schedule.dueAt) return schedule.dueAt;
    return this.buildDueAt(schedule.scheduledDate || new Date().setHours(0, 0, 0, 0), schedule.scheduledTime || '09:00');
  }

  getNearestTaskDue(task: Task): number {
    if (task.schedules.length === 0) return 9999999999999;
    let nearest = this.getScheduleDueAt(task.schedules[0]);
    for (let schedule of task.schedules) {
      const due = this.getScheduleDueAt(schedule);
      if (due < nearest) nearest = due;
    }
    return nearest;
  }

  getOverdueCount(): number {
    const now = Date.now();
    let count = 0;
    for (let task of this.tasks) {
      for (let schedule of task.schedules) {
        if (this.getScheduleDueAt(schedule) < now) count++;
      }
    }
    return count;
  }

  getOngoingCount(): number {
    const now = Date.now();
    let count = 0;
    for (let task of this.tasks) {
      for (let schedule of task.schedules) {
        const due = this.getScheduleDueAt(schedule);
        const start = due - schedule.estimatedTime * 60 * 1000;
        if (now >= start && now <= due) count++;
      }
    }
    return count;
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
      { label: '早上', value: '09:00' },
      { label: '中午', value: '12:00' },
      { label: '下午', value: '15:00' },
      { label: '傍晚', value: '18:00' },
      { label: '晚上', value: '20:00' }
    ];
  }

  getReminderOptions(): ReminderOption[] {
    return [
      { label: '不提醒', value: -1 },
      { label: '准时', value: 0 },
      { label: '提前10分', value: 10 },
      { label: '提前30分', value: 30 }
    ];
  }

  getReminderText(minutes?: number): string {
    if (minutes === undefined || minutes < 0) return '不提醒';
    if (minutes === 0) return '准时提醒';
    return `提前 ${minutes} 分钟`;
  }

  formatScheduleDate(date?: number): string {
    const value = date || new Date().setHours(0, 0, 0, 0);
    const target = new Date(value);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const diff = Math.round((target.getTime() - today.getTime()) / (24 * 60 * 60 * 1000));
    if (diff === 0) return '今天';
    if (diff === 1) return '明天';
    return `${target.getMonth() + 1}/${target.getDate()}`;
  }

  formatScheduleDateTime(schedule: Schedule): string {
    return `${this.formatScheduleDate(schedule.scheduledDate)} ${schedule.scheduledTime || '09:00'}`;
  }

  getScheduleStatusLabel(schedule: Schedule): string {
    const now = Date.now();
    const due = this.getScheduleDueAt(schedule);
    const start = due - schedule.estimatedTime * 60 * 1000;
    if (due < now) return '已过期';
    if (now >= start && now <= due) return '进行中';
    return '已安排';
  }

  getScheduleStatusColor(schedule: Schedule): string {
    const label = this.getScheduleStatusLabel(schedule);
    if (label === '已过期') return '#8EA1AE';
    if (label === '进行中') return '#58B7AE';
    return '#2F6F86';
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text('今日计划')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')

        Text('用清晰的时间点组织今天')
          .fontSize(12)
          .fontColor('#6C7A84')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button('+')
        .fontSize(24)
        .fontColor('#FFFFFF')
        .width(44)
        .height(44)
        .borderRadius(8)
        .backgroundColor('#2F6F86')
        .onClick(() => {
          this.showAddTask = true;
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 8 })
  }

  @Builder
  PlanOverview() {
    Row() {
      this.OverviewItem(this.tasks.length.toString(), '任务')
      this.OverviewItem(this.getScheduleCount().toString(), '日程')
      this.OverviewItem(this.getInboxCount().toString(), '收集箱')
      this.OverviewItem(this.getOngoingCount().toString(), '进行中')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor('#17212A')
    .borderRadius(8)
  }

  @Builder
  OverviewItem(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text(label)
        .fontSize(11)
        .fontColor('#9BAAB2')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  QuickCapture() {
    Column() {
      Row() {
        Column() {
          Text('快速收集')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#151C22')

          Text('先放进收集箱，稍后再安排时间')
            .fontSize(12)
            .fontColor('#6C7A84')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(`${this.getOverdueCount()} 个逾期`)
          .fontSize(11)
          .fontColor(this.getOverdueCount() > 0 ? '#2F6F86' : '#8EA1AE')
          .fontWeight(FontWeight.Medium)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#F4F7F8')
          .borderRadius(8)
      }
      .width('100%')

      Row() {
        TextInput({ placeholder: '输入一个想法、任务或待办', text: this.quickTaskTitle })
          .height(46)
          .layoutWeight(1)
          .backgroundColor('#F4F7F8')
          .borderRadius(8)
          .onChange((value: string) => {
            this.quickTaskTitle = value;
          })

        Button('收集')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .width(70)
          .height(46)
          .backgroundColor(this.quickTaskTitle.trim().length > 0 ? '#2F6F86' : '#9BAAB2')
          .borderRadius(8)
          .margin({ left: 10 })
          .onClick(() => {
            this.handleQuickAddTask();
          })
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 18, color: '#23313A0F', offsetX: 0, offsetY: 10 })
    .margin({ top: 12 })
  }

  @Builder
  TodayTimeline() {
    Column() {
      Row() {
        Column() {
          Text('今日时间线')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#151C22')

          Text(`${this.getTodaySchedules().length} 个时间块 · ${this.getTotalEstimatedMinutes()} 分钟已规划`)
            .fontSize(12)
            .fontColor('#6C7A84')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('新建')
          .fontSize(12)
          .fontColor('#2F6F86')
          .backgroundColor('#EAF2F5')
          .borderRadius(8)
          .onClick(() => {
            this.showAddTask = true;
          })
      }
      .width('100%')

      if (this.getTodaySchedules().length === 0) {
        Row() {
          Text()
            .width(8)
            .height(8)
            .borderRadius(4)
            .backgroundColor('#8EA1AE')
            .margin({ right: 10 })

          Column() {
            Text('今天还没有时间块')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#151C22')

            Text('从收集箱挑一个任务，安排到今天')
              .fontSize(12)
              .fontColor('#6C7A84')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 18, bottom: 2 })
      } else {
        Column() {
          ForEach(this.getTodaySchedules().slice(0, 5), (schedule: Schedule) => {
            this.TimelineItem(schedule)
          }, (schedule: Schedule) => schedule.id)
        }
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 18, color: '#23313A0F', offsetX: 0, offsetY: 10 })
    .margin({ top: 12 })
  }

  @Builder
  TimelineItem(schedule: Schedule) {
    Row() {
      Column() {
        Text(schedule.scheduledTime || '09:00')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')

        Text(`${schedule.estimatedTime} 分钟`)
          .fontSize(10)
          .fontColor('#8EA1AE')
          .margin({ top: 3 })
      }
      .width(56)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text()
          .width(9)
          .height(9)
          .borderRadius(5)
          .backgroundColor(this.getScheduleStatusColor(schedule))
          .margin({ top: 3 })

        Text()
          .width(1)
          .height(38)
          .backgroundColor('#DDE6EA')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ left: 6, right: 12 })

      Column() {
        Text(schedule.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#151C22')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.getTaskTitle(schedule.taskId))
          .fontSize(11)
          .fontColor('#6C7A84')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.getScheduleStatusLabel(schedule))
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getScheduleStatusColor(schedule))
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#F4F7F8')
        .borderRadius(8)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  TaskCard(task: Task) {
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
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#151C22')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`${task.schedules.length} 个日程 · ${this.getPriorityText(task.priority)} · ${this.getStepCount(task)} 个子任务`)
            .fontSize(12)
            .fontColor('#6C7A84')
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.getPriorityLabel(task.priority))
          .fontSize(12)
          .fontColor(this.getPriorityColor(task.priority))
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.getPriorityBackground(task.priority))
          .borderRadius(8)
      }
      .width('100%')

      if (task.schedules.length === 0) {
        Text('还没有安排具体日程')
          .fontSize(13)
          .fontColor('#8EA1AE')
          .padding({ top: 18, bottom: 8 })
      } else {
        Column() {
          ForEach(task.schedules, (schedule: Schedule) => {
            this.ScheduleRow(schedule, task)
          }, (schedule: Schedule) => schedule.id)
        }
        .margin({ top: 14 })
      }

      Row() {
        Button('详情')
          .fontSize(13)
          .fontColor('#151C22')
          .backgroundColor('#F4F7F8')
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.openTaskDetail(task);
          })

        Button(task.schedules.length === 0 ? '安排' : '添加日程')
          .fontSize(13)
          .fontColor('#2F6F86')
          .backgroundColor('#EAF2F5')
          .borderRadius(8)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.selectedTask = task;
            this.showAddSchedule = true;
          })

        Button('删除')
          .fontSize(13)
          .fontColor('#7D8C96')
          .backgroundColor('#F0F3F5')
          .borderRadius(8)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.handleDeleteTask(task.id);
          })
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 18, color: '#23313A0F', offsetX: 0, offsetY: 10 })
    .margin({ top: 12 })
  }

  getTaskMinutes(task: Task): number {
    let total = 0;
    for (let schedule of task.schedules) {
      total += schedule.estimatedTime;
    }
    return total;
  }

  @Builder
  ScheduleRow(schedule: Schedule, task: Task) {
    Row() {
      Column() {
        Text(schedule.scheduledTime || '09:00')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')

        Text(this.formatScheduleDate(schedule.scheduledDate))
          .fontSize(10)
          .fontColor('#7D8C96')
          .margin({ top: 3 })
      }
      .width(54)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text(schedule.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#151C22')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${schedule.estimatedTime} 分钟 · ${this.getReminderText(schedule.reminderMinutes)}`)
          .fontSize(11)
          .fontColor('#6C7A84')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.getScheduleStatusLabel(schedule))
        .fontSize(10)
        .fontColor(this.getScheduleStatusColor(schedule))
        .fontWeight(FontWeight.Medium)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('#F4F7F8')
        .borderRadius(8)
        .margin({ right: 8 })

      Button('开始')
        .fontSize(12)
        .fontColor('#FFFFFF')
        .backgroundColor('#58B7AE')
        .borderRadius(8)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/FocusPage',
            params: {
              duration: schedule.estimatedTime,
              scheduleId: schedule.id,
              taskId: task.id
            }
          });
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  EmptyState() {
    Column() {
      SymbolGlyph($r('sys.symbol.doc_text'))
        .fontSize(34)
        .fontColor(['#8EA1AE'])

      Text('还没有计划')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#151C22')
        .margin({ top: 14 })

      Text('创建一个任务，并安排它的第一个时间点。')
        .fontSize(13)
        .fontColor('#6C7A84')
        .margin({ top: 6 })

      Button('创建任务')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#2F6F86')
        .borderRadius(8)
        .margin({ top: 18 })
        .onClick(() => {
          this.showAddTask = true;
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 36, bottom: 36 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ top: 14 })
  }

  @Builder
  DateStrip(forTask: boolean) {
    Row() {
      ForEach(this.getDateOptions(), (option: DateOption) => {
        this.DatePill(option, forTask ? this.newTaskScheduleDate === option.value : this.newScheduleDate === option.value, () => {
          if (forTask) {
            this.newTaskScheduleDate = option.value;
          } else {
            this.newScheduleDate = option.value;
          }
        })
      }, (option: DateOption) => option.value.toString())
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  TimeStrip(forTask: boolean) {
    Row() {
      ForEach(this.getTimeOptions(), (option: TimeOption) => {
        this.TimePill(option, forTask ? this.newTaskScheduleTime === option.value : this.newScheduleTime === option.value, () => {
          if (forTask) {
            this.newTaskScheduleTime = option.value;
          } else {
            this.newScheduleTime = option.value;
          }
        })
      }, (option: TimeOption) => option.value)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  ReminderStrip(forTask: boolean) {
    Row() {
      ForEach(this.getReminderOptions(), (option: ReminderOption) => {
        this.ReminderPill(option, forTask ? this.newTaskReminderMinutes === option.value : this.newScheduleReminderMinutes === option.value, () => {
          if (forTask) {
            this.newTaskReminderMinutes = option.value;
          } else {
            this.newScheduleReminderMinutes = option.value;
          }
        })
      }, (option: ReminderOption) => option.value.toString())
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  DatePill(option: DateOption, selected: boolean, onSelect: () => void) {
    Column() {
      Text(option.label)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(selected ? '#FFFFFF' : '#52626D')

      Text(option.subLabel)
        .fontSize(10)
        .fontColor(selected ? '#C9DBE0' : '#8EA1AE')
        .margin({ top: 3 })
    }
    .width(42)
    .height(50)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(selected ? '#2F6F86' : '#F4F7F8')
    .borderRadius(8)
    .onClick(onSelect)
  }

  @Builder
  TimePill(option: TimeOption, selected: boolean, onSelect: () => void) {
    Column() {
      Text(option.label)
        .fontSize(10)
        .fontColor(selected ? '#C9DBE0' : '#8EA1AE')

      Text(option.value)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(selected ? '#FFFFFF' : '#52626D')
        .margin({ top: 3 })
    }
    .width(56)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(selected ? '#2F6F86' : '#F4F7F8')
    .borderRadius(8)
    .onClick(onSelect)
  }

  @Builder
  ReminderPill(option: ReminderOption, selected: boolean, onSelect: () => void) {
    Text(option.label)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(selected ? '#FFFFFF' : '#52626D')
      .padding({ left: 9, right: 9, top: 8, bottom: 8 })
      .backgroundColor(selected ? '#2F6F86' : '#F4F7F8')
      .borderRadius(8)
      .onClick(onSelect)
  }

  @Builder
  PrioritySelector() {
    Row() {
      this.PriorityPill('P0', '优先')
      this.PriorityPill('P1', '重要')
      this.PriorityPill('P2', '常规')
    }
    .width('100%')
  }

  @Builder
  PriorityPill(priority: Priority, label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.newTaskPriority === priority ? '#FFFFFF' : '#52626D')
      .padding({ left: 16, right: 16, top: 9, bottom: 9 })
      .backgroundColor(this.newTaskPriority === priority ? this.getPriorityColor(priority) : '#F4F7F8')
      .borderRadius(8)
      .margin({ right: 8 })
      .onClick(() => {
        this.newTaskPriority = priority;
      })
  }

  @Builder
  DetailPrioritySelector() {
    Row() {
      this.DetailPriorityPill('P0', '优先')
      this.DetailPriorityPill('P1', '重要')
      this.DetailPriorityPill('P2', '常规')
    }
    .width('100%')
  }

  @Builder
  DetailPriorityPill(priority: Priority, label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.detailPriority === priority ? '#FFFFFF' : '#52626D')
      .padding({ left: 16, right: 16, top: 9, bottom: 9 })
      .backgroundColor(this.detailPriority === priority ? this.getPriorityColor(priority) : '#F4F7F8')
      .borderRadius(8)
      .margin({ right: 8 })
      .onClick(() => {
        this.detailPriority = priority;
      })
  }

  @Builder
  DetailDateStrip() {
    Row() {
      ForEach(this.getDateOptions(), (option: DateOption) => {
        this.DatePill(option, this.detailScheduleDate === option.value, () => {
          this.detailScheduleDate = option.value;
        })
      }, (option: DateOption) => option.value.toString())
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  DetailTimeStrip() {
    Row() {
      ForEach(this.getTimeOptions(), (option: TimeOption) => {
        this.TimePill(option, this.detailScheduleTime === option.value, () => {
          this.detailScheduleTime = option.value;
        })
      }, (option: TimeOption) => option.value)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  DetailReminderStrip() {
    Row() {
      ForEach(this.getReminderOptions(), (option: ReminderOption) => {
        this.ReminderPill(option, this.detailReminderMinutes === option.value, () => {
          this.detailReminderMinutes = option.value;
        })
      }, (option: ReminderOption) => option.value.toString())
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  StepRow(step: TaskStep) {
    Row() {
      Text(step.completed ? '✓' : '')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(24)
        .height(24)
        .textAlign(TextAlign.Center)
        .backgroundColor(step.completed ? '#58B7AE' : '#DDE6EA')
        .borderRadius(12)
        .margin({ right: 10 })
        .onClick(() => {
          this.toggleDetailStep(step.id);
        })

      Text(step.title)
        .fontSize(14)
        .fontColor(step.completed ? '#8EA1AE' : '#151C22')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Button('删')
        .fontSize(11)
        .fontColor('#7D8C96')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .onClick(() => {
          this.deleteDetailStep(step.id);
        })
    }
    .width('100%')
    .padding({ left: 12, right: 8, top: 9, bottom: 9 })
    .backgroundColor('#F4F7F8')
    .borderRadius(8)
    .margin({ top: 8 })
  }

  @Builder
  TaskDetailSheet() {
    if (this.detailTask) {
      Column() {
        Row() {
          Column() {
            Text('任务详情')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#151C22')

            Text(`${this.detailTask.schedules.length} 个日程 · 子任务 ${this.getDetailStepSummary()}`)
              .fontSize(12)
              .fontColor('#6C7A84')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('完成')
            .fontSize(12)
            .fontColor('#2F6F86')
            .backgroundColor('#EAF2F5')
            .borderRadius(8)
            .onClick(() => {
              this.saveAndCloseTaskDetail();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 18, bottom: 12 })

        Scroll() {
          Column() {
            TextInput({ placeholder: '任务标题', text: this.detailTitle })
              .width('100%')
              .height(48)
              .backgroundColor('#F4F7F8')
              .borderRadius(8)
              .onChange((value: string) => {
                this.detailTitle = value;
              })

            Text('优先级')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#52626D')
              .margin({ top: 16, bottom: 10 })
            this.DetailPrioritySelector()

            Text('备注')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#52626D')
              .margin({ top: 18, bottom: 10 })
            TextArea({ placeholder: '补充背景、链接、要求或灵感', text: this.detailNote })
              .width('100%')
              .height(92)
              .backgroundColor('#F4F7F8')
              .borderRadius(8)
              .onChange((value: string) => {
                this.detailNote = value;
              })

            Row() {
              Text('子任务')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#151C22')
                .layoutWeight(1)

              Text(this.getDetailStepSummary())
                .fontSize(12)
                .fontColor('#6C7A84')
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .backgroundColor('#F4F7F8')
                .borderRadius(8)
            }
            .width('100%')
            .margin({ top: 20 })

            if (this.getDetailTaskSteps().length === 0) {
              Text('还没有子任务，适合把大任务拆成 2-5 个可执行步骤。')
                .fontSize(12)
                .fontColor('#8EA1AE')
                .margin({ top: 10 })
            } else {
              ForEach(this.getDetailTaskSteps(), (step: TaskStep) => {
                this.StepRow(step)
              }, (step: TaskStep) => step.id)
            }

            Row() {
              TextInput({ placeholder: '添加一个子任务', text: this.detailNewStepTitle })
                .height(44)
                .layoutWeight(1)
                .backgroundColor('#F4F7F8')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.detailNewStepTitle = value;
                })

              Button('添加')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .width(66)
                .height(44)
                .backgroundColor(this.detailNewStepTitle.trim().length > 0 ? '#2F6F86' : '#9BAAB2')
                .borderRadius(8)
                .margin({ left: 10 })
                .onClick(() => {
                  this.handleAddDetailStep();
                })
            }
            .width('100%')
            .margin({ top: 12 })

            Text('安排到时间线')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#151C22')
              .margin({ top: 22, bottom: 10 })

            TextInput({ placeholder: '时间块内容，默认使用任务标题', text: this.detailScheduleTitle })
              .width('100%')
              .height(46)
              .backgroundColor('#F4F7F8')
              .borderRadius(8)
              .onChange((value: string) => {
                this.detailScheduleTitle = value;
              })

            Row() {
              TextInput({ placeholder: '25', text: this.detailScheduleDuration.toString() })
                .type(InputType.Number)
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F4F7F8')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.detailScheduleDuration = parseInt(value) || 25;
                })

              Text('分钟')
                .fontSize(13)
                .fontColor('#6C7A84')
                .margin({ left: 10 })
            }
            .width('100%')
            .margin({ top: 10, bottom: 14 })

            this.DetailDateStrip()
            Text('时间点')
              .fontSize(13)
              .fontColor('#52626D')
              .margin({ top: 16, bottom: 10 })
            this.DetailTimeStrip()
            Text('提醒')
              .fontSize(13)
              .fontColor('#52626D')
              .margin({ top: 16, bottom: 10 })
            this.DetailReminderStrip()
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 16 })
        }
        .width('100%')
        .layoutWeight(1)

        Row() {
          Button('保存')
            .fontSize(14)
            .fontColor('#52626D')
            .backgroundColor('#F0F3F5')
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => {
              this.saveTaskDetail();
            })

          Button('安排')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#2F6F86')
            .borderRadius(8)
            .layoutWeight(1)
            .margin({ left: 10 })
            .onClick(() => {
              this.handleAddDetailSchedule();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 18 })
        .backgroundColor('#FFFFFF')
      }
      .width('100%')
      .height('88%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
  }

  @Builder
  AddTaskDialog() {
    if (this.showAddTask) {
      Column() {
        Text('新建任务')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')
          .margin({ bottom: 18 })

        TextInput({ placeholder: '任务标题', text: this.newTaskTitle })
          .width('100%')
          .height(46)
          .backgroundColor('#F4F7F8')
          .borderRadius(8)
          .onChange((value: string) => {
            this.newTaskTitle = value;
          })

        Text('优先级')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#52626D')
          .margin({ top: 16, bottom: 10 })
        this.PrioritySelector()

        Text('第一个日程')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#52626D')
          .margin({ top: 18, bottom: 10 })

        TextInput({ placeholder: '例如：整理课程笔记', text: this.newTaskScheduleTitle })
          .width('100%')
          .height(46)
          .backgroundColor('#F4F7F8')
          .borderRadius(8)
          .onChange((value: string) => {
            this.newTaskScheduleTitle = value;
          })

        Row() {
          TextInput({ placeholder: '25', text: this.newTaskScheduleDuration.toString() })
            .type(InputType.Number)
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#F4F7F8')
            .borderRadius(8)
            .onChange((value: string) => {
              this.newTaskScheduleDuration = parseInt(value) || 25;
            })

          Text('分钟')
            .fontSize(13)
            .fontColor('#6C7A84')
            .margin({ left: 10 })
        }
        .width('100%')
        .margin({ top: 10, bottom: 14 })

        this.DateStrip(true)
        Text('时间点')
          .fontSize(13)
          .fontColor('#52626D')
          .margin({ top: 16, bottom: 10 })
        this.TimeStrip(true)
        Text('提醒')
          .fontSize(13)
          .fontColor('#52626D')
          .margin({ top: 16, bottom: 10 })
        this.ReminderStrip(true)

        this.DialogActions(() => {
          this.resetTaskForm();
          this.showAddTask = false;
        }, () => {
          this.handleAddTask();
        })
      }
      .width('90%')
      .padding({ left: 20, right: 20, top: 22, bottom: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
    }
  }

  @Builder
  AddScheduleDialog() {
    if (this.showAddSchedule) {
      Column() {
        Text('添加日程')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')
          .margin({ bottom: 18 })

        TextInput({ placeholder: '日程内容', text: this.newScheduleTitle })
          .width('100%')
          .height(46)
          .backgroundColor('#F4F7F8')
          .borderRadius(8)
          .onChange((value: string) => {
            this.newScheduleTitle = value;
          })

        Row() {
          TextInput({ placeholder: '25', text: this.newScheduleDuration.toString() })
            .type(InputType.Number)
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#F4F7F8')
            .borderRadius(8)
            .onChange((value: string) => {
              this.newScheduleDuration = parseInt(value) || 25;
            })

          Text('分钟')
            .fontSize(13)
            .fontColor('#6C7A84')
            .margin({ left: 10 })
        }
        .width('100%')
        .margin({ top: 10, bottom: 16 })

        this.DateStrip(false)
        Text('时间点')
          .fontSize(13)
          .fontColor('#52626D')
          .margin({ top: 16, bottom: 10 })
        this.TimeStrip(false)
        Text('提醒')
          .fontSize(13)
          .fontColor('#52626D')
          .margin({ top: 16, bottom: 10 })
        this.ReminderStrip(false)

        this.DialogActions(() => {
          this.resetScheduleForm();
          this.showAddSchedule = false;
          this.selectedTask = null;
        }, () => {
          this.handleAddSchedule();
        })
      }
      .width('90%')
      .padding({ left: 20, right: 20, top: 22, bottom: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
    }
  }

  @Builder
  DialogActions(onCancel: () => void, onConfirm: () => void) {
    Row() {
      Button('取消')
        .fontSize(14)
        .fontColor('#52626D')
        .backgroundColor('#F0F3F5')
        .borderRadius(8)
        .layoutWeight(1)
        .onClick(onCancel)

      Button('确认')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#2F6F86')
        .borderRadius(8)
        .layoutWeight(1)
        .margin({ left: 10 })
        .onClick(onConfirm)
    }
    .width('100%')
    .margin({ top: 22 })
  }

  build() {
    Stack() {
      Column() {
        this.Header()

        Scroll() {
          Column() {
            this.PlanOverview()
            this.QuickCapture()
            this.TodayTimeline()

            if (this.tasks.length === 0) {
              this.EmptyState()
            } else {
              ForEach(this.tasks, (task: Task) => {
                this.TaskCard(task)
              }, (task: Task) => task.id)
            }
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F4F7F8')

      if (this.showAddTask || this.showAddSchedule) {
        Column() {
          this.AddTaskDialog()
          this.AddScheduleDialog()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#17212A66')
      }

      if (this.showTaskDetail) {
        Column() {
          Blank()
          this.TaskDetailSheet()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#17212A66')
      }
    }
  }
}
