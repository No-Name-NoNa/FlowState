import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_FONT_TOKENS,
  KEY_HISTORY_NEEDS_REFRESH,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { MonthGroup, StatisticsViewModel, StatsSummary, TimeRange } from '../viewmodel/StatisticsViewModel';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

interface MonthArchiveParams {
  year: number;
  month: number;
  label: string;
}

interface DayFocusTrend {
  dayOfWeek: number;
  focusMs: number;
  archivedCount: number;
  ratio: number;
  isToday: boolean;
}

@Component
export struct HistoryPage {
  @StorageLink(KEY_APP_LANGUAGE) private currentLanguage: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) private themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) private fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  @Watch('onHistoryRefreshChanged')
  @StorageLink(KEY_HISTORY_NEEDS_REFRESH) private historyVersion: number = 0;
  @State private monthGroups: MonthGroup[] = [];
  @State private todayArchivedCount: number = 0;
  @State private todayFocusMs: number = 0;
  @State private weekFocusMs: number = 0;
  @State private weekArchivedCount: number = 0;
  @State private activeDays: number = 0;
  @State private weekTrends: DayFocusTrend[] = [];
  @State private pressedRowIndex: number = -1;
  @State private rowSpreadScale: number = 0;
  @State private rowSpreadOpacity: number = 0;
  @State private rowSpreadCenterX: number = 0;
  /** loadData 调用序号，防止快速连续刷新时旧异步结果覆盖新数据 */
  private loadSeq: number = 0;

  aboutToAppear(): void {
    this.loadData();
  }

  build() {
    Column() {
      Row() {
        Text(I18nHelper.t(I18nKeys.TAB_HISTORY, this.currentLanguage))
          .fontSize(this.fontTokens.headerTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)

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

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      List({ space: 8 }) {
        ListItem() {
          Column({ space: 0 }) {
            this.TodayStatsRow()
            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
            this.WeeklyTrendCard()
            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
            this.MonthSectionHeader()
            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
          }
          .width('100%')
          .padding({
            left: $r('app.float.spacing_lg'),
            right: $r('app.float.spacing_lg'),
            top: 12,
            bottom: 0,
          })
        }

        ForEach(
          this.monthGroups,
          (group: MonthGroup, index: number) => {
            ListItem() {
              Stack({ alignContent: Alignment.Center }) {
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

                Row() {
                  Text(this.buildMonthLabel(group.year, group.month))
                    .fontSize(this.fontTokens.body)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.themeTokens.colorTextPrimary)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Start)

                  Text(group.count.toString()
                    + I18nHelper.t(I18nKeys.HISTORY_MONTH_ITEMS, this.currentLanguage))
                    .fontSize(this.fontTokens.caption)
                    .fontColor(this.themeTokens.colorTextSecondary)
                    .margin({ right: 8 })

                  Image($r('sys.media.ohos_ic_public_arrow_right'))
                    .width(16)
                    .height(16)
                    .fillColor(this.themeTokens.colorTextSecondary)
                }
                .width('100%')
                .constraintSize({ minHeight: this.fontTokens.inboxItemMinHeight })
                .padding({
                  left: $r('app.float.spacing_lg'),
                  right: $r('app.float.spacing_lg'),
                  top: 14,
                  bottom: 14,
                })
                .alignItems(VerticalAlign.Center)
                .onClick(() => {
                  const params: MonthArchiveParams = {
                    year: group.year,
                    month: group.month,
                    label: this.buildMonthLabel(group.year, group.month),
                  };
                  router.pushUrl({ url: 'pages/MonthArchivePage', params: params });
                })
              }
              .width('100%')
              .clip(true)
              .onTouch((e: TouchEvent) => {
                if (e.type === TouchType.Down) {
                  this.triggerRowSpread(index, e.touches[0].x);
                }
              })
            }
            .swipeAction({
              end: (): void => {
                this.deleteMonthButton(group);
              },
            })
          },
          (group: MonthGroup) => group.year.toString() + '_' + group.month.toString() + '_' + group.count.toString()
        )

        if (this.monthGroups.length === 0) {
          ListItem() {
            Column() {
              Text(I18nHelper.t(I18nKeys.HISTORY_MONTHS_EMPTY, this.currentLanguage))
                .fontSize(this.fontTokens.bodySmall)
                .fontColor(this.themeTokens.colorTextPrimary)
            }
            .width('100%')
            .padding({ top: 28, bottom: 28 })
            .alignItems(HorizontalAlign.Center)
            .margin({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }

  /** 今日专注统计：大号强调时长 + 归档任务数，直接读取 @State 变量确保响应式更新 */
  @Builder
  private TodayStatsRow(): void {
    Column({ space: 6 }) {
      Text(I18nHelper.t(I18nKeys.HISTORY_TODAY_FOCUS, this.currentLanguage))
        .fontSize(this.fontTokens.caption)
        .fontColor(this.themeTokens.colorTextSecondary)

      Text(StatisticsViewModel.formatDuration(this.todayFocusMs))
        .fontSize(Math.round(this.fontTokens.timerDigit * 0.65))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeTokens.colorAccent)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(I18nHelper.t(I18nKeys.HISTORY_TREND_DONE, this.currentLanguage)
        .replace('{count}', this.todayArchivedCount.toString()))
        .fontSize(this.fontTokens.caption)
        .fontColor(this.themeTokens.colorTextSecondary)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 20, bottom: 16 })
  }

  /** 本周专注趋势：标题行右侧显示本周汇总，柱状图仅保留色柱和日期标签 */
  @Builder
  private WeeklyTrendCard(): void {
    Column({ space: 14 }) {
      Row() {
        Text(I18nHelper.t(I18nKeys.HISTORY_METRIC_WEEK_FOCUS, this.currentLanguage))
          .fontSize(this.fontTokens.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)

        Text(StatisticsViewModel.formatDuration(this.weekFocusMs)
          + '  '
          + this.activeDays.toString()
          + I18nHelper.t(I18nKeys.HISTORY_METRIC_DAYS_UNIT, this.currentLanguage))
          .fontSize(this.fontTokens.caption)
          .fontColor(this.themeTokens.colorTextSecondary)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 柱状图：仅色柱 + 日期标签，不显示每格时长文字
      Row({ space: 6 }) {
        ForEach(
          this.weekTrends,
          (item: DayFocusTrend) => {
            Column({ space: 4 }) {
              Stack({ alignContent: Alignment.Bottom }) {
                // 轨道底色，始终占满容器高度
                Rect()
                  .width(10)
                  .height(72)
                  .fill(this.getBarTrackColor())
                  .borderRadius(5)
                // 进度条，按比例叠加在轨道上
                if (item.focusMs > 0) {
                  Rect()
                    .width(10)
                    .height(this.getBarHeight(item))
                    .fill(item.isToday ? this.themeTokens.colorAccent : this.themeTokens.colorTextSecondary)
                    .borderRadius(5)
                }
              }
              .width('100%')
              .height(72)

              Text(this.buildDayLabel(item.dayOfWeek, item.isToday))
                .fontSize(this.fontTokens.label)
                .fontColor(item.isToday ? this.themeTokens.colorAccent : this.themeTokens.colorTextSecondary)
                .maxLines(1)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          },
          (item: DayFocusTrend) => item.dayOfWeek.toString() + item.focusMs.toString()
        )
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: 4, bottom: 16 })
  }

  @Builder
  private MonthSectionHeader(): void {
    Row() {
      Text(I18nHelper.t(I18nKeys.HISTORY_MONTH_SECTION_TITLE, this.currentLanguage))
        .fontSize(this.fontTokens.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeTokens.colorTextPrimary)
        .layoutWeight(1)
      Text(this.monthGroups.length.toString()
        + ' '
        + I18nHelper.t(I18nKeys.HISTORY_MONTH_SECTION_UNIT, this.currentLanguage))
        .fontSize(this.fontTokens.caption)
        .fontColor(this.themeTokens.colorTextSecondary)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: 10, bottom: 10 })
  }

  private onHistoryRefreshChanged(): void {
    // 计数器每次递增都会触发此回调，无需判断具体值，直接重新加载
    this.loadData();
  }

  private loadData(): void {
    // 递增序号，确保只有最新一次 loadData 的结果才会被应用
    const seq: number = ++this.loadSeq;
    const now: Date = new Date();
    const todayRange: TimeRange = StatisticsViewModel.getTodayRange();
    const weekRange: TimeRange = StatisticsViewModel.getWeekRange();

    // 构建过去 7 天的时间范围（含今日）
    const dayRanges: TimeRange[] = [];
    const dayOfWeeks: number[] = [];
    for (let offset: number = 6; offset >= 0; offset--) {
      const d: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - offset, 0, 0, 0, 0);
      const to: Date = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);
      dayRanges.push({ from: d.getTime(), to: to.getTime() + 1 });
      dayOfWeeks.push(d.getDay());
    }

    // 将今日、本周、7日三组查询合并为一次 Promise.all，消除多异步链竞态
    const allRanges: TimeRange[] = [todayRange, weekRange];
    for (const r of dayRanges) {
      allRanges.push(r);
    }
    const allQueries: Promise<StatsSummary>[] = allRanges.map((r: TimeRange) => StatisticsViewModel.getStats(r));

    Promise.all(allQueries).then((results: StatsSummary[]) => {
      if (seq !== this.loadSeq) {
        return;
      }
      const todayStat: StatsSummary = results[0];
      const weekStat: StatsSummary = results[1];
      const dayStats: StatsSummary[] = results.slice(2);

      this.todayFocusMs = todayStat.focusTimeMs;
      this.todayArchivedCount = todayStat.archivedCount;
      this.weekFocusMs = weekStat.focusTimeMs;
      this.weekArchivedCount = weekStat.archivedCount;

      let maxFocusMs: number = 0;
      let activeDays: number = 0;
      for (const s of dayStats) {
        if (s.focusTimeMs > maxFocusMs) {
          maxFocusMs = s.focusTimeMs;
        }
        if (s.focusTimeMs > 0 || s.archivedCount > 0) {
          activeDays++;
        }
      }
      this.activeDays = activeDays;

      // 柱状图 7 日趋势
      const chartMaxFocusMs: number = Math.max(maxFocusMs, 30 * 60 * 1000);
      const trends: DayFocusTrend[] = [];
      for (let i: number = 0; i < dayStats.length; i++) {
        const ratio: number = dayStats[i].focusTimeMs > 0 ? dayStats[i].focusTimeMs / chartMaxFocusMs : 0;
        trends.push({
          dayOfWeek: dayOfWeeks[i],
          focusMs: dayStats[i].focusTimeMs,
          archivedCount: dayStats[i].archivedCount,
          ratio,
          isToday: i === dayStats.length - 1,
        });
      }
      this.weekTrends = trends;
    });

    StatisticsViewModel.loadMonthGroups().then((groups: MonthGroup[]) => {
      if (seq !== this.loadSeq) {
        return;
      }
      this.monthGroups = groups;
    });
  }

  /** 根据当前语言生成星期标签，今日显示专属文字 */
  private buildDayLabel(dayOfWeek: number, isToday: boolean): string {
    if (isToday) {
      return I18nHelper.t(I18nKeys.HISTORY_TODAY_LABEL, this.currentLanguage);
    }
    const weekdayKeys: I18nKeys[] = [
      I18nKeys.TASK_RECURRING_WEEKDAY_SUN,
      I18nKeys.TASK_RECURRING_WEEKDAY_MON,
      I18nKeys.TASK_RECURRING_WEEKDAY_TUE,
      I18nKeys.TASK_RECURRING_WEEKDAY_WED,
      I18nKeys.TASK_RECURRING_WEEKDAY_THU,
      I18nKeys.TASK_RECURRING_WEEKDAY_FRI,
      I18nKeys.TASK_RECURRING_WEEKDAY_SAT,
    ];
    const key: I18nKeys = weekdayKeys[dayOfWeek];
    return I18nHelper.t(key, this.currentLanguage);
  }

  /** 根据当前语言生成月份标签，如「2026年5月」或「5/2026」 */
  private buildMonthLabel(year: number, month: number): string {
    return I18nHelper.t(I18nKeys.HISTORY_MONTH_FORMAT, this.currentLanguage)
      .replace('{year}', year.toString())
      .replace('{month}', month.toString());
  }

  private getBarHeight(item: DayFocusTrend): number {
    if (item.ratio <= 0) {
      return 0;
    }
    return Math.max(4, Math.round(item.ratio * 64));
  }

  private getBarTrackColor(): string {
    return this.isDarkTheme() ? '#252C34' : '#EDF1F2';
  }

  private getBarColor(): string {
    return this.isDarkTheme() ? '#8DB8C8' : '#8BBAC5';
  }

  private isDarkTheme(): boolean {
    const bg: string = this.themeTokens.colorBackground.toLowerCase();
    return bg === '#000000' || bg === '#1a1a18' || bg === '#1a0a1e' || bg === '#282c34' || bg === '#2b2b2b';
  }

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

  @Builder
  private deleteMonthButton(group: MonthGroup): void {
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
        title: I18nHelper.t(I18nKeys.HISTORY_MONTH_DELETE_TITLE, this.currentLanguage),
        message: I18nHelper.t(I18nKeys.HISTORY_MONTH_DELETE_MSG, this.currentLanguage),
        primaryButton: {
          value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.currentLanguage),
          action: () => {
            StatisticsViewModel.deleteArchivedInRange(group.from, group.to).then(() => {
              this.loadData();
            });
          },
        },
        secondaryButton: {
          value: I18nHelper.t(I18nKeys.DIALOG_CANCEL, this.currentLanguage),
          action: () => {
          },
        },
        autoCancel: true,
      });
    })
  }
}
