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

/** AppStorage：全局默认提醒类型键名（值为 TaskReminderType number）已废弃，保留用于向后兼容 */

/** Preferences：全局默认通知消息文本存储键（空字符串 = 使用 App 生成） */
export const PREFS_KEY_NOTIF_MESSAGE: string = 'notif_default_message';

/** 系统默认音效标识（SOUND/ALARM 类型下的默认选项） */
export const NOTIF_SOUND_DEFAULT: string = 'default';

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

/** 收集箱 RDB 数据库文件名 */
export const INBOX_DB_STORE_NAME: string = 'inbox.db';

/** AppStorage：收集箱跨页刷新信号键名（编辑/新建页保存后置 true，首页检测到后刷新并置回 false） */
export const KEY_INBOX_NEEDS_REFRESH: string = 'inboxNeedsRefresh';

/** 任务 RDB 数据库文件名 */
export const TASK_DB_STORE_NAME: string = 'tasks.db';

/** AppStorage：任务列表跨页刷新信号键名（任务编辑/新建页保存后置 true，TaskPage 检测到后刷新并置回 false） */
export const KEY_TASK_NEEDS_REFRESH: string = 'taskNeedsRefresh';

/**
 * 分隔线宽度。
 * Divider.strokeWidth() 的 SDK 声明为 strokeWidth(value: number | string)，
 * 不接受 Resource 类型，故此处以字符串常量统一管理，与 float.json 中的 0.5vp 保持一致。
 */
export const DIVIDER_STROKE_WIDTH: string = '0.5vp';

/** AppStorage：通知点击后需切换到的 Tab 索引（-1 = 无需切换） */
export const KEY_NOTIFY_TAB_INDEX: string = 'notifyTabIndex';

/** WantAgent 参数键：需要被归档的任务 ID（> 0 触发归档） */
export const WANT_PARAM_ARCHIVE_TASK_ID: string = 'archiveTaskId';

/** WantAgent 参数键：通知点击后需切换到的 Tab 索引 */
export const WANT_PARAM_NOTIFY_TAB: string = 'notifyTabIndex';

/** AppStorage：冷启动时待处理的归档任务 ID（0 = 无待处理归档） */
export const KEY_PENDING_ARCHIVE_TASK_ID: string = 'pendingArchiveTaskId';

/** AppStorage：字体大小 token 键名（值为 FontSizeTokens 对象） */
export const KEY_FONT_TOKENS: string = 'fontSizeTokens';

/** AppStorage：当前字体缩放档位 ID 键名（值为 FontScaleId 字符串） */
export const KEY_FONT_SCALE_ID: string = 'fontScaleId';

/** Preferences：字体缩放档位存储键名 */
export const PREFS_KEY_FONT_SCALE: string = 'font_scale_id';

/** 字体缩放默认倍数（1.0 = 100%，与 float.json 基准值完全一致） */
export const DEFAULT_FONT_SCALE: number = 1.0;

/** 字体缩放最小倍数（80%） */
export const FONT_SCALE_MIN: number = 0.8;

/** 字体缩放最大倍数（150%） */
export const FONT_SCALE_MAX: number = 1.5;

/** 字体缩放滑块步长（5%） */
export const FONT_SCALE_STEP: number = 0.05;
