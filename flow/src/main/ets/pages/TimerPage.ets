/**
 * TimerPage.ets
 * 多任务并行计时器页（v2）。
 *
 * v2 改进：
 *  - 进度条内嵌于条目 Stack，不再夹在条目与 Divider 之间
 *  - 支持关键词搜索与标签过滤（displayedTaskList 驱动展示，taskList 驱动计时）
 *  - Header 重构为：返回 | 标题 | 搜索图标 | 过滤图标
 *
 * 路由：从 TaskPage Header 的秒表图标通过 router.pushUrl({ url: 'pages/TimerPage' }) 进入
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_FONT_TOKENS,
  KEY_TASK_NEEDS_REFRESH,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { TaskViewModel } from '../viewmodel/TaskViewModel';
import { NotificationHelper } from '../util/NotificationHelper';
import { PreferencesHelper } from '../util/PreferencesHelper';
import {
  formatTaskDeadline,
  formatTaskInterval,
  getNextDeadline,
  getStartTime,
  parseIntervalNodes,
  parseTimeNodes,
  TaskCompletionType,
  TaskEntry,
  TaskPriority,
  TaskScheduleType,
  TaskStatus,
} from '../model/TaskEntry';
import { parseTags } from '../model/InboxEntry';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';
import { TimerSessionDatabase } from '../util/TimerSessionDatabase';

@Entry
@Component
struct TimerPage {
  @StorageLink(KEY_APP_LANGUAGE) private lang: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) private themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) private fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  /** 全量活跃任务（PENDING + IN_PROGRESS），供计时逻辑使用 */
  @State private taskList: TaskEntry[] = [];
  /** 过滤后的展示列表（受 searchKeyword 和 activeTag 驱动） */
  @State private displayedTaskList: TaskEntry[] = [];
  /** 所有标签的聚合列表，用于标签筛选 chips */
  @State private tagList: string[] = [];
  /** 当前搜索关键词 */
  @State private searchKeyword: string = '';
  /** 当前激活的标签筛选，空字符串表示全部 */
  @State private activeTag: string = '';
  /** 搜索栏是否展开 */
  @State private showSearch: boolean = false;
  /** 搜索栏动画高度（0 = 收起，48 = 展开） */
  @State private searchBarHeight: number = 0;
  /** 标签筛选区是否展开 */
  @State private showTagFilter: boolean = false;
  /** 标签筛选区动画高度（0 = 收起，40 = 展开） */
  @State private tagFilterHeight: number = 0;
  /** 已勾选的任务 ID 集合 */
  @State private checkedIds: number[] = [];
  /** 与 taskList 索引对齐的每任务会话计时毫秒 */
  @State private sessionMsArr: number[] = [];
  /** 全局总计时毫秒（页面顶部大字展示） */
  @State private globalTimerMs: number = 0;
  /** 计时器是否正在运行 */
  @State private isRunning: boolean = false;
  // ── 启停按钮扩散特效状态 ───────────────────────────────────────────────────
  @State private pressedBtnIndex: number = -1;
  @State private btnSpreadScale: number = 0;
  @State private btnSpreadOpacity: number = 0;
  @State private btnSpreadCenterX: number = 0;
  // ── 任务行扩散特效状态 ─────────────────────────────────────────────────────
  @State private pressedRowIndex: number = -1;
  @State private rowSpreadScale: number = 0;
  @State private rowSpreadOpacity: number = 0;
  @State private rowSpreadCenterX: number = 0;
  /** setInterval 返回的计时器 ID，-1 表示未运行 */
  private timerId: number = -1;
  /** 跨 loadTasks() 持久化各任务会话计时毫秒（以任务 ID 为键） */
  private sessionMsCache: Map<number, number> = new Map<number, number>();
  /** 正在自动完成流程中的任务 ID（防止同一任务多次触发） */
  private autoCompletingIds: number[] = [];
  /** 当前活跃计时分段对应的任务 ID 并行数组（与 openSessionIds 一一对应） */
  private openSessionTaskIds: number[] = [];
  /** 当前活跃计时分段的 DB session ID 并行数组（与 openSessionTaskIds 一一对应） */
  private openSessionIds: number[] = [];

  aboutToAppear(): void {
    TaskViewModel.load().then(() => {
      this.loadTasks();
    });
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    // 关闭所有活跃计时分段（页面退出兜底）
    const exitAt: number = Date.now();
    for (const sessionId of this.openSessionIds) {
      TimerSessionDatabase.closeSession(sessionId, exitAt);
    }
    this.openSessionTaskIds = [];
    this.openSessionIds = [];
    // 保存所有已计时任务的会话进度（fire-and-forget）
    const len: number = this.taskList.length < this.sessionMsArr.length
      ? this.taskList.length
      : this.sessionMsArr.length;
    for (let i = 0; i < len; i++) {
      const sessionMs: number = this.sessionMsArr[i];
      if (sessionMs > 0) {
        const task: TaskEntry = this.taskList[i];
        const totalMs: number = task.accumulatedDuration + sessionMs;
        TaskViewModel.updateProgress(task.id, totalMs, task.status, 0);
      }
    }
    AppStorage.setOrCreate(KEY_TASK_NEEDS_REFRESH, true);
  }

  build() {
    Column() {
      // ── 顶部导航栏（返回 + 标题 + 搜索 + 过滤） ──────────────────────────
      Row() {
        Image($r('sys.media.ohos_ic_back'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextPrimary)
          .padding(4)
          .margin({ right: 8 })
          .onClick(() => {
            router.back();
          })

        Text(I18nHelper.t(I18nKeys.TIMER_PAGE_TITLE, this.lang))
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

        // 标签过滤图标
        Image($r('app.media.ic_filter'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.showTagFilter ? this.themeTokens.colorAccent : this.themeTokens.colorTextSecondary)
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
          placeholder: I18nHelper.t(I18nKeys.TASK_SEARCH_PLACEHOLDER, this.lang),
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
            this.applyFilter(val.trim().toLowerCase(), this.activeTag);
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

      // ── 标签筛选区（高度动画展开/收起） ─────────────────────────────────
      Row() {
        Scroll() {
          Row({ space: $r('app.float.spacing_xs') }) {
            // 「全部」chip
            Text(I18nHelper.t(I18nKeys.TASK_TAG_ALL, this.lang))
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
                this.applyFilter(this.searchKeyword.trim().toLowerCase(), '');
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
                  this.applyFilter(this.searchKeyword.trim().toLowerCase(), newTag);
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

      // ── 计时展示区（固定布局，居中对齐） ─────────────────────────────────
      Column({ space: 20 }) {
        Text(this.formatElapsed(this.globalTimerMs))
          .fontSize(this.fontTokens.timerDigit)
          .fontWeight(FontWeight.Lighter)
          .fontColor(this.themeTokens.colorTextPrimary)
          .letterSpacing(2)

        Text(this.getSelectionHint())
          .fontSize(this.fontTokens.bodySmall)
          .fontColor(this.themeTokens.colorTextSecondary)

        // ── 启停按钮 ───────────────────────────────────────────────────────
        Stack({ alignContent: Alignment.Center }) {
          Rect()
            .width('100%')
            .height(48)
            .fill(this.themeTokens.colorAccent)
            .opacity(this.pressedBtnIndex === 0 ? this.btnSpreadOpacity : 0)
            .scale({ x: this.pressedBtnIndex === 0 ? this.btnSpreadScale : 1, y: 1.0, centerX: this.btnSpreadCenterX })
            .borderRadius(24)
            .hitTestBehavior(HitTestMode.None)

          Text(
            this.isRunning
              ? I18nHelper.t(I18nKeys.TIMER_BTN_STOP, this.lang)
              : I18nHelper.t(I18nKeys.TIMER_BTN_START, this.lang)
          )
            .fontSize(this.fontTokens.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(
              this.isBtnEnabled()
                ? this.themeTokens.colorAccent
                : this.themeTokens.colorTextSecondary
            )
            .padding({
              left: 36,
              right: 36,
              top: 12,
              bottom: 12
            })
        }
        .borderRadius(24)
        .border({
          width: 1.5,
          color: this.isBtnEnabled()
            ? this.themeTokens.colorAccent
            : this.themeTokens.colorDivider,
        })
        .clip(true)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            if (this.isBtnEnabled()) {
              this.triggerBtnSpread(event.touches[0].x);
            }
          } else if (event.type === TouchType.Up) {
            if (this.isBtnEnabled()) {
              this.toggleTimer();
            }
          }
        })
      }
      .width('100%')
      .padding({ top: 36, bottom: 36 })
      .alignItems(HorizontalAlign.Center)

      // ── 分隔线 ────────────────────────────────────────────────────────────
      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .margin({ left: 16, right: 16 })

      // ── 任务列表标签行 ────────────────────────────────────────────────────
      Row() {
        Text(I18nHelper.t(I18nKeys.TIMER_SELECT_LABEL, this.lang))
          .fontSize(this.fontTokens.label)
          .fontColor(this.themeTokens.colorTextSecondary)
          .fontWeight(FontWeight.Medium)
          .letterSpacing(0.5)
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 10,
        bottom: 10
      })

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)

      // ── 任务列表 / 空状态 ─────────────────────────────────────────────────
      if (this.taskList.length === 0) {
        // 无活跃任务
        Column() {
          Text(I18nHelper.t(I18nKeys.TIMER_NO_TASKS, this.lang))
            .fontSize(this.fontTokens.body)
            .fontColor(this.themeTokens.colorTextSecondary)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.displayedTaskList.length === 0) {
        // 有活跃任务但搜索/过滤无匹配结果
        Column() {
          Text(I18nHelper.t(I18nKeys.TIMER_NO_MATCHES, this.lang))
            .fontSize(this.fontTokens.body)
            .fontColor(this.themeTokens.colorTextSecondary)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(
            this.displayedTaskList,
            (task: TaskEntry, index: number) => {
              ListItem() {
                Column({ space: 0 }) {
                  // ── 条目 Stack（进度条内嵌，clip 限定扩散动画，左侧优先级竖条） ──
                  Stack({ alignContent: Alignment.TopStart }) {
                    // 扩散特效矩形（高度仅覆盖内容行，不延伸至进度条）
                    Rect()
                      .width('100%')
                      .height(this.fontTokens.inboxItemMinHeight)
                      .fill(this.themeTokens.colorTextPrimary)
                      .opacity(this.pressedRowIndex === index ? this.rowSpreadOpacity : 0)
                      .scale({
                        x: this.pressedRowIndex === index ? this.rowSpreadScale : 1,
                        y: 1.0,
                        centerX: this.rowSpreadCenterX,
                      })
                      .hitTestBehavior(HitTestMode.None)

                    // 内容列：主信息行 + DURATION 进度条
                    Column({ space: 0 }) {
                      Row({ space: 12 }) {
                        // 自定义 checkbox：未选为空圆，已选为填色圆 + 勾
                        if (this.isChecked(task.id)) {
                          Row() {
                            Image($r('sys.media.ohos_ic_public_ok'))
                              .width(13)
                              .height(13)
                              .fillColor(this.themeTokens.colorBackground)
                          }
                          .width(22)
                          .height(22)
                          .borderRadius(11)
                          .backgroundColor(this.themeTokens.colorAccent)
                          .justifyContent(FlexAlign.Center)
                          .alignItems(VerticalAlign.Center)
                          .flexShrink(0)
                        } else {
                          Row()
                            .width(22)
                            .height(22)
                            .borderRadius(11)
                            .border({ width: 1.5, color: this.themeTokens.colorTextSecondary })
                            .flexShrink(0)
                        }

                        // 任务信息区（双行：标题行 + 元信息行）
                        Column({ space: 4 }) {
                          // 标题行：标题文本 + 置顶/循环/多节点 chip
                          Row({ space: 6 }) {
                            Text(task.title)
                              .fontSize(this.fontTokens.body)
                              .fontColor(this.themeTokens.colorTextPrimary)
                              .fontWeight(FontWeight.Medium)
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                              .layoutWeight(1)

                            // 置顶标识 chip
                            if (task.isPinned === 1) {
                              Text(I18nHelper.t(I18nKeys.TASK_MENU_PIN, this.lang))
                                .fontSize(this.fontTokens.label)
                                .fontColor(this.themeTokens.colorAccent)
                                .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 4 })
                                .padding({
                                  left: 4,
                                  right: 4,
                                  top: 1,
                                  bottom: 1
                                })
                                .flexShrink(0)
                            }

                            // 周期性任务标识 chip
                            if (task.scheduleType === TaskScheduleType.RECURRING) {
                              Text(I18nHelper.t(I18nKeys.TASK_BADGE_RECURRING, this.lang))
                                .fontSize(this.fontTokens.label)
                                .fontColor(this.themeTokens.colorAccent)
                                .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 4 })
                                .padding({
                                  left: 4,
                                  right: 4,
                                  top: 1,
                                  bottom: 1
                                })
                                .flexShrink(0)
                            }

                            // 多节点进度 chip（节点数 > 1 时显示）
                            if ((task.scheduleType === TaskScheduleType.MULTI_NODE
                              || task.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL)
                              && this.getTotalNodes(task) > 1) {
                              Text((task.currentNodeIndex + 1).toString()
                                + '/' + this.getTotalNodes(task).toString()
                                + ' ' + I18nHelper.t(I18nKeys.TASK_BADGE_MULTI_NODE, this.lang))
                                .fontSize(this.fontTokens.label)
                                .fontColor(this.themeTokens.colorTextSecondary)
                                .border({ width: 0.5, color: this.themeTokens.colorDivider, radius: 4 })
                                .padding({
                                  left: 4,
                                  right: 4,
                                  top: 1,
                                  bottom: 1
                                })
                                .flexShrink(0)
                            }
                          }
                          .width('100%')
                          .alignItems(VerticalAlign.Center)

                          // 元信息行：标签 + 计时中标记 + 截止时间 + 实时进度（有内容时渲染）
                          if (task.tags !== ''
                            || getNextDeadline(task) > 0
                            || getStartTime(task) > 0
                            || (task.completionType === TaskCompletionType.DURATION && task.targetDuration > 0)
                            || task.status === TaskStatus.IN_PROGRESS) {
                            Row({ space: 6 }) {
                              // 标签：尽可能多显示，layoutWeight(1) 防止挤压右侧内容
                              Text(this.buildTagsDisplayText(task))
                                .fontSize(this.fontTokens.label)
                                .fontColor(this.themeTokens.colorAccent)
                                .maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .layoutWeight(1)

                              // 计时中标记（IN_PROGRESS 时显示）
                              if (task.status === TaskStatus.IN_PROGRESS) {
                                Text(I18nHelper.t(I18nKeys.TASK_STATUS_IN_PROGRESS, this.lang))
                                  .fontSize(this.fontTokens.label)
                                  .fontColor(this.themeTokens.colorAccent)
                                  .maxLines(1)
                                  .flexShrink(0)
                              }

                              // 截止/区间时间（有截止时间时显示）
                              if (getNextDeadline(task) > 0) {
                                if ((task.scheduleType === TaskScheduleType.INTERVAL
                                  || task.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL)
                                  && getStartTime(task) > 0) {
                                  Text(formatTaskInterval(getStartTime(task), getNextDeadline(task), this.lang))
                                    .fontSize(this.fontTokens.label)
                                    .fontColor(
                                      getNextDeadline(task) < Date.now()
                                        ? this.themeTokens.colorAccent
                                        : this.themeTokens.colorTextSecondary
                                    )
                                    .maxLines(1)
                                    .flexShrink(0)
                                } else {
                                  Text(formatTaskDeadline(getNextDeadline(task), this.lang))
                                    .fontSize(this.fontTokens.label)
                                    .fontColor(
                                      getNextDeadline(task) < Date.now()
                                        ? this.themeTokens.colorAccent
                                        : this.themeTokens.colorTextSecondary
                                    )
                                    .maxLines(1)
                                    .flexShrink(0)
                                }
                              }

                              // DURATION 实时进度百分比
                              if (task.completionType === TaskCompletionType.DURATION && task.targetDuration > 0) {
                                Text(this.getProgressPctById(task.id).toString() + '%')
                                  .fontSize(this.fontTokens.label)
                                  .fontColor(
                                    this.getProgressPctById(task.id) >= 100
                                      ? this.themeTokens.colorAccent
                                      : this.themeTokens.colorTextSecondary
                                  )
                                  .maxLines(1)
                                  .flexShrink(0)
                              }
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
                        left: 16,
                        right: 16,
                        top: 14,
                        bottom: 14
                      })
                      .alignItems(VerticalAlign.Center)

                      // DURATION 进度条（内嵌 Stack，明确归属当前条目）
                      if (this.isDurationTask(task)) {
                        Progress({
                          value: this.getProgressPctById(task.id),
                          total: 100,
                          type: ProgressType.Linear,
                        })
                          .width('100%')
                          .height(3)
                          .color(this.themeTokens.colorAccent)
                          .backgroundColor(this.themeTokens.colorDivider)
                      }
                    }
                    .width('100%')
                  }
                  .width('100%')
                  .clip(true)
                  .borderWidth({ left: 3 })
                  .borderColor({ left: this.getPriorityBorderColor(task.priority) })
                  .borderStyle({ left: BorderStyle.Solid })

                  Divider()
                    .strokeWidth(DIVIDER_STROKE_WIDTH)
                    .color(this.themeTokens.colorDivider)
                }
                .width('100%')
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.triggerRowSpread(index, event.touches[0].x);
                  } else if (event.type === TouchType.Up) {
                    this.toggleCheck(task.id);
                  }
                })
              }
            },
            (task: TaskEntry) => task.id.toString()
          )
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }

  /**
   * 从 TaskViewModel.allTasks 加载活跃任务，保留 sessionMsCache 的已累积时间，
   * 并更新展示列表与标签列表。
   */
  private loadTasks(): void {
    const activeTasks: TaskEntry[] = TaskViewModel.allTasks.filter(
      (t: TaskEntry) => t.status === TaskStatus.PENDING || t.status === TaskStatus.IN_PROGRESS
    );
    const newSessionMsArr: number[] = activeTasks.map(
      (t: TaskEntry) => {
        const cached: number | undefined = this.sessionMsCache.get(t.id);
        return cached !== undefined ? cached : 0;
      }
    );
    this.taskList = activeTasks;
    this.sessionMsArr = newSessionMsArr;
    this.updateDisplayedList();
    this.updateTagList();
  }

  /**
   * 启动全局计时器：每秒为所有勾选任务累加 1000ms，并检测 DURATION 任务是否达到目标。
   */
  private startTimer(): void {
    if (this.isRunning) {
      return;
    }
    this.isRunning = true;
    // 为所有已勾选任务创建计时分段
    const startAt: number = Date.now();
    for (const taskId of this.checkedIds) {
      TimerSessionDatabase.insertSession(taskId, startAt).then((sessionId: number) => {
        this.openSessionTaskIds.push(taskId);
        this.openSessionIds.push(sessionId);
      });
    }
    this.timerId = setInterval(() => {
      this.globalTimerMs += 1000;
      const newArr: number[] = [];
      for (let i = 0; i < this.taskList.length; i++) {
        const task: TaskEntry = this.taskList[i];
        const prev: number = this.sessionMsArr[i] !== undefined ? this.sessionMsArr[i] : 0;
        if (this.checkedIds.includes(task.id)) {
          const updated: number = prev + 1000;
          newArr.push(updated);
          this.sessionMsCache.set(task.id, updated);
          if (
            task.completionType === TaskCompletionType.DURATION
              && task.targetDuration > 0
              && !this.autoCompletingIds.includes(task.id)
          ) {
            const totalMs: number = task.accumulatedDuration + updated;
            if (totalMs >= task.targetDuration * 60000) {
              this.handleAutoComplete(task.id, totalMs);
            }
          }
        } else {
          newArr.push(prev);
        }
      }
      this.sessionMsArr = newArr;
    }, 1000);
  }

  /**
   * 停止全局计时器（不保存进度，不修改任务状态）。
   */
  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.isRunning = false;
    // 关闭所有活跃计时分段
    const endAt: number = Date.now();
    for (const sessionId of this.openSessionIds) {
      TimerSessionDatabase.closeSession(sessionId, endAt);
    }
    this.openSessionTaskIds = [];
    this.openSessionIds = [];
  }

  private toggleTimer(): void {
    if (this.isRunning) {
      this.stopTimer();
    } else {
      this.startTimer();
    }
  }

  /**
   * DURATION 任务达到目标时长后自动完成：发送完成通知 → 保存进度 → 标记完成 → 重载列表。
   */
  private handleAutoComplete(taskId: number, totalMs: number): void {
    this.autoCompletingIds.push(taskId);
    this.checkedIds = this.checkedIds.filter((id: number) => id !== taskId);
    this.sessionMsCache.delete(taskId);
    // 关闭该任务的计时分段
    const sessionIdx: number = this.openSessionTaskIds.indexOf(taskId);
    if (sessionIdx !== -1) {
      TimerSessionDatabase.closeSession(this.openSessionIds[sessionIdx], Date.now());
      const newTaskIds: number[] = [];
      const newSessionIds: number[] = [];
      for (let i = 0; i < this.openSessionTaskIds.length; i++) {
        if (i !== sessionIdx) {
          newTaskIds.push(this.openSessionTaskIds[i]);
          newSessionIds.push(this.openSessionIds[i]);
        }
      }
      this.openSessionTaskIds = newTaskIds;
      this.openSessionIds = newSessionIds;
    }

    // 发送任务完成通知（行为由 task.reminderType 决定，NONE 时跳过）
    let completedTask: TaskEntry | null = null;
    for (let i = 0; i < this.taskList.length; i++) {
      if (this.taskList[i].id === taskId) {
        completedTask = this.taskList[i];
        break;
      }
    }
    if (completedTask !== null) {
      NotificationHelper.publishTaskDone(completedTask, PreferencesHelper.getNotifMessage());
    }

    const completedAt: number = Date.now();
    TaskViewModel.updateProgress(taskId, totalMs, TaskStatus.COMPLETED, completedAt)
      .then(() => {
        return TaskViewModel.load();
      })
      .then(() => {
        this.loadTasks();
        const idx: number = this.autoCompletingIds.indexOf(taskId);
        if (idx !== -1) {
          this.autoCompletingIds.splice(idx, 1);
        }
      });
  }

  private toggleCheck(taskId: number): void {
    if (this.checkedIds.includes(taskId)) {
      this.checkedIds = this.checkedIds.filter((id: number) => id !== taskId);
      // 若计时器正在运行，关闭该任务的当前计时分段
      if (this.isRunning) {
        const idx: number = this.openSessionTaskIds.indexOf(taskId);
        if (idx !== -1) {
          TimerSessionDatabase.closeSession(this.openSessionIds[idx], Date.now());
          const newTaskIds: number[] = [];
          const newSessionIds: number[] = [];
          for (let i = 0; i < this.openSessionTaskIds.length; i++) {
            if (i !== idx) {
              newTaskIds.push(this.openSessionTaskIds[i]);
              newSessionIds.push(this.openSessionIds[i]);
            }
          }
          this.openSessionTaskIds = newTaskIds;
          this.openSessionIds = newSessionIds;
        }
      }
    } else {
      this.checkedIds = this.checkedIds.concat([taskId]);
      // 若计时器正在运行，为该任务插入新的计时分段
      if (this.isRunning) {
        TimerSessionDatabase.insertSession(taskId, Date.now()).then((sessionId: number) => {
          this.openSessionTaskIds.push(taskId);
          this.openSessionIds.push(sessionId);
        });
      }
    }
  }

  private isChecked(taskId: number): boolean {
    return this.checkedIds.includes(taskId);
  }

  private isDurationTask(task: TaskEntry): boolean {
    return task.completionType === TaskCompletionType.DURATION && task.targetDuration > 0;
  }

  /** 根据优先级返回左侧竖条颜色（与 TaskItemComponent 保持一致） */
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

  /** 获取任务的总节点数（多节点类型有效，其他返回 0） */
  private getTotalNodes(task: TaskEntry): number {
    if (task.scheduleType === TaskScheduleType.MULTI_NODE) {
      return parseTimeNodes(task.timeNodes).length;
    }
    if (task.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL) {
      return parseIntervalNodes(task.timeNodes).length;
    }
    return 0;
  }

  /**
   * 将标签列表格式化为可显示的字符串。
   * 根据右侧内容（计时中标记 / 截止时间 / 进度百分比）的宽度估算标签区可用字符单元数，
   * 贪心地尽可能多显示标签；若不能全部显示，末尾追加 " …" 提示还有更多标签。
   * 每个标签名超过 8 字符时截断并加 "…"。
   */
  private buildTagsDisplayText(task: TaskEntry): string {
    if (task.tags === '') {
      return '';
    }
    const allTags: string[] = parseTags(task.tags);
    const MAX_TAG_CHARS: number = 8;

    // 估算右侧所有内容合并后占用宽度单元（CJK 字符算 2 单元，其余算 1）
    let rightText: string = '';
    if (task.status === TaskStatus.IN_PROGRESS) {
      const statusStr: string = I18nHelper.t(I18nKeys.TASK_STATUS_IN_PROGRESS, this.lang);
      rightText += statusStr;
    }
    if (getNextDeadline(task) > 0) {
      const deadlineStr: string = (task.scheduleType === TaskScheduleType.INTERVAL
        || task.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL)
        && getStartTime(task) > 0
        ? formatTaskInterval(getStartTime(task), getNextDeadline(task), this.lang)
        : formatTaskDeadline(getNextDeadline(task), this.lang);
      rightText += rightText !== '' ? ' ' + deadlineStr : deadlineStr;
    }
    if (task.completionType === TaskCompletionType.DURATION && task.targetDuration > 0) {
      const pct: string = this.getProgressPctById(task.id).toString() + '%';
      rightText += rightText !== '' ? ' ' + pct : pct;
    }

    let rightUnits: number = 0;
    for (let c: number = 0; c < rightText.length; c++) {
      rightUnits += rightText.charCodeAt(c) > 255 ? 2 : 1;
    }
    // 内容列总单元约 38（对应 ~285vp 宽度、label 字体），减去右侧和间距
    const tagsUnits: number = Math.max(8, 38 - rightUnits - 1);

    const pieces: string[] = [];
    let usedUnits: number = 0;
    let truncated: boolean = false;

    for (let i: number = 0; i < allTags.length; i++) {
      const rawTag: string = allTags[i];
      const tagName: string = rawTag.length > MAX_TAG_CHARS
        ? rawTag.slice(0, MAX_TAG_CHARS) + '…'
        : rawTag;
      const piece: string = '#' + tagName;
      const sepUnits: number = pieces.length > 0 ? 1 : 0;

      let pieceUnits: number = 0;
      for (let c: number = 0; c < piece.length; c++) {
        pieceUnits += piece.charCodeAt(c) > 255 ? 2 : 1;
      }
      // 非最后一个标签时，预留 2 个单元给末尾的 " …" 指示符
      const isLastTag: boolean = i === allTags.length - 1;
      const reserve: number = isLastTag ? 0 : 2;

      if (usedUnits + sepUnits + pieceUnits > tagsUnits - reserve) {
        truncated = true;
        break;
      }
      usedUnits += sepUnits + pieceUnits;
      pieces.push(piece);
    }

    let result: string = pieces.join(' ');
    if (truncated) {
      result += pieces.length > 0 ? ' …' : '…';
    }
    return result;
  }

  /**
   * 根据任务 ID 计算完成进度百分比（0 ~ 100）。
   * 通过 ID 查找 taskList 中的索引，避免 displayedTaskList 显示索引与 taskList 索引错位。
   */
  private getProgressPctById(taskId: number): number {
    let idx: number = -1;
    for (let i = 0; i < this.taskList.length; i++) {
      if (this.taskList[i].id === taskId) {
        idx = i;
        break;
      }
    }
    if (idx < 0) {
      return 0;
    }
    const task: TaskEntry = this.taskList[idx];
    if (task.targetDuration <= 0) {
      return 0;
    }
    const sessionMs: number = this.sessionMsArr[idx] !== undefined ? this.sessionMsArr[idx] : 0;
    const totalMs: number = task.accumulatedDuration + sessionMs;
    const targetMs: number = task.targetDuration * 60000;
    const ratio: number = totalMs / targetMs;
    if (ratio >= 1.0) {
      return 100;
    }
    return Math.floor(ratio * 100);
  }

  /**
   * 应用关键词与标签过滤，更新 displayedTaskList。
   * @param kwLower 已小写化的关键词（空字符串表示不过滤）
   * @param tag     要筛选的标签（空字符串表示全部）
   */
  private applyFilter(kwLower: string, tag: string): void {
    if (kwLower === '' && tag === '') {
      this.displayedTaskList = this.taskList.slice();
      return;
    }
    const result: TaskEntry[] = [];
    for (let i = 0; i < this.taskList.length; i++) {
      const t: TaskEntry = this.taskList[i];
      let matchKw: boolean = true;
      if (kwLower !== '') {
        const inTitle: boolean = t.title.toLowerCase().includes(kwLower);
        const inContent: boolean = t.content.toLowerCase().includes(kwLower);
        // 直接在 JSON 字符串中搜索标签（避免每次反序列化）
        const inTags: boolean = t.tags.toLowerCase().includes(kwLower);
        matchKw = inTitle || inContent || inTags;
      }
      let matchTag: boolean = true;
      if (tag !== '') {
        if (t.tags === '') {
          matchTag = false;
        } else {
          try {
            const tagsArr: string[] = parseTags(t.tags);
            matchTag = tagsArr.indexOf(tag) >= 0;
          } catch {
            matchTag = false;
          }
        }
      }
      if (matchKw && matchTag) {
        result.push(t);
      }
    }
    this.displayedTaskList = result;
  }

  /** 根据当前 searchKeyword 和 activeTag 重新计算 displayedTaskList */
  private updateDisplayedList(): void {
    this.applyFilter(this.searchKeyword.trim().toLowerCase(), this.activeTag);
  }

  /** 从 allTasks 中提取所有不重复标签，更新 tagList */
  private updateTagList(): void {
    this.tagList = TaskViewModel.getAllTags();
  }

  /** 切换搜索栏展开/收起（附带 250ms EaseOut 高度动画） */
  private toggleSearch(): void {
    animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showSearch = !this.showSearch;
      this.searchBarHeight = this.showSearch ? 48 : 0;
      if (!this.showSearch) {
        // 收起时重置关键词并刷新展示列表
        this.searchKeyword = '';
        this.applyFilter('', this.activeTag);
      }
    });
  }

  /** 切换标签筛选区展开/收起（附带 250ms EaseOut 高度动画） */
  private toggleTagFilter(): void {
    animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showTagFilter = !this.showTagFilter;
      this.tagFilterHeight = this.showTagFilter ? 40 : 0;
      if (!this.showTagFilter) {
        // 收起时重置标签并刷新展示列表
        this.activeTag = '';
        this.applyFilter(this.searchKeyword.trim().toLowerCase(), '');
      }
    });
  }

  private formatElapsed(ms: number): string {
    const totalSec: number = Math.floor(ms / 1000);
    const h: number = Math.floor(totalSec / 3600);
    const m: number = Math.floor((totalSec % 3600) / 60);
    const s: number = totalSec % 60;
    return this.padTwo(h) + ':' + this.padTwo(m) + ':' + this.padTwo(s);
  }

  private padTwo(n: number): string {
    if (n < 10) {
      return '0' + n.toString();
    }
    return n.toString();
  }

  private getSelectionHint(): string {
    if (this.checkedIds.length === 0) {
      return I18nHelper.t(I18nKeys.TIMER_IDLE_HINT, this.lang);
    }
    return I18nHelper.t(I18nKeys.TIMER_SELECTED_PREFIX, this.lang)
      + ' '
      + this.checkedIds.length.toString()
      + ' '
      + I18nHelper.t(I18nKeys.TIMER_SELECTED_UNIT, this.lang);
  }

  private isBtnEnabled(): boolean {
    return this.checkedIds.length > 0 || this.isRunning;
  }

  private triggerBtnSpread(touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx) => {
        this.pressedBtnIndex = idx;
      },
      (scale, opacity) => {
        this.btnSpreadScale = scale;
        this.btnSpreadOpacity = opacity;
      },
      (x) => {
        this.btnSpreadCenterX = x;
      },
      0,
      touchX,
    );
  }

  private triggerRowSpread(rowIndex: number, touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx) => {
        this.pressedRowIndex = idx;
      },
      (scale, opacity) => {
        this.rowSpreadScale = scale;
        this.rowSpreadOpacity = opacity;
      },
      (x) => {
        this.rowSpreadCenterX = x;
      },
      rowIndex,
      touchX,
    );
  }
}

