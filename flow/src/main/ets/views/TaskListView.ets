/**
 * TaskListView.ets
 * 任务列表组件。
 *
 * 关键设计（与 InboxListView 保持一致）：
 *  - ForEach 全量渲染，key = id + '_' + updatedAt，保证数据变化时组件重建。
 *  - 给 TaskItemComponent 传基本类型 props，保证 ArkUI 强制下推刷新。
 *  - 截止时间由本组件调用 getNextDeadline 预计算后作为 prop 传入（避免在 build() 中声明变量）。
 *  - 左滑显示红色删除按钮。
 *  - 任务按动态权重排序（在 ViewModel.load() 中完成），本组件不做额外排序。
 */
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_FONT_TOKENS,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { TaskViewModel } from '../viewmodel/TaskViewModel';
import {
  getNextDeadline,
  getStartTime,
  parseIntervalNodes,
  parseTimeNodes,
  TaskEntry,
  TaskScheduleType
} from '../model/TaskEntry';
import { TaskItemComponent } from './TaskItemComponent';

/** 任务列表组件 */
@Component
export struct TaskListView {
  /** 当前要渲染的任务数组（@Link 直接绑定父组件 @State，保证动态刷新） */
  @Link tasks: TaskEntry[];
  /** 是否显示空状态提示（由父组件根据数据源长度决定） */
  @Prop showEmptyHint: boolean = false;
  /**
   * 时钟 tick（由 TaskPage 每 60s 递增传入）。
   * 透传给每条 TaskItemComponent 的 entryNowMs，触发截止时间文字重渲染。
   */
  @Prop clockTick: number = 0;
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  /** 数据变化回调：完成/删除操作完成后，通知父组件刷新 */
  onDataChanged: () => void = () => {
  };

  /** 左滑显示的红色删除按钮 */
  @Builder
  deleteButton(taskId: number): void {
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
        title: I18nHelper.t(I18nKeys.TASK_MENU_DELETE, this.currentLanguage),
        message: I18nHelper.t(I18nKeys.DIALOG_DELETE_MSG, this.currentLanguage),
        primaryButton: {
          value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.currentLanguage),
          action: () => {
            TaskViewModel.remove(taskId).then(() => {
              this.onDataChanged();
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

  build() {
    Stack({ alignContent: Alignment.Center }) {
      List() {
        ForEach(this.tasks, (task: TaskEntry, index: number) => {
          ListItem() {
            TaskItemComponent({
              entryId: task.id,
              entryTitle: task.title,
              entryTags: task.tags,
              entryStatus: task.status,
              entryPriority: task.priority,
              entryIsPinned: task.isPinned,
              entryDeadline: getNextDeadline(task),
              entryScheduleType: task.scheduleType,
              entryStartTime: getStartTime(task),
              entryUpdatedAt: task.updatedAt,
              entryIndex: index + 1,
              entryCompletionType: task.completionType,
              entryAccumulatedDuration: task.accumulatedDuration,
              entryTargetDuration: task.targetDuration,
              entryTotalNodes: this.getTotalNodes(task),
              entryCurrentNodeIndex: task.currentNodeIndex,
              entryNowMs: this.clockTick,
              onDataChanged: this.onDataChanged,
            })
          }
          .swipeAction({
            end: (): void => {
              this.deleteButton(task.id);
            },
          })
        }, (task: TaskEntry) => task.id.toString() + '_' + task.updatedAt.toString())
      }
      .width('100%')
      .height('100%')
      .divider({ strokeWidth: DIVIDER_STROKE_WIDTH, color: this.themeTokens.colorDivider })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 空状态提示（覆盖在空列表上方，不影响触摸）
      if (this.showEmptyHint) {
        Column() {
          Text(I18nHelper.t(I18nKeys.TASK_EMPTY_HINT, this.currentLanguage))
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

  /** 获取任务的总节点数（多节点/多节点区间类型有效，其他返回 0） */
  private getTotalNodes(task: TaskEntry): number {
    if (task.scheduleType === TaskScheduleType.MULTI_NODE) {
      return parseTimeNodes(task.timeNodes).length;
    }
    if (task.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL) {
      return parseIntervalNodes(task.timeNodes).length;
    }
    return 0;
  }
}
