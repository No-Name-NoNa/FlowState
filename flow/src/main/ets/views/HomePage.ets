/**
 * HomePage.ets
 * 首页（主工作区）视图组件。
 * 包含极简顶部 Header（问候语 + 设置入口图标）和主内容占位区域，
 * 后续将在此处挂载动态任务列表与快速捕获输入框。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import { DIVIDER_STROKE_WIDTH, KEY_APP_LANGUAGE, KEY_THEME_TOKENS, LANG_ZH_CN } from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';

/** 首页视图组件 */
@Component
export struct HomePage {
  /** 订阅语言变化，语言切换时触发组件重渲染 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  /** 订阅主题变化，主题切换时触发组件立即重渲染 */
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;

  /** 点击设置图标，路由跳转至设置页 */
  private navigateToSettings(): void {
    router.pushUrl({ url: 'pages/SettingsPage' });
  }

  build() {
    Column() {
      // 顶部 Header：问候语（左）+ 设置图标（右）
      Row() {
        Text(I18nHelper.t(I18nKeys.HOME_GREETING, this.currentLanguage))
          .fontSize($r('app.float.font_size_header_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)

        // 设置入口图标按钮
        Image($r('app.media.ic_settings'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextSecondary)
          .onClick(() => {
            this.navigateToSettings();
          })
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)

      // 顶部分隔线（极细，符合去卡片化原则）
      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // 主内容区占位（后续开发任务列表与快速捕获输入框）
      Column() {
        Text(I18nHelper.t(I18nKeys.HOME_EMPTY_HINT, this.currentLanguage))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor(this.themeTokens.colorTextSecondary)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }
}
