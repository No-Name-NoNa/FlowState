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

export interface TaskStep {
  id: string;
  title: string;
  completed: boolean;
  createdAt: number;
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
