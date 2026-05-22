/**
 * ThemeHelper.ets
 * 主题管理工具类。
 * 负责主题应用、自定义 token 推导和预设主题数据访问。
 * 通过 AppStorage 更新 KEY_THEME_TOKENS 和 KEY_THEME_ID，
 * 触发全部订阅 @StorageLink 的组件即时重渲染，实现主题无重启刷新。
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  DEFAULT_THEME_TOKENS,
  getPresetTokens,
  PRESET_THEME_PREVIEWS,
  THEME_LIGHT,
  ThemeId,
  ThemePreview,
  ThemeTokens,
} from '../constants/ThemeConstants';
import { KEY_THEME_ID, KEY_THEME_TOKENS, LOG_DOMAIN, } from '../constants/AppConstants';
import { PreferencesHelper } from './PreferencesHelper';

/** 主题管理工具类 */
export class ThemeHelper {
  /**
   * 应用指定主题并持久化主题 ID。
   * 对于预设主题，直接使用对应的 tokens；
   * 对于自定义主题，必须同时传入 customTokens。
   * 调用后 AppStorage 中的 KEY_THEME_TOKENS 立即更新，触发全局组件重渲染。
   * @param themeId       目标主题 ID
   * @param customTokens  自定义主题时必须传入的完整 tokens（预设主题可不传）
   */
  static applyTheme(themeId: string, customTokens?: ThemeTokens): void {
    let tokens: ThemeTokens;
    if (themeId === ThemeId.CUSTOM && customTokens !== undefined) {
      tokens = customTokens;
    } else {
      tokens = getPresetTokens(themeId);
    }
    // 必须传入新对象引用，才能触发 @StorageLink 响应式更新
    AppStorage.set<ThemeTokens>(KEY_THEME_TOKENS, tokens);
    AppStorage.set<string>(KEY_THEME_ID, themeId);
    PreferencesHelper.saveThemeId(themeId);
  }

  /**
   * 应用并持久化保存自定义主题。
   * @param customTokens 完整的自定义主题 tokens
   */
  static applyAndSaveCustomTheme(customTokens: ThemeTokens): void {
    const json: string = JSON.stringify(customTokens);
    PreferencesHelper.saveCustomThemeTokens(json);
    ThemeHelper.applyTheme(ThemeId.CUSTOM, customTokens);
  }

  /**
   * 从 Preferences 中读取已保存的自定义主题 tokens。
   * 若未保存或解析失败，则返回清晨主题作为自定义编辑器的初始配色。
   * @returns 已保存的自定义 ThemeTokens
   */
  static loadSavedCustomTokens(): ThemeTokens {
    const json: string = PreferencesHelper.getCustomThemeTokens();
    if (json === '') {
      return THEME_LIGHT;
    }
    try {
      return JSON.parse(json) as ThemeTokens;
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'ThemeHelper', '解析自定义主题失败：%{public}s', JSON.stringify(err));
      return THEME_LIGHT;
    }
  }

  /**
   * 在 FlowAbility.onCreate() 中调用，从持久化存储恢复主题并写入 AppStorage。
   * 必须在任何页面加载前调用，确保组件初始化时即读到正确的主题 tokens。
   */
  static initFromStorage(): void {
    const themeId: string = PreferencesHelper.getThemeId();
    let tokens: ThemeTokens;
    if (themeId === ThemeId.CUSTOM) {
      tokens = ThemeHelper.loadSavedCustomTokens();
    } else {
      tokens = getPresetTokens(themeId);
    }
    AppStorage.setOrCreate<ThemeTokens>(KEY_THEME_TOKENS, tokens);
    AppStorage.setOrCreate<string>(KEY_THEME_ID, themeId);
  }

  /**
   * 根据三个基准色构建完整的 ThemeTokens。
   * 次要文本色和分隔线通过与背景色线性混合推导，保持配色和谐统一。
   * @param bg          背景色（#RRGGBB）
   * @param textPrimary 主文本色（#RRGGBB）
   * @param accent      强调色（#RRGGBB）
   * @returns 完整的 ThemeTokens 对象
   */
  static buildCustomTokens(bg: string, textPrimary: string, accent: string): ThemeTokens {
    // 次要文本色：主文本色与背景色 50% 混合
    const textSecondary: string = ThemeHelper.blendColors(textPrimary, bg, 0.5);
    // 分隔线：主文本色与背景色 12% 混合（极淡）
    const divider: string = ThemeHelper.blendColors(textPrimary, bg, 0.12);
    // Tab 未选中色：主文本色与背景色 40% 混合
    const tabNormal: string = ThemeHelper.blendColors(textPrimary, bg, 0.4);
    return {
      colorBackground: bg,
      colorTextPrimary: textPrimary,
      colorTextSecondary: textSecondary,
      colorAccent: accent,
      colorDivider: divider,
      colorTabSelected: accent,
      colorTabNormal: tabNormal,
      colorTabBarBg: bg,
      colorSettingsSelected: accent,
    };
  }

  /**
   * 校验颜色字符串是否为合法的 #RRGGBB 十六进制格式。
   * @param color 待校验的颜色字符串
   * @returns 合法则返回 true
   */
  static isValidHexColor(color: string): boolean {
    if (color.length !== 7 || color.charAt(0) !== '#') {
      return false;
    }
    const hexChars: string = '0123456789ABCDEFabcdef';
    for (let i: number = 1; i < 7; i++) {
      if (hexChars.indexOf(color.charAt(i)) < 0) {
        return false;
      }
    }
    return true;
  }

  /**
   * 返回全部预设主题预览元数据列表（不含 CUSTOM）。
   * @returns ThemePreview 数组
   */
  static getPresetPreviews(): ThemePreview[] {
    return PRESET_THEME_PREVIEWS;
  }

  /**
   * 获取默认的 ThemeTokens（清晨主题），供组件声明 @StorageLink 时提供默认值。
   * @returns 默认 ThemeTokens 对象
   */
  static getDefault(): ThemeTokens {
    return DEFAULT_THEME_TOKENS;
  }

  /**
   * 两色线性混合算法（RGB 分量各自加权插值）。
   * ratio=1 返回 color1 本色，ratio=0 返回 color2 本色。
   * @param color1 起始颜色（#RRGGBB）
   * @param color2 目标颜色（#RRGGBB）
   * @param ratio  color1 的权重 [0, 1]
   * @returns 混合后的颜色（#RRGGBB 大写）
   */
  private static blendColors(color1: string, color2: string, ratio: number): string {
    const r1: number = parseInt(color1.substring(1, 3), 16);
    const g1: number = parseInt(color1.substring(3, 5), 16);
    const b1: number = parseInt(color1.substring(5, 7), 16);
    const r2: number = parseInt(color2.substring(1, 3), 16);
    const g2: number = parseInt(color2.substring(3, 5), 16);
    const b2: number = parseInt(color2.substring(5, 7), 16);
    const r: number = Math.round(r1 * ratio + r2 * (1 - ratio));
    const g: number = Math.round(g1 * ratio + g2 * (1 - ratio));
    const b: number = Math.round(b1 * ratio + b2 * (1 - ratio));
    const toHex = (n: number): string => {
      const hex: string = n.toString(16);
      return hex.length === 1 ? '0' + hex : hex;
    };
    return ('#' + toHex(r) + toHex(g) + toHex(b)).toUpperCase();
  }
}
