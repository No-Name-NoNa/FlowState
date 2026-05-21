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
import { KEY_APP_LANGUAGE, LANG_ZH_CN, LOG_DOMAIN, PREFS_STORE_NAME } from '../constants/AppConstants';

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
}
