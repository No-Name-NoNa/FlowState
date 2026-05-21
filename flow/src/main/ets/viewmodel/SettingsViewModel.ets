/**
 * SettingsViewModel.ets
 * 设置页的 ViewModel 层。
 * 负责封装语言偏好的读取与写入逻辑，
 * 视图层只需调用此类的静态方法，不直接操作 AppStorage 或持久化存储。
 */
import { KEY_APP_LANGUAGE, LANG_ZH_CN } from '../constants/AppConstants';
import { PreferencesHelper } from '../util/PreferencesHelper';

/** 设置页 ViewModel */
export class SettingsViewModel {
  /**
   * 获取当前语言标识。
   * 若 AppStorage 中尚无记录，则返回默认语言（简体中文）。
   * @returns 当前语言标识字符串
   */
  static getCurrentLanguage(): string {
    return AppStorage.get<string>(KEY_APP_LANGUAGE) ?? LANG_ZH_CN;
  }

  /**
   * 设置并持久化新的语言标识。
   * 1. AppStorage.set 触发全局 @StorageLink 响应式更新，UI 即时切换语言。
   * 2. PreferencesHelper.saveLanguage 将新值写入 @kit.ArkData preferences 文件，
   *    确保 app 重启后仍还原用户选择的语言。
   * @param language 目标语言标识（如 'zh_CN' 或 'en_US'）
   */
  static setLanguage(language: string): void {
    AppStorage.set<string>(KEY_APP_LANGUAGE, language);
    PreferencesHelper.saveLanguage(language);
  }
}
