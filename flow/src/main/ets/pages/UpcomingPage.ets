/**
 * Future schedule ownership surface.
 */

import { DataManager } from '../utils/DataManager';
import { NavigationManager } from '../utils/NavigationManager';
import { PickerDateTime } from '../utils/PickerDateTime';
import { ScheduleAnalyzer } from '../utils/ScheduleAnalyzer';
import { TaskDepthUtils } from '../utils/TaskDepthUtils';
import { TimeFormatter } from '../utils/TimeFormatter';
import { ThemeContext } from '../utils/ThemeContext';
import { ThemeTokens } from '../utils/ThemeTokens';
import { Priority, Schedule, ScheduleArchiveEntry, ScheduleChange, ScheduleChangeType, Task, TaskStep, ThemeConfig } from '../models/DataModels';

interface UpcomingGroup {
  title: string;
  subtitle: string;
  color: string;
  schedules: Schedule[];
}

@Component
export struct UpcomingPage {
  @StorageLink(ThemeContext.getThemeLink()) currentTheme: ThemeConfig = ThemeContext.getCurrentTheme();
  @State tasks: Task[] = [];
  @State schedules: Schedule[] = [];
  @State todaySchedules: Schedule[] = [];
  @State tomorrowSchedules: Schedule[] = [];
  @State weekSchedules: Schedule[] = [];
  @State laterSchedules: Schedule[] = [];
  @State lastActionText: string = '';
  @State totalFutureMinutes: number = 0;
  @State showScheduleEditor: boolean = false;
  @State editingSchedule: Schedule | null = null;
  @State editTitle: string = '';
  @State editPriority: Priority = 'P2';
  @State editDuration: number = 25;
  @State editDate: number = new Date().setHours(0, 0, 0, 0);
  @State editTime: string = '09:00';
  @State editChangeNote: string = '';
  @State editTaskNote: string = '';
  @State editTaskSteps: TaskStep[] = [];
  @State editNewStepTitle: string = '';
  @State showTaskDepthEditor: boolean = false;

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.tasks = await DataManager.getAllTasks();
    const allSchedules = await DataManager.getAllSchedules();
    this.schedules = [];
    this.todaySchedules = [];
    this.tomorrowSchedules = [];
    this.weekSchedules = [];
    this.laterSchedules = [];
    this.totalFutureMinutes = 0;

    const todayStart = this.getDayStart(0);
    const tomorrowStart = this.getDayStart(1);
    const afterTomorrowStart = this.getDayStart(2);
    const weekEnd = this.getDayStart(8);

    for (let schedule of allSchedules) {
      if (!ScheduleAnalyzer.isActiveForPlanning(schedule)) {
        continue;
      }
      const due = ScheduleAnalyzer.getDueAt(schedule);
      if (due >= todayStart && due < tomorrowStart) {
        this.todaySchedules.push(schedule);
      }
      if (due < tomorrowStart) {
        continue;
      }
      this.schedules.push(schedule);
      this.totalFutureMinutes += schedule.estimatedTime;
      if (due >= tomorrowStart && due < afterTomorrowStart) {
        this.tomorrowSchedules.push(schedule);
      } else if (due >= afterTomorrowStart && due < weekEnd) {
        this.weekSchedules.push(schedule);
      } else {
        this.laterSchedules.push(schedule);
      }
    }

    this.sortSchedules(this.tomorrowSchedules);
    this.sortSchedules(this.weekSchedules);
    this.sortSchedules(this.laterSchedules);
    this.sortSchedules(this.todaySchedules);
    this.sortSchedules(this.schedules);
  }

  sortSchedules(list: Schedule[]) {
    list.sort((a: Schedule, b: Schedule) => ScheduleAnalyzer.getDueAt(a) - ScheduleAnalyzer.getDueAt(b));
  }

  getDayStart(offset: number): number {
    const date = new Date();
    date.setHours(0, 0, 0, 0);
    date.setDate(date.getDate() + offset);
    return date.getTime();
  }

  buildDueAt(date: number, time: string): number {
    const parts = time.split(':');
    const hour = parseInt(parts[0]) || 0;
    const minute = parseInt(parts[1]) || 0;
    const due = new Date(date);
    due.setHours(hour, minute, 0, 0);
    return due.getTime();
  }

  getTaskForSchedule(schedule: Schedule): Task | null {
    for (let task of this.tasks) {
      if (task.id === schedule.taskId) {
        return task;
      }
    }
    return null;
  }

  getTaskNote(schedule: Schedule): string {
    return TaskDepthUtils.getNote(this.getTaskForSchedule(schedule));
  }

  getTaskSteps(schedule: Schedule): TaskStep[] {
    return TaskDepthUtils.getSteps(this.getTaskForSchedule(schedule));
  }

  getTaskStepSummary(schedule: Schedule): string {
    return TaskDepthUtils.getStepSummary(this.getTaskSteps(schedule));
  }

  async toggleTaskStep(taskId: string, stepId: string) {
    const task = await DataManager.getTask(taskId);
    if (!task) return;
    const updated = TaskDepthUtils.buildTaskWithToggledStep(task, stepId);
    await DataManager.saveTask(updated);
    await this.loadData();
  }

  getEditingStepSummary(): string {
    return TaskDepthUtils.getDraftStepSummary(this.editTaskSteps);
  }

  getEditingDepthHint(): string {
    return TaskDepthUtils.getDepthHint(this.editTaskNote, this.editTaskSteps);
  }

  addEditingTaskStep() {
    if (!TaskDepthUtils.hasStepTitle(this.editNewStepTitle)) return;
    this.editTaskSteps = TaskDepthUtils.addStep(this.editTaskSteps, this.editNewStepTitle);
    this.editNewStepTitle = '';
  }

  toggleEditingTaskStep(stepId: string) {
    this.editTaskSteps = TaskDepthUtils.toggleStep(this.editTaskSteps, stepId);
  }

  deleteEditingTaskStep(stepId: string) {
    this.editTaskSteps = TaskDepthUtils.deleteStep(this.editTaskSteps, stepId);
  }

  async saveEditingTaskDepth() {
    if (!this.editingSchedule) return;
    const task = await DataManager.getTask(this.editingSchedule.taskId);
    if (!task) return;
    const updated = TaskDepthUtils.buildUpdatedTask(
      task,
      this.editTitle,
      this.editPriority,
      this.editTaskNote,
      this.editTaskSteps
    );
    await DataManager.saveTask(updated);
  }

  openScheduleEditor(schedule: Schedule) {
    const due = ScheduleAnalyzer.getDueAt(schedule);
    const date = new Date(due);
    date.setHours(0, 0, 0, 0);
    const task = this.getTaskForSchedule(schedule);
    this.editingSchedule = schedule;
    this.editTitle = schedule.title;
    this.editPriority = schedule.priority;
    this.editDuration = schedule.estimatedTime;
    this.editDate = date.getTime();
    this.editTime = TimeFormatter.formatTime(due);
    this.editChangeNote = '';
    const draft = TaskDepthUtils.createDraft(task);
    this.editTaskNote = draft.note;
    this.editTaskSteps = draft.steps;
    this.editNewStepTitle = draft.newStepTitle;
    this.showTaskDepthEditor = draft.expanded;
    NavigationManager.setTabBarCovered(true);
    this.showScheduleEditor = true;
  }

  closeScheduleEditor() {
    this.showScheduleEditor = false;
    NavigationManager.setTabBarCovered(false);
    this.editingSchedule = null;
    this.editTitle = '';
    this.editPriority = 'P2';
    this.editDuration = 25;
    this.editDate = new Date().setHours(0, 0, 0, 0);
    this.editTime = '09:00';
    this.editChangeNote = '';
    const draft = TaskDepthUtils.emptyDraft();
    this.editTaskNote = draft.note;
    this.editTaskSteps = draft.steps;
    this.editNewStepTitle = draft.newStepTitle;
    this.showTaskDepthEditor = draft.expanded;
  }

  getSafeEditDuration(): number {
    if (this.editDuration < 5) return 5;
    if (this.editDuration > 240) return 240;
    return this.editDuration;
  }

  setEditDuration(value: string) {
    const parsed = parseInt(value);
    if (!isNaN(parsed)) {
      this.editDuration = parsed;
    }
  }

  adjustEditDuration(delta: number) {
    const next = this.getSafeEditDuration() + delta;
    if (next < 5) {
      this.editDuration = 5;
    } else if (next > 240) {
      this.editDuration = 240;
    } else {
      this.editDuration = next;
    }
  }

  getPickerStartDate(): Date {
    return PickerDateTime.getStartDate();
  }

  getPickerEndDate(): Date {
    return PickerDateTime.getEndDate();
  }

  getEditSelectedDate(): Date {
    return PickerDateTime.getSelectedDate(this.editDate);
  }

  getEditSelectedTime(): Date {
    return PickerDateTime.getSelectedTime(this.editDate, this.editTime);
  }

  applyEditDate(value: Date) {
    this.editDate = PickerDateTime.dateFromSelectedDate(value);
  }

  applyEditTime(value: TimePickerResult) {
    this.editTime = PickerDateTime.timeFromPickerResult(this.editTime, value);
  }

  getChangeFallbackNote(type: ScheduleChangeType): string {
    if (type === 'delete') return '删除未来安排';
    if (type === 'delay') return '调整未来安排';
    return '编辑未来安排';
  }

  buildChangeRecord(type: ScheduleChangeType, fromDueAt: number, toDueAt: number, fromDuration: number, toDuration: number): ScheduleChange {
    return {
      id: `change_${Date.now()}`,
      type,
      timestamp: Date.now(),
      note: this.editChangeNote.trim().length > 0 ? this.editChangeNote.trim() : this.getChangeFallbackNote(type),
      fromDueAt,
      toDueAt,
      fromDuration,
      toDuration
    };
  }

  async saveScheduleEdit(type: ScheduleChangeType = 'edit') {
    if (!this.editingSchedule || !this.editTitle.trim()) return;

    const fromDueAt = ScheduleAnalyzer.getDueAt(this.editingSchedule);
    const toDueAt = this.buildDueAt(this.editDate, this.editTime);
    const fromDuration = this.editingSchedule.estimatedTime;
    const toDuration = this.getSafeEditDuration();
    const history: ScheduleChange[] = [];
    for (let item of this.editingSchedule.changeHistory || []) {
      history.push(item);
    }
    if (fromDueAt !== toDueAt || fromDuration !== toDuration || this.editChangeNote.trim().length > 0 || type !== 'edit') {
      history.push(this.buildChangeRecord(type, fromDueAt, toDueAt, fromDuration, toDuration));
    }

    const updated: Schedule = {
      id: this.editingSchedule.id,
      taskId: this.editingSchedule.taskId,
      title: this.editTitle.trim(),
      estimatedTime: toDuration,
      priority: this.editPriority,
      scheduledDate: this.editDate,
      scheduledTime: this.editTime,
      dueAt: toDueAt,
      reminderMinutes: this.editingSchedule.reminderMinutes,
      createdAt: this.editingSchedule.createdAt,
      stats: this.editingSchedule.stats,
      changeHistory: history,
      state: this.editingSchedule.state || 'planned',
      completedAt: this.editingSchedule.completedAt,
      deferredAt: this.editingSchedule.deferredAt,
      cancelledAt: this.editingSchedule.cancelledAt,
      actualMinutes: this.editingSchedule.actualMinutes,
      stateNote: this.editingSchedule.stateNote,
      routineId: this.editingSchedule.routineId
    };

    await this.saveEditingTaskDepth();
    await DataManager.saveSchedule(updated);
    this.lastActionText = `已更新：${updated.title}`;
    this.closeScheduleEditor();
    await this.loadData();
  }

  async deleteEditingSchedule() {
    if (!this.editingSchedule) return;
    const schedule = this.editingSchedule;
    await this.archiveAndDeleteSchedule(schedule, this.editChangeNote.trim().length > 0 ? this.editChangeNote.trim() : '删除未来安排');
    this.lastActionText = `已删除未来安排：${schedule.title}`;
    this.closeScheduleEditor();
    await this.loadData();
  }

  async archiveAndDeleteSchedule(schedule: Schedule, note: string) {
    const archive: ScheduleArchiveEntry = {
      id: `archive_${Date.now()}_${schedule.id}`,
      scheduleId: schedule.id,
      taskId: schedule.taskId,
      title: schedule.title,
      estimatedTime: schedule.estimatedTime,
      priority: schedule.priority,
      scheduledDate: schedule.scheduledDate,
      scheduledTime: schedule.scheduledTime,
      dueAt: ScheduleAnalyzer.getDueAt(schedule),
      archivedAt: Date.now(),
      reason: 'delete',
      note,
      changeHistory: schedule.changeHistory || []
    };
    await DataManager.saveScheduleArchiveEntry(archive);
    await DataManager.deleteSchedule(schedule.id);
  }

  getNextTodayTime(): string {
    const now = new Date();
    let hour = now.getHours() + 1;
    if (hour < 9) hour = 9;

    if (this.todaySchedules.length > 0) {
      const lastDue = new Date(ScheduleAnalyzer.getDueAt(this.todaySchedules[this.todaySchedules.length - 1]));
      hour = lastDue.getHours() + 1;
    }

    if (hour > 21) hour = 21;
    return `${String(hour).padStart(2, '0')}:00`;
  }

  buildMoveChange(schedule: Schedule, toDueAt: number): ScheduleChange {
    return {
      id: `change_${Date.now()}_${schedule.id}`,
      type: 'edit',
      timestamp: Date.now(),
      note: '从未来移到今天',
      fromDueAt: ScheduleAnalyzer.getDueAt(schedule),
      toDueAt,
      fromDuration: schedule.estimatedTime,
      toDuration: schedule.estimatedTime
    };
  }

  async moveToToday(schedule: Schedule) {
    const today = this.getDayStart(0);
    const time = this.getNextTodayTime();
    const dueAt = this.buildDueAt(today, time);
    const history: ScheduleChange[] = [];
    for (let item of schedule.changeHistory || []) {
      history.push(item);
    }
    history.push(this.buildMoveChange(schedule, dueAt));

    const updated: Schedule = {
      id: schedule.id,
      taskId: schedule.taskId,
      title: schedule.title,
      estimatedTime: schedule.estimatedTime,
      priority: schedule.priority,
      scheduledDate: today,
      scheduledTime: time,
      dueAt,
      reminderMinutes: schedule.reminderMinutes,
      createdAt: schedule.createdAt,
      stats: schedule.stats,
      changeHistory: history,
      state: 'planned',
      completedAt: schedule.completedAt,
      deferredAt: schedule.deferredAt,
      cancelledAt: schedule.cancelledAt,
      actualMinutes: schedule.actualMinutes,
      stateNote: '从未来移到今天',
      routineId: schedule.routineId
    };
    await DataManager.saveSchedule(updated);
    this.lastActionText = `已移到今天 ${time}：${schedule.title}`;
    await this.loadData();
  }

  async sendBackToInbox(schedule: Schedule) {
    await this.archiveAndDeleteSchedule(schedule, '退回收集箱');
    this.lastActionText = `已退回收集箱：${schedule.title}`;
    await this.loadData();
  }

  getGroups(): UpcomingGroup[] {
    return [
      {
        title: '明天',
        subtitle: '从收集箱点“明天”的任务会先来到这里',
        color: '#8A7CC3',
        schedules: this.tomorrowSchedules
      },
      {
        title: '本周稍后',
        subtitle: '未来 7 天内已经安排但不是明天的时间块',
        color: '#256D85',
        schedules: this.weekSchedules
      },
      {
        title: '以后',
        subtitle: '更远日期的安排先放在这里，之后会进入周/月视图',
        color: '#607385',
        schedules: this.laterSchedules
      }
    ];
  }

  getPriorityColor(priority: Priority): string {
    if (priority === 'P0') return '#2F6F86';
    if (priority === 'P1') return '#58B7AE';
    return '#607385';
  }

  getPriorityLabel(priority: Priority): string {
    if (priority === 'P0') return '优先';
    if (priority === 'P1') return '重要';
    return '常规';
  }

  getScheduleDateText(schedule: Schedule): string {
    const due = ScheduleAnalyzer.getDueAt(schedule);
    return `${TimeFormatter.formatDate(due)} · ${TimeFormatter.getWeekdayName(due)}`;
  }

  getScheduleTimeText(schedule: Schedule): string {
    return `${TimeFormatter.formatTime(ScheduleAnalyzer.getStartAt(schedule))}-${TimeFormatter.formatTime(ScheduleAnalyzer.getDueAt(schedule))}`;
  }

  getEmptyHint(): string {
    return '安排到明天、本周或以后时，这里会成为它们的固定位置。收集箱只保留还没安排时间的任务。';
  }

  navigateTo(url: string) {
    if (!NavigationManager.openMainTab(url)) {
      NavigationManager.push(this.getUIContext(), url);
    }
  }

  @Builder
  Header() {
    Column() {
      Text('未来')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.text(this.currentTheme))

      Text('管理明天、本周和以后已经安排的时间块。')
        .fontSize(12)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .lineHeight(18)
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 8 })
  }

  @Builder
  SummaryBand() {
    Column() {
      Row() {
        Column() {
          Text('未来负荷')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#607385')

          Text(`${this.schedules.length} 个安排`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(`${this.totalFutureMinutes} 分钟`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#256D85')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
          .borderRadius(8)
      }
      .width('100%')

      if (this.lastActionText.length > 0) {
        Text(this.lastActionText)
          .fontSize(12)
          .fontColor('#46AFA5')
          .lineHeight(18)
          .margin({ top: 12 })
      } else {
        Text('如果任务已经有时间，就不应该继续藏在收集箱。这里负责给未来安排一个清楚的位置。')
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .lineHeight(18)
          .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(ThemeTokens.elevated(this.currentTheme))
    .borderRadius(18)
    .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
    .shadow({ radius: 22, color: ThemeTokens.cardShadow(this.currentTheme), offsetX: 0, offsetY: 10 })
  }

  @Builder
  GroupPanel(group: UpcomingGroup) {
    Column() {
      Row() {
        Text(group.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .layoutWeight(1)

        Text(`${group.schedules.length}`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(group.color)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(ThemeTokens.canvas(this.currentTheme))
          .borderRadius(8)
      }
      .width('100%')

      Text(group.subtitle)
        .fontSize(12)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .lineHeight(18)
        .margin({ top: 6 })

      if (group.schedules.length === 0) {
        Text('暂无安排')
          .fontSize(12)
          .fontColor(ThemeTokens.secondary(this.currentTheme))
          .padding({ left: 12, right: 12, top: 14, bottom: 14 })
          .width('100%')
          .backgroundColor(ThemeTokens.canvas(this.currentTheme))
          .borderRadius(10)
          .margin({ top: 12 })
      } else {
        ForEach(group.schedules, (schedule: Schedule) => {
          this.ScheduleItem(schedule, group.color)
        }, (schedule: Schedule) => schedule.id)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(ThemeTokens.elevated(this.currentTheme))
    .borderRadius(18)
    .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
    .shadow({ radius: 22, color: ThemeTokens.cardShadow(this.currentTheme), offsetX: 0, offsetY: 10 })
    .margin({ top: 12 })
  }

  @Builder
  ScheduleItem(schedule: Schedule, color: string) {
    Column() {
      Row() {
        Text()
          .width(4)
          .height(54)
          .backgroundColor(color)
          .borderRadius(2)
          .margin({ right: 12 })

        Column() {
          Text(schedule.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`${this.getScheduleDateText(schedule)} · ${this.getScheduleTimeText(schedule)} · ${schedule.estimatedTime}m${this.getTaskStepSummary(schedule).length > 0 ? ` · 子任务 ${this.getTaskStepSummary(schedule)}` : ''}`)
            .fontSize(11)
            .fontColor(ThemeTokens.muted(this.currentTheme))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.getPriorityLabel(schedule.priority))
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 5, bottom: 5 })
          .backgroundColor(this.getPriorityColor(schedule.priority))
          .borderRadius(7)
      }
      .width('100%')

      if (this.getTaskNote(schedule).length > 0) {
        Text(this.getTaskNote(schedule))
          .fontSize(12)
          .fontColor('#607385')
          .lineHeight(18)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .backgroundColor(ThemeTokens.canvas(this.currentTheme))
          .borderRadius(8)
          .margin({ top: 8, left: 16 })
      }

      if (this.getTaskSteps(schedule).length > 0) {
        Row() {
          ForEach(this.getTaskSteps(schedule).slice(0, 2), (step: TaskStep) => {
            this.TaskStepChip(schedule.taskId, step)
          }, (step: TaskStep) => step.id)
        }
        .width('100%')
        .margin({ top: 8, left: 16 })
      }

      Row() {
        Button('编辑')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#256D85')
          .height(34)
          .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
          .borderRadius(9)
          .layoutWeight(1)
          .onClick(() => {
            this.openScheduleEditor(schedule);
          })

        Button('移到今天')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .height(34)
          .backgroundColor('#256D85')
          .borderRadius(9)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.moveToToday(schedule);
          })

        Button('退回收集箱')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#607385')
          .height(34)
          .backgroundColor(ThemeTokens.subtle(this.currentTheme))
          .borderRadius(9)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.sendBackToInbox(schedule);
          })
      }
      .width('100%')
      .margin({ top: 10, left: 16 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  TaskStepChip(taskId: string, step: TaskStep) {
    Row() {
      Text(step.completed ? '✓' : '')
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(18)
        .height(18)
        .textAlign(TextAlign.Center)
        .backgroundColor(step.completed ? '#46AFA5' : ThemeTokens.hairline(this.currentTheme))
        .borderRadius(9)
        .margin({ right: 6 })

      Text(step.title)
        .fontSize(10)
        .fontColor(step.completed ? ThemeTokens.secondary(this.currentTheme) : ThemeTokens.text(this.currentTheme))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .layoutWeight(1)
    .height(30)
    .padding({ left: 8, right: 8 })
    .backgroundColor(ThemeTokens.canvas(this.currentTheme))
    .borderRadius(8)
    .margin({ right: 8 })
    .onClick(() => {
      this.toggleTaskStep(taskId, step.id);
    })
  }

  @Builder
  EmptyState() {
    if (this.schedules.length === 0) {
      Column() {
        Text('还没有未来安排')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.text(this.currentTheme))

        Text(this.getEmptyHint())
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .lineHeight(18)
          .margin({ top: 8 })

        Row() {
          Button('去收集')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .height(40)
            .backgroundColor('#256D85')
            .borderRadius(10)
            .layoutWeight(1)
            .onClick(() => {
              this.navigateTo('pages/InboxPage');
            })

          Button('去规划')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#256D85')
            .height(40)
            .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
            .borderRadius(10)
            .layoutWeight(1)
            .margin({ left: 10 })
            .onClick(() => {
              this.navigateTo('pages/PlanPage');
            })
        }
        .width('100%')
        .margin({ top: 14 })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 18, right: 18, top: 18, bottom: 18 })
      .backgroundColor(ThemeTokens.elevated(this.currentTheme))
      .borderRadius(18)
      .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
      .shadow({ radius: 22, color: ThemeTokens.cardShadow(this.currentTheme), offsetX: 0, offsetY: 10 })
      .margin({ top: 12 })
    }
  }

  @Builder
  EditPriorityChip(priority: Priority) {
    Text(this.getPriorityLabel(priority))
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.editPriority === priority ? '#FFFFFF' : this.getPriorityColor(priority))
      .height(34)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .backgroundColor(this.editPriority === priority ? this.getPriorityColor(priority) : ThemeTokens.subtle(this.currentTheme))
      .borderRadius(9)
      .margin({ right: 8 })
      .onClick(() => {
        this.editPriority = priority;
      })
  }

  @Builder
  EditingStepRow(step: TaskStep) {
    Row() {
      Text(step.completed ? '✓' : '')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(22)
        .height(22)
        .textAlign(TextAlign.Center)
        .backgroundColor(step.completed ? '#46AFA5' : ThemeTokens.hairline(this.currentTheme))
        .borderRadius(11)
        .margin({ right: 10 })
        .onClick(() => {
          this.toggleEditingTaskStep(step.id);
        })

      Text(step.title)
        .fontSize(13)
        .fontColor(step.completed ? ThemeTokens.secondary(this.currentTheme) : ThemeTokens.text(this.currentTheme))
        .decoration({ type: step.completed ? TextDecorationType.LineThrough : TextDecorationType.None })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Text('删除')
        .fontSize(11)
        .fontColor('#6F7F88')
        .padding({ left: 8, right: 8, top: 5, bottom: 5 })
        .backgroundColor(ThemeTokens.slateWash(this.currentTheme))
        .borderRadius(8)
        .onClick(() => {
          this.deleteEditingTaskStep(step.id);
        })
    }
    .width('100%')
    .padding({ left: 10, right: 8, top: 8, bottom: 8 })
    .backgroundColor(ThemeTokens.canvas(this.currentTheme))
    .borderRadius(10)
    .margin({ top: 8 })
  }

  @Builder
  TaskDepthEditorSection(emptyText: string) {
    Column() {
      Row() {
        Column() {
          Text('任务细节')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))

          Text(this.getEditingDepthHint())
            .fontSize(11)
            .fontColor(ThemeTokens.muted(this.currentTheme))
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button(this.showTaskDepthEditor ? '收起' : '展开')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#256D85')
          .height(32)
          .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
          .borderRadius(8)
          .onClick(() => {
            this.showTaskDepthEditor = !this.showTaskDepthEditor;
          })
      }
      .width('100%')

      if (this.showTaskDepthEditor) {
        TextArea({ placeholder: '备注、背景或下一步', text: this.editTaskNote })
          .width('100%')
          .height(70)
          .backgroundColor(ThemeTokens.surface(this.currentTheme))
          .borderRadius(10)
          .margin({ top: 12 })
          .onChange((value: string) => {
            this.editTaskNote = value;
          })

        Text('优先级')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .margin({ top: 14, bottom: 8 })

        Row() {
          this.EditPriorityChip('P0')
          this.EditPriorityChip('P1')
          this.EditPriorityChip('P2')
        }
        .width('100%')

        Row() {
          Text('子任务')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
            .layoutWeight(1)

          Text(this.getEditingStepSummary())
            .fontSize(12)
            .fontColor('#607385')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(ThemeTokens.surface(this.currentTheme))
            .borderRadius(8)
        }
        .width('100%')
        .margin({ top: 16 })

        if (this.editTaskSteps.length === 0) {
          Text(emptyText)
            .fontSize(12)
            .fontColor(ThemeTokens.secondary(this.currentTheme))
            .lineHeight(18)
            .margin({ top: 8 })
        } else {
          ForEach(this.editTaskSteps, (step: TaskStep) => {
            this.EditingStepRow(step)
          }, (step: TaskStep) => step.id)
        }

        Row() {
          TextInput({ placeholder: '添加一个子任务', text: this.editNewStepTitle })
            .height(40)
            .layoutWeight(1)
            .fontColor(ThemeTokens.text(this.currentTheme))
            .placeholderColor(ThemeTokens.secondary(this.currentTheme))
            .backgroundColor(ThemeTokens.surface(this.currentTheme))
            .borderRadius(10)
            .onChange((value: string) => {
              this.editNewStepTitle = value;
            })

          Button('添加')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .width(66)
            .height(40)
            .backgroundColor(this.editNewStepTitle.trim().length > 0 ? '#256D85' : '#A8B2B6')
            .borderRadius(10)
            .margin({ left: 10 })
            .onClick(() => {
              this.addEditingTaskStep();
            })
        }
        .width('100%')
        .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .backgroundColor(ThemeTokens.subtle(this.currentTheme))
    .borderRadius(12)
    .margin({ top: 12 })
  }

  @Builder
  ScheduleEditorSheet() {
    Column() {
      Row() {
        Column() {
          Text('编辑未来安排')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
          Text('调整日期、结束时间和预计时长，让未来安排保持清楚。')
            .fontSize(12)
            .fontColor(ThemeTokens.muted(this.currentTheme))
            .lineHeight(18)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('关闭')
          .fontSize(12)
          .fontColor('#607385')
          .backgroundColor(ThemeTokens.subtle(this.currentTheme))
          .borderRadius(9)
          .height(34)
          .onClick(() => {
            this.closeScheduleEditor();
          })
      }
      .width('100%')

      TextInput({ placeholder: '安排标题', text: this.editTitle })
        .width('100%')
        .height(46)
        .fontColor(ThemeTokens.text(this.currentTheme))
        .placeholderColor(ThemeTokens.secondary(this.currentTheme))
        .backgroundColor(ThemeTokens.canvas(this.currentTheme))
        .borderRadius(10)
        .margin({ top: 16 })
        .onChange((value: string) => {
          this.editTitle = value;
        })

      this.TaskDepthEditorSection('可以提前把未来任务拆成执行步骤，到了当天会自动带到今天。')

      Row() {
        Text('预计时长')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .layoutWeight(1)

        Button('-10')
          .fontSize(12)
          .fontColor('#256D85')
          .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
          .borderRadius(8)
          .height(34)
          .onClick(() => {
            this.adjustEditDuration(-10);
          })

        TextInput({ text: this.editDuration.toString() })
          .type(InputType.Number)
          .width(72)
          .height(34)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .textAlign(TextAlign.Center)
          .backgroundColor(ThemeTokens.canvas(this.currentTheme))
          .borderRadius(8)
          .margin({ left: 8, right: 8 })
          .onChange((value: string) => {
            this.setEditDuration(value);
          })

        Button('+10')
          .fontSize(12)
          .fontColor('#256D85')
          .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
          .borderRadius(8)
          .height(34)
          .onClick(() => {
            this.adjustEditDuration(10);
          })
      }
      .width('100%')
      .margin({ top: 14 })

      Text('日期')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeTokens.text(this.currentTheme))
        .margin({ top: 16, bottom: 8 })

      DatePicker({ start: this.getPickerStartDate(), end: this.getPickerEndDate(), selected: this.getEditSelectedDate() })
        .width('100%')
        .height(118)
        .backgroundColor(ThemeTokens.canvas(this.currentTheme))
        .borderRadius(10)
        .onDateChange((value: Date) => {
          this.applyEditDate(value);
        })
      .width('100%')

      Text('结束时间')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeTokens.text(this.currentTheme))
        .margin({ top: 8, bottom: 8 })

      TimePicker({ selected: this.getEditSelectedTime(), format: TimePickerFormat.HOUR_MINUTE })
        .width('100%')
        .height(112)
        .backgroundColor(ThemeTokens.canvas(this.currentTheme))
        .borderRadius(10)
        .onChange((value: TimePickerResult) => {
          this.applyEditTime(value);
        })
      .width('100%')

      TextArea({ placeholder: '变更备注，例如：改到周五上午处理', text: this.editChangeNote })
        .width('100%')
        .height(70)
        .backgroundColor(ThemeTokens.canvas(this.currentTheme))
        .borderRadius(10)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.editChangeNote = value;
        })

      Row() {
        Button('删除安排')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6F7F88')
          .height(40)
          .backgroundColor(ThemeTokens.slateWash(this.currentTheme))
          .borderRadius(10)
          .layoutWeight(1)
          .onClick(() => {
            this.deleteEditingSchedule();
          })

        Button('保存修改')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .height(40)
          .backgroundColor('#256D85')
          .borderRadius(10)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.saveScheduleEdit();
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 22 })
    .backgroundColor(ThemeTokens.surface(this.currentTheme))
    .borderRadius(22)
    .shadow({ radius: 24, color: '#22182126', offsetX: 0, offsetY: -8 })
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        Scroll() {
          Column() {
            this.SummaryBand()
            this.EmptyState()
            ForEach(this.getGroups(), (group: UpcomingGroup) => {
              this.GroupPanel(group)
            }, (group: UpcomingGroup) => group.title)
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 24 })
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeTokens.canvas(this.currentTheme))

      if (this.showScheduleEditor) {
        Column() {
          Blank()
          Scroll() {
            this.ScheduleEditorSheet()
          }
          .width('100%')
          .height('92%')
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#66182126')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.canvas(this.currentTheme))
  }
}

@Entry
@Component
struct UpcomingPageEntry {
  build() {
    Column() {
      UpcomingPage()
    }
    .width('100%')
    .height('100%')
  }
}
