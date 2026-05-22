/**
 * TimerSessionEntry.ets
 * 计时分段记录数据模型。
 *
 * 每次用户在 TaskDetailPage 或 TimerPage 启动计时器，都会在 timer_sessions 表中
 * 插入一条新记录（startAt）；暂停或停止时写入 endAt。
 * 一个任务可有多条记录，支持断断续续的计时场景。
 */

/** 计时分段条目 */
export interface TimerSessionEntry {
  /** 数据库自增主键，新建时传 0 */
  id: number;

  /** 关联的任务 ID（对应 task_entries.id） */
  taskId: number;

  /** 本段计时的开始时间戳（ms） */
  startAt: number;

  /**
   * 本段计时的结束时间戳（ms）。
   * 0 表示该计时段尚未关闭（应用异常退出时可能残留，读取时忽略）。
   */
  endAt: number;
}
