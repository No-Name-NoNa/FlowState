/**
 * FontSizeHelper.ets
 * 字体大小管理工具类。
 * 负责从 Preferences 恢复字体缩放倍数、应用并写入 AppStorage，
 * 触发全部订阅 @StorageLink(KEY_FONT_TOKENS) 的组件即时重渲染。
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  buildFontTokens, DEFAULT_FONT_TOKENS, FontSizeTokens,
} from '../constants/FontSizeConstants';
import { KEY_FONT_SCALE_ID, KEY_FONT_TOKENS, LOG_DOMAIN } from '../constants/AppConstants';
import { PreferencesHelper } from './PreferencesHelper';

/** 字体大小管理工具类 */
export class FontSizeHelper {
  /**
   * 在 FlowAbility.onCreate() 中调用，从持久化存储恢复字体缩放倍数并写入 AppStorage。
   * 必须在任何页面加载前调用，确保组件初始化时即读到正确的字号 tokens。
   */
  static initFromStorage(): void {
    const scale: number = PreferencesHelper.getFontScale();
    const tokens: FontSizeTokens = buildFontTokens(scale);
    AppStorage.setOrCreate<FontSizeTokens>(KEY_FONT_TOKENS, tokens);
    AppStorage.setOrCreate<string>(KEY_FONT_SCALE_ID, scale.toString());
    hilog.info(LOG_DOMAIN, 'FontSizeHelper', '字体缩放已恢复：×%{public}s', scale.toString());
  }

  /**
   * 切换字体缩放倍数并持久化。
   * 调用后 AppStorage 中的 KEY_FONT_TOKENS 立即更新，触发全局组件重渲染。
   * @param scale 缩放倍数（0.8～1.5，1.0 = 100%）
   */
  static applyFontScale(scale: number): void {
    const tokens: FontSizeTokens = buildFontTokens(scale);
    // 必须传入新对象引用，才能触发 @StorageLink 响应式更新
    AppStorage.set<FontSizeTokens>(KEY_FONT_TOKENS, tokens);
    AppStorage.set<string>(KEY_FONT_SCALE_ID, scale.toString());
    PreferencesHelper.saveFontScale(scale);
    hilog.info(LOG_DOMAIN, 'FontSizeHelper', '字体缩放已切换：×%{public}s', scale.toString());
  }

  /**
   * 获取默认 FontSizeTokens（标准档 ×1.0），供组件声明 @StorageLink 时提供初始值。
   * @returns 默认 FontSizeTokens 对象
   */
  static getDefault(): FontSizeTokens {
    return DEFAULT_FONT_TOKENS;
  }
}
