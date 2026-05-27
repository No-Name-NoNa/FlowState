/**
 * InboxDatabase.ets
 * 收集箱 RelationalStore (SQLite) 数据库静态封装。
 * 在 FlowAbility.onCreate() 中调用 init(context) 一次性初始化，
 * 其余 CRUD 方法通过 ensureReady() 等待初始化完成后再执行。
 */
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Context } from '@kit.AbilityKit';
import { INBOX_DB_STORE_NAME, LOG_DOMAIN } from '../constants/AppConstants';
import { InboxEntry } from '../model/InboxEntry';

/** RDB 表名 */
const TABLE_NAME: string = 'inbox_entries';

/** 列名常量 */
const COL_ID: string = 'id';
const COL_TEXT: string = 'text';
const COL_CONTENT: string = 'content';
const COL_TAGS: string = 'tags';
const COL_SORT_ORDER: string = 'sort_order';
const COL_IS_PINNED: string = 'is_pinned';
const COL_CREATED_AT: string = 'created_at';
const COL_UPDATED_AT: string = 'updated_at';

/** 查询时返回的列名列表 */
const ALL_COLUMNS: string[] = [
  COL_ID, COL_TEXT, COL_CONTENT, COL_TAGS,
  COL_SORT_ORDER, COL_IS_PINNED,
  COL_CREATED_AT, COL_UPDATED_AT,
];

/** 建表 SQL（IF NOT EXISTS 保证幂等） */
const CREATE_TABLE_SQL: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (` +
    `${COL_ID} INTEGER PRIMARY KEY AUTOINCREMENT,` +
    `${COL_TEXT} TEXT NOT NULL,` +
    `${COL_CONTENT} TEXT NOT NULL DEFAULT '',` +
    `${COL_TAGS} TEXT NOT NULL DEFAULT '',` +
    `${COL_SORT_ORDER} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_IS_PINNED} INTEGER NOT NULL DEFAULT 0,` +
    `${COL_CREATED_AT} INTEGER NOT NULL,` +
    `${COL_UPDATED_AT} INTEGER NOT NULL` +
    `)`;

/** 收集箱 RDB 数据库封装，所有方法均为静态 */
export class InboxDatabase {
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
    InboxDatabase.initPromise = InboxDatabase.doInit(context);
  }

  /**
   * 查询全部条目，置顶优先（DESC）、sortOrder 升序（ASC）。
   * @returns 排序后的条目数组
   */
  static async queryAll(): Promise<InboxEntry[]> {
    await InboxDatabase.ensureReady();
    if (InboxDatabase.store === null) {
      return [];
    }
    const entries: InboxEntry[] = [];
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.orderByDesc(COL_IS_PINNED).orderByAsc(COL_SORT_ORDER);
      const rs: relationalStore.ResultSet = await InboxDatabase.store.query(predicates, ALL_COLUMNS);
      while (rs.goToNextRow()) {
        entries.push(InboxDatabase.rowToEntry(rs));
      }
      rs.close();
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'InboxDatabase', 'queryAll 失败：%{public}s', JSON.stringify(err));
    }
    return entries;
  }

  /**
   * 根据 ID 查询单条目。
   * @param id 条目主键
   * @returns 找到时返回 InboxEntry，否则返回 null
   */
  static async getById(id: number): Promise<InboxEntry | null> {
    await InboxDatabase.ensureReady();
    if (InboxDatabase.store === null) {
      return null;
    }
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo(COL_ID, id);
      const rs: relationalStore.ResultSet = await InboxDatabase.store.query(predicates, ALL_COLUMNS);
      if (rs.goToFirstRow()) {
        const entry: InboxEntry = InboxDatabase.rowToEntry(rs);
        rs.close();
        return entry;
      }
      rs.close();
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'InboxDatabase', 'getById 失败（id=%{public}d）：%{public}s',
        id, JSON.stringify(err));
    }
    return null;
  }

  /**
   * 插入新条目，id 字段由 DB AUTOINCREMENT 自动生成（传入值被忽略）。
   * @param entry 条目数据
   * @returns 新行 ID，失败返回 -1
   */
  static async insert(entry: InboxEntry): Promise<number> {
    await InboxDatabase.ensureReady();
    if (InboxDatabase.store === null) {
      return -1;
    }
    try {
      const bucket: relationalStore.ValuesBucket = {};
      bucket['text'] = entry.text;
      bucket['content'] = entry.content;
      bucket['tags'] = entry.tags;
      bucket['sort_order'] = entry.sortOrder;
      bucket['is_pinned'] = entry.isPinned;
      bucket['created_at'] = entry.createdAt;
      bucket['updated_at'] = entry.updatedAt;
      return await InboxDatabase.store.insert(TABLE_NAME, bucket);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'InboxDatabase', 'insert 失败：%{public}s', JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 更新已有条目的全部可编辑字段。
   * @param entry 含有效 id 的完整条目
   */
  static async update(entry: InboxEntry): Promise<void> {
    await InboxDatabase.ensureReady();
    if (InboxDatabase.store === null) {
      return;
    }
    try {
      const bucket: relationalStore.ValuesBucket = {};
      bucket['text'] = entry.text;
      bucket['content'] = entry.content;
      bucket['tags'] = entry.tags;
      bucket['sort_order'] = entry.sortOrder;
      bucket['is_pinned'] = entry.isPinned;
      bucket['created_at'] = entry.createdAt;
      bucket['updated_at'] = entry.updatedAt;
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo(COL_ID, entry.id);
      await InboxDatabase.store.update(bucket, predicates);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'InboxDatabase', 'update 失败（id=%{public}d）：%{public}s',
        entry.id, JSON.stringify(err));
    }
  }

  /**
   * 删除指定 ID 的条目。
   * @param id 条目主键
   */
  static async delete(id: number): Promise<void> {
    await InboxDatabase.ensureReady();
    if (InboxDatabase.store === null) {
      return;
    }
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo(COL_ID, id);
      await InboxDatabase.store.delete(predicates);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'InboxDatabase', 'delete 失败（id=%{public}d）：%{public}s',
        id, JSON.stringify(err));
    }
  }

  /**
   * 批量更新条目的 sortOrder（拖拽排序后调用）。
   * 以 entries 在数组中的位置（0-indexed）作为新的 sortOrder。
   * @param entries 按新顺序排列的条目数组
   */
  static async updateOrder(entries: InboxEntry[]): Promise<void> {
    await InboxDatabase.ensureReady();
    if (InboxDatabase.store === null) {
      return;
    }
    for (let i: number = 0; i < entries.length; i++) {
      try {
        const bucket: relationalStore.ValuesBucket = {};
        bucket['sort_order'] = i;
        const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
        predicates.equalTo(COL_ID, entries[i].id);
        await InboxDatabase.store.update(bucket, predicates);
      } catch (err) {
        hilog.error(LOG_DOMAIN, 'InboxDatabase',
          '批量更新顺序失败（id=%{public}d）：%{public}s', entries[i].id, JSON.stringify(err));
      }
    }
  }

  /**
   * 删除全部条目（调试用途）。
   */
  static async deleteAll(): Promise<void> {
    await InboxDatabase.ensureReady();
    if (InboxDatabase.store === null) {
      return;
    }
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.greaterThan(COL_ID, 0);
      await InboxDatabase.store.delete(predicates);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'InboxDatabase', 'deleteAll 失败：%{public}s', JSON.stringify(err));
    }
  }

  /** 执行实际初始化：创建/打开 RDB 并建表 */
  private static async doInit(context: Context): Promise<void> {
    try {
      const config: relationalStore.StoreConfig = {
        name: INBOX_DB_STORE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
      };
      InboxDatabase.store = await relationalStore.getRdbStore(context, config);
      await InboxDatabase.store.executeSql(CREATE_TABLE_SQL);
      hilog.info(LOG_DOMAIN, 'InboxDatabase', '数据库初始化成功');
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'InboxDatabase', '初始化失败：%{public}s', JSON.stringify(err));
    }
  }

  /** 等待数据库初始化完成，保证后续操作在 store 就绪后执行 */
  private static async ensureReady(): Promise<void> {
    if (InboxDatabase.initPromise !== null) {
      await InboxDatabase.initPromise;
    }
  }

  /** 将 ResultSet 当前行映射为 InboxEntry 对象 */
  private static rowToEntry(rs: relationalStore.ResultSet): InboxEntry {
    return {
      id: rs.getLong(rs.getColumnIndex(COL_ID)),
      text: rs.getString(rs.getColumnIndex(COL_TEXT)),
      content: rs.getString(rs.getColumnIndex(COL_CONTENT)),
      tags: rs.getString(rs.getColumnIndex(COL_TAGS)),
      sortOrder: rs.getLong(rs.getColumnIndex(COL_SORT_ORDER)),
      isPinned: rs.getLong(rs.getColumnIndex(COL_IS_PINNED)),
      createdAt: rs.getLong(rs.getColumnIndex(COL_CREATED_AT)),
      updatedAt: rs.getLong(rs.getColumnIndex(COL_UPDATED_AT)),
    };
  }
}
