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
  /** 单次截止时间 */
  SINGLE = 1,
  /** 多节点自定义日期（如 1/10、2/5 等不规则日期） */
  MULTI_NODE = 2,
  /** 规则循环（绝对/相对） */
  RECURRING = 3,
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

/** 提醒强度 */
export const enum TaskReminderType {
  /** 无提醒 */
  NONE = 0,
  /** 静默提醒：仅 UI 状态高亮 */
  SILENT = 1,
  /** 弱提醒：系统通知 + 自定义音效/震动 */
  WEAK = 2,
  /** 强提醒：需手动干预才能关闭（类闹钟） */
  STRONG = 3,
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

  /** 提醒强度，取值 TaskReminderType */
  reminderType: number;

  /** 提前提醒时间（分钟），0 表示在节点时刻精确提醒 */
  reminderOffset: number;

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

  /** 用户自定义排序值，越小越靠前（同权重时生效） */
  sortOrder: number;

  /** 创建时间戳（ms） */
  createdAt: number;

  /** 最后修改时间戳（ms） */
  updatedAt: number;
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

// ── 调度逻辑工具函数 ──────────────────────────────────────────────────────────

/**
 * 获取任务的下一个截止时间戳。
 * - SINGLE：返回唯一节点时间
 * - MULTI_NODE/RECURRING：返回 currentNodeIndex 指向的节点时间
 * - NONE 或节点数组为空：返回 0
 * @param entry 任务条目
 * @returns 下一个截止时间戳（ms），0 表示无截止时间
 */
export function getNextDeadline(entry: TaskEntry): number {
  if (entry.scheduleType === TaskScheduleType.NONE) {
    return 0;
  }
  const nodes: number[] = parseTimeNodes(entry.timeNodes);
  if (nodes.length === 0) {
    return 0;
  }
  const idx: number = entry.currentNodeIndex < nodes.length ? entry.currentNodeIndex : 0;
  return nodes[idx];
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
