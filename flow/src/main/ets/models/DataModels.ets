/**
 * Core data models for Flow State.
 */

export interface MoodEntry {
  id: string;
  timestamp: number;
  moodValue: number;
  moodLabel: string;
  note?: string;
}

export type Priority = 'P0' | 'P1' | 'P2';

export type ScheduleChangeType = 'edit' | 'delay' | 'advance' | 'delete' | 'complete' | 'carryover';

export type ScheduleExecutionState = 'planned' | 'completed' | 'deferred' | 'cancelled';

export interface TaskStep {
  id: string;
  title: string;
  completed: boolean;
  createdAt: number;
}

export interface RoutineTemplate {
  id: string;
  title: string;
  description: string;
  scheduledTime: string;
  estimatedTime: number;
  priority: Priority;
  color: string;
  steps?: string[];
}

export interface ScheduleChange {
  id: string;
  type: ScheduleChangeType;
  timestamp: number;
  note: string;
  fromDueAt?: number;
  toDueAt?: number;
  fromDuration?: number;
  toDuration?: number;
}

export interface Task {
  id: string;
  title: string;
  color: string;
  priority: Priority;
  schedules: Schedule[];
  createdAt: number;
  updatedAt?: number;
  note?: string;
  steps?: TaskStep[];
  isExpanded?: boolean;
  routineId?: string;
}

export interface Schedule {
  id: string;
  taskId: string;
  title: string;
  estimatedTime: number;
  priority: Priority;
  scheduledDate?: number;
  scheduledTime?: string;
  dueAt?: number;
  reminderMinutes?: number;
  createdAt: number;
  stats?: number[];
  changeHistory?: ScheduleChange[];
  state?: ScheduleExecutionState;
  completedAt?: number;
  deferredAt?: number;
  cancelledAt?: number;
  actualMinutes?: number;
  stateNote?: string;
  routineId?: string;
}

export interface ScheduleArchiveEntry {
  id: string;
  scheduleId: string;
  taskId: string;
  title: string;
  estimatedTime: number;
  priority: Priority;
  scheduledDate?: number;
  scheduledTime?: string;
  dueAt?: number;
  archivedAt: number;
  reason: ScheduleChangeType;
  note?: string;
  changeHistory?: ScheduleChange[];
}

export interface FocusSession {
  id: string;
  scheduleId?: string;
  taskId?: string;
  startTime: number;
  endTime?: number;
  duration: number;
  mode: 'pomodoro' | 'continuous';
  completed: boolean;
  pauseCount: number;
  reflection?: string;
}

export interface RestSession {
  id: string;
  focusSessionId: string;
  startTime: number;
  endTime?: number;
  duration: number;
  skipped: boolean;
}

export interface ThemeConfig {
  id: string;
  name: string;
  primaryColor: string;
  backgroundColor: string;
  cardColor: string;
  textColor: string;
  accentColor: string;
  backgroundImage?: string;
  isDark: boolean;
}

export interface UserSettings {
  defaultFocusTime: number;
  defaultRestTime: number;
  dailyCapacityMinutes: number;
  autoStartRest: boolean;
  notificationEnabled: boolean;
  soundEnabled: boolean;
  vibrationEnabled: boolean;
  currentTheme: string;
}

export interface UserInfo {
  id?: string;
  username?: string;
  avatar?: string;
  email?: string;
  isLoggedIn: boolean;
}

export interface RecommendMode {
  moodRange: [number, number];
  modeName: string;
  suggestedDuration: number;
  description: string;
}

export interface AIInsight {
  date: string;
  totalFocusTime: number;
  taskSummary: string;
  moodCorrelation: string;
  recommendation: string;
}

export interface AIPlanTask {
  title: string;
  estimatedTime: number;
  subtasks: string[];
}

export interface AIPlan {
  goal: string;
  tasks: AIPlanTask[];
  totalEstimatedTime: number;
}
