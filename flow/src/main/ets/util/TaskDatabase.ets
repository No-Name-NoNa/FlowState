/**
 * TaskDatabase.ets
 * 任务模块 RelationalStore (SQLite) 数据库静态封装。
 * 在 FlowAbility.onCreate() 中调用 init(context) 一次性初始化，
 * 其余 CRUD 方法通过 ensureReady() 等待初始化完成后再执行。
 * 设计模式同 InboxDatabase，保持项目一致性。
 */
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Context } from '@kit.AbilityKit';
import { LOG_DOMAIN, TASK_DB_STORE_NAME } from '../constants/AppConstants';
import { TaskEntry, TaskStatus } from '../model/TaskEntry';

/** RDB 表名 */
const TABLE_NAME: string = 'task_entries';

/** 列名常量 */
const COL_ID: string = 'id';
const COL_TITLE: string = 'title';
const COL_CONTENT: string = 'content';
const COL_TAGS: string = 'tags';
const COL_PRIORITY: string = 'priority';
const COL_STATUS: string = 'status';
const COL_SCHEDULE_TYPE: string = 'schedule_type';
const COL_TIME_NODES: string = 'time_nodes';
const COL_CURRENT_NODE_INDEX: string = 'current_node_index';
const COL_RECURRING_RULE: string = 'recurring_rule';
const COL_TARGET_DURATION: string = 'target_duration';
const COL_ACCUMULATED_DURATION: string = 'accumulated_duration';
const COL_REMINDER_TYPE: string = 'reminder_type';
const COL_REMINDER_OFFSET: string = 'reminder_offset';
const COL_COMPLETION_TYPE: string = 'completion_type';
const COL_COMPLETED_AT: string = 'completed_at';
const COL_SOURCE_INBOX_ID: string = 'source_inbox_id';
const COL_SORT_ORDER: string = 'sort_order';
const COL_CREATED_AT: string = 'created_at';
const COL_UPDATED_AT: string = 'updated_at';

/** 查询时返回的列名列表 */
const ALL_COLUMNS: string[] = [
  COL_ID, COL_TITLE, COL_CONTENT, COL_TAGS,
  COL_PRIORITY, COL_STATUS,
  COL_SCHEDULE_TYPE, COL_TIME_NODES, COL_CURRENT_NODE_INDEX, COL_RECURRING_RULE,
  COL_TARGET_DURATION, COL_ACCUMULATED_DURATION,
  COL_REMINDER_TYPE, COL_REMINDER_OFFSET,
  COL_COMPLETION_TYPE, COL_COMPLETED_AT,
  COL_SOURCE_INBOX_ID, COL_SORT_ORDER,
  COL_CREATED_AT, COL_UPDATED_AT,
];

/** 建表 SQL（IF NOT EXISTS 保证幂等） */
const CREATE_TABLE_SQL: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (` +
    `${COL_ID} INTEGER PRIMARY KEY AUTOINCREMENT,` +
    `${COL_TITLE} TEXT NOT NULL,` +
    `${COL_CONTENT} TEXT NOT NULL DEFAULT '',` +
    `${COL_TAGS} TEXT NOT NULL DEFAULT '',` +
    `${COL_PRIORITY} INTEGER NOT NULL DEFAULT 1,` +
    `${COL_STATUS} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_SCHEDULE_TYPE} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_TIME_NODES} TEXT NOT NULL DEFAULT '',` +
    `${COL_CURRENT_NODE_INDEX} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_RECURRING_RULE} TEXT NOT NULL DEFAULT '',` +
    `${COL_TARGET_DURATION} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_ACCUMULATED_DURATION} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_REMINDER_TYPE} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_REMINDER_OFFSET} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_COMPLETION_TYPE} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_COMPLETED_AT} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_SOURCE_INBOX_ID} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_SORT_ORDER} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_CREATED_AT} INTEGER NOT NULL,` +
    `${COL_UPDATED_AT} INTEGER NOT NULL` +
    `)`;

/** 任务 RDB 数据库封装，所有方法均为静态 */
export class TaskDatabase {
  /** RDB 实例 */
  private static store: relationalStore.RdbStore | null = null;
  /** 初始化 Promise，供 ensureReady() 等待 */
  private static initPromise: Promise<void> | null = null;

  /**
   * 初始化数据库，在 FlowAbility.onCreate() 中调用一次。
   * 异步执行，不阻塞启动流程。
   * @param context UIAbility 上下文
   */
  static init(context: Context): void {
    TaskDatabase.initPromise = TaskDatabase.doInit(context);
  }

  /** 执行实际初始化：创建/打开 RDB 并建表 */
  private static async doInit(context: Context): Promise<void> {
    try {
      const config: relationalStore.StoreConfig = {
        name: TASK_DB_STORE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
      };
      TaskDatabase.store = await relationalStore.getRdbStore(context, config);
      await TaskDatabase.store.executeSql(CREATE_TABLE_SQL);
      hilog.info(LOG_DOMAIN, 'TaskDatabase', '数据库初始化成功');
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TaskDatabase', '初始化失败：%{public}s', JSON.stringify(err));
    }
  }

  /** 等待数据库初始化完成，保证后续操作在 store 就绪后执行 */
  private static async ensureReady(): Promise<void> {
    if (TaskDatabase.initPromise !== null) {
      await TaskDatabase.initPromise;
    }
  }

  /** 将 ResultSet 当前行映射为 TaskEntry 对象 */
  private static rowToEntry(rs: relationalStore.ResultSet): TaskEntry {
    return {
      id: rs.getLong(rs.getColumnIndex(COL_ID)),
      title: rs.getString(rs.getColumnIndex(COL_TITLE)),
      content: rs.getString(rs.getColumnIndex(COL_CONTENT)),
      tags: rs.getString(rs.getColumnIndex(COL_TAGS)),
      priority: rs.getLong(rs.getColumnIndex(COL_PRIORITY)),
      status: rs.getLong(rs.getColumnIndex(COL_STATUS)),
      scheduleType: rs.getLong(rs.getColumnIndex(COL_SCHEDULE_TYPE)),
      timeNodes: rs.getString(rs.getColumnIndex(COL_TIME_NODES)),
      currentNodeIndex: rs.getLong(rs.getColumnIndex(COL_CURRENT_NODE_INDEX)),
      recurringRule: rs.getString(rs.getColumnIndex(COL_RECURRING_RULE)),
      targetDuration: rs.getLong(rs.getColumnIndex(COL_TARGET_DURATION)),
      accumulatedDuration: rs.getLong(rs.getColumnIndex(COL_ACCUMULATED_DURATION)),
      reminderType: rs.getLong(rs.getColumnIndex(COL_REMINDER_TYPE)),
      reminderOffset: rs.getLong(rs.getColumnIndex(COL_REMINDER_OFFSET)),
      completionType: rs.getLong(rs.getColumnIndex(COL_COMPLETION_TYPE)),
      completedAt: rs.getLong(rs.getColumnIndex(COL_COMPLETED_AT)),
      sourceInboxId: rs.getLong(rs.getColumnIndex(COL_SOURCE_INBOX_ID)),
      sortOrder: rs.getLong(rs.getColumnIndex(COL_SORT_ORDER)),
      createdAt: rs.getLong(rs.getColumnIndex(COL_CREATED_AT)),
      updatedAt: rs.getLong(rs.getColumnIndex(COL_UPDATED_AT)),
    };
  }

  /**
   * 查询全部未归档任务，按 sortOrder 升序排列。
   * ViewModel 层负责按动态权重二次排序。
   * @returns 任务数组
   */
  static async queryAll(): Promise<TaskEntry[]> {
    await TaskDatabase.ensureReady();
    if (TaskDatabase.store === null) {
      return [];
    }
    const entries: TaskEntry[] = [];
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.notEqualTo(COL_STATUS, TaskStatus.ARCHIVED).orderByAsc(COL_SORT_ORDER);
      const rs: relationalStore.ResultSet = await TaskDatabase.store.query(predicates, ALL_COLUMNS);
      while (rs.goToNextRow()) {
        entries.push(TaskDatabase.rowToEntry(rs));
      }
      rs.close();
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TaskDatabase', 'queryAll 失败：%{public}s', JSON.stringify(err));
    }
    return entries;
  }

  /**
   * 按状态过滤查询任务。
   * @param status 目标状态（TaskStatus 枚举值）
   * @returns 对应状态的任务数组
   */
  static async queryByStatus(status: number): Promise<TaskEntry[]> {
    await TaskDatabase.ensureReady();
    if (TaskDatabase.store === null) {
      return [];
    }
    const entries: TaskEntry[] = [];
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo(COL_STATUS, status).orderByAsc(COL_SORT_ORDER);
      const rs: relationalStore.ResultSet = await TaskDatabase.store.query(predicates, ALL_COLUMNS);
      while (rs.goToNextRow()) {
        entries.push(TaskDatabase.rowToEntry(rs));
      }
      rs.close();
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TaskDatabase',
        'queryByStatus 失败（status=%{public}d）：%{public}s', status, JSON.stringify(err));
    }
    return entries;
  }

  /**
   * 根据 ID 查询单条任务。
   * @param id 任务主键
   * @returns 找到时返回 TaskEntry，否则返回 null
   */
  static async getById(id: number): Promise<TaskEntry | null> {
    await TaskDatabase.ensureReady();
    if (TaskDatabase.store === null) {
      return null;
    }
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo(COL_ID, id);
      const rs: relationalStore.ResultSet = await TaskDatabase.store.query(predicates, ALL_COLUMNS);
      if (rs.goToFirstRow()) {
        const entry: TaskEntry = TaskDatabase.rowToEntry(rs);
        rs.close();
        return entry;
      }
      rs.close();
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TaskDatabase', 'getById 失败（id=%{public}d）：%{public}s',
        id, JSON.stringify(err));
    }
    return null;
  }

  /**
   * 插入新任务，id 字段由 DB AUTOINCREMENT 自动生成（传入值被忽略）。
   * @param entry 任务数据
   * @returns 新行 ID，失败返回 -1
   */
  static async insert(entry: TaskEntry): Promise<number> {
    await TaskDatabase.ensureReady();
    if (TaskDatabase.store === null) {
      return -1;
    }
    try {
      const bucket: relationalStore.ValuesBucket = {};
      bucket[COL_TITLE] = entry.title;
      bucket[COL_CONTENT] = entry.content;
      bucket[COL_TAGS] = entry.tags;
      bucket[COL_PRIORITY] = entry.priority;
      bucket[COL_STATUS] = entry.status;
      bucket[COL_SCHEDULE_TYPE] = entry.scheduleType;
      bucket[COL_TIME_NODES] = entry.timeNodes;
      bucket[COL_CURRENT_NODE_INDEX] = entry.currentNodeIndex;
      bucket[COL_RECURRING_RULE] = entry.recurringRule;
      bucket[COL_TARGET_DURATION] = entry.targetDuration;
      bucket[COL_ACCUMULATED_DURATION] = entry.accumulatedDuration;
      bucket[COL_REMINDER_TYPE] = entry.reminderType;
      bucket[COL_REMINDER_OFFSET] = entry.reminderOffset;
      bucket[COL_COMPLETION_TYPE] = entry.completionType;
      bucket[COL_COMPLETED_AT] = entry.completedAt;
      bucket[COL_SOURCE_INBOX_ID] = entry.sourceInboxId;
      bucket[COL_SORT_ORDER] = entry.sortOrder;
      bucket[COL_CREATED_AT] = entry.createdAt;
      bucket[COL_UPDATED_AT] = entry.updatedAt;
      return await TaskDatabase.store.insert(TABLE_NAME, bucket);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TaskDatabase', 'insert 失败：%{public}s', JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 更新已有任务的全部可编辑字段。
   * @param entry 含有效 id 的完整任务条目
   */
  static async update(entry: TaskEntry): Promise<void> {
    await TaskDatabase.ensureReady();
    if (TaskDatabase.store === null) {
      return;
    }
    try {
      const bucket: relationalStore.ValuesBucket = {};
      bucket[COL_TITLE] = entry.title;
      bucket[COL_CONTENT] = entry.content;
      bucket[COL_TAGS] = entry.tags;
      bucket[COL_PRIORITY] = entry.priority;
      bucket[COL_STATUS] = entry.status;
      bucket[COL_SCHEDULE_TYPE] = entry.scheduleType;
      bucket[COL_TIME_NODES] = entry.timeNodes;
      bucket[COL_CURRENT_NODE_INDEX] = entry.currentNodeIndex;
      bucket[COL_RECURRING_RULE] = entry.recurringRule;
      bucket[COL_TARGET_DURATION] = entry.targetDuration;
      bucket[COL_ACCUMULATED_DURATION] = entry.accumulatedDuration;
      bucket[COL_REMINDER_TYPE] = entry.reminderType;
      bucket[COL_REMINDER_OFFSET] = entry.reminderOffset;
      bucket[COL_COMPLETION_TYPE] = entry.completionType;
      bucket[COL_COMPLETED_AT] = entry.completedAt;
      bucket[COL_SOURCE_INBOX_ID] = entry.sourceInboxId;
      bucket[COL_SORT_ORDER] = entry.sortOrder;
      bucket[COL_CREATED_AT] = entry.createdAt;
      bucket[COL_UPDATED_AT] = entry.updatedAt;
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo(COL_ID, entry.id);
      await TaskDatabase.store.update(bucket, predicates);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TaskDatabase', 'update 失败（id=%{public}d）：%{public}s',
        entry.id, JSON.stringify(err));
    }
  }

  /**
   * 删除指定 ID 的任务。
   * @param id 任务主键
   */
  static async delete(id: number): Promise<void> {
    await TaskDatabase.ensureReady();
    if (TaskDatabase.store === null) {
      return;
    }
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo(COL_ID, id);
      await TaskDatabase.store.delete(predicates);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TaskDatabase', 'delete 失败（id=%{public}d）：%{public}s',
        id, JSON.stringify(err));
    }
  }
}
