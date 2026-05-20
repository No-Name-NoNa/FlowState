/**
 * SettingsViewModel.ets
 * 设置页的 ViewModel 层。
 * 负责封装语言偏好的读取与写入逻辑，
 * 视图层只需调用此类的静态方法，不直接操作 AppStorage。
 */
import { KEY_APP_LANGUAGE, LANG_ZH_CN } from '../constants/AppConstants';

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
   * 写入 AppStorage 后，所有绑定 @StorageLink('appLanguage') 的组件将自动触发重渲染。
   * @param language 目标语言标识（如 'zh_CN' 或 'en_US'）
   */
  static setLanguage(language: string): void {
    AppStorage.setOrCreate<string>(KEY_APP_LANGUAGE, language);
  }
}
