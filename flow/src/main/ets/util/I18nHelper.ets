/**
 * I18nHelper.ets
 * 轻量级应用内国际化工具类。
 * 在 FlowAbility.onCreate() 中调用 init(context) 预加载 rawfile JSON 翻译文件，
 * 之后各组件通过 t(key, lang) 查询字符串。
 *
 * 响应式说明：
 *   组件声明 @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string，在 build() 中将
 *   this.currentLanguage 传给 t()，ArkUI 的依赖追踪系统即可感知到该节点依赖语言状态，
 *   语言切换时自动触发重渲染。
 *
 * 新增/修改翻译字符串：只需编辑 resources/rawfile/i18n/{lang}.json，无需改动此文件。
 */
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Context } from '@kit.AbilityKit';
import { LANG_ZH_CN, LANG_EN_US, LOG_DOMAIN } from '../constants/AppConstants';

/** 国际化字符串工具类 */
export class I18nHelper {
  /** 各语言字符串 map，key 为语言标识，value 为该语言的 {字符串key: 翻译值} 映射 */
  private static maps: Map<string, Record<string, string>> = new Map();

  /**
   * 预加载所有语言的翻译文件，应在 FlowAbility.onCreate() 中调用一次。
   * 从 resources/rawfile/i18n/{lang}.json 读取并缓存为内存 map。
   * @param context UIAbility context，用于访问 resourceManager
   */
  static init(context: Context): void {
    const decoder = util.TextDecoder.create('utf-8');
    for (const lang of [LANG_ZH_CN, LANG_EN_US]) {
      try {
        const raw: Uint8Array = context.resourceManager.getRawFileContentSync(`i18n/${lang}.json`);
        const text: string = decoder.decodeToString(raw);
        I18nHelper.maps.set(lang, JSON.parse(text) as Record<string, string>);
      } catch (err) {
        hilog.error(LOG_DOMAIN, 'I18nHelper', '加载翻译文件失败 i18n/%{public}s.json：%{public}s', lang, JSON.stringify(err));
      }
    }
  }

  /**
   * 根据 key 和语言标识查询对应的翻译字符串。
   * lang 参数须传入组件的 @StorageLink(KEY_APP_LANGUAGE) 状态属性（即 this.currentLanguage），
   * 以确保 ArkUI 依赖追踪系统感知到当前节点依赖语言状态，语言切换时自动重渲染。
   * 若 key 不存在则返回 key 本身，不会崩溃。
   * @param key  字符串 key，建议使用 I18nKeys 常量
   * @param lang 当前语言标识，传入组件的 @StorageLink lang 属性
   * @returns 翻译后的字符串
   */
  static t(key: string, lang: string): string {
    const map: Record<string, string> | undefined =
      I18nHelper.maps.get(lang) ?? I18nHelper.maps.get(LANG_ZH_CN);
    return map?.[key] ?? key;
  }
}
