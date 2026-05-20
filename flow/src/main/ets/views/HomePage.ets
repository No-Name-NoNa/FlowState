/**
 * HomePage.ets
 * 首页（主工作区）视图组件。
 * 包含极简顶部 Header（问候语 + 设置入口图标）和主内容占位区域，
 * 后续将在此处挂载动态任务列表与快速捕获输入框。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { KEY_APP_LANGUAGE, LANG_ZH_CN, DIVIDER_STROKE_WIDTH } from '../constants/AppConstants';

/** 首页视图组件 */
@Component
export struct HomePage {
  /** 当前语言，绑定全局 AppStorage，语言切换时自动触发重渲染 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;

  /** 点击设置图标，路由跳转至设置页 */
  private navigateToSettings(): void {
    router.pushUrl({ url: 'pages/SettingsPage' });
  }

  build() {
    Column() {
      // 顶部 Header：问候语（左）+ 设置图标（右）
      Row() {
        Text(I18nHelper.getHomeGreeting(this.currentLanguage))
          .fontSize($r('app.float.font_size_header_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_text_primary'))
          .layoutWeight(1)

        // 设置入口图标按钮
        Image($r('app.media.ic_settings'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor($r('app.color.color_text_secondary'))
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
        .color($r('app.color.color_divider'))
        .width('100%')

      // 主内容区占位（后续开发任务列表与快速捕获输入框）
      Column() {
        Text(I18nHelper.getHomeEmptyHint(this.currentLanguage))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.color_text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_background'))
  }
}
