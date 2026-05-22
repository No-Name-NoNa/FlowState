/**
 * TaskEntry.ets
 * 任务模块数据模型、枚举、循环规则及工具函数。
 *
 * 设计要点：
 *  - 所有任务共用同一 TaskEntry 结构（PRD「统一任务执行引擎」）
 *  - 时间系统采用「节点数组」架构，三种调度模式（单次/多节点/循环）共享同一张表
 *  - JSON 序列化字段（tags/timeNodes/recurringRule）用空字符串表示"无值"
 *  - 动态权重（urgencyScore + priorityScore）在 ViewModel 层计算，不持久化到 DB
 */

// ── 枚举定义 ──────────────────────────────────────────────────────────────────

/** 任务优先级 */
export const enum TaskPriority {
  /** 低优先级 */
  LOW = 0,
  /** 普通优先级（默认） */
  NORMAL = 1,
  /** 高优先级 */
  HIGH = 2,
  /** 紧急 */
  URGENT = 3,
}

/** 任务状态 */
export const enum TaskStatus {
  /** 待办（未开始） */
  PENDING = 0,
  /** 进行中（计时器运行中） */
  IN_PROGRESS = 1,
  /** 已完成 */
  COMPLETED = 2,
  /** 已归档（不在主列表显示） */
  ARCHIVED = 3,
}

/** 任务时间调度类型 */
export const enum TaskScheduleType {
  /** 无时间安排 */
  NONE = 0,
  /** 单次截止时间，timeNodes = number[]（1 个元素） */
  SINGLE = 1,
  /** 多节点自定义日期（如 1/10、2/5 等不规则日期），timeNodes = number[]（多个元素） */
  MULTI_NODE = 2,
  /** 规则循环（绝对/相对），timeNodes = number[]（1 个元素，表示当前周期触发时刻） */
  RECURRING = 3,
  /** 单次区间：有开始时间和截止时间，timeNodes = IntervalNode[]（1 个元素） */
  INTERVAL = 4,
  /** 多节点区间：多个 [开始, 结束] 对，timeNodes = IntervalNode[]（多个元素） */
  MULTI_NODE_INTERVAL = 5,
}

/** 任务完成方式 */
export const enum TaskCompletionType {
  /** 手动完成（一键标记，忽略计时器） */
  MANUAL = 0,
  /** 累计时长达标后自动完成 */
  DURATION = 1,
  /** 到达时间节点时自动结算 */
  NODE = 2,
}

/** 提醒类型 */
export const enum TaskReminderType {
  /** 无提醒 */
  NONE = 0,
  /** 只弹消息提醒：静默通知，无声音/震动 */
  POPUP = 1,
  /** 带音效的提醒：通知 + 系统音效 */
  SOUND = 2,
}

/** 循环规则类型 */
export const enum RecurringType {
  /** 相对循环：上次完成后 n 天重新生效 */
  RELATIVE = 0,
  /** 绝对循环：每天 */
  DAILY = 1,
  /** 绝对循环：每周特定星期几（可多选） */
  WEEKLY = 2,
  /** 绝对循环：每月特定日期 */
  MONTHLY = 3,
}

// ── 接口定义 ──────────────────────────────────────────────────────────────────

/**
 * 区间节点对象。
 * 用于 INTERVAL / MULTI_NODE_INTERVAL 类型任务，序列化为 JSON 数组存入 TaskEntry.timeNodes。
 */
export interface IntervalNode {
  /** 区间开始时间戳（ms） */
  start: number;

  /** 区间结束时间戳（ms） */
  end: number;
}

/**
 * 循环规则对象。
 * 序列化为 JSON 字符串存入 TaskEntry.recurringRule 字段。
 */
export interface RecurringRule {
  /** 循环类型，取值 RecurringType */
  type: number;

  /**
   * RELATIVE 模式专用：上次完成后间隔天数（>0）。
   * 其他模式此字段填 0。
   */
  intervalDays: number;

  /**
   * WEEKLY 模式专用：需执行的星期几列表。
   * 0=周日, 1=周一, ..., 6=周六；可多选，如 [1,3,5] 表示每周一三五。
   * 非 WEEKLY 模式此字段填空数组。
   */
  daysOfWeek: number[];

  /**
   * MONTHLY 模式专用：每月执行的日期（1-31）。
   * 非 MONTHLY 模式此字段填 0。
   */
  dayOfMonth: number;
}

/** 任务条目核心数据结构 */
export interface TaskEntry {
  /** 数据库自增主键，新建时传 0 */
  id: number;

  /** 任务标题（必填，单行） */
  title: string;

  /** 任务详情描述（可选，多行，空字符串表示无） */
  content: string;

  /** 标签列表，JSON 字符串存储，格式同 InboxEntry.tags */
  tags: string;

  /** 优先级，取值 TaskPriority */
  priority: number;

  /** 状态，取值 TaskStatus */
  status: number;

  // ── 时间调度 ───────────────────────────────────────────────────────────────

  /** 调度类型，取值 TaskScheduleType */
  scheduleType: number;

  /**
   * 时间节点数组，JSON 序列化的 number[]（时间戳 ms）。
   * - SINGLE：仅含 1 个元素（截止时刻）
   * - MULTI_NODE：多个不规则时刻，按时间升序排列
   * - RECURRING：当前周期的触发时刻（1 个元素，每次完成后重新计算写入）
   * - NONE：空字符串 ''
   */
  timeNodes: string;

  /**
   * 当前活跃节点的索引（0-based）。
   * - MULTI_NODE：完成当前节点后递增，指向下一节点
   * - RECURRING：固定为 0（每次完成后重置 timeNodes[0] 为下一周期时刻）
   * - SINGLE/NONE：固定为 0
   */
  currentNodeIndex: number;

  /**
   * 循环规则，JSON 序列化的 RecurringRule 对象。
   * scheduleType !== RECURRING 时为空字符串 ''。
   */
  recurringRule: string;

  // ── 执行时长 ───────────────────────────────────────────────────────────────

  /** 目标专注时长（分钟），0 表示无时长目标 */
  targetDuration: number;

  /** 已累计专注时长（毫秒），计时器运行时实时更新 */
  accumulatedDuration: number;

  // ── 提醒 ───────────────────────────────────────────────────────────────────

  /** 提醒类型，取值 TaskReminderType */
  reminderType: number;

  /** 提前提醒时间（分钟），0 表示在节点时刻精确提醒 */
  reminderOffset: number;

  /**
   * 该任务专属的提醒音效标识符。
   * '' = 跟随全局默认；'default' = 系统默认；其他值为预设音效 ID（chime/bell/ping）。
   */
  reminderSound: string;

  /**
   * 该任务专属的通知消息文本。
   * '' = 使用全局默认消息；非空值为本任务自定义内容。
   */
  reminderMessage: string;

  // ── 完成 ───────────────────────────────────────────────────────────────────

  /** 完成方式，取值 TaskCompletionType */
  completionType: number;

  /** 完成时间戳（ms），0 表示尚未完成 */
  completedAt: number;

  // ── 来源 ───────────────────────────────────────────────────────────────────

  /**
   * 来源收集箱条目 ID。
   * 0 = 直接创建；> 0 = 由收集箱条目转入（转入时自动预填 title/content/tags）。
   * 仅作记录追踪，不建立强外键约束。
   */
  sourceInboxId: number;

  // ── 排序 & 元数据 ──────────────────────────────────────────────────────────

  /** 是否置顶：0 = 普通，1 = 置顶 */
  isPinned: number;

  /** 用户自定义排序值，越小越靠前（同权重时生效） */
  sortOrder: number;

  /** 创建时间戳（ms） */
  createdAt: number;

  /** 最后修改时间戳（ms） */
  updatedAt: number;

  /**
   * 截止提醒标识符（由 NotificationHelper.scheduleDeadlineReminder 返回）。
   * 新约定：等于 task.id；0 = 未注册，> 0 = 已注册，可用于取消。
   */
  reminderId: number;

  // ── 区间任务专属：开始时间提醒 ─────────────────────────────────────────────

  /**
   * 区间任务「开始时间」的提醒类型，取值 TaskReminderType。
   * 非 INTERVAL 类型任务此字段固定为 0（NONE）。
   */
  startReminderType: number;

  /**
   * 区间任务「开始时间」的自定义通知消息文本。
   * '' = 使用任务标题作为消息；非空值为本任务自定义内容。
   */
  startReminderMessage: string;

  /**
   * 区间任务「开始时间」提醒标识符（由 NotificationHelper.scheduleStartReminder 返回）。
   * 新约定：等于 task.id + 1000000；0 = 未注册，> 0 = 已注册，可用于取消。
   */
  startReminderId: number;
}

// ── 序列化工具函数 ─────────────────────────────────────────────────────────────

/**
 * 从 JSON 字符串解析时间节点数组。
 * @param json 时间节点 JSON 字符串
 * @returns 时间戳数组，解析失败或为空时返回空数组
 */
export function parseTimeNodes(json: string): number[] {
  if (json === '') {
    return [];
  }
  try {
    return JSON.parse(json) as number[];
  } catch {
    return [];
  }
}

/**
 * 将时间节点数组序列化为 JSON 字符串。
 * @param nodes 时间戳数组
 * @returns JSON 字符串，无节点时返回空字符串
 */
export function serializeTimeNodes(nodes: number[]): string {
  if (nodes.length === 0) {
    return '';
  }
  return JSON.stringify(nodes);
}

/**
 * 从 JSON 字符串解析循环规则对象。
 * @param json 循环规则 JSON 字符串
 * @returns RecurringRule 对象，解析失败时返回 null
 */
export function parseRecurringRule(json: string): RecurringRule | null {
  if (json === '') {
    return null;
  }
  try {
    return JSON.parse(json) as RecurringRule;
  } catch {
    return null;
  }
}

/**
 * 将循环规则对象序列化为 JSON 字符串。
 * @param rule 循环规则对象
 * @returns JSON 字符串
 */
export function serializeRecurringRule(rule: RecurringRule): string {
  return JSON.stringify(rule);
}

/**
 * 从 JSON 字符串解析区间节点数组。
 * 用于 INTERVAL / MULTI_NODE_INTERVAL 类型任务。
 * @param json 区间节点 JSON 字符串
 * @returns IntervalNode 数组，解析失败或为空时返回空数组
 */
export function parseIntervalNodes(json: string): IntervalNode[] {
  if (json === '') {
    return [];
  }
  try {
    return JSON.parse(json) as IntervalNode[];
  } catch {
    return [];
  }
}

/**
 * 将区间节点数组序列化为 JSON 字符串。
 * @param nodes 区间节点数组
 * @returns JSON 字符串，无节点时返回空字符串
 */
export function serializeIntervalNodes(nodes: IntervalNode[]): string {
  if (nodes.length === 0) {
    return '';
  }
  return JSON.stringify(nodes);
}

// ── 调度逻辑工具函数 ──────────────────────────────────────────────────────────

/**
 * 获取任务的下一个截止时间戳。
 * - SINGLE：返回唯一节点时间
 * - RECURRING：返回 currentNodeIndex 指向的节点时间
 * - INTERVAL：返回单个区间节点的结束时间
 * - MULTI_NODE：遍历节点，返回第一个尚未到来（> now）的节点时间；
 *   若所有节点均已过期则返回最后节点时间（令 formatTaskDeadline 显示"已过期"）
 * - MULTI_NODE_INTERVAL：遍历区间节点，返回第一个尚未结束（end > now）的区间 end；
 *   若所有区间均已结束则返回最后区间的 end
 * - NONE 或节点数组为空：返回 0
 * @param entry 任务条目
 * @returns 下一个截止时间戳（ms），0 表示无截止时间
 */
export function getNextDeadline(entry: TaskEntry): number {
  if (entry.scheduleType === TaskScheduleType.NONE) {
    return 0;
  }
  if (entry.scheduleType === TaskScheduleType.INTERVAL) {
    // 区间任务：读取 IntervalNode，截止时间取 end
    const intervalNodes: IntervalNode[] = parseIntervalNodes(entry.timeNodes);
    if (intervalNodes.length === 0) {
      return 0;
    }
    return intervalNodes[0].end;
  }
  if (entry.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL) {
    // 多节点区间：动态找第一个尚未结束的区间（end > now）
    const intervalNodes: IntervalNode[] = parseIntervalNodes(entry.timeNodes);
    if (intervalNodes.length === 0) {
      return 0;
    }
    const now: number = Date.now();
    for (let i: number = 0; i < intervalNodes.length; i++) {
      if (intervalNodes[i].end > now) {
        return intervalNodes[i].end;
      }
    }
    // 全部区间已过期：返回最后区间的 end
    return intervalNodes[intervalNodes.length - 1].end;
  }
  // SINGLE / MULTI_NODE / RECURRING：number[] 格式
  const nodes: number[] = parseTimeNodes(entry.timeNodes);
  if (nodes.length === 0) {
    return 0;
  }
  if (entry.scheduleType === TaskScheduleType.MULTI_NODE) {
    // 多节点：动态找第一个尚未到来的节点（> now）
    const now: number = Date.now();
    for (let i: number = 0; i < nodes.length; i++) {
      if (nodes[i] > now) {
        return nodes[i];
      }
    }
    // 全部节点已过期：返回最后节点时间
    return nodes[nodes.length - 1];
  }
  // SINGLE / RECURRING：固定取 currentNodeIndex
  const idx: number = entry.currentNodeIndex < nodes.length ? entry.currentNodeIndex : 0;
  return nodes[idx];
}

/**
 * 获取区间任务的开始时间戳。
 * - INTERVAL：返回单个区间节点的 start
 * - MULTI_NODE_INTERVAL：动态找第一个尚未结束（end > now）的区间的 start；
 *   若全部结束则返回最后区间的 start
 * - 非区间类型或无节点时返回 0
 * @param entry 任务条目
 * @returns 开始时间戳（ms），0 表示无开始时间
 */
export function getStartTime(entry: TaskEntry): number {
  if (entry.scheduleType === TaskScheduleType.INTERVAL) {
    const intervalNodes: IntervalNode[] = parseIntervalNodes(entry.timeNodes);
    return intervalNodes.length >= 1 ? intervalNodes[0].start : 0;
  }
  if (entry.scheduleType === TaskScheduleType.MULTI_NODE_INTERVAL) {
    const intervalNodes: IntervalNode[] = parseIntervalNodes(entry.timeNodes);
    if (intervalNodes.length === 0) {
      return 0;
    }
    const now: number = Date.now();
    for (let i: number = 0; i < intervalNodes.length; i++) {
      if (intervalNodes[i].end > now) {
        return intervalNodes[i].start;
      }
    }
    // 全部结束：返回最后区间的 start
    return intervalNodes[intervalNodes.length - 1].start;
  }
  return 0;
}

/**
 * 将毫秒差值格式化为简洁时长字符串（内部工具）。
 * - ≥1天：Xd Xh（小时为 0 时省略）
 * - ≥1小时：Xh Xm（分钟为 0 时省略）
 * - ≥1分钟：Xm
 * - <1分钟：< 1m
 */
function timeDiffStr(diffMs: number): string {
  const ONE_MIN_MS: number = 60000;
  const ONE_HOUR_MS: number = 3600000;
  const ONE_DAY_MS: number = 86400000;
  if (diffMs >= ONE_DAY_MS) {
    const days: number = Math.floor(diffMs / ONE_DAY_MS);
    const hours: number = Math.floor((diffMs % ONE_DAY_MS) / ONE_HOUR_MS);
    if (hours > 0) {
      return days.toString() + 'd ' + hours.toString() + 'h';
    }
    return days.toString() + 'd';
  }
  if (diffMs >= ONE_HOUR_MS) {
    const hours: number = Math.floor(diffMs / ONE_HOUR_MS);
    const minutes: number = Math.floor((diffMs % ONE_HOUR_MS) / ONE_MIN_MS);
    if (minutes > 0) {
      return hours.toString() + 'h ' + minutes.toString() + 'm';
    }
    return hours.toString() + 'h';
  }
  const minutes: number = Math.floor(diffMs / ONE_MIN_MS);
  if (minutes >= 1) {
    return minutes.toString() + 'm';
  }
  return '< 1m';
}

/**
 * 将区间任务的开始/截止时间格式化为简洁状态文本。
 * - 已结束（end ≤ now）：zh="已过期" / en="Overdue"
 * - 未开始（start > now）：zh="距开始 Xd Xh" / en="Starts in Xd Xh"
 * - 进行中（start ≤ now < end）：zh="距结束 Xh Xm" / en="Ends in Xh Xm"
 * @param startTs 开始时间戳（ms）
 * @param endTs   截止时间戳（ms）
 * @param lang    当前语言标识
 * @returns 格式化状态字符串
 */
export function formatTaskInterval(startTs: number, endTs: number, lang: string): string {
  if (startTs <= 0 || endTs <= 0) {
    return '';
  }
  const isZh: boolean = lang.startsWith('zh');
  const now: number = Date.now();
  if (endTs <= now) {
    return isZh ? '已过期' : 'Overdue';
  }
  if (startTs > now) {
    const diff: string = timeDiffStr(startTs - now);
    return isZh ? ('距开始 ' + diff) : ('Starts in ' + diff);
  }
  // 进行中
  const diff: string = timeDiffStr(endTs - now);
  return isZh ? ('距结束 ' + diff) : ('Ends in ' + diff);
}

/**
 * 将截止时间戳格式化为列表行中的简洁时间距离文本。
 * - 已逾期：zh="已过期" / en="Overdue"
 * - 未逾期：显示剩余时长，单位自动适配，无汉字描述（d/h/m 通用）
 *   - ≥1天：Xd Xh（小时为 0 时省略）
 *   - ≥1小时：Xh Xm（分钟为 0 时省略）
 *   - ≥1分钟：Xm
 *   - <1分钟：< 1m
 * @param deadline 截止时间戳（ms），0 表示无截止时间
 * @param lang 当前语言标识
 * @returns 格式化字符串，deadline=0 时返回空字符串
 */
export function formatTaskDeadline(deadline: number, lang: string): string {
  if (deadline === 0) {
    return '';
  }
  const isZh: boolean = lang.startsWith('zh');
  const now: number = Date.now();
  if (deadline <= now) {
    return isZh ? '已过期' : 'Overdue';
  }
  const diff: string = timeDiffStr(deadline - now);
  return isZh ? ('距结束 ' + diff) : ('Ends in ' + diff);
}

/**
 * 根据循环规则计算下一次触发时间戳。
 *
 * RELATIVE：completedAt + intervalDays 天
 * DAILY：currentTriggerTs 向后推 1 天（保持相同时分）
 * WEEKLY：从 currentTriggerTs + 1 天起，找下一个匹配 daysOfWeek 的日期（保持相同时分）
 * MONTHLY：从 currentTriggerTs 所在月 + 1 月起，找下一个 dayOfMonth（保持相同时分）
 *
 * @param rule             循环规则对象
 * @param currentTriggerTs 当前触发时间戳（ms），RECURRING 任务的 timeNodes[0]
 * @param completedAt      任务完成时间戳（ms），仅 RELATIVE 模式使用
 * @returns 下一次触发时间戳（ms），无法计算时返回 0
 */
export function computeNextRecurringDate(
  rule: RecurringRule,
  currentTriggerTs: number,
  completedAt: number,
): number {
  const ONE_DAY_MS: number = 86400000;

  if (rule.type === RecurringType.RELATIVE) {
    // 相对循环：基于完成时间推 intervalDays 天
    if (rule.intervalDays <= 0) {
      return 0;
    }
    return completedAt + rule.intervalDays * ONE_DAY_MS;
  }

  if (rule.type === RecurringType.DAILY) {
    // 每天：在当前触发时间基础上 +1 天
    return currentTriggerTs + ONE_DAY_MS;
  }

  if (rule.type === RecurringType.WEEKLY) {
    if (rule.daysOfWeek.length === 0) {
      return 0;
    }
    // 从明天开始向前最多搜索 7 天，找到下一个匹配的星期几
    const base: Date = new Date(currentTriggerTs);
    const timeOfDayMs: number = base.getHours() * 3600000 + base.getMinutes() * 60000;
    for (let i: number = 1; i <= 7; i++) {
      const candidate: Date = new Date(currentTriggerTs + i * ONE_DAY_MS);
      candidate.setHours(0, 0, 0, 0);
      const dayOfWeek: number = candidate.getDay();
      if (rule.daysOfWeek.indexOf(dayOfWeek) >= 0) {
        return candidate.getTime() + timeOfDayMs;
      }
    }
    return 0;
  }

  if (rule.type === RecurringType.MONTHLY) {
    if (rule.dayOfMonth <= 0 || rule.dayOfMonth > 31) {
      return 0;
    }
    const base: Date = new Date(currentTriggerTs);
    const timeOfDayMs: number = base.getHours() * 3600000 + base.getMinutes() * 60000;
    // 尝试下个月同日
    let targetYear: number = base.getFullYear();
    let targetMonth: number = base.getMonth() + 1; // 推进到下一个月
    if (targetMonth > 11) {
      targetMonth = 0;
      targetYear += 1;
    }
    // 最多尝试 12 个月，处理月份天数不一致（如 2 月没有 31 日）
    for (let m: number = 0; m < 12; m++) {
      const candidate: Date = new Date(targetYear, targetMonth, rule.dayOfMonth, 0, 0, 0, 0);
      // 验证日期有效（getDate() 与目标相符表示没有溢出到下一个月）
      if (candidate.getDate() === rule.dayOfMonth) {
        return candidate.getTime() + timeOfDayMs;
      }
      // 当月没有该日期，继续尝试下一个月
      targetMonth++;
      if (targetMonth > 11) {
        targetMonth = 0;
        targetYear += 1;
      }
    }
    return 0;
  }

  return 0;
}

/**
 * 计算任务的动态排序权重（越大越靠前）。
 *
 * urgencyScore（按截止紧迫度）：
 *   逾期        → 200
 *   24 小时内   → 80
 *   3 天内      → 40
 *   7 天内      → 20
 *   30 天内     → 10
 *   30 天外     → 3
 *   无截止      → 0
 *
 * priorityScore（按用户设定优先级）：
 *   LOW=0 / NORMAL=25 / HIGH=50 / URGENT=75
 *
 * @param entry 任务条目
 * @returns 动态权重（越大越靠排序前端）
 */
export function computeTaskWeight(entry: TaskEntry): number {
  const ONE_DAY_MS: number = 86400000;
  const deadline: number = getNextDeadline(entry);

  let urgencyScore: number = 0;
  if (deadline > 0) {
    const remaining: number = deadline - Date.now();
    if (remaining <= 0) {
      urgencyScore = 200;
    } else if (remaining <= ONE_DAY_MS) {
      urgencyScore = 80;
    } else if (remaining <= ONE_DAY_MS * 3) {
      urgencyScore = 40;
    } else if (remaining <= ONE_DAY_MS * 7) {
      urgencyScore = 20;
    } else if (remaining <= ONE_DAY_MS * 30) {
      urgencyScore = 10;
    } else {
      urgencyScore = 3;
    }
  }

  const PRIORITY_STEP: number = 25;
  const priorityScore: number = entry.priority * PRIORITY_STEP;

  return urgencyScore + priorityScore;
}
