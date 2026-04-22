/**
 * 常量配置
 */

// 情绪标签映射
export const MOOD_LABELS = {
  0: '休息',
  25: '疲惫',
  50: '焦虑',
  75: '平淡',
  85: '平静',
  100: '充沛'
};

// 情绪表情映射
export const MOOD_EMOJIS = {
  0: '😴',
  25: '😴',
  50: '😰',
  75: '😐',
  85: '🙂',
  100: '⚡'
};

// 推荐模式规则
export const RECOMMEND_RULES = [
  { moodRange: [0, 20], modeName: '建议休息', suggestedDuration: 15, description: '当前状态不适合专注，建议先休息一下' },
  { moodRange: [21, 40], modeName: '轻松任务', suggestedDuration: 10, description: '可以从简单的任务开始，慢慢进入状态' },
  { moodRange: [41, 60], modeName: '标准任务', suggestedDuration: 25, description: '适合处理标准难度的任务' },
  { moodRange: [61, 80], modeName: '深度任务', suggestedDuration: 45, description: '状态不错，可以挑战深度工作' },
  { moodRange: [81, 100], modeName: '冲刺模式', suggestedDuration: 60, description: '精力充沛，适合长时间专注' }
];

// 时间配置
export const TIME_PRESETS = [15, 25, 45, 60, 90]; // 预设时长（分钟）

// 颜色配置
export const TASK_COLORS = {
  blue: '#4A90E2',
  gray: '#8E8E93',
  green: '#5AC8A8',
  orange: '#F5A623',
  red: '#E94B3C',
  purple: '#9B59B6'
};

// 优先级配置
export const PRIORITY_CONFIG = {
  P0: { label: '紧急', color: '#E94B3C' },
  P1: { label: '重要', color: '#F5A623' },
  P2: { label: '普通', color: '#4A90E2' }
};

// 预设主题
export const PRESET_THEMES = [
  {
    id: 'light',
    name: '浅色主题',
    primaryColor: '#4A90E2',
    backgroundColor: '#F5F5F7',
    cardColor: '#FFFFFF',
    textColor: '#1D1D1F',
    accentColor: '#5AC8A8',
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
    name: '暖色主题',
    primaryColor: '#FF9500',
    backgroundColor: '#FFF8F0',
    cardColor: '#FFFFFF',
    textColor: '#2D2D2D',
    accentColor: '#FF6B6B',
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
export const STORAGE_KEYS = {
  MOOD_ENTRIES: 'mood_entries',
  TASKS: 'tasks',
  SCHEDULES: 'schedules',
  FOCUS_SESSIONS: 'focus_sessions',
  REST_SESSIONS: 'rest_sessions',
  USER_SETTINGS: 'user_settings',
  USER_INFO: 'user_info',
  CUSTOM_THEMES: 'custom_themes',
  CURRENT_THEME: 'current_theme'
};

// 日志域
export const LOG_DOMAIN = 0x0001;
