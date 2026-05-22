/**
 * LanguagePage.ets
 * 语言选择独立子页。
 * 从设置页导航进入，展示全部可选语言，选中态高亮 + 勾选图标。
 * 返回时通过 router.back() 退出，过渡动画与设置页一致。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_FONT_TOKENS,
  KEY_THEME_TOKENS,
  LANG_EN_US,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';
;

/** 语言选择页 */
@Entry
@Component
struct LanguagePage {
  /** 订阅语言变化，切换后界面即时响应 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  /** 订阅主题变化，确保配色随主题即时更新 */
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  // ── 行点击扩散特效状态 ───────────────────────────────────────────────────────
  /** 当前正在播放扩散动效的行索引，-1 表示无动效 */
  @State pressedRowIndex: number = -1;
  /** 扩散矩形横向缩放比，从 0.02 动画至 1.4 */
  @State rowSpreadScale: number = 0;
  /** 扩散矩形透明度，从 0.12 动画至 0 */
  @State rowSpreadOpacity: number = 0;
  /** 扩散矩形 scale 变换中心 X（vp），来自触摸点坐标 */
  @State spreadCenterX: number = 0;

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
   * 单个语言选项行。
   * 选中项以强调色文字 + 右侧勾选图标标识，未选中项以次要色显示。
   * @param langCode    语言标识代码
   * @param displayName 展示给用户的语言名称（固定为该语言自身文字）
   * @param rowIndex    行索引，用于扩散特效
   */
  @Builder
  languageOptionItem(langCode: string, displayName: string, rowIndex: number): void {
    Stack({ alignContent: Alignment.Center }) {
      // 横向扩散矩形
      if (this.pressedRowIndex === rowIndex) {
        Rect()
          .width('100%')
          .height(this.fontTokens.settingsItemHeight)
          .fill(this.themeTokens.colorTextPrimary)
          .opacity(this.rowSpreadOpacity)
          .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
          .hitTestBehavior(HitTestMode.None)
      }
      Row() {
        Text(displayName)
          .fontSize(this.fontTokens.body)
          .fontColor(this.currentLanguage === langCode
            ? this.themeTokens.colorSettingsSelected
            : this.themeTokens.colorTextPrimary)
          .fontWeight(this.currentLanguage === langCode
            ? FontWeight.Medium
            : FontWeight.Regular)
          .layoutWeight(1)

        // 选中时展示勾选图标
        if (this.currentLanguage === langCode) {
          Image($r('sys.media.ohos_ic_public_ok'))
            .width($r('app.float.icon_size_sm'))
            .height($r('app.float.icon_size_sm'))
            .fillColor(this.themeTokens.colorSettingsSelected)
        }
      }
      .width('100%')
      .height(this.fontTokens.settingsItemHeight)
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down) {
          this.triggerRowSpread(rowIndex, e.touches[0].x);
        }
      })
      .onClick(() => {
        SettingsViewModel.setLanguage(langCode);
      })
    }
    .width('100%')
    .height(this.fontTokens.settingsItemHeight)
  }

  build() {
    Column() {
      // ── 顶部导航栏：返回按钮 + 页面标题 ──────────────────────────────────
      Row() {
        Image($r('sys.media.ohos_ic_back'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextPrimary)
          .onClick(() => {
            router.back();
          })

        Text(I18nHelper.t(I18nKeys.SETTINGS_LANGUAGE_LABEL, this.currentLanguage))
          .fontSize(this.fontTokens.headerTitle)
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

      // 顶部分隔线
      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 语言选项列表 ──────────────────────────────────────────────────────
      Column() {
        // 简体中文
        this.languageOptionItem(LANG_ZH_CN, I18nHelper.t(I18nKeys.SETTINGS_LANGUAGE_ZH, this.currentLanguage), 0)

        Divider()
          .strokeWidth(DIVIDER_STROKE_WIDTH)
          .color(this.themeTokens.colorDivider)
          .margin({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })

        // English
        this.languageOptionItem(LANG_EN_US, I18nHelper.t(I18nKeys.SETTINGS_LANGUAGE_EN, this.currentLanguage), 1)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }
}
