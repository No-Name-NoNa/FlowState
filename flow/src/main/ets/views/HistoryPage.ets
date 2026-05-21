/**
 * HistoryPage.ets
 * 历史记录视图组件。
 * 展示用户已完成任务的历史数据，当前阶段为框架占位，
 * 后续将挂载完成记录列表与数据统计面板。
 */
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import { DIVIDER_STROKE_WIDTH, KEY_APP_LANGUAGE, KEY_THEME_TOKENS, LANG_ZH_CN } from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';

/** 历史记录视图组件 */
@Component
export struct HistoryPage {
  /** 订阅语言变化，语言切换时触发组件重渲染 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  /** 订阅主题变化，主题切换时触发组件立即重渲染 */
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;

  build() {
    Column() {
      // 顶部 Header：页面标题
      Row() {
        Text(I18nHelper.t(I18nKeys.TAB_HISTORY, this.currentLanguage))
          .fontSize($r('app.float.font_size_header_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)

      // 顶部分隔线
      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // 主内容区占位（后续开发历史记录列表与数据统计面板）
      Column() {
        Text(I18nHelper.t(I18nKeys.HISTORY_EMPTY_HINT, this.currentLanguage))
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
