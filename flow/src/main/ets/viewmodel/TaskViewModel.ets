/**
 * TaskViewModel.ets
 * 任务模块业务逻辑层。
 * 静态类封装任务列表加载、动态权重排序、关键词/状态过滤、
 * 以及从收集箱条目快速转入任务的工厂方法。
 */
import { TaskDatabase } from '../util/TaskDatabase';
import {
  computeTaskWeight,
  TaskCompletionType,
  TaskEntry,
  TaskPriority,
  TaskReminderType,
  TaskScheduleType,
  TaskStatus
} from '../model/TaskEntry';
import { InboxEntry, parseTags } from '../model/InboxEntry';

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

  /**
   * 从 DB 重新加载全部任务并按动态权重排序。
   * 调用方在 Promise 完成后需同步读取 filteredTasks 刷新视图。
   */
  static async load(): Promise<void> {
    const tasks: TaskEntry[] = await TaskDatabase.queryAll();
    // 按动态权重降序排序，同权重按创建时间升序（稳定排序）
    tasks.sort((a: TaskEntry, b: TaskEntry) => {
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
      completionType: TaskCompletionType.MANUAL,
      completedAt: 0,
      sourceInboxId: inbox.id,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    };
  }

  /**
   * 将新任务写入 DB 并刷新内存缓存。
   * @param entry id=0 的任务草稿
   * @returns 新行 ID，失败返回 -1
   */
  static async create(entry: TaskEntry): Promise<number> {
    const newId: number = await TaskDatabase.insert(entry);
    if (newId > 0) {
      await TaskViewModel.load();
    }
    return newId;
  }

  /**
   * 更新任务并刷新内存缓存。
   * @param entry 含有效 id 的完整任务条目
   */
  static async update(entry: TaskEntry): Promise<void> {
    await TaskDatabase.update(entry);
    await TaskViewModel.load();
  }

  /**
   * 删除任务并刷新内存缓存。
   * @param id 任务主键
   */
  static async remove(id: number): Promise<void> {
    await TaskDatabase.delete(id);
    await TaskViewModel.load();
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
   * 将指定任务标记为已完成，并刷新内存缓存。
   * @param id 任务主键
   */
  static async complete(id: number): Promise<void> {
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
      status: TaskStatus.COMPLETED,
      scheduleType: entry.scheduleType,
      timeNodes: entry.timeNodes,
      currentNodeIndex: entry.currentNodeIndex,
      recurringRule: entry.recurringRule,
      targetDuration: entry.targetDuration,
      accumulatedDuration: entry.accumulatedDuration,
      reminderType: entry.reminderType,
      reminderOffset: entry.reminderOffset,
      completionType: entry.completionType,
      completedAt: now,
      sourceInboxId: entry.sourceInboxId,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: now,
    };
    await TaskDatabase.update(updated);
    await TaskViewModel.load();
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
      completionType: entry.completionType,
      completedAt: 0,
      sourceInboxId: entry.sourceInboxId,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: now,
    };
    await TaskDatabase.update(updated);
    await TaskViewModel.load();
  }

  /**
   * 将指定任务标记为归档，不再在任务列表显示，可在历史页查看。
   * @param id 任务主键
   */
  static async archive(id: number): Promise<void> {
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
      status: TaskStatus.ARCHIVED,
      scheduleType: entry.scheduleType,
      timeNodes: entry.timeNodes,
      currentNodeIndex: entry.currentNodeIndex,
      recurringRule: entry.recurringRule,
      targetDuration: entry.targetDuration,
      accumulatedDuration: entry.accumulatedDuration,
      reminderType: entry.reminderType,
      reminderOffset: entry.reminderOffset,
      completionType: entry.completionType,
      completedAt: 0,
      sourceInboxId: entry.sourceInboxId,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: now,
    };
    await TaskDatabase.update(updated);
    await TaskViewModel.load();
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
      completionType: entry.completionType,
      completedAt: completedAt,
      sourceInboxId: entry.sourceInboxId,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: now,
    };
    await TaskDatabase.update(updated);
  }
}
