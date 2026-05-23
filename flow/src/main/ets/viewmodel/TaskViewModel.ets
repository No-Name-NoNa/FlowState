/**
 * TaskViewModel.ets
 * 任务模块业务逻辑层。
 * 静态类封装任务列表加载、动态权重排序、关键词/状态过滤、
 * 以及从收集箱条目快速转入任务的工厂方法。
 */
import { TaskDatabase } from '../util/TaskDatabase';
import {
  computeNextRecurringDate,
  computeTaskWeight,
  getNextDeadline,
  IntervalNode,
  parseIntervalNodes,
  parseRecurringRule,
  parseTimeNodes,
  RecurringRule,
  serializeIntervalNodes,
  serializeTimeNodes,
  TaskCompletionType,
  TaskEntry,
  TaskPriority,
  TaskReminderType,
  TaskScheduleType,
  TaskStatus
} from '../model/TaskEntry';
import { InboxEntry, parseTags } from '../model/InboxEntry';
import { NotificationHelper } from '../util/NotificationHelper';
import { TimerSessionDatabase } from '../util/TimerSessionDatabase';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { KEY_HISTORY_NEEDS_REFRESH, LOG_DOMAIN } from '../constants/AppConstants';

/** 任务 ViewModel，所有方法均为静态 */
export class TaskViewModel {
  /** 内存中全量任务缓存（已按动态权重降序排列） */
  static allTasks: TaskEntry[] = [];
  /** 当前过滤后可见的任务列表（供视图直接绑定） */
  static filteredTasks: TaskEntry[] = [];
  /** 当前搜索关键词（空字符串 = 无过滤） */
  private static currentKeyword: string = '';
  /** 当前状态过滤（-1 = 显示全部非归档任务） */
  private static currentStatus: number = -1;
  /** 当前标签过滤（空字符串 = 不按标签过滤） */
  private static currentTag: string = '';
  /** 防止 reconcileReminders 并发执行的互斥标志 */
  private static isReconciling: boolean = false;
  /** 上次 reconcileReminders 完成的时间戳（ms），供 maybeReconcile 限频使用 */
  private static lastReconcileAt: number = 0;
  /** maybeReconcile 的最短调用间隔：60 秒 */
  private static readonly RECONCILE_INTERVAL_MS: number = 60 * 1000;

  /**
   * 从 DB 重新加载全部任务并按动态权重排序。
   * 排序规则：置顶激活任务浮顶 → 普通激活任务（按权重降序）→ 已完成任务沉底。
   * 调用方在 Promise 完成后需同步读取 filteredTasks 刷新视图。
   */
  static async load(): Promise<void> {
    const tasks: TaskEntry[] = await TaskDatabase.queryAll();
    // 置顶激活 > 普通激活（按权重降序，同权重按创建时间升序）> 已完成
    tasks.sort((a: TaskEntry, b: TaskEntry) => {
      const aCompleted: boolean = a.status === TaskStatus.COMPLETED;
      const bCompleted: boolean = b.status === TaskStatus.COMPLETED;
      // 已完成任务始终沉底
      if (aCompleted !== bCompleted) {
        return aCompleted ? 1 : -1;
      }
      if (!aCompleted) {
        // 置顶任务优先浮顶
        if (a.isPinned !== b.isPinned) {
          return b.isPinned - a.isPinned;
        }
      }
      // 同组内按动态权重降序，权重相同时按创建时间升序
      const diff: number = computeTaskWeight(b) - computeTaskWeight(a);
      if (diff !== 0) {
        return diff;
      }
      return a.createdAt - b.createdAt;
    });
    TaskViewModel.allTasks = tasks;
    TaskViewModel.applyFilter();
  }

  /**
   * 设置关键词、状态、标签过滤条件，刷新 filteredTasks。
   * 不触发 DB 查询，仅在内存中过滤 allTasks。
   * @param keyword  搜索关键词（匹配 title / content / tags），空字符串表示不过滤
   * @param status   状态枚举值，-1 表示显示全部非归档任务
   * @param tag      标签过滤，空字符串表示不按标签过滤
   */
  static filter(keyword: string, status: number, tag: string = ''): void {
    TaskViewModel.currentKeyword = keyword;
    TaskViewModel.currentStatus = status;
    TaskViewModel.currentTag = tag;
    TaskViewModel.applyFilter();
  }

  /**
   * 从收集箱条目快速构造任务草稿。
   * 自动预填 title/content/tags 及 sourceInboxId，其余字段使用默认值。
   * 调用方可在此基础上修改字段后调用 create() 入库。
   * @param inbox 收集箱条目
   * @returns 预填好的 TaskEntry 草稿（id=0，尚未入库）
   */
  static buildFromInbox(inbox: InboxEntry): TaskEntry {
    const now: number = Date.now();
    return {
      id: 0,
      title: inbox.text,
      content: inbox.content,
      tags: inbox.tags,
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
      sourceInboxId: inbox.id,
      isPinned: 0,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
      reminderId: 0,
      startReminderType: 0,
      startReminderMessage: '',
      startReminderId: 0,
    };
  }

  /**
   * 将新任务写入 DB、调度截止提醒（如有），并刷新内存缓存。
   * @param entry id=0 的任务草稿
   * @returns 新行 ID，失败返回 -1
   */
  static async create(entry: TaskEntry): Promise<number> {
    const newId: number = await TaskDatabase.insert(entry);
    if (newId > 0) {
      // 注册截止提醒（若有），将 reminderId 写回 DB
      const entryWithId: TaskEntry = {
        id: newId,
        title: entry.title,
        content: entry.content,
        tags: entry.tags,
        priority: entry.priority,
        status: entry.status,
        scheduleType: entry.scheduleType,
        timeNodes: entry.timeNodes,
        currentNodeIndex: entry.currentNodeIndex,
        recurringRule: entry.recurringRule,
        targetDuration: entry.targetDuration,
        accumulatedDuration: entry.accumulatedDuration,
        reminderType: entry.reminderType,
        reminderOffset: entry.reminderOffset,
        reminderSound: entry.reminderSound,
        reminderMessage: entry.reminderMessage,
        completionType: entry.completionType,
        completedAt: entry.completedAt,
        sourceInboxId: entry.sourceInboxId,
        isPinned: entry.isPinned,
        sortOrder: entry.sortOrder,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        reminderId: 0,
        startReminderType: entry.startReminderType,
        startReminderMessage: entry.startReminderMessage,
        startReminderId: 0,
      };
      const reminderId: number = await NotificationHelper.scheduleDeadlineReminder(entryWithId);
      const startReminderId: number = await NotificationHelper.scheduleStartReminder(entryWithId);
      if (reminderId > 0 || startReminderId > 0) {
        const withReminder: TaskEntry = {
          id: entryWithId.id,
          title: entryWithId.title,
          content: entryWithId.content,
          tags: entryWithId.tags,
          priority: entryWithId.priority,
          status: entryWithId.status,
          scheduleType: entryWithId.scheduleType,
          timeNodes: entryWithId.timeNodes,
          currentNodeIndex: entryWithId.currentNodeIndex,
          recurringRule: entryWithId.recurringRule,
          targetDuration: entryWithId.targetDuration,
          accumulatedDuration: entryWithId.accumulatedDuration,
          reminderType: entryWithId.reminderType,
          reminderOffset: entryWithId.reminderOffset,
          reminderSound: entryWithId.reminderSound,
          reminderMessage: entryWithId.reminderMessage,
          completionType: entryWithId.completionType,
          completedAt: entryWithId.completedAt,
          sourceInboxId: entryWithId.sourceInboxId,
          isPinned: entryWithId.isPinned,
          sortOrder: entryWithId.sortOrder,
          createdAt: entryWithId.createdAt,
          updatedAt: entryWithId.updatedAt,
          reminderId: reminderId,
          startReminderType: entryWithId.startReminderType,
          startReminderMessage: entryWithId.startReminderMessage,
          startReminderId: startReminderId,
        };
        await TaskDatabase.update(withReminder);
      }
      await TaskViewModel.load();
    }
    return newId;
  }

  /**
   * 更新任务：先取消旧提醒，重新调度新提醒，再写 DB 并刷新内存缓存。
   * @param entry 含有效 id 的完整任务条目
   */
  static async update(entry: TaskEntry): Promise<void> {
    // 取消旧的截止提醒和开始提醒
    await NotificationHelper.cancelReminder(entry.reminderId);
    await NotificationHelper.cancelReminder(entry.startReminderId);
    // 注册新提醒并写入 reminderId
    const reminderId: number = await NotificationHelper.scheduleDeadlineReminder(entry);
    const startReminderId: number = await NotificationHelper.scheduleStartReminder(entry);
    const updated: TaskEntry = {
      id: entry.id,
      title: entry.title,
      content: entry.content,
      tags: entry.tags,
      priority: entry.priority,
      status: entry.status,
      scheduleType: entry.scheduleType,
      timeNodes: entry.timeNodes,
      currentNodeIndex: entry.currentNodeIndex,
      recurringRule: entry.recurringRule,
      targetDuration: entry.targetDuration,
      accumulatedDuration: entry.accumulatedDuration,
      reminderType: entry.reminderType,
      reminderOffset: entry.reminderOffset,
      reminderSound: entry.reminderSound,
      reminderMessage: entry.reminderMessage,
      completionType: entry.completionType,
      completedAt: entry.completedAt,
      sourceInboxId: entry.sourceInboxId,
      isPinned: entry.isPinned,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      reminderId: reminderId,
      startReminderType: entry.startReminderType,
      startReminderMessage: entry.startReminderMessage,
      startReminderId: startReminderId,
    };
    await TaskDatabase.update(updated);
    await TaskViewModel.load();
  }

  /**
   * 删除任务：先取消提醒，再删 DB、清理计时分段记录，并刷新内存缓存。
   * @param id 任务主键
   */
  static async remove(id: number): Promise<void> {
    const entry: TaskEntry | null = await TaskDatabase.getById(id);
    if (entry !== null) {
      await NotificationHelper.cancelReminder(entry.reminderId);
      await NotificationHelper.cancelReminder(entry.startReminderId);
    }
    // 同步删除该任务的所有计时分段记录
    await TimerSessionDatabase.deleteByTaskId(id);
    await TaskDatabase.delete(id);
    await TaskViewModel.load();
  }

  /**
   * 启动时协调提醒定时器：清除全部内存定时器后，为所有活跃任务重新调度。
   * 解决应用重启后定时器失效导致的提醒丢失问题。
   * 火后不管（fire-and-forget）异步调用，不阻塞页面加载。
   * 内置互斥锁防止并发执行导致重复注册。
   */
  static async reconcileReminders(): Promise<void> {
    // 互斥：防止并发调用导致重复注册
    if (TaskViewModel.isReconciling) {
      hilog.debug(LOG_DOMAIN, 'TaskViewModel', '提醒协调正在进行中，跳过本次并发调用');
      return;
    }
    TaskViewModel.isReconciling = true;
    TaskViewModel.lastReconcileAt = Date.now();
    try {
      // 清空全部已注册提醒，重置槽位计数
      await NotificationHelper.cancelAllReminders();
      const tasks: TaskEntry[] = await TaskDatabase.queryAll();
      let count: number = 0;
      let deadlineCount: number = 0;
      let startCount: number = 0;
      for (const task of tasks) {
        if (task.status === TaskStatus.COMPLETED || task.status === TaskStatus.ARCHIVED) {
          // 已完成/归档任务无需提醒，若 DB 残留旧 ID 一并清零
          if (task.reminderId !== 0 || task.startReminderId !== 0) {
            await TaskDatabase.updateReminderIds(task.id, 0, 0);
          }
          continue;
        }
        const newReminderId: number = await NotificationHelper.scheduleDeadlineReminder(task);
        const newStartReminderId: number = await NotificationHelper.scheduleStartReminder(task);
        if (newReminderId !== task.reminderId || newStartReminderId !== task.startReminderId) {
          await TaskDatabase.updateReminderIds(task.id, newReminderId, newStartReminderId);
        }
        if (newReminderId > 0) {
          deadlineCount++;
        }
        if (newStartReminderId > 0) {
          startCount++;
        }
        count++;
      }
      hilog.info(LOG_DOMAIN, 'TaskViewModel',
        '提醒协调完成，活跃任务 %{public}d 条，截止提醒 %{public}d 条，开始提醒 %{public}d 条',
        count, deadlineCount, startCount);
    } finally {
      TaskViewModel.isReconciling = false;
    }
  }

  /**
   * 限频版 reconcileReminders：距上次协调未满 60 秒时直接返回，避免频繁重调度。
   * 供 onForeground 调用，每次进入前台时补调度可能遗漏的定时器。
   */
  static async maybeReconcile(): Promise<void> {
    const now: number = Date.now();
    if (now - TaskViewModel.lastReconcileAt < TaskViewModel.RECONCILE_INTERVAL_MS) {
      return;
    }
    await TaskViewModel.reconcileReminders();
  }

  /**
   * 聚合当前 allTasks 中出现的所有标签（去重）。
   * @returns 标签字符串数组
   */
  static getAllTags(): string[] {
    const tagSet: string[] = [];
    for (const task of TaskViewModel.allTasks) {
      if (task.tags === '') {
        continue;
      }
      try {
        const tags: string[] = parseTags(task.tags);
        for (const tag of tags) {
          if (tagSet.indexOf(tag) < 0) {
            tagSet.push(tag);
          }
        }
      } catch {
        // 忽略 tags 解析异常
      }
    }
    return tagSet;
  }

  /**
   * 根据 ID 获取单条任务（透传 DB 查询，供编辑页加载原始数据使用）。
   * @param id 任务主键
   * @returns 任务条目，不存在时返回 null
   */
  static async getById(id: number): Promise<TaskEntry | null> {
    return await TaskDatabase.getById(id);
  }

  /**
   * 将指定任务标记为已完成，取消截止提醒，并刷新内存缓存。
   *
   * 特殊行为：
   * - RECURRING：将当前实例标为完成，并自动创建携带下一次触发时间的新任务（进入待办）。
   * - MULTI_NODE / MULTI_NODE_INTERVAL：若还有下一节点，推进 currentNodeIndex，保持 PENDING；
   *   若已是最后节点，才标记为 COMPLETED。
   *
   * @param id 任务主键
   */
  static async complete(id: number): Promise<void> {
    const entry: TaskEntry | null = await TaskDatabase.getById(id);
    if (entry === null) {
      return;
    }
    await NotificationHelper.cancelReminder(entry.reminderId);
    await NotificationHelper.cancelReminder(entry.startReminderId);
    const now: number = Date.now();

    // ── RECURRING：完成当前实例 + 自动创建下一实例 ──────────────────────────
    if (entry.scheduleType === TaskScheduleType.RECURRING) {
      // 将当前实例标为完成
      const completedEntry: TaskEntry = {
        id: entry.id,
        title: entry.title,
        content: entry.content,
        tags: entry.tags,
        priority: entry.priority,
        status: TaskStatus.COMPLETED,
        scheduleType: entry.scheduleType,
        timeNodes: entry.timeNodes,
        currentNodeIndex: entry.currentNodeIndex,
        recurringRule: entry.recurringRule,
        targetDuration: entry.targetDuration,
        accumulatedDuration: entry.accumulatedDuration,
        reminderType: entry.reminderType,
        reminderOffset: entry.reminderOffset,
        reminderSound: entry.reminderSound,
        reminderMessage: entry.reminderMessage,
        completionType: entry.completionType,
        completedAt: now,
        sourceInboxId: entry.sourceInboxId,
        isPinned: entry.isPinned,
        sortOrder: entry.sortOrder,
        createdAt: entry.createdAt,
        updatedAt: now,
        reminderId: 0,
        startReminderType: entry.startReminderType,
        startReminderMessage: entry.startReminderMessage,
        startReminderId: 0,
      };
      await TaskDatabase.update(completedEntry);

      // 计算下一次触发时间并创建新任务实例
      const rule: RecurringRule | null = parseRecurringRule(entry.recurringRule);
      if (rule !== null) {
        const currentNodes: number[] = parseTimeNodes(entry.timeNodes);
        const currentTriggerTs: number = currentNodes.length > 0 ? currentNodes[0] : now;
        const nextTs: number = computeNextRecurringDate(rule, currentTriggerTs, now);
        if (nextTs > 0) {
          const nextEntry: TaskEntry = {
            id: 0,
            title: entry.title,
            content: entry.content,
            tags: entry.tags,
            priority: entry.priority,
            status: TaskStatus.PENDING,
            scheduleType: TaskScheduleType.RECURRING,
            timeNodes: serializeTimeNodes([nextTs]),
            currentNodeIndex: 0,
            recurringRule: entry.recurringRule,
            targetDuration: entry.targetDuration,
            accumulatedDuration: 0,
            reminderType: entry.reminderType,
            reminderOffset: entry.reminderOffset,
            reminderSound: entry.reminderSound,
            reminderMessage: entry.reminderMessage,
            completionType: entry.completionType,
            completedAt: 0,
            sourceInboxId: 0,
            isPinned: 0,
            sortOrder: entry.sortOrder,
            createdAt: now,
            updatedAt: now,
            reminderId: 0,
            startReminderType: 0,
            startReminderMessage: '',
            startReminderId: 0,
          };
          await TaskViewModel.create(nextEntry);
          return; // create() 内部已调用 load()，直接返回
        }
      }
      await TaskViewModel.load();
      return;
    }

    // ── MULTI_NODE：推进节点索引，最后节点完成后才标为 COMPLETED ───────────
    if (entry.scheduleType === TaskScheduleType.MULTI_NODE) {
      const nodes: number[] = parseTimeNodes(entry.timeNodes);
      const nextIndex: number = entry.currentNodeIndex + 1;
      if (nextIndex < nodes.length) {
        // 还有下一节点：推进索引，保持 PENDING 状态
        const advanced: TaskEntry = {
          id: entry.id,
          title: entry.title,
          content: entry.content,
          tags: entry.tags,
          priority: entry.priority,
          status: TaskStatus.PENDING,
          scheduleType: entry.scheduleType,
          timeNodes: entry.timeNodes,
          currentNodeIndex: nextIndex,
          recurringRule: entry.recurringRule,
          targetDuration: entry.targetDuration,
          accumulatedDuration: 0,
          reminderType: entry.reminderType,
          reminderOffset: entry.reminderOffset,
          reminderSound: entry.reminderSound,
          reminderMessage: entry.reminderMessage,
          completionType: entry.completionType,
          completedAt: 0,
          sourceInboxId: entry.sourceInboxId,
          isPinned: entry.isPinned,
          sortOrder: entry.sortOrder,
          createdAt: entry.createdAt,
          updatedAt: now,
          reminderId: 0,
          startReminderType: entry.startReminderType,
          startReminderMessage: entry.startReminderMessage,
          startReminderId: 0,
        };
        const newReminderId: number = await NotificationHelper.scheduleDeadlineReminder(advanced);
        const withReminder: TaskEntry = {
          id: advanced.id,
          title: advanced.title,
          content: advanced.content,
          tags: advanced.tags,
          priority: advanced.priority,
          status: advanced.status,
          scheduleType: advanced.scheduleType,
          timeNodes: advanced.timeNodes,
          currentNodeIndex: advanced.currentNodeIndex,
          recurringRule: advanced.recurringRule,
          targetDuration: advanced.targetDuration,
          accumulatedDuration: advanced.accumulatedDuration,
          reminderType: advanced.reminderType,
          reminderOffset: advanced.reminderOffset,
          reminderSound: advanced.reminderSound,
          reminderMessage: advanced.reminderMessage,
          completionType: advanced.completionType,
          completedAt: advanced.completedAt,
          sourceInboxId: advanced.sourceInboxId,
          isPinned: advanced.isPinned,
          sortOrder: advanced.sortOrder,
          createdAt: advanced.createdAt,
          updatedAt: advanced.updatedAt,
          reminderId: newReminderId,
          startReminderType: advanced.startReminderType,
          startReminderMessage: advanced.startReminderMessage,
          startReminderId: 0,
        };
        await TaskDatabase.update(withReminder);
        await TaskViewModel.load();
        return;
      }
      // 已是最后节点：正常标完成
    }

    // ── MULTI_NODE_INTERVAL：推进节点索引，最后节点完成后才标为 COMPLETED ──
    if (entry.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL) {
      const intervalNodes: IntervalNode[] = parseIntervalNodes(entry.timeNodes);
      const nextIndex: number = entry.currentNodeIndex + 1;
      if (nextIndex < intervalNodes.length) {
        // 还有下一区间节点：推进索引，保持 PENDING
        const advanced: TaskEntry = {
          id: entry.id,
          title: entry.title,
          content: entry.content,
          tags: entry.tags,
          priority: entry.priority,
          status: TaskStatus.PENDING,
          scheduleType: entry.scheduleType,
          timeNodes: entry.timeNodes,
          currentNodeIndex: nextIndex,
          recurringRule: entry.recurringRule,
          targetDuration: entry.targetDuration,
          accumulatedDuration: 0,
          reminderType: entry.reminderType,
          reminderOffset: entry.reminderOffset,
          reminderSound: entry.reminderSound,
          reminderMessage: entry.reminderMessage,
          completionType: entry.completionType,
          completedAt: 0,
          sourceInboxId: entry.sourceInboxId,
          isPinned: entry.isPinned,
          sortOrder: entry.sortOrder,
          createdAt: entry.createdAt,
          updatedAt: now,
          reminderId: 0,
          startReminderType: entry.startReminderType,
          startReminderMessage: entry.startReminderMessage,
          startReminderId: 0,
        };
        const newReminderId: number = await NotificationHelper.scheduleDeadlineReminder(advanced);
        const newStartReminderId: number = await NotificationHelper.scheduleStartReminder(advanced);
        const withReminder: TaskEntry = {
          id: advanced.id,
          title: advanced.title,
          content: advanced.content,
          tags: advanced.tags,
          priority: advanced.priority,
          status: advanced.status,
          scheduleType: advanced.scheduleType,
          timeNodes: advanced.timeNodes,
          currentNodeIndex: advanced.currentNodeIndex,
          recurringRule: advanced.recurringRule,
          targetDuration: advanced.targetDuration,
          accumulatedDuration: advanced.accumulatedDuration,
          reminderType: advanced.reminderType,
          reminderOffset: advanced.reminderOffset,
          reminderSound: advanced.reminderSound,
          reminderMessage: advanced.reminderMessage,
          completionType: advanced.completionType,
          completedAt: advanced.completedAt,
          sourceInboxId: advanced.sourceInboxId,
          isPinned: advanced.isPinned,
          sortOrder: advanced.sortOrder,
          createdAt: advanced.createdAt,
          updatedAt: advanced.updatedAt,
          reminderId: newReminderId,
          startReminderType: advanced.startReminderType,
          startReminderMessage: advanced.startReminderMessage,
          startReminderId: newStartReminderId,
        };
        await TaskDatabase.update(withReminder);
        await TaskViewModel.load();
        return;
      }
      // 已是最后节点：正常标完成
    }

    // ── 通用完成逻辑（SINGLE / INTERVAL / 最后节点） ────────────────────────
    const updated: TaskEntry = {
      id: entry.id,
      title: entry.title,
      content: entry.content,
      tags: entry.tags,
      priority: entry.priority,
      status: TaskStatus.COMPLETED,
      scheduleType: entry.scheduleType,
      timeNodes: entry.timeNodes,
      currentNodeIndex: entry.currentNodeIndex,
      recurringRule: entry.recurringRule,
      targetDuration: entry.targetDuration,
      accumulatedDuration: entry.accumulatedDuration,
      reminderType: entry.reminderType,
      reminderOffset: entry.reminderOffset,
      reminderSound: entry.reminderSound,
      reminderMessage: entry.reminderMessage,
      completionType: entry.completionType,
      completedAt: now,
      sourceInboxId: entry.sourceInboxId,
      isPinned: entry.isPinned,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: now,
      reminderId: 0,
      startReminderType: entry.startReminderType,
      startReminderMessage: entry.startReminderMessage,
      startReminderId: 0,
    };
    await TaskDatabase.update(updated);
    await TaskViewModel.load();
    // 归档后通知历史页刷新
    AppStorage.setOrCreate(KEY_HISTORY_NEEDS_REFRESH, true);
  }

  /**
   * 取消指定任务的完成状态，恢复为待办，并刷新内存缓存。
   * @param id 任务主键
   */
  static async uncomplete(id: number): Promise<void> {
    const entry: TaskEntry | null = await TaskDatabase.getById(id);
    if (entry === null) {
      return;
    }
    const now: number = Date.now();
    const updated: TaskEntry = {
      id: entry.id,
      title: entry.title,
      content: entry.content,
      tags: entry.tags,
      priority: entry.priority,
      status: TaskStatus.PENDING,
      scheduleType: entry.scheduleType,
      timeNodes: entry.timeNodes,
      currentNodeIndex: entry.currentNodeIndex,
      recurringRule: entry.recurringRule,
      targetDuration: entry.targetDuration,
      accumulatedDuration: entry.accumulatedDuration,
      reminderType: entry.reminderType,
      reminderOffset: entry.reminderOffset,
      reminderSound: entry.reminderSound,
      reminderMessage: entry.reminderMessage,
      completionType: entry.completionType,
      completedAt: 0,
      sourceInboxId: entry.sourceInboxId,
      isPinned: entry.isPinned,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: now,
      reminderId: entry.reminderId,
      startReminderType: entry.startReminderType,
      startReminderMessage: entry.startReminderMessage,
      startReminderId: entry.startReminderId,
    };
    await TaskDatabase.update(updated);
    await TaskViewModel.load();
  }

  /**
   * 将指定任务标记为归档，取消截止提醒，不再在任务列表显示，可在历史页查看。
   * @param id 任务主键
   */
  static async archive(id: number): Promise<void> {
    const entry: TaskEntry | null = await TaskDatabase.getById(id);
    if (entry === null) {
      return;
    }
    // 归档时取消截止提醒和开始提醒
    await NotificationHelper.cancelReminder(entry.reminderId);
    await NotificationHelper.cancelReminder(entry.startReminderId);
    const now: number = Date.now();
    const updated: TaskEntry = {
      id: entry.id,
      title: entry.title,
      content: entry.content,
      tags: entry.tags,
      priority: entry.priority,
      status: TaskStatus.ARCHIVED,
      scheduleType: entry.scheduleType,
      timeNodes: entry.timeNodes,
      currentNodeIndex: entry.currentNodeIndex,
      recurringRule: entry.recurringRule,
      targetDuration: entry.targetDuration,
      accumulatedDuration: entry.accumulatedDuration,
      reminderType: entry.reminderType,
      reminderOffset: entry.reminderOffset,
      reminderSound: entry.reminderSound,
      reminderMessage: entry.reminderMessage,
      completionType: entry.completionType,
      completedAt: 0,
      sourceInboxId: entry.sourceInboxId,
      isPinned: entry.isPinned,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: now,
      reminderId: 0,
      startReminderType: entry.startReminderType,
      startReminderMessage: entry.startReminderMessage,
      startReminderId: 0,
    };
    await TaskDatabase.update(updated);
    await TaskViewModel.load();
    // 归档后通知历史页刷新
    AppStorage.setOrCreate(KEY_HISTORY_NEEDS_REFRESH, true);
  }

  /**
   * 保存任务的计时进度和状态变更（供详情页计时器使用）。
   * 不触发 filteredTasks 刷新，由调用方通过 KEY_TASK_NEEDS_REFRESH 信号通知列表页更新。
   * @param id          任务主键
   * @param accMs       最新累计专注时长（ms）
   * @param status      最新任务状态（TaskStatus 枚举值）
   * @param completedAt 完成时间戳（ms），非完成状态传 0
   */
  static async updateProgress(id: number, accMs: number, status: number, completedAt: number): Promise<void> {
    const entry: TaskEntry | null = await TaskDatabase.getById(id);
    if (entry === null) {
      return;
    }
    const now: number = Date.now();
    const updated: TaskEntry = {
      id: entry.id,
      title: entry.title,
      content: entry.content,
      tags: entry.tags,
      priority: entry.priority,
      status: status,
      scheduleType: entry.scheduleType,
      timeNodes: entry.timeNodes,
      currentNodeIndex: entry.currentNodeIndex,
      recurringRule: entry.recurringRule,
      targetDuration: entry.targetDuration,
      accumulatedDuration: accMs,
      reminderType: entry.reminderType,
      reminderOffset: entry.reminderOffset,
      reminderSound: entry.reminderSound,
      reminderMessage: entry.reminderMessage,
      completionType: entry.completionType,
      completedAt: completedAt,
      sourceInboxId: entry.sourceInboxId,
      isPinned: entry.isPinned,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: now,
      reminderId: entry.reminderId,
      startReminderType: entry.startReminderType,
      startReminderMessage: entry.startReminderMessage,
      startReminderId: entry.startReminderId,
    };
    await TaskDatabase.update(updated);
  }

  /**
   * 切换指定任务的置顶状态，并刷新内存缓存。
   * @param id 任务主键
   */
  static async togglePin(id: number): Promise<void> {
    const entry: TaskEntry | null = await TaskDatabase.getById(id);
    if (entry === null) {
      return;
    }
    const now: number = Date.now();
    const updated: TaskEntry = {
      id: entry.id,
      title: entry.title,
      content: entry.content,
      tags: entry.tags,
      priority: entry.priority,
      status: entry.status,
      scheduleType: entry.scheduleType,
      timeNodes: entry.timeNodes,
      currentNodeIndex: entry.currentNodeIndex,
      recurringRule: entry.recurringRule,
      targetDuration: entry.targetDuration,
      accumulatedDuration: entry.accumulatedDuration,
      reminderType: entry.reminderType,
      reminderOffset: entry.reminderOffset,
      reminderSound: entry.reminderSound,
      reminderMessage: entry.reminderMessage,
      completionType: entry.completionType,
      completedAt: entry.completedAt,
      sourceInboxId: entry.sourceInboxId,
      isPinned: entry.isPinned === 1 ? 0 : 1,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: now,
      reminderId: entry.reminderId,
      startReminderType: entry.startReminderType,
      startReminderMessage: entry.startReminderMessage,
      startReminderId: entry.startReminderId,
    };
    await TaskDatabase.update(updated);
    await TaskViewModel.load();
  }

  /**
   * 检查并自动完成所有已逾期的待办任务（PENDING 状态）。
   * IN_PROGRESS 任务由用户自行决定，不强制完成。
   *
   * MULTI_NODE / MULTI_NODE_INTERVAL：必须按 currentNodeIndex 检查当前节点的截止时间，
   * 不能用 getNextDeadline（它动态扫描第一个未来节点，导致中间节点永远不会被认为逾期）。
   *
   * @returns 是否有任务被自动完成（供调用方决定是否刷新视图）
   */
  static async autoCompleteOverdue(): Promise<boolean> {
    const now: number = Date.now();
    const overdueIds: number[] = [];
    for (const task of TaskViewModel.allTasks) {
      if (task.status !== TaskStatus.PENDING) {
        continue;
      }
      let deadline: number = 0;
      if (task.scheduleType === TaskScheduleType.MULTI_NODE) {
        // 多节点：检查当前节点（currentNodeIndex）是否已过期
        const nodes: number[] = parseTimeNodes(task.timeNodes);
        if (task.currentNodeIndex < nodes.length) {
          deadline = nodes[task.currentNodeIndex];
        }
      } else if (task.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL) {
        // 多区间节点：检查当前区间（currentNodeIndex）的结束时间是否已过期
        const intervalNodes: IntervalNode[] = parseIntervalNodes(task.timeNodes);
        if (task.currentNodeIndex < intervalNodes.length) {
          deadline = intervalNodes[task.currentNodeIndex].end;
        }
      } else {
        deadline = getNextDeadline(task);
      }
      if (deadline > 0 && deadline <= now) {
        overdueIds.push(task.id);
      }
    }
    if (overdueIds.length === 0) {
      return false;
    }
    for (const id of overdueIds) {
      // 对多节点任务连续推进，直到当前节点尚未到期（处理 app 离线期间积压的多个逾期节点）
      let keepGoing: boolean = true;
      while (keepGoing) {
        await TaskViewModel.complete(id);
        // complete() 内部调用 load()，重新取最新任务状态
        const matched: TaskEntry[] = TaskViewModel.allTasks.filter((t: TaskEntry) => t.id === id);
        const updated: TaskEntry | null = matched.length > 0 ? matched[0] : null;
        if (updated === null || updated.status !== TaskStatus.PENDING) {
          keepGoing = false;
          continue;
        }
        if (updated.scheduleType === TaskScheduleType.MULTI_NODE) {
          const nodes: number[] = parseTimeNodes(updated.timeNodes);
          const nodeDeadline: number =
            updated.currentNodeIndex < nodes.length ? nodes[updated.currentNodeIndex] : 0;
          keepGoing = nodeDeadline > 0 && nodeDeadline <= now;
        } else if (updated.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL) {
          const iNodes: IntervalNode[] = parseIntervalNodes(updated.timeNodes);
          const nodeDeadline: number =
            updated.currentNodeIndex < iNodes.length ? iNodes[updated.currentNodeIndex].end : 0;
          keepGoing = nodeDeadline > 0 && nodeDeadline <= now;
        } else {
          keepGoing = false;
        }
      }
    }
    return true;
  }

  /** 内部：将当前过滤条件应用到 allTasks，生成 filteredTasks */
  private static applyFilter(): void {
    let result: TaskEntry[] = TaskViewModel.allTasks;

    // 状态过滤（-1 = 所有非归档；>= 0 = 精确匹配指定状态）
    if (TaskViewModel.currentStatus >= 0) {
      result = result.filter((t: TaskEntry) => t.status === TaskViewModel.currentStatus);
    } else {
      // 默认排除已归档任务
      result = result.filter((t: TaskEntry) => t.status !== TaskStatus.ARCHIVED);
    }

    // 关键词过滤（标题/正文/标签任意命中即可）
    const kw: string = TaskViewModel.currentKeyword.trim().toLowerCase();
    if (kw !== '') {
      result = result.filter((t: TaskEntry) => {
        if (t.title.toLowerCase().includes(kw)) {
          return true;
        }
        if (t.content.toLowerCase().includes(kw)) {
          return true;
        }
        // 标签匹配：直接在 JSON 字符串中搜索（避免每次反序列化）
        if (t.tags.toLowerCase().includes(kw)) {
          return true;
        }
        return false;
      });
    }

    // 标签精确过滤
    if (TaskViewModel.currentTag !== '') {
      result = result.filter((t: TaskEntry) => {
        if (t.tags === '') {
          return false;
        }
        try {
          const tags: string[] = parseTags(t.tags);
          return tags.indexOf(TaskViewModel.currentTag) >= 0;
        } catch {
          return false;
        }
      });
    }

    // 已完成任务始终沉底：将 COMPLETED 条目分离至末尾
    const active: TaskEntry[] = result.filter((t: TaskEntry) => t.status !== TaskStatus.COMPLETED);
    const completed: TaskEntry[] = result.filter((t: TaskEntry) => t.status === TaskStatus.COMPLETED);
    TaskViewModel.filteredTasks = active.concat(completed);
  }
}
