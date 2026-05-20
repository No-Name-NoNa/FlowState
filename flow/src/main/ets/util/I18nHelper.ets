/**
 * I18nHelper.ets
 * 轻量级应用内国际化工具类。
 * 通过静态方法根据传入的语言标识返回对应的界面字符串，
 * 配合 @StorageLink('appLanguage') 实现响应式语言切换。
 */
import { LANG_ZH_CN } from '../constants/AppConstants';

/** 国际化字符串工具类 */
export class I18nHelper {
  /**
   * 获取"首页"Tab 标签文字
   * @param language 语言标识
   * @returns 对应语言的标签字符串
   */
  static getTabHome(language: string): string {
    return language === LANG_ZH_CN ? '首页' : 'Home';
  }

  /**
   * 获取"历史"Tab 标签文字
   * @param language 语言标识
   * @returns 对应语言的标签字符串
   */
  static getTabHistory(language: string): string {
    return language === LANG_ZH_CN ? '历史' : 'History';
  }

  /**
   * 获取首页顶部问候语
   * @param language 语言标识
   * @returns 对应语言的问候字符串
   */
  static getHomeGreeting(language: string): string {
    return language === LANG_ZH_CN ? '今天想做什么？' : "What's on your mind today?";
  }

  /**
   * 获取设置页标题
   * @param language 语言标识
   * @returns 对应语言的标题字符串
   */
  static getSettingsTitle(language: string): string {
    return language === LANG_ZH_CN ? '设置' : 'Settings';
  }

  /**
   * 获取语言设置分区标签
   * @param language 语言标识
   * @returns 对应语言的标签字符串
   */
  static getLanguageLabel(language: string): string {
    return language === LANG_ZH_CN ? '语言' : 'Language';
  }

  /**
   * 获取历史页空状态提示文字
   * @param language 语言标识
   * @returns 对应语言的提示字符串
   */
  static getHistoryEmptyHint(language: string): string {
    return language === LANG_ZH_CN ? '暂无完成记录' : 'No completed tasks yet.';
  }

  /**
   * 获取首页主内容区空状态提示文字
   * @param language 语言标识
   * @returns 对应语言的提示字符串
   */
  static getHomeEmptyHint(language: string): string {
    return language === LANG_ZH_CN ? '轻触下方，开始记录' : 'Tap below to start capturing';
  }
}
