/**
 * TaskDetailPage.ets
 * 任务详情与计时器页。
 *
 * 路由参数：{ taskId: number }
 *  - 展示任务标题、正文、标签
 *  - 提供开始/暂停计时器，DURATION 类型时长达标后自动完成
 *  - 手动完成、归档操作
 *  - 页面退出时自动保存计时进度与状态，并通知任务列表刷新
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_TASK_NEEDS_REFRESH,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { TaskViewModel } from '../viewmodel/TaskViewModel';
import { TaskCompletionType, TaskEntry, TaskStatus } from '../model/TaskEntry';
import { parseTags } from '../model/InboxEntry';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';
import { NotificationHelper } from '../util/NotificationHelper';
import { PreferencesHelper } from '../util/PreferencesHelper';

/** router.getParams() 的参数结构 */
interface DetailRouterParams {
  taskId: number;
}

@Entry
@Component
struct TaskDetailPage {
  @StorageLink(KEY_APP_LANGUAGE) private lang: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) private themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  /** 当前任务条目（加载后赋值） */
  @State private taskEntry: TaskEntry | null = null;
  /** 当前会话已计时毫秒数（页面退出时累加到 accumulatedDuration） */
  @State private sessionElapsedMs: number = 0;
  /** 计时器是否正在运行 */
  @State private isTimerRunning: boolean = false;
  /** 当前任务状态（独立跟踪，退出时保存用） */
  @State private currentStatus: number = TaskStatus.PENDING;
  // ── 行点击扩散特效状态 ───────────────────────────────────────────────────────
  /** 当前正在播放扩散动效的行索引（0=计时控制行，1=完成行，2=归档行），-1 表示无动效 */
  @State private pressedRowIndex: number = -1;
  /** 扩散矩形横向缩放比 */
  @State private rowSpreadScale: number = 0;
  /** 扩散矩形透明度 */
  @State private rowSpreadOpacity: number = 0;
  /** 扩散矩形 scale 变换中心 X（vp） */
  @State private spreadCenterX: number = 0;
  /** 当前任务 ID */
  private taskId: number = 0;
  /** setInterval 返回的计时器 ID，-1 表示未运行 */
  private timerId: number = -1;

  aboutToAppear(): void {
    const params = router.getParams() as DetailRouterParams;
    this.taskId = params.taskId;
    TaskViewModel.getById(this.taskId).then((entry: TaskEntry | null) => {
      this.taskEntry = entry;
      if (entry !== null) {
        this.currentStatus = entry.status;
      }
    });
  }

  aboutToDisappear(): void {
    // 停止计时器，保存进度后通知列表页刷新（fire-and-forget）
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    const completedAt: number = this.currentStatus === TaskStatus.COMPLETED ? Date.now() : 0;
    TaskViewModel.updateProgress(this.taskId, this.totalAccumulatedMs(), this.currentStatus, completedAt)
      .then(() => {
        return TaskViewModel.load();
      })
      .then(() => {
        AppStorage.setOrCreate(KEY_TASK_NEEDS_REFRESH, true);
      });
  }

  /** 触发指定行的横向矩形扩散特效 */
  private triggerSpread(rowIndex: number, touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx) => {
        this.pressedRowIndex = idx;
      },
      (scale, opacity) => {
        this.rowSpreadScale = scale;
        this.rowSpreadOpacity = opacity;
      },
      (x) => {
        this.spreadCenterX = x;
      },
      rowIndex,
      touchX,
    );
  }

  /** 计算总累计时长（已保存 + 本次会话） */
  private totalAccumulatedMs(): number {
    const entry: TaskEntry | null = this.taskEntry;
    if (entry === null) {
      return this.sessionElapsedMs;
    }
    return entry.accumulatedDuration + this.sessionElapsedMs;
  }

  /** 判断当前任务是否为时长完成类型且目标有效 */
  private isDurationTask(): boolean {
    const entry: TaskEntry | null = this.taskEntry;
    return entry !== null
      && entry.completionType === TaskCompletionType.DURATION
      && entry.targetDuration > 0;
  }

  /** 启动计时器 */
  private startTimer(): void {
    if (this.isTimerRunning) {
      return;
    }
    this.isTimerRunning = true;
    // 进入进行中状态
    if (this.currentStatus === TaskStatus.PENDING) {
      this.currentStatus = TaskStatus.IN_PROGRESS;
    }
    this.timerId = setInterval(() => {
      this.sessionElapsedMs += 1000;
      // DURATION 类型：达到目标时长后自动完成
      const entry: TaskEntry | null = this.taskEntry;
      if (entry !== null && entry.completionType === TaskCompletionType.DURATION && entry.targetDuration > 0) {
        if (this.totalAccumulatedMs() >= entry.targetDuration * 60000) {
          this.executeComplete();
        }
      }
    }, 1000);
  }

  /** 停止计时器（不改变状态，不保存） */
  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.isTimerRunning = false;
  }

  /** 直接执行完成（DURATION 计时到达时自动调用，不弹窗） */
  private async executeComplete(): Promise<void> {
    this.stopTimer();
    this.currentStatus = TaskStatus.COMPLETED;
    // 发送即时完成通知（异步，携带 WantAgent 与归档操作按钮）
    const entry: TaskEntry | null = this.taskEntry;
    if (entry !== null) {
      await NotificationHelper.publishTaskDone(entry, PreferencesHelper.getNotifMessage());
    }
    router.back();
  }

  /** 直接执行归档 */
  private executeArchive(): void {
    this.stopTimer();
    this.currentStatus = TaskStatus.ARCHIVED;
    router.back();
  }

  /** 手动标记完成：弹出二次确认弹窗 */
  private confirmComplete(): void {
    AlertDialog.show({
      title: I18nHelper.t(I18nKeys.TASK_DETAIL_COMPLETE, this.lang),
      message: I18nHelper.t(I18nKeys.DIALOG_COMPLETE_MSG, this.lang),
      primaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
        action: () => {
          this.executeComplete();
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

  /** 手动归档：弹出二次确认弹窗 */
  private confirmArchive(): void {
    AlertDialog.show({
      title: I18nHelper.t(I18nKeys.TASK_DETAIL_ARCHIVE, this.lang),
      message: I18nHelper.t(I18nKeys.DIALOG_ARCHIVE_MSG, this.lang),
      primaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
        action: () => {
          this.executeArchive();
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

  /** 直接执行重置：停止计时并清零所有累计时长 */
  private executeReset(): void {
    this.stopTimer();
    // 清零本次会话时长（@State 变化触发 UI 刷新）
    this.sessionElapsedMs = 0;
    // 同时清零已持久化的历史累计时长；re-render 由 sessionElapsedMs 触发，届时读到新值
    const entry: TaskEntry | null = this.taskEntry;
    if (entry !== null) {
      entry.accumulatedDuration = 0;
    }
    // 恢复为待办状态
    if (this.currentStatus === TaskStatus.IN_PROGRESS) {
      this.currentStatus = TaskStatus.PENDING;
    }
  }

  /** 重置计时：弹出二次确认弹窗 */
  private confirmReset(): void {
    AlertDialog.show({
      title: I18nHelper.t(I18nKeys.TASK_DETAIL_RESET, this.lang),
      message: I18nHelper.t(I18nKeys.DIALOG_RESET_MSG, this.lang),
      primaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
        action: () => {
          this.executeReset();
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

  /** 将毫秒格式化为 HH:MM:SS */
  private formatElapsed(ms: number): string {
    const totalSec: number = Math.floor(ms / 1000);
    const h: number = Math.floor(totalSec / 3600);
    const m: number = Math.floor((totalSec % 3600) / 60);
    const s: number = totalSec % 60;
    return this.padTwo(h) + ':' + this.padTwo(m) + ':' + this.padTwo(s);
  }

  /** 数字补齐为两位字符串 */
  private padTwo(n: number): string {
    if (n < 10) {
      return '0' + n.toString();
    }
    return n.toString();
  }

  /** 计算 DURATION 类型的进度值（0 ~ 100） */
  private getDurationProgressValue(): number {
    const entry: TaskEntry | null = this.taskEntry;
    if (entry === null || entry.targetDuration <= 0) {
      return 0;
    }
    const targetMs: number = entry.targetDuration * 60000;
    const ratio: number = this.totalAccumulatedMs() / targetMs;
    if (ratio >= 1.0) {
      return 100;
    }
    return Math.floor(ratio * 100);
  }

  build() {
    Column() {
      // ── 顶部导航栏 ───────────────────────────────────────────────────────
      Row() {
        Image($r('sys.media.ohos_ic_back'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextPrimary)
          .padding(4)
          .onClick(() => {
            router.back();
          })

        Blank()

        // 跳转编辑页图标按钮
        Image($r('sys.media.ohos_ic_public_edit'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextSecondary)
          .padding(4)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/TaskEditorPage',
              params: { taskId: this.taskId, fromInboxId: 0 },
            });
          })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 12
      })
      .alignItems(VerticalAlign.Center)

      // ── 主内容（可滚动） ─────────────────────────────────────────────────
      Scroll() {
        Column({ space: 0 }) {
          if (this.taskEntry !== null) {
            // 标题
            Text(this.taskEntry.title)
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeTokens.colorTextPrimary)
              .width('100%')
              .padding({
                left: 20,
                right: 20,
                top: 8,
                bottom: 6
              })

            // 标签行（若有）
            if (this.taskEntry.tags !== '') {
              Row({ space: 8 }) {
                ForEach(parseTags(this.taskEntry.tags), (tag: string) => {
                  Text('#' + tag)
                    .fontSize($r('app.float.font_size_label'))
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
              .width('100%')
              .padding({ left: 20, right: 20, bottom: 8 })
            }

            // 正文备注（若有）
            if (this.taskEntry.content !== '') {
              Text(this.taskEntry.content)
                .fontSize(15)
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

            // ── 计时区域 ─────────────────────────────────────────────────
            Column({ space: 0 }) {
              // DURATION 类型：进度标签行 + 进度条
              if (this.isDurationTask()) {
                // 进度信息行：左侧「已专注」，右侧「XX% · 目标 Xmin」
                Row() {
                  Text(I18nHelper.t(I18nKeys.TASK_DETAIL_ELAPSED, this.lang))
                    .fontSize($r('app.float.font_size_label'))
                    .fontColor(this.themeTokens.colorTextSecondary)

                  Blank()

                  Text(
                    this.getDurationProgressValue().toString()
                      + '% · '
                      + I18nHelper.t(I18nKeys.TASK_DETAIL_TARGET, this.lang)
                      + ' '
                      + this.taskEntry.targetDuration.toString()
                      + I18nHelper.t(I18nKeys.TASK_DURATION_UNIT, this.lang)
                  )
                    .fontSize($r('app.float.font_size_label'))
                    .fontColor(
                      this.getDurationProgressValue() >= 100
                        ? this.themeTokens.colorAccent
                        : this.themeTokens.colorTextSecondary
                    )
                }
                .width('100%')
                .padding({
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 10
                })

                // 进度条（较粗，外层容器提供内边距保证 strokeWidth 渲染正确）
                Column() {
                  Progress({
                    value: this.getDurationProgressValue(),
                    total: 100,
                    type: ProgressType.Linear,
                  })
                    .width('100%')
                    .color(this.themeTokens.colorAccent)
                    .backgroundColor(this.themeTokens.colorDivider)
                    .style({ strokeWidth: 6 })
                }
                .width('100%')
                .padding({ left: 20, right: 20 })
              } else {
                // 非 DURATION 类型：仅显示「已专注」标签
                Text(I18nHelper.t(I18nKeys.TASK_DETAIL_ELAPSED, this.lang))
                  .fontSize($r('app.float.font_size_label'))
                  .fontColor(this.themeTokens.colorTextSecondary)
                  .width('100%')
                  .padding({
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: 0
                  })
              }

              // 大号计时器数字（两种类型均展示）
              Text(this.formatElapsed(this.totalAccumulatedMs()))
                .fontSize(52)
                .fontWeight(FontWeight.Lighter)
                .fontColor(
                  this.isTimerRunning
                    ? this.themeTokens.colorAccent
                    : this.themeTokens.colorTextPrimary
                )
                .letterSpacing(3)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 16, bottom: 8 })

              // 开始 / 暂停行（已完成或已归档时隐藏）
              if (
                this.currentStatus !== TaskStatus.COMPLETED &&
                  this.currentStatus !== TaskStatus.ARCHIVED
              ) {
                Stack({ alignContent: Alignment.Center }) {
                  // 扩散矩形
                  if (this.pressedRowIndex === 0) {
                    Rect()
                      .width('100%')
                      .height(64)
                      .fill(this.themeTokens.colorTextPrimary)
                      .opacity(this.rowSpreadOpacity)
                      .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
                      .hitTestBehavior(HitTestMode.None)
                  }
                  // 图标 + 文字居中排列
                  Row({ space: 10 }) {
                    Image(
                      this.isTimerRunning
                        ? $r('sys.media.ohos_ic_public_pause')
                        : $r('sys.media.ohos_ic_public_play')
                    )
                      .width(22)
                      .height(22)
                      .fillColor(this.themeTokens.colorAccent)

                    Text(I18nHelper.t(
                      this.isTimerRunning ? I18nKeys.TASK_DETAIL_PAUSE : I18nKeys.TASK_DETAIL_START,
                      this.lang,
                    ))
                      .fontSize(16)
                      .fontColor(this.themeTokens.colorAccent)
                  }
                  .width('100%')
                  .height(64)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                  .onTouch((e: TouchEvent) => {
                    if (e.type === TouchType.Down) {
                      this.triggerSpread(0, e.touches[0].x);
                    }
                  })
                  .onClick(() => {
                    if (this.isTimerRunning) {
                      this.stopTimer();
                    } else {
                      this.startTimer();
                    }
                  })
                }
                .width('100%')
              }
            }
            .width('100%')

            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)

            // ── 操作行（非归档状态时显示） ───────────────────────────────
            if (this.currentStatus !== TaskStatus.ARCHIVED) {
              // 完成 / 取消完成行
              Stack({ alignContent: Alignment.Center }) {
                if (this.pressedRowIndex === 1) {
                  Rect()
                    .width('100%')
                    .height($r('app.float.settings_item_height'))
                    .fill(this.themeTokens.colorTextPrimary)
                    .opacity(this.rowSpreadOpacity)
                    .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
                    .hitTestBehavior(HitTestMode.None)
                }
                Row() {
                  Text(I18nHelper.t(
                    this.currentStatus !== TaskStatus.COMPLETED
                      ? I18nKeys.TASK_DETAIL_COMPLETE
                      : I18nKeys.TASK_MENU_UNCOMPLETE,
                    this.lang,
                  ))
                    .fontSize(15)
                    .fontColor(
                      this.currentStatus !== TaskStatus.COMPLETED
                        ? this.themeTokens.colorAccent
                        : this.themeTokens.colorTextSecondary
                    )
                    .layoutWeight(1)

                  Image($r('sys.media.ohos_ic_public_arrow_right'))
                    .width($r('app.float.icon_size_sm'))
                    .height($r('app.float.icon_size_sm'))
                    .fillColor(this.themeTokens.colorTextSecondary)
                }
                .width('100%')
                .height($r('app.float.settings_item_height'))
                .padding({ left: 20, right: 20 })
                .alignItems(VerticalAlign.Center)
                .onTouch((e: TouchEvent) => {
                  if (e.type === TouchType.Down) {
                    this.triggerSpread(1, e.touches[0].x);
                  }
                })
                .onClick(() => {
                  if (this.currentStatus !== TaskStatus.COMPLETED) {
                    this.confirmComplete();
                  } else {
                    this.currentStatus = TaskStatus.PENDING;
                  }
                })
              }
              .width('100%')

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .margin({ left: 20, right: 20 })

              // 重置计时行（有累计时长且未完成时显示）
              if (
                this.currentStatus !== TaskStatus.COMPLETED &&
                  this.totalAccumulatedMs() > 0
              ) {
                Stack({ alignContent: Alignment.Center }) {
                  if (this.pressedRowIndex === 2) {
                    Rect()
                      .width('100%')
                      .height($r('app.float.settings_item_height'))
                      .fill(this.themeTokens.colorTextPrimary)
                      .opacity(this.rowSpreadOpacity)
                      .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
                      .hitTestBehavior(HitTestMode.None)
                  }
                  Row() {
                    Text(I18nHelper.t(I18nKeys.TASK_DETAIL_RESET, this.lang))
                      .fontSize(15)
                      .fontColor(this.themeTokens.colorTextPrimary)
                      .layoutWeight(1)

                    Image($r('sys.media.ohos_ic_public_arrow_right'))
                      .width($r('app.float.icon_size_sm'))
                      .height($r('app.float.icon_size_sm'))
                      .fillColor(this.themeTokens.colorTextSecondary)
                  }
                  .width('100%')
                  .height($r('app.float.settings_item_height'))
                  .padding({ left: 20, right: 20 })
                  .alignItems(VerticalAlign.Center)
                  .onTouch((e: TouchEvent) => {
                    if (e.type === TouchType.Down) {
                      this.triggerSpread(2, e.touches[0].x);
                    }
                  })
                  .onClick(() => {
                    this.confirmReset();
                  })
                }
                .width('100%')

                Divider()
                  .strokeWidth(DIVIDER_STROKE_WIDTH)
                  .color(this.themeTokens.colorDivider)
                  .margin({ left: 20, right: 20 })
              }

              // 归档行
              Stack({ alignContent: Alignment.Center }) {
                if (this.pressedRowIndex === 3) {
                  Rect()
                    .width('100%')
                    .height($r('app.float.settings_item_height'))
                    .fill(this.themeTokens.colorTextPrimary)
                    .opacity(this.rowSpreadOpacity)
                    .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
                    .hitTestBehavior(HitTestMode.None)
                }
                Row() {
                  Text(I18nHelper.t(I18nKeys.TASK_DETAIL_ARCHIVE, this.lang))
                    .fontSize(15)
                    .fontColor(this.themeTokens.colorTextSecondary)
                    .layoutWeight(1)

                  Image($r('sys.media.ohos_ic_public_arrow_right'))
                    .width($r('app.float.icon_size_sm'))
                    .height($r('app.float.icon_size_sm'))
                    .fillColor(this.themeTokens.colorTextSecondary)
                }
                .width('100%')
                .height($r('app.float.settings_item_height'))
                .padding({ left: 20, right: 20 })
                .alignItems(VerticalAlign.Center)
                .onTouch((e: TouchEvent) => {
                  if (e.type === TouchType.Down) {
                    this.triggerSpread(3, e.touches[0].x);
                  }
                })
                .onClick(() => {
                  this.confirmArchive();
                })
              }
              .width('100%')
              .margin({ bottom: 36 })
            }
          } else {
            // 数据加载中占位
            Text('...')
              .fontSize(16)
              .fontColor(this.themeTokens.colorTextSecondary)
              .padding({ top: 40 })
              .width('100%')
              .textAlign(TextAlign.Center)
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }
}
