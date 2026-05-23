/**
 * HistoryPage.ets
 * 历史/归档页面视图组件。
 *
 * 展示：
 *  - 今日统计摘要（今日归档数、今日专注时长）
 *  - 月份归档分组列表（按年月倒序）
 *    - 左滑显示 X 按钮，二次确认后删除该月所有归档
 *    - 点击跳转 MonthArchivePage 查看本月归档详情
 *
 * 刷新触发：
 *  - aboutToAppear() 初始加载
 *  - KEY_HISTORY_NEEDS_REFRESH 信号：归档/恢复/删除任何归档任务后由对应逻辑置 true
 */
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
import { MonthGroup, StatisticsViewModel } from '../viewmodel/StatisticsViewModel';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

/** MonthArchivePage 路由参数 */
interface MonthArchiveParams {
  year: number;
  month: number;
  label: string;
}

/** 历史页面视图（月份归档分组列表） */
@Component
export struct HistoryPage {
  @StorageLink(KEY_APP_LANGUAGE) private currentLanguage: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) private themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) private fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  /** 历史页刷新信号：归档/恢复/删除操作后由对应逻辑置 true */
  @Watch('onHistoryRefreshChanged')
  @StorageLink(KEY_HISTORY_NEEDS_REFRESH) private historyNeedsRefresh: boolean = false;
  /** 月份分组列表（最新月份在前） */
  @State private monthGroups: MonthGroup[] = [];
  /** 今日归档数量 */
  @State private todayArchivedCount: number = 0;
  /** 今日专注时长（ms） */
  @State private todayFocusMs: number = 0;
  // ── 月份行点击扩散特效状态 ──────────────────────────────────────────────
  @State private pressedRowIndex: number = -1;
  @State private rowSpreadScale: number = 0;
  @State private rowSpreadOpacity: number = 0;
  @State private rowSpreadCenterX: number = 0;

  aboutToAppear(): void {
    this.loadData();
  }

  build() {
    Column() {
      // ── 顶部 Header ──────────────────────────────────────────────────────
      Row() {
        Text(I18nHelper.t(I18nKeys.TAB_HISTORY, this.currentLanguage))
          .fontSize(this.fontTokens.headerTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 今日统计摘要 ─────────────────────────────────────────────────────
      Row() {
        // 今日归档数
        Column({ space: 4 }) {
          Text(this.todayArchivedCount.toString())
            .fontSize(this.fontTokens.titleLarge)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeTokens.colorTextPrimary)
          Text(I18nHelper.t(I18nKeys.HISTORY_TODAY_ARCHIVED, this.currentLanguage))
            .fontSize(this.fontTokens.caption)
            .fontColor(this.themeTokens.colorTextSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 16, bottom: 16 })

        // 竖向分割线
        Column()
          .width(0.5)
          .height(36)
          .backgroundColor(this.themeTokens.colorDivider)

        // 今日专注时长
        Column({ space: 4 }) {
          Text(StatisticsViewModel.formatDuration(this.todayFocusMs))
            .fontSize(this.fontTokens.titleLarge)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeTokens.colorTextPrimary)
          Text(I18nHelper.t(I18nKeys.HISTORY_TODAY_FOCUS, this.currentLanguage))
            .fontSize(this.fontTokens.caption)
            .fontColor(this.themeTokens.colorTextSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 16, bottom: 16 })
      }
      .width('100%')

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 月份归档列表 ─────────────────────────────────────────────────────
      Stack({ alignContent: Alignment.Center }) {
        List() {
          ForEach(
            this.monthGroups,
            (group: MonthGroup, index: number) => {
              ListItem() {
                Stack({ alignContent: Alignment.Center }) {
                  // 点击扩散特效矩形
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
                    // 月份标签
                    Text(group.label)
                      .fontSize(this.fontTokens.body)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.themeTokens.colorTextPrimary)
                      .layoutWeight(1)
                    // 条数
                    Text(group.count.toString()
                      + I18nHelper.t(I18nKeys.HISTORY_MONTH_ITEMS, this.currentLanguage))
                      .fontSize(this.fontTokens.caption)
                      .fontColor(this.themeTokens.colorTextSecondary)
                      .margin({ right: 4 })
                    // 向右箭头
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
        }
        .width('100%')
        .height('100%')
        .divider({ strokeWidth: DIVIDER_STROKE_WIDTH, color: this.themeTokens.colorDivider })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        // 空状态提示
        if (this.monthGroups.length === 0) {
          Column() {
            Text(I18nHelper.t(I18nKeys.HISTORY_MONTHS_EMPTY, this.currentLanguage))
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
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }

  /** 刷新信号回调：收到任何归档变化后重新加载 */
  private onHistoryRefreshChanged(): void {
    if (this.historyNeedsRefresh) {
      AppStorage.set<boolean>(KEY_HISTORY_NEEDS_REFRESH, false);
      this.loadData();
    }
  }

  /** 加载今日统计 + 月份分组 */
  private loadData(): void {
    const todayRange = StatisticsViewModel.getTodayRange();
    StatisticsViewModel.getStats(todayRange).then((summary) => {
      this.todayArchivedCount = summary.archivedCount;
      this.todayFocusMs = summary.focusTimeMs;
    });
    StatisticsViewModel.loadMonthGroups().then((groups: MonthGroup[]) => {
      this.monthGroups = groups;
    });
  }

  /** 触发月份行的横向扩散特效 */
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

  /** 月份行左滑删除按钮 */
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
