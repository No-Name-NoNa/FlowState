/**
 * StatisticsViewModel.ets
 * 统计/历史页面业务逻辑层。
 *
 * 提供统计数据聚合、归档任务查询、批量清理和任务恢复等操作。
 * 所有方法均为静态。
 */
import { TaskDatabase } from '../util/TaskDatabase';
import { TimerSessionDatabase } from '../util/TimerSessionDatabase';
import { TaskEntry, TaskStatus } from '../model/TaskEntry';
import { NotificationHelper } from '../util/NotificationHelper';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LOG_DOMAIN } from '../constants/AppConstants';
import { HistoryRefreshSignal } from '../util/HistoryRefreshSignal';

/** 统计数据快照 */
export interface StatsSummary {
  /** 指定周期内的归档任务数量 */
  archivedCount: number;

  /** 指定周期内的总专注时长（ms） */
  focusTimeMs: number;
}

/** 时间范围（含起始，不含结束） */
export interface TimeRange {
  /** 起始时间戳（ms，含） */
  from: number;

  /** 结束时间戳（ms，不含） */
  to: number;
}

/** 月份分组：一个月内所有归档任务的摘要 */
export interface MonthGroup {
  /** 年份（4 位整数，例如 2026） */
  year: number;

  /** 月份（1-12） */
  month: number;

  /** 显示标签，例如 "2026年5月" */
  label: string;

  /** 本月归档任务数量 */
  count: number;

  /** 本月起始时间戳（ms，含，即月份第 1 天 00:00:00.000） */
  from: number;

  /** 本月截止时间戳（ms，不含，即下月第 1 天 00:00:00.000） */
  to: number;
}

/** 统计/历史 ViewModel，所有方法均为静态 */
export class StatisticsViewModel {
  /**
   * 获取今日时间范围：当天 00:00:00.000 ~ 23:59:59.999。
   * @returns TimeRange
   */
  static getTodayRange(): TimeRange {
    const now: Date = new Date();
    const from: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
    const to: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
    return { from: from.getTime(), to: to.getTime() + 1 };
  }

  /**
   * 获取本周时间范围：本周一 00:00:00.000 ~ 今天 23:59:59.999。
   * 以周一为每周开始。
   * @returns TimeRange
   */
  static getWeekRange(): TimeRange {
    const now: Date = new Date();
    // 计算本周一：0=周日,1=周一,...,6=周六；若今天是周日（0）则往前 6 天
    const dayOfWeek: number = now.getDay();
    const daysToMonday: number = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    const monday: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - daysToMonday, 0, 0, 0, 0);
    const to: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
    return { from: monday.getTime(), to: to.getTime() + 1 };
  }

  /**
   * 获取本月时间范围：本月 1 日 00:00:00.000 ~ 今天 23:59:59.999。
   * @returns TimeRange
   */
  static getMonthRange(): TimeRange {
    const now: Date = new Date();
    const firstDay: Date = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
    const to: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
    return { from: firstDay.getTime(), to: to.getTime() + 1 };
  }

  /**
   * 获取指定时间范围内的统计数据快照。
   * - archivedCount：updatedAt 在范围内的 ARCHIVED 任务数
   * - focusTimeMs：start_at 在范围内的计时段总时长
   * @param range 时间范围
   * @returns StatsSummary
   */
  static async getStats(range: TimeRange): Promise<StatsSummary> {
    try {
      // 统计归档数量
      const allArchived: TaskEntry[] = await TaskDatabase.queryByStatus(TaskStatus.ARCHIVED);
      let archivedCount: number = 0;
      for (const task of allArchived) {
        if (task.updatedAt >= range.from && task.updatedAt < range.to) {
          archivedCount++;
        }
      }
      // 统计专注时长
      const focusTimeMs: number = await TimerSessionDatabase.queryFocusTimeInRange(range.from, range.to);
      return { archivedCount, focusTimeMs };
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'StatisticsViewModel', 'getStats 失败：%{public}s', JSON.stringify(err));
      return { archivedCount: 0, focusTimeMs: 0 };
    }
  }

  /**
   * 加载全量已归档任务，按 updatedAt 降序排列（最近归档的排前面）。
   * @returns 已归档任务列表
   */
  static async loadArchivedTasks(): Promise<TaskEntry[]> {
    try {
      const tasks: TaskEntry[] = await TaskDatabase.queryByStatus(TaskStatus.ARCHIVED);
      tasks.sort((a: TaskEntry, b: TaskEntry) => b.updatedAt - a.updatedAt);
      return tasks;
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'StatisticsViewModel', 'loadArchivedTasks 失败：%{public}s', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 加载指定时间范围内的已归档任务（按 updatedAt 筛选），按 updatedAt 降序排列。
   * @param from 起始时间戳（ms，含）
   * @param to   截止时间戳（ms，不含）
   * @returns 范围内的已归档任务列表
   */
  static async loadArchivedTasksInRange(from: number, to: number): Promise<TaskEntry[]> {
    try {
      const tasks: TaskEntry[] = await TaskDatabase.queryByStatus(TaskStatus.ARCHIVED);
      const filtered: TaskEntry[] = tasks.filter((t: TaskEntry) => t.updatedAt >= from && t.updatedAt < to);
      filtered.sort((a: TaskEntry, b: TaskEntry) => b.updatedAt - a.updatedAt);
      return filtered;
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'StatisticsViewModel',
        'loadArchivedTasksInRange 失败：%{public}s', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 将全量已归档任务按 updatedAt 字段分组为月份列表，按年月倒序排列。
   * 每个 MonthGroup 包含该月的起止时间戳、任务数量和可显示标签。
   * @returns 月份分组列表，最新的月份在前
   */
  static async loadMonthGroups(): Promise<MonthGroup[]> {
    try {
      const tasks: TaskEntry[] = await TaskDatabase.queryByStatus(TaskStatus.ARCHIVED);
      // 用于记录已出现过的 year*100+month 组合，避免重复
      const seenKeys: number[] = [];
      const groups: MonthGroup[] = [];
      for (const task of tasks) {
        const d: Date = new Date(task.updatedAt);
        const year: number = d.getFullYear();
        const month: number = d.getMonth() + 1; // 1-12
        const key: number = year * 100 + month;
        if (seenKeys.indexOf(key) < 0) {
          seenKeys.push(key);
          const from: number = new Date(year, month - 1, 1, 0, 0, 0, 0).getTime();
          const to: number = new Date(year, month, 1, 0, 0, 0, 0).getTime();
          // 统计本月任务数
          let count: number = 0;
          for (const t of tasks) {
            if (t.updatedAt >= from && t.updatedAt < to) {
              count++;
            }
          }
          groups.push({
            year,
            month,
            label: `${year}年${month}月`,
            count,
            from,
            to
          });
        }
      }
      // 按年月降序（最新在前）
      groups.sort((a: MonthGroup, b: MonthGroup) => {
        if (a.year !== b.year) {
          return b.year - a.year;
        }
        return b.month - a.month;
      });
      return groups;
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'StatisticsViewModel', 'loadMonthGroups 失败：%{public}s', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 删除指定时间范围内（按 updatedAt）的所有已归档任务及其计时分段记录。
   * @param from 起始时间戳（ms，含）
   * @param to   截止时间戳（ms，不含）
   * @returns 实际删除的任务数量
   */
  static async deleteArchivedInRange(from: number, to: number): Promise<number> {
    try {
      const tasks: TaskEntry[] = await TaskDatabase.queryByStatus(TaskStatus.ARCHIVED);
      const ids: number[] = tasks
        .filter((t: TaskEntry) => t.updatedAt >= from && t.updatedAt < to)
        .map((t: TaskEntry) => t.id);
      if (ids.length === 0) {
        return 0;
      }
      await TimerSessionDatabase.deleteByTaskIds(ids);
      await TaskDatabase.deleteByIds(ids);
      return ids.length;
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'StatisticsViewModel',
        'deleteArchivedInRange 失败：%{public}s', JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 将指定归档任务恢复为待办状态。
   * 保留任务的 accumulatedDuration（历史计时记录保留），清零 completedAt。
   * @param id 任务主键
   */
  static async restoreTask(id: number): Promise<void> {
    const entry: TaskEntry | null = await TaskDatabase.getById(id);
    if (entry === null) {
      return;
    }
    const now: number = Date.now();
    const restored: TaskEntry = {
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
      isPinned: 0,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: now,
      reminderId: 0,
      startReminderType: entry.startReminderType,
      startReminderMessage: entry.startReminderMessage,
      startReminderId: 0,
      nodeTargetDurations: entry.nodeTargetDurations,
    };
    await TaskDatabase.update(restored);
    // 恢复后重新注册截止提醒（若有时间节点）
    const reminderId: number = await NotificationHelper.scheduleDeadlineReminder(restored);
    const startReminderId: number = await NotificationHelper.scheduleStartReminder(restored);
    if (reminderId > 0 || startReminderId > 0) {
      await TaskDatabase.updateReminderIds(id, reminderId, startReminderId);
    }
  }

  /**
   * 删除指定归档任务及其所有计时分段记录。
   * @param id 任务主键
   */
  static async deleteArchivedTask(id: number): Promise<void> {
    await TimerSessionDatabase.deleteByTaskId(id);
    await TaskDatabase.delete(id);
  }

  /**
   * 批量删除 updatedAt < beforeMs 的所有归档任务及其计时分段记录。
   * @param beforeMs 截止时间戳（ms），仅删除在此时刻之前归档的任务
   * @returns 实际删除的任务数量
   */
  static async deleteArchivedBefore(beforeMs: number): Promise<number> {
    try {
      const ids: number[] = await TaskDatabase.queryArchivedIdsBefore(beforeMs);
      if (ids.length === 0) {
        return 0;
      }
      await TimerSessionDatabase.deleteByTaskIds(ids);
      await TaskDatabase.deleteByIds(ids);
      // 批量删除后归档数量与专注时长均发生变化，通知历史页刷新
      HistoryRefreshSignal.bump();
      return ids.length;
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'StatisticsViewModel',
        'deleteArchivedBefore 失败：%{public}s', JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 删除全部已归档任务及其所有计时分段记录。
   * @returns 实际删除的任务数量
   */
  static async deleteAllArchived(): Promise<number> {
    try {
      const ids: number[] = await TaskDatabase.queryAllArchivedIds();
      if (ids.length === 0) {
        return 0;
      }
      await TimerSessionDatabase.deleteByTaskIds(ids);
      await TaskDatabase.deleteByIds(ids);
      // 全量删除后归档数量与专注时长均发生变化，通知历史页刷新
      HistoryRefreshSignal.bump();
      return ids.length;
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'StatisticsViewModel', 'deleteAllArchived 失败：%{public}s', JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 将毫秒数格式化为可读的时长字符串。
   * - < 60s：显示 "< 1 分钟"
   * - < 60min：显示 "X 分钟"
   * - >= 60min：显示 "Xh Xm"
   * @param ms 毫秒数
   * @returns 格式化后的时长字符串
   */
  static formatDuration(ms: number): string {
    if (ms <= 0) {
      return '0';
    }
    const totalSec: number = Math.floor(ms / 1000);
    const totalMin: number = Math.floor(totalSec / 60);
    if (totalMin < 1) {
      return '< 1 min';
    }
    if (totalMin < 60) {
      return `${totalMin} min`;
    }
    const hours: number = Math.floor(totalMin / 60);
    const mins: number = totalMin % 60;
    if (mins === 0) {
      return `${hours}h`;
    }
    return `${hours}h ${mins}m`;
  }

  /**
   * 将时间戳格式化为 "YYYY/MM/DD HH:mm" 字符串（本地时间）。
   * @param ms 时间戳（ms），0 时返回空字符串
   * @returns 格式化后的时间字符串
   */
  static formatDateTime(ms: number): string {
    if (ms <= 0) {
      return '';
    }
    const d: Date = new Date(ms);
    const year: number = d.getFullYear();
    const month: string = String(d.getMonth() + 1).padStart(2, '0');
    const day: string = String(d.getDate()).padStart(2, '0');
    const hour: string = String(d.getHours()).padStart(2, '0');
    const min: string = String(d.getMinutes()).padStart(2, '0');
    return `${year}/${month}/${day} ${hour}:${min}`;
  }

  /**
   * 将时间戳格式化为 "MM/DD HH:mm" 字符串（省略年份，用于计时记录列表）。
   * @param ms 时间戳（ms）
   * @returns 格式化后的时间字符串
   */
  static formatShortTime(ms: number): string {
    if (ms <= 0) {
      return '--';
    }
    const d: Date = new Date(ms);
    const month: string = String(d.getMonth() + 1).padStart(2, '0');
    const day: string = String(d.getDate()).padStart(2, '0');
    const hour: string = String(d.getHours()).padStart(2, '0');
    const min: string = String(d.getMinutes()).padStart(2, '0');
    return `${month}/${day} ${hour}:${min}`;
  }
}
