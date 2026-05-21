/**
 * Index.ets
 * 应用主框架入口页。
 * 基于原生 Tabs 组件构建三 Tab 底部导航结构：
 *   - Tab 0：首页（Home），快速捕获收集箱
 *   - Tab 1：任务（Tasks），动态优先级任务工作区
 *   - Tab 2：历史（History），已完成任务的轻量历史数据库
 * 遵循 PRD "去卡片化" 与 "Smooth & Snappy" 动画要求。
 */
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import { HomePage } from '../views/HomePage';
import { TaskPage } from '../views/TaskPage';
import { HistoryPage } from '../views/HistoryPage';
import { KEY_APP_LANGUAGE, KEY_THEME_TOKENS, LANG_ZH_CN } from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

/** 应用主框架：承载底部双 Tab 导航 */
@Entry
@Component
struct MainPage {
  /** 当前选中的 Tab 索引，初始为首页（0） */
  @State currentTabIndex: number = 0;
  /** 订阅语言变化，语言切换时触发组件重渲染以刷新 Tab 标签文字 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  /** 订阅主题变化，主题切换时触发组件立即重渲染 */
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  // ── Tab 点击扩散特效状态 ─────────────────────────────────────────────────
  /** 当前正在播放扩散动效的 Tab 索引，-1 表示无动效 */
  @State pressedTabIndex: number = -1;
  /** 扩散矩形的横向缩放比，从 0.02 动画至 1.4 */
  @State spreadingScale: number = 0;
  /** 扩散矩形的透明度，从 0.12 动画至 0 */
  @State spreadingOpacity: number = 0;
  /** 扩散矩形 scale 变换中心 X（vp），来自触摸点坐标 */
  @State spreadCenterX: number = 0;

  /**
   * 触发指定 Tab 的横向矩形扩散点击特效。
   * @param tabIndex 被点击的 Tab 索引
   * @param touchX   触摸点相对于 Tab 项的 X 坐标（vp）
   */
  private triggerSpreadEffect(tabIndex: number, touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx) => {
        this.pressedTabIndex = idx;
      },
      (scale, opacity) => {
        this.spreadingScale = scale;
        this.spreadingOpacity = opacity;
      },
      (x) => {
        this.spreadCenterX = x;
      },
      tabIndex,
      touchX,
    );
  }

  /**
   * 自定义 Tab 标签构建函数。
   * 图标与文字颜色根据选中状态切换，无阴影、无色块，符合去卡片化原则。
   * 按下时从中心向外扩散柔和光晕（无涟漪圆环）。
   * labelKey 须传入 I18nKeys 常量；翻译在 @Builder 内部完成，以确保 ArkUI 依赖追踪
   * 感知到该节点依赖 currentLanguage，语言切换时自动触发重渲染。
   * @param tabIndex  目标 Tab 的索引
   * @param icon      图标资源引用
   * @param labelKey  i18n 字符串 key（I18nKeys 常量）
   */
  @Builder
  tabBarItem(tabIndex: number, icon: Resource, labelKey: string): void {
    Stack({ alignContent: Alignment.Center }) {
      // 横向扩散矩形（仅当此 Tab 被按下时渲染，hitTestBehavior 设为 None 不拦截点击事件）
      if (this.pressedTabIndex === tabIndex) {
        Rect()
          .width('100%')
          .height($r('app.float.tab_bar_height'))
          .fill(this.themeTokens.colorTabSelected)
          .opacity(this.spreadingOpacity)
          .scale({ x: this.spreadingScale, y: 1, centerX: this.spreadCenterX })
          .hitTestBehavior(HitTestMode.None)
      }

      // Tab Bar 顶部分割线（与页面内容区视觉分隔）
      Row()
        .width('100%')
        .height(0.5)
        .backgroundColor(this.themeTokens.colorDivider)
        .hitTestBehavior(HitTestMode.None)
        .position({ x: 0, y: 0 })

      Column({ space: 3 }) {
        Image(icon)
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.currentTabIndex === tabIndex
            ? this.themeTokens.colorTabSelected
            : this.themeTokens.colorTabNormal)

        // 在 @Builder 内部读取 this.currentLanguage，建立 ArkUI 响应式依赖
        Text(I18nHelper.t(labelKey, this.currentLanguage))
          .fontSize($r('app.float.font_size_tab_label'))
          .fontColor(this.currentTabIndex === tabIndex
            ? this.themeTokens.colorTabSelected
            : this.themeTokens.colorTabNormal)
      }
      .width('100%')
      .height($r('app.float.tab_bar_height'))
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onTouch((event: TouchEvent) => {
        // 手指按下瞬间触发扩散特效，不影响 Tabs 组件自身的切换事件
        if (event.type === TouchType.Down) {
          this.triggerSpreadEffect(tabIndex, event.touches[0].x);
        }
      })
    }
    .width('100%')
    .height($r('app.float.tab_bar_height'))
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

      // ── Tab 1：任务 ──────────────────────────────────────────────────────
      TabContent() {
        TaskPage()
      }
      .tabBar(this.tabBarItem(
        1,
        $r('app.media.ic_tab_tasks'),
        I18nKeys.TAB_TASKS
      ))

      // ── Tab 2：历史 ──────────────────────────────────────────────────────
      TabContent() {
        HistoryPage()
      }
      .tabBar(this.tabBarItem(
        2,
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
    .barBackgroundColor(this.themeTokens.colorTabBarBg)
    // 整体背景色
    .backgroundColor(this.themeTokens.colorBackground)
    .width('100%')
    .height('100%')
  }
}

