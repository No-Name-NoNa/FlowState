/**
 * ThemeConstants.ets
 * 主题系统常量与类型定义。
 * 定义 ThemeId 枚举、ThemeTokens 接口及全部预设主题配色方案。
 * 禁止在组件内直接硬编码颜色值，统一通过 ThemeTokens 访问。
 */

/** 主题标识枚举 */
export enum ThemeId {
  LIGHT = 'light',
  DARK = 'dark',
  WARM = 'warm',
  OCEAN = 'ocean',
  FOREST = 'forest',
  DARCULA = 'darcula',
  INTELLIJ = 'intellij',
  REIMU = 'reimu',
  MARISA = 'marisa',
  SAKUYA = 'sakuya',
  REMILIA = 'remilia',
  CUSTOM = 'custom',
}

/**
 * 主题颜色 token 集合。
 * 所有颜色以 #RRGGBB 格式字符串表示，可直接传入 ArkUI 的 ResourceColor 属性。
 */
export interface ThemeTokens {
  /** 页面主背景色 */
  colorBackground: string;

  /** 主文本色 */
  colorTextPrimary: string;

  /** 次要文本色 */
  colorTextSecondary: string;

  /** 强调色（按钮、选中态、图标高亮等） */
  colorAccent: string;

  /** 细分隔线颜色 */
  colorDivider: string;

  /** Tab 栏选中态颜色 */
  colorTabSelected: string;

  /** Tab 栏未选中态颜色 */
  colorTabNormal: string;

  /** Tab 栏背景色 */
  colorTabBarBg: string;

  /** 设置页选中项颜色 */
  colorSettingsSelected: string;
}

/** 主题预览元数据，供设置页渲染预设主题色块使用 */
export interface ThemePreview {
  id: ThemeId;

  /** i18n key，对应该主题的显示名称 */
  nameKey: string;

  /** 预览背景色 */
  previewBg: string;

  /** 预览强调色（内圆点颜色） */
  previewAccent: string;
}

/** ── 预设主题：清晨（Light）—— 白底黑字，极简 */
export const THEME_LIGHT: ThemeTokens = {
  colorBackground: '#FFFFFF',
  colorTextPrimary: '#1A1A1A',
  colorTextSecondary: '#8A8A8A',
  colorAccent: '#1A1A1A',
  colorDivider: '#E8E8E8',
  colorTabSelected: '#1A1A1A',
  colorTabNormal: '#999999',
  colorTabBarBg: '#FFFFFF',
  colorSettingsSelected: '#1A1A1A',
};

/** ── 预设主题：暗夜（Dark）—— 黑底浅字 */
export const THEME_DARK: ThemeTokens = {
  colorBackground: '#000000',
  colorTextPrimary: '#F0F0F0',
  colorTextSecondary: '#707070',
  colorAccent: '#F0F0F0',
  colorDivider: '#2A2A2A',
  colorTabSelected: '#F0F0F0',
  colorTabNormal: '#606060',
  colorTabBarBg: '#000000',
  colorSettingsSelected: '#F0F0F0',
};

/** ── 预设主题：暖阳（Warm）—— 奶油米色 + 琥珀橙 */
export const THEME_WARM: ThemeTokens = {
  colorBackground: '#FDF8F0',
  colorTextPrimary: '#2C1A0E',
  colorTextSecondary: '#9A7A60',
  colorAccent: '#C06828',
  colorDivider: '#EDD8C0',
  colorTabSelected: '#C06828',
  colorTabNormal: '#B09070',
  colorTabBarBg: '#FDF8F0',
  colorSettingsSelected: '#C06828',
};

/** ── 预设主题：海洋（Ocean）—— 浅蓝底 + 深海蓝 */
export const THEME_OCEAN: ThemeTokens = {
  colorBackground: '#F0F6FE',
  colorTextPrimary: '#0A2540',
  colorTextSecondary: '#5A80A0',
  colorAccent: '#0060CC',
  colorDivider: '#C0D8F0',
  colorTabSelected: '#0060CC',
  colorTabNormal: '#7A9CBC',
  colorTabBarBg: '#F0F6FE',
  colorSettingsSelected: '#0060CC',
};

/** ── 预设主题：森林（Forest）—— 浅绿底 + 墨绿 */
export const THEME_FOREST: ThemeTokens = {
  colorBackground: '#F2F8F0',
  colorTextPrimary: '#152A10',
  colorTextSecondary: '#6A8A62',
  colorAccent: '#2A7A30',
  colorDivider: '#C2DCC0',
  colorTabSelected: '#2A7A30',
  colorTabNormal: '#7A9A74',
  colorTabBarBg: '#F2F8F0',
  colorSettingsSelected: '#2A7A30',
};

/** ── 主题：余烬（Darcula）—— 深灰底 + 暖橙强调，类 Darcula 风格 */
export const THEME_DARCULA: ThemeTokens = {
  colorBackground: '#2B2B2B',
  colorTextPrimary: '#A9B7C6',
  colorTextSecondary: '#6A6A6A',
  colorAccent: '#CC7832',
  colorDivider: '#3C3F41',
  colorTabSelected: '#CC7832',
  colorTabNormal: '#6A6A6A',
  colorTabBarBg: '#313335',
  colorSettingsSelected: '#CC7832',
};

/** ── 主题：深空（Cosmos）—— 深蓝灰底 + 天空蓝强调 */
export const THEME_INTELLIJ: ThemeTokens = {
  colorBackground: '#282C34',
  colorTextPrimary: '#ABB2BF',
  colorTextSecondary: '#5C6370',
  colorAccent: '#61AFEF',
  colorDivider: '#3A3F4B',
  colorTabSelected: '#61AFEF',
  colorTabNormal: '#5C6370',
  colorTabBarBg: '#21252B',
  colorSettingsSelected: '#61AFEF',
};

/** ── 主题：朱砂（Cinnabar）—— 暖白奶油底 + 朱红强调 */
export const THEME_REIMU: ThemeTokens = {
  colorBackground: '#FDF8F5',
  colorTextPrimary: '#2A0808',
  colorTextSecondary: '#9A6060',
  colorAccent: '#CC2222',
  colorDivider: '#EDD0C0',
  colorTabSelected: '#CC2222',
  colorTabNormal: '#9A6060',
  colorTabBarBg: '#FDF8F5',
  colorSettingsSelected: '#CC2222',
};

/** ── 主题：星辰（Starlight）—— 纯黑底 + 星尘金强调 */
export const THEME_MARISA: ThemeTokens = {
  colorBackground: '#1A1A18',
  colorTextPrimary: '#F0E870',
  colorTextSecondary: '#806840',
  colorAccent: '#F0C020',
  colorDivider: '#2C2C22',
  colorTabSelected: '#F0C020',
  colorTabNormal: '#806840',
  colorTabBarBg: '#1A1A18',
  colorSettingsSelected: '#F0C020',
};

/** ── 主题：霜蓝（Frost）—— 冰蓝白底 + 钢铁蓝强调 */
export const THEME_SAKUYA: ThemeTokens = {
  colorBackground: '#F0F4F8',
  colorTextPrimary: '#1A2840',
  colorTextSecondary: '#7090A0',
  colorAccent: '#4888B8',
  colorDivider: '#C8D8E4',
  colorTabSelected: '#4888B8',
  colorTabNormal: '#7090A0',
  colorTabBarBg: '#F0F4F8',
  colorSettingsSelected: '#4888B8',
};

/** ── 主题：绯夜（Velvet）—— 深紫黑底 + 绯红强调 */
export const THEME_REMILIA: ThemeTokens = {
  colorBackground: '#1A0A1E',
  colorTextPrimary: '#E8C0D0',
  colorTextSecondary: '#806070',
  colorAccent: '#CC2060',
  colorDivider: '#2A1830',
  colorTabSelected: '#CC2060',
  colorTabNormal: '#806070',
  colorTabBarBg: '#1A0A1E',
  colorSettingsSelected: '#CC2060',
};

/** 默认启动主题 ID（首次安装时使用） */
export const DEFAULT_THEME_ID: string = ThemeId.LIGHT;

/** 默认启动主题 tokens */
export const DEFAULT_THEME_TOKENS: ThemeTokens = THEME_LIGHT;

/**
 * 根据主题 ID 获取对应的预设 ThemeTokens。
 * 若 themeId 为 CUSTOM 或未知，则返回 THEME_LIGHT 作为兜底。
 * @param themeId 主题标识（ThemeId 枚举值字符串）
 * @returns 对应的 ThemeTokens 对象
 */
export function getPresetTokens(themeId: string): ThemeTokens {
  switch (themeId) {
    case ThemeId.DARK:
      return THEME_DARK;
    case ThemeId.WARM:
      return THEME_WARM;
    case ThemeId.OCEAN:
      return THEME_OCEAN;
    case ThemeId.FOREST:
      return THEME_FOREST;
    case ThemeId.DARCULA:
      return THEME_DARCULA;
    case ThemeId.INTELLIJ:
      return THEME_INTELLIJ;
    case ThemeId.REIMU:
      return THEME_REIMU;
    case ThemeId.MARISA:
      return THEME_MARISA;
    case ThemeId.SAKUYA:
      return THEME_SAKUYA;
    case ThemeId.REMILIA:
      return THEME_REMILIA;
    default:
      return THEME_LIGHT;
  }
}

/**
 * 全部预设主题的预览元数据列表（不含 CUSTOM）。
 * 顺序即设置页中渲染预设色块的顺序。
 */
export const PRESET_THEME_PREVIEWS: ThemePreview[] = [
  {
    id: ThemeId.LIGHT,
    nameKey: 'settings_theme_light',
    previewBg: '#FFFFFF',
    previewAccent: '#1A1A1A'
  },
  {
    id: ThemeId.DARK,
    nameKey: 'settings_theme_dark',
    previewBg: '#000000',
    previewAccent: '#F0F0F0'
  },
  {
    id: ThemeId.WARM,
    nameKey: 'settings_theme_warm',
    previewBg: '#FDF8F0',
    previewAccent: '#C06828'
  },
  {
    id: ThemeId.OCEAN,
    nameKey: 'settings_theme_ocean',
    previewBg: '#F0F6FE',
    previewAccent: '#0060CC'
  },
  {
    id: ThemeId.FOREST,
    nameKey: 'settings_theme_forest',
    previewBg: '#F2F8F0',
    previewAccent: '#2A7A30'
  },
  {
    id: ThemeId.DARCULA,
    nameKey: 'settings_theme_darcula',
    previewBg: '#2B2B2B',
    previewAccent: '#CC7832'
  },
  {
    id: ThemeId.INTELLIJ,
    nameKey: 'settings_theme_intellij',
    previewBg: '#282C34',
    previewAccent: '#61AFEF'
  },
  {
    id: ThemeId.REIMU,
    nameKey: 'settings_theme_reimu',
    previewBg: '#FDF8F5',
    previewAccent: '#CC2222'
  },
  {
    id: ThemeId.MARISA,
    nameKey: 'settings_theme_marisa',
    previewBg: '#1A1A18',
    previewAccent: '#F0C020'
  },
  {
    id: ThemeId.SAKUYA,
    nameKey: 'settings_theme_sakuya',
    previewBg: '#F0F4F8',
    previewAccent: '#4888B8'
  },
  {
    id: ThemeId.REMILIA,
    nameKey: 'settings_theme_remilia',
    previewBg: '#1A0A1E',
    previewAccent: '#CC2060'
  },
];

/** 自定义主题背景色调色板 */
export const PALETTE_BACKGROUND: string[] = [
  '#FFFFFF', '#F5F5F5', '#FDF8F0', '#F0F6FE', '#F2F8F0',
  '#FFF5F5', '#F5F0FF', '#FAFAF8', '#1A1A1A', '#000000',
];

/** 自定义主题主文本色调色板 */
export const PALETTE_TEXT: string[] = [
  '#1A1A1A', '#2C1A0E', '#0A2540', '#152A10', '#2A0A28',
  '#FFFFFF', '#F0F0F0', '#FDF8F0', '#0A0A0A',
];

/** 自定义主题强调色调色板 */
export const PALETTE_ACCENT: string[] = [
  '#1A1A1A', '#0060CC', '#2A7A30', '#C06828', '#D03060',
  '#7040C0', '#CC4400', '#00848A', '#F0B800',
];
