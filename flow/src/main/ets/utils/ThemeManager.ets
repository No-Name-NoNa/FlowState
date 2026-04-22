/**
 * 主题管理器
 * 管理应用主题切换和自定义主题
 */

import { ThemeConfig } from '../models/DataModels';
import { DataManager } from './DataManager';

export class ThemeManager {
  private static currentTheme: ThemeConfig | null = null;
  private static themeChangeCallbacks: ((theme: ThemeConfig) => void)[] = [];

  /**
   * 初始化主题管理器
   */
  static async init(): Promise<void> {
    this.currentTheme = await DataManager.getCurrentTheme();
  }

  /**
   * 获取当前主题
   */
  static async getCurrentTheme(): Promise<ThemeConfig> {
    if (!this.currentTheme) {
      this.currentTheme = await DataManager.getCurrentTheme();
    }
    return this.currentTheme;
  }

  /**
   * 切换主题
   */
  static async setTheme(themeId: string): Promise<void> {
    await DataManager.setCurrentTheme(themeId);
    this.currentTheme = await DataManager.getCurrentTheme();
    this.notifyThemeChange();
  }

  /**
   * 保存自定义主题
   */
  static async saveCustomTheme(theme: ThemeConfig): Promise<void> {
    await DataManager.saveCustomTheme(theme);
  }

  /**
   * 获取所有可用主题
   */
  static async getAllThemes(): Promise<ThemeConfig[]> {
    return await DataManager.getAllThemes();
  }

  /**
   * 注册主题变化回调
   */
  static registerThemeChangeCallback(callback: (theme: ThemeConfig) => void): void {
    this.themeChangeCallbacks.push(callback);
  }

  /**
   * 取消注册主题变化回调
   */
  static unregisterThemeChangeCallback(callback: (theme: ThemeConfig) => void): void {
    const index = this.themeChangeCallbacks.indexOf(callback);
    if (index > -1) {
      this.themeChangeCallbacks.splice(index, 1);
    }
  }

  /**
   * 通知主题变化
   */
  private static notifyThemeChange(): void {
    if (this.currentTheme) {
      this.themeChangeCallbacks.forEach(callback => callback(this.currentTheme!));
    }
  }

  /**
   * 根据图片生成主题（提取主色调）
   */
  static createThemeFromImage(imagePath: string, themeName: string, isDark: boolean): ThemeConfig {
    // 这里简化处理，实际应用中可以使用图像处理库提取主色调
    const themeId = `custom_${Date.now()}`;

    return {
      id: themeId,
      name: themeName,
      primaryColor: isDark ? '#0A84FF' : '#4A90E2',
      backgroundColor: isDark ? '#1C1C1E' : '#F5F5F7',
      cardColor: isDark ? '#2C2C2E' : '#FFFFFF',
      textColor: isDark ? '#F5F5F7' : '#1D1D1F',
      accentColor: isDark ? '#30D158' : '#5AC8A8',
      backgroundImage: imagePath,
      isDark: isDark
    };
  }

  /**
   * 验证主题配置
   */
  static validateThemeConfig(theme: ThemeConfig): boolean {
    return !!(
      theme.id &&
      theme.name &&
      theme.primaryColor &&
      theme.backgroundColor &&
      theme.cardColor &&
      theme.textColor &&
      theme.accentColor
    );
  }
}
