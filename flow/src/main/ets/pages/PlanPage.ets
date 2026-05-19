/**
 * Guided planning ritual surface.
 */

import { DataManager } from '../utils/DataManager';
import { NavigationManager } from '../utils/NavigationManager';
import { TimeFormatter } from '../utils/TimeFormatter';
import { ThemeContext } from '../utils/ThemeContext';
import { ThemeTokens } from '../utils/ThemeTokens';
import { ScheduleAnalyzer, ScheduleConflict } from '../utils/ScheduleAnalyzer';
import { AutoPlanner, AutoPlanResult, AutoPlanSuggestion } from '../utils/AutoPlanner';
import { Schedule, ScheduleChange, Task, ThemeConfig } from '../models/DataModels';

interface PlanningStep {
  title: string;
  description: string;
  accent: string;
}

@Component
export struct PlanPage {
  @StorageLink(ThemeContext.getThemeLink()) currentTheme: ThemeConfig = ThemeContext.getCurrentTheme();
  @State tasks: Task[] = [];
  @State inboxTasks: Task[] = [];
  @State todaySchedules: Schedule[] = [];
  @State carryOverSchedules: Schedule[] = [];
  @State futureCandidateSchedules: Schedule[] = [];
  @State inboxCount: number = 0;
  @State plannedMinutes: number = 0;
  @State tomorrowCarryOverMinutes: number = 0;
  @State activeStep: number = 1;
  @State lastScheduledTitle: string = '';
  @State lastAppliedScheduleId: string = '';
  @State planFeedbackText: string = '';
  @State dailyCapacityMinutes: number = 300;
  @State defaultFocusMinutes: number = 25;
  @State conflicts: ScheduleConflict[] = [];
  @State autoPlanSuggestions: AutoPlanSuggestion[] = [];
  @State autoPlanSkippedCount: number = 0;
  @State autoPlanMinutes: number = 0;
  @State autoPlanRemainingMinutes: number = 0;
  @State autoPlanRemainingAfterMinutes: number = 0;
  @State selectedAutoPlanTaskIds: string[] = [];
  @State unselectedAutoPlanTaskIds: string[] = [];
  @State excludedAutoPlanTaskIds: string[] = [];

  private readonly steps: PlanningStep[] = [
    { title: '回看', description: '知其所来，方知所往。', accent: '#607385' },
    { title: '选择', description: '取其要者，先入今日。', accent: '#8A7CC3' },
    { title: '估算', description: '留有余地，方能从容。', accent: '#8EA1AE' },
    { title: '排序', description: '事有先后，行有节奏。', accent: '#46AFA5' },
    { title: '开始', description: '定下一段，即刻前行。', accent: '#256D85' }
  ];

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    const settings = await DataManager.getUserSettings();
    this.dailyCapacityMinutes = settings.dailyCapacityMinutes || 300;
    this.defaultFocusMinutes = settings.defaultFocusTime || 25;
    this.tasks = await DataManager.getAllTasks();
    const allSchedules = await DataManager.getAllSchedules();
    this.todaySchedules = [];
    this.carryOverSchedules = [];
    this.futureCandidateSchedules = [];
    this.inboxTasks = [];
    this.inboxCount = 0;
    this.plannedMinutes = 0;
    this.tomorrowCarryOverMinutes = 0;
    this.conflicts = [];
    this.autoPlanSuggestions = [];
    this.autoPlanSkippedCount = 0;
    this.autoPlanMinutes = 0;
    this.autoPlanRemainingMinutes = 0;
    this.autoPlanRemainingAfterMinutes = 0;

    for (let task of this.tasks) {
      const schedules = await DataManager.getTaskSchedules(task.id);
      task.schedules = schedules;
      if (schedules.length === 0) {
        this.inboxTasks.push(task);
      }
    }
    this.inboxTasks.sort((a: Task, b: Task) => this.getPriorityRank(a.priority) - this.getPriorityRank(b.priority));
    this.inboxCount = this.inboxTasks.length;

    const range = this.getTodayRange();
    const tomorrowRange = this.getTomorrowRange();
    const weekRange = this.getWeekCandidateRange();
    for (let schedule of allSchedules) {
      const due = this.getScheduleDueAt(schedule);
      if (due >= range[0] && due < range[1] && schedule.state !== 'cancelled') {
        this.todaySchedules.push(schedule);
        this.plannedMinutes += schedule.estimatedTime;
      }
      if (due >= tomorrowRange[0] && ScheduleAnalyzer.isActiveForPlanning(schedule)) {
        this.futureCandidateSchedules.push(schedule);
      }
      if (due >= tomorrowRange[0] && due < tomorrowRange[1] && this.isCarryOverSchedule(schedule)) {
        this.carryOverSchedules.push(schedule);
        this.tomorrowCarryOverMinutes += schedule.estimatedTime;
      }
    }
    this.todaySchedules.sort((a: Schedule, b: Schedule) => this.getScheduleDueAt(a) - this.getScheduleDueAt(b));
    this.futureCandidateSchedules.sort((a: Schedule, b: Schedule) => this.getScheduleDueAt(a) - this.getScheduleDueAt(b));
    this.conflicts = ScheduleAnalyzer.getConflicts(this.todaySchedules);
    this.carryOverSchedules.sort((a: Schedule, b: Schedule) => this.getScheduleDueAt(a) - this.getScheduleDueAt(b));
    this.refreshAutoPlan();
  }

  refreshAutoPlan() {
    const range = this.getTodayRange();
    const planningTasks: Task[] = [];
    const validInboxTaskIds: string[] = [];
    for (let task of this.inboxTasks) {
      validInboxTaskIds.push(task.id);
      if (!this.isAutoPlanExcluded(task.id)) {
        planningTasks.push(task);
      }
    }
    this.excludedAutoPlanTaskIds = this.keepKnownTaskIds(this.excludedAutoPlanTaskIds, validInboxTaskIds);
    this.unselectedAutoPlanTaskIds = this.keepKnownTaskIds(this.unselectedAutoPlanTaskIds, validInboxTaskIds);

    const result: AutoPlanResult = AutoPlanner.buildTodayPlan(
      planningTasks,
      this.todaySchedules,
      range[0],
      this.getDailyCapacity(),
      this.getDefaultFocusMinutes(),
      this.plannedMinutes,
      Date.now()
    );
    this.autoPlanSuggestions = result.suggestions;
    this.autoPlanSkippedCount = result.skippedCount + this.excludedAutoPlanTaskIds.length;
    this.autoPlanMinutes = result.plannedMinutes;
    this.autoPlanRemainingMinutes = result.remainingMinutes;
    this.autoPlanRemainingAfterMinutes = result.remainingAfterMinutes;
    this.syncAutoPlanSelection();
  }

  getTodayRange(): [number, number] {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return [today.getTime(), today.getTime() + 24 * 60 * 60 * 1000];
  }

  getTomorrowRange(): [number, number] {
    const tomorrow = new Date();
    tomorrow.setHours(0, 0, 0, 0);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return [tomorrow.getTime(), tomorrow.getTime() + 24 * 60 * 60 * 1000];
  }

  getWeekCandidateRange(): [number, number] {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    start.setDate(start.getDate() + 2);
    return [start.getTime(), start.getTime() + 6 * 24 * 60 * 60 * 1000];
  }

  getFutureSourceLabel(schedule: Schedule): string {
    const due = this.getScheduleDueAt(schedule);
    const tomorrowRange = this.getTomorrowRange();
    const weekRange = this.getWeekCandidateRange();
    if (due >= tomorrowRange[0] && due < tomorrowRange[1]) {
      return '明天';
    }
    if (due >= weekRange[0] && due < weekRange[1]) {
      return TimeFormatter.getWeekdayName(due);
    }
    return TimeFormatter.formatDate(due).slice(5);
  }

  getFutureSourceMeta(schedule: Schedule): string {
    return `${this.getFutureSourceLabel(schedule)} ${TimeFormatter.formatTime(this.getScheduleDueAt(schedule))} · ${schedule.estimatedTime}m · ${this.getPriorityLabel(schedule.priority)}`;
  }

  getSourcePanelHint(): string {
    if (this.inboxCount === 0 && this.futureCandidateSchedules.length === 0) {
      return '暂无可排之事。先写下一件，今日才有起点。';
    }
    if (this.futureCandidateSchedules.length > 0) {
      return '未来可前移，今日仍需轻。';
    }
    return '少排一分，多留一分从容。';
  }

  buildPlanMoveChange(schedule: Schedule, toDueAt: number): ScheduleChange {
    return {
      id: `change_${Date.now()}_${schedule.id}`,
      type: 'edit',
      timestamp: Date.now(),
      note: '从规划页移到今天',
      fromDueAt: this.getScheduleDueAt(schedule),
      toDueAt,
      fromDuration: schedule.estimatedTime,
      toDuration: schedule.estimatedTime
    };
  }

  async moveFutureScheduleToToday(schedule: Schedule) {
    const today = this.getTodayRange()[0];
    const time = this.getNextAvailableTime();
    const dueAt = this.buildDueAt(today, time);
    const history: ScheduleChange[] = [];
    for (let item of schedule.changeHistory || []) {
      history.push(item);
    }
    history.push(this.buildPlanMoveChange(schedule, dueAt));

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
      stateNote: '从规划页移到今天',
      routineId: schedule.routineId
    };
    await DataManager.saveSchedule(updated);
    this.lastScheduledTitle = schedule.title;
    this.lastAppliedScheduleId = schedule.id;
    this.planFeedbackText = `已移到今天：${schedule.title}`;
    this.activeStep = 5;
    await this.loadData();
  }

  isCarryOverSchedule(schedule: Schedule): boolean {
    if (schedule.stateNote === '从昨天结转') return true;
    for (let change of schedule.changeHistory || []) {
      if (change.type === 'carryover') return true;
    }
    return false;
  }

  getScheduleDueAt(schedule: Schedule): number {
    if (schedule.dueAt) return schedule.dueAt;
    const date = schedule.scheduledDate || new Date().setHours(0, 0, 0, 0);
    const time = schedule.scheduledTime || '09:00';
    return this.buildDueAt(date, time);
  }

  getScheduleStartAt(schedule: Schedule): number {
    return this.getScheduleDueAt(schedule) - schedule.estimatedTime * 60 * 1000;
  }

  getScheduleWindowText(schedule: Schedule): string {
    return `${TimeFormatter.formatTime(this.getScheduleStartAt(schedule))}-${TimeFormatter.formatTime(this.getScheduleDueAt(schedule))}`;
  }

  buildDueAt(date: number, time: string): number {
    const parts = time.split(':');
    const hour = parseInt(parts[0]) || 0;
    const minute = parseInt(parts[1]) || 0;
    const due = new Date(date);
    due.setHours(hour, minute, 0, 0);
    return due.getTime();
  }

  getPriorityRank(priority: string): number {
    if (priority === 'P0') return 0;
    if (priority === 'P1') return 1;
    return 2;
  }

  getPriorityLabel(priority: string): string {
    if (priority === 'P0') return '优先';
    if (priority === 'P1') return '重要';
    return '常规';
  }

  getWorkloadStatus(): string {
    if (this.conflicts.length > 0) return '存在时间冲突';
    if (this.plannedMinutes > this.getDailyCapacity()) return '今天已经超载';
    if (this.plannedMinutes > this.getNearCapacityThreshold()) return '计划接近上限';
    return '今天仍然留有余量';
  }

  getWorkloadColor(): string {
    if (this.conflicts.length > 0) return '#6F7F88';
    if (this.plannedMinutes > this.getDailyCapacity()) return '#6F7F88';
    if (this.plannedMinutes > this.getNearCapacityThreshold()) return '#8EA1AE';
    return '#46AFA5';
  }

  getWorkloadPercent(): number {
    const value = Math.round(this.plannedMinutes * 100 / this.getDailyCapacity());
    if (value > 100) return 100;
    return value;
  }

  getDailyCapacity(): number {
    return this.dailyCapacityMinutes > 0 ? this.dailyCapacityMinutes : 300;
  }

  getNearCapacityThreshold(): number {
    return Math.round(this.getDailyCapacity() * 0.7);
  }

  getDefaultFocusMinutes(): number {
    return this.defaultFocusMinutes > 0 ? this.defaultFocusMinutes : 25;
  }

  hasAutoPlanSuggestions(): boolean {
    return this.autoPlanSuggestions.length > 0 && this.conflicts.length === 0;
  }

  hasSelectedAutoPlanSuggestions(): boolean {
    return this.getSelectedAutoPlanCount() > 0 && this.conflicts.length === 0;
  }

  hasFutureCandidates(): boolean {
    return this.futureCandidateSchedules.length > 0;
  }

  getFirstFutureCandidate(): Schedule | null {
    return this.futureCandidateSchedules.length > 0 ? this.futureCandidateSchedules[0] : null;
  }

  keepKnownTaskIds(taskIds: string[], validTaskIds: string[]): string[] {
    const next: string[] = [];
    for (let taskId of taskIds) {
      if (validTaskIds.indexOf(taskId) >= 0 && next.indexOf(taskId) < 0) {
        next.push(taskId);
      }
    }
    return next;
  }

  isAutoPlanExcluded(taskId: string): boolean {
    return this.excludedAutoPlanTaskIds.indexOf(taskId) >= 0;
  }

  isSuggestionSelected(taskId: string): boolean {
    return this.selectedAutoPlanTaskIds.indexOf(taskId) >= 0;
  }

  syncAutoPlanSelection() {
    const suggestionIds: string[] = [];
    for (let suggestion of this.autoPlanSuggestions) {
      suggestionIds.push(suggestion.taskId);
    }
    this.unselectedAutoPlanTaskIds = this.keepKnownTaskIds(this.unselectedAutoPlanTaskIds, suggestionIds);

    const nextSelected: string[] = [];
    for (let suggestion of this.autoPlanSuggestions) {
      if (this.unselectedAutoPlanTaskIds.indexOf(suggestion.taskId) < 0) {
        nextSelected.push(suggestion.taskId);
      }
    }
    this.selectedAutoPlanTaskIds = nextSelected;
  }

  addTaskId(taskIds: string[], taskId: string): string[] {
    const next: string[] = [];
    for (let item of taskIds) {
      if (next.indexOf(item) < 0) {
        next.push(item);
      }
    }
    if (next.indexOf(taskId) < 0) {
      next.push(taskId);
    }
    return next;
  }

  removeTaskId(taskIds: string[], taskId: string): string[] {
    const next: string[] = [];
    for (let item of taskIds) {
      if (item !== taskId && next.indexOf(item) < 0) {
        next.push(item);
      }
    }
    return next;
  }

  toggleAutoPlanSelection(taskId: string) {
    this.planFeedbackText = '';
    if (this.isSuggestionSelected(taskId)) {
      this.selectedAutoPlanTaskIds = this.removeTaskId(this.selectedAutoPlanTaskIds, taskId);
      this.unselectedAutoPlanTaskIds = this.addTaskId(this.unselectedAutoPlanTaskIds, taskId);
      return;
    }
    this.selectedAutoPlanTaskIds = this.addTaskId(this.selectedAutoPlanTaskIds, taskId);
    this.unselectedAutoPlanTaskIds = this.removeTaskId(this.unselectedAutoPlanTaskIds, taskId);
  }

  selectAllAutoPlanSuggestions() {
    this.planFeedbackText = '';
    const selectedIds: string[] = [];
    for (let suggestion of this.autoPlanSuggestions) {
      selectedIds.push(suggestion.taskId);
    }
    this.selectedAutoPlanTaskIds = selectedIds;
    this.unselectedAutoPlanTaskIds = [];
  }

  excludeAutoPlanSuggestion(taskId: string) {
    this.planFeedbackText = '';
    this.excludedAutoPlanTaskIds = this.addTaskId(this.excludedAutoPlanTaskIds, taskId);
    this.selectedAutoPlanTaskIds = this.removeTaskId(this.selectedAutoPlanTaskIds, taskId);
    this.unselectedAutoPlanTaskIds = this.removeTaskId(this.unselectedAutoPlanTaskIds, taskId);
    this.refreshAutoPlan();
  }

  includeAutoPlanTask(taskId: string) {
    this.planFeedbackText = '';
    this.excludedAutoPlanTaskIds = this.removeTaskId(this.excludedAutoPlanTaskIds, taskId);
    this.refreshAutoPlan();
  }

  getTaskTitleById(taskId: string): string {
    for (let task of this.inboxTasks) {
      if (task.id === taskId) return task.title;
    }
    for (let task of this.tasks) {
      if (task.id === taskId) return task.title;
    }
    return '已排除任务';
  }

  getSelectedAutoPlanSuggestions(): AutoPlanSuggestion[] {
    const selected: AutoPlanSuggestion[] = [];
    for (let suggestion of this.autoPlanSuggestions) {
      if (this.isSuggestionSelected(suggestion.taskId)) {
        selected.push(suggestion);
      }
    }
    return selected;
  }

  getSelectedAutoPlanCount(): number {
    return this.getSelectedAutoPlanSuggestions().length;
  }

  getSelectedAutoPlanMinutes(): number {
    let minutes = 0;
    for (let suggestion of this.autoPlanSuggestions) {
      if (this.isSuggestionSelected(suggestion.taskId)) {
        minutes += suggestion.estimatedTime;
      }
    }
    return minutes;
  }

  getSelectedAutoPlanRemainingAfterMinutes(): number {
    const remaining = this.autoPlanRemainingMinutes - this.getSelectedAutoPlanMinutes();
    return remaining > 0 ? remaining : 0;
  }

  getFirstStartableSchedule(): Schedule | null {
    const now = Date.now();
    for (let schedule of this.todaySchedules) {
      if (ScheduleAnalyzer.isActiveForPlanning(schedule) && this.getScheduleDueAt(schedule) >= now) {
        return schedule;
      }
    }
    for (let schedule of this.todaySchedules) {
      if (ScheduleAnalyzer.isActiveForPlanning(schedule)) {
        return schedule;
      }
    }
    return null;
  }

  getHandoffSchedule(): Schedule | null {
    if (this.lastAppliedScheduleId.length > 0) {
      for (let schedule of this.todaySchedules) {
        if (schedule.id === this.lastAppliedScheduleId && ScheduleAnalyzer.isActiveForPlanning(schedule)) {
          return schedule;
        }
      }
    }
    return this.getFirstStartableSchedule();
  }

  getHandoffTitle(): string {
    const schedule = this.getHandoffSchedule();
    return schedule ? schedule.title : '今天已经排好';
  }

  getHandoffMeta(): string {
    const schedule = this.getHandoffSchedule();
    if (!schedule) return '回到今天，查看全局';
    return `${this.getScheduleWindowText(schedule)} · ${schedule.estimatedTime} 分钟 · ${this.getPriorityLabel(schedule.priority)}`;
  }

  getHandoffCopy(): string {
    const schedule = this.getHandoffSchedule();
    if (!schedule) return '计划已经生成，下一步回到今天检查完整顺序。';
    return '计划已落地，第一段可启程。';
  }

  startFocusFromPlan(schedule: Schedule) {
    NavigationManager.push(this.getUIContext(), 'pages/FocusPage', {
      duration: schedule.estimatedTime,
      scheduleId: schedule.id,
      taskId: schedule.taskId,
      autoStart: true
    });
  }

  getSuggestionIndex(taskId: string): number {
    for (let i = 0; i < this.autoPlanSuggestions.length; i++) {
      if (this.autoPlanSuggestions[i].taskId === taskId) {
        return i;
      }
    }
    return -1;
  }

  canMoveSuggestion(taskId: string, direction: number): boolean {
    const index = this.getSuggestionIndex(taskId);
    if (direction < 0) return index > 0;
    if (direction > 0) return index >= 0 && index < this.autoPlanSuggestions.length - 1;
    return false;
  }

  moveAutoPlanSuggestion(taskId: string, direction: number) {
    if (!this.canMoveSuggestion(taskId, direction)) {
      return;
    }
    const index = this.getSuggestionIndex(taskId);
    const targetIndex = index + direction;
    const ordered: AutoPlanSuggestion[] = [];
    for (let i = 0; i < this.autoPlanSuggestions.length; i++) {
      if (i === index) {
        ordered.push(this.autoPlanSuggestions[targetIndex]);
      } else if (i === targetIndex) {
        ordered.push(this.autoPlanSuggestions[index]);
      } else {
        ordered.push(this.autoPlanSuggestions[i]);
      }
    }
    this.applyReflowedSuggestions(ordered);
  }

  adjustAutoPlanDuration(taskId: string, delta: number) {
    const adjusted: AutoPlanSuggestion[] = [];
    for (let suggestion of this.autoPlanSuggestions) {
      let duration = suggestion.estimatedTime;
      if (suggestion.taskId === taskId) {
        duration += delta;
        if (duration < 15) duration = 15;
        if (duration > 180) duration = 180;
      }
      adjusted.push(this.copySuggestionWithDuration(suggestion, duration));
    }
    this.applyReflowedSuggestions(adjusted);
  }

  copySuggestionWithDuration(suggestion: AutoPlanSuggestion, duration: number): AutoPlanSuggestion {
    return {
      taskId: suggestion.taskId,
      title: suggestion.title,
      priority: suggestion.priority,
      estimatedTime: duration,
      scheduledDate: suggestion.scheduledDate,
      scheduledTime: suggestion.scheduledTime,
      dueAt: suggestion.dueAt,
      startAt: suggestion.startAt,
      endAt: suggestion.endAt,
      reason: suggestion.reason
    };
  }

  applyReflowedSuggestions(suggestions: AutoPlanSuggestion[]) {
    const range = this.getTodayRange();
    const reflowed = AutoPlanner.reflowTodaySuggestions(suggestions, this.todaySchedules, range[0], Date.now());
    if (reflowed.length === suggestions.length) {
      this.autoPlanSuggestions = reflowed;
      this.planFeedbackText = '节奏已重排';
      return;
    }
    this.planFeedbackText = '当前空档放不下这个调整';
  }

  getAutoPlanStatus(): string {
    if (this.conflicts.length > 0) return '先处理冲突';
    if (this.inboxTasks.length === 0 && this.hasFutureCandidates()) return '有未来事项';
    if (this.inboxTasks.length === 0) return '收集箱为空';
    if (this.excludedAutoPlanTaskIds.length === this.inboxTasks.length) return '已排除全部';
    if (this.autoPlanSuggestions.length === 0 && this.autoPlanRemainingMinutes <= 0) return '今日容量已满';
    if (this.autoPlanSuggestions.length === 0) return '没有可用时间段';
    return `已选 ${this.getSelectedAutoPlanCount()}/${this.autoPlanSuggestions.length} 项`;
  }

  getAutoPlanHint(): string {
    if (this.conflicts.length > 0) return '时段相叠，先理顺再前行。';
    if (this.inboxTasks.length === 0 && this.hasFutureCandidates()) return '收集箱已清，可从未来取一件入今日。';
    if (this.inboxTasks.length === 0) return '暂无待排之事，先收一念。';
    if (this.excludedAutoPlanTaskIds.length === this.inboxTasks.length) return '今日暂不承接，恢复一项即可继续。';
    if (this.autoPlanSuggestions.length === 0 && this.autoPlanRemainingMinutes <= 0) return `今日 ${this.getDailyCapacity()} 分钟已满，减一事，留一隙。`;
    if (this.autoPlanSuggestions.length === 0) return '有余量，但缺一段完整的空白。';
    if (this.getSelectedAutoPlanCount() === 0) return '择其合拍者入今日，其余暂且留后。';
    return `已定 ${this.getSelectedAutoPlanMinutes()} 分钟，仍余 ${this.getSelectedAutoPlanRemainingAfterMinutes()} 分钟可周转。`;
  }

  getAutoPlanStatusColor(): string {
    if (this.conflicts.length > 0) return '#6F7F88';
    if (this.getSelectedAutoPlanCount() > 0) return '#46AFA5';
    if (this.autoPlanSuggestions.length > 0) return '#8EA1AE';
    if (this.inboxTasks.length === 0 && this.hasFutureCandidates()) return '#256D85';
    return '#607385';
  }

  getAutoPlanActionLabel(): string {
    if (this.conflicts.length > 0) return '去今天调整';
    if (this.getSelectedAutoPlanCount() > 0) return `安排 ${this.getSelectedAutoPlanCount()} 项建议`;
    if (this.autoPlanSuggestions.length > 0) return '选择全部建议';
    if (this.inboxTasks.length === 0 && this.hasFutureCandidates()) return '移入首个未来事项';
    if (this.inboxTasks.length === 0) return '打开收集箱';
    return '查看时间线';
  }

  navigateTo(url: string) {
    if (!NavigationManager.openMainTab(url)) {
      NavigationManager.push(this.getUIContext(), url);
    }
  }

  async handleAutoPlanAction() {
    if (this.conflicts.length > 0) {
      this.navigateTo('pages/TodayPage');
      return;
    }
    if (this.autoPlanSuggestions.length > 0) {
      if (this.getSelectedAutoPlanCount() === 0) {
        this.selectAllAutoPlanSuggestions();
        return;
      }
      await this.applyAutoPlanSuggestions();
      return;
    }
    if (this.inboxTasks.length === 0 && this.hasFutureCandidates()) {
      const candidate = this.getFirstFutureCandidate();
      if (candidate) {
        await this.moveFutureScheduleToToday(candidate);
      }
      return;
    }
    if (this.inboxTasks.length === 0) {
      this.navigateTo('pages/InboxPage');
      return;
    }
    this.navigateTo('pages/TodayPage');
  }

  getCurrentStep(): PlanningStep {
    return this.steps[this.activeStep - 1];
  }

  getNextAvailableTime(): string {
    const now = new Date();
    let hour = now.getHours() + 1;
    if (hour < 9) hour = 9;

    if (this.todaySchedules.length > 0) {
      const lastDue = new Date(this.getScheduleDueAt(this.todaySchedules[this.todaySchedules.length - 1]));
      hour = lastDue.getHours() + 1;
    }

    if (hour > 21) hour = 21;
    return `${String(hour).padStart(2, '0')}:00`;
  }

  getPrimaryActionLabel(): string {
    if (this.activeStep === 1) return '查看复盘';
    if (this.activeStep === 2) return this.hasAutoPlanSuggestions() ? (this.getSelectedAutoPlanCount() > 0 ? `安排 ${this.getSelectedAutoPlanCount()} 项建议` : '选择全部建议') : (this.inboxTasks.length > 0 ? '安排一个任务' : (this.hasFutureCandidates() ? '移入未来事项' : '去收集箱'));
    if (this.activeStep === 3 && this.conflicts.length > 0) return '调整冲突';
    if (this.activeStep === 3) return '确认负荷';
    if (this.activeStep === 4) return '查看时间线';
    return this.getHandoffSchedule() ? '开始第一段' : '回到今天';
  }

  getSecondaryActionLabel(): string {
    if (this.activeStep === 1) return '下一步';
    if (this.activeStep === 2) return '打开收集箱';
    if (this.activeStep === 3) return '继续排序';
    if (this.activeStep === 4) return '下一步';
    return '回到今天';
  }

  async handlePrimaryAction() {
    if (this.activeStep === 1) {
      this.navigateTo('pages/ReviewPage');
      return;
    }
    if (this.activeStep === 2) {
      if (this.inboxTasks.length > 0) {
        if (this.hasSelectedAutoPlanSuggestions()) {
          await this.applyAutoPlanSuggestions();
        } else if (this.hasAutoPlanSuggestions()) {
          this.selectAllAutoPlanSuggestions();
        } else {
          await this.scheduleTopInboxTask();
        }
      } else if (this.hasFutureCandidates()) {
        const candidate = this.getFirstFutureCandidate();
        if (candidate) {
          await this.moveFutureScheduleToToday(candidate);
        }
      } else {
        this.navigateTo('pages/InboxPage');
      }
      return;
    }
    if (this.activeStep === 3) {
      if (this.conflicts.length > 0) {
        this.navigateTo('pages/TodayPage');
        return;
      }
      this.activeStep = 4;
      return;
    }
    if (this.activeStep === 4) {
      this.navigateTo('pages/TodayPage');
      return;
    }
    const handoff = this.getHandoffSchedule();
    if (handoff) {
      this.startFocusFromPlan(handoff);
      return;
    }
    this.navigateTo('pages/TodayPage');
  }

  handleSecondaryAction() {
    if (this.activeStep === 2) {
      this.navigateTo('pages/InboxPage');
      return;
    }
    if (this.activeStep < 5) {
      this.activeStep++;
      return;
    }
    this.navigateTo('pages/TodayPage');
  }

  async scheduleTopInboxTask() {
    if (this.inboxTasks.length === 0) return;
    const task = this.inboxTasks[0];
    const scheduledDate = this.getTodayRange()[0];
    const scheduledTime = this.getNextAvailableTime();
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
    this.lastScheduledTitle = task.title;
    this.lastAppliedScheduleId = schedule.id;
    this.planFeedbackText = '';
    this.activeStep = 5;
    await this.loadData();
  }

  async applyAutoPlanSuggestions() {
    if (this.conflicts.length > 0) {
      this.navigateTo('pages/TodayPage');
      return;
    }
    if (this.autoPlanSuggestions.length === 0) {
      if (this.inboxTasks.length > 0) {
        await this.scheduleTopInboxTask();
      } else {
        this.navigateTo('pages/InboxPage');
      }
      return;
    }

    const suggestions = this.getSelectedAutoPlanSuggestions();
    if (suggestions.length === 0) {
      this.selectAllAutoPlanSuggestions();
      return;
    }

    const now = Date.now();
    let firstScheduleId = '';
    for (let i = 0; i < suggestions.length; i++) {
      const suggestion = suggestions[i];
      const scheduleId = `schedule_${now}_${i}`;
      if (i === 0) {
        firstScheduleId = scheduleId;
      }
      const schedule: Schedule = {
        id: scheduleId,
        taskId: suggestion.taskId,
        title: suggestion.title,
        estimatedTime: suggestion.estimatedTime,
        priority: suggestion.priority,
        scheduledDate: suggestion.scheduledDate,
        scheduledTime: suggestion.scheduledTime,
        dueAt: suggestion.dueAt,
        reminderMinutes: -1,
        createdAt: now + i,
        stats: [0, 0, 0, 0, 0, 0],
        changeHistory: [],
        state: 'planned'
      };
      await DataManager.saveSchedule(schedule);
    }
    this.lastScheduledTitle = `已自动安排 ${suggestions.length} 个任务`;
    this.lastAppliedScheduleId = firstScheduleId;
    this.planFeedbackText = '';
    this.activeStep = 5;
    await this.loadData();
  }

  @Builder
  Header() {
    Column() {
      Text('规划')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.text(this.currentTheme))
        .textAlign(TextAlign.Center)
        .width('100%')

      Text('先定其序，再行其事。')
        .fontSize(12)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 4 })

      Text()
        .width(42)
        .height(3)
        .borderRadius(2)
        .backgroundColor(this.currentTheme.primaryColor)
        .opacity(0.72)
        .margin({ top: 10 })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 8 })
  }

  @Builder
  StepperPanel() {
    Column() {
      Row() {
        ForEach(this.steps, (step: PlanningStep, index: number) => {
          Text((index + 1).toString())
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.activeStep === index + 1 ? '#FFFFFF' : (this.activeStep > index + 1 ? step.accent : ThemeTokens.secondary(this.currentTheme)))
            .width(34)
            .height(34)
            .textAlign(TextAlign.Center)
            .backgroundColor(this.activeStep === index + 1 ? step.accent : ThemeTokens.subtle(this.currentTheme))
            .borderRadius(17)
            .border({ width: 1, color: this.activeStep === index + 1 ? step.accent : ThemeTokens.cardBorder(this.currentTheme) })
            .shadow({ radius: this.activeStep === index + 1 ? 12 : 0, color: ThemeTokens.paperThinShadow(this.currentTheme), offsetX: 0, offsetY: 5 })
            .margin({ right: 8 })
            .onClick(() => {
              this.activeStep = index + 1;
            })
        }, (step: PlanningStep) => step.title)
      }
      .width('100%')

      Text(this.getCurrentStep().title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.text(this.currentTheme))
        .margin({ top: 18 })

      Text(this.getCurrentStep().description)
        .fontSize(13)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .lineHeight(20)
        .margin({ top: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .backgroundColor(ThemeTokens.elevated(this.currentTheme))
    .borderRadius(24)
    .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
    .shadow({ radius: 32, color: ThemeTokens.cardShadow(this.currentTheme), offsetX: 0, offsetY: 15 })
  }

  @Builder
  WorkloadPanel() {
    Column() {
      Row() {
        Column() {
          Text('计划负荷')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#607385')

          Row() {
            Text(`${this.plannedMinutes}`)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeTokens.text(this.currentTheme))

            Text('分钟')
              .fontSize(13)
              .fontColor(ThemeTokens.muted(this.currentTheme))
              .margin({ left: 6, top: 14 })
          }
          .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.getWorkloadStatus())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getWorkloadColor())
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(ThemeTokens.canvas(this.currentTheme))
          .borderRadius(8)
      }
      .width('100%')

      Progress({ value: this.getWorkloadPercent(), total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(8)
        .color(this.getWorkloadColor())
        .backgroundColor(ThemeTokens.hairline(this.currentTheme))
        .margin({ top: 14 })

      Row() {
        this.SmallMetric(`${this.todaySchedules.length}`, '今日时间块')
        this.SmallMetric(`${this.inboxCount}`, '收集箱')
        this.SmallMetric(`${this.conflicts.length}`, '冲突')
        this.SmallMetric(`${this.tasks.length}`, '总任务')
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .backgroundColor(ThemeTokens.elevated(this.currentTheme))
    .borderRadius(24)
    .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
    .shadow({ radius: 32, color: ThemeTokens.cardShadow(this.currentTheme), offsetX: 0, offsetY: 15 })
    .margin({ top: 12 })
  }

  @Builder
  SmallMetric(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.text(this.currentTheme))
      Text(label)
        .fontSize(10)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding({ left: 10, right: 10, top: 10, bottom: 10 })
    .backgroundColor(ThemeTokens.paperInset(this.currentTheme))
    .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
    .borderRadius(16)
    .shadow({ radius: 12, color: ThemeTokens.paperThinShadow(this.currentTheme), offsetX: 0, offsetY: 5 })
    .margin({ right: 7 })
  }

  @Builder
  SourcePanel() {
    Column() {
      Row() {
        Column() {
          Text('可安排来源')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))

          Text(this.getSourcePanelHint())
            .fontSize(12)
            .fontColor(ThemeTokens.muted(this.currentTheme))
            .lineHeight(18)
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(`${this.inboxCount + this.futureCandidateSchedules.length} 项`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#256D85')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
          .borderRadius(8)
      }
      .width('100%')

      Row() {
        this.AutoPlanMetric(`${this.inboxCount}`, '收集箱')
        this.AutoPlanMetric(`${this.futureCandidateSchedules.length}`, '未来事项')
        this.AutoPlanMetric(`${this.plannedMinutes}m`, '今日已排')
      }
      .width('100%')
      .padding({ top: 14 })

      if (this.futureCandidateSchedules.length > 0) {
        Column() {
          Text('可提前到今天')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#607385')
            .margin({ bottom: 2 })

          ForEach(this.futureCandidateSchedules.slice(0, 3), (schedule: Schedule) => {
            this.FutureSourceRow(schedule)
          }, (schedule: Schedule) => schedule.id)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .backgroundColor(ThemeTokens.canvas(this.currentTheme))
        .borderRadius(10)
        .margin({ top: 12 })
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
  FutureSourceRow(schedule: Schedule) {
    Row() {
      Column() {
        Text(schedule.title)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.getFutureSourceMeta(schedule))
          .fontSize(10)
          .fontColor(ThemeTokens.secondary(this.currentTheme))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button('移到今天')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor('#256D85')
        .height(30)
        .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
        .borderRadius(8)
        .margin({ left: 10 })
        .onClick(() => {
          this.moveFutureScheduleToToday(schedule);
        })
    }
    .width('100%')
    .margin({ top: 10 })
  }

  @Builder
  ConflictPanel() {
    if (this.conflicts.length > 0) {
      Column() {
        Row() {
          Text('时间冲突')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
            .layoutWeight(1)

          Text(`${this.conflicts.length} 处`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#6F7F88')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(ThemeTokens.slateWash(this.currentTheme))
            .borderRadius(8)
        }
        .width('100%')

        Text('先让时段归位，再添新事。')
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .lineHeight(18)
          .margin({ top: 8 })

        ForEach(this.conflicts.slice(0, 2), (conflict: ScheduleConflict) => {
          Row() {
            Text(`${TimeFormatter.formatTime(conflict.startAt)}-${TimeFormatter.formatTime(conflict.endAt)}`)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#6F7F88')
              .width(78)

            Text(`${conflict.firstTitle} / ${conflict.secondTitle}`)
              .fontSize(13)
              .fontColor(ThemeTokens.text(this.currentTheme))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            Text(`${conflict.overlapMinutes}m`)
              .fontSize(11)
              .fontColor(ThemeTokens.muted(this.currentTheme))
          }
          .width('100%')
          .margin({ top: 10 })
        }, (conflict: ScheduleConflict) => conflict.id)

        Button('去今天调整')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .height(40)
          .width('100%')
          .backgroundColor('#6F7F88')
          .borderRadius(10)
          .margin({ top: 14 })
          .onClick(() => {
            this.navigateTo('pages/TodayPage');
          })
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
  AutoPlanPanel() {
    Column() {
      Row() {
        Column() {
          Text('自动编排')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))

          Text('择要而行，避繁就简。')
            .fontSize(12)
            .fontColor(ThemeTokens.muted(this.currentTheme))
            .lineHeight(18)
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.getAutoPlanStatus())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getAutoPlanStatusColor())
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(ThemeTokens.canvas(this.currentTheme))
          .borderRadius(8)
      }
      .width('100%')

      Text(this.getAutoPlanHint())
        .fontSize(12)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .lineHeight(18)
        .margin({ top: 12 })

      if (this.autoPlanSuggestions.length > 0 && this.conflicts.length === 0) {
        Row() {
          this.AutoPlanMetric(`${this.getSelectedAutoPlanCount()}`, '已选')
          this.AutoPlanMetric(`${this.getSelectedAutoPlanMinutes()}m`, '将安排')
          this.AutoPlanMetric(`${this.getSelectedAutoPlanRemainingAfterMinutes()}m`, '安排后余量')
          this.AutoPlanMetric(`${this.autoPlanSkippedCount}`, '暂不处理')
        }
        .width('100%')
        .padding({ top: 12 })

        ForEach(this.autoPlanSuggestions, (suggestion: AutoPlanSuggestion) => {
          this.AutoPlanSuggestionRow(suggestion)
        }, (suggestion: AutoPlanSuggestion) => suggestion.taskId)
      }

      if (this.excludedAutoPlanTaskIds.length > 0 && this.conflicts.length === 0) {
        Column() {
          Text('已排除')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#607385')
            .margin({ bottom: 4 })

          ForEach(this.excludedAutoPlanTaskIds, (taskId: string) => {
            this.ExcludedAutoPlanTaskRow(taskId)
          }, (taskId: string) => taskId)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .backgroundColor(ThemeTokens.canvas(this.currentTheme))
        .borderRadius(10)
        .margin({ top: 12 })
      }

      Button(this.getAutoPlanActionLabel())
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .height(42)
        .width('100%')
        .backgroundColor(this.getAutoPlanStatusColor())
        .borderRadius(10)
        .margin({ top: 14 })
        .onClick(() => {
          this.handleAutoPlanAction();
        })
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
  AutoPlanMetric(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.text(this.currentTheme))

      Text(label)
        .fontSize(10)
        .fontColor(ThemeTokens.secondary(this.currentTheme))
        .margin({ top: 3 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  AutoPlanSuggestionRow(suggestion: AutoPlanSuggestion) {
    Column() {
      Row() {
        Text(this.isSuggestionSelected(suggestion.taskId) ? '✓' : '')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isSuggestionSelected(suggestion.taskId) ? '#FFFFFF' : ThemeTokens.secondary(this.currentTheme))
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.isSuggestionSelected(suggestion.taskId) ? '#46AFA5' : ThemeTokens.surface(this.currentTheme))
          .border({ width: 1, color: this.isSuggestionSelected(suggestion.taskId) ? '#46AFA5' : ThemeTokens.hairline(this.currentTheme) })
          .borderRadius(12)
          .margin({ right: 10 })
          .onClick(() => {
            this.toggleAutoPlanSelection(suggestion.taskId);
          })

        Column() {
          Text(`${TimeFormatter.formatTime(suggestion.startAt)}-${TimeFormatter.formatTime(suggestion.endAt)}`)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isSuggestionSelected(suggestion.taskId) ? '#256D85' : ThemeTokens.secondary(this.currentTheme))

          Text(suggestion.reason)
            .fontSize(10)
            .fontColor(ThemeTokens.secondary(this.currentTheme))
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .width(86)

        Text(suggestion.title)
          .fontSize(13)
          .fontColor(this.isSuggestionSelected(suggestion.taskId) ? ThemeTokens.text(this.currentTheme) : '#607385')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(suggestion.priority)
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#607385')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(ThemeTokens.subtle(this.currentTheme))
          .borderRadius(6)
          .margin({ left: 8, right: 8 })

        Text('排除')
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6F7F88')
          .padding({ left: 8, right: 8, top: 5, bottom: 5 })
          .backgroundColor(ThemeTokens.slateWash(this.currentTheme))
          .borderRadius(8)
          .onClick(() => {
            this.excludeAutoPlanSuggestion(suggestion.taskId);
          })
      }
      .width('100%')

      Row() {
        Text('顺序')
          .fontSize(10)
          .fontColor(ThemeTokens.secondary(this.currentTheme))
          .width(34)

        this.MoveControl('↑', suggestion.taskId, -1)

        this.MoveControl('↓', suggestion.taskId, 1)

        Text('时长')
          .fontSize(10)
          .fontColor(ThemeTokens.secondary(this.currentTheme))
          .margin({ left: 14 })

        this.DurationControl('-10', suggestion.taskId, -10, suggestion.estimatedTime > 15)

        Text(`${suggestion.estimatedTime}m`)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeTokens.text(this.currentTheme))
          .width(48)
          .textAlign(TextAlign.Center)

        this.DurationControl('+10', suggestion.taskId, 10, suggestion.estimatedTime < 180)
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(this.isSuggestionSelected(suggestion.taskId) ? ThemeTokens.canvas(this.currentTheme) : ThemeTokens.surface(this.currentTheme))
    .border({ width: 1, color: this.isSuggestionSelected(suggestion.taskId) ? ThemeTokens.hairline(this.currentTheme) : '#EEF2F1' })
    .borderRadius(10)
    .margin({ top: 10 })
  }

  @Builder
  MoveControl(label: string, taskId: string, direction: number) {
    Text(label)
      .fontSize(10)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.canMoveSuggestion(taskId, direction) ? '#256D85' : '#A8B2B6')
      .width(38)
      .height(24)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.canMoveSuggestion(taskId, direction) ? '#E8F2F1' : ThemeTokens.subtle(this.currentTheme))
      .borderRadius(8)
      .margin({ left: 6 })
      .onClick(() => {
        this.moveAutoPlanSuggestion(taskId, direction);
      })
  }

  @Builder
  DurationControl(label: string, taskId: string, delta: number, active: boolean) {
    Text(label)
      .fontSize(10)
      .fontWeight(FontWeight.Bold)
      .fontColor(active ? '#256D85' : '#A8B2B6')
      .width(38)
      .height(24)
      .textAlign(TextAlign.Center)
      .backgroundColor(active ? '#E8F2F1' : ThemeTokens.subtle(this.currentTheme))
      .borderRadius(8)
      .margin({ left: 6 })
      .onClick(() => {
        if (active) {
          this.adjustAutoPlanDuration(taskId, delta);
        }
      })
  }

  @Builder
  ExcludedAutoPlanTaskRow(taskId: string) {
    Row() {
      Text(this.getTaskTitleById(taskId))
        .fontSize(12)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Text('恢复')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor('#256D85')
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
        .borderRadius(8)
        .onClick(() => {
          this.includeAutoPlanTask(taskId);
        })
    }
    .width('100%')
    .margin({ top: 8 })
  }

  @Builder
  DecisionPanel() {
    Column() {
      Text(this.planFeedbackText.length > 0 ? this.planFeedbackText : (this.lastScheduledTitle.length > 0 ? `刚安排：${this.lastScheduledTitle}` : this.getDecisionHint()))
        .fontSize(13)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .lineHeight(20)
        .margin({ bottom: 14 })

      Row() {
        Button(this.getPrimaryActionLabel())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .height(44)
          .backgroundColor(this.getCurrentStep().accent)
          .borderRadius(10)
          .layoutWeight(1)
          .onClick(() => {
            this.handlePrimaryAction();
          })

        Button(this.getSecondaryActionLabel())
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getCurrentStep().accent)
          .height(44)
          .backgroundColor(ThemeTokens.subtle(this.currentTheme))
          .borderRadius(10)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.handleSecondaryAction();
          })
      }
      .width('100%')
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

  getDecisionHint(): string {
    if (this.activeStep === 1) return '先观昨日，再定今日。';
    if (this.activeStep === 2) return this.getStepTwoDecisionHint();
    if (this.conflicts.length > 0) return '时段相叠，先让今日归位。';
    if (this.activeStep === 3) return this.carryOverSchedules.length > 0 ? `明天已有 ${this.carryOverSchedules.length} 段待续，今日宜轻。` : `超过 ${this.getDailyCapacity()} 分钟时，宜减不宜加。`;
    if (this.activeStep === 4) return '顺序已成，细处可再微调。';
    return '计划已明，第一步便是开始。';
  }

  getStepTwoDecisionHint(): string {
    if (this.hasAutoPlanSuggestions()) {
      if (this.getSelectedAutoPlanCount() > 0) {
        return `先定 ${this.getSelectedAutoPlanCount()} 段，让今日成形。`;
      }
      return '择其合拍，余者暂缓。';
    }
    if (this.inboxTasks.length > 0) {
      return `先从这一件开始：${this.inboxTasks[0].title}`;
    }
    const candidate = this.getFirstFutureCandidate();
    if (candidate) {
      return `未来已有一事，可提前入今日：${candidate.title}`;
    }
    return '收集箱为空，先写下一件事。';
  }

  @Builder
  PlanHandoffPanel() {
    if (this.activeStep === 5) {
      Column() {
        Row() {
          Text()
            .width(4)
            .height(58)
            .borderRadius(2)
            .backgroundColor('#46AFA5')
            .margin({ right: 12 })

          Column() {
            Text('准备开始')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#46AFA5')

            Text(this.getHandoffTitle())
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeTokens.text(this.currentTheme))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 5 })

            Text(this.getHandoffMeta())
              .fontSize(12)
              .fontColor(ThemeTokens.muted(this.currentTheme))
              .margin({ top: 5 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        Text(this.getHandoffCopy())
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .lineHeight(18)
          .margin({ top: 12 })

        Row() {
          Button('开始第一段')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .height(44)
            .backgroundColor(this.getHandoffSchedule() ? '#46AFA5' : '#A8B2B6')
            .borderRadius(10)
            .layoutWeight(1)
            .onClick(() => {
              const schedule = this.getHandoffSchedule();
              if (schedule) {
                this.startFocusFromPlan(schedule);
              }
            })

          Button('回到今天')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#256D85')
            .height(44)
            .backgroundColor(ThemeTokens.selectedSurface(this.currentTheme))
            .borderRadius(10)
            .layoutWeight(1)
            .margin({ left: 10 })
            .onClick(() => {
              this.navigateTo('pages/TodayPage');
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
  TodayPreview() {
    Column() {
      Text('今日顺序')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeTokens.text(this.currentTheme))
        .margin({ bottom: 8 })

      if (this.todaySchedules.length === 0) {
        Text('一事入时，今日有序。')
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .lineHeight(18)
      } else {
        ForEach(this.todaySchedules.slice(0, 4), (schedule: Schedule) => {
          Row() {
            Text(schedule.scheduledTime || this.getNextAvailableTime())
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#607385')
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
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(ThemeTokens.elevated(this.currentTheme))
    .borderRadius(18)
    .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
    .shadow({ radius: 22, color: ThemeTokens.cardShadow(this.currentTheme), offsetX: 0, offsetY: 10 })
    .margin({ top: 12, bottom: 24 })
  }

  @Builder
  CarryOverPanel() {
    if (this.carryOverSchedules.length > 0) {
      Column() {
        Row() {
          Text('明日结转')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeTokens.text(this.currentTheme))
            .layoutWeight(1)

          Text(`${this.tomorrowCarryOverMinutes} 分钟`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#8A7CC3')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(ThemeTokens.subtle(this.currentTheme))
            .borderRadius(8)
        }
        .width('100%')

        Text('今日未竟，明日再续。')
          .fontSize(12)
          .fontColor(ThemeTokens.muted(this.currentTheme))
          .lineHeight(18)
          .margin({ top: 8 })

        ForEach(this.carryOverSchedules.slice(0, 3), (schedule: Schedule) => {
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
      .backgroundColor(ThemeTokens.elevated(this.currentTheme))
      .borderRadius(18)
      .border({ width: 1, color: ThemeTokens.cardBorder(this.currentTheme) })
      .shadow({ radius: 22, color: ThemeTokens.cardShadow(this.currentTheme), offsetX: 0, offsetY: 10 })
      .margin({ top: 12 })
    }
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.StepperPanel()
          this.WorkloadPanel()
          this.SourcePanel()
          this.ConflictPanel()
          this.AutoPlanPanel()
          this.DecisionPanel()
          this.PlanHandoffPanel()
          this.CarryOverPanel()
          this.TodayPreview()
        }
        .padding({ left: 16, right: 16, top: 8 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeTokens.canvas(this.currentTheme))
  }
}

@Entry
@Component
struct PlanPageEntry {
  build() {
    Column() {
      PlanPage()
    }
    .width('100%')
    .height('100%')
  }
}
