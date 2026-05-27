/**
 * TaskEditorPage.ets
 * 任务创建/编辑页。
 *
 * 路由参数（EditorRouterParams）：
 *   taskId      > 0  → 编辑模式，加载已有任务
 *   fromInboxId > 0  → 从收集箱转入，预填标题/内容/标签（任务 ID 为 0，创建新任务）
 *   两者均为 0       → 空白新建
 *
 * 属性面板（可滚动）：
 *   1. 正文 TextArea
 *   2. 标签区（与 InboxEditorPage 完全相同的 chip + 输入框模式）
 *   3. 优先级 chips（低 / 普通 / 高 / 紧急）
 *   4. 截止时间行（DatePickerDialog → TimePickerDialog 链式弹出）
 *   5. 目标时长行（数字输入 + 单位文本）
 *   6. 完成方式 chips（手动 / 时长到达）
 *   7. 提醒 chips（无 / 静默 / 系统通知）
 *   8. 时间戳（仅编辑模式）
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_FONT_TOKENS,
  KEY_INBOX_NEEDS_REFRESH,
  KEY_TASK_NEEDS_REFRESH,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { InboxDatabase } from '../util/InboxDatabase';
import { InboxViewModel } from '../viewmodel/InboxViewModel';
import { TaskViewModel } from '../viewmodel/TaskViewModel';
import { formatTimestamp, parseTags, serializeTags } from '../model/InboxEntry';
import {
  TaskCompletionType,
  TaskEntry,
  TaskPriority,
  TaskReminderType,
  TaskScheduleType,
  TaskStatus,
  IntervalNode,
  RecurringType,
  RecurringRule,
  parseTimeNodes,
  serializeTimeNodes,
  parseIntervalNodes,
  serializeIntervalNodes,
  parseRecurringRule,
  serializeRecurringRule,
  parseNodeTargetDurations,
  serializeNodeTargetDurations,
} from '../model/TaskEntry';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

/** router.getParams() 的参数结构 */
interface EditorRouterParams {
  taskId: number;
  fromInboxId: number;
}

/** 用于兼容 TimePickerDialog 回调参数的本地接口 */
interface TimeResult {
  hour: number;
  minute: number;
}

/** 多节点时间戳与目标时长的配对结构（用于保存时排序） */
interface NodeWithDuration {
  ts: number;
  durStr: string;
}

/** 多节点区间与目标时长的配对结构（用于保存时排序） */
interface IntervalWithDuration {
  start: number;
  end: number;
  durStr: string;
}

@Entry
@Component
struct TaskEditorPage {
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  // ── 页面模式 ────────────────────────────────────────────────────────────
  /** 编辑模式目标任务 ID，0 表示新建 */
  @State taskId: number = 0;
  /** 是否处于编辑模式 */
  @State isEditMode: boolean = false;
  /** 从收集箱转入时的来源条目 ID（0 表示非收集箱来源），保存任务后自动删除对应收集箱条目 */
  @State fromInboxId: number = 0;
  // ── 表单字段 ────────────────────────────────────────────────────────────
  /** 任务标题 */
  @State titleText: string = '';
  /** 正文备注 */
  @State content: string = '';
  /** 当前已选标签数组 */
  @State tags: string[] = [];
  /** 标签输入框文本 */
  @State tagInput: string = '';
  /** 系统中现有标签（从 ViewModel 加载，供快速勾选） */
  @State existingTags: string[] = [];
  /** 优先级（TaskPriority 枚举值） */
  @State priority: number = TaskPriority.NORMAL;
  /** 截止时间戳（ms），0 表示无截止时间 */
  @State deadlineTs: number = 0;
  /** 目标时长（字符串，用于 TextInput 绑定；保存时 parseInt 转换为数字） */
  @State targetDurationStr: string = '';
  /** 完成方式（TaskCompletionType 枚举值） */
  @State completionType: number = TaskCompletionType.MANUAL;
  /** 提醒类型（TaskReminderType 枚举值） */
  @State reminderType: number = TaskReminderType.NONE;
  /** 任务专属通知消息文本，'' = 跟随全局 */
  @State reminderMessage: string = '';
  // ── 日期选择器临时状态 ───────────────────────────────────────────────────
  /** DatePickerDialog 完成后暂存日期部分（ms），待 TimePickerDialog 确认后合并 */
  @State pendingDateMs: number = 0;
  // ── 原始条目（编辑模式持有，保留不可编辑字段） ──────────────────────────
  @State originalEntry: TaskEntry = {
    id: 0,
    title: '',
    content: '',
    tags: '',
    priority: TaskPriority.NORMAL,
    status: TaskStatus.PENDING,
    scheduleType: TaskScheduleType.NONE,
    timeNodes: '',
    currentNodeIndex: 0,
    recurringRule: '',
    targetDuration: 0,
    accumulatedDuration: 0,
    reminderType: TaskReminderType.NONE,
    reminderOffset: 0,
    reminderSound: '',
    reminderMessage: '',
    completionType: TaskCompletionType.MANUAL,
    completedAt: 0,
    sourceInboxId: 0,
    isPinned: 0,
    sortOrder: 0,
    reminderId: 0,
    createdAt: 0,
    updatedAt: 0,
    startReminderType: 0,
    startReminderMessage: '',
    startReminderId: 0,
    nodeTargetDurations: '',
  };
  // ── 区间任务专属状态 ──────────────────────────────────────────────────────
  /** 当前任务类型选择：0 = 单次截止，TaskScheduleType.INTERVAL = 区间 */
  @State scheduleTypeSelection: number = 0;
  /** 区间任务开始时间戳（ms），0 表示未设置 */
  @State startTs: number = 0;
  /** DatePickerDialog 暂存的日期部分（用于开始时间选择器链式调用） */
  @State pendingStartDateMs: number = 0;
  /** 区间任务开始提醒类型（TaskReminderType 枚举值） */
  @State startReminderType: number = TaskReminderType.NONE;
  /** 区间任务开始提醒自定义消息，'' = 使用任务标题 */
  @State startReminderMessage: string = '';
  // ── 多节点任务状态 ────────────────────────────────────────────────────────
  /** 多节点任务的时间节点列表（MULTI_NODE 类型） */
  @State multiNodes: number[] = [];
  /** 多节点区间任务的区间节点列表（MULTI_NODE_INTERVAL 类型） */
  @State multiIntervalNodes: IntervalNode[] = [];
  /** 多节点任务各节点的目标时长输入字符串（与 multiNodes / multiIntervalNodes 索引对应） */
  @State nodeTargetDurationStrs: string[] = [];
  /** 正在编辑的节点索引（等于数组长度时表示"新增"） */
  @State pendingMultiNodeIndex: number = -1;
  /** 多节点选择器暂存的日期部分（ms） */
  @State pendingMultiDateMs: number = 0;
  /** 当前选取的是区间节点的开始（0）还是结束（1）侧 */
  @State pendingMultiIntervalSide: number = 0;
  // ── 周期性任务状态 ────────────────────────────────────────────────────────
  /** 周期性任务子类型（RecurringType 枚举值） */
  @State recurringType: number = RecurringType.DAILY;
  /** RELATIVE 类型：间隔天数字符串（TextInput 绑定） */
  @State intervalDaysStr: string = '7';
  /** WEEKLY 类型：选中的星期几列表（0=周日，1=周一，…，6=周六） */
  @State selectedWeekDays: number[] = [1];
  /** MONTHLY 类型：每月执行的日期字符串（TextInput 绑定） */
  @State dayOfMonthStr: string = '1';
  // ── 保存按钮扩散特效状态 ─────────────────────────────────────────────────
  @State savePressedIndex: number = -1;
  @State saveSpreadScale: number = 0;
  @State saveSpreadOpacity: number = 0;
  @State saveCenterX: number = 0;
  // ── 返回按钮扩散特效状态 ─────────────────────────────────────────────────
  @State backPressedIndex: number = -1;
  @State backSpreadScale: number = 0;
  @State backSpreadOpacity: number = 0;
  @State backCenterX: number = 0;

  aboutToAppear(): void {
    // 加载已有标签供快速勾选
    this.existingTags = TaskViewModel.getAllTags();

    const params = router.getParams();
    if (params === null || params === undefined) {
      return;
    }
    const p: EditorRouterParams = params as EditorRouterParams;

    if (p.taskId !== undefined && p.taskId > 0) {
      // 编辑模式
      this.taskId = p.taskId;
      this.isEditMode = true;
      TaskViewModel.getById(this.taskId).then((entry: TaskEntry | null) => {
        if (entry === null) {
          return;
        }
        this.originalEntry = entry;
        this.titleText = entry.title;
        this.content = entry.content;
        this.tags = parseTags(entry.tags);
        this.priority = entry.priority;
        // 根据调度类型加载时间字段
        if (entry.scheduleType === TaskScheduleType.INTERVAL) {
          this.scheduleTypeSelection = TaskScheduleType.INTERVAL;
          const intervalNodes: IntervalNode[] = parseIntervalNodes(entry.timeNodes);
          this.startTs = intervalNodes.length >= 1 ? intervalNodes[0].start : 0;
          this.deadlineTs = intervalNodes.length >= 1 ? intervalNodes[0].end : 0;
        } else if (entry.scheduleType === TaskScheduleType.MULTI_NODE) {
          this.scheduleTypeSelection = TaskScheduleType.MULTI_NODE;
          this.multiNodes = parseTimeNodes(entry.timeNodes);
          // 加载各节点目标时长
          const perNode: number[] = parseNodeTargetDurations(entry.nodeTargetDurations);
          const strs: string[] = [];
          for (let i: number = 0; i < this.multiNodes.length; i++) {
            strs.push(i < perNode.length && perNode[i] > 0 ? perNode[i].toString() : '');
          }
          this.nodeTargetDurationStrs = strs;
        } else if (entry.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL) {
          this.scheduleTypeSelection = TaskScheduleType.MULTI_NODE_INTERVAL;
          this.multiIntervalNodes = parseIntervalNodes(entry.timeNodes);
          // 加载各区间节点目标时长
          const perNode2: number[] = parseNodeTargetDurations(entry.nodeTargetDurations);
          const strs2: string[] = [];
          for (let i: number = 0; i < this.multiIntervalNodes.length; i++) {
            strs2.push(i < perNode2.length && perNode2[i] > 0 ? perNode2[i].toString() : '');
          }
          this.nodeTargetDurationStrs = strs2;
        } else if (entry.scheduleType === TaskScheduleType.RECURRING) {
          this.scheduleTypeSelection = TaskScheduleType.RECURRING;
          const nodes: number[] = parseTimeNodes(entry.timeNodes);
          this.deadlineTs = nodes.length > 0 ? nodes[0] : 0;
          const rule: RecurringRule | null = parseRecurringRule(entry.recurringRule);
          if (rule !== null) {
            this.recurringType = rule.type;
            this.intervalDaysStr = rule.intervalDays > 0 ? rule.intervalDays.toString() : '7';
            this.selectedWeekDays = rule.daysOfWeek.length > 0 ? rule.daysOfWeek : [1];
            this.dayOfMonthStr = rule.dayOfMonth > 0 ? rule.dayOfMonth.toString() : '1';
          }
        } else {
          this.scheduleTypeSelection = 0;
          this.deadlineTs = entry.timeNodes !== '' ? parseTimeNodes(entry.timeNodes)[0] ?? 0 : 0;
        }
        this.targetDurationStr = entry.targetDuration > 0 ? entry.targetDuration.toString() : '';
        this.completionType = entry.completionType;
        this.reminderType = entry.reminderType;
        this.reminderMessage = entry.reminderMessage;
        this.startReminderType = entry.startReminderType;
        this.startReminderMessage = entry.startReminderMessage;
      });
    } else if (p.fromInboxId !== undefined && p.fromInboxId > 0) {
      // 从收集箱转入：记录来源 ID 并预填标题/内容/标签
      this.fromInboxId = p.fromInboxId;
      InboxDatabase.getById(p.fromInboxId).then((inbox) => {
        if (inbox === null) {
          return;
        }
        this.titleText = inbox.text;
        this.content = inbox.content;
        this.tags = parseTags(inbox.tags);
      });
    }
  }

  /** 单个已添加标签的 chip（含移除按钮） */
  @Builder
  tagChip(tag: string, index: number): void {
    Row({ space: 2 }) {
      Text('#' + tag)
        .fontSize(this.fontTokens.label)
        .fontColor(this.themeTokens.colorAccent)

      Image($r('sys.media.ohos_ic_public_cancel'))
        .width(14)
        .height(14)
        .fillColor(this.themeTokens.colorTextSecondary)
        .onClick(() => {
          this.removeTag(index);
        })
    }
    .height($r('app.float.tag_chip_height'))
    .padding({ left: $r('app.float.tag_chip_padding_h'), right: $r('app.float.tag_chip_padding_h') })
    .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 11 })
    .margin({ right: $r('app.float.spacing_xs'), bottom: $r('app.float.spacing_xs') })
  }

  build() {
    Column() {
      // ── 顶部导航栏 ───────────────────────────────────────────────────────
      Row() {
        // 返回按钮（带扩散特效）
        Stack({ alignContent: Alignment.Center }) {
          if (this.backPressedIndex === 0) {
            Rect()
              .width(40)
              .height(40)
              .fill(this.themeTokens.colorTextPrimary)
              .opacity(this.backSpreadOpacity)
              .scale({ x: this.backSpreadScale, y: 1.0, centerX: this.backCenterX })
              .hitTestBehavior(HitTestMode.None)
              .borderRadius(20)
          }
          Image($r('sys.media.ohos_ic_back'))
            .width($r('app.float.icon_size_md'))
            .height($r('app.float.icon_size_md'))
            .fillColor(this.themeTokens.colorTextPrimary)
        }
        .width(40)
        .height(40)
        .onTouch((e: TouchEvent) => {
          if (e.type === TouchType.Down) {
            this.triggerBackSpread(e.touches[0].x);
          }
        })
        .onClick(() => {
          router.back();
        })

        // 标题输入框
        TextInput({
          text: this.titleText,
          placeholder: I18nHelper.t(I18nKeys.TASK_EDITOR_TITLE_PLACEHOLDER, this.currentLanguage),
        })
          .layoutWeight(1)
          .height(40)
          .fontSize(this.fontTokens.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .placeholderColor(this.themeTokens.colorTextSecondary)
          .caretColor(this.themeTokens.colorAccent)
          .backgroundColor(Color.Transparent)
          .padding({ left: $r('app.float.spacing_sm'), right: $r('app.float.spacing_sm') })
          .borderRadius(0)
          .onChange((val: string) => {
            this.titleText = val;
          })

        // 保存按钮（文字，带扩散特效）
        Stack({ alignContent: Alignment.Center }) {
          if (this.savePressedIndex === 0) {
            Rect()
              .width(56)
              .height(36)
              .fill(this.themeTokens.colorAccent)
              .opacity(this.saveSpreadOpacity)
              .scale({ x: this.saveSpreadScale, y: 1.0, centerX: this.saveCenterX })
              .hitTestBehavior(HitTestMode.None)
              .borderRadius(4)
          }
          Text(I18nHelper.t(I18nKeys.TASK_EDITOR_SAVE, this.currentLanguage))
            .fontSize(this.fontTokens.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(
              this.titleText.trim() !== ''
                ? this.themeTokens.colorAccent
                : this.themeTokens.colorTextSecondary
            )
        }
        .width(56)
        .height(36)
        .onTouch((e: TouchEvent) => {
          if (e.type === TouchType.Down) {
            this.triggerSaveSpread(e.touches[0].x);
          }
        })
        .onClick(() => {
          this.doSave();
        })
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
      .alignItems(VerticalAlign.Center)

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 可滚动属性面板 ────────────────────────────────────────────────────
      Scroll() {
        Column() {

          // ── 1. 正文备注输入区 ────────────────────────────────────────────
          TextArea({
            text: this.content,
            placeholder: I18nHelper.t(I18nKeys.TASK_EDITOR_CONTENT_PLACEHOLDER, this.currentLanguage),
          })
            .width('100%')
            .constraintSize({ minHeight: 100 })
            .fontSize(this.fontTokens.body)
            .fontColor(this.themeTokens.colorTextPrimary)
            .placeholderColor(this.themeTokens.colorTextSecondary)
            .caretColor(this.themeTokens.colorAccent)
            .backgroundColor(Color.Transparent)
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_sm'),
              bottom: $r('app.float.spacing_lg'),
            })
            .textAlign(TextAlign.Start)
            .align(Alignment.TopStart)
            .borderRadius(0)
            .onChange((val: string) => {
              this.content = val;
            })

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .width('100%')

          // ── 2. 标签区 ────────────────────────────────────────────────────
          Column({ space: 0 }) {
            // 快速勾选已有标签
            if (this.existingTags.length > 0) {
              Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
                ForEach(this.existingTags, (tag: string) => {
                  Text('#' + tag)
                    .fontSize(this.fontTokens.label)
                    .fontColor(
                      this.tags.indexOf(tag) >= 0
                        ? this.themeTokens.colorBackground
                        : this.themeTokens.colorAccent
                    )
                    .height($r('app.float.tag_chip_height'))
                    .padding({
                      left: $r('app.float.tag_chip_padding_h'),
                      right: $r('app.float.tag_chip_padding_h'),
                    })
                    .backgroundColor(
                      this.tags.indexOf(tag) >= 0 ? this.themeTokens.colorAccent : Color.Transparent
                    )
                    .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 11 })
                    .margin({ right: $r('app.float.spacing_xs'), bottom: $r('app.float.spacing_xs') })
                    .onClick(() => {
                      const idx: number = this.tags.indexOf(tag);
                      const newTags: string[] = [];
                      for (const t of this.tags) {
                        newTags.push(t);
                      }
                      if (idx >= 0) {
                        newTags.splice(idx, 1);
                      } else {
                        newTags.push(tag);
                      }
                      this.tags = newTags;
                    })
                }, (tag: string) => tag)
              }
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_sm'),
                bottom: $r('app.float.spacing_xs'),
              })

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')
            }

            // 已添加标签 chip + 内联输入框
            Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
              ForEach(this.tags, (tag: string, index: number) => {
                this.tagChip(tag, index);
              }, (tag: string) => tag)

              TextInput({
                text: this.tagInput,
                placeholder: I18nHelper.t(I18nKeys.TASK_TAG_PLACEHOLDER, this.currentLanguage),
              })
                .height($r('app.float.tag_chip_height'))
                .constraintSize({ minWidth: 80 })
                .layoutWeight(1)
                .fontSize(this.fontTokens.label)
                .fontColor(this.themeTokens.colorTextPrimary)
                .placeholderColor(this.themeTokens.colorTextSecondary)
                .caretColor(this.themeTokens.colorAccent)
                .backgroundColor(Color.Transparent)
                .padding({
                  left: $r('app.float.spacing_xs'),
                  right: 0,
                  top: 0,
                  bottom: 0
                })
                .borderRadius(0)
                .onChange((val: string) => {
                  if (val.endsWith(',') || val.endsWith('，')) {
                    this.tagInput = val.substring(0, val.length - 1);
                    this.addTag();
                  } else {
                    this.tagInput = val;
                  }
                })
                .onSubmit((_enterKey: EnterKeyType) => {
                  this.addTag();
                })
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
          }
          .width('100%')

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .width('100%')

          // ── 3. 优先级 chips ──────────────────────────────────────────────
          Row({ space: $r('app.float.spacing_sm') }) {
            Text(I18nHelper.t(I18nKeys.TASK_PRIORITY_LABEL, this.currentLanguage))
              .fontSize(this.fontTokens.body)
              .fontColor(this.themeTokens.colorTextPrimary)
              .width(80)
              .flexShrink(0)

            Scroll() {
              Row({ space: $r('app.float.spacing_xs') }) {
                ForEach(
                  [TaskPriority.LOW, TaskPriority.NORMAL, TaskPriority.HIGH, TaskPriority.URGENT],
                  (level: number) => {
                    Text(I18nHelper.t(
                      level === TaskPriority.LOW
                        ? I18nKeys.TASK_PRIORITY_LOW
                        : level === TaskPriority.NORMAL
                        ? I18nKeys.TASK_PRIORITY_NORMAL
                        : level === TaskPriority.HIGH
                          ? I18nKeys.TASK_PRIORITY_HIGH
                          : I18nKeys.TASK_PRIORITY_URGENT,
                      this.currentLanguage,
                    ))
                      .fontSize(this.fontTokens.label)
                      .fontColor(
                        this.priority === level
                          ? this.themeTokens.colorBackground
                          : this.themeTokens.colorTextSecondary
                      )
                      .height($r('app.float.tag_chip_height'))
                      .padding({
                        left: $r('app.float.tag_chip_padding_h'),
                        right: $r('app.float.tag_chip_padding_h'),
                      })
                      .backgroundColor(
                        this.priority === level ? this.themeTokens.colorAccent : Color.Transparent
                      )
                      .border({
                        width: 0.5,
                        color: this.priority === level
                          ? this.themeTokens.colorAccent
                          : this.themeTokens.colorDivider,
                        radius: 11,
                      })
                      .onClick(() => {
                        animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                          this.priority = level;
                        });
                      })
                  },
                  (level: number) => level.toString(),
                )
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .layoutWeight(1)
          }
          .width('100%')
          .padding({
            left: $r('app.float.spacing_lg'),
            right: $r('app.float.spacing_lg'),
            top: $r('app.float.spacing_md'),
            bottom: $r('app.float.spacing_md'),
          })
          .alignItems(VerticalAlign.Center)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .width('100%')

          // ── 3.5 任务类型 chips ──────────────────────────────────────────
          Row({ space: $r('app.float.spacing_sm') }) {
            Text(I18nHelper.t(I18nKeys.TASK_TYPE_LABEL, this.currentLanguage))
              .fontSize(this.fontTokens.body)
              .fontColor(this.themeTokens.colorTextPrimary)
              .width(80)
              .flexShrink(0)

            Scroll() {
              Row({ space: $r('app.float.spacing_xs') }) {
                ForEach(
                  [0, TaskScheduleType.INTERVAL, TaskScheduleType.MULTI_NODE,
                    TaskScheduleType.MULTI_NODE_INTERVAL, TaskScheduleType.RECURRING],
                  (typeVal: number) => {
                    Text(this.scheduleTypeLabel(typeVal))
                      .fontSize(this.fontTokens.label)
                      .fontColor(
                        this.scheduleTypeSelection === typeVal
                          ? this.themeTokens.colorBackground
                          : this.themeTokens.colorTextSecondary
                      )
                      .height($r('app.float.tag_chip_height'))
                      .padding({
                        left: $r('app.float.tag_chip_padding_h'),
                        right: $r('app.float.tag_chip_padding_h'),
                      })
                      .backgroundColor(
                        this.scheduleTypeSelection === typeVal
                          ? this.themeTokens.colorAccent
                          : Color.Transparent
                      )
                      .border({
                        width: 0.5,
                        color: this.scheduleTypeSelection === typeVal
                          ? this.themeTokens.colorAccent
                          : this.themeTokens.colorDivider,
                        radius: 11,
                      })
                      .onClick(() => {
                        animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                          this.scheduleTypeSelection = typeVal;
                          // 切换类型时清除不相关状态
                          if (typeVal !== TaskScheduleType.INTERVAL) {
                            this.startTs = 0;
                            this.startReminderType = TaskReminderType.NONE;
                            this.startReminderMessage = '';
                          }
                          if (typeVal !== TaskScheduleType.MULTI_NODE) {
                            this.multiNodes = [];
                          }
                          if (typeVal !== TaskScheduleType.MULTI_NODE_INTERVAL) {
                            this.multiIntervalNodes = [];
                          }
                          if (typeVal !== TaskScheduleType.RECURRING) {
                            // 切走周期性任务时不清除 deadlineTs，方便切回
                          }
                        });
                      })
                  },
                  (typeVal: number) => typeVal.toString(),
                )
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .layoutWeight(1)
          }
          .width('100%')
          .padding({
            left: $r('app.float.spacing_lg'),
            right: $r('app.float.spacing_lg'),
            top: $r('app.float.spacing_md'),
            bottom: $r('app.float.spacing_md'),
          })
          .alignItems(VerticalAlign.Center)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .width('100%')

          // ── 3.6 开始时间行（仅区间任务） ─────────────────────────────────
          if (this.scheduleTypeSelection === TaskScheduleType.INTERVAL) {
            Row() {
              Text(I18nHelper.t(I18nKeys.TASK_INTERVAL_START_LABEL, this.currentLanguage))
                .fontSize(this.fontTokens.body)
                .fontColor(this.themeTokens.colorTextPrimary)
                .width(80)
                .flexShrink(0)

              Text(this.formatStartDisplay())
                .fontSize(this.fontTokens.body)
                .fontColor(this.startTs > 0
                  ? this.themeTokens.colorAccent
                  : this.themeTokens.colorTextSecondary)
                .layoutWeight(1)
                .onClick(() => {
                  this.showStartDatePicker();
                })

              if (this.startTs > 0) {
                Text(I18nHelper.t(I18nKeys.TASK_SCHEDULE_CLEAR, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
                  .padding({ left: $r('app.float.spacing_sm') })
                  .flexShrink(0)
                  .onClick(() => {
                    animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                      this.startTs = 0;
                    });
                  })
              }
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
            .alignItems(VerticalAlign.Center)

            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
              .width('100%')
          }

          // ── 3.7 多节点编辑器（仅多节点任务） ─────────────────────────────
          if (this.scheduleTypeSelection === TaskScheduleType.MULTI_NODE) {
            ForEach(this.multiNodes, (ts: number, index: number) => {
              Row() {
                Text(I18nHelper.t(I18nKeys.TASK_MULTINODE_NODE_LABEL, this.currentLanguage)
                  + ' ' + (index + 1).toString())
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .width(80)
                  .flexShrink(0)

                Text(this.formatNodeTs(ts))
                  .fontSize(this.fontTokens.body)
                  .fontColor(ts > 0
                    ? this.themeTokens.colorAccent
                    : this.themeTokens.colorTextSecondary)
                  .width(130)
                  .flexShrink(0)
                  .onClick(() => {
                    this.showMultiNodeDatePicker(index);
                  })

                // 节点目标时长输入框
                TextInput({
                  text: index < this.nodeTargetDurationStrs.length
                    ? this.nodeTargetDurationStrs[index] : '',
                  placeholder: I18nHelper.t(I18nKeys.TASK_DURATION_UNIT, this.currentLanguage),
                })
                  .layoutWeight(1)
                  .height(32)
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .placeholderColor(this.themeTokens.colorTextSecondary)
                  .caretColor(this.themeTokens.colorAccent)
                  .backgroundColor(Color.Transparent)
                  .inputFilter('[0-9]')
                  .type(InputType.Number)
                  .padding({ left: $r('app.float.spacing_xs'), right: $r('app.float.spacing_xs') })
                  .borderRadius(0)
                  .onChange((val: string) => {
                    this.updateNodeDuration(index, val);
                  })

                Text(I18nHelper.t(I18nKeys.TASK_DURATION_UNIT, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
                  .flexShrink(0)
                  .margin({ right: $r('app.float.spacing_xs') })

                Image($r('sys.media.ohos_ic_public_cancel'))
                  .width(18)
                  .height(18)
                  .fillColor(this.themeTokens.colorTextSecondary)
                  .flexShrink(0)
                  .onClick(() => {
                    animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                      this.removeMultiNode(index);
                    });
                  })
              }
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_md'),
                bottom: $r('app.float.spacing_md'),
              })
              .alignItems(VerticalAlign.Center)

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')
            }, (ts: number, index: number) => index.toString() + '_' + ts.toString())

            // 添加节点按钮
            Row() {
              Text(I18nHelper.t(I18nKeys.TASK_MULTINODE_ADD, this.currentLanguage))
                .fontSize(this.fontTokens.body)
                .fontColor(this.themeTokens.colorAccent)
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
            .onClick(() => {
              this.showMultiNodeDatePicker(this.multiNodes.length);
            })

            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
              .width('100%')
          }

          // ── 3.8 多节点区间编辑器（仅多节点区间任务） ───────────────────
          if (this.scheduleTypeSelection === TaskScheduleType.MULTI_NODE_INTERVAL) {
            ForEach(this.multiIntervalNodes, (node: IntervalNode, index: number) => {
              Column({ space: 0 }) {
                // 开始时间行
                Row() {
                  Text(I18nHelper.t(I18nKeys.TASK_MULTINODE_NODE_LABEL, this.currentLanguage)
                    + ' ' + (index + 1).toString() + ' '
                    + I18nHelper.t(I18nKeys.TASK_INTERVAL_START_LABEL, this.currentLanguage))
                    .fontSize(this.fontTokens.body)
                    .fontColor(this.themeTokens.colorTextPrimary)
                    .width(120)
                    .flexShrink(0)

                  Text(this.formatNodeTs(node.start))
                    .fontSize(this.fontTokens.body)
                    .fontColor(node.start > 0
                      ? this.themeTokens.colorAccent
                      : this.themeTokens.colorTextSecondary)
                    .layoutWeight(1)
                    .onClick(() => {
                      this.showMultiIntervalStartDatePicker(index);
                    })
                }
                .width('100%')
                .padding({
                  left: $r('app.float.spacing_lg'),
                  right: $r('app.float.spacing_lg'),
                  top: $r('app.float.spacing_md'),
                  bottom: $r('app.float.spacing_sm'),
                })
                .alignItems(VerticalAlign.Center)

                // 结束时间行
                Row() {
                  Text(I18nHelper.t(I18nKeys.TASK_MULTINODE_NODE_LABEL, this.currentLanguage)
                    + ' ' + (index + 1).toString() + ' '
                    + I18nHelper.t(I18nKeys.TASK_SCHEDULE_LABEL, this.currentLanguage))
                    .fontSize(this.fontTokens.body)
                    .fontColor(this.themeTokens.colorTextPrimary)
                    .width(120)
                    .flexShrink(0)

                  Text(this.formatNodeTs(node.end))
                    .fontSize(this.fontTokens.body)
                    .fontColor(node.end > 0
                      ? this.themeTokens.colorAccent
                      : this.themeTokens.colorTextSecondary)
                    .layoutWeight(1)
                    .onClick(() => {
                      this.showMultiIntervalEndDatePicker(index);
                    })

                  Image($r('sys.media.ohos_ic_public_cancel'))
                    .width(18)
                    .height(18)
                    .fillColor(this.themeTokens.colorTextSecondary)
                    .flexShrink(0)
                    .onClick(() => {
                      animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                        this.removeMultiInterval(index);
                      });
                    })
                }
                .width('100%')
                .padding({
                  left: $r('app.float.spacing_lg'),
                  right: $r('app.float.spacing_lg'),
                  top: $r('app.float.spacing_sm'),
                  bottom: $r('app.float.spacing_sm'),
                })
                .alignItems(VerticalAlign.Center)

                // 节点目标时长行
                Row() {
                  Text(I18nHelper.t(I18nKeys.TASK_DURATION_LABEL, this.currentLanguage))
                    .fontSize(this.fontTokens.body)
                    .fontColor(this.themeTokens.colorTextPrimary)
                    .width(120)
                    .flexShrink(0)

                  TextInput({
                    text: index < this.nodeTargetDurationStrs.length
                      ? this.nodeTargetDurationStrs[index] : '',
                    placeholder: '0',
                  })
                    .layoutWeight(1)
                    .height(32)
                    .fontSize(this.fontTokens.label)
                    .fontColor(this.themeTokens.colorTextPrimary)
                    .placeholderColor(this.themeTokens.colorTextSecondary)
                    .caretColor(this.themeTokens.colorAccent)
                    .backgroundColor(Color.Transparent)
                    .inputFilter('[0-9]')
                    .type(InputType.Number)
                    .padding({ left: $r('app.float.spacing_xs'), right: $r('app.float.spacing_xs') })
                    .borderRadius(0)
                    .onChange((val: string) => {
                      this.updateNodeDuration(index, val);
                    })

                  Text(I18nHelper.t(I18nKeys.TASK_DURATION_UNIT, this.currentLanguage))
                    .fontSize(this.fontTokens.label)
                    .fontColor(this.themeTokens.colorTextSecondary)
                    .flexShrink(0)
                }
                .width('100%')
                .padding({
                  left: $r('app.float.spacing_lg'),
                  right: $r('app.float.spacing_lg'),
                  top: $r('app.float.spacing_sm'),
                  bottom: $r('app.float.spacing_md'),
                })
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')
            }, (node: IntervalNode, index: number) => index.toString() + '_' + node.start.toString())

            // 添加区间节点按钮
            Row() {
              Text(I18nHelper.t(I18nKeys.TASK_MULTINODE_ADD_INTERVAL, this.currentLanguage))
                .fontSize(this.fontTokens.body)
                .fontColor(this.themeTokens.colorAccent)
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
            .onClick(() => {
              this.showMultiIntervalStartDatePicker(this.multiIntervalNodes.length);
            })

            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
              .width('100%')
          }

          // ── 3.9 周期规则编辑器（仅周期性任务） ───────────────────────────
          if (this.scheduleTypeSelection === TaskScheduleType.RECURRING) {
            // 周期子类型 chips
            Row({ space: $r('app.float.spacing_sm') }) {
              Text(I18nHelper.t(I18nKeys.TASK_RECURRING_RULE_LABEL, this.currentLanguage))
                .fontSize(this.fontTokens.body)
                .fontColor(this.themeTokens.colorTextPrimary)
                .width(80)
                .flexShrink(0)

              Row({ space: $r('app.float.spacing_xs') }) {
                ForEach(
                  [RecurringType.RELATIVE, RecurringType.DAILY,
                    RecurringType.WEEKLY, RecurringType.MONTHLY],
                  (rt: number) => {
                    Text(I18nHelper.t(
                      rt === RecurringType.RELATIVE ? I18nKeys.TASK_RECURRING_RELATIVE
                        : rt === RecurringType.DAILY ? I18nKeys.TASK_RECURRING_DAILY
                        : rt === RecurringType.WEEKLY ? I18nKeys.TASK_RECURRING_WEEKLY
                          : I18nKeys.TASK_RECURRING_MONTHLY,
                      this.currentLanguage,
                    ))
                      .fontSize(this.fontTokens.label)
                      .fontColor(
                        this.recurringType === rt
                          ? this.themeTokens.colorBackground
                          : this.themeTokens.colorTextSecondary
                      )
                      .height($r('app.float.tag_chip_height'))
                      .padding({
                        left: $r('app.float.tag_chip_padding_h'),
                        right: $r('app.float.tag_chip_padding_h'),
                      })
                      .backgroundColor(
                        this.recurringType === rt
                          ? this.themeTokens.colorAccent
                          : Color.Transparent
                      )
                      .border({
                        width: 0.5,
                        color: this.recurringType === rt
                          ? this.themeTokens.colorAccent
                          : this.themeTokens.colorDivider,
                        radius: 11,
                      })
                      .onClick(() => {
                        animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                          this.recurringType = rt;
                        });
                      })
                  },
                  (rt: number) => rt.toString(),
                )
              }
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
            .alignItems(VerticalAlign.Center)

            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
              .width('100%')

            // RELATIVE：间隔天数输入
            if (this.recurringType === RecurringType.RELATIVE) {
              Row() {
                Text(I18nHelper.t(I18nKeys.TASK_RECURRING_INTERVAL_DAYS_LABEL, this.currentLanguage))
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .width(80)
                  .flexShrink(0)

                TextInput({
                  text: this.intervalDaysStr,
                  placeholder: '7',
                })
                  .layoutWeight(1)
                  .height(36)
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .placeholderColor(this.themeTokens.colorTextSecondary)
                  .caretColor(this.themeTokens.colorAccent)
                  .backgroundColor(Color.Transparent)
                  .inputFilter('[0-9]')
                  .type(InputType.Number)
                  .padding({ left: $r('app.float.spacing_sm'), right: $r('app.float.spacing_sm') })
                  .borderRadius(0)
                  .onChange((val: string) => {
                    this.intervalDaysStr = val;
                  })

                Text(I18nHelper.t(I18nKeys.TASK_RECURRING_INTERVAL_DAYS_UNIT, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
                  .flexShrink(0)
              }
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_md'),
                bottom: $r('app.float.spacing_md'),
              })
              .alignItems(VerticalAlign.Center)

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')
            }

            // WEEKLY：星期几多选 chips
            if (this.recurringType === RecurringType.WEEKLY) {
              Row({ space: $r('app.float.spacing_sm') }) {
                Text('')
                  .width(80)
                  .flexShrink(0)

                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(
                    [1, 2, 3, 4, 5, 6, 0],
                    (day: number) => {
                      Text(this.weekdayLabel(day, this.currentLanguage))
                        .fontSize(this.fontTokens.label)
                        .fontColor(
                          this.isWeekDaySelected(day)
                            ? this.themeTokens.colorBackground
                            : this.themeTokens.colorTextSecondary
                        )
                        .height($r('app.float.tag_chip_height'))
                        .padding({
                          left: $r('app.float.tag_chip_padding_h'),
                          right: $r('app.float.tag_chip_padding_h'),
                        })
                        .backgroundColor(
                          this.isWeekDaySelected(day)
                            ? this.themeTokens.colorAccent
                            : Color.Transparent
                        )
                        .border({
                          width: 0.5,
                          color: this.isWeekDaySelected(day)
                            ? this.themeTokens.colorAccent
                            : this.themeTokens.colorDivider,
                          radius: 11,
                        })
                        .margin({ right: $r('app.float.spacing_xs'), bottom: $r('app.float.spacing_xs') })
                        .onClick(() => {
                          this.toggleWeekDay(day);
                        })
                    },
                    (day: number) => day.toString(),
                  )
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_md'),
                bottom: $r('app.float.spacing_md'),
              })
              .alignItems(VerticalAlign.Top)

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')
            }

            // MONTHLY：每月第几天输入
            if (this.recurringType === RecurringType.MONTHLY) {
              Row() {
                Text(I18nHelper.t(I18nKeys.TASK_RECURRING_DAY_OF_MONTH_LABEL, this.currentLanguage))
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .width(80)
                  .flexShrink(0)

                TextInput({
                  text: this.dayOfMonthStr,
                  placeholder: '1',
                })
                  .layoutWeight(1)
                  .height(36)
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .placeholderColor(this.themeTokens.colorTextSecondary)
                  .caretColor(this.themeTokens.colorAccent)
                  .backgroundColor(Color.Transparent)
                  .inputFilter('[0-9]')
                  .type(InputType.Number)
                  .padding({ left: $r('app.float.spacing_sm'), right: $r('app.float.spacing_sm') })
                  .borderRadius(0)
                  .onChange((val: string) => {
                    this.dayOfMonthStr = val;
                  })

                Text(I18nHelper.t(I18nKeys.TASK_RECURRING_DAY_OF_MONTH_UNIT, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
                  .flexShrink(0)
              }
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_md'),
                bottom: $r('app.float.spacing_md'),
              })
              .alignItems(VerticalAlign.Center)

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')
            }
          }

          // ── 4. 截止时间行（单次/区间/周期显示；多节点类型隐藏） ──────────
          if (this.scheduleTypeSelection !== TaskScheduleType.MULTI_NODE
            && this.scheduleTypeSelection !== TaskScheduleType.MULTI_NODE_INTERVAL) {
            Row() {
              Text(
                this.scheduleTypeSelection === TaskScheduleType.RECURRING
                  ? I18nHelper.t(I18nKeys.TASK_RECURRING_TRIGGER_LABEL, this.currentLanguage)
                  : I18nHelper.t(I18nKeys.TASK_SCHEDULE_LABEL, this.currentLanguage)
              )
                .fontSize(this.fontTokens.body)
                .fontColor(this.themeTokens.colorTextPrimary)
                .width(80)
                .flexShrink(0)

              // 当前截止时间显示（点击跳出日期选择器）
              Text(this.formatDeadlineDisplay())
                .fontSize(this.fontTokens.body)
                .fontColor(this.deadlineTs > 0
                  ? this.themeTokens.colorAccent
                  : this.themeTokens.colorTextSecondary)
                .layoutWeight(1)
                .onClick(() => {
                  this.showDatePicker();
                })

              // 清除截止时间按钮（仅截止时间已设置时显示）
              if (this.deadlineTs > 0) {
                Text(I18nHelper.t(I18nKeys.TASK_SCHEDULE_CLEAR, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
                  .padding({ left: $r('app.float.spacing_sm') })
                  .flexShrink(0)
                  .onClick(() => {
                    animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                      this.deadlineTs = 0;
                    });
                  })
              }
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
            .alignItems(VerticalAlign.Center)

            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
              .width('100%')
          }

          // ── 5. 目标时长行（多节点/多区间任务使用每节点时长，隐藏此行）──────
          if (this.scheduleTypeSelection !== TaskScheduleType.MULTI_NODE
            && this.scheduleTypeSelection !== TaskScheduleType.MULTI_NODE_INTERVAL) {
            Row() {
              Text(I18nHelper.t(I18nKeys.TASK_DURATION_LABEL, this.currentLanguage))
                .fontSize(this.fontTokens.body)
                .fontColor(this.themeTokens.colorTextPrimary)
                .width(80)
                .flexShrink(0)

              TextInput({
                text: this.targetDurationStr,
                placeholder: '0',
              })
                .layoutWeight(1)
                .height(36)
                .fontSize(this.fontTokens.body)
                .fontColor(this.themeTokens.colorTextPrimary)
                .placeholderColor(this.themeTokens.colorTextSecondary)
                .caretColor(this.themeTokens.colorAccent)
                .backgroundColor(Color.Transparent)
                .inputFilter('[0-9]')
                .type(InputType.Number)
                .padding({ left: $r('app.float.spacing_sm'), right: $r('app.float.spacing_sm') })
                .borderRadius(0)
                .onChange((val: string) => {
                  this.targetDurationStr = val;
                  // 用户填入时长后，若不是多节点类型，自动切换为「时长到达」完成方式
                  const d: number = parseInt(val.trim(), 10);
                  if (!isNaN(d) && d > 0
                    && this.scheduleTypeSelection !== TaskScheduleType.MULTI_NODE
                    && this.scheduleTypeSelection !== TaskScheduleType.MULTI_NODE_INTERVAL) {
                    this.completionType = TaskCompletionType.DURATION;
                  }
                })

              Text(I18nHelper.t(I18nKeys.TASK_DURATION_UNIT, this.currentLanguage))
                .fontSize(this.fontTokens.label)
                .fontColor(this.themeTokens.colorTextSecondary)
                .flexShrink(0)
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
            .alignItems(VerticalAlign.Center)

            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
              .width('100%')
          } // if not multi-node

          // ── 6. 完成方式 chips ────────────────────────────────────────────
          Row({ space: $r('app.float.spacing_sm') }) {
            Text(I18nHelper.t(I18nKeys.TASK_COMPLETION_LABEL, this.currentLanguage))
              .fontSize(this.fontTokens.body)
              .fontColor(this.themeTokens.colorTextPrimary)
              .width(80)
              .flexShrink(0)

            Row({ space: $r('app.float.spacing_xs') }) {
              ForEach(
                [TaskCompletionType.MANUAL, TaskCompletionType.DURATION],
                (type: number) => {
                  Text(I18nHelper.t(
                    type === TaskCompletionType.MANUAL
                      ? I18nKeys.TASK_COMPLETION_MANUAL
                      : I18nKeys.TASK_COMPLETION_DURATION,
                    this.currentLanguage,
                  ))
                    .fontSize(this.fontTokens.label)
                    .fontColor(
                      this.completionType === type
                        ? this.themeTokens.colorBackground
                        : this.themeTokens.colorTextSecondary
                    )
                    .height($r('app.float.tag_chip_height'))
                    .padding({
                      left: $r('app.float.tag_chip_padding_h'),
                      right: $r('app.float.tag_chip_padding_h'),
                    })
                    .backgroundColor(
                      this.completionType === type ? this.themeTokens.colorAccent : Color.Transparent
                    )
                    .border({
                      width: 0.5,
                      color: this.completionType === type
                        ? this.themeTokens.colorAccent
                        : this.themeTokens.colorDivider,
                      radius: 11,
                    })
                    .onClick(() => {
                      animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                        this.completionType = type;
                      });
                    })
                },
                (type: number) => type.toString(),
              )
            }
          }
          .width('100%')
          .padding({
            left: $r('app.float.spacing_lg'),
            right: $r('app.float.spacing_lg'),
            top: $r('app.float.spacing_md'),
            bottom: $r('app.float.spacing_md'),
          })
          .alignItems(VerticalAlign.Center)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .width('100%')

          // ── 7. 提醒 ─────────────────────────────────────────────────────
          if (this.scheduleTypeSelection === TaskScheduleType.INTERVAL
            || this.scheduleTypeSelection === TaskScheduleType.MULTI_NODE_INTERVAL) {
            // ── 区间/多节点区间任务：开始提醒 + 截止提醒分块 ──────────────
            // 开始提醒 chips
            Row({ space: $r('app.float.spacing_sm') }) {
              Text(I18nHelper.t(I18nKeys.TASK_START_REMINDER_LABEL, this.currentLanguage))
                .fontSize(this.fontTokens.body)
                .fontColor(this.themeTokens.colorTextPrimary)
                .width(80)
                .flexShrink(0)

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(
                  [TaskReminderType.NONE, TaskReminderType.POPUP, TaskReminderType.SOUND],
                  (type: number) => {
                    Text(I18nHelper.t(
                      type === TaskReminderType.NONE
                        ? I18nKeys.TASK_REMINDER_NONE
                        : type === TaskReminderType.POPUP
                        ? I18nKeys.TASK_REMINDER_POPUP
                        : I18nKeys.TASK_REMINDER_SOUND,
                      this.currentLanguage,
                    ))
                      .fontSize(this.fontTokens.label)
                      .fontColor(
                        this.startReminderType === type
                          ? this.themeTokens.colorBackground
                          : this.themeTokens.colorTextSecondary
                      )
                      .height($r('app.float.tag_chip_height'))
                      .padding({
                        left: $r('app.float.tag_chip_padding_h'),
                        right: $r('app.float.tag_chip_padding_h'),
                      })
                      .margin({ right: $r('app.float.spacing_xs') })
                      .backgroundColor(
                        this.startReminderType === type ? this.themeTokens.colorAccent : Color.Transparent
                      )
                      .border({
                        width: 0.5,
                        color: this.startReminderType === type
                          ? this.themeTokens.colorAccent
                          : this.themeTokens.colorDivider,
                        radius: 11,
                      })
                      .onClick(() => {
                        animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                          this.startReminderType = type;
                        });
                      })
                  },
                  (type: number) => 'sr_' + type.toString(),
                )
              }
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
            .alignItems(VerticalAlign.Center)

            // 开始提醒自定义消息
            if (this.startReminderType !== TaskReminderType.NONE) {
              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')

              Row({ space: $r('app.float.spacing_sm') }) {
                Text(I18nHelper.t(I18nKeys.TASK_REMINDER_MESSAGE_LABEL, this.currentLanguage))
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .width(80)
                  .flexShrink(0)

                TextInput({
                  placeholder: I18nHelper.t(I18nKeys.TASK_REMINDER_MESSAGE_PLACEHOLDER, this.currentLanguage),
                  text: this.startReminderMessage,
                })
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .placeholderColor(this.themeTokens.colorTextSecondary)
                  .backgroundColor(Color.Transparent)
                  .borderWidth(0)
                  .layoutWeight(1)
                  .onChange((value: string) => {
                    this.startReminderMessage = value;
                  })
              }
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_md'),
                bottom: $r('app.float.spacing_md'),
              })
              .alignItems(VerticalAlign.Center)
            }

            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
              .width('100%')

            // 截止提醒 chips
            Row({ space: $r('app.float.spacing_sm') }) {
              Text(I18nHelper.t(I18nKeys.TASK_END_REMINDER_LABEL, this.currentLanguage))
                .fontSize(this.fontTokens.body)
                .fontColor(this.themeTokens.colorTextPrimary)
                .width(80)
                .flexShrink(0)

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(
                  [TaskReminderType.NONE, TaskReminderType.POPUP, TaskReminderType.SOUND],
                  (type: number) => {
                    Text(I18nHelper.t(
                      type === TaskReminderType.NONE
                        ? I18nKeys.TASK_REMINDER_NONE
                        : type === TaskReminderType.POPUP
                        ? I18nKeys.TASK_REMINDER_POPUP
                        : I18nKeys.TASK_REMINDER_SOUND,
                      this.currentLanguage,
                    ))
                      .fontSize(this.fontTokens.label)
                      .fontColor(
                        this.reminderType === type
                          ? this.themeTokens.colorBackground
                          : this.themeTokens.colorTextSecondary
                      )
                      .height($r('app.float.tag_chip_height'))
                      .padding({
                        left: $r('app.float.tag_chip_padding_h'),
                        right: $r('app.float.tag_chip_padding_h'),
                      })
                      .margin({ right: $r('app.float.spacing_xs') })
                      .backgroundColor(
                        this.reminderType === type ? this.themeTokens.colorAccent : Color.Transparent
                      )
                      .border({
                        width: 0.5,
                        color: this.reminderType === type
                          ? this.themeTokens.colorAccent
                          : this.themeTokens.colorDivider,
                        radius: 11,
                      })
                      .onClick(() => {
                        animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                          this.reminderType = type;
                        });
                      })
                  },
                  (type: number) => 'er_' + type.toString(),
                )
              }
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
            .alignItems(VerticalAlign.Center)

            // 截止提醒自定义消息
            if (this.reminderType !== TaskReminderType.NONE) {
              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')

              Row({ space: $r('app.float.spacing_sm') }) {
                Text(I18nHelper.t(I18nKeys.TASK_REMINDER_MESSAGE_LABEL, this.currentLanguage))
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .width(80)
                  .flexShrink(0)

                TextInput({
                  placeholder: I18nHelper.t(I18nKeys.TASK_REMINDER_MESSAGE_PLACEHOLDER, this.currentLanguage),
                  text: this.reminderMessage,
                })
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .placeholderColor(this.themeTokens.colorTextSecondary)
                  .backgroundColor(Color.Transparent)
                  .borderWidth(0)
                  .layoutWeight(1)
                  .onChange((value: string) => {
                    this.reminderMessage = value;
                  })
              }
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_md'),
                bottom: $r('app.float.spacing_md'),
              })
              .alignItems(VerticalAlign.Center)
            }
          } else {
            // ── 单次任务：单块提醒 ──────────────────────────────────────────
            // 提醒类型 chips（4 种）
            Row({ space: $r('app.float.spacing_sm') }) {
              Text(I18nHelper.t(I18nKeys.TASK_REMINDER_LABEL, this.currentLanguage))
                .fontSize(this.fontTokens.body)
                .fontColor(this.themeTokens.colorTextPrimary)
                .width(80)
                .flexShrink(0)

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(
                  [TaskReminderType.NONE, TaskReminderType.POPUP, TaskReminderType.SOUND],
                  (type: number) => {
                    Text(I18nHelper.t(
                      type === TaskReminderType.NONE
                        ? I18nKeys.TASK_REMINDER_NONE
                        : type === TaskReminderType.POPUP
                        ? I18nKeys.TASK_REMINDER_POPUP
                        : I18nKeys.TASK_REMINDER_SOUND,
                      this.currentLanguage,
                    ))
                      .fontSize(this.fontTokens.label)
                      .fontColor(
                        this.reminderType === type
                          ? this.themeTokens.colorBackground
                          : this.themeTokens.colorTextSecondary
                      )
                      .height($r('app.float.tag_chip_height'))
                      .padding({
                        left: $r('app.float.tag_chip_padding_h'),
                        right: $r('app.float.tag_chip_padding_h'),
                      })
                      .margin({ right: $r('app.float.spacing_xs') })
                      .backgroundColor(
                        this.reminderType === type ? this.themeTokens.colorAccent : Color.Transparent
                      )
                      .border({
                        width: 0.5,
                        color: this.reminderType === type
                          ? this.themeTokens.colorAccent
                          : this.themeTokens.colorDivider,
                        radius: 11,
                      })
                      .onClick(() => {
                        animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                          this.reminderType = type;
                        });
                      })
                  },
                  (type: number) => type.toString(),
                )
              }
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
            .alignItems(VerticalAlign.Center)

            // 自定义通知文字（POPUP / SOUND 时显示）
            if (this.reminderType !== TaskReminderType.NONE) {
              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')

              Row({ space: $r('app.float.spacing_sm') }) {
                Text(I18nHelper.t(I18nKeys.TASK_REMINDER_MESSAGE_LABEL, this.currentLanguage))
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .width(80)
                  .flexShrink(0)

                TextInput({
                  placeholder: I18nHelper.t(I18nKeys.TASK_REMINDER_MESSAGE_PLACEHOLDER, this.currentLanguage),
                  text: this.reminderMessage,
                })
                  .fontSize(this.fontTokens.body)
                  .fontColor(this.themeTokens.colorTextPrimary)
                  .placeholderColor(this.themeTokens.colorTextSecondary)
                  .backgroundColor(Color.Transparent)
                  .borderWidth(0)
                  .layoutWeight(1)
                  .onChange((value: string) => {
                    this.reminderMessage = value;
                  })
              }
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_md'),
                bottom: $r('app.float.spacing_md'),
              })
              .alignItems(VerticalAlign.Center)
            }
          }

          // ── 8. 时间戳（仅编辑模式） ──────────────────────────────────────
          if (this.isEditMode && this.originalEntry.createdAt > 0) {
            Divider()
              .strokeWidth(DIVIDER_STROKE_WIDTH)
              .color(this.themeTokens.colorDivider)
              .width('100%')

            Column({ space: 6 }) {
              Row({ space: 6 }) {
                Text(I18nHelper.t(I18nKeys.TASK_CREATED_AT, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
                Text(formatTimestamp(this.originalEntry.createdAt, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
              }

              Row({ space: 6 }) {
                Text(I18nHelper.t(I18nKeys.TASK_UPDATED_AT, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
                Text(formatTimestamp(this.originalEntry.updatedAt, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }

  /** 触发保存按钮横向扩散特效 */
  private triggerSaveSpread(touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx: number) => {
        this.savePressedIndex = idx;
      },
      (scale: number, opacity: number) => {
        this.saveSpreadScale = scale;
        this.saveSpreadOpacity = opacity;
      },
      (x: number) => {
        this.saveCenterX = x;
      },
      0,
      touchX,
    );
  }

  /** 触发返回按钮横向扩散特效 */
  private triggerBackSpread(touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx: number) => {
        this.backPressedIndex = idx;
      },
      (scale: number, opacity: number) => {
        this.backSpreadScale = scale;
        this.backSpreadOpacity = opacity;
      },
      (x: number) => {
        this.backCenterX = x;
      },
      0,
      touchX,
    );
  }

  /**
   * 确认添加标签输入框中的内容为新标签。
   * 自动 trim，忽略空内容及重复标签。
   */
  private addTag(): void {
    const trimmed: string = this.tagInput.trim().replace(/，/g, '').replace(/,/g, '');
    if (trimmed === '' || this.tags.indexOf(trimmed) >= 0) {
      this.tagInput = '';
      return;
    }
    const newTags: string[] = [];
    for (const t of this.tags) {
      newTags.push(t);
    }
    newTags.push(trimmed);
    this.tags = newTags;
    this.tagInput = '';
  }

  /** 移除指定索引的标签 */
  private removeTag(index: number): void {
    const newTags: string[] = [];
    for (let i: number = 0; i < this.tags.length; i++) {
      if (i !== index) {
        newTags.push(this.tags[i]);
      }
    }
    this.tags = newTags;
  }

  /**
   * 弹出日期选择器（DatePickerDialog → TimePickerDialog 链式调用）。
   * 日期确认后自动弹出时间选择器，两者均确认后合并写入 deadlineTs。
   */
  private showDatePicker(): void {
    const initDate: Date = this.deadlineTs > 0 ? new Date(this.deadlineTs) : new Date();
    DatePickerDialog.show({
      start: new Date(),
      end: new Date(Date.now() + 365 * 86400000),
      selected: initDate,
      onDateAccept: (dateValue: Date) => {
        // 暂存日期部分，等待时间选择器
        const d: Date = new Date(dateValue.getTime());
        d.setHours(0, 0, 0, 0);
        this.pendingDateMs = d.getTime();
        this.showTimePicker();
      },
    });
  }

  /** 弹出时间选择器，并在确认后将日期+时间合并写入 deadlineTs */
  private showTimePicker(): void {
    const initDate: Date = this.deadlineTs > 0 ? new Date(this.deadlineTs) : new Date();
    TimePickerDialog.show({
      selected: initDate,
      useMilitaryTime: true,
      onAccept: (timeValue: TimeResult) => {
        const combined: number = this.pendingDateMs
          + timeValue.hour * 3600000
          + timeValue.minute * 60000;
        this.deadlineTs = combined;
      },
    });
  }

  /**
   * 将截止时间戳格式化为简洁的显示字符串（仅在编辑器中使用，精确到分钟）。
   * 用私有方法代替 build() 内联逻辑，遵循 ArkTS build() 无变量声明约束。
   */
  private formatDeadlineDisplay(): string {
    if (this.deadlineTs === 0) {
      return I18nHelper.t(I18nKeys.TASK_SCHEDULE_NONE, this.currentLanguage);
    }
    const d: Date = new Date(this.deadlineTs);
    const month: number = d.getMonth() + 1;
    const day: number = d.getDate();
    const hour: number = d.getHours();
    const minute: number = d.getMinutes();
    const hh: string = hour < 10 ? '0' + hour.toString() : hour.toString();
    const mm: string = minute < 10 ? '0' + minute.toString() : minute.toString();
    return month.toString() + '/' + day.toString() + ' ' + hh + ':' + mm;
  }

  /** 将开始时间戳格式化为简洁显示字符串（区间任务用） */
  private formatStartDisplay(): string {
    if (this.startTs === 0) {
      return I18nHelper.t(I18nKeys.TASK_SCHEDULE_NONE, this.currentLanguage);
    }
    const d: Date = new Date(this.startTs);
    const month: number = d.getMonth() + 1;
    const day: number = d.getDate();
    const hour: number = d.getHours();
    const minute: number = d.getMinutes();
    const hh: string = hour < 10 ? '0' + hour.toString() : hour.toString();
    const mm: string = minute < 10 ? '0' + minute.toString() : minute.toString();
    return month.toString() + '/' + day.toString() + ' ' + hh + ':' + mm;
  }

  // ── 多节点选择器 ──────────────────────────────────────────────────────────

  /**
   * 弹出开始时间日期选择器（区间任务用）。
   * 日期确认后自动弹出时间选择器，两者均确认后合并写入 startTs。
   */
  private showStartDatePicker(): void {
    const initDate: Date = this.startTs > 0 ? new Date(this.startTs) : new Date();
    DatePickerDialog.show({
      start: new Date(),
      end: new Date(Date.now() + 365 * 86400000),
      selected: initDate,
      onDateAccept: (dateValue: Date) => {
        const d: Date = new Date(dateValue.getTime());
        d.setHours(0, 0, 0, 0);
        this.pendingStartDateMs = d.getTime();
        this.showStartTimePicker();
      },
    });
  }

  /** 弹出开始时间的时间选择器，确认后合并写入 startTs */
  private showStartTimePicker(): void {
    const initDate: Date = this.startTs > 0 ? new Date(this.startTs) : new Date();
    TimePickerDialog.show({
      selected: initDate,
      useMilitaryTime: true,
      onAccept: (timeValue: TimeResult) => {
        const combined: number = this.pendingStartDateMs
          + timeValue.hour * 3600000
          + timeValue.minute * 60000;
        this.startTs = combined;
      },
    });
  }

  /** 将时间戳格式化为 M/D HH:mm 字符串，供节点行显示 */
  private formatNodeTs(ts: number): string {
    if (ts <= 0) {
      return I18nHelper.t(I18nKeys.TASK_SCHEDULE_NONE, this.currentLanguage);
    }
    const d: Date = new Date(ts);
    const month: number = d.getMonth() + 1;
    const day: number = d.getDate();
    const hour: number = d.getHours();
    const minute: number = d.getMinutes();
    const hh: string = hour < 10 ? '0' + hour.toString() : hour.toString();
    const mm: string = minute < 10 ? '0' + minute.toString() : minute.toString();
    return month.toString() + '/' + day.toString() + ' ' + hh + ':' + mm;
  }

  /**
   * 响应式更新多节点列表的指定索引。
   * index === multiNodes.length 时追加新节点，同步扩展 nodeTargetDurationStrs。
   */
  private updateMultiNode(index: number, ts: number): void {
    const newNodes: number[] = [];
    for (let i: number = 0; i < this.multiNodes.length; i++) {
      newNodes.push(i === index ? ts : this.multiNodes[i]);
    }
    if (index === this.multiNodes.length) {
      newNodes.push(ts);
      // 同步扩展目标时长数组
      const newDurs: string[] = [];
      for (let i: number = 0; i < this.nodeTargetDurationStrs.length; i++) {
        newDurs.push(this.nodeTargetDurationStrs[i]);
      }
      newDurs.push('');
      this.nodeTargetDurationStrs = newDurs;
    }
    this.multiNodes = newNodes;
  }

  /** 移除多节点列表的指定索引 */
  private removeMultiNode(index: number): void {
    const newNodes: number[] = [];
    const newDurs: string[] = [];
    for (let i: number = 0; i < this.multiNodes.length; i++) {
      if (i !== index) {
        newNodes.push(this.multiNodes[i]);
        newDurs.push(i < this.nodeTargetDurationStrs.length ? this.nodeTargetDurationStrs[i] : '');
      }
    }
    this.multiNodes = newNodes;
    this.nodeTargetDurationStrs = newDurs;
  }

  /**
   * 响应式更新指定索引节点的目标时长字符串。
   * ArkTS 禁止直接通过索引赋值 @State 数组，需重建整个数组。
   */
  private updateNodeDuration(index: number, val: string): void {
    const len: number = this.scheduleTypeSelection === TaskScheduleType.MULTI_NODE
      ? this.multiNodes.length
      : this.multiIntervalNodes.length;
    const newDurs: string[] = [];
    for (let i: number = 0; i < len; i++) {
      if (i === index) {
        newDurs.push(val);
      } else {
        newDurs.push(i < this.nodeTargetDurationStrs.length ? this.nodeTargetDurationStrs[i] : '');
      }
    }
    this.nodeTargetDurationStrs = newDurs;
  }

  // ── 多节点区间选择器 ──────────────────────────────────────────────────────

  /** 弹出多节点日期选择器（接着弹时间选择器）；index === length 表示新增 */
  private showMultiNodeDatePicker(index: number): void {
    this.pendingMultiNodeIndex = index;
    const initTs: number = index < this.multiNodes.length ? this.multiNodes[index] : Date.now();
    DatePickerDialog.show({
      start: new Date(),
      end: new Date(Date.now() + 365 * 86400000),
      selected: new Date(initTs),
      onDateAccept: (dateValue: Date) => {
        const d: Date = new Date(dateValue.getTime());
        d.setHours(0, 0, 0, 0);
        this.pendingMultiDateMs = d.getTime();
        this.showMultiNodeTimePicker();
      },
    });
  }

  /** 弹出多节点时间选择器，确认后写入 multiNodes */
  private showMultiNodeTimePicker(): void {
    const index: number = this.pendingMultiNodeIndex;
    const initTs: number = index < this.multiNodes.length ? this.multiNodes[index] : Date.now();
    TimePickerDialog.show({
      selected: new Date(initTs),
      useMilitaryTime: true,
      onAccept: (timeValue: TimeResult) => {
        const combined: number = this.pendingMultiDateMs
          + timeValue.hour * 3600000
          + timeValue.minute * 60000;
        this.updateMultiNode(this.pendingMultiNodeIndex, combined);
      },
    });
  }

  /**
   * 响应式更新多节点区间列表的 start 侧。
   * index === multiIntervalNodes.length 时追加新区间（end 默认为 start + 1h）。
   * 返回实际写入的索引（供自动触发结束时间选取使用）。
   */
  private updateMultiIntervalStart(index: number, ts: number): number {
    const newNodes: IntervalNode[] = [];
    let actualIdx: number = index;
    for (let i: number = 0; i < this.multiIntervalNodes.length; i++) {
      if (i === index) {
        newNodes.push({ start: ts, end: this.multiIntervalNodes[i].end });
      } else {
        newNodes.push(this.multiIntervalNodes[i]);
      }
    }
    if (index === this.multiIntervalNodes.length) {
      newNodes.push({ start: ts, end: ts + 3600000 });
      actualIdx = newNodes.length - 1;
      // 同步扩展目标时长数组
      const newDurs: string[] = [];
      for (let i: number = 0; i < this.nodeTargetDurationStrs.length; i++) {
        newDurs.push(this.nodeTargetDurationStrs[i]);
      }
      newDurs.push('');
      this.nodeTargetDurationStrs = newDurs;
    }
    this.multiIntervalNodes = newNodes;
    return actualIdx;
  }

  /** 响应式更新多节点区间列表的 end 侧 */
  private updateMultiIntervalEnd(index: number, ts: number): void {
    const newNodes: IntervalNode[] = [];
    for (let i: number = 0; i < this.multiIntervalNodes.length; i++) {
      if (i === index) {
        newNodes.push({ start: this.multiIntervalNodes[i].start, end: ts });
      } else {
        newNodes.push(this.multiIntervalNodes[i]);
      }
    }
    this.multiIntervalNodes = newNodes;
  }

  /** 移除多节点区间列表的指定索引 */
  private removeMultiInterval(index: number): void {
    const newNodes: IntervalNode[] = [];
    const newDurs: string[] = [];
    for (let i: number = 0; i < this.multiIntervalNodes.length; i++) {
      if (i !== index) {
        newNodes.push(this.multiIntervalNodes[i]);
        newDurs.push(i < this.nodeTargetDurationStrs.length ? this.nodeTargetDurationStrs[i] : '');
      }
    }
    this.multiIntervalNodes = newNodes;
    this.nodeTargetDurationStrs = newDurs;
  }

  /** 弹出区间节点开始时间日期选择器；index === length 时为新增模式 */
  private showMultiIntervalStartDatePicker(index: number): void {
    this.pendingMultiNodeIndex = index;
    this.pendingMultiIntervalSide = 0;
    const initTs: number = index < this.multiIntervalNodes.length
      ? this.multiIntervalNodes[index].start
      : Date.now();
    DatePickerDialog.show({
      start: new Date(),
      end: new Date(Date.now() + 365 * 86400000),
      selected: new Date(initTs),
      onDateAccept: (dateValue: Date) => {
        const d: Date = new Date(dateValue.getTime());
        d.setHours(0, 0, 0, 0);
        this.pendingMultiDateMs = d.getTime();
        this.showMultiIntervalStartTimePicker();
      },
    });
  }

  /** 弹出区间节点开始时间的时间选择器，完成后自动弹出结束时间选取 */
  private showMultiIntervalStartTimePicker(): void {
    const index: number = this.pendingMultiNodeIndex;
    const initTs: number = index < this.multiIntervalNodes.length
      ? this.multiIntervalNodes[index].start
      : Date.now();
    TimePickerDialog.show({
      selected: new Date(initTs),
      useMilitaryTime: true,
      onAccept: (timeValue: TimeResult) => {
        const combined: number = this.pendingMultiDateMs
          + timeValue.hour * 3600000
          + timeValue.minute * 60000;
        // updateMultiIntervalStart 返回实际写入的索引（追加时等于旧 length）
        const realIdx: number = this.updateMultiIntervalStart(this.pendingMultiNodeIndex, combined);
        // 自动继续弹出结束时间选取
        this.pendingMultiNodeIndex = realIdx;
        this.showMultiIntervalEndDatePicker(realIdx);
      },
    });
  }

  // ── 周期规则星期几选择 ────────────────────────────────────────────────────

  /** 弹出区间节点结束时间日期选择器 */
  private showMultiIntervalEndDatePicker(index: number): void {
    this.pendingMultiNodeIndex = index;
    this.pendingMultiIntervalSide = 1;
    const initTs: number = index < this.multiIntervalNodes.length
      ? this.multiIntervalNodes[index].end
      : Date.now() + 3600000;
    DatePickerDialog.show({
      start: new Date(),
      end: new Date(Date.now() + 365 * 86400000),
      selected: new Date(initTs),
      onDateAccept: (dateValue: Date) => {
        const d: Date = new Date(dateValue.getTime());
        d.setHours(0, 0, 0, 0);
        this.pendingMultiDateMs = d.getTime();
        this.showMultiIntervalEndTimePicker();
      },
    });
  }

  /** 弹出区间节点结束时间的时间选择器，确认后写入 multiIntervalNodes */
  private showMultiIntervalEndTimePicker(): void {
    const index: number = this.pendingMultiNodeIndex;
    const initTs: number = index < this.multiIntervalNodes.length
      ? this.multiIntervalNodes[index].end
      : Date.now() + 3600000;
    TimePickerDialog.show({
      selected: new Date(initTs),
      useMilitaryTime: true,
      onAccept: (timeValue: TimeResult) => {
        const combined: number = this.pendingMultiDateMs
          + timeValue.hour * 3600000
          + timeValue.minute * 60000;
        this.updateMultiIntervalEnd(this.pendingMultiNodeIndex, combined);
      },
    });
  }

  /** 切换 WEEKLY 模式中某个星期几的选中状态 */
  private toggleWeekDay(day: number): void {
    const newDays: number[] = [];
    let found: boolean = false;
    for (const d of this.selectedWeekDays) {
      if (d === day) {
        found = true;
      } else {
        newDays.push(d);
      }
    }
    if (!found) {
      // 保证至少选中一天：仅在非最后一个时允许反选
      for (const d of this.selectedWeekDays) {
        newDays.push(d);
      }
      newDays.push(day);
      newDays.sort();
      this.selectedWeekDays = newDays;
    } else if (this.selectedWeekDays.length > 1) {
      // 移除后至少还有一天
      this.selectedWeekDays = newDays;
    }
  }

  /** 根据星期几索引（0=周日）返回对应的 i18n 翻译文本 */
  private weekdayLabel(dayIndex: number, lang: string): string {
    if (dayIndex === 0) {
      return I18nHelper.t(I18nKeys.TASK_RECURRING_WEEKDAY_SUN, lang);
    }
    if (dayIndex === 1) {
      return I18nHelper.t(I18nKeys.TASK_RECURRING_WEEKDAY_MON, lang);
    }
    if (dayIndex === 2) {
      return I18nHelper.t(I18nKeys.TASK_RECURRING_WEEKDAY_TUE, lang);
    }
    if (dayIndex === 3) {
      return I18nHelper.t(I18nKeys.TASK_RECURRING_WEEKDAY_WED, lang);
    }
    if (dayIndex === 4) {
      return I18nHelper.t(I18nKeys.TASK_RECURRING_WEEKDAY_THU, lang);
    }
    if (dayIndex === 5) {
      return I18nHelper.t(I18nKeys.TASK_RECURRING_WEEKDAY_FRI, lang);
    }
    return I18nHelper.t(I18nKeys.TASK_RECURRING_WEEKDAY_SAT, lang);
  }

  /** 判断某天是否在 WEEKLY 选中列表中 */
  private isWeekDaySelected(day: number): boolean {
    for (const d of this.selectedWeekDays) {
      if (d === day) {
        return true;
      }
    }
    return false;
  }

  /** 获取调度类型 chip 的文本 */
  private scheduleTypeLabel(typeVal: number): string {
    if (typeVal === TaskScheduleType.INTERVAL) {
      return I18nHelper.t(I18nKeys.TASK_TYPE_INTERVAL, this.currentLanguage);
    }
    if (typeVal === TaskScheduleType.MULTI_NODE) {
      return I18nHelper.t(I18nKeys.TASK_TYPE_MULTI_NODE, this.currentLanguage);
    }
    if (typeVal === TaskScheduleType.MULTI_NODE_INTERVAL) {
      return I18nHelper.t(I18nKeys.TASK_TYPE_MULTI_INTERVAL, this.currentLanguage);
    }
    if (typeVal === TaskScheduleType.RECURRING) {
      return I18nHelper.t(I18nKeys.TASK_TYPE_RECURRING, this.currentLanguage);
    }
    return I18nHelper.t(I18nKeys.TASK_TYPE_SINGLE, this.currentLanguage);
  }

  private async doSave(): Promise<void> {
    // 自动提交输入框中尚未按回车确认的标签
    this.addTag();
    const trimmedTitle: string = this.titleText.trim();
    if (trimmedTitle === '') {
      return;
    }
    const tagsStr: string = serializeTags(this.tags);
    const targetDuration: number = this.targetDurationStr.trim() === ''
      ? 0
      : parseInt(this.targetDurationStr.trim(), 10);
    const safeTargetDuration: number = isNaN(targetDuration) ? 0 : targetDuration;

    // 根据任务类型决定 scheduleType 和 timeNodes
    let scheduleType: number;
    let timeNodesStr: string;
    let recurringRuleStr: string = '';
    let nodeTargetDurationsStr: string = '';
    if (this.scheduleTypeSelection === TaskScheduleType.INTERVAL) {
      // 区间任务：必须同时有开始时间和截止时间，且开始 < 截止
      if (this.startTs <= 0 || this.deadlineTs <= 0 || this.startTs >= this.deadlineTs) {
        return;
      }
      scheduleType = TaskScheduleType.INTERVAL;
      timeNodesStr = serializeIntervalNodes([{ start: this.startTs, end: this.deadlineTs }]);
    } else if (this.scheduleTypeSelection === TaskScheduleType.MULTI_NODE) {
      // 多节点任务：至少需要 1 个有效节点
      if (this.multiNodes.length === 0) {
        return;
      }
      scheduleType = TaskScheduleType.MULTI_NODE;
      // 将节点与目标时长配对后排序，确保排序后索引仍与目标时长对应
      const paired: NodeWithDuration[] = [];
      for (let i: number = 0; i < this.multiNodes.length; i++) {
        paired.push({
          ts: this.multiNodes[i],
          durStr: i < this.nodeTargetDurationStrs.length ? this.nodeTargetDurationStrs[i] : '',
        });
      }
      paired.sort((a: NodeWithDuration, b: NodeWithDuration) => a.ts - b.ts);
      const sortedTs: number[] = [];
      const sortedDurs: number[] = [];
      for (const p of paired) {
        sortedTs.push(p.ts);
        const d: number = parseInt(p.durStr.trim(), 10);
        sortedDurs.push(isNaN(d) ? 0 : d);
      }
      timeNodesStr = serializeTimeNodes(sortedTs);
      nodeTargetDurationsStr = serializeNodeTargetDurations(sortedDurs);
    } else if (this.scheduleTypeSelection === TaskScheduleType.MULTI_NODE_INTERVAL) {
      // 多节点区间任务：至少需要 1 个有效区间，且每个区间 start < end
      if (this.multiIntervalNodes.length === 0) {
        return;
      }
      for (const node of this.multiIntervalNodes) {
        if (node.start <= 0 || node.end <= 0 || node.start >= node.end) {
          return;
        }
      }
      scheduleType = TaskScheduleType.MULTI_NODE_INTERVAL;
      // 将区间节点与目标时长配对后排序
      const pairedInterval: IntervalWithDuration[] = [];
      for (let i: number = 0; i < this.multiIntervalNodes.length; i++) {
        pairedInterval.push({
          start: this.multiIntervalNodes[i].start,
          end: this.multiIntervalNodes[i].end,
          durStr: i < this.nodeTargetDurationStrs.length ? this.nodeTargetDurationStrs[i] : '',
        });
      }
      pairedInterval.sort((a: IntervalWithDuration, b: IntervalWithDuration) => a.start - b.start);
      const sortedIntervals: IntervalNode[] = [];
      const sortedIntervalDurs: number[] = [];
      for (const p of pairedInterval) {
        sortedIntervals.push({ start: p.start, end: p.end });
        const d: number = parseInt(p.durStr.trim(), 10);
        sortedIntervalDurs.push(isNaN(d) ? 0 : d);
      }
      timeNodesStr = serializeIntervalNodes(sortedIntervals);
      nodeTargetDurationsStr = serializeNodeTargetDurations(sortedIntervalDurs);
    } else if (this.scheduleTypeSelection === TaskScheduleType.RECURRING) {
      // 周期性任务：需要首次触发时间
      if (this.deadlineTs <= 0) {
        return;
      }
      scheduleType = TaskScheduleType.RECURRING;
      timeNodesStr = serializeTimeNodes([this.deadlineTs]);
      const intervalDays: number = parseInt(this.intervalDaysStr.trim(), 10);
      const safeIntervalDays: number = isNaN(intervalDays) || intervalDays <= 0 ? 7 : intervalDays;
      const dayOfMonth: number = parseInt(this.dayOfMonthStr.trim(), 10);
      const safeDayOfMonth: number = isNaN(dayOfMonth) || dayOfMonth < 1 ? 1
        : dayOfMonth > 31 ? 31 : dayOfMonth;
      const rule: RecurringRule = {
        type: this.recurringType,
        intervalDays: safeIntervalDays,
        daysOfWeek: this.selectedWeekDays.length > 0 ? this.selectedWeekDays : [1],
        dayOfMonth: safeDayOfMonth,
      };
      recurringRuleStr = serializeRecurringRule(rule);
    } else {
      scheduleType = this.deadlineTs > 0 ? TaskScheduleType.SINGLE : TaskScheduleType.NONE;
      timeNodesStr = this.deadlineTs > 0 ? serializeTimeNodes([this.deadlineTs]) : '';
    }
    const now: number = Date.now();

    if (this.isEditMode) {
      const updated: TaskEntry = {
        id: this.originalEntry.id,
        title: trimmedTitle,
        content: this.content.trim(),
        tags: tagsStr,
        priority: this.priority,
        status: this.originalEntry.status,
        scheduleType: scheduleType,
        timeNodes: timeNodesStr,
        currentNodeIndex: this.originalEntry.currentNodeIndex,
        recurringRule: recurringRuleStr !== '' ? recurringRuleStr : this.originalEntry.recurringRule,
        targetDuration: safeTargetDuration,
        accumulatedDuration: this.originalEntry.accumulatedDuration,
        reminderType: this.reminderType,
        reminderOffset: this.originalEntry.reminderOffset,
        reminderSound: '',
        reminderMessage: this.reminderMessage,
        completionType: this.completionType,
        completedAt: this.originalEntry.completedAt,
        sourceInboxId: this.originalEntry.sourceInboxId,
        isPinned: this.originalEntry.isPinned,
        sortOrder: this.originalEntry.sortOrder,
        createdAt: this.originalEntry.createdAt,
        updatedAt: now,
        reminderId: this.originalEntry.reminderId,
        startReminderType: this.startReminderType,
        startReminderMessage: this.startReminderMessage,
        startReminderId: this.originalEntry.startReminderId,
        nodeTargetDurations: nodeTargetDurationsStr,
      };
      await TaskViewModel.update(updated);
    } else {
      const newEntry: TaskEntry = {
        id: 0,
        title: trimmedTitle,
        content: this.content.trim(),
        tags: tagsStr,
        priority: this.priority,
        status: TaskStatus.PENDING,
        scheduleType: scheduleType,
        timeNodes: timeNodesStr,
        currentNodeIndex: 0,
        recurringRule: recurringRuleStr,
        targetDuration: safeTargetDuration,
        accumulatedDuration: 0,
        reminderType: this.reminderType,
        reminderOffset: 0,
        reminderSound: '',
        reminderMessage: this.reminderMessage,
        completionType: this.completionType,
        completedAt: 0,
        sourceInboxId: this.fromInboxId,
        isPinned: 0,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
        reminderId: 0,
        startReminderType: this.startReminderType,
        startReminderMessage: this.startReminderMessage,
        startReminderId: 0,
        nodeTargetDurations: nodeTargetDurationsStr,
      };
      await TaskViewModel.create(newEntry);
      // 从收集箱转入时，任务创建成功后删除对应收集箱条目并通知收集箱刷新
      if (this.fromInboxId > 0) {
        await InboxViewModel.delete(this.fromInboxId);
        AppStorage.set<boolean>(KEY_INBOX_NEEDS_REFRESH, true);
      }
    }
    AppStorage.set<boolean>(KEY_TASK_NEEDS_REFRESH, true);
    router.back();
  }
}
