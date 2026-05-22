/**
 * FontSizePage.ets
 * 字体大小自定义子页。
 * 提供滑块（80%～150%，步长 5%）供用户自定义字号缩放比，
 * 同时附带 4 个快捷预设 chip（小 / 标准 / 大 / 特大）和实时预览区。
 * 切换后立即生效并持久化，全 App 字号与行高即时响应。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import { FontSizeHelper } from '../util/FontSizeHelper';
import {
  DIVIDER_STROKE_WIDTH,
  FONT_SCALE_MAX,
  FONT_SCALE_MIN,
  FONT_SCALE_STEP,
  KEY_APP_LANGUAGE,
  KEY_FONT_SCALE_ID,
  KEY_FONT_TOKENS,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import {
  DEFAULT_FONT_TOKENS,
  FontSizeTokens,
  PRESET_SCALE_LARGE,
  PRESET_SCALE_NORMAL,
  PRESET_SCALE_SMALL,
  PRESET_SCALE_XLARGE,
} from '../constants/FontSizeConstants';

/** 字体大小自定义页 */
@Entry
@Component
struct FontSizePage {
  /** 订阅语言变化 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  /** 订阅主题变化 */
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  /** 订阅字体缩放倍数字符串（如 "1.0"），驱动预设 chip 高亮 */
  @StorageLink(KEY_FONT_SCALE_ID) currentScaleStr: string = '1.0';
  /** 订阅字体大小 tokens，确保本页字号也随拖动即时更新 */
  @StorageLink(KEY_FONT_TOKENS) fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  /** Slider 当前值（80～150，对应缩放比 0.8～1.5，步长 5） */
  @State sliderValue: number = 100;

  aboutToAppear(): void {
    const scale: number = Number(this.currentScaleStr);
    this.sliderValue = isNaN(scale) ? 100 : Math.round(scale * 100);
  }

  /** 将当前 sliderValue 转换为缩放倍数（保留两位小数） */
  private toScale(value: number): number {
    return Math.round(value) / 100;
  }

  /** 将缩放倍数格式化为百分比字符串，如 "100%" */
  private formatPct(value: number): string {
    return Math.round(value).toString() + '%';
  }

  /** 判断某个快捷预设是否为当前选中值 */
  private isPresetActive(presetScale: number): boolean {
    return Math.abs(this.sliderValue - Math.round(presetScale * 100)) < 1;
  }

  build() {
    Column() {
      // ── 顶部导航栏 ────────────────────────────────────────────────────────
      Row() {
        Image($r('sys.media.ohos_ic_back'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextPrimary)
          .onClick(() => {
            router.back();
          })

        Text(I18nHelper.t(I18nKeys.SETTINGS_FONTSIZE_LABEL, this.currentLanguage))
          .fontSize(this.fontTokens.headerTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row()
          .width($r('app.float.icon_size_md'))
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
      .alignItems(VerticalAlign.Center)

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 滑块区域 ──────────────────────────────────────────────────────────
      Column({ space: 0 }) {
        // 当前百分比显示
        Row() {
          Text(this.formatPct(this.sliderValue))
            .fontSize(this.fontTokens.titleLarge)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeTokens.colorAccent)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: $r('app.float.spacing_lg'), bottom: $r('app.float.spacing_sm') })

        // 滑块
        Slider({
          value: this.sliderValue,
          min: Math.round(FONT_SCALE_MIN * 100),
          max: Math.round(FONT_SCALE_MAX * 100),
          step: Math.round(FONT_SCALE_STEP * 100),
          style: SliderStyle.OutSet,
        })
          .width('100%')
          .trackColor(this.themeTokens.colorDivider)
          .selectedColor(this.themeTokens.colorAccent)
          .showTips(false)
          .padding({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
          .onChange((value: number, mode: SliderChangeMode) => {
            this.sliderValue = Math.round(value);
            FontSizeHelper.applyFontScale(this.toScale(this.sliderValue));
          })

        // 最小 / 最大标签
        Row() {
          Text(this.formatPct(Math.round(FONT_SCALE_MIN * 100)))
            .fontSize(this.fontTokens.caption)
            .fontColor(this.themeTokens.colorTextSecondary)

          Blank()

          Text(this.formatPct(Math.round(FONT_SCALE_MAX * 100)))
            .fontSize(this.fontTokens.caption)
            .fontColor(this.themeTokens.colorTextSecondary)
        }
        .width('100%')
        .padding({
          left: $r('app.float.spacing_md'),
          right: $r('app.float.spacing_md'),
          bottom: $r('app.float.spacing_lg'),
        })
      }
      .width('100%')
      .backgroundColor(this.themeTokens.colorBackground)

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 快捷预设 ──────────────────────────────────────────────────────────
      Row({ space: 8 }) {
        // 小
        Text(I18nHelper.t(I18nKeys.FONT_SCALE_SMALL, this.currentLanguage))
          .fontSize(this.fontTokens.body)
          .fontColor(this.isPresetActive(PRESET_SCALE_SMALL)
            ? this.themeTokens.colorBackground
            : this.themeTokens.colorTextPrimary)
          .backgroundColor(this.isPresetActive(PRESET_SCALE_SMALL)
            ? this.themeTokens.colorAccent
            : this.themeTokens.colorDivider)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(8)
          .onClick(() => {
            this.sliderValue = Math.round(PRESET_SCALE_SMALL * 100);
            FontSizeHelper.applyFontScale(PRESET_SCALE_SMALL);
          })

        // 标准
        Text(I18nHelper.t(I18nKeys.FONT_SCALE_NORMAL, this.currentLanguage))
          .fontSize(this.fontTokens.body)
          .fontColor(this.isPresetActive(PRESET_SCALE_NORMAL)
            ? this.themeTokens.colorBackground
            : this.themeTokens.colorTextPrimary)
          .backgroundColor(this.isPresetActive(PRESET_SCALE_NORMAL)
            ? this.themeTokens.colorAccent
            : this.themeTokens.colorDivider)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(8)
          .onClick(() => {
            this.sliderValue = Math.round(PRESET_SCALE_NORMAL * 100);
            FontSizeHelper.applyFontScale(PRESET_SCALE_NORMAL);
          })

        // 大
        Text(I18nHelper.t(I18nKeys.FONT_SCALE_LARGE, this.currentLanguage))
          .fontSize(this.fontTokens.body)
          .fontColor(this.isPresetActive(PRESET_SCALE_LARGE)
            ? this.themeTokens.colorBackground
            : this.themeTokens.colorTextPrimary)
          .backgroundColor(this.isPresetActive(PRESET_SCALE_LARGE)
            ? this.themeTokens.colorAccent
            : this.themeTokens.colorDivider)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(8)
          .onClick(() => {
            this.sliderValue = Math.round(PRESET_SCALE_LARGE * 100);
            FontSizeHelper.applyFontScale(PRESET_SCALE_LARGE);
          })

        // 特大
        Text(I18nHelper.t(I18nKeys.FONT_SCALE_XLARGE, this.currentLanguage))
          .fontSize(this.fontTokens.body)
          .fontColor(this.isPresetActive(PRESET_SCALE_XLARGE)
            ? this.themeTokens.colorBackground
            : this.themeTokens.colorTextPrimary)
          .backgroundColor(this.isPresetActive(PRESET_SCALE_XLARGE)
            ? this.themeTokens.colorAccent
            : this.themeTokens.colorDivider)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(8)
          .onClick(() => {
            this.sliderValue = Math.round(PRESET_SCALE_XLARGE * 100);
            FontSizeHelper.applyFontScale(PRESET_SCALE_XLARGE);
          })
      }
      .width('100%')
      .padding({
        left: $r('app.float.spacing_lg'),
        right: $r('app.float.spacing_lg'),
        top: $r('app.float.spacing_lg'),
        bottom: $r('app.float.spacing_lg'),
      })

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 实时预览区 ────────────────────────────────────────────────────────
      Column({ space: 12 }) {
        Text(I18nHelper.t(I18nKeys.SETTINGS_FONTSIZE_PREVIEW, this.currentLanguage))
          .fontSize(this.fontTokens.caption)
          .fontColor(this.themeTokens.colorTextSecondary)
          .width('100%')

        Text('正文 · Body')
          .fontSize(this.fontTokens.body)
          .fontColor(this.themeTokens.colorTextPrimary)
          .width('100%')

        Text('辅助说明 · Caption')
          .fontSize(this.fontTokens.caption)
          .fontColor(this.themeTokens.colorTextSecondary)
          .width('100%')

        Text('标签 · Label')
          .fontSize(this.fontTokens.label)
          .fontColor(this.themeTokens.colorTextSecondary)
          .width('100%')
      }
      .width('100%')
      .padding({
        left: $r('app.float.spacing_lg'),
        right: $r('app.float.spacing_lg'),
        top: $r('app.float.spacing_lg'),
        bottom: $r('app.float.spacing_lg'),
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }
}
