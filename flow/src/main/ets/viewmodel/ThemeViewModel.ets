/**
 * ThemeViewModel.ets
 * 主题设置 ViewModel 层。
 * 封装主题切换与自定义主题配色的读写逻辑，
 * 视图层只需调用此类的静态方法，不直接操作 AppStorage 或持久化存储。
 */
import { ThemeId, ThemeTokens } from '../constants/ThemeConstants';
import { KEY_THEME_ID } from '../constants/AppConstants';
import { ThemeHelper } from '../util/ThemeHelper';

/** 主题设置 ViewModel */
export class ThemeViewModel {
  /**
   * 获取当前主题 ID。
   * @returns 当前主题 ID 字符串
   */
  static getCurrentThemeId(): string {
    return AppStorage.get<string>(KEY_THEME_ID) ?? ThemeId.LIGHT;
  }

  /**
   * 切换为指定预设主题并立即刷新全局 UI。
   * @param themeId 目标主题 ID（非 CUSTOM 的预设主题 ID）
   */
  static setTheme(themeId: string): void {
    ThemeHelper.applyTheme(themeId);
  }

  /**
   * 根据三个基准色构建自定义主题，立即应用并持久化保存。
   * @param bg          自定义背景色（#RRGGBB）
   * @param textPrimary 自定义主文本色（#RRGGBB）
   * @param accent      自定义强调色（#RRGGBB）
   */
  static setCustomTheme(bg: string, textPrimary: string, accent: string): void {
    const tokens: ThemeTokens = ThemeHelper.buildCustomTokens(bg, textPrimary, accent);
    ThemeHelper.applyAndSaveCustomTheme(tokens);
  }

  /**
   * 读取用户上次保存的自定义主题配色，供设置页初始化自定义编辑面板使用。
   * @returns 已保存的自定义 ThemeTokens，未保存时返回清晨主题作为初始配色
   */
  static getCustomThemeTokens(): ThemeTokens {
    return ThemeHelper.loadSavedCustomTokens();
  }
}
