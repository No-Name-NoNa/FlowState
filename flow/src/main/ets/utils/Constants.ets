/**
 * 常量配置
 */

import { RecommendMode, ThemeConfig } from '../models/DataModels';

// 情绪标签映射类
export class MoodLabels {
  static getLabel(value: number): string {
    if (value === 0) return '休息';
    if (value === 25) return '疲惫';
    if (value === 50) return '焦虑';
    if (value === 75) return '平淡';
    if (value === 85) return '平静';
    if (value === 100) return '充沛';
    return '平淡';
  }
}

// 推荐模式规则
export const RECOMMEND_RULES: RecommendMode[] = [
  { moodRange: [0, 20], modeName: '建议休息', suggestedDuration: 15, description: '当前状态不适合专注，建议先休息一下' },
  { moodRange: [21, 40], modeName: '轻松任务', suggestedDuration: 10, description: '可以从简单的任务开始，慢慢进入状态' },
  { moodRange: [41, 60], modeName: '标准任务', suggestedDuration: 25, description: '适合处理标准难度的任务' },
  { moodRange: [61, 80], modeName: '深度任务', suggestedDuration: 45, description: '状态不错，可以挑战深度工作' },
  { moodRange: [81, 100], modeName: '冲刺模式', suggestedDuration: 60, description: '精力充沛，适合长时间专注' }
];

// 时间配置
export const TIME_PRESETS: number[] = [15, 25, 45, 60, 90]; // 预设时长（分钟）

// 颜色配置类
export class TaskColors {
  static blue: string = '#2F6F86';
  static gray: string = '#7D8C96';
  static green: string = '#58B7AE';
  static orange: string = '#8EA1AE';
  static red: string = '#9C5B5B';
  static purple: string = '#7E86A8';
}

// 优先级配置项
export interface PriorityItem {
  label: string;
  color: string;
}

// 优先级配置类
export class PriorityConfig {
  static P0: PriorityItem = { label: '紧急', color: '#2F6F86' };
  static P1: PriorityItem = { label: '重要', color: '#58B7AE' };
  static P2: PriorityItem = { label: '普通', color: '#7D8C96' };
}

// 预设主题
export const PRESET_THEMES: ThemeConfig[] = [
  {
    id: 'light',
    name: '雾白主题',
    primaryColor: '#2F6F86',
    backgroundColor: '#F4F7F8',
    cardColor: '#FFFFFF',
    textColor: '#151C22',
    accentColor: '#58B7AE',
    isDark: false
  },
  {
    id: 'dark',
    name: '深色主题',
    primaryColor: '#0A84FF',
    backgroundColor: '#1C1C1E',
    cardColor: '#2C2C2E',
    textColor: '#F5F5F7',
    accentColor: '#30D158',
    isDark: true
  },
  {
    id: 'warm',
    name: '石墨主题',
    primaryColor: '#2F6F86',
    backgroundColor: '#F4F7F8',
    cardColor: '#FFFFFF',
    textColor: '#151C22',
    accentColor: '#58B7AE',
    isDark: false
  },
  {
    id: 'cool',
    name: '冷色主题',
    primaryColor: '#5856D6',
    backgroundColor: '#F0F4F8',
    cardColor: '#FFFFFF',
    textColor: '#1A1A1A',
    accentColor: '#64D2FF',
    isDark: false
  },
  {
    id: 'nature',
    name: '自然主题',
    primaryColor: '#34C759',
    backgroundColor: '#F0F9F4',
    cardColor: '#FFFFFF',
    textColor: '#1F3A2C',
    accentColor: '#87CEEB',
    isDark: false
  }
];

// 数据存储键
export class StorageKeys {
  static MOOD_ENTRIES: string = 'mood_entries';
  static TASKS: string = 'tasks';
  static SCHEDULES: string = 'schedules';
  static FOCUS_SESSIONS: string = 'focus_sessions';
  static REST_SESSIONS: string = 'rest_sessions';
  static USER_SETTINGS: string = 'user_settings';
  static USER_INFO: string = 'user_info';
  static CUSTOM_THEMES: string = 'custom_themes';
  static CURRENT_THEME: string = 'current_theme';
}

// 日志域
export const LOG_DOMAIN: number = 0x0001;
