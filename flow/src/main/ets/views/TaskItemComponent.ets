/**
 * TaskItemComponent.ets
 * 任务列表单条目组件。
 *
 * 关键设计（与 InboxItemComponent 保持一致）：
 *  - 所有数据字段以基本类型 @Prop 传入，保证 ArkUI 在 ForEach key 变化时强制下推刷新。
 *  - 扩散 Rect 始终挂载，用 opacity 控制可见性，避免 Stack 测量不稳定。
 *  - 左侧 3vp 优先级竖条：LOW 透明 / NORMAL 次要文本色 / HIGH 橙色 / URGENT 红色。
 *  - 置顶标识：优先级竖条不变，标题行右侧显示「置顶」文字 chip（accent 色）。
 *  - 已完成任务：标题加删除线 + 字色变次要色。
 *
 * 功能：
 *  - 标题行：序号 → 标题（完成时删除线）→「置顶」chip（仅置顶时）
 *  - 元信息行：标签列表 + 截止剩余时间（进行中时显示"计时中"）+ 进度百分比
 *  - 右侧三点菜单（编辑 / 置顶·取消置顶 / 完成·取消完成 / 归档 / 删除）
 *  - 单击主内容区跳转任务详情页
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import { KEY_APP_LANGUAGE, KEY_FONT_TOKENS, KEY_THEME_TOKENS, LANG_ZH_CN } from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { TaskViewModel } from '../viewmodel/TaskViewModel';
import {
  formatTaskDeadline,
  formatTaskInterval,
  TaskCompletionType,
  TaskPriority,
  TaskScheduleType,
  TaskStatus
} from '../model/TaskEntry';
import { parseTags } from '../model/InboxEntry';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

/** 任务列表单条目组件 */
@Component
export struct TaskItemComponent {
  // ── 基本类型 @Prop（保证 ForEach 父状态变化时强制下推刷新） ────────────────
  /** 条目主键 */
  @Prop entryId: number = 0;
  /** 任务标题 */
  @Prop entryTitle: string = '';
  /** 标签 JSON 字符串 */
  @Prop entryTags: string = '';
  /** 任务状态（TaskStatus 枚举值） */
  @Prop entryStatus: number = 0;
  /** 任务优先级（TaskPriority 枚举值） */
  @Prop entryPriority: number = 1;
  /** 是否置顶（0/1） */
  @Prop entryIsPinned: number = 0;
  /** 预计算的截止时间戳（ms），0 表示无截止时间；由父组件调用 getNextDeadline 计算后传入 */
  @Prop entryDeadline: number = 0;
  /** 任务调度类型（TaskScheduleType 枚举值），用于区分区间任务和单次任务 */
  @Prop entryScheduleType: number = 0;
  /** 区间任务的开始时间戳（ms），0 表示非区间任务或未设置 */
  @Prop entryStartTime: number = 0;
  /** 最后修改时间戳（ms），用于 ForEach key 使 ArkUI 感知数据变化 */
  @Prop entryUpdatedAt: number = 0;
  /** 列表中的显示序号（1-based） */
  @Prop entryIndex: number = 0;
  /** 完成方式（TaskCompletionType 枚举值） */
  @Prop entryCompletionType: number = 0;
  /** 已累计专注时长（毫秒） */
  @Prop entryAccumulatedDuration: number = 0;
  /** 目标专注时长（分钟），0 表示无目标 */
  @Prop entryTargetDuration: number = 0;
  /** 总节点数（MULTI_NODE / MULTI_NODE_INTERVAL 类型有效，其他传 0） */
  @Prop entryTotalNodes: number = 0;
  /** 当前活跃节点索引（MULTI_NODE / MULTI_NODE_INTERVAL 类型有效） */
  @Prop entryCurrentNodeIndex: number = 0;
  /**
   * 时钟 tick（由 TaskPage 每 60s 递增后透传）。
   * 本身不参与任何渲染逻辑，仅作为 ArkUI 重渲染触发器，
   * 确保 formatTaskDeadline / formatTaskInterval 每分钟重算一次 Date.now()。
   */
  @Prop entryNowMs: number = 0;
  @StorageLink(KEY_APP_LANGUAGE) private lang: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) private themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) private fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  // ── 条目点击横向扩散特效状态 ─────────────────────────────────────────────
  @State private spreadScale: number = 0;
  @State private spreadOpacity: number = 0;
  @State private spreadCenterX: number = 0;

  /** 数据变化回调：完成/删除操作后通知父组件刷新 */
  onDataChanged: () => void = () => {
  };

  /** 三点菜单内容 */
  @Builder
  buildItemMenu(): void {
    Menu() {
      // 编辑
      MenuItem({ content: I18nHelper.t(I18nKeys.TASK_MENU_EDIT, this.lang) })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/TaskEditorPage',
            params: { taskId: this.entryId, fromInboxId: 0 },
          });
        })

      // 置顶 / 取消置顶
      MenuItem({
        content: I18nHelper.t(
          this.entryIsPinned === 1 ? I18nKeys.TASK_MENU_UNPIN : I18nKeys.TASK_MENU_PIN,
          this.lang,
        ),
      })
        .onClick(() => {
          TaskViewModel.togglePin(this.entryId).then(() => {
            this.onDataChanged();
          });
        })

      // 完成 / 取消完成
      MenuItem({
        content: I18nHelper.t(
          this.entryStatus === TaskStatus.COMPLETED
            ? I18nKeys.TASK_MENU_UNCOMPLETE
            : I18nKeys.TASK_MENU_COMPLETE,
          this.lang,
        ),
      })
        .onClick(() => {
          if (this.entryStatus === TaskStatus.COMPLETED) {
            TaskViewModel.uncomplete(this.entryId).then(() => {
              this.onDataChanged();
            });
          } else {
            AlertDialog.show({
              title: I18nHelper.t(I18nKeys.TASK_MENU_COMPLETE, this.lang),
              message: I18nHelper.t(I18nKeys.DIALOG_COMPLETE_MSG, this.lang),
              primaryButton: {
                value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
                action: () => {
                  TaskViewModel.complete(this.entryId).then(() => {
                    this.onDataChanged();
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
        })

      // 归档
      MenuItem({ content: I18nHelper.t(I18nKeys.TASK_MENU_ARCHIVE, this.lang) })
        .onClick(() => {
          AlertDialog.show({
            title: I18nHelper.t(I18nKeys.TASK_MENU_ARCHIVE, this.lang),
            message: I18nHelper.t(I18nKeys.DIALOG_ARCHIVE_MSG, this.lang),
            primaryButton: {
              value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
              action: () => {
                TaskViewModel.archive(this.entryId).then(() => {
                  this.onDataChanged();
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

      // 删除
      MenuItem({ content: I18nHelper.t(I18nKeys.TASK_MENU_DELETE, this.lang) })
        .onClick(() => {
          AlertDialog.show({
            title: I18nHelper.t(I18nKeys.TASK_MENU_DELETE, this.lang),
            message: I18nHelper.t(I18nKeys.DIALOG_DELETE_MSG, this.lang),
            primaryButton: {
              value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
              action: () => {
                TaskViewModel.remove(this.entryId).then(() => {
                  this.onDataChanged();
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

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // ── 横向扩散特效矩形（始终挂载，用 opacity/scale 控制可见性） ────────
      Rect()
        .width('100%')
        .height(this.fontTokens.inboxItemMinHeight)
        .fill(this.themeTokens.colorTextPrimary)
        .opacity(this.spreadOpacity)
        .scale({ x: this.spreadScale, y: 1.0, centerX: this.spreadCenterX })
        .hitTestBehavior(HitTestMode.None)

      Row({ space: 10 }) {
        // ── 序号（1-based，固定宽，次要色） ────────────────────────────────
        Text(this.entryIndex.toString())
          .fontSize(this.fontTokens.body)
          .fontColor(this.themeTokens.colorTextSecondary)
          .width(26)
          .textAlign(TextAlign.Start)
          .flexShrink(0)

        // ── 主内容区（双行：标题行 + 元信息行，单击跳转任务详情页） ──────────
        Column({ space: 4 }) {
          // 标题行：标题文本 + 置顶 chip（仅置顶时显示）
          Row({ space: 6 }) {
            Text(this.entryTitle)
              .fontSize(this.fontTokens.body)
              .fontColor(
                this.entryStatus === TaskStatus.COMPLETED
                  ? this.themeTokens.colorTextSecondary
                  : this.themeTokens.colorTextPrimary
              )
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .decoration({
                type: this.entryStatus === TaskStatus.COMPLETED
                  ? TextDecorationType.LineThrough
                  : TextDecorationType.None,
                color: this.themeTokens.colorTextSecondary,
              })
              .layoutWeight(1)

            // 置顶标识 chip（不与优先级竖条冲突，显示在标题右侧）
            if (this.entryIsPinned === 1) {
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

            // 循环标识 chip（周期性任务）
            if (this.entryScheduleType === TaskScheduleType.RECURRING) {
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

            // 多节点进度 chip（多节点 / 多节点区间任务，节点数 > 1 时显示）
            if ((this.entryScheduleType === TaskScheduleType.MULTI_NODE
              || this.entryScheduleType === TaskScheduleType.MULTI_NODE_INTERVAL)
              && this.entryTotalNodes > 1) {
              Text((this.entryCurrentNodeIndex + 1).toString()
                + '/' + this.entryTotalNodes.toString()
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

          // 元信息行：标签列表 + 截止剩余时间 + 进度（仅有内容时渲染）
          if (this.entryTags !== ''
            || this.entryDeadline > 0
            || this.entryStartTime > 0
            || (this.entryCompletionType === TaskCompletionType.DURATION && this.entryTargetDuration > 0)
            || this.entryStatus === TaskStatus.IN_PROGRESS) {
            Row({ space: 6 }) {
              // 标签列表（最多显示 2 个，overflow 截断）
              if (this.entryTags !== '') {
                ForEach(parseTags(this.entryTags).slice(0, 2), (tag: string) => {
                  Text('#' + tag)
                    .fontSize(this.fontTokens.label)
                    .fontColor(this.themeTokens.colorAccent)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .constraintSize({ maxWidth: 72 })
                    .flexShrink(0)
                }, (tag: string) => tag)
              }

              // 弹性占位，将右侧信息推到最右
              Blank()

              // 计时中标签（IN_PROGRESS 时显示，与截止时间并列，互不遮盖）
              if (this.entryStatus === TaskStatus.IN_PROGRESS) {
                Text(I18nHelper.t(I18nKeys.TASK_STATUS_IN_PROGRESS, this.lang))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorAccent)
                  .maxLines(1)
                  .flexShrink(0)
              }

              // 截止剩余时间 / 区间时间范围（有截止时间时始终显示，不受 IN_PROGRESS 影响）
              if (this.entryDeadline > 0) {
                // 区间任务显示「开始 → 截止」格式（包含多节点区间）
                if ((this.entryScheduleType === TaskScheduleType.INTERVAL
                  || this.entryScheduleType === TaskScheduleType.MULTI_NODE_INTERVAL)
                  && this.entryStartTime > 0) {
                  Text(formatTaskInterval(this.entryStartTime, this.entryDeadline, this.lang))
                    .fontSize(this.fontTokens.label)
                    .fontColor(
                      this.entryDeadline < Date.now()
                        ? this.themeTokens.colorAccent
                        : this.themeTokens.colorTextSecondary
                    )
                    .maxLines(1)
                    .flexShrink(0)
                } else {
                  Text(formatTaskDeadline(this.entryDeadline, this.lang))
                    .fontSize(this.fontTokens.label)
                    .fontColor(
                      this.entryDeadline < Date.now()
                        ? this.themeTokens.colorAccent
                        : this.themeTokens.colorTextSecondary
                    )
                    .maxLines(1)
                    .flexShrink(0)
                }
              }

              // DURATION 进度百分比
              if (this.entryCompletionType === TaskCompletionType.DURATION && this.entryTargetDuration > 0) {
                Text(this.getProgressPercent().toString() + '%')
                  .fontSize(this.fontTokens.label)
                  .fontColor(
                    this.getProgressPercent() >= 100
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
        .onClick(() => {
          router.pushUrl({
            url: 'pages/TaskDetailPage',
            params: { taskId: this.entryId },
          });
        })

        // ── 三点菜单按钮 ──────────────────────────────────────────────────
        Image($r('sys.media.ohos_ic_public_more'))
          .width($r('app.float.icon_size_sm'))
          .height($r('app.float.icon_size_sm'))
          .fillColor(this.themeTokens.colorTextSecondary)
          .padding(4)
          .flexShrink(0)
          .bindMenu(this.buildItemMenu)
      }
      .width('100%')
      .constraintSize({ minHeight: this.fontTokens.inboxItemMinHeight })
      .padding({
        left: 12,
        right: 16,
        top: 14,
        bottom: 14
      })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .clip(true)
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.triggerSpread(e.touches[0].x);
      }
    })
    // 优先级竖条：LOW 透明 / NORMAL 次要文本色 / HIGH 橙色 / URGENT 红色
    .borderWidth({ left: 3 })
    .borderColor({ left: this.getPriorityBorderColor() })
    .borderStyle({ left: BorderStyle.Solid })
  }

  /** 触发横向扩散特效（Rect 始终挂载） */
  private triggerSpread(touchX: number): void {
    SpreadEffectHelper.trigger(
      (_idx: number) => {
      },
      (scale: number, opacity: number) => {
        this.spreadScale = scale;
        this.spreadOpacity = opacity;
      },
      (x: number) => {
        this.spreadCenterX = x;
      },
      0,
      touchX,
    );
  }

  /** 计算 DURATION 类型的完成进度百分比（0~100） */
  private getProgressPercent(): number {
    if (this.entryTargetDuration <= 0) {
      return 0;
    }
    const ratio: number = this.entryAccumulatedDuration / (this.entryTargetDuration * 60000);
    if (ratio >= 1.0) {
      return 100;
    }
    return Math.floor(ratio * 100);
  }

  /** 根据优先级返回左侧竖条颜色字符串 */
  private getPriorityBorderColor(): string {
    if (this.entryPriority === TaskPriority.URGENT) {
      return '#E84040';
    }
    if (this.entryPriority === TaskPriority.HIGH) {
      return '#F0A030';
    }
    if (this.entryPriority === TaskPriority.NORMAL) {
      return this.themeTokens.colorTextSecondary;
    }
    // LOW 优先级：透明（十六进制全透明）
    return '#00000000';
  }
}
