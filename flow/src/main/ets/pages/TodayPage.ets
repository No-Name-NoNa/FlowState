/**
 * Timeline-first Today surface.
 */

import { DataManager } from '../utils/DataManager';
import { NavigationManager } from '../utils/NavigationManager';
import { PickerDateTime } from '../utils/PickerDateTime';
import { RoutineEngine } from '../utils/RoutineEngine';
import { TimeFormatter } from '../utils/TimeFormatter';
import { ThemeContext } from '../utils/ThemeContext';
import { ThemeTokens } from '../utils/ThemeTokens';
import { ScheduleAnalyzer, ScheduleConflict } from '../utils/ScheduleAnalyzer';
import { TaskDepthUtils } from '../utils/TaskDepthUtils';
import { Priority, RoutineTemplate, Schedule, ScheduleArchiveEntry, ScheduleChange, ScheduleChangeType, Task, TaskStep, ThemeConfig } from '../models/DataModels';

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
export struct TodayPage {
  @State tasks: Task[] = [];
  @State schedules: Schedule[] = [];
  @State tomorrowSchedules: Schedule[] = [];
  @State inboxTasks: Task[] = [];
  @State availableRoutineTemplates: RoutineTemplate[] = [];
  @State routineFeedbackText: string = '';
  @State nextSchedule: Schedule | null = null;
  @State plannedMinutes: number = 0;
  @State completedCount: number = 0;
  @State focusMinutes: number = 0;
  @State missedCount: number = 0;
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
  @State dailyCapacityMinutes: number = 300;
  @State conflicts: ScheduleConflict[] = [];
  @StorageLink(ThemeContext.getThemeLink()) currentTheme: ThemeConfig = ThemeContext.getCurrentTheme();

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    const settings = await DataManager.getUserSettings();
    this.dailyCapacityMinutes = settings.dailyCapacityMinutes || 300;
    this.tasks = await DataManager.getAllTasks();
    const allSchedules = await DataManager.getAllSchedules();
    this.focusMinutes = await DataManager.getTodayTotalFocusTime();
    this.completedCount = await DataManager.getTodayCompletedCount();

    this.inboxTasks = [];
    for (let task of this.tasks) {
      const taskSchedules = await DataManager.getTaskSchedules(task.id);
      task.schedules = taskSchedules;
      if (taskSchedules.length === 0) {
        this.inboxTasks.push(task);
      }
    }

    this.schedules = this.getSchedulesForDay(allSchedules, 0);
    this.tomorrowSchedules = this.getSchedulesForDay(allSchedules, 1);
    this.availableRoutineTemplates = RoutineEngine.getAvailableTemplates(this.schedules);
    this.conflicts = ScheduleAnalyzer.getConflicts(this.schedules);
    this.plannedMinutes = 0;
    for (let schedule of this.schedules) {
      this.plannedMinutes += schedule.estimatedTime;
    }
    this.missedCount = this.getMissedSchedules().length;
    this.nextSchedule = this.getNextSchedule();
  }

  getSchedulesForDay(source: Schedule[], dayOffset: number): Schedule[] {
    const day = new Date();
    day.setHours(0, 0, 0, 0);
    day.setDate(day.getDate() + dayOffset);
    const start = day.getTime();
    const end = start + 24 * 60 * 60 * 1000;
    const result: Schedule[] = [];
    for (let schedule of source) {
      const due = this.getScheduleDueAt(schedule);
      if (due >= start && due < end) {
        result.push(schedule);
      }
    }
    result.sort((a: Schedule, b: Schedule) => this.getScheduleDueAt(a) - this.getScheduleDueAt(b));
    return result;
  }

  getNextSchedule(): Schedule | null {
    const now = Date.now();
    for (let schedule of this.schedules) {
      if (this.isScheduleActive(schedule) && this.getScheduleDueAt(schedule) >= now) {
        return schedule;
      }
    }
    return null;
  }

  isScheduleActive(schedule: Schedule): boolean {
    return schedule.state !== 'completed' && schedule.state !== 'cancelled' && schedule.state !== 'deferred';
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

  getScheduleStartAt(schedule: Schedule): number {
    return this.getScheduleDueAt(schedule) - schedule.estimatedTime * 60 * 1000;
  }

  getScheduleStartText(schedule: Schedule): string {
    return TimeFormatter.formatTime(this.getScheduleStartAt(schedule));
  }

  getScheduleEndText(schedule: Schedule): string {
    return TimeFormatter.formatTime(this.getScheduleDueAt(schedule));
  }

  getTaskTitle(taskId: string): string {
    for (let task of this.tasks) {
      if (task.id === taskId) return task.title;
    }
    return '未归类';
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

  getBlockColor(schedule: Schedule): string {
    if (schedule.priority === 'P0') return '#2F6F86';
    if (schedule.priority === 'P1') return '#58B7AE';
    const palette: string[] = ['#256D85', '#46AFA5', '#7BAE7F', '#8A7CC3', '#607385'];
    const index = Math.abs(schedule.title.length + schedule.estimatedTime) % palette.length;
    return palette[index];
  }

  getCapacityText(): string {
    const target = this.getDailyCapacity();
    if (this.plannedMinutes > target) {
      return `超出 ${this.plannedMinutes - target} 分钟`;
    }
    return `还可安排 ${target - this.plannedMinutes} 分钟`;
  }

  getWorkloadPercent(): number {
    const value = Math.round(this.plannedMinutes * 100 / this.getDailyCapacity());
    if (value > 100) return 100;
    return value;
  }

  getDailyCapacity(): number {
    return this.dailyCapacityMinutes > 0 ? this.dailyCapacityMinutes : 300;
  }

  isOverCapacity(): boolean {
    return this.plannedMinutes > this.getDailyCapacity();
  }

  isScheduleInConflict(schedule: Schedule): boolean {
    for (let conflict of this.conflicts) {
      if (conflict.firstId === schedule.id || conflict.secondId === schedule.id) {
        return true;
      }
    }
    return false;
  }

  getNextActionAccentColor(): string {
    if (this.nextSchedule) return this.getBlockColor(this.nextSchedule);
    if (this.schedules.length > 0) return '#6E7F89';
    if (this.inboxTasks.length > 0) return '#256D85';
    return '#46AFA5';
  }

  getNextActionKicker(): string {
    if (this.nextSchedule) return '下一段';
    if (this.schedules.length > 0) return '今天已无后续块';
    if (this.inboxTasks.length > 0) return '待安排';
    return '从这里开始';
  }

  getNextActionTitle(): string {
    if (this.nextSchedule) return this.nextSchedule.title;
    if (this.schedules.length > 0) return '复盘一下今天的节奏';
    if (this.inboxTasks.length > 0) return `收集箱有 ${this.inboxTasks.length} 个待安排`;
    return '先收集一个任务';
  }

  getNextActionSubtitle(): string {
    if (this.nextSchedule) return `${this.getScheduleStartText(this.nextSchedule)}-${this.getScheduleEndText(this.nextSchedule)} · ${this.nextSchedule.estimatedTime} 分钟`;
    if (this.schedules.length > 0) return '今天结束了，复盘一下节奏。';
    if (this.inboxTasks.length > 0) return '把待办放进时间线，今天就能开始。';
    return '先写下一件事，再安排时间。';
  }

  getNextActionButtonLabel(): string {
    if (this.nextSchedule) return '开始';
    if (this.schedules.length > 0) return '复盘';
    if (this.inboxTasks.length > 0) return '安排';
    return '收集';
  }

  runNextAction() {
    if (this.nextSchedule) {
      NavigationManager.push(this.getUIContext(), 'pages/FocusPage', {
        duration: this.nextSchedule.estimatedTime,
        scheduleId: this.nextSchedule.id,
        taskId: this.nextSchedule.taskId
      });
      return;
    }

    if (this.schedules.length > 0) {
      NavigationManager.openMainTab('pages/ReviewPage');
      return;
    }

    NavigationManager.openMainTab('pages/InboxPage');
  }

  getScheduleById(scheduleId: string): Schedule | null {
    for (let schedule of this.schedules) {
      if (schedule.id === scheduleId) return schedule;
    }
    return null;
  }

  openFirstConflictSchedule() {
    if (this.conflicts.length === 0) return;
    const conflict = this.conflicts[0];
    const target = this.getScheduleById(conflict.secondId) || this.getScheduleById(conflict.firstId);
    if (target) {
      this.openScheduleEditor(target);
    }
  }

  getEditConflictText(): string {
    if (!this.editingSchedule) return '';
    const candidateEnd = this.buildDueAt(this.editDate, this.editTime);
    const candidateStart = candidateEnd - this.getSafeEditDuration() * 60 * 1000;

    for (let schedule of this.schedules) {
      if (schedule.id === this.editingSchedule.id || !ScheduleAnalyzer.isActiveForPlanning(schedule)) {
        continue;
      }
      const start = this.getScheduleStartAt(schedule);
      const end = this.getScheduleDueAt(schedule);
      const overlapStart = Math.max(candidateStart, start);
      const overlapEnd = Math.min(candidateEnd, end);
      if (overlapStart < overlapEnd) {
        const minutes = Math.max(1, Math.round((overlapEnd - overlapStart) / 60000));
        return `将与「${schedule.title}」重叠 ${minutes} 分钟`;
      }
    }
    return '';
  }

  isScheduleOngoing(schedule: Schedule): boolean {
    const now = Date.now();
    return now >= this.getScheduleStartAt(schedule) && now <= this.getScheduleDueAt(schedule);
  }

  getScheduleStatusText(schedule: Schedule): string {
    if (schedule.state === 'completed') return '已完成';
    if (schedule.state === 'deferred') return '已顺延';
    if (schedule.state === 'cancelled') return '已取消';
    if (this.isScheduleInConflict(schedule)) return '时间冲突';
    if (this.isScheduleOngoing(schedule)) return '进行中';
    if (this.isScheduleMissed(schedule)) return '已错过';
    if (Date.now() > this.getScheduleDueAt(schedule)) return '已结束';
    return '待开始';
  }

  getScheduleStatusColor(schedule: Schedule): string {
    if (schedule.state === 'completed') return '#7BAE7F';
    if (schedule.state === 'deferred') return '#8A7CC3';
    if (schedule.state === 'cancelled') return ThemeTokens.secondary(this.currentTheme);
    if (this.isScheduleInConflict(schedule)) return '#6F7F88';
    if (this.isScheduleOngoing(schedule)) return '#46AFA5';
    if (this.isScheduleMissed(schedule)) return '#6F7F88';
    if (Date.now() > this.getScheduleDueAt(schedule)) return ThemeTokens.secondary(this.currentTheme);
    return this.getBlockColor(schedule);
  }

  getScheduleCardBackground(schedule: Schedule): string {
    if (schedule.state === 'completed') return ThemeTokens.greenWash(this.currentTheme);
    if (this.isScheduleInConflict(schedule) || this.isScheduleMissed(schedule)) return ThemeTokens.slateWash(this.currentTheme);
    if (this.isScheduleOngoing(schedule)) return ThemeTokens.tealWash(this.currentTheme);
    return ThemeTokens.paperInset(this.currentTheme);
  }

  isScheduleMissed(schedule: Schedule): boolean {
    return this.isScheduleActive(schedule) && this.getScheduleDueAt(schedule) < Date.now();
  }

  getMissedSchedules(): Schedule[] {
    const missed: Schedule[] = [];
    for (let schedule of this.schedules) {
      if (this.isScheduleMissed(schedule)) {
        missed.push(schedule);
      }
    }
    return missed;
  }

  shouldShowNowBefore(schedule: Schedule, index: number): boolean {
    const now = Date.now();
    if (this.schedules.length === 0) return false;
    if (index === 0) {
      return now <= this.getScheduleDueAt(schedule);
    }
    const previous = this.schedules[index - 1];
    return now > this.getScheduleDueAt(previous) && now <= this.getScheduleDueAt(schedule);
  }

  shouldShowNowAfterAll(): boolean {
    if (this.schedules.length === 0) return false;
    const last = this.schedules[this.schedules.length - 1];
    return Date.now() > this.getScheduleDueAt(last);
  }

  getGapAfter(schedule: Schedule, index: number): number {
    if (index >= this.schedules.length - 1) return 0;
    const next = this.schedules[index + 1];
    const gap = Math.round((this.getScheduleStartAt(next) - this.getScheduleDueAt(schedule)) / 60000);
    return gap > 0 ? gap : 0;
  }

  openScheduleEditor(schedule: Schedule) {
    const due = this.getScheduleDueAt(schedule);
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

  setEditDueAt(timestamp: number) {
    const date = new Date(timestamp);
    const day = new Date(timestamp);
    day.setHours(0, 0, 0, 0);
    this.editDate = day.getTime();
    this.editTime = `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
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

  getChangeFallbackNote(type: ScheduleChangeType): string {
    if (type === 'delay') return '推迟时间块';
    if (type === 'advance') return '提前时间块';
    if (type === 'delete') return '删除时间块';
    if (type === 'complete') return '完成时间块';
    if (type === 'carryover') return '结转到明天';
    return '调整时间块';
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

    const fromDueAt = this.getScheduleDueAt(this.editingSchedule);
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
      deferredAt: type === 'delay' ? Date.now() : this.editingSchedule.deferredAt,
      cancelledAt: this.editingSchedule.cancelledAt,
      actualMinutes: this.editingSchedule.actualMinutes,
      stateNote: this.editingSchedule.stateNote,
      routineId: this.editingSchedule.routineId
    };

    await this.saveEditingTaskDepth();
    await DataManager.saveSchedule(updated);
    this.closeScheduleEditor();
    await this.loadData();
  }

  buildScheduleArchiveEntry(schedule: Schedule, reason: ScheduleChangeType): ScheduleArchiveEntry {
    return {
      id: `archive_${Date.now()}`,
      scheduleId: schedule.id,
      taskId: schedule.taskId,
      title: schedule.title,
      estimatedTime: schedule.estimatedTime,
      priority: schedule.priority,
      scheduledDate: schedule.scheduledDate,
      scheduledTime: schedule.scheduledTime,
      dueAt: this.getScheduleDueAt(schedule),
      archivedAt: Date.now(),
      reason,
      note: this.editChangeNote.trim(),
      changeHistory: schedule.changeHistory || []
    };
  }

  async completeEditingSchedule() {
    if (!this.editingSchedule) return;
    const fromDueAt = this.getScheduleDueAt(this.editingSchedule);
    const history: ScheduleChange[] = [];
    for (let item of this.editingSchedule.changeHistory || []) {
      history.push(item);
    }
    history.push(this.buildChangeRecord('complete', fromDueAt, fromDueAt, this.editingSchedule.estimatedTime, this.getSafeEditDuration()));

    const updated: Schedule = {
      id: this.editingSchedule.id,
      taskId: this.editingSchedule.taskId,
      title: this.editTitle.trim().length > 0 ? this.editTitle.trim() : this.editingSchedule.title,
      estimatedTime: this.getSafeEditDuration(),
      priority: this.editPriority,
      scheduledDate: this.editingSchedule.scheduledDate,
      scheduledTime: this.editingSchedule.scheduledTime,
      dueAt: this.editingSchedule.dueAt,
      reminderMinutes: this.editingSchedule.reminderMinutes,
      createdAt: this.editingSchedule.createdAt,
      stats: this.editingSchedule.stats,
      changeHistory: history,
      state: 'completed',
      completedAt: Date.now(),
      deferredAt: this.editingSchedule.deferredAt,
      cancelledAt: this.editingSchedule.cancelledAt,
      actualMinutes: this.getSafeEditDuration(),
      stateNote: this.editChangeNote.trim(),
      routineId: this.editingSchedule.routineId
    };

    await this.saveEditingTaskDepth();
    await DataManager.saveSchedule(updated);
    this.closeScheduleEditor();
    await this.loadData();
  }

  async quickMoveEditingSchedule(minutes: number, note: string, type: ScheduleChangeType) {
    if (!this.editingSchedule) return;
    const target = this.buildDueAt(this.editDate, this.editTime) + minutes * 60 * 1000;
    this.setEditDueAt(target);
    if (this.editChangeNote.trim().length === 0) {
      this.editChangeNote = note;
    }
    await this.saveScheduleEdit(type);
  }

  async moveEditingScheduleToTomorrow() {
    if (!this.editingSchedule) return;
    const target = new Date();
    target.setDate(target.getDate() + 1);
    target.setHours(9, 0, 0, 0);
    this.setEditDueAt(target.getTime());
    if (this.editChangeNote.trim().length === 0) {
      this.editChangeNote = '移到明天上午';
    }
    await this.saveScheduleEdit('delay');
  }

  async deleteEditingSchedule() {
    if (!this.editingSchedule) return;
    await DataManager.saveScheduleArchiveEntry(this.buildScheduleArchiveEntry(this.editingSchedule, 'delete'));
    await DataManager.deleteSchedule(this.editingSchedule.id);
    this.closeScheduleEditor();
    await this.loadData();
  }

  getTomorrowDate(): number {
    const tomorrow = new Date();
    tomorrow.setHours(0, 0, 0, 0);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow.getTime();
  }

  getCarryOverTime(index: number): string {
    let hour = 9 + index;
    if (hour > 21) hour = 21;
    return `${String(hour).padStart(2, '0')}:00`;
  }

  buildCarryOverChange(schedule: Schedule, toDueAt: number): ScheduleChange {
    return {
      id: `change_${Date.now()}_${schedule.id}`,
      type: 'carryover',
      timestamp: Date.now(),
      note: '结转到明天',
      fromDueAt: this.getScheduleDueAt(schedule),
      toDueAt,
      fromDuration: schedule.estimatedTime,
      toDuration: schedule.estimatedTime
    };
  }

  async carryOverMissedSchedules() {
    const missed = this.getMissedSchedules();
    const tomorrow = this.getTomorrowDate();
    for (let i = 0; i < missed.length; i++) {
      const schedule = missed[i];
      const scheduledTime = this.getCarryOverTime(i);
      const toDueAt = this.buildDueAt(tomorrow, scheduledTime);
      const change = this.buildCarryOverChange(schedule, toDueAt);
      const history: ScheduleChange[] = [];
      for (let item of schedule.changeHistory || []) {
        history.push(item);
      }
      history.push(change);

      const deferred: Schedule = {
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
        state: 'deferred',
        completedAt: schedule.completedAt,
        deferredAt: Date.now(),
        cancelledAt: schedule.cancelledAt,
        actualMinutes: schedule.actualMinutes,
        stateNote: '已结转到明天',
        routineId: schedule.routineId
      };

      const carried: Schedule = {
        id: `schedule_${Date.now()}_${i}`,
        taskId: schedule.taskId,
        title: schedule.title,
        estimatedTime: schedule.estimatedTime,
        priority: schedule.priority,
        scheduledDate: tomorrow,
        scheduledTime,
        dueAt: toDueAt,
        reminderMinutes: schedule.reminderMinutes,
        createdAt: Date.now(),
        stats: schedule.stats,
        changeHistory: [change],
        state: 'planned',
        stateNote: '从昨天结转',
        routineId: schedule.routineId
      };

      await DataManager.saveSchedule(deferred);
      await DataManager.saveSchedule(carried);
    }
    await this.loadData();
  }

  getTodayDate(): number {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return today.getTime();
  }

  shouldShowRoutineStrip(): boolean {
    return this.availableRoutineTemplates.length > 0 && this.schedules.length <= 4;
  }

  async addRoutineTemplate(template: RoutineTemplate) {
    if (RoutineEngine.isTemplateScheduled(template, this.schedules)) {
      this.routineFeedbackText = `${template.title} 今天已经有了`;
      return;
    }
    const task = RoutineEngine.buildTask(template);
    const schedule = RoutineEngine.buildSchedule(template, task.id, this.getTodayDate());
    await DataManager.saveTask(task);
    await DataManager.saveSchedule(schedule);
    this.routineFeedbackText = `已加入今天：${template.title}`;
    await this.loadData();
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

  @Builder
  Header() {
    Row() {
      Column() {
        Text('今天')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTheme.textColor)

        Text(`${TimeFormatter.formatDate(Date.now())} · ${TimeFormatter.getWeekdayName(Date.now())} · 把任务排进时间线，一段一段执行`)
          .fontSize(11)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button() {
        SymbolGlyph($r('sys.symbol.gearshape'))
          .fontSize(22)
          .fontColor([this.currentTheme.primaryColor])
      }
      .width(44)
      .height(44)
      .borderRadius(10)
      .backgroundColor(this.currentTheme.cardColor)
      .onClick(() => {
        NavigationManager.push(this.getUIContext(), 'pages/SettingsPage');
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 8 })
  }

  @Builder
  WorkloadBand() {
    Column() {
      Text()
        .width(46)
        .height(3)
        .borderRadius(2)
        .backgroundColor(this.isOverCapacity() ? '#6F7F88' : '#46AFA5')
        .margin({ bottom: 14 })

      Row() {
        Column() {
          Text('今日负荷')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#607385')

          Text(`${this.plannedMinutes} 分钟已规划`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.getCapacityText())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isOverCapacity() ? '#6F7F88' : '#256D85')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.isOverCapacity() ? '#EEF2F3' : ThemeTokens.selectedSurface(this.currentTheme))
          .borderRadius(8)
      }
      .width('100%')

      Progress({ value: this.getWorkloadPercent(), total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(6)
        .color(this.isOverCapacity() ? '#6F7F88' : '#46AFA5')
        .backgroundColor(ThemeTokens.hairline(this.currentTheme))
        .margin({ top: 14 })

      Row() {
        this.Metric(`${this.schedules.length}`, '时间块')
        this.Metric(`${this.inboxTasks.length}`, '收集箱')
        this.Metric(`${this.completedCount}`, '完成')
        this.Metric(TimeFormatter.formatHours(this.focusMinutes), '专注h')
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(ThemeTokens.paper(this.currentTheme))
    .borderRadius(18)
    .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
    .shadow({ radius: 26, color: ThemeTokens.paperShadow(this.currentTheme), offsetX: 0, offsetY: 12 })
  }

  @Builder
  ConflictBanner() {
    if (this.conflicts.length > 0) {
      Column() {
        Row() {
          Text()
            .width(4)
            .height(48)
            .borderRadius(2)
            .backgroundColor('#6F7F88')
            .margin({ right: 12 })

          Column() {
            Text(`${this.conflicts.length} 处时间冲突`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeTokens.text(this.currentTheme))
            Text(`${TimeFormatter.formatTime(this.conflicts[0].startAt)}-${TimeFormatter.formatTime(this.conflicts[0].endAt)} · ${this.conflicts[0].firstTitle} / ${this.conflicts[0].secondTitle}`)
              .fontSize(12)
              .fontColor(ThemeTokens.muted(this.currentTheme))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        Button('调整冲突块')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .height(38)
          .width('100%')
          .backgroundColor('#6F7F88')
          .borderRadius(10)
          .margin({ top: 14 })
          .onClick(() => {
            this.openFirstConflictSchedule();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor(ThemeTokens.paper(this.currentTheme))
      .borderRadius(18)
      .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
      .shadow({ radius: 24, color: ThemeTokens.paperShadow(this.currentTheme), offsetX: 0, offsetY: 11 })
      .margin({ top: 12 })
    }
  }

  @Builder
  StartGuide() {
    if (this.schedules.length === 0) {
      Column() {
        Text('今日起步')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.text(this.currentTheme))

        Text('这个应用的核心不是清单，而是把事情放进今天的时间线。')
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .lineHeight(18)
          .margin({ top: 6 })

        Row() {
          this.GuideStep('1', '收集', '先写下来', '#8A7CC3')
          this.GuideStep('2', '安排', '放进时间', '#256D85')
          this.GuideStep('3', '专注', '开始下一段', '#46AFA5')
        }
        .width('100%')
        .margin({ top: 14 })

        Row() {
          Button(this.inboxTasks.length > 0 ? '去安排收集箱' : '收集第一个任务')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .height(40)
            .backgroundColor('#256D85')
            .borderRadius(10)
            .layoutWeight(1)
            .onClick(() => {
              NavigationManager.openMainTab('pages/InboxPage');
            })

          Button('自动规划')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#256D85')
            .height(40)
            .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
            .borderRadius(10)
            .layoutWeight(1)
            .margin({ left: 10 })
            .onClick(() => {
              NavigationManager.openMainTab('pages/PlanPage');
            })
        }
        .width('100%')
        .margin({ top: 14 })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 18, right: 18, top: 18, bottom: 18 })
      .backgroundColor(ThemeTokens.paper(this.currentTheme))
      .borderRadius(18)
      .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
      .shadow({ radius: 24, color: ThemeTokens.paperShadow(this.currentTheme), offsetX: 0, offsetY: 11 })
      .margin({ top: 12 })
    }
  }

  @Builder
  RoutineStrip() {
    if (this.shouldShowRoutineStrip()) {
      Column() {
        Row() {
          Column() {
            Text('常用模板')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeTokens.text(this.currentTheme))

            Text('一键加入今天，适合每天重复的小块。')
              .fontSize(12)
              .fontColor(ThemeTokens.muted(this.currentTheme))
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text(`${this.availableRoutineTemplates.length} 个可用`)
            .fontSize(11)
            .fontColor('#7BAE7F')
            .padding({ left: 9, right: 9, top: 5, bottom: 5 })
            .backgroundColor('#EEF5EF')
            .borderRadius(8)
        }
        .width('100%')

        ForEach(this.availableRoutineTemplates.slice(0, 3), (template: RoutineTemplate) => {
          this.RoutineTemplateRow(template)
        }, (template: RoutineTemplate) => template.id)

        if (this.routineFeedbackText.length > 0) {
          Text(this.routineFeedbackText)
            .fontSize(12)
            .fontColor('#256D85')
            .margin({ top: 8 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor(ThemeTokens.paper(this.currentTheme))
      .borderRadius(18)
      .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
      .shadow({ radius: 24, color: ThemeTokens.paperShadow(this.currentTheme), offsetX: 0, offsetY: 11 })
      .margin({ top: 12 })
    }
  }

  @Builder
  RoutineTemplateRow(template: RoutineTemplate) {
    Row() {
      Text()
        .width(4)
        .height(44)
        .borderRadius(2)
        .backgroundColor(template.color)
        .margin({ right: 10 })

      Column() {
        Text(template.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${template.scheduledTime} · ${template.estimatedTime} 分钟 · ${template.description}`)
          .fontSize(11)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button('加入')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .height(34)
        .backgroundColor('#256D85')
        .borderRadius(9)
        .padding({ left: 13, right: 13 })
        .onClick(() => {
          this.addRoutineTemplate(template);
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 10 })
    .border({ width: { bottom: 1 }, color: '#EEF2F1' })
  }

  @Builder
  GuideStep(index: string, title: string, subtitle: string, color: string) {
    Column() {
      Text(index)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(26)
        .height(26)
        .textAlign(TextAlign.Center)
        .backgroundColor(color)
        .borderRadius(13)

      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.text(this.currentTheme))
        .margin({ top: 8 })

      Text(subtitle)
        .fontSize(10)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .margin({ top: 3 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding({ left: 12, right: 10, top: 12, bottom: 12 })
    .backgroundColor(ThemeTokens.paperInset(this.currentTheme))
    .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
    .borderRadius(12)
    .margin({ right: 8 })
  }

  @Builder
  Metric(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.text(this.currentTheme))
      Text(label)
        .fontSize(10)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding({ left: 10, right: 10, top: 9, bottom: 9 })
    .backgroundColor(ThemeTokens.paperInset(this.currentTheme))
    .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
    .borderRadius(12)
    .shadow({ radius: 10, color: ThemeTokens.paperThinShadow(this.currentTheme), offsetX: 0, offsetY: 4 })
    .margin({ right: 7 })
  }

  @Builder
  NextAction() {
    Row() {
      Text()
        .width(5)
        .height(62)
        .borderRadius(4)
        .backgroundColor(this.getNextActionAccentColor())
        .margin({ right: 14 })

      Column() {
        Text(this.getNextActionKicker())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeTokens.muted(this.currentTheme))

        Text(this.getNextActionTitle())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })

        Text(this.getNextActionSubtitle())
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button(this.getNextActionButtonLabel())
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.schedules.length > 0 && !this.nextSchedule ? '#315B66' : ThemeTokens.onPrimary(this.currentTheme))
        .width(82)
        .height(44)
        .borderRadius(16)
        .backgroundColor(this.schedules.length > 0 && !this.nextSchedule ? '#E5EEF1' : this.getNextActionAccentColor())
        .border({ width: 1, color: this.schedules.length > 0 && !this.nextSchedule ? '#CCDBDF' : this.getNextActionAccentColor() })
        .shadow({ radius: 12, color: ThemeTokens.paperThinShadow(this.currentTheme), offsetX: 0, offsetY: 5 })
        .onClick(() => {
          this.runNextAction();
        })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(ThemeTokens.paper(this.currentTheme))
    .borderRadius(20)
    .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
    .shadow({ radius: 28, color: ThemeTokens.paperShadow(this.currentTheme), offsetX: 0, offsetY: 12 })
    .margin({ top: 12 })
  }

  @Builder
  ReplanBanner() {
    if (this.missedCount > 0) {
      Column() {
        Row() {
          Text()
            .width(4)
            .height(48)
            .borderRadius(2)
            .backgroundColor('#6F7F88')
            .margin({ right: 12 })

          Column() {
            Text(`${this.missedCount} 个时间块已错过`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeTokens.text(this.currentTheme))
            Text('把它们结转到明天，今天的时间线会保留顺延记录。')
              .fontSize(12)
              .fontColor(ThemeTokens.muted(this.currentTheme))
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Button('结转到明天')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .height(38)
            .backgroundColor('#6F7F88')
            .borderRadius(10)
            .layoutWeight(1)
            .onClick(() => {
              this.carryOverMissedSchedules();
            })

          Button('先复盘')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#6F7F88')
            .height(38)
            .backgroundColor(ThemeTokens.slateWash(this.currentTheme))
            .borderRadius(10)
            .layoutWeight(1)
            .margin({ left: 10 })
            .onClick(() => {
              NavigationManager.openMainTab('pages/ReviewPage');
            })
        }
        .width('100%')
        .margin({ top: 14 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor(ThemeTokens.paper(this.currentTheme))
      .borderRadius(18)
      .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
      .shadow({ radius: 24, color: ThemeTokens.paperShadow(this.currentTheme), offsetX: 0, offsetY: 11 })
      .margin({ top: 12 })
    }
  }

  @Builder
  Timeline() {
    Column() {
      Text()
        .width(44)
        .height(3)
        .borderRadius(2)
        .backgroundColor('#256D85')
        .margin({ bottom: 14 })

      Row() {
        Text('时间线')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .layoutWeight(1)

        Text(this.schedules.length === 0 ? '未规划' : `${this.schedules.length} 段`)
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
      }
      .width('100%')
      .margin({ bottom: 10 })

      if (this.schedules.length === 0) {
        this.EmptyTimeline()
      } else {
        ForEach(this.schedules, (schedule: Schedule, index: number) => {
          if (this.shouldShowNowBefore(schedule, index)) {
            this.NowIndicator()
          }
          this.TimelineBlock(schedule)
          if (this.getGapAfter(schedule, index) >= 20) {
            this.FreeSpaceRow(this.getGapAfter(schedule, index))
          }
        }, (schedule: Schedule) => schedule.id)
        if (this.shouldShowNowAfterAll()) {
          this.NowIndicator()
        }
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(ThemeTokens.paper(this.currentTheme))
    .borderRadius(18)
    .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
    .shadow({ radius: 26, color: ThemeTokens.paperShadow(this.currentTheme), offsetX: 0, offsetY: 12 })
    .margin({ top: 12 })
  }

  @Builder
  NowIndicator() {
    Row() {
      Text(TimeFormatter.formatTime(Date.now()))
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor('#6F7F88')
        .width(48)

      Text()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor('#6F7F88')
        .margin({ left: 9, right: 13 })

      Row() {
        Text()
          .height(1)
          .layoutWeight(1)
          .backgroundColor('#F0C2BA')
        Text('现在')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6F7F88')
          .margin({ left: 8 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: 8, bottom: 6 })
  }

  @Builder
  FreeSpaceRow(minutes: number) {
    Row() {
      Text('')
        .width(48)

      Text()
        .width(1)
        .height(34)
        .backgroundColor(ThemeTokens.hairline(this.currentTheme))
        .margin({ left: 13, right: 17 })

      Row() {
        Text(`空档 ${minutes} 分钟`)
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .layoutWeight(1)

        Button('安排')
          .fontSize(11)
          .fontColor('#256D85')
          .backgroundColor(ThemeTokens.surface(this.currentTheme))
          .borderRadius(8)
          .height(28)
          .onClick(() => {
            NavigationManager.openMainTab('pages/InboxPage');
          })
      }
      .layoutWeight(1)
      .padding({ left: 12, right: 10, top: 8, bottom: 8 })
      .backgroundColor(ThemeTokens.paperSoft(this.currentTheme))
      .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
      .borderRadius(12)
    }
    .width('100%')
    .margin({ top: 4, bottom: 4 })
  }

  @Builder
  TimelineBlock(schedule: Schedule) {
    Row() {
      Column() {
        Text(this.getScheduleStartText(schedule))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.text(this.currentTheme))
        Text(this.getScheduleEndText(schedule))
          .fontSize(10)
          .fontColor(ThemeTokens.secondary(this.currentTheme))
          .margin({ top: 4 })
      }
      .width(48)
      .alignItems(HorizontalAlign.Start)

      Column() {
        Text()
          .width(10)
          .height(10)
          .borderRadius(5)
          .backgroundColor(this.getScheduleStatusColor(schedule))
          .margin({ top: 4 })
        Text()
          .width(1)
          .height(54)
          .backgroundColor(ThemeTokens.hairline(this.currentTheme))
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ left: 8, right: 12 })

      Column() {
        Row() {
          Text(schedule.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text(this.getScheduleStatusText(schedule))
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getScheduleStatusColor(schedule))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(ThemeTokens.surface(this.currentTheme))
            .borderRadius(7)
        }
        .width('100%')

        Text(`${this.getTaskTitle(schedule.taskId)} · ${schedule.estimatedTime} 分钟${this.getTaskStepSummary(schedule).length > 0 ? ` · 子任务 ${this.getTaskStepSummary(schedule)}` : ''}`)
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .margin({ top: 6 })

        if (this.getTaskNote(schedule).length > 0) {
          Text(this.getTaskNote(schedule))
            .fontSize(12)
            .fontColor('#607385')
            .lineHeight(18)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .padding({ left: 10, right: 10, top: 8, bottom: 8 })
            .backgroundColor(ThemeTokens.surface(this.currentTheme))
            .borderRadius(8)
            .margin({ top: 8 })
        }

        if (this.getTaskSteps(schedule).length > 0) {
          Row() {
            ForEach(this.getTaskSteps(schedule).slice(0, 2), (step: TaskStep) => {
              this.TaskStepChip(schedule.taskId, step)
            }, (step: TaskStep) => step.id)
          }
          .width('100%')
          .margin({ top: 8 })
        }

        Row() {
          Button('编辑')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#256D85')
            .height(32)
            .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
            .borderRadius(8)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.openScheduleEditor(schedule);
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .backgroundColor(this.getScheduleCardBackground(schedule))
      .borderRadius(14)
      .border({ width: 1, color: this.isScheduleOngoing(schedule) || schedule.state === 'completed' || this.isScheduleInConflict(schedule) ? this.getScheduleStatusColor(schedule) : ThemeTokens.paperBorder(this.currentTheme) })
      .shadow({ radius: 12, color: ThemeTokens.paperThinShadow(this.currentTheme), offsetX: 0, offsetY: 5 })
    }
    .width('100%')
    .margin({ top: 8 })
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
    .backgroundColor(ThemeTokens.paper(this.currentTheme))
    .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
    .borderRadius(9)
    .margin({ right: 8 })
    .onClick(() => {
      this.toggleTaskStep(taskId, step.id);
    })
  }

  @Builder
  EmptyTimeline() {
    Column() {
      Text('今天还是空的')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.text(this.currentTheme))

      Text('先把一个收集箱任务安排进时间线，今天就有了起点。')
        .fontSize(12)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .margin({ top: 6 })

      Button('去收集箱安排')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .height(38)
        .borderRadius(10)
        .backgroundColor('#256D85')
        .margin({ top: 14 })
        .onClick(() => {
          NavigationManager.openMainTab('pages/InboxPage');
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 14, right: 14, top: 18, bottom: 18 })
    .backgroundColor(ThemeTokens.paperInset(this.currentTheme))
    .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
    .borderRadius(14)
  }

  @Builder
  InboxStrip() {
    Column() {
      Row() {
        Text('收集箱')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .layoutWeight(1)

        Text(`${this.inboxTasks.length} 个未安排`)
          .fontSize(12)
          .fontColor('#8A7CC3')
      }
      .width('100%')

      if (this.inboxTasks.length === 0) {
        Text('没有待整理的想法。')
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .margin({ top: 10 })
      } else {
        ForEach(this.inboxTasks.slice(0, 3), (task: Task) => {
          Row() {
            Text()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor('#8A7CC3')
              .margin({ right: 10 })

            Text(task.title)
              .fontSize(13)
              .fontColor(ThemeTokens.text(this.currentTheme))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ top: 10 })
          .onClick(() => {
            NavigationManager.openMainTab('pages/InboxPage');
          })
        }, (task: Task) => task.id)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(ThemeTokens.paper(this.currentTheme))
    .borderRadius(18)
    .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
    .shadow({ radius: 24, color: ThemeTokens.paperShadow(this.currentTheme), offsetX: 0, offsetY: 11 })
    .margin({ top: 12, bottom: 24 })
  }

  @Builder
  TomorrowPreview() {
    if (this.tomorrowSchedules.length > 0) {
      Column() {
        Row() {
          Text('明天预备')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
            .layoutWeight(1)

          Text(`${this.tomorrowSchedules.length} 个时间块`)
            .fontSize(12)
            .fontColor('#8A7CC3')
        }
        .width('100%')

        Text('从收集箱点“明天”的任务会先放在这里，明天打开后进入今天时间线。')
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .lineHeight(18)
          .margin({ top: 8 })

        ForEach(this.tomorrowSchedules.slice(0, 3), (schedule: Schedule) => {
          Row() {
            Text(schedule.scheduledTime || '09:00')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#8A7CC3')
              .width(48)

            Text(schedule.title)
              .fontSize(13)
              .fontColor(ThemeTokens.text(this.currentTheme))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            Text(`${schedule.estimatedTime}m`)
              .fontSize(11)
              .fontColor(ThemeTokens.muted(this.currentTheme))
          }
          .width('100%')
          .margin({ top: 10 })
        }, (schedule: Schedule) => schedule.id)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 18, right: 18, top: 18, bottom: 18 })
      .backgroundColor(ThemeTokens.paper(this.currentTheme))
      .borderRadius(18)
      .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
      .shadow({ radius: 24, color: ThemeTokens.paperShadow(this.currentTheme), offsetX: 0, offsetY: 11 })
      .margin({ top: 12 })
    }
  }

  @Builder
  DateChip(option: DateOption) {
    Column() {
      Text(option.label)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.editDate === option.value ? '#FFFFFF' : ThemeTokens.text(this.currentTheme))
      Text(option.subLabel)
        .fontSize(10)
        .fontColor(this.editDate === option.value ? '#EAF8F8' : ThemeTokens.muted(this.currentTheme))
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
    .width(54)
    .padding({ top: 8, bottom: 8 })
    .backgroundColor(this.editDate === option.value ? '#256D85' : ThemeTokens.subtle(this.currentTheme))
    .borderRadius(10)
    .margin({ right: 8, bottom: 8 })
    .onClick(() => {
      this.editDate = option.value;
    })
  }

  @Builder
  TimeChip(option: TimeOption) {
    Text(option.label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.editTime === option.value ? '#FFFFFF' : ThemeTokens.text(this.currentTheme))
      .padding({ left: 12, right: 12, top: 9, bottom: 9 })
      .backgroundColor(this.editTime === option.value ? '#256D85' : ThemeTokens.subtle(this.currentTheme))
      .borderRadius(10)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.editTime = option.value;
      })
  }

  @Builder
  EditPriorityChip(priority: Priority) {
    Text(this.getPriorityLabel(priority))
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.editPriority === priority ? '#FFFFFF' : this.getPriorityColor(priority))
      .width(86)
      .height(38)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.editPriority === priority ? this.getPriorityColor(priority) : ThemeTokens.subtle(this.currentTheme))
      .borderRadius(18)
      .border({ width: 1, color: this.editPriority === priority ? this.getPriorityColor(priority) : ThemeTokens.cardBorder(this.currentTheme) })
      .margin({ left: 4, right: 4 })
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
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
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
    .padding({ left: 12, right: 10, top: 10, bottom: 10 })
    .backgroundColor(ThemeTokens.elevated(this.currentTheme))
    .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
    .borderRadius(14)
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
          .height(78)
          .fontSize(14)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .backgroundColor(ThemeTokens.elevated(this.currentTheme))
          .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
          .borderRadius(16)
          .margin({ top: 12 })
          .onChange((value: string) => {
            this.editTaskNote = value;
          })

        Text('优先级')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 14, bottom: 8 })

        Row() {
          this.EditPriorityChip('P0')
          this.EditPriorityChip('P1')
          this.EditPriorityChip('P2')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

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
            .padding({ left: 12, right: 12, top: 11, bottom: 11 })
            .backgroundColor(ThemeTokens.elevated(this.currentTheme))
            .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
            .borderRadius(14)
            .margin({ top: 10 })
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
  EditScheduleTimePicker() {
    Column() {
      Row() {
        Column() {
          Text('安排时间')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
          Text('选择日期和结束时间，开始点会由时长自动推算')
            .fontSize(11)
            .fontColor(ThemeTokens.muted(this.currentTheme))
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(`${TimeFormatter.formatDate(this.editDate)} · ${this.editTime}`)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#256D85')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
          .borderRadius(12)
      }
      .width('100%')

      Text('日期')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .margin({ top: 14, bottom: 6 })

      DatePicker({ start: this.getPickerStartDate(), end: this.getPickerEndDate(), selected: this.getEditSelectedDate() })
        .width('100%')
        .height(104)
        .backgroundColor(ThemeTokens.elevated(this.currentTheme))
        .borderRadius(14)
        .onDateChange((value: Date) => {
          this.applyEditDate(value);
        })

      Text('结束时间')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .margin({ top: 12, bottom: 6 })

      TimePicker({ selected: this.getEditSelectedTime(), format: TimePickerFormat.HOUR_MINUTE })
        .width('100%')
        .height(100)
        .backgroundColor(ThemeTokens.elevated(this.currentTheme))
        .borderRadius(14)
        .onChange((value: TimePickerResult) => {
          this.applyEditTime(value);
        })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .backgroundColor(ThemeTokens.mist(this.currentTheme))
    .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
    .borderRadius(18)
    .margin({ top: 14 })
  }

  @Builder
  ScheduleEditorSheet() {
    Column() {
      Row() {
        Column() {
          Text('调整时间块')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
          Text('修改时间、时长或把这一段顺延到更合适的位置')
            .fontSize(12)
            .fontColor(ThemeTokens.muted(this.currentTheme))
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

      TextInput({ placeholder: '时间块标题', text: this.editTitle })
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeTokens.text(this.currentTheme))
        .placeholderColor(ThemeTokens.secondary(this.currentTheme))
        .backgroundColor(ThemeTokens.mist(this.currentTheme))
        .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
        .borderRadius(16)
        .margin({ top: 16 })
        .onChange((value: string) => {
          this.editTitle = value;
        })

      this.TaskDepthEditorSection('可以把这一段拆成几个执行步骤，专注时更容易进入状态。')

      Row() {
        Text('时长')
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

        Text('分钟')
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ top: 14 })

      this.EditScheduleTimePicker()
      if (this.getEditConflictText().length > 0) {
        Row() {
          Text()
            .width(4)
            .height(38)
            .borderRadius(2)
            .backgroundColor('#6F7F88')
            .margin({ right: 10 })

          Text(this.getEditConflictText())
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#6F7F88')
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(ThemeTokens.slateWash(this.currentTheme))
        .borderRadius(10)
        .margin({ top: 8 })
      }

      TextArea({ placeholder: '变更备注，例如：等资料到了再做', text: this.editChangeNote })
        .width('100%')
        .height(76)
        .fontSize(14)
        .fontColor(ThemeTokens.text(this.currentTheme))
        .backgroundColor(ThemeTokens.mist(this.currentTheme))
        .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
        .borderRadius(16)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.editChangeNote = value;
        })

      Button('标记完成')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#315B66')
        .height(44)
        .width('100%')
        .borderRadius(18)
        .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
        .backgroundColor(ThemeTokens.mist(this.currentTheme))
        .margin({ top: 14 })
        .onClick(() => {
          this.completeEditingSchedule();
        })

      Row() {
        Button('提前15分钟')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#256D85')
          .backgroundColor(ThemeTokens.mist(this.currentTheme))
          .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
          .borderRadius(16)
          .height(40)
          .layoutWeight(1)
          .onClick(() => {
            this.quickMoveEditingSchedule(-15, '提前15分钟', 'advance');
          })

        Button('推迟30分钟')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#256D85')
          .backgroundColor(ThemeTokens.mist(this.currentTheme))
          .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
          .borderRadius(16)
          .height(40)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.quickMoveEditingSchedule(30, '推迟30分钟', 'delay');
          })
      }
      .width('100%')
      .margin({ top: 12 })

      Row() {
        Button('明天 09:00')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#256D85')
          .backgroundColor(ThemeTokens.mist(this.currentTheme))
          .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
          .borderRadius(16)
          .height(40)
          .layoutWeight(1)
          .onClick(() => {
            this.moveEditingScheduleToTomorrow();
          })

        Button('删除')
          .fontSize(12)
          .fontColor('#6F7F88')
          .backgroundColor(ThemeTokens.slateWash(this.currentTheme))
          .borderRadius(16)
          .height(40)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.deleteEditingSchedule();
          })
      }
      .width('100%')
      .margin({ top: 10 })

      Button('保存调整')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .height(48)
        .width('100%')
        .borderRadius(18)
        .backgroundColor('#256D85')
        .margin({ top: 14 })
        .onClick(() => {
          this.saveScheduleEdit('edit');
        })
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
            this.WorkloadBand()
            this.StartGuide()
            this.RoutineStrip()
            this.ConflictBanner()
            this.NextAction()
            this.ReplanBanner()
            this.Timeline()
            this.TomorrowPreview()
            this.InboxStrip()
          }
          .padding({ left: 16, right: 16, top: 8 })
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.currentTheme.backgroundColor)

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
    .backgroundColor(this.currentTheme.backgroundColor)
  }
}

@Entry
@Component
struct TodayPageEntry {
  build() {
    Column() {
      TodayPage()
    }
    .width('100%')
    .height('100%')
  }
}
