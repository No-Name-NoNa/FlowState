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
  label: string;
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
          Column({ space: 10 }) {
            this.FocusOverviewCard()
            this.WeeklyTrendCard()
            this.MonthSectionHeader()
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
                  Column() {
                    Text(group.label)
                      .fontSize(this.fontTokens.body)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.themeTokens.colorTextPrimary)
                  }
                  .layoutWeight(1)

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
                    label: group.label,
                  };
                  router.pushUrl({ url: 'pages/MonthArchivePage', params: params });
                })
              }
              .width('100%')
              .clip(true)
              .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
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

  @Builder
  private FocusOverviewCard(): void {
    Column({ space: 12 }) {
      Row() {
        Text('专注概览')
          .fontSize(this.fontTokens.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)

        Text('近 7 天')
          .fontSize(this.fontTokens.caption)
          .fontColor(this.themeTokens.colorTextSecondary)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 0 }) {
        this.MetricTile('今日专注', StatisticsViewModel.formatDuration(this.todayFocusMs), true)
        this.MetricTile('今日归档', this.todayArchivedCount.toString() + ' 条', false)
        this.MetricTile('本周专注', StatisticsViewModel.formatDuration(this.weekFocusMs), false)
        this.MetricTile('活跃天数', this.activeDays.toString() + ' 天', false)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 4, bottom: 4 })
  }

  @Builder
  private MetricTile(label: string, value: string, highlighted: boolean): void {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(highlighted ? this.fontTokens.titleLarge : this.fontTokens.body)
        .fontWeight(FontWeight.Bold)
        .fontColor(highlighted ? this.themeTokens.colorAccent : this.themeTokens.colorTextPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(label)
        .fontSize(this.fontTokens.label)
        .fontColor(this.themeTokens.colorTextSecondary)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 4, right: 4, top: 6, bottom: 6 })
  }

  @Builder
  private WeeklyTrendCard(): void {
    Column({ space: 12 }) {
      Row() {
        Text('专注时间变化')
          .fontSize(this.fontTokens.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: 6 }) {
        ForEach(
          this.weekTrends,
          (item: DayFocusTrend) => {
            Column({ space: 6 }) {
              Text(this.getCompactDuration(item.focusMs))
                .fontSize(this.fontTokens.label)
                .fontWeight(item.focusMs > 0 ? FontWeight.Medium : FontWeight.Regular)
                .fontColor(item.focusMs > 0 ? this.themeTokens.colorTextPrimary : this.themeTokens.colorTextSecondary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Stack({ alignContent: Alignment.Bottom }) {
                if (item.focusMs > 0) {
                  Rect()
                    .width(10)
                    .height(this.getBarHeight(item))
                    .fill(item.isToday ? this.themeTokens.colorAccent : this.getBarColor())
                    .borderRadius(5)
                } else {
                  Rect()
                    .width(10)
                    .height(2)
                    .fill(this.getBarTrackColor())
                    .borderRadius(1)
                }
              }
              .width('100%')
              .height(64)

              Text(item.label)
                .fontSize(this.fontTokens.label)
                .fontColor(item.isToday ? this.themeTokens.colorAccent : this.themeTokens.colorTextSecondary)
                .maxLines(1)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          },
          (item: DayFocusTrend) => item.label + item.focusMs.toString()
        )
      }
      .width('100%')

      Row({ space: 10 }) {
        Text('平均 ' + StatisticsViewModel.formatDuration(this.getAverageDailyFocusMs()))
          .fontSize(this.fontTokens.caption)
          .fontColor(this.themeTokens.colorTextSecondary)
          .layoutWeight(1)
        Text('完成 ' + this.weekArchivedCount.toString() + ' 条')
          .fontSize(this.fontTokens.caption)
          .fontColor(this.themeTokens.colorTextSecondary)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 12, bottom: 12 })
  }

  @Builder
  private MonthSectionHeader(): void {
    Row() {
      Text('月度归档')
        .fontSize(this.fontTokens.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeTokens.colorTextPrimary)
        .layoutWeight(1)
      Text(this.monthGroups.length.toString() + ' 个月')
        .fontSize(this.fontTokens.caption)
        .fontColor(this.themeTokens.colorTextSecondary)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: 6, bottom: 4 })
  }

  private onHistoryRefreshChanged(): void {
    // 计数器每次递增都会触发此回调，无需判断具体值，直接重新加载
    this.loadData();
  }

  private loadData(): void {
    // 递增序号，确保只有最新一次 loadData 的结果才会被应用
    const seq: number = ++this.loadSeq;
    const todayRange: TimeRange = StatisticsViewModel.getTodayRange();
    StatisticsViewModel.getStats(todayRange).then((summary: StatsSummary) => {
      if (seq !== this.loadSeq) {
        return;
      }
      this.todayArchivedCount = summary.archivedCount;
      this.todayFocusMs = summary.focusTimeMs;
    });
    StatisticsViewModel.getStats(StatisticsViewModel.getWeekRange()).then((summary: StatsSummary) => {
      if (seq !== this.loadSeq) {
        return;
      }
      this.weekArchivedCount = summary.archivedCount;
      this.weekFocusMs = summary.focusTimeMs;
    });
    StatisticsViewModel.loadMonthGroups().then((groups: MonthGroup[]) => {
      if (seq !== this.loadSeq) {
        return;
      }
      this.monthGroups = groups;
    });
    this.loadWeekTrend(seq);
  }

  private loadWeekTrend(seq: number): void {
    const now: Date = new Date();
    const ranges: TimeRange[] = [];
    const labels: string[] = [];
    for (let offset: number = 6; offset >= 0; offset--) {
      const d: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - offset, 0, 0, 0, 0);
      const to: Date = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);
      ranges.push({ from: d.getTime(), to: to.getTime() + 1 });
      labels.push(offset === 0 ? '今' : this.formatWeekday(d));
    }

    Promise.all(ranges.map((range: TimeRange) => StatisticsViewModel.getStats(range)))
      .then((stats: StatsSummary[]) => {
        if (seq !== this.loadSeq) {
          return;
        }
        let maxFocusMs: number = 0;
        let activeDays: number = 0;
        for (const item of stats) {
          if (item.focusTimeMs > maxFocusMs) {
            maxFocusMs = item.focusTimeMs;
          }
          if (item.focusTimeMs > 0 || item.archivedCount > 0) {
            activeDays++;
          }
        }

        const chartMaxFocusMs: number = Math.max(maxFocusMs, 30 * 60 * 1000);
        const trends: DayFocusTrend[] = [];
        for (let i: number = 0; i < stats.length; i++) {
          const ratio: number = stats[i].focusTimeMs > 0 ? stats[i].focusTimeMs / chartMaxFocusMs : 0;
          trends.push({
            label: labels[i],
            focusMs: stats[i].focusTimeMs,
            archivedCount: stats[i].archivedCount,
            ratio,
            isToday: i === stats.length - 1,
          });
        }
        this.activeDays = activeDays;
        this.weekTrends = trends;
      });
  }

  private formatWeekday(date: Date): string {
    const day: number = date.getDay();
    const labels: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return labels[day];
  }

  private getAverageDailyFocusMs(): number {
    if (this.weekTrends.length === 0) {
      return 0;
    }
    return Math.floor(this.weekFocusMs / this.weekTrends.length);
  }

  private getBarHeight(item: DayFocusTrend): number {
    if (item.ratio <= 0) {
      return 0;
    }
    return Math.max(4, Math.round(item.ratio * 64));
  }

  private getCompactDuration(ms: number): string {
    if (ms <= 0) {
      return '0';
    }
    const totalMin: number = Math.floor(ms / 60000);
    if (totalMin < 1) {
      return '<1m';
    }
    if (totalMin < 60) {
      return totalMin.toString() + 'm';
    }
    const hours: number = Math.floor(totalMin / 60);
    const mins: number = totalMin % 60;
    if (mins === 0) {
      return hours.toString() + 'h';
    }
    return hours.toString() + 'h' + mins.toString() + 'm';
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
