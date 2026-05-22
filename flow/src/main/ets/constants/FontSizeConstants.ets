/**
 * FontSizeConstants.ets
 * 字体大小系统常量与类型定义。
 * 定义 FontScaleId 枚举、FontSizeTokens 接口，并通过 buildFontTokens(scale) 动态计算字号。
 * 禁止在组件内直接硬编码字号或行高值，统一通过 FontSizeTokens 访问。
 */

/** 字体缩放快捷预设标识枚举（用于 FontSizePage 快捷选择） */
export enum FontScaleId {
  SMALL = 'small',
  NORMAL = 'normal',
  LARGE = 'large',
  XLARGE = 'xlarge',
}

/** 各快捷预设对应的缩放倍数 */
export const PRESET_SCALE_SMALL: number = 0.85;
export const PRESET_SCALE_NORMAL: number = 1.0;
export const PRESET_SCALE_LARGE: number = 1.15;
export const PRESET_SCALE_XLARGE: number = 1.3;

/**
 * 字体大小 token 集合。
 * 字号以 fp 为单位，行高以 vp 为单位，均以 number 表示，可直接传入 ArkUI 的 fontSize/height 属性。
 */
export interface FontSizeTokens {
  /** 页面大标题字号（基准 22fp） */
  headerTitle: number;
  /** 正文字号（基准 16fp） */
  body: number;
  /** 辅助说明字号（基准 13fp） */
  caption: number;
  /** Tab 标签字号（基准 12fp） */
  tabLabel: number;
  /** 小标签字号（基准 11fp） */
  label: number;
  /** 任务详情页大标题字号（基准 26fp） */
  titleLarge: number;
  /** 操作行说明文本字号（基准 15fp） */
  bodySmall: number;
  /** 计时器数字字号（基准 52fp） */
  timerDigit: number;
  /** 设置导航行 / 操作行高（基准 52vp） */
  settingsItemHeight: number;
  /** 任务 / 收集箱列表行最小高（基准 64vp） */
  inboxItemMinHeight: number;
}

/**
 * 根据缩放倍数动态计算所有字号与行高 token。
 * @param scale 缩放倍数（建议范围 0.8～1.5，默认 1.0 = 100%）
 * @returns 完整的 FontSizeTokens 对象
 */
export function buildFontTokens(scale: number): FontSizeTokens {
  return {
    headerTitle: Math.round(22 * scale),
    body: Math.round(16 * scale),
    caption: Math.round(13 * scale),
    tabLabel: Math.round(12 * scale),
    label: Math.round(11 * scale),
    titleLarge: Math.round(26 * scale),
    bodySmall: Math.round(15 * scale),
    timerDigit: Math.round(52 * scale),
    settingsItemHeight: Math.round(52 * scale),
    inboxItemMinHeight: Math.round(64 * scale),
  };
}

/** 默认字体 tokens（标准档 ×1.0），供组件声明 @StorageLink 时提供初始值 */
export const DEFAULT_FONT_TOKENS: FontSizeTokens = buildFontTokens(PRESET_SCALE_NORMAL);
