import { Priority, Schedule, Task } from '../models/DataModels';
import { ScheduleAnalyzer } from './ScheduleAnalyzer';
import { TimeFormatter } from './TimeFormatter';

export interface AutoPlanSuggestion {
  taskId: string;
  title: string;
  priority: Priority;
  estimatedTime: number;
  scheduledDate: number;
  scheduledTime: string;
  dueAt: number;
  startAt: number;
  endAt: number;
  reason: string;
}

export interface AutoPlanResult {
  suggestions: AutoPlanSuggestion[];
  skippedCount: number;
  plannedMinutes: number;
  remainingMinutes: number;
  remainingAfterMinutes: number;
}

interface BusyWindow {
  startAt: number;
  endAt: number;
}

interface AvailableWindow {
  startAt: number;
  endAt: number;
}

export class AutoPlanner {
  static buildTodayPlan(tasks: Task[], schedules: Schedule[], todayStart: number, dailyCapacityMinutes: number, defaultFocusMinutes: number, currentPlannedMinutes: number, now: number): AutoPlanResult {
    const capacity = dailyCapacityMinutes > 0 ? dailyCapacityMinutes : 300;
    const baseDuration = defaultFocusMinutes > 0 ? defaultFocusMinutes : 25;
    const minBlockMinutes = 15;
    const maxSuggestions = 4;
    const workStart = AutoPlanner.buildTime(todayStart, 9, 0);
    const workEnd = AutoPlanner.buildTime(todayStart, 21, 30);
    let cursorStart = AutoPlanner.roundUpToQuarter(Math.max(now, workStart));
    if (cursorStart > workEnd) {
      cursorStart = workEnd;
    }

    let remainingMinutes = capacity - currentPlannedMinutes;
    if (remainingMinutes < 0) {
      remainingMinutes = 0;
    }

    const sortedTasks = AutoPlanner.sortTasks(tasks);
    const busyWindows = AutoPlanner.buildBusyWindows(schedules, workStart, workEnd);
    const suggestions: AutoPlanSuggestion[] = [];
    let plannedMinutes = 0;
    let skippedCount = 0;

    for (let i = 0; i < sortedTasks.length; i++) {
      if (suggestions.length >= maxSuggestions) {
        skippedCount += sortedTasks.length - i;
        break;
      }
      if (remainingMinutes < minBlockMinutes) {
        skippedCount += sortedTasks.length - i;
        break;
      }

      const task = sortedTasks[i];
      let duration = baseDuration;
      if (duration < minBlockMinutes) {
        duration = minBlockMinutes;
      }
      if (duration > remainingMinutes) {
        duration = remainingMinutes;
      }

      const slot = AutoPlanner.findAvailableWindow(busyWindows, cursorStart, workEnd, duration);
      if (!slot) {
        skippedCount++;
        continue;
      }

      const suggestion: AutoPlanSuggestion = {
        taskId: task.id,
        title: task.title,
        priority: task.priority,
        estimatedTime: duration,
        scheduledDate: todayStart,
        scheduledTime: TimeFormatter.formatTime(slot.endAt),
        dueAt: slot.endAt,
        startAt: slot.startAt,
        endAt: slot.endAt,
        reason: AutoPlanner.buildReason(task.priority, duration)
      };
      suggestions.push(suggestion);
      plannedMinutes += duration;
      remainingMinutes -= duration;
      busyWindows.push({ startAt: slot.startAt, endAt: slot.endAt });
      busyWindows.sort((a: BusyWindow, b: BusyWindow) => a.startAt - b.startAt);
      cursorStart = slot.endAt + 10 * 60 * 1000;
    }

    return {
      suggestions,
      skippedCount,
      plannedMinutes,
      remainingMinutes: Math.max(0, capacity - currentPlannedMinutes),
      remainingAfterMinutes: remainingMinutes
    };
  }

  static reflowTodaySuggestions(suggestions: AutoPlanSuggestion[], schedules: Schedule[], todayStart: number, now: number): AutoPlanSuggestion[] {
    const workStart = AutoPlanner.buildTime(todayStart, 9, 0);
    const workEnd = AutoPlanner.buildTime(todayStart, 21, 30);
    let cursorStart = AutoPlanner.roundUpToQuarter(Math.max(now, workStart));
    if (cursorStart > workEnd) {
      cursorStart = workEnd;
    }

    const busyWindows = AutoPlanner.buildBusyWindows(schedules, workStart, workEnd);
    const reflowed: AutoPlanSuggestion[] = [];
    for (let suggestion of suggestions) {
      const duration = AutoPlanner.clampDuration(suggestion.estimatedTime);
      const slot = AutoPlanner.findAvailableWindow(busyWindows, cursorStart, workEnd, duration);
      if (!slot) {
        return reflowed;
      }

      reflowed.push({
        taskId: suggestion.taskId,
        title: suggestion.title,
        priority: suggestion.priority,
        estimatedTime: duration,
        scheduledDate: todayStart,
        scheduledTime: TimeFormatter.formatTime(slot.endAt),
        dueAt: slot.endAt,
        startAt: slot.startAt,
        endAt: slot.endAt,
        reason: AutoPlanner.buildReason(suggestion.priority, duration)
      });
      busyWindows.push({ startAt: slot.startAt, endAt: slot.endAt });
      busyWindows.sort((a: BusyWindow, b: BusyWindow) => a.startAt - b.startAt);
      cursorStart = slot.endAt + 10 * 60 * 1000;
    }
    return reflowed;
  }

  private static sortTasks(tasks: Task[]): Task[] {
    const sorted = tasks.slice();
    sorted.sort((a: Task, b: Task) => {
      const priorityDiff = AutoPlanner.getPriorityRank(a.priority) - AutoPlanner.getPriorityRank(b.priority);
      if (priorityDiff !== 0) {
        return priorityDiff;
      }
      return a.createdAt - b.createdAt;
    });
    return sorted;
  }

  private static getPriorityRank(priority: Priority): number {
    if (priority === 'P0') return 0;
    if (priority === 'P1') return 1;
    return 2;
  }

  private static buildBusyWindows(schedules: Schedule[], workStart: number, workEnd: number): BusyWindow[] {
    const windows: BusyWindow[] = [];
    for (let schedule of schedules) {
      if (!ScheduleAnalyzer.isActiveForPlanning(schedule)) {
        continue;
      }
      const startAt = Math.max(ScheduleAnalyzer.getStartAt(schedule), workStart);
      const endAt = Math.min(ScheduleAnalyzer.getDueAt(schedule), workEnd);
      if (startAt < endAt) {
        windows.push({ startAt, endAt });
      }
    }
    windows.sort((a: BusyWindow, b: BusyWindow) => a.startAt - b.startAt);
    return windows;
  }

  private static findAvailableWindow(busyWindows: BusyWindow[], cursorStart: number, workEnd: number, durationMinutes: number): AvailableWindow | null {
    const duration = durationMinutes * 60 * 1000;
    const buffer = 10 * 60 * 1000;
    let cursor = cursorStart;

    for (let window of busyWindows) {
      if (window.endAt <= cursor) {
        continue;
      }
      if (cursor + duration <= window.startAt) {
        return { startAt: cursor, endAt: cursor + duration };
      }
      cursor = Math.max(cursor, window.endAt + buffer);
    }

    if (cursor + duration <= workEnd) {
      return { startAt: cursor, endAt: cursor + duration };
    }
    return null;
  }

  private static buildTime(dayStart: number, hour: number, minute: number): number {
    const date = new Date(dayStart);
    date.setHours(hour, minute, 0, 0);
    return date.getTime();
  }

  private static roundUpToQuarter(timestamp: number): number {
    const interval = 15 * 60 * 1000;
    return Math.ceil(timestamp / interval) * interval;
  }

  private static buildReason(priority: Priority, duration: number): string {
    if (priority === 'P0') return `优先处理 · 避开冲突 · ${duration}m`;
    if (priority === 'P1') return `重要事项 · 容量内 · ${duration}m`;
    return `常规安排 · 补位 · ${duration}m`;
  }

  private static clampDuration(duration: number): number {
    if (duration < 15) return 15;
    if (duration > 180) return 180;
    return duration;
  }
}
