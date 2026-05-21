/**
 * AppConstants.ets
 * 全局应用常量定义文件。
 * 统一管理 AppStorage 键名及其他应用级常量，禁止在组件内散落硬编码的键名字符串。
 */

/** AppStorage：当前语言标识键名 */
export const KEY_APP_LANGUAGE: string = 'appLanguage';

/** AppStorage：当前主题 ID 键名 */
export const KEY_THEME_ID: string = 'appThemeId';

/** AppStorage：当前主题颜色 token 键名（值为 ThemeTokens 对象） */
export const KEY_THEME_TOKENS: string = 'appThemeTokens';

/** Preferences：自定义主题颜色 token 存储键名（以 JSON 字符串序列化保存） */
export const KEY_CUSTOM_THEME_TOKENS: string = 'customThemeTokens';

/** 输入校验：HEX 颜色值非法时的提示边框色（通用错误红） */
export const COLOR_INPUT_ERROR: string = '#FF4444';

/** 支持的语言标识：简体中文 */
export const LANG_ZH_CN: string = 'zh_CN';

/** 支持的语言标识：英语 */
export const LANG_EN_US: string = 'en_US';

/** 日志域标识 */
export const LOG_DOMAIN: number = 0x0001;

/** 用户偏好设置文件名（对应 app 沙箱目录下的 preferences 文件） */
export const PREFS_STORE_NAME: string = 'app_preferences';

/**
 * 分隔线宽度。
 * Divider.strokeWidth() 的 SDK 声明为 strokeWidth(value: number | string)，
 * 不接受 Resource 类型，故此处以字符串常量统一管理，与 float.json 中的 0.5vp 保持一致。
 */
export const DIVIDER_STROKE_WIDTH: string = '0.5vp';
