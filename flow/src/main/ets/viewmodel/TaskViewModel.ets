/**
 * TaskViewModel.ets
 * 任务模块业务逻辑层。
 * 静态类封装任务列表加载、动态权重排序、关键词/状态过滤、
 * 以及从收集箱条目快速转入任务的工厂方法。
 */
import { TaskDatabase } from '../util/TaskDatabase';
import { TaskEntry, TaskPriority, TaskScheduleType, TaskCompletionType,
  TaskReminderType, TaskStatus, computeTaskWeight } from '../model/TaskEntry';
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
   * 设置关键词与状态过滤条件，刷新 filteredTasks。
   * 不触发 DB 查询，仅在内存中过滤 allTasks。
   * @param keyword  搜索关键词（匹配 title / content / tags），空字符串表示不过滤
   * @param status   状态枚举值，-1 表示显示全部非归档任务
   */
  static filter(keyword: string, status: number): void {
    TaskViewModel.currentKeyword = keyword;
    TaskViewModel.currentStatus = status;
    TaskViewModel.applyFilter();
  }

  /** 内部：将当前过滤条件应用到 allTasks，生成 filteredTasks */
  private static applyFilter(): void {
    let result: TaskEntry[] = TaskViewModel.allTasks;

    // 状态过滤（-1 = 所有非归档）
    if (TaskViewModel.currentStatus >= 0) {
      result = result.filter((t: TaskEntry) => t.status === TaskViewModel.currentStatus);
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

    TaskViewModel.filteredTasks = result;
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
}
