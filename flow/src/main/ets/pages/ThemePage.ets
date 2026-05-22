/**
 * ThemePage.ets
 * 主题设置独立子页。
 * 从设置页导航进入，展示预设主题选项列表以及自定义调色板编辑器。
 * 返回时通过 router.back() 退出，过渡动画与设置页一致。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import { ThemeViewModel } from '../viewmodel/ThemeViewModel';
import { ThemeHelper } from '../util/ThemeHelper';
import {
  COLOR_INPUT_ERROR,
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_THEME_ID,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import {
  DEFAULT_THEME_TOKENS,
  PALETTE_ACCENT,
  PALETTE_BACKGROUND,
  PALETTE_TEXT,
  THEME_LIGHT,
  ThemeId,
  ThemeTokens,
} from '../constants/ThemeConstants';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

/** 主题设置页 */
@Entry
@Component
struct ThemePage {
  /** 订阅语言变化，界面文字即时响应 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  /** 订阅主题 tokens 变化，确保本页配色也随主题即时更新 */
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  /** 订阅主题 ID，用于渲染选中态高亮 */
  @StorageLink(KEY_THEME_ID) currentThemeId: string = ThemeId.LIGHT;
  // ── 行点击扩散特效状态 ───────────────────────────────────────────────────────
  /** 当前正在播放扩散动效的行索引，-1 表示无动效 */
  @State pressedRowIndex: number = -1;
  /** 扩散矩形横向缩放比，从 0.02 动画至 1.4 */
  @State rowSpreadScale: number = 0;
  /** 扩散矩形透明度，从 0.12 动画至 0 */
  @State rowSpreadOpacity: number = 0;
  /** 扩散矩形 scale 变换中心 X（vp），来自触摸点坐标 */
  @State spreadCenterX: number = 0;
  // ── 自定义主题编辑器状态 ────────────────────────────────────────────────────
  /** 当前已应用的自定义背景色 */
  @State customBgColor: string = THEME_LIGHT.colorBackground;
  /** 当前已应用的自定义主文本色 */
  @State customTextColor: string = THEME_LIGHT.colorTextPrimary;
  /** 当前已应用的自定义强调色 */
  @State customAccentColor: string = THEME_LIGHT.colorAccent;
  /** 背景色 HEX 输入框当前值 */
  @State bgHexInput: string = THEME_LIGHT.colorBackground;
  /** 文本色 HEX 输入框当前值 */
  @State textHexInput: string = THEME_LIGHT.colorTextPrimary;
  /** 强调色 HEX 输入框当前值 */
  @State accentHexInput: string = THEME_LIGHT.colorAccent;

  aboutToAppear(): void {
    // 从持久化存储读取已保存的自定义主题配色，初始化编辑器状态
    const savedTokens: ThemeTokens = ThemeViewModel.getCustomThemeTokens();
    this.customBgColor = savedTokens.colorBackground;
    this.customTextColor = savedTokens.colorTextPrimary;
    this.customAccentColor = savedTokens.colorAccent;
    this.bgHexInput = savedTokens.colorBackground;
    this.textHexInput = savedTokens.colorTextPrimary;
    this.accentHexInput = savedTokens.colorAccent;
  }

  /** 使用当前编辑器三色立即应用并保存自定义主题 */
  private applyCustomColors(): void {
    ThemeViewModel.setCustomTheme(
      this.customBgColor,
      this.customTextColor,
      this.customAccentColor,
    );
  }

  /**
   * 触发指定行的横向矩形扩散特效。
   * @param rowIndex 被点击的行索引
   * @param touchX   触摸点相对于行元素的 X 坐标（vp）
   */
  private triggerRowSpread(rowIndex: number, touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx) => {
        this.pressedRowIndex = idx;
      },
      (scale, opacity) => {
        this.rowSpreadScale = scale;
        this.rowSpreadOpacity = opacity;
      },
      (x) => {
        this.spreadCenterX = x;
      },
      rowIndex,
      touchX,
    );
  }

  /**
   * 单个主题选项行（文字 + 选中勾）。
   * @param themeId   主题标识
   * @param nameKey   i18n key
   * @param rowIndex  行索引，用于扩散特效
   */
  @Builder
  themeOptionItem(themeId: string, nameKey: string, rowIndex: number): void {
    Stack({ alignContent: Alignment.Center }) {
      // 横向扩散矩形
      if (this.pressedRowIndex === rowIndex) {
        Rect()
          .width('100%')
          .height($r('app.float.settings_item_height'))
          .fill(this.themeTokens.colorTextPrimary)
          .opacity(this.rowSpreadOpacity)
          .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
          .hitTestBehavior(HitTestMode.None)
      }
      Row() {
        Text(I18nHelper.t(nameKey, this.currentLanguage))
          .fontSize($r('app.float.font_size_body'))
          .fontColor(this.currentThemeId === themeId
            ? this.themeTokens.colorSettingsSelected
            : this.themeTokens.colorTextPrimary)
          .fontWeight(this.currentThemeId === themeId
            ? FontWeight.Medium
            : FontWeight.Regular)
          .layoutWeight(1)

        if (this.currentThemeId === themeId) {
          Image($r('sys.media.ohos_ic_public_ok'))
            .width($r('app.float.icon_size_sm'))
            .height($r('app.float.icon_size_sm'))
            .fillColor(this.themeTokens.colorSettingsSelected)
        }
      }
      .width('100%')
      .height($r('app.float.settings_item_height'))
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down) {
          this.triggerRowSpread(rowIndex, e.touches[0].x);
        }
      })
      .onClick(() => {
        if (themeId === ThemeId.CUSTOM) {
          this.applyCustomColors();
        } else {
          ThemeViewModel.setTheme(themeId);
        }
      })
    }
    .width('100%')
    .height($r('app.float.settings_item_height'))
  }

  /**
   * 自定义主题单色编辑行（调色板色块 + HEX 输入框）。
   * colorType: 0 = 背景色, 1 = 文本色, 2 = 强调色
   * @param colorType 颜色类型标识
   */
  @Builder
  colorEditorRow(colorType: number): void {
    Column({ space: 6 }) {
      // 行标签
      Text(I18nHelper.t(
        colorType === 0 ? I18nKeys.SETTINGS_THEME_CUSTOM_BG
          : colorType === 1 ? I18nKeys.SETTINGS_THEME_CUSTOM_TEXT
          : I18nKeys.SETTINGS_THEME_CUSTOM_ACCENT,
        this.currentLanguage,
      ))
        .fontSize($r('app.float.font_size_caption'))
        .fontColor(this.themeTokens.colorTextSecondary)
        .width('100%')

      // 调色板色块 + HEX 输入框
      Row({ space: 10 }) {
        // 调色板水平滚动区
        Scroll() {
          Row({ space: 8 }) {
            ForEach(
              colorType === 0 ? PALETTE_BACKGROUND
                : colorType === 1 ? PALETTE_TEXT
                : PALETTE_ACCENT,
              (color: string) => {
                // 判断当前是否选中：对比已应用颜色（大写统一比较）
                Row()
                  .width(26)
                  .height(26)
                  .borderRadius(13)
                  .backgroundColor(color)
                  .borderWidth(
                    (colorType === 0 ? this.customBgColor :
                      colorType === 1 ? this.customTextColor : this.customAccentColor)
                      .toUpperCase() === color ? 2.5 : 1
                  )
                  .borderColor(
                    (colorType === 0 ? this.customBgColor :
                      colorType === 1 ? this.customTextColor : this.customAccentColor)
                      .toUpperCase() === color
                      ? this.themeTokens.colorTextPrimary
                      : this.themeTokens.colorDivider
                  )
                  .onClick(() => {
                    if (colorType === 0) {
                      this.customBgColor = color;
                      this.bgHexInput = color;
                    } else if (colorType === 1) {
                      this.customTextColor = color;
                      this.textHexInput = color;
                    } else {
                      this.customAccentColor = color;
                      this.accentHexInput = color;
                    }
                    this.applyCustomColors();
                  })
              },
              (color: string) => color,
            )
          }
          .padding({ left: 2, right: 2 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)

        // HEX 输入框
        TextInput({
          text: colorType === 0 ? this.bgHexInput
            : colorType === 1 ? this.textHexInput
              : this.accentHexInput,
          placeholder: '#RRGGBB',
        })
          .width(92)
          .height(34)
          .fontSize($r('app.float.font_size_caption'))
          .fontColor(this.themeTokens.colorTextPrimary)
          .placeholderColor(this.themeTokens.colorTextSecondary)
          .backgroundColor(this.themeTokens.colorBackground)
          .caretColor(this.themeTokens.colorAccent)
          .borderWidth(1)
          .borderRadius(6)
          .borderColor(
            ThemeHelper.isValidHexColor(
              colorType === 0 ? this.bgHexInput
                : colorType === 1 ? this.textHexInput
                : this.accentHexInput
            ) ? this.themeTokens.colorDivider : COLOR_INPUT_ERROR
          )
          .maxLength(7)
          .onChange((value: string) => {
            if (colorType === 0) {
              this.bgHexInput = value;
              if (ThemeHelper.isValidHexColor(value)) {
                this.customBgColor = value.toUpperCase();
                this.applyCustomColors();
              }
            } else if (colorType === 1) {
              this.textHexInput = value;
              if (ThemeHelper.isValidHexColor(value)) {
                this.customTextColor = value.toUpperCase();
                this.applyCustomColors();
              }
            } else {
              this.accentHexInput = value;
              if (ThemeHelper.isValidHexColor(value)) {
                this.customAccentColor = value.toUpperCase();
                this.applyCustomColors();
              }
            }
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column({ space: 0 }) {
      // ── 顶部导航栏：返回按钮 + 页面标题 ──────────────────────────────────
      Row() {
        Image($r('sys.media.ohos_ic_back'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextPrimary)
          .onClick(() => {
            router.back();
          })

        Text(I18nHelper.t(I18nKeys.SETTINGS_THEME_LABEL, this.currentLanguage))
          .fontSize($r('app.float.font_size_header_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 右侧占位，保持标题视觉居中
        Row()
          .width($r('app.float.icon_size_md'))
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
      .alignItems(VerticalAlign.Center)

      // 顶部分隔线 (限制固定高度，防止 Divider 自动占用额外垂直空间)
      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')
        .height(DIVIDER_STROKE_WIDTH)
        .margin(0)

      Scroll() {
        Column({ space: 0 }) {
          // 预设主题选项列表
          this.themeOptionItem(ThemeId.LIGHT, I18nKeys.SETTINGS_THEME_LIGHT, 0)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.DARK, I18nKeys.SETTINGS_THEME_DARK, 1)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.WARM, I18nKeys.SETTINGS_THEME_WARM, 2)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.OCEAN, I18nKeys.SETTINGS_THEME_OCEAN, 3)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.FOREST, I18nKeys.SETTINGS_THEME_FOREST, 4)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.DARCULA, I18nKeys.SETTINGS_THEME_DARCULA, 5)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.INTELLIJ, I18nKeys.SETTINGS_THEME_INTELLIJ, 6)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.REIMU, I18nKeys.SETTINGS_THEME_REIMU, 7)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.MARISA, I18nKeys.SETTINGS_THEME_MARISA, 8)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.SAKUYA, I18nKeys.SETTINGS_THEME_SAKUYA, 9)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.REMILIA, I18nKeys.SETTINGS_THEME_REMILIA, 10)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })
            .height(DIVIDER_STROKE_WIDTH)

          this.themeOptionItem(ThemeId.CUSTOM, I18nKeys.SETTINGS_THEME_CUSTOM, 11)

          // 自定义主题颜色编辑面板（仅选中 CUSTOM 时展示）
          if (this.currentThemeId === ThemeId.CUSTOM) {
            Column({ space: 0 }) {
              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .margin({ left: $r('app.float.spacing_lg') })
                .height(DIVIDER_STROKE_WIDTH)

              Column() {
                this.colorEditorRow(0)
              }
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_sm'),
                bottom: $r('app.float.spacing_sm'),
              })

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .margin({ left: $r('app.float.spacing_lg') })
                .height(DIVIDER_STROKE_WIDTH)

              Column() {
                this.colorEditorRow(1)
              }
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_sm'),
                bottom: $r('app.float.spacing_sm'),
              })

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .margin({ left: $r('app.float.spacing_lg') })
                .height(DIVIDER_STROKE_WIDTH)

              Column() {
                this.colorEditorRow(2)
              }
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_sm'),
                bottom: $r('app.float.spacing_md'),
              })
            }
            .width('100%')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor(this.themeTokens.colorBackground)
  }
}