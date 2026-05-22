/**
 * PreferencesHelper.ets
 * 用户偏好持久化工具类。
 * 封装 @kit.ArkData 的 preferences 模块，提供同步读取与异步写入接口。
 * 在 FlowAbility.onCreate() 中调用 init(context) 完成初始化，之后可在任意位置调用
 * getLanguage() / saveLanguage()，无需再持有 context 引用。
 */
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Context } from '@kit.AbilityKit';
import {
  KEY_APP_LANGUAGE,
  KEY_CUSTOM_THEME_TOKENS,
  KEY_THEME_ID,
  LANG_ZH_CN,
  LOG_DOMAIN,
  PREFS_KEY_FONT_SCALE,
  PREFS_KEY_NOTIF_MESSAGE,
  PREFS_STORE_NAME
} from '../constants/AppConstants';
import { DEFAULT_THEME_ID } from '../constants/ThemeConstants';

/** 用户偏好持久化工具类 */
export class PreferencesHelper {
  /** 偏好设置实例，由 init() 同步初始化后可安全访问 */
  private static store: preferences.Preferences | null = null;

  /**
   * 初始化偏好设置实例，应在 FlowAbility.onCreate() 中调用一次，早于任何 UI 加载。
   * 使用同步 API 确保初始化完成后立即可读取已保存的值。
   * @param context UIAbility 上下文，用于确定偏好设置文件的沙箱路径
   */
  static init(context: Context): void {
    try {
      PreferencesHelper.store = preferences.getPreferencesSync(context, { name: PREFS_STORE_NAME });
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '初始化偏好设置失败：%{public}s', JSON.stringify(err));
    }
  }

  /**
   * 同步读取已保存的语言标识。
   * 若未初始化或读取失败，则返回默认语言（简体中文）。
   * @returns 已保存的语言标识字符串
   */
  static getLanguage(): string {
    try {
      return PreferencesHelper.store?.getSync(KEY_APP_LANGUAGE, LANG_ZH_CN) as string ?? LANG_ZH_CN;
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '读取语言偏好失败：%{public}s', JSON.stringify(err));
      return LANG_ZH_CN;
    }
  }

  /**
   * 持久化保存语言标识。
   * putSync 同步写入内存缓存，flush 异步将缓存落盘。
   * 即使应用在 flush 完成前被杀死，下次 flush 成功后也会补存数据；
   * 对用户手动切换语言的场景，flush 通常在 app 进入后台前完成。
   * @param language 目标语言标识（如 'zh_CN'、'en_US'）
   */
  static saveLanguage(language: string): void {
    if (!PreferencesHelper.store) {
      hilog.warn(LOG_DOMAIN, 'PreferencesHelper', '偏好设置未初始化，跳过语言保存');
      return;
    }
    try {
      PreferencesHelper.store.putSync(KEY_APP_LANGUAGE, language);
      PreferencesHelper.store.flush().catch((err: Error) => {
        hilog.error(LOG_DOMAIN, 'PreferencesHelper', '语言偏好写盘失败：%{public}s', JSON.stringify(err));
      });
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '保存语言偏好失败：%{public}s', JSON.stringify(err));
    }
  }

  /**
   * 同步读取已保存的主题 ID。
   * 若未初始化或读取失败，则返回默认主题（清晨）。
   * @returns 已保存的主题 ID 字符串
   */
  static getThemeId(): string {
    try {
      return PreferencesHelper.store?.getSync(KEY_THEME_ID, DEFAULT_THEME_ID) as string ?? DEFAULT_THEME_ID;
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '读取主题 ID 失败：%{public}s', JSON.stringify(err));
      return DEFAULT_THEME_ID;
    }
  }

  /**
   * 持久化保存主题 ID。
   * @param themeId 目标主题 ID（如 'light'、'dark'、'custom'）
   */
  static saveThemeId(themeId: string): void {
    if (!PreferencesHelper.store) {
      hilog.warn(LOG_DOMAIN, 'PreferencesHelper', '偏好设置未初始化，跳过主题 ID 保存');
      return;
    }
    try {
      PreferencesHelper.store.putSync(KEY_THEME_ID, themeId);
      PreferencesHelper.store.flush().catch((err: Error) => {
        hilog.error(LOG_DOMAIN, 'PreferencesHelper', '主题 ID 写盘失败：%{public}s', JSON.stringify(err));
      });
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '保存主题 ID 失败：%{public}s', JSON.stringify(err));
    }
  }

  /**
   * 同步读取已保存的自定义主题 tokens（JSON 字符串格式）。
   * 返回空字符串表示尚无自定义主题记录。
   * @returns 自定义主题 JSON 字符串，未保存时返回空字符串
   */
  static getCustomThemeTokens(): string {
    try {
      return PreferencesHelper.store?.getSync(KEY_CUSTOM_THEME_TOKENS, '') as string ?? '';
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '读取自定义主题失败：%{public}s', JSON.stringify(err));
      return '';
    }
  }

  /**
   * 持久化保存自定义主题 tokens（JSON 字符串格式）。
   * @param json 自定义主题的 ThemeTokens 序列化 JSON
   */
  static saveCustomThemeTokens(json: string): void {
    if (!PreferencesHelper.store) {
      hilog.warn(LOG_DOMAIN, 'PreferencesHelper', '偏好设置未初始化，跳过自定义主题保存');
      return;
    }
    try {
      PreferencesHelper.store.putSync(KEY_CUSTOM_THEME_TOKENS, json);
      PreferencesHelper.store.flush().catch((err: Error) => {
        hilog.error(LOG_DOMAIN, 'PreferencesHelper', '自定义主题写盘失败：%{public}s', JSON.stringify(err));
      });
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '保存自定义主题失败：%{public}s', JSON.stringify(err));
    }
  }

  // ── 全局通知设置 ────────────────────────────────────────────────────────────

  /**
   * 同步读取全局默认通知消息文本。
   * @returns 消息文本，默认空字符串（App 自动生成）
   */
  static getNotifMessage(): string {
    try {
      return PreferencesHelper.store?.getSync(PREFS_KEY_NOTIF_MESSAGE, '') as string ?? '';
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '读取通知消息失败：%{public}s', JSON.stringify(err));
      return '';
    }
  }

  /**
   * 持久化保存全局默认通知消息文本。
   * @param message 自定义消息文本，空字符串表示使用 App 自动生成
   */
  static saveNotifMessage(message: string): void {
    if (!PreferencesHelper.store) {
      return;
    }
    try {
      PreferencesHelper.store.putSync(PREFS_KEY_NOTIF_MESSAGE, message);
      PreferencesHelper.store.flush().catch((err: Error) => {
        hilog.error(LOG_DOMAIN, 'PreferencesHelper', '通知消息写盘失败：%{public}s', JSON.stringify(err));
      });
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '保存通知消息失败：%{public}s', JSON.stringify(err));
    }
  }

  // ── 字体缩放倍数 ────────────────────────────────────────────────────────────

  /**
   * 同步读取已保存的字体缩放倍数。
   * 值以数字字符串形式存储（如 "1.0"、"0.85"），读取后解析为 number。
   * @returns 缩放倍数（0.8～1.5），默认 1.0
   */
  static getFontScale(): number {
    try {
      const stored: string = PreferencesHelper.store?.getSync(PREFS_KEY_FONT_SCALE, '1.0') as string ?? '1.0';
      const scale: number = Number(stored);
      return (isNaN(scale) || scale < 0.8 || scale > 1.5) ? 1.0 : scale;
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '读取字体缩放倍数失败：%{public}s', JSON.stringify(err));
      return 1.0;
    }
  }

  /**
   * 持久化保存字体缩放倍数。
   * @param scale 缩放倍数（0.8～1.5），存储为数字字符串
   */
  static saveFontScale(scale: number): void {
    if (!PreferencesHelper.store) {
      hilog.warn(LOG_DOMAIN, 'PreferencesHelper', '偏好设置未初始化，跳过字体缩放保存');
      return;
    }
    try {
      PreferencesHelper.store.putSync(PREFS_KEY_FONT_SCALE, scale.toString());
      PreferencesHelper.store.flush().catch((err: Error) => {
        hilog.error(LOG_DOMAIN, 'PreferencesHelper', '字体缩放写盘失败：%{public}s', JSON.stringify(err));
      });
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'PreferencesHelper', '保存字体缩放失败：%{public}s', JSON.stringify(err));
    }
  }
}
