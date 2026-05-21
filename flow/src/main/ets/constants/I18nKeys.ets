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
  // 主题设置相关 key
  SETTINGS_THEME_LABEL = 'settings_theme_label',
  SETTINGS_THEME_LIGHT = 'settings_theme_light',
  SETTINGS_THEME_DARK = 'settings_theme_dark',
  SETTINGS_THEME_WARM = 'settings_theme_warm',
  SETTINGS_THEME_OCEAN = 'settings_theme_ocean',
  SETTINGS_THEME_FOREST = 'settings_theme_forest',
  SETTINGS_THEME_CUSTOM = 'settings_theme_custom',
  SETTINGS_THEME_CUSTOM_BG = 'settings_theme_custom_bg',
  SETTINGS_THEME_CUSTOM_TEXT = 'settings_theme_custom_text',
  SETTINGS_THEME_CUSTOM_ACCENT = 'settings_theme_custom_accent',
  // 收集箱相关 key
  INBOX_TITLE = 'inbox_title',
  INBOX_NEW_BUTTON = 'inbox_new_button',
  INBOX_EMPTY_HINT = 'inbox_empty_hint',
  INBOX_SEARCH_PLACEHOLDER = 'inbox_search_placeholder',
  INBOX_TAG_ALL = 'inbox_tag_all',
  INBOX_TAG_PLACEHOLDER = 'inbox_tag_placeholder',
  INBOX_EDITOR_TITLE_CREATE = 'inbox_editor_title_create',
  INBOX_EDITOR_TITLE_EDIT = 'inbox_editor_title_edit',
  INBOX_EDITOR_SAVE = 'inbox_editor_save',
  INBOX_EDITOR_TEXT_PLACEHOLDER = 'inbox_editor_text_placeholder',
  INBOX_MENU_PIN = 'inbox_menu_pin',
  INBOX_MENU_UNPIN = 'inbox_menu_unpin',
  INBOX_MENU_EDIT = 'inbox_menu_edit',
  INBOX_MENU_DELETE = 'inbox_menu_delete',
  INBOX_CREATED_AT = 'inbox_created_at',
  INBOX_UPDATED_AT = 'inbox_updated_at',
  INBOX_MENU_MOVE_TO_TOP = 'inbox_menu_move_to_top',
  INBOX_EDITOR_TITLE_PLACEHOLDER = 'inbox_editor_title_placeholder',
  INBOX_EDITOR_CONTENT_PLACEHOLDER = 'inbox_editor_content_placeholder',
}