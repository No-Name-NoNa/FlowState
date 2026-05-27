/**
 * MonthArchivePage.ets
 * 月份归档详情页。
 *
 * 路由参数：{ year: number, month: number, label: string }
 * 展示指定月份内的所有已归档任务，支持关键词搜索和标签筛选。
 *  - 条目样式与任务列表一致（优先级竖条、序号、标题、标签、归档日期）
 *  - 左滑单条：二次确认后删除该条归档任务
 *  - 点击条目：跳转 ArchivedTaskDetailPage 查看详情
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_FONT_TOKENS,
  KEY_MONTH_ARCHIVE_NEEDS_REFRESH,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { StatisticsViewModel, StatsSummary, TimeRange } from '../viewmodel/StatisticsViewModel';
import { TaskEntry, TaskPriority } from '../model/TaskEntry';
import { parseTags } from '../model/InboxEntry';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';
import { HistoryRefreshSignal } from '../util/HistoryRefreshSignal';

/** 路由参数结构 */
interface MonthArchiveRouterParams {
  year: number;
  month: number;
  label: string;
}

/** ArchivedTaskDetailPage 路由参数 */
interface ArchiveDetailParams {
  taskId: number;
}

@Entry
@Component
struct MonthArchivePage {
  @StorageLink(KEY_APP_LANGUAGE) private lang: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) private themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) private fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  /** ArchivedTaskDetailPage 恢复/删除后触发本页刷新的专属信号 */
  @Watch('onMonthArchiveRefreshChanged')
  @StorageLink(KEY_MONTH_ARCHIVE_NEEDS_REFRESH) private monthArchiveNeedsRefresh: boolean = false;
  /** 当前月份的所有归档任务（全量缓存） */
  @State private allTasks: TaskEntry[] = [];
  /** 过滤后的展示列表 */
  @State private filteredTasks: TaskEntry[] = [];
  /** 所有标签聚合（从全量任务中提取） */
  @State private tagList: string[] = [];
  /** 搜索关键词 */
  @State private searchKeyword: string = '';
  /** 当前激活的标签筛选，空字符串 = 全部 */
  @State private activeTag: string = '';
  /** 搜索栏是否展开 */
  @State private showSearch: boolean = false;
  /** 搜索栏动画高度（0=收起，48=展开） */
  @State private searchBarHeight: number = 0;
  /** 标签筛选区是否展开 */
  @State private showTagFilter: boolean = false;
  /** 标签筛选区动画高度（0=收起，40=展开） */
  @State private tagFilterHeight: number = 0;
  // ── 条目行点击扩散特效状态 ──────────────────────────────────────────────
  @State private pressedRowIndex: number = -1;
  @State private rowSpreadScale: number = 0;
  @State private rowSpreadOpacity: number = 0;
  @State private rowSpreadCenterX: number = 0;
  /** 月份标题标签（路由参数传入） */
  private monthLabel: string = '';
  /** 月份起始时间戳（ms，含） */
  private rangeFrom: number = 0;
  /** 月份截止时间戳（ms，不含） */
  private rangeTo: number = 0;
  // ── 月度统计 ─────────────────────────────────────────────────────────────
  /** 本月总专注时长（ms） */
  @State private monthFocusMs: number = 0;
  /** 本月归档任务总数（全量，不受搜索/标签过滤影响） */
  @State private monthArchivedCount: number = 0;
  /** 本月有归档记录的天数 */
  @State private monthActiveDays: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as MonthArchiveRouterParams;
    const year: number = params.year;
    const month: number = params.month;
    this.monthLabel = params.label;
    this.rangeFrom = new Date(year, month - 1, 1, 0, 0, 0, 0).getTime();
    this.rangeTo = new Date(year, month, 1, 0, 0, 0, 0).getTime();
    this.loadData();
  }

  build() {
    Column() {
      // ── 顶部 Header ──────────────────────────────────────────────────────
      Row() {
        Image($r('sys.media.ohos_ic_back'))
          .width(24)
          .height(24)
          .fillColor(this.themeTokens.colorTextPrimary)
          .onClick(() => {
            router.back();
          })
        Text(this.monthLabel)
          .fontSize(this.fontTokens.headerTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .margin({ left: 12 })

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
          .onClick(() => {
            this.toggleTagFilter();
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
          placeholder: I18nHelper.t(I18nKeys.MONTH_ARCHIVE_SEARCH, this.lang),
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
            this.applyFilter();
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

      // ── 标签筛选区（动画展开/收起） ──────────────────────────────────────
      Row() {
        Scroll() {
          Row({ space: $r('app.float.spacing_xs') }) {
            // 「全部」chip
            Text(I18nHelper.t(I18nKeys.MONTH_ARCHIVE_TAG_ALL, this.lang))
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
                this.applyFilter();
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
                .backgroundColor(this.activeTag === tag ? this.themeTokens.colorAccent : Color.Transparent)
                .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 11 })
                .onClick(() => {
                  const newTag: string = this.activeTag === tag ? '' : tag;
                  animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                    this.activeTag = newTag;
                  });
                  this.applyFilter();
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

      if (this.showTagFilter) {
        Divider()
          .strokeWidth(DIVIDER_STROKE_WIDTH)
          .color(this.themeTokens.colorDivider)
          .width('100%')
      }

      // ── 归档任务列表 ─────────────────────────────────────────────────────
      Stack({ alignContent: Alignment.Center }) {
        List() {
          // ── 月度统计卡片 ─────────────────────────────────────────────────
          ListItem() {
            Column({ space: 0 }) {
              this.MonthStatsCard()
              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
            }
            .width('100%')
            .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
          }

          ForEach(
            this.filteredTasks,
            (task: TaskEntry, index: number) => {
              ListItem() {
                Stack({ alignContent: Alignment.Center }) {
                  // 横向扩散特效矩形
                  Rect()
                    .width('100%')
                    .height(this.fontTokens.inboxItemMinHeight)
                    .fill(this.themeTokens.colorTextPrimary)
                    .opacity(this.pressedRowIndex === index ? this.rowSpreadOpacity : 0)
                    .scale({
                      x: this.pressedRowIndex === index ? this.rowSpreadScale : 0,
                      y: 1.0,
                      centerX: this.rowSpreadCenterX,
                    })
                    .hitTestBehavior(HitTestMode.None)

                  Row({ space: 10 }) {
                    // 序号（1-based）
                    Text((index + 1).toString())
                      .fontSize(this.fontTokens.body)
                      .fontColor(this.themeTokens.colorTextSecondary)
                      .width(26)
                      .textAlign(TextAlign.Start)
                      .flexShrink(0)

                    // 主内容区（标题 + 标签行）
                    Column({ space: 4 }) {
                      // 标题行
                      Text(task.title)
                        .fontSize(this.fontTokens.body)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.themeTokens.colorTextPrimary)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')

                      // 元信息行：标签 + 归档日期
                      if (task.tags !== '' || task.updatedAt > 0) {
                        Row({ space: 6 }) {
                          // 标签列表（最多 2 个）
                          if (task.tags !== '') {
                            ForEach(
                              parseTags(task.tags).slice(0, 2),
                              (tag: string) => {
                                Text('#' + tag)
                                  .fontSize(this.fontTokens.caption)
                                  .fontColor(this.themeTokens.colorAccent)
                                  .maxLines(1)
                                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                                  .constraintSize({ maxWidth: 72 })
                                  .flexShrink(0)
                              },
                              (tag: string) => tag
                            )
                          }
                          Blank()
                          // 归档日期
                          Text(this.formatDate(task.updatedAt))
                            .fontSize(this.fontTokens.caption)
                            .fontColor(this.themeTokens.colorTextSecondary)
                            .flexShrink(0)
                        }
                        .width('100%')
                        .alignItems(VerticalAlign.Center)
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .constraintSize({ minHeight: this.fontTokens.inboxItemMinHeight })
                  .padding({
                    left: 12,
                    right: 16,
                    top: 14,
                    bottom: 14,
                  })
                  .alignItems(VerticalAlign.Center)
                }
                .width('100%')
                .clip(true)
                .onTouch((e: TouchEvent) => {
                  if (e.type === TouchType.Down) {
                    this.triggerRowSpread(index, e.touches[0].x);
                  }
                })
                .onClick(() => {
                  const params: ArchiveDetailParams = { taskId: task.id };
                  router.pushUrl({ url: 'pages/ArchivedTaskDetailPage', params: params });
                })
                // 优先级左侧竖条
                .borderWidth({ left: 3 })
                .borderColor({ left: this.getPriorityBorderColor(task.priority) })
                .borderStyle({ left: BorderStyle.Solid })
              }
              .swipeAction({
                end: (): void => {
                  this.deleteTaskButton(task.id);
                },
              })
            },
            (task: TaskEntry) => task.id.toString() + '_' + task.updatedAt.toString()
          )
        }
        .width('100%')
        .height('100%')
        .divider({ strokeWidth: DIVIDER_STROKE_WIDTH, color: this.themeTokens.colorDivider })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        // 空状态提示
        if (this.filteredTasks.length === 0) {
          Column() {
            Text(I18nHelper.t(I18nKeys.MONTH_ARCHIVE_EMPTY, this.lang))
              .fontSize(this.fontTokens.caption)
              .fontColor(this.themeTokens.colorTextSecondary)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .hitTestBehavior(HitTestMode.None)
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }

  /** ArchivedTaskDetailPage 恢复/删除后的专属刷新回调 */
  private onMonthArchiveRefreshChanged(): void {
    if (this.monthArchiveNeedsRefresh) {
      AppStorage.set<boolean>(KEY_MONTH_ARCHIVE_NEEDS_REFRESH, false);
      this.loadData();
    }
  }

  /** 从 DB 加载本月全量归档任务 + 月度专注时长 */
  private loadData(): void {
    StatisticsViewModel.loadArchivedTasksInRange(this.rangeFrom, this.rangeTo).then((tasks: TaskEntry[]) => {
      this.allTasks = tasks;
      this.monthArchivedCount = tasks.length;
      this.monthActiveDays = this.computeActiveDays(tasks);
      this.rebuildTagList();
      this.applyFilter();
    });
    const range: TimeRange = { from: this.rangeFrom, to: this.rangeTo };
    StatisticsViewModel.getStats(range).then((s: StatsSummary) => {
      this.monthFocusMs = s.focusTimeMs;
    });
  }

  /** 统计 allTasks 中有归档记录的不重复天数 */
  private computeActiveDays(tasks: TaskEntry[]): number {
    const keys: number[] = [];
    for (const t of tasks) {
      const d: Date = new Date(t.updatedAt);
      const k: number = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
      if (keys.indexOf(k) < 0) {
        keys.push(k);
      }
    }
    return keys.length;
  }

  /** 提取所有标签的并集 */
  private rebuildTagList(): void {
    const tagSet: string[] = [];
    for (const task of this.allTasks) {
      if (task.tags === '') {
        continue;
      }
      const tags: string[] = parseTags(task.tags);
      for (const tag of tags) {
        if (tagSet.indexOf(tag) < 0) {
          tagSet.push(tag);
        }
      }
    }
    this.tagList = tagSet;
  }

  /** 根据当前关键词 + 标签重新过滤 */
  private applyFilter(): void {
    let result: TaskEntry[] = this.allTasks.slice();
    if (this.searchKeyword.length > 0) {
      const kw: string = this.searchKeyword.toLowerCase();
      result = result.filter((t: TaskEntry) =>
      t.title.toLowerCase().indexOf(kw) >= 0
        || t.content.toLowerCase().indexOf(kw) >= 0
      );
    }
    if (this.activeTag.length > 0) {
      result = result.filter((t: TaskEntry) => {
        if (t.tags === '') {
          return false;
        }
        const tags: string[] = parseTags(t.tags);
        return tags.indexOf(this.activeTag) >= 0;
      });
    }
    this.filteredTasks = result;
  }

  /** 切换搜索栏展开/收起 */
  private toggleSearch(): void {
    animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showSearch = !this.showSearch;
      this.searchBarHeight = this.showSearch ? 48 : 0;
      if (!this.showSearch) {
        this.searchKeyword = '';
        this.applyFilter();
      }
    });
  }

  /** 切换标签筛选区展开/收起 */
  private toggleTagFilter(): void {
    animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showTagFilter = !this.showTagFilter;
      this.tagFilterHeight = this.showTagFilter ? 40 : 0;
      if (!this.showTagFilter) {
        this.activeTag = '';
        this.applyFilter();
      }
    });
  }

  /** 触发条目行横向扩散特效 */
  private triggerRowSpread(index: number, touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx: number) => {
        this.pressedRowIndex = idx;
      },
      (scale: number, opacity: number) => {
        this.rowSpreadScale = scale;
        this.rowSpreadOpacity = opacity;
      },
      (x: number) => {
        this.rowSpreadCenterX = x;
      },
      index,
      touchX,
    );
  }

  /** 获取优先级左侧竖条颜色 */
  private getPriorityBorderColor(priority: number): string {
    if (priority === TaskPriority.URGENT) {
      return '#E84040';
    }
    if (priority === TaskPriority.HIGH) {
      return '#F0A030';
    }
    if (priority === TaskPriority.NORMAL) {
      return this.themeTokens.colorTextSecondary;
    }
    return '#00000000';
  }

  /** 将 updatedAt 格式化为 MM/DD */
  private formatDate(ms: number): string {
    if (ms <= 0) {
      return '';
    }
    const d: Date = new Date(ms);
    const month: string = String(d.getMonth() + 1).padStart(2, '0');
    const day: string = String(d.getDate()).padStart(2, '0');
    return `${month}/${day}`;
  }

  /** 月度统计卡片，布局对标 HistoryPage.WeeklyTrendCard */
  @Builder
  private MonthStatsCard(): void {
    Column({ space: 14 }) {
      // 标题行：左"本月投入"，右 专注时长 + 活跃天数
      Row() {
        Text(I18nHelper.t(I18nKeys.MONTH_ARCHIVE_STATS_FOCUS, this.lang))
          .fontSize(this.fontTokens.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)

        Text(StatisticsViewModel.formatDuration(this.monthFocusMs)
          + '  '
          + this.monthActiveDays.toString()
          + I18nHelper.t(I18nKeys.HISTORY_METRIC_DAYS_UNIT, this.lang))
          .fontSize(this.fontTokens.caption)
          .fontColor(this.themeTokens.colorTextSecondary)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 大号 accent 时长
      Text(StatisticsViewModel.formatDuration(this.monthFocusMs))
        .fontSize(Math.round(this.fontTokens.timerDigit * 0.65))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeTokens.colorAccent)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 小号描述：归档任务数
      Text(I18nHelper.t(I18nKeys.HISTORY_TREND_DONE, this.lang)
        .replace('{count}', this.monthArchivedCount.toString()))
        .fontSize(this.fontTokens.caption)
        .fontColor(this.themeTokens.colorTextSecondary)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 20, bottom: 16 })
  }

  /** 条目左滑删除按钮 */
  @Builder
  private deleteTaskButton(taskId: number): void {
    Row() {
      Image($r('sys.media.ohos_ic_public_cancel'))
        .width($r('app.float.icon_size_md'))
        .height($r('app.float.icon_size_md'))
        .fillColor(this.themeTokens.colorBackground)
    }
    .width(72)
    .height('100%')
    .backgroundColor(this.themeTokens.colorTextPrimary)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      AlertDialog.show({
        title: I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_DELETE, this.lang),
        message: I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_DELETE_MSG, this.lang),
        primaryButton: {
          value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
          action: () => {
            StatisticsViewModel.deleteArchivedTask(taskId).then(() => {
              this.loadData();
              // 通知 HistoryPage 刷新今日统计和月份分组计数
              HistoryRefreshSignal.bump();
            });
          },
        },
        secondaryButton: {
          value: I18nHelper.t(I18nKeys.DIALOG_CANCEL, this.lang),
          action: () => {
          },
        },
        autoCancel: true,
      });
    })
  }
}
