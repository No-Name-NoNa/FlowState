/**
 * 数据模型定义
 * Flow State 核心数据结构
 */

// 情绪签到记录
export interface MoodEntry {
  id: string;
  timestamp: number;
  moodValue: number; // 0-100
  moodLabel: string; // '疲惫', '焦虑', '平淡', '平静', '充沛'
  note?: string;
}

// 任务优先级
export type Priority = 'P0' | 'P1' | 'P2';

// 任务模型
export interface Task {
  id: string;
  title: string;
  color: string; // 'blue' | 'gray'
  priority: Priority;
  schedules: Schedule[];
  createdAt: number;
  isExpanded?: boolean; // UI 状态
}

// 子日程模型
export interface Schedule {
  id: string;
  taskId: string;
  title: string;
  estimatedTime: number; // 分钟
  priority: Priority;
  createdAt: number;
  stats?: number[]; // 柱状图数据（6个点）
}

// 专注记录
export interface FocusSession {
  id: string;
  scheduleId?: string;
  taskId?: string;
  startTime: number;
  endTime?: number;
  duration: number; // 实际专注时长（分钟）
  mode: 'pomodoro' | 'continuous'; // 番茄钟 | 正计时
  completed: boolean;
  pauseCount: number;
  reflection?: string; // 复盘心得
}

// 休息记录
export interface RestSession {
  id: string;
  focusSessionId: string;
  startTime: number;
  endTime?: number;
  duration: number;
  skipped: boolean;
}

// 主题配置
export interface ThemeConfig {
  id: string;
  name: string;
  primaryColor: string;
  backgroundColor: string;
  cardColor: string;
  textColor: string;
  accentColor: string;
  backgroundImage?: string; // base64 or path
  isDark: boolean;
}

// 用户设置
export interface UserSettings {
  defaultFocusTime: number; // 默认专注时长（分钟）
  defaultRestTime: number; // 默认休息时长（分钟）
  autoStartRest: boolean; // 自动开始休息
  notificationEnabled: boolean;
  soundEnabled: boolean;
  vibrationEnabled: boolean;
  currentTheme: string; // 主题 ID
}

// 用户信息
export interface UserInfo {
  id?: string;
  username?: string;
  avatar?: string;
  email?: string;
  isLoggedIn: boolean;
}

// 推荐模式
export interface RecommendMode {
  moodRange: [number, number]; // [min, max]
  modeName: string;
  suggestedDuration: number; // 分钟
  description: string;
}

// AI 洞察数据（模拟）
export interface AIInsight {
  date: string;
  totalFocusTime: number; // 小时
  taskSummary: string;
  moodCorrelation: string;
  recommendation: string;
}

// AI 计划任务项
export interface AIPlanTask {
  title: string;
  estimatedTime: number;
  subtasks: string[];
}

// AI 计划数据（模拟）
export interface AIPlan {
  goal: string;
  tasks: AIPlanTask[];
  totalEstimatedTime: number;
}
