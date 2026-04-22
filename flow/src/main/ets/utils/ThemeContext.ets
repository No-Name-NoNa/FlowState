/**
 * 主题上下文管理
 * 使用AppStorage进行全局主题状态管理
 */

import { ThemeConfig } from '../models/DataModels';
import { PRESET_THEMES } from './Constants';

export class ThemeContext {
  private static readonly THEME_KEY = 'currentThemeConfig';

  /**
   * 初始化主题上下文
   */
  static init(theme: ThemeConfig): void {
    AppStorage.setOrCreate(ThemeContext.THEME_KEY, theme);
  }

  /**
   * 获取当前主题
   */
  static getCurrentTheme(): ThemeConfig {
    return AppStorage.get<ThemeConfig>(ThemeContext.THEME_KEY) || PRESET_THEMES[0];
  }

  /**
   * 更新主题
   */
  static updateTheme(theme: ThemeConfig): void {
    AppStorage.set(ThemeContext.THEME_KEY, theme);
  }

  /**
   * 获取主题链接（用于@StorageLink）
   */
  static getThemeLink(): string {
    return ThemeContext.THEME_KEY;
  }
}
