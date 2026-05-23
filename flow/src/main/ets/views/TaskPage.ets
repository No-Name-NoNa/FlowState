/**
 * TaskPage.ets
 * 任务模块主视图。
 * 包含：Header（标题 + 搜索 + 标签筛选）、可动画展开的搜索栏、
 * 标签筛选 chips、TaskListView 列表主体、底部「+ 新建任务」按钮。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_FONT_TOKENS,
  KEY_PENDING_ARCHIVE_TASK_ID,
  KEY_TASK_NEEDS_REFRESH,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { TaskViewModel } from '../viewmodel/TaskViewModel';
import { TaskEntry } from '../model/TaskEntry';
import { TaskListView } from './TaskListView';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

;

/** 任务模块主视图组件 */
@Component
export struct TaskPage {
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  /** 跨页刷新信号：任务编辑/新建页保存后置 true，此处检测到后重新加载列表 */
  @Watch('onTaskRefreshChanged')
  @StorageLink(KEY_TASK_NEEDS_REFRESH) taskNeedsRefresh: boolean = false;
  /** 当前要渲染的过滤后任务（ForEach 数据源） */
  @State tasks: TaskEntry[] = [];
  /** 所有标签的聚合列表，用于标签筛选 chips */
  @State tagList: string[] = [];
  /** 当前搜索关键词 */
  @State searchKeyword: string = '';
  /** 当前激活的标签筛选，空字符串表示全部 */
  @State activeTag: string = '';
  /** 搜索栏是否展开 */
  @State showSearch: boolean = false;
  /** 搜索栏动画高度（0 = 收起，48 = 展开） */
  @State searchBarHeight: number = 0;
  /** 标签筛选区是否展开 */
  @State showTagFilter: boolean = false;
  /** 标签筛选区动画高度（0 = 收起，40 = 展开） */
  @State tagFilterHeight: number = 0;
  /** 列表是否为空，控制 TaskListView 的空状态提示 */
  @State tasksIsEmpty: boolean = true;
  /**
   * 时钟 tick，每 60s 自增。同时用于：
   * 1. 触发 TaskListView → TaskItemComponent 重渲染，刷新截止时间倒计时文字。
   * 2. 驱动 autoCompleteOverdue 定时检查并自动完成逾期任务。
   */
  @State private clockTick: number = 0;
  /** 对齐到整分钟时刻的 setTimeout ID */
  private alignTimer: number = -1;
  /** 60s 定时器 ID，在 aboutToDisappear 时清理 */
  private tickTimer: number = -1;
  // ── 「+ 新建任务」按钮扩散特效状态 ────────────────────────────────────────
  @State newBtnPressedIndex: number = -1;
  @State newBtnSpreadScale: number = 0;
  @State newBtnSpreadOpacity: number = 0;
  @State newBtnCenterX: number = 0;

  aboutToAppear(): void {
    this.loadData();
    // 先等到下一个整分钟时刻，再以 60s 为周期精准触发
    // 保证「剩余 1 分钟 → 逾期」等卡点转换在真实时刻立即刷新
    const msUntilNextMinute: number = 60000 - (Date.now() % 60000);
    this.alignTimer = setTimeout(() => {
      this.onClockTick();
      this.tickTimer = setInterval(() => {
        this.onClockTick();
      }, 60000);
    }, msUntilNextMinute);
  }

  aboutToDisappear(): void {
    clearTimeout(this.alignTimer);
    clearInterval(this.tickTimer);
  }

  build() {
    Column() {
      // ── 顶部 Header ──────────────────────────────────────────────────────
      Row() {
        // 页面标题（左）
        Text(I18nHelper.t(I18nKeys.TAB_TASKS, this.currentLanguage))
          .fontSize(this.fontTokens.headerTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)

        // 搜索图标
        Image($r('app.media.ic_search'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.showSearch ? this.themeTokens.colorAccent : this.themeTokens.colorTextSecondary)
          .margin({ right: $r('app.float.spacing_md') })
          .onClick(() => {
            this.toggleSearch();
          })

        // 标签筛选图标
        Image($r('app.media.ic_filter'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(
            this.showTagFilter ? this.themeTokens.colorAccent : this.themeTokens.colorTextSecondary
          )
          .margin({ right: $r('app.float.spacing_md') })
          .onClick(() => {
            this.toggleTagFilter();
          })

        // 多任务计时器入口图标
        Image($r('app.media.ic_stopwatch'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextSecondary)
          .margin({ right: $r('app.float.spacing_md') })
          .onClick(() => {
            router.pushUrl({ url: 'pages/TimerPage' });
          })

        // 设置入口图标
        Image($r('app.media.ic_settings'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextSecondary)
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingsPage' });
          })
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)

      // ── 搜索栏（动画展开/收起，高度 0→48） ──────────────────────────────
      Row() {
        TextInput({
          text: this.searchKeyword,
          placeholder: I18nHelper.t(I18nKeys.TASK_SEARCH_PLACEHOLDER, this.currentLanguage),
        })
          .layoutWeight(1)
          .height(36)
          .fontSize(this.fontTokens.body)
          .fontColor(this.themeTokens.colorTextPrimary)
          .placeholderColor(this.themeTokens.colorTextSecondary)
          .caretColor(this.themeTokens.colorAccent)
          .backgroundColor(this.themeTokens.colorDivider)
          .borderRadius(8)
          .padding({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
          .onChange((val: string) => {
            this.searchKeyword = val;
            TaskViewModel.filter(val, -1, this.activeTag);
            this.refreshTasks();
          })
      }
      .width('100%')
      .height(this.searchBarHeight)
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .clip(true)

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 标签筛选区（点击筛选图标触发，高度动画展开/收起） ─────────────────
      Row() {
        Scroll() {
          Row({ space: $r('app.float.spacing_xs') }) {
            // 「全部」chip
            Text(I18nHelper.t(I18nKeys.TASK_TAG_ALL, this.currentLanguage))
              .fontSize(this.fontTokens.label)
              .fontColor(this.activeTag === '' ? this.themeTokens.colorBackground : this.themeTokens.colorTextSecondary)
              .height($r('app.float.tag_chip_height'))
              .padding({ left: $r('app.float.tag_chip_padding_h'), right: $r('app.float.tag_chip_padding_h') })
              .backgroundColor(this.activeTag === '' ? this.themeTokens.colorAccent : Color.Transparent)
              .border({
                width: 0.5,
                color: this.activeTag === '' ? this.themeTokens.colorAccent : this.themeTokens.colorDivider,
                radius: 11,
              })
              .onClick(() => {
                animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                  this.activeTag = '';
                });
                TaskViewModel.filter(this.searchKeyword, -1, '');
                this.refreshTasks();
              })

            // 各标签 chip
            ForEach(this.tagList, (tag: string) => {
              Text('#' + tag)
                .fontSize(this.fontTokens.label)
                .fontColor(
                  this.activeTag === tag
                    ? this.themeTokens.colorBackground
                    : this.themeTokens.colorAccent
                )
                .height($r('app.float.tag_chip_height'))
                .padding({ left: $r('app.float.tag_chip_padding_h'), right: $r('app.float.tag_chip_padding_h') })
                .backgroundColor(
                  this.activeTag === tag ? this.themeTokens.colorAccent : Color.Transparent
                )
                .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 11 })
                .onClick(() => {
                  const newTag: string = this.activeTag === tag ? '' : tag;
                  animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                    this.activeTag = newTag;
                  });
                  TaskViewModel.filter(this.searchKeyword, -1, newTag);
                  this.refreshTasks();
                })
            }, (tag: string) => tag)
          }
          .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None)
        .width('100%')
      }
      .width('100%')
      .height(this.tagFilterHeight)
      .clip(true)

      // 标签筛选区展开时显示底部分割线
      if (this.showTagFilter) {
        Divider()
          .strokeWidth(DIVIDER_STROKE_WIDTH)
          .color(this.themeTokens.colorDivider)
          .width('100%')
      }

      // ── 列表主体 ─────────────────────────────────────────────────────────
      TaskListView({
        tasks: $tasks,
        showEmptyHint: this.tasksIsEmpty,
        clockTick: this.clockTick,
        onDataChanged: () => {
          this.loadData();
        },
      })

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 底部「+ 新建任务」文字按钮 ─────────────────────────────────────────
      Stack({ alignContent: Alignment.Center }) {
        // 横向扩散特效矩形（仅在按下时挂载）
        if (this.newBtnPressedIndex === 0) {
          Rect()
            .width('100%')
            .height($r('app.float.inbox_input_bar_height'))
            .fill(this.themeTokens.colorAccent)
            .opacity(this.newBtnSpreadOpacity)
            .scale({ x: this.newBtnSpreadScale, y: 1.0, centerX: this.newBtnCenterX })
            .hitTestBehavior(HitTestMode.None)
        }

        Text(I18nHelper.t(I18nKeys.TASK_NEW_BUTTON, this.currentLanguage))
          .fontSize(this.fontTokens.body)
          .fontColor(this.themeTokens.colorAccent)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height($r('app.float.inbox_input_bar_height'))
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down) {
          this.triggerNewBtnSpread(e.touches[0].x);
        }
      })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/TaskEditorPage',
          params: { taskId: 0, fromInboxId: 0 },
        });
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }

  /** 从 DB 加载数据，刷新所有列表状态 */
  private loadData(): void {
    TaskViewModel.load().then(() => {
      // 冷启动归档处理：FlowAbility.onCreate 发现通知归档参数时
      // 将任务 ID 暂存到 AppStorage，此处 DB 就绪后执行实际归档
      const pendingId: number = AppStorage.get<number>(KEY_PENDING_ARCHIVE_TASK_ID) ?? 0;
      if (pendingId > 0) {
        AppStorage.setOrCreate<number>(KEY_PENDING_ARCHIVE_TASK_ID, 0);
        TaskViewModel.archive(pendingId).then(() => {
          TaskViewModel.load().then(() => {
            this.refreshTasks();
          });
        });
      } else {
        this.refreshTasks();
      }
    });
  }

  /** 整分钟回调：检查逾期任务并刷新倒计时显示 */
  private onClockTick(): void {
    TaskViewModel.autoCompleteOverdue().then((changed: boolean) => {
      if (changed) {
        this.loadData();
      } else {
        this.refreshTasks();
      }
    });
  }

  /** 将 ViewModel 过滤结果同步到视图状态，同时刷新倒计时显示 */
  private refreshTasks(): void {
    // 每次数据刷新时同步更新倒计时，确保创建/编辑/返回页面后立即显示精准剩余时间
    this.clockTick++;
    this.tasks = TaskViewModel.filteredTasks.slice();
    this.tagList = TaskViewModel.getAllTags();
    this.tasksIsEmpty = this.tasks.length === 0;
  }

  /** 跨页刷新信号回调：TaskEditorPage 保存后触发，需重新从 DB 加载以包含新建/编辑的任务 */
  private onTaskRefreshChanged(): void {
    if (this.taskNeedsRefresh) {
      AppStorage.set<boolean>(KEY_TASK_NEEDS_REFRESH, false);
      this.loadData();
    }
  }

  /** 切换搜索栏展开/收起（附带 250ms EaseOut 高度动画） */
  private toggleSearch(): void {
    animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showSearch = !this.showSearch;
      this.searchBarHeight = this.showSearch ? 48 : 0;
      if (!this.showSearch) {
        this.searchKeyword = '';
        TaskViewModel.filter('', -1, this.activeTag);
        this.refreshTasks();
      }
    });
  }

  /** 切换标签筛选区展开/收起（附带 250ms EaseOut 高度动画） */
  private toggleTagFilter(): void {
    animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showTagFilter = !this.showTagFilter;
      this.tagFilterHeight = this.showTagFilter ? 40 : 0;
      if (!this.showTagFilter) {
        this.activeTag = '';
        TaskViewModel.filter(this.searchKeyword, -1, '');
        this.refreshTasks();
      }
    });
  }

  /** 触发「+ 新建任务」按钮横向扩散特效 */
  private triggerNewBtnSpread(touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx: number) => {
        this.newBtnPressedIndex = idx;
      },
      (scale: number, opacity: number) => {
        this.newBtnSpreadScale = scale;
        this.newBtnSpreadOpacity = opacity;
      },
      (x: number) => {
        this.newBtnCenterX = x;
      },
      0,
      touchX,
    );
  }
}
