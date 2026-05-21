/**
 * I18nKeys.ets
 * 国际化字符串 key 常量。
 * 统一声明所有 i18n key，避免调用侧出现魔法字符串，方便 IDE 跳转与重命名。
 * 新增 i18n 条目时，同步在 rawfile/i18n/zh_CN.json 和 en_US.json 中添加对应键值对即可。
 */

/** 所有界面字符串的 key 常量 */
export enum I18nKeys {
  TAB_HOME = 'tab_home',
  TAB_HISTORY = 'tab_history',
  HOME_GREETING = 'home_greeting',
  SETTINGS_TITLE = 'settings_title',
  SETTINGS_LANGUAGE_LABEL = 'settings_language_label',
  SETTINGS_LANGUAGE_ZH = 'settings_language_zh',
  SETTINGS_LANGUAGE_EN = 'settings_language_en',
  HISTORY_EMPTY_HINT = 'history_empty_hint',
  HOME_EMPTY_HINT = 'home_empty_hint',
}