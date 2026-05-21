/**
 * SettingsPage.ets
 * 应用设置页（导航入口列表）。
 * 通过全屏路由从首页 Header 的设置图标跳转进入。
 * 每个设置项以导航行展示当前值 + 右箭头，点击跳转至对应独立子页。
 * 遵循去卡片化原则：无卡片阴影，以细分隔线和留白进行视觉分层。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_THEME_ID,
  KEY_THEME_TOKENS,
  LANG_EN_US,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeId, ThemeTokens, } from '../constants/ThemeConstants';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

/** 设置页（导航列表） */
@Entry
@Component
struct SettingsPage {
  /** 订阅语言变化，切换后整个应用实时响应 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  /** 订阅主题 tokens 变化，确保设置页自身配色也随主题即时更新 */
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  /** 订阅主题 ID，用于在渲染树中直接读取并显示当前主题名称 */
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
   * 语言导航行。
   * 直接在渲染树中读取 this.currentLanguage 以建立 ArkUI 响应式依赖，
   * 确保语言切换后右侧副文字即时刷新，无需重启。
   */
  @Builder
  languageNavRow(): void {
    Stack({ alignContent: Alignment.Center }) {
      // 横向扩散矩形（仅当此行被按下时渲染）
      if (this.pressedRowIndex === 0) {
        Rect()
          .width('100%')
          .height($r('app.float.settings_item_height'))
          .fill(this.themeTokens.colorTextPrimary)
          .opacity(this.rowSpreadOpacity)
          .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
          .hitTestBehavior(HitTestMode.None)
      }
      Row() {
        Text(I18nHelper.t(I18nKeys.SETTINGS_LANGUAGE_LABEL, this.currentLanguage))
          .fontSize($r('app.float.font_size_body'))
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)

        // 直接在渲染树中求值，不经由方法或参数传递，确保 ArkUI 追踪依赖
        Text(this.currentLanguage === LANG_EN_US
          ? I18nHelper.t(I18nKeys.SETTINGS_LANGUAGE_EN, this.currentLanguage)
          : I18nHelper.t(I18nKeys.SETTINGS_LANGUAGE_ZH, this.currentLanguage))
          .fontSize($r('app.float.font_size_body'))
          .fontColor(this.themeTokens.colorTextSecondary)
          .margin({ right: $r('app.float.spacing_sm') })

        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width($r('app.float.icon_size_sm'))
          .height($r('app.float.icon_size_sm'))
          .fillColor(this.themeTokens.colorTextSecondary)
      }
      .width('100%')
      .height($r('app.float.settings_item_height'))
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down) {
          this.triggerRowSpread(0, e.touches[0].x);
        }
      })
      .onClick(() => {
        router.pushUrl({ url: 'pages/LanguagePage' });
      })
    }
    .width('100%')
    .height($r('app.float.settings_item_height'))
  }

  /**
   * 主题导航行。
   * 直接在渲染树中读取 this.currentThemeId + this.currentLanguage 建立双重响应式依赖，
   * 主题或语言切换后右侧副文字均即时刷新。
   */
  @Builder
  themeNavRow(): void {
    Stack({ alignContent: Alignment.Center }) {
      if (this.pressedRowIndex === 1) {
        Rect()
          .width('100%')
          .height($r('app.float.settings_item_height'))
          .fill(this.themeTokens.colorTextPrimary)
          .opacity(this.rowSpreadOpacity)
          .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
          .hitTestBehavior(HitTestMode.None)
      }
      Row() {
        Text(I18nHelper.t(I18nKeys.SETTINGS_THEME_LABEL, this.currentLanguage))
          .fontSize($r('app.float.font_size_body'))
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)

        // this.currentThemeId 和 this.currentLanguage 均在渲染树中直接读取，建立双重依赖
        Text(I18nHelper.t(
          this.currentThemeId === ThemeId.DARK ? I18nKeys.SETTINGS_THEME_DARK
            : this.currentThemeId === ThemeId.WARM ? I18nKeys.SETTINGS_THEME_WARM
            : this.currentThemeId === ThemeId.OCEAN ? I18nKeys.SETTINGS_THEME_OCEAN
              : this.currentThemeId === ThemeId.FOREST ? I18nKeys.SETTINGS_THEME_FOREST
                : this.currentThemeId === ThemeId.CUSTOM ? I18nKeys.SETTINGS_THEME_CUSTOM
                  : I18nKeys.SETTINGS_THEME_LIGHT,
          this.currentLanguage,
        ))
          .fontSize($r('app.float.font_size_body'))
          .fontColor(this.themeTokens.colorTextSecondary)
          .margin({ right: $r('app.float.spacing_sm') })

        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width($r('app.float.icon_size_sm'))
          .height($r('app.float.icon_size_sm'))
          .fillColor(this.themeTokens.colorTextSecondary)
      }
      .width('100%')
      .height($r('app.float.settings_item_height'))
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down) {
          this.triggerRowSpread(1, e.touches[0].x);
        }
      })
      .onClick(() => {
        router.pushUrl({ url: 'pages/ThemePage' });
      })
    }
    .width('100%')
    .height($r('app.float.settings_item_height'))
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

        Text(I18nHelper.t(I18nKeys.SETTINGS_TITLE, this.currentLanguage))
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

      // 顶部分隔线
      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 设置项列表 ──────────────────────────────────────────────────────
      Column() {
        // ── 第一项：语言 ──────────────────────────────────────────────────
        this.languageNavRow()

        Divider()
          .strokeWidth(DIVIDER_STROKE_WIDTH)
          .color(this.themeTokens.colorDivider)
          .margin({ left: $r('app.float.spacing_lg') })

        // ── 第二项：主题 ──────────────────────────────────────────────────
        this.themeNavRow()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }
}
