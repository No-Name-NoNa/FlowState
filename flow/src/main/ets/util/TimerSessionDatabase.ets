/**
 * TimerSessionDatabase.ets
 * 计时分段记录 RelationalStore (SQLite) 数据库静态封装。
 *
 * 每次用户启动计时器时插入一条记录（endAt=0），暂停/停止时更新 endAt。
 * 一个任务可关联多条记录，记录断断续续的计时历史。
 * 在 FlowAbility.onCreate() 中调用 init(context) 一次性初始化。
 */
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Context } from '@kit.AbilityKit';
import { LOG_DOMAIN, KEY_HISTORY_NEEDS_REFRESH, TIMER_SESSION_DB_STORE_NAME } from '../constants/AppConstants';
import { TimerSessionEntry } from '../model/TimerSessionEntry';

/** RDB 表名 */
const TABLE_NAME: string = 'timer_sessions';

/** 列名常量 */
const COL_ID: string = 'id';
const COL_TASK_ID: string = 'task_id';
const COL_START_AT: string = 'start_at';
const COL_END_AT: string = 'end_at';

/** 查询时返回的列名列表 */
const ALL_COLUMNS: string[] = [COL_ID, COL_TASK_ID, COL_START_AT, COL_END_AT];

/** 建表 SQL（IF NOT EXISTS 保证幂等） */
const CREATE_TABLE_SQL: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (` +
    `${COL_ID} INTEGER PRIMARY KEY AUTOINCREMENT,` +
    `${COL_TASK_ID} INTEGER NOT NULL,` +
    `${COL_START_AT} INTEGER NOT NULL,` +
    `${COL_END_AT} INTEGER NOT NULL DEFAULT 0` +
    `)`;

/** 计时分段 RDB 数据库封装，所有方法均为静态 */
export class TimerSessionDatabase {
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
    TimerSessionDatabase.initPromise = TimerSessionDatabase.doInit(context);
  }

  /**
   * 插入一条新的计时段记录（endAt=0 表示尚未结束）。
   * @param taskId  关联任务 ID
   * @param startAt 计时段开始时间戳（ms）
   * @returns 新行 ID，失败返回 -1
   */
  static async insertSession(taskId: number, startAt: number): Promise<number> {
    await TimerSessionDatabase.ensureReady();
    if (TimerSessionDatabase.store === null) {
      return -1;
    }
    try {
      const bucket: relationalStore.ValuesBucket = {};
      bucket[COL_TASK_ID] = taskId;
      bucket[COL_START_AT] = startAt;
      bucket[COL_END_AT] = 0;
      return await TimerSessionDatabase.store.insert(TABLE_NAME, bucket);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TimerSessionDatabase',
        'insertSession 失败（taskId=%{public}d）：%{public}s', taskId, JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 关闭一条计时段记录，写入 endAt。
   * @param sessionId 计时段主键 ID
   * @param endAt     计时段结束时间戳（ms）
   */
  static async closeSession(sessionId: number, endAt: number): Promise<void> {
    await TimerSessionDatabase.ensureReady();
    if (TimerSessionDatabase.store === null) {
      return;
    }
    try {
      const bucket: relationalStore.ValuesBucket = {};
      bucket[COL_END_AT] = endAt;
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo(COL_ID, sessionId);
      await TimerSessionDatabase.store.update(bucket, predicates);
      // 专注时段关闭后通知历史页刷新今日专注时长
      AppStorage.setOrCreate(KEY_HISTORY_NEEDS_REFRESH, true);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TimerSessionDatabase',
        'closeSession 失败（sessionId=%{public}d）：%{public}s', sessionId, JSON.stringify(err));
    }
  }

  /**
   * 查询指定任务的所有计时段记录，按 startAt 升序排列。
   * 自动过滤 endAt=0 的未关闭记录（异常残留）。
   * @param taskId 任务 ID
   * @returns 计时段记录数组
   */
  static async queryByTaskId(taskId: number): Promise<TimerSessionEntry[]> {
    await TimerSessionDatabase.ensureReady();
    if (TimerSessionDatabase.store === null) {
      return [];
    }
    const entries: TimerSessionEntry[] = [];
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      // 仅返回已关闭的记录（endAt > 0）
      predicates.equalTo(COL_TASK_ID, taskId).greaterThan(COL_END_AT, 0).orderByAsc(COL_START_AT);
      const rs: relationalStore.ResultSet =
        await TimerSessionDatabase.store.query(predicates, ALL_COLUMNS);
      while (rs.goToNextRow()) {
        entries.push(TimerSessionDatabase.rowToEntry(rs));
      }
      rs.close();
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TimerSessionDatabase',
        'queryByTaskId 失败（taskId=%{public}d）：%{public}s', taskId, JSON.stringify(err));
    }
    return entries;
  }

  /**
   * 统计指定时间段内所有已关闭计时段的累计时长（ms）。
   * 条件：start_at >= fromMs AND start_at < toMs AND end_at > 0
   * @param fromMs 起始时间戳（ms，含）
   * @param toMs   结束时间戳（ms，不含）
   * @returns 时间段内总专注毫秒数
   */
  static async queryFocusTimeInRange(fromMs: number, toMs: number): Promise<number> {
    await TimerSessionDatabase.ensureReady();
    if (TimerSessionDatabase.store === null) {
      return 0;
    }
    let totalMs: number = 0;
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates
        .greaterThanOrEqualTo(COL_START_AT, fromMs)
        .and()
        .lessThan(COL_START_AT, toMs)
        .and()
        .greaterThan(COL_END_AT, 0);
      const rs: relationalStore.ResultSet =
        await TimerSessionDatabase.store.query(predicates, ALL_COLUMNS);
      while (rs.goToNextRow()) {
        const s: number = rs.getLong(rs.getColumnIndex(COL_START_AT));
        const e: number = rs.getLong(rs.getColumnIndex(COL_END_AT));
        totalMs += e - s;
      }
      rs.close();
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TimerSessionDatabase',
        'queryFocusTimeInRange 失败：%{public}s', JSON.stringify(err));
    }
    return totalMs;
  }

  /**
   * 删除指定任务的所有计时段记录（任务删除时调用）。
   * @param taskId 任务 ID
   */
  static async deleteByTaskId(taskId: number): Promise<void> {
    await TimerSessionDatabase.ensureReady();
    if (TimerSessionDatabase.store === null) {
      return;
    }
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.equalTo(COL_TASK_ID, taskId);
      await TimerSessionDatabase.store.delete(predicates);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TimerSessionDatabase',
        'deleteByTaskId 失败（taskId=%{public}d）：%{public}s', taskId, JSON.stringify(err));
    }
  }

  /**
   * 批量删除多个任务的所有计时段记录（批量清理历史时调用）。
   * @param taskIds 任务 ID 数组
   */
  static async deleteByTaskIds(taskIds: number[]): Promise<void> {
    if (taskIds.length === 0) {
      return;
    }
    await TimerSessionDatabase.ensureReady();
    if (TimerSessionDatabase.store === null) {
      return;
    }
    try {
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NAME);
      predicates.in(COL_TASK_ID, taskIds);
      await TimerSessionDatabase.store.delete(predicates);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TimerSessionDatabase',
        'deleteByTaskIds 失败：%{public}s', JSON.stringify(err));
    }
  }

  /** 执行实际初始化：创建/打开 RDB 并建表 */
  private static async doInit(context: Context): Promise<void> {
    try {
      const config: relationalStore.StoreConfig = {
        name: TIMER_SESSION_DB_STORE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1,
      };
      TimerSessionDatabase.store = await relationalStore.getRdbStore(context, config);
      await TimerSessionDatabase.store.executeSql(CREATE_TABLE_SQL);
      hilog.info(LOG_DOMAIN, 'TimerSessionDatabase', '计时分段数据库初始化成功');
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'TimerSessionDatabase', '初始化失败：%{public}s', JSON.stringify(err));
    }
  }

  /** 等待数据库初始化完成 */
  private static async ensureReady(): Promise<void> {
    if (TimerSessionDatabase.initPromise !== null) {
      await TimerSessionDatabase.initPromise;
    }
  }

  /** 将 ResultSet 当前行映射为 TimerSessionEntry */
  private static rowToEntry(rs: relationalStore.ResultSet): TimerSessionEntry {
    return {
      id: rs.getLong(rs.getColumnIndex(COL_ID)),
      taskId: rs.getLong(rs.getColumnIndex(COL_TASK_ID)),
      startAt: rs.getLong(rs.getColumnIndex(COL_START_AT)),
      endAt: rs.getLong(rs.getColumnIndex(COL_END_AT)),
    };
  }
}
