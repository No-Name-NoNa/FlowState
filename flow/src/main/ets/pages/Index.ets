/**
 * Index.ets
 * 应用主框架入口页。
 * 基于原生 Tabs 组件构建双 Tab 底部导航结构：
 *   - Tab 0：首页（Home），主工作区，含快速捕获与动态任务列表
 *   - Tab 1：历史（History），已完成任务的轻量历史数据库
 * 遵循 PRD "去卡片化" 与 "Smooth & Snappy" 动画要求。
 */
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import { HomePage } from '../views/HomePage';
import { HistoryPage } from '../views/HistoryPage';
import { KEY_APP_LANGUAGE, LANG_ZH_CN } from '../constants/AppConstants';

/** 应用主框架：承载底部双 Tab 导航 */
@Entry
@Component
struct MainPage {
  /** 当前选中的 Tab 索引，初始为首页（0） */
  @State currentTabIndex: number = 0;

  /** 订阅语言变化，语言切换时触发组件重渲染以刷新 Tab 标签文字 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;

  /**
   * 自定义 Tab 标签构建函数。
   * 图标与文字颜色根据选中状态切换，无阴影、无色块，符合去卡片化原则。
   * labelKey 须传入 I18nKeys 常量；翻译在 @Builder 内部完成，以确保 ArkUI 依赖追踪
   * 感知到该节点依赖 currentLanguage，语言切换时自动触发重渲染。
   * @param tabIndex  目标 Tab 的索引
   * @param icon      图标资源引用
   * @param labelKey  i18n 字符串 key（I18nKeys 常量）
   */
  @Builder
  tabBarItem(tabIndex: number, icon: Resource, labelKey: string): void {
    Column({ space: 3 }) {
      Image(icon)
        .width($r('app.float.icon_size_md'))
        .height($r('app.float.icon_size_md'))
        .fillColor(this.currentTabIndex === tabIndex
          ? $r('app.color.color_tab_selected')
          : $r('app.color.color_tab_normal'))

      // 在 @Builder 内部读取 this.currentLanguage，建立 ArkUI 响应式依赖
      Text(I18nHelper.t(labelKey, this.currentLanguage))
        .fontSize($r('app.float.font_size_tab_label'))
        .fontColor(this.currentTabIndex === tabIndex
          ? $r('app.color.color_tab_selected')
          : $r('app.color.color_tab_normal'))
    }
    .width('100%')
    .height($r('app.float.tab_bar_height'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTabIndex }) {
      // ── Tab 0：首页 ──────────────────────────────────────────────────────
      TabContent() {
        HomePage()
      }
      .tabBar(this.tabBarItem(
        0,
        $r('app.media.ic_tab_home'),
        I18nKeys.TAB_HOME
      ))

      // ── Tab 1：历史 ──────────────────────────────────────────────────────
      TabContent() {
        HistoryPage()
      }
      .tabBar(this.tabBarItem(
        1,
        $r('sys.media.ohos_ic_public_clock'),
        I18nKeys.TAB_HISTORY
      ))
    }
    // Tab 切换监听，同步更新 currentTabIndex 以刷新自定义 TabBar 选中样式
    .onChange((index: number) => {
      this.currentTabIndex = index;
    })
    // 300ms 平滑切换动画，符合 PRD "Smooth & Snappy" 要求
    .animationDuration(300)
    // 允许左右滑动切换 Tab
    .scrollable(true)
    // TabBar 高度固定，背景与页面保持一致（去卡片化）
    .barHeight($r('app.float.tab_bar_height'))
    .barMode(BarMode.Fixed)
    .barBackgroundColor($r('app.color.color_tab_bar_bg'))
    // 整体背景色
    .backgroundColor($r('app.color.color_background'))
    .width('100%')
    .height('100%')
  }
}

