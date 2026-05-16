/**
 * 数据管理器
 * 封装 Preferences 存储操作
 */

import { preferences } from '@kit.ArkData';
import { MoodEntry, Task, Schedule, FocusSession, RestSession, UserSettings, UserInfo, ThemeConfig, ScheduleArchiveEntry } from '../models/DataModels';
import { StorageKeys, PRESET_THEMES } from './Constants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CURRENT_DATA_SCHEMA_VERSION, DataMigration } from './DataMigration';

const LOG_DOMAIN = 0x0001;
const TAG = 'DataManager';

export class DataManager {
  private static dataPreferences: preferences.Preferences | null = null;

  /**
   * 初始化数据存储
   */
  static async init(context: Context): Promise<void> {
    try {
      const options: preferences.Options = { name: 'FlowStateData' };
      DataManager.dataPreferences = await preferences.getPreferences(context, options);
      await DataManager.migrateDataIfNeeded();
      hilog.info(LOG_DOMAIN, TAG, 'DataManager initialized');
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to init DataManager: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 保存数据
   */
  private static async saveData<T>(key: string, data: T): Promise<void> {
    if (!DataManager.dataPreferences) return;
    try {
      await DataManager.dataPreferences.put(key, JSON.stringify(data));
      await DataManager.dataPreferences.flush();
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to save data: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 读取数据
   */
  private static async getData<T>(key: string, defaultValue: T): Promise<T> {
    if (!DataManager.dataPreferences) return defaultValue;
    try {
      const value = await DataManager.dataPreferences.get(key, '') as string;
      if (value) {
        return JSON.parse(value) as T;
      }
      return defaultValue;
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to get data: %{public}s', JSON.stringify(err));
      return defaultValue;
    }
  }

  // ==================== 情绪签到相关 ====================

  /**
   * 保存情绪签到记录
   */
  static async saveMoodEntry(entry: MoodEntry): Promise<void> {
    const entries = await DataManager.getAllMoodEntries();
    entries.push(entry);
    await DataManager.saveData(StorageKeys.MOOD_ENTRIES, entries);
  }

  /**
   * 获取所有情绪记录
   */
  static async getAllMoodEntries(): Promise<MoodEntry[]> {
    return await DataManager.getData<MoodEntry[]>(StorageKeys.MOOD_ENTRIES, []);
  }

  /**
   * 获取今日情绪记录
   */
  static async getTodayMoodEntries(): Promise<MoodEntry[]> {
    const entries = await DataManager.getAllMoodEntries();
    const today = new Date().setHours(0, 0, 0, 0);
    return entries.filter(entry => entry.timestamp >= today);
  }

  /**
   * 获取最近的情绪记录
   */
  static async getRecentMoodEntry(): Promise<MoodEntry | null> {
    const entries = await DataManager.getAllMoodEntries();
    return entries.length > 0 ? entries[entries.length - 1] : null;
  }

  // ==================== 任务相关 ====================

  /**
   * 保存任务
   */
  static async saveTask(task: Task): Promise<void> {
    const tasks = await DataManager.getAllTasks();
    const index = tasks.findIndex(t => t.id === task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.push(task);
    }
    await DataManager.saveData(StorageKeys.TASKS, tasks);
  }

  /**
   * 获取所有任务
   */
  static async getAllTasks(): Promise<Task[]> {
    return await DataManager.getData<Task[]>(StorageKeys.TASKS, []);
  }

  /**
   * 删除任务
   */
  static async deleteTask(taskId: string): Promise<void> {
    const tasks = await DataManager.getAllTasks();
    const filtered = tasks.filter(t => t.id !== taskId);
    await DataManager.saveData(StorageKeys.TASKS, filtered);
  }

  /**
   * 获取任务
   */
  static async getTask(taskId: string): Promise<Task | null> {
    const tasks = await DataManager.getAllTasks();
    return tasks.find(t => t.id === taskId) || null;
  }

  // ==================== 日程相关 ====================

  /**
   * 保存日程
   */
  static async saveSchedule(schedule: Schedule): Promise<void> {
    const schedules = await DataManager.getAllSchedules();
    const index = schedules.findIndex(s => s.id === schedule.id);
    if (index >= 0) {
      schedules[index] = schedule;
    } else {
      schedules.push(schedule);
    }
    await DataManager.saveData(StorageKeys.SCHEDULES, schedules);
  }

  /**
   * 获取所有日程
   */
  static async getAllSchedules(): Promise<Schedule[]> {
    return await DataManager.getData<Schedule[]>(StorageKeys.SCHEDULES, []);
  }

  /**
   * 删除日程
   */
  static async deleteSchedule(scheduleId: string): Promise<void> {
    const schedules = await DataManager.getAllSchedules();
    const filtered = schedules.filter(s => s.id !== scheduleId);
    await DataManager.saveData(StorageKeys.SCHEDULES, filtered);
  }

  /**
   * 获取任务的所有日程
   */
  static async getTaskSchedules(taskId: string): Promise<Schedule[]> {
    const schedules = await DataManager.getAllSchedules();
    return schedules.filter(s => s.taskId === taskId);
  }

  // ==================== 专注记录相关 ====================

  /**
   * 保存专注记录
   */
  static async saveScheduleArchiveEntry(entry: ScheduleArchiveEntry): Promise<void> {
    const entries = await DataManager.getAllScheduleArchiveEntries();
    entries.push(entry);
    await DataManager.saveData(StorageKeys.SCHEDULE_ARCHIVE, entries);
  }

  private static async migrateDataIfNeeded(): Promise<void> {
    const storedVersion = await DataManager.getData<number>(StorageKeys.DATA_SCHEMA_VERSION, 1);
    if (storedVersion >= CURRENT_DATA_SCHEMA_VERSION) return;

    if (storedVersion < 2) {
      await DataManager.saveData(StorageKeys.MOOD_ENTRIES, DataMigration.normalizeMoodEntries(await DataManager.getData<MoodEntry[]>(StorageKeys.MOOD_ENTRIES, [])));
      await DataManager.saveData(StorageKeys.TASKS, DataMigration.normalizeTasks(await DataManager.getData<Task[]>(StorageKeys.TASKS, [])));
      await DataManager.saveData(StorageKeys.SCHEDULES, DataMigration.normalizeSchedules(await DataManager.getData<Schedule[]>(StorageKeys.SCHEDULES, [])));
      await DataManager.saveData(StorageKeys.SCHEDULE_ARCHIVE, DataMigration.normalizeScheduleArchive(await DataManager.getData<ScheduleArchiveEntry[]>(StorageKeys.SCHEDULE_ARCHIVE, [])));
      await DataManager.saveData(StorageKeys.FOCUS_SESSIONS, DataMigration.normalizeFocusSessions(await DataManager.getData<FocusSession[]>(StorageKeys.FOCUS_SESSIONS, [])));
      await DataManager.saveData(StorageKeys.REST_SESSIONS, DataMigration.normalizeRestSessions(await DataManager.getData<RestSession[]>(StorageKeys.REST_SESSIONS, [])));
      await DataManager.saveData(StorageKeys.USER_SETTINGS, DataMigration.normalizeUserSettings(await DataManager.getData<UserSettings>(StorageKeys.USER_SETTINGS, {
        defaultFocusTime: 25,
        defaultRestTime: 5,
        dailyCapacityMinutes: 300,
        autoStartRest: false,
        notificationEnabled: true,
        soundEnabled: true,
        vibrationEnabled: false,
        currentTheme: 'light'
      })));
      await DataManager.saveData(StorageKeys.USER_INFO, DataMigration.normalizeUserInfo(await DataManager.getData<UserInfo>(StorageKeys.USER_INFO, {
        isLoggedIn: false
      })));
    }

    await DataManager.saveData(StorageKeys.DATA_SCHEMA_VERSION, CURRENT_DATA_SCHEMA_VERSION);
  }

  static async getAllScheduleArchiveEntries(): Promise<ScheduleArchiveEntry[]> {
    return await DataManager.getData<ScheduleArchiveEntry[]>(StorageKeys.SCHEDULE_ARCHIVE, []);
  }

  static async getScheduleArchiveEntriesInRange(startTime: number, endTime: number): Promise<ScheduleArchiveEntry[]> {
    const entries = await DataManager.getAllScheduleArchiveEntries();
    return entries.filter(entry => entry.archivedAt >= startTime && entry.archivedAt <= endTime);
  }

  static async saveFocusSession(session: FocusSession): Promise<void> {
    const sessions = await DataManager.getAllFocusSessions();
    const index = sessions.findIndex(s => s.id === session.id);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.push(session);
    }
    await DataManager.saveData(StorageKeys.FOCUS_SESSIONS, sessions);
  }

  /**
   * 获取所有专注记录
   */
  static async getAllFocusSessions(): Promise<FocusSession[]> {
    return await DataManager.getData<FocusSession[]>(StorageKeys.FOCUS_SESSIONS, []);
  }

  /**
   * 获取今日专注记录
   */
  static async getTodayFocusSessions(): Promise<FocusSession[]> {
    const sessions = await DataManager.getAllFocusSessions();
    const today = new Date().setHours(0, 0, 0, 0);
    return sessions.filter(s => s.startTime >= today);
  }

  /**
   * 获取日期范围内的专注记录
   */
  static async getFocusSessionsInRange(startTime: number, endTime: number): Promise<FocusSession[]> {
    const sessions = await DataManager.getAllFocusSessions();
    return sessions.filter(s => s.startTime >= startTime && s.startTime <= endTime);
  }

  // ==================== 用户设置相关 ====================

  /**
   * 保存用户设置
   */
  static async saveUserSettings(settings: UserSettings): Promise<void> {
    await DataManager.saveData(StorageKeys.USER_SETTINGS, settings);
  }

  /**
   * 获取用户设置
   */
  static async getUserSettings(): Promise<UserSettings> {
    const defaults: UserSettings = {
      defaultFocusTime: 25,
      defaultRestTime: 5,
      dailyCapacityMinutes: 300,
      autoStartRest: false,
      notificationEnabled: true,
      soundEnabled: true,
      vibrationEnabled: false,
      currentTheme: 'light'
    };
    const settings = await DataManager.getData<UserSettings>(StorageKeys.USER_SETTINGS, defaults);
    return {
      defaultFocusTime: settings.defaultFocusTime || defaults.defaultFocusTime,
      defaultRestTime: settings.defaultRestTime || defaults.defaultRestTime,
      dailyCapacityMinutes: settings.dailyCapacityMinutes || defaults.dailyCapacityMinutes,
      autoStartRest: settings.autoStartRest === undefined ? defaults.autoStartRest : settings.autoStartRest,
      notificationEnabled: settings.notificationEnabled === undefined ? defaults.notificationEnabled : settings.notificationEnabled,
      soundEnabled: settings.soundEnabled === undefined ? defaults.soundEnabled : settings.soundEnabled,
      vibrationEnabled: settings.vibrationEnabled === undefined ? defaults.vibrationEnabled : settings.vibrationEnabled,
      currentTheme: settings.currentTheme || defaults.currentTheme
    };
  }

  // ==================== 用户信息相关 ====================

  /**
   * 保存用户信息
   */
  static async saveUserInfo(userInfo: UserInfo): Promise<void> {
    await DataManager.saveData(StorageKeys.USER_INFO, userInfo);
  }

  /**
   * 获取用户信息
   */
  static async getUserInfo(): Promise<UserInfo> {
    return await DataManager.getData<UserInfo>(StorageKeys.USER_INFO, {
      isLoggedIn: false
    });
  }

  // ==================== 主题相关 ====================

  /**
   * 保存自定义主题
   */
  static async saveCustomTheme(theme: ThemeConfig): Promise<void> {
    const themes = await DataManager.getCustomThemes();
    const index = themes.findIndex(t => t.id === theme.id);
    if (index >= 0) {
      themes[index] = theme;
    } else {
      themes.push(theme);
    }
    await DataManager.saveData(StorageKeys.CUSTOM_THEMES, themes);
  }

  /**
   * 获取自定义主题列表
   */
  static async getCustomThemes(): Promise<ThemeConfig[]> {
    return await DataManager.getData<ThemeConfig[]>(StorageKeys.CUSTOM_THEMES, []);
  }

  /**
   * 获取所有主题（预设+自定义）
   */
  static async getAllThemes(): Promise<ThemeConfig[]> {
    const customThemes = await DataManager.getCustomThemes();
    return [...PRESET_THEMES, ...customThemes];
  }

  /**
   * 获取当前主题
   */
  static async getCurrentTheme(): Promise<ThemeConfig> {
    const settings = await DataManager.getUserSettings();
    const allThemes = await DataManager.getAllThemes();
    return allThemes.find(t => t.id === settings.currentTheme) || PRESET_THEMES[0];
  }

  /**
   * 设置当前主题
   */
  static async setCurrentTheme(themeId: string): Promise<void> {
    const settings = await DataManager.getUserSettings();
    settings.currentTheme = themeId;
    await DataManager.saveUserSettings(settings);
  }

  // ==================== 统计相关 ====================

  /**
   * 获取今日总专注时长（分钟）
   */
  static async getTodayTotalFocusTime(): Promise<number> {
    const sessions = await DataManager.getTodayFocusSessions();
    return sessions.reduce((sum, s) => sum + (s.completed ? s.duration : 0), 0);
  }

  /**
   * 获取今日完成的专注次数
   */
  static async getTodayCompletedCount(): Promise<number> {
    const sessions = await DataManager.getTodayFocusSessions();
    return sessions.filter(s => s.completed).length;
  }

  /**
   * 清除所有数据
   */
  static async clearAllData(): Promise<void> {
    if (!DataManager.dataPreferences) return;
    try {
      await DataManager.dataPreferences.clear();
      await DataManager.dataPreferences.flush();
      hilog.info(LOG_DOMAIN, TAG, 'All data cleared');
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, 'Failed to clear data: %{public}s', JSON.stringify(err));
    }
  }
}
