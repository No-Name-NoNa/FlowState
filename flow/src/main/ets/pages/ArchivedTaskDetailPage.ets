/**
 * ArchivedTaskDetailPage.ets
 * 归档任务详情页。
 *
 * 路由参数：{ taskId: number }
 * 展示归档任务的完整信息：基础字段、元信息、计时分段记录。
 * 底部提供「恢复为待办」和「删除」操作，均有二次确认弹窗。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_FONT_TOKENS,
  KEY_MONTH_ARCHIVE_NEEDS_REFRESH,
  KEY_TASK_NEEDS_REFRESH,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { StatisticsViewModel } from '../viewmodel/StatisticsViewModel';
import { TimerSessionDatabase } from '../util/TimerSessionDatabase';
import { TaskDatabase } from '../util/TaskDatabase';
import {
  TaskEntry,
  TaskPriority,
  TaskCompletionType,
  TaskScheduleType,
  getNextDeadline,
} from '../model/TaskEntry';
import { TimerSessionEntry } from '../model/TimerSessionEntry';
import { parseTags } from '../model/InboxEntry';
import { HistoryRefreshSignal } from '../util/HistoryRefreshSignal';

/** 路由参数结构 */
interface ArchiveDetailRouterParams {
  taskId: number;
}

@Entry
@Component
struct ArchivedTaskDetailPage {
  @StorageLink(KEY_APP_LANGUAGE) private lang: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) private themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) private fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  /** 归档任务条目（加载后赋值） */
  @State private taskEntry: TaskEntry | null = null;
  /** 该任务的计时分段记录 */
  @State private timerSessions: TimerSessionEntry[] = [];
  /** 当前任务 ID */
  private taskId: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as ArchiveDetailRouterParams;
    this.taskId = params.taskId;
    this.loadData();
  }

  build() {
    Column() {
      // ── Header：返回 + 标题 ─────────────────────────────────────────────────
      Row() {
        Image($r('sys.media.ohos_ic_back'))
          .width(24)
          .height(24)
          .fillColor(this.themeTokens.colorTextPrimary)
          .onClick(() => {
            router.back();
          })
        Text(this.taskEntry !== null ? this.taskEntry.title : '')
          .fontSize(this.fontTokens.headerTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .margin({ left: 12 })
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 主内容区（可滚动） ──────────────────────────────────────────────────
      Scroll() {
        Column() {
          if (this.taskEntry !== null) {

            // 标签行（若有）——内容过多时可左右滑动
            if (this.taskEntry.tags !== '') {
              Scroll() {
                Row({ space: 8 }) {
                  ForEach(parseTags(this.taskEntry.tags), (tag: string) => {
                    Text('#' + tag)
                      .fontSize(this.fontTokens.label)
                      .fontColor(this.themeTokens.colorAccent)
                      .padding({
                        left: 8,
                        right: 8,
                        top: 3,
                        bottom: 3
                      })
                      .backgroundColor(this.themeTokens.colorDivider)
                      .borderRadius(10)
                  }, (tag: string) => tag)
                }
                .padding({
                  left: 20,
                  right: 20,
                  bottom: 8,
                  top: 8
                })
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.None)
              .width('100%')
            }

            // 正文备注（若有）
            if (this.taskEntry.content !== '') {
              Text(this.taskEntry.content)
                .fontSize(this.fontTokens.bodySmall)
                .fontColor(this.themeTokens.colorTextSecondary)
                .width('100%')
                .padding({
                  left: 20,
                  right: 20,
                  top: 4,
                  bottom: 12
                })
                .lineHeight(22)
            }

            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
              .width('100%')

            // ── 元信息区 ──────────────────────────────────────────────────────
            this.buildInfoRow(
              I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_CREATED_AT, this.lang),
              StatisticsViewModel.formatDateTime(this.taskEntry.createdAt)
            )
            this.buildInfoRow(
              I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_ARCHIVED_AT, this.lang),
              StatisticsViewModel.formatDateTime(this.taskEntry.updatedAt)
            )
            this.buildInfoRow(
              I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_PRIORITY, this.lang),
              this.getPriorityLabel(this.taskEntry.priority)
            )
            this.buildInfoRow(
              I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_COMPLETION_TYPE, this.lang),
              this.getCompletionTypeLabel(this.taskEntry.completionType)
            )
            if (
              this.taskEntry.scheduleType !== TaskScheduleType.NONE
                && this.getScheduleDisplay().length > 0
            ) {
              this.buildInfoRow(
                I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_SCHEDULE, this.lang),
                this.getScheduleDisplay()
              )
            }
            if (this.taskEntry.targetDuration > 0) {
              this.buildInfoRow(
                I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_TARGET_DURATION, this.lang),
                `${this.taskEntry.targetDuration} ${I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_MINUTES, this.lang)}`
              )
            }
            if (this.taskEntry.accumulatedDuration > 0) {
              this.buildInfoRow(
                I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_ACCUMULATED, this.lang),
                StatisticsViewModel.formatDuration(this.taskEntry.accumulatedDuration)
              )
            }

            // ── 计时分段记录区 ────────────────────────────────────────────────
            if (this.timerSessions.length > 0) {
              // 区块标题
              Row() {
                Text(I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_TIMER_SESSIONS, this.lang))
                  .fontSize(this.fontTokens.caption)
                  .fontColor(this.themeTokens.colorTextSecondary)
              }
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: 12,
                bottom: 10,
              })

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')

              ForEach(
                this.timerSessions,
                (session: TimerSessionEntry) => {
                  Column() {
                    Row() {
                      // 开始时间
                      Text(StatisticsViewModel.formatShortTime(session.startAt))
                        .fontSize(this.fontTokens.body)
                        .fontColor(this.themeTokens.colorTextPrimary)
                      Text(' → ')
                        .fontSize(this.fontTokens.body)
                        .fontColor(this.themeTokens.colorTextSecondary)
                      // 结束时间
                      Text(StatisticsViewModel.formatShortTime(session.endAt))
                        .fontSize(this.fontTokens.body)
                        .fontColor(this.themeTokens.colorTextPrimary)
                      Blank()
                      // 本段时长
                      Text(StatisticsViewModel.formatDuration(session.endAt - session.startAt))
                        .fontSize(this.fontTokens.caption)
                        .fontColor(this.themeTokens.colorTextSecondary)
                    }
                    .width('100%')
                    .padding({
                      left: $r('app.float.spacing_lg'),
                      right: $r('app.float.spacing_lg'),
                      top: 10,
                      bottom: 10,
                    })
                    .alignItems(VerticalAlign.Center)

                    Divider()
                      .strokeWidth(DIVIDER_STROKE_WIDTH)
                      .color(this.themeTokens.colorDivider)
                      .width('100%')
                  }
                },
                (session: TimerSessionEntry) => session.id.toString()
              )
            }

            // 底部安全间距（为底部按钮留空间）
            Column().height(80)
          }
        }
        .width('100%')
      }
      .align(Alignment.TopStart)
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      // ── 底部操作按钮 ────────────────────────────────────────────────────────
      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      Row({ space: 16 }) {
        // 恢复按钮
        Button(I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_RESTORE, this.lang))
          .fontSize(this.fontTokens.body)
          .fontColor(this.themeTokens.colorAccent)
          .backgroundColor(Color.Transparent)
          .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 8 })
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.showRestoreDialog();
          })

        // 删除按钮
        Button(I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_DELETE, this.lang))
          .fontSize(this.fontTokens.body)
          .fontColor('#E84040')
          .backgroundColor(Color.Transparent)
          .border({ width: 0.5, color: '#E84040', radius: 8 })
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.showDeleteDialog();
          })
      }
      .width('100%')
      .padding({
        left: $r('app.float.spacing_lg'),
        right: $r('app.float.spacing_lg'),
        top: 12,
        bottom: 24
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }

  private loadData(): void {
    TaskDatabase.getById(this.taskId).then((entry: TaskEntry | null) => {
      this.taskEntry = entry;
    });
    TimerSessionDatabase.queryByTaskId(this.taskId).then((sessions: TimerSessionEntry[]) => {
      this.timerSessions = sessions;
    });
  }

  /** 获取优先级的本地化标签 */
  private getPriorityLabel(priority: number): string {
    if (priority === TaskPriority.URGENT) {
      return I18nHelper.t(I18nKeys.TASK_PRIORITY_URGENT, this.lang);
    }
    if (priority === TaskPriority.HIGH) {
      return I18nHelper.t(I18nKeys.TASK_PRIORITY_HIGH, this.lang);
    }
    if (priority === TaskPriority.NORMAL) {
      return I18nHelper.t(I18nKeys.TASK_PRIORITY_NORMAL, this.lang);
    }
    return I18nHelper.t(I18nKeys.TASK_PRIORITY_LOW, this.lang);
  }

  /** 获取完成类型的本地化标签 */
  private getCompletionTypeLabel(type: number): string {
    if (type === TaskCompletionType.DURATION) {
      return I18nHelper.t(I18nKeys.TASK_COMPLETION_DURATION, this.lang);
    }
    return I18nHelper.t(I18nKeys.TASK_COMPLETION_MANUAL, this.lang);
  }

  /** 获取任务的时间安排格式化字符串（无时间安排时返回空字符串） */
  private getScheduleDisplay(): string {
    const entry: TaskEntry | null = this.taskEntry;
    if (entry === null || entry.scheduleType === TaskScheduleType.NONE) {
      return '';
    }
    const deadline: number = getNextDeadline(entry);
    if (deadline <= 0) {
      return '';
    }
    return StatisticsViewModel.formatDateTime(deadline);
  }

  /** 恢复任务确认弹窗 */
  private showRestoreDialog(): void {
    AlertDialog.show({
      title: I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_RESTORE_TITLE, this.lang),
      message: I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_RESTORE_MSG, this.lang),
      primaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
        action: () => {
          StatisticsViewModel.restoreTask(this.taskId).then(() => {
            AppStorage.setOrCreate(KEY_TASK_NEEDS_REFRESH, true);
            HistoryRefreshSignal.bump();
            AppStorage.setOrCreate(KEY_MONTH_ARCHIVE_NEEDS_REFRESH, true);
            router.back();
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
  }

  /** 删除归档任务确认弹窗 */
  private showDeleteDialog(): void {
    AlertDialog.show({
      title: I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_DELETE, this.lang),
      message: I18nHelper.t(I18nKeys.ARCHIVE_DETAIL_DELETE_MSG, this.lang),
      primaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
        action: () => {
          StatisticsViewModel.deleteArchivedTask(this.taskId).then(() => {
            HistoryRefreshSignal.bump();
            AppStorage.setOrCreate(KEY_MONTH_ARCHIVE_NEEDS_REFRESH, true);
            router.back();
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
  }

  /** 构建元信息行（标签 + 值） */
  @Builder
  private buildInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(this.fontTokens.caption)
        .fontColor(this.themeTokens.colorTextSecondary)
        .width(100)
        .flexShrink(0)
      Text(value)
        .fontSize(this.fontTokens.body)
        .fontColor(this.themeTokens.colorTextPrimary)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({
      left: $r('app.float.spacing_lg'),
      right: $r('app.float.spacing_lg'),
      top: 10,
      bottom: 10,
    })
    .alignItems(VerticalAlign.Top)

    Divider()
      .strokeWidth(DIVIDER_STROKE_WIDTH)
      .color(this.themeTokens.colorDivider)
      .width('100%')
  }
}
