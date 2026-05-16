/**
 * Lightweight schema migration for local Preferences data.
 */

import {
  FocusSession,
  MoodEntry,
  Priority,
  RestSession,
  Schedule,
  ScheduleArchiveEntry,
  ScheduleExecutionState,
  Task,
  TaskStep,
  UserInfo,
  UserSettings
} from '../models/DataModels';

export const CURRENT_DATA_SCHEMA_VERSION: number = 2;

export class DataMigration {
  static normalizeMoodEntries(entries: MoodEntry[]): MoodEntry[] {
    const normalized: MoodEntry[] = [];
    for (let entry of entries) {
      const timestamp = entry.timestamp > 0 ? entry.timestamp : Date.now();
      normalized.push({
        id: entry.id || `mood_${timestamp}`,
        timestamp,
        moodValue: entry.moodValue >= 0 ? entry.moodValue : 75,
        moodLabel: entry.moodLabel || '平静',
        note: entry.note
      });
    }
    return normalized;
  }

  static normalizeTasks(tasks: Task[]): Task[] {
    const normalized: Task[] = [];
    for (let task of tasks) {
      const createdAt = task.createdAt > 0 ? task.createdAt : Date.now();
      normalized.push({
        id: task.id || `task_${createdAt}`,
        title: DataMigration.cleanTitle(task.title, '未命名任务'),
        color: task.color || '#2F6F86',
        priority: DataMigration.normalizePriority(task.priority),
        schedules: task.schedules || [],
        createdAt,
        updatedAt: task.updatedAt || createdAt,
        note: task.note,
        steps: DataMigration.normalizeTaskSteps(task.steps || [], createdAt),
        isExpanded: task.isExpanded === true,
        routineId: task.routineId
      });
    }
    return normalized;
  }

  static normalizeSchedules(schedules: Schedule[]): Schedule[] {
    const normalized: Schedule[] = [];
    for (let schedule of schedules) {
      const createdAt = schedule.createdAt > 0 ? schedule.createdAt : Date.now();
      const estimatedTime = schedule.estimatedTime > 0 ? schedule.estimatedTime : 25;
      const dueAt = schedule.dueAt && schedule.dueAt > 0
        ? schedule.dueAt
        : DataMigration.buildDueAt(schedule.scheduledDate, schedule.scheduledTime, createdAt, estimatedTime);
      normalized.push({
        id: schedule.id || `schedule_${createdAt}`,
        taskId: schedule.taskId || '',
        title: DataMigration.cleanTitle(schedule.title, '未命名日程'),
        estimatedTime,
        priority: DataMigration.normalizePriority(schedule.priority),
        scheduledDate: schedule.scheduledDate || DataMigration.getDayStart(dueAt),
        scheduledTime: schedule.scheduledTime || DataMigration.getStartTimeText(dueAt, estimatedTime),
        dueAt,
        reminderMinutes: schedule.reminderMinutes === undefined ? -1 : schedule.reminderMinutes,
        createdAt,
        stats: schedule.stats || [],
        changeHistory: schedule.changeHistory || [],
        state: DataMigration.normalizeScheduleState(schedule.state, schedule.completedAt),
        completedAt: schedule.completedAt,
        deferredAt: schedule.deferredAt,
        cancelledAt: schedule.cancelledAt,
        actualMinutes: schedule.actualMinutes,
        stateNote: schedule.stateNote,
        routineId: schedule.routineId
      });
    }
    return normalized;
  }

  static normalizeScheduleArchive(entries: ScheduleArchiveEntry[]): ScheduleArchiveEntry[] {
    const normalized: ScheduleArchiveEntry[] = [];
    for (let entry of entries) {
      const archivedAt = entry.archivedAt > 0 ? entry.archivedAt : Date.now();
      normalized.push({
        id: entry.id || `archive_${archivedAt}`,
        scheduleId: entry.scheduleId || '',
        taskId: entry.taskId || '',
        title: DataMigration.cleanTitle(entry.title, '已归档日程'),
        estimatedTime: entry.estimatedTime > 0 ? entry.estimatedTime : 25,
        priority: DataMigration.normalizePriority(entry.priority),
        scheduledDate: entry.scheduledDate,
        scheduledTime: entry.scheduledTime,
        dueAt: entry.dueAt,
        archivedAt,
        reason: entry.reason || 'delete',
        note: entry.note,
        changeHistory: entry.changeHistory || []
      });
    }
    return normalized;
  }

  static normalizeFocusSessions(sessions: FocusSession[]): FocusSession[] {
    const normalized: FocusSession[] = [];
    for (let session of sessions) {
      const startTime = session.startTime > 0 ? session.startTime : Date.now();
      let duration = session.duration > 0 ? session.duration : 25;
      if ((!session.duration || session.duration <= 0) && session.endTime && session.endTime > startTime) {
        duration = Math.max(1, Math.floor((session.endTime - startTime) / 60000));
      }
      normalized.push({
        id: session.id || `focus_${startTime}`,
        scheduleId: session.scheduleId,
        taskId: session.taskId,
        startTime,
        endTime: session.endTime,
        duration,
        mode: session.mode === 'continuous' ? 'continuous' : 'pomodoro',
        completed: session.completed === true,
        pauseCount: session.pauseCount >= 0 ? session.pauseCount : 0,
        reflection: session.reflection
      });
    }
    return normalized;
  }

  static normalizeRestSessions(sessions: RestSession[]): RestSession[] {
    const normalized: RestSession[] = [];
    for (let session of sessions) {
      const startTime = session.startTime > 0 ? session.startTime : Date.now();
      normalized.push({
        id: session.id || `rest_${startTime}`,
        focusSessionId: session.focusSessionId || '',
        startTime,
        endTime: session.endTime,
        duration: session.duration > 0 ? session.duration : 5,
        skipped: session.skipped === true
      });
    }
    return normalized;
  }

  static normalizeUserSettings(settings: UserSettings): UserSettings {
    return {
      defaultFocusTime: settings.defaultFocusTime > 0 ? settings.defaultFocusTime : 25,
      defaultRestTime: settings.defaultRestTime > 0 ? settings.defaultRestTime : 5,
      dailyCapacityMinutes: settings.dailyCapacityMinutes > 0 ? settings.dailyCapacityMinutes : 300,
      autoStartRest: settings.autoStartRest === true,
      notificationEnabled: settings.notificationEnabled === undefined ? true : settings.notificationEnabled,
      soundEnabled: settings.soundEnabled === undefined ? true : settings.soundEnabled,
      vibrationEnabled: settings.vibrationEnabled === true,
      currentTheme: settings.currentTheme || 'light'
    };
  }

  static normalizeUserInfo(userInfo: UserInfo): UserInfo {
    return {
      id: userInfo.id,
      username: userInfo.username,
      avatar: userInfo.avatar,
      email: userInfo.email,
      isLoggedIn: userInfo.isLoggedIn === true
    };
  }

  private static normalizeTaskSteps(steps: TaskStep[], fallbackTime: number): TaskStep[] {
    const normalized: TaskStep[] = [];
    for (let i = 0; i < steps.length; i++) {
      const step = steps[i];
      const createdAt = step.createdAt > 0 ? step.createdAt : fallbackTime + i;
      normalized.push({
        id: step.id || `step_${createdAt}`,
        title: DataMigration.cleanTitle(step.title, `步骤 ${i + 1}`),
        completed: step.completed === true,
        createdAt
      });
    }
    return normalized;
  }

  private static normalizePriority(priority: string | undefined): Priority {
    if (priority === 'P0' || priority === 'P1' || priority === 'P2') {
      return priority;
    }
    return 'P2';
  }

  private static normalizeScheduleState(state: string | undefined, completedAt: number | undefined): ScheduleExecutionState {
    if (state === 'completed' || state === 'deferred' || state === 'cancelled' || state === 'planned') {
      return state;
    }
    if (completedAt && completedAt > 0) {
      return 'completed';
    }
    return 'planned';
  }

  private static cleanTitle(title: string | undefined, fallback: string): string {
    if (!title) return fallback;
    const cleaned = title.trim();
    return cleaned.length > 0 ? cleaned : fallback;
  }

  private static buildDueAt(scheduledDate: number | undefined, scheduledTime: string | undefined, fallbackTime: number, duration: number): number {
    const date = scheduledDate && scheduledDate > 0 ? new Date(scheduledDate) : new Date(fallbackTime);
    date.setSeconds(0, 0);
    if (scheduledTime && scheduledTime.indexOf(':') > 0) {
      const parts = scheduledTime.split(':');
      const hour = parseInt(parts[0]) || 0;
      const minute = parseInt(parts[1]) || 0;
      date.setHours(hour, minute, 0, 0);
    }
    return date.getTime() + duration * 60 * 1000;
  }

  private static getDayStart(timestamp: number): number {
    const date = new Date(timestamp);
    date.setHours(0, 0, 0, 0);
    return date.getTime();
  }

  private static getStartTimeText(dueAt: number, duration: number): string {
    const date = new Date(dueAt - duration * 60 * 1000);
    const hour = date.getHours() < 10 ? `0${date.getHours()}` : `${date.getHours()}`;
    const minute = date.getMinutes() < 10 ? `0${date.getMinutes()}` : `${date.getMinutes()}`;
    return `${hour}:${minute}`;
  }
}
