/**
 * HistoryPage.ets
 * 历史记录视图组件。
 * 展示用户已完成任务的历史数据，当前阶段为框架占位，
 * 后续将挂载完成记录列表与数据统计面板。
 */
import { I18nHelper } from '../util/I18nHelper';
import { KEY_APP_LANGUAGE, LANG_ZH_CN, DIVIDER_STROKE_WIDTH } from '../constants/AppConstants';

/** 历史记录视图组件 */
@Component
export struct HistoryPage {
  /** 当前语言，绑定全局 AppStorage，语言切换时自动触发重渲染 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;

  build() {
    Column() {
      // 顶部 Header：页面标题
      Row() {
        Text(I18nHelper.getTabHistory(this.currentLanguage))
          .fontSize($r('app.float.font_size_header_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_text_primary'))
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)

      // 顶部分隔线
      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color($r('app.color.color_divider'))
        .width('100%')

      // 主内容区占位（后续开发历史记录列表与数据统计面板）
      Column() {
        Text(I18nHelper.getHistoryEmptyHint(this.currentLanguage))
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
