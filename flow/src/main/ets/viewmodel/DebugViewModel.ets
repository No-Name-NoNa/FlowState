/**
 * DebugViewModel.ets
 * 调试工具业务逻辑层。
 * 提供演示数据生成与全量数据清除方法，仅供调试页面使用。
 */
import { TaskDatabase } from '../util/TaskDatabase';
import { InboxDatabase } from '../util/InboxDatabase';
import { TimerSessionDatabase } from '../util/TimerSessionDatabase';
import { TaskEntry, TaskStatus, TaskPriority, TaskCompletionType, TaskScheduleType } from '../model/TaskEntry';
import { InboxEntry } from '../model/InboxEntry';
import { HistoryRefreshSignal } from '../util/HistoryRefreshSignal';
import {
  KEY_TASK_NEEDS_REFRESH, KEY_INBOX_NEEDS_REFRESH, LOG_DOMAIN,
} from '../constants/AppConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';

/** 时间常量（毫秒） */
const DAY_MS: number = 86400000;
const HOUR_MS: number = 3600000;
const MIN_MS: number = 60000;

/**
 * 演示归档任务配置项。
 * sessions 每项格式：[开始小时（0-23）, 持续分钟]
 */
interface ArchivedSeed {
  title: string;
  tags: string;
  priority: number;

  /** 距今多少天前归档 */
  daysAgo: number;

  /** 计时段列表：[开始小时, 持续分钟][] */
  sessions: number[][];
}

/** 演示收集箱条目配置 */
interface InboxSeed {
  text: string;
  content: string;
  tags: string;
}

/** 预置的归档任务演示数据（覆盖近 3 个月） */
const ARCHIVED_SEEDS: ArchivedSeed[] = [
  {
    title: '整理技术分享讲义',
    tags: '["技术","学习"]',
    priority: TaskPriority.NORMAL,
    daysAgo: 1,
    sessions: [[9, 45], [14, 30]]
  },
  {
    title: '修复登录页面样式缺陷',
    tags: '["工作","技术"]',
    priority: TaskPriority.HIGH,
    daysAgo: 2,
    sessions: [[10, 40], [15, 45]]
  },
  {
    title: '更新第三方依赖库版本',
    tags: '["工作"]',
    priority: TaskPriority.LOW,
    daysAgo: 3,
    sessions: [[14, 30]]
  },
  {
    title: 'Code Review：支付模块',
    tags: '["工作","技术"]',
    priority: TaskPriority.HIGH,
    daysAgo: 4,
    sessions: [[9, 30], [14, 30]]
  },
  {
    title: '撰写本周工作周报',
    tags: '["工作"]',
    priority: TaskPriority.LOW,
    daysAgo: 5,
    sessions: [[16, 20]]
  },
  {
    title: '梳理下期功能需求文档',
    tags: '["工作"]',
    priority: TaskPriority.NORMAL,
    daysAgo: 6,
    sessions: [[9, 45], [14, 45]]
  },
  {
    title: '设计系统组件库重构方案',
    tags: '["工作","设计"]',
    priority: TaskPriority.HIGH,
    daysAgo: 12,
    sessions: [[9, 60], [14, 60]]
  },
  {
    title: '优化首屏加载速度',
    tags: '["工作","技术"]',
    priority: TaskPriority.HIGH,
    daysAgo: 15,
    sessions: [[10, 45], [14, 45]]
  },
  {
    title: '实现应用暗色主题适配',
    tags: '["工作","UI"]',
    priority: TaskPriority.NORMAL,
    daysAgo: 18,
    sessions: [[9, 60], [13, 50], [16, 40]]
  },
  {
    title: '数据库查询索引优化',
    tags: '["技术"]',
    priority: TaskPriority.NORMAL,
    daysAgo: 22,
    sessions: [[10, 30], [14, 30]]
  },
  {
    title: '编写核心模块单元测试',
    tags: '["工作","技术"]',
    priority: TaskPriority.NORMAL,
    daysAgo: 25,
    sessions: [[9, 35], [14, 35]]
  },
  {
    title: '竞品分析调研报告',
    tags: '["工作"]',
    priority: TaskPriority.LOW,
    daysAgo: 28,
    sessions: [[14, 40]]
  },
  {
    title: '重构用户认证授权模块',
    tags: '["工作","技术"]',
    priority: TaskPriority.HIGH,
    daysAgo: 30,
    sessions: [[9, 60], [13, 60], [16, 60]]
  },
  {
    title: 'Q2 工作成果总结',
    tags: '["工作"]',
    priority: TaskPriority.NORMAL,
    daysAgo: 35,
    sessions: [[14, 45], [16, 45]]
  },
  {
    title: 'ArkTS 开发实践博客',
    tags: '["学习","写作"]',
    priority: TaskPriority.LOW,
    daysAgo: 45,
    sessions: [[9, 60], [14, 60]]
  },
  {
    title: '性能监控埋点系统搭建',
    tags: '["工作","技术"]',
    priority: TaskPriority.HIGH,
    daysAgo: 55,
    sessions: [[9, 50], [13, 50], [16, 60]]
  },
  {
    title: '接口文档整理更新',
    tags: '["工作"]',
    priority: TaskPriority.LOW,
    daysAgo: 58,
    sessions: [[14, 40]]
  },
  {
    title: '旧版本向后兼容修复',
    tags: '["工作","技术"]',
    priority: TaskPriority.NORMAL,
    daysAgo: 65,
    sessions: [[9, 40], [14, 40]]
  },
  {
    title: '安全漏洞扫描与修复',
    tags: '["工作","技术"]',
    priority: TaskPriority.URGENT,
    daysAgo: 75,
    sessions: [[9, 50], [14, 50]]
  },
  {
    title: '系统架构设计评审',
    tags: '["工作"]',
    priority: TaskPriority.HIGH,
    daysAgo: 85,
    sessions: [[9, 60], [13, 70], [16, 70]]
  },
];

/** 预置的收集箱演示条目 */
const INBOX_SEEDS: InboxSeed[] = [
  { text: '重构用户登录界面', content: '考虑重新设计 UX 交互流程，参考 Material You 规范', tags: '["工作","UI"]' },
  { text: '买本《Clean Code》', content: '', tags: '["学习"]' },
  { text: '联系周五聚餐的朋友', content: '', tags: '' },
  { text: '写一篇关于 ArkTS 的博客', content: '记录开发过程中遇到的坑与解决方案', tags: '["学习","写作"]' },
  { text: '备份电脑文件', content: '', tags: '["生活"]' },
  { text: '研究 SwiftUI 动画系统', content: '对比 ArkUI 的动效实现差异', tags: '["学习","技术"]' },
  { text: '制定下个季度 OKR', content: '', tags: '["工作"]' },
  { text: '订购新机械键盘', content: 'Cherry MX 茶轴，65% 配列', tags: '["生活"]' },
  { text: '读完《原则》', content: '第三章开始精读', tags: '["学习"]' },
  { text: '更新个人主页 About 页面', content: '', tags: '["工作","UI"]' },
];

/** 调试工具 ViewModel，所有方法均为静态 */
export class DebugViewModel {
  /**
   * 生成演示任务。
   * 插入 5 条活跃任务 + 20 条历史归档任务，并为每条归档任务创建配套的计时段记录。
   */
  static async generateDemoTasks(): Promise<void> {
    const now: number = Date.now();
    try {
      // ── 插入活跃任务 ──────────────────────────────────────────────────────
      const activeTasks: TaskEntry[] = DebugViewModel.buildActiveTasks(now);
      for (let i: number = 0; i < activeTasks.length; i++) {
        await TaskDatabase.insert(activeTasks[i]);
      }

      // ── 插入归档任务及计时段记录 ──────────────────────────────────────────
      for (let i: number = 0; i < ARCHIVED_SEEDS.length; i++) {
        const seed: ArchivedSeed = ARCHIVED_SEEDS[i];
        const task: TaskEntry = DebugViewModel.buildArchivedTask(seed, now);
        const taskId: number = await TaskDatabase.insert(task);
        if (taskId > 0) {
          // 计算该任务归档当天零点时刻（UTC 近似）
          const archivedDayStart: number = now - seed.daysAgo * DAY_MS;
          const midnight: number = archivedDayStart - (archivedDayStart % DAY_MS);
          for (let j: number = 0; j < seed.sessions.length; j++) {
            const startHour: number = seed.sessions[j][0];
            const durationMin: number = seed.sessions[j][1];
            const startAt: number = midnight + startHour * HOUR_MS;
            const endAt: number = startAt + durationMin * MIN_MS;
            await TimerSessionDatabase.insertCompletedSession(taskId, startAt, endAt);
          }
        }
      }

      // ── 触发全局刷新信号 ──────────────────────────────────────────────────
      AppStorage.setOrCreate(KEY_TASK_NEEDS_REFRESH, true);
      HistoryRefreshSignal.bump();
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'DebugViewModel',
        'generateDemoTasks 失败：%{public}s', JSON.stringify(err));
    }
  }

  /**
   * 生成演示收集箱条目（插入 10 条）。
   */
  static async generateDemoInbox(): Promise<void> {
    const now: number = Date.now();
    try {
      for (let i: number = 0; i < INBOX_SEEDS.length; i++) {
        const seed: InboxSeed = INBOX_SEEDS[i];
        const entry: InboxEntry = {
          id: 0,
          text: seed.text,
          content: seed.content,
          tags: seed.tags,
          sortOrder: i,
          isPinned: 0,
          createdAt: now - (INBOX_SEEDS.length - i) * HOUR_MS,
          updatedAt: now - (INBOX_SEEDS.length - i) * HOUR_MS,
        };
        await InboxDatabase.insert(entry);
      }
      AppStorage.setOrCreate(KEY_INBOX_NEEDS_REFRESH, true);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'DebugViewModel',
        'generateDemoInbox 失败：%{public}s', JSON.stringify(err));
    }
  }

  /**
   * 清空所有任务及计时段记录。
   */
  static async clearAllTasks(): Promise<void> {
    try {
      await TimerSessionDatabase.deleteAll();
      await TaskDatabase.deleteAll();
      AppStorage.setOrCreate(KEY_TASK_NEEDS_REFRESH, true);
      HistoryRefreshSignal.bump();
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'DebugViewModel',
        'clearAllTasks 失败：%{public}s', JSON.stringify(err));
    }
  }

  /**
   * 清空收集箱所有条目。
   */
  static async clearAllInbox(): Promise<void> {
    try {
      await InboxDatabase.deleteAll();
      AppStorage.setOrCreate(KEY_INBOX_NEEDS_REFRESH, true);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'DebugViewModel',
        'clearAllInbox 失败：%{public}s', JSON.stringify(err));
    }
  }

  /**
   * 清空全部数据（任务 + 计时记录 + 收集箱）。
   */
  static async clearAll(): Promise<void> {
    await DebugViewModel.clearAllTasks();
    await DebugViewModel.clearAllInbox();
  }

  // ── 内部构建方法 ──────────────────────────────────────────────────────────

  /**
   * 构建 5 条演示活跃任务。
   * @param now 当前时间戳（ms）
   */
  private static buildActiveTasks(now: number): TaskEntry[] {
    return [
      // 1. 紧急任务，截止明天
      {
        id: 0,
        title: '完成 Q3 产品路线图',
        content: '包含功能规划、里程碑与资源分配',
        tags: '["工作"]',
        priority: TaskPriority.URGENT,
        status: TaskStatus.PENDING,
        scheduleType: TaskScheduleType.SINGLE,
        timeNodes: JSON.stringify([now + DAY_MS]),
        currentNodeIndex: 0,
        recurringRule: '',
        targetDuration: 0,
        accumulatedDuration: 0,
        reminderType: 0,
        reminderOffset: 0,
        reminderSound: '',
        reminderMessage: '',
        completionType: TaskCompletionType.MANUAL,
        completedAt: 0,
        sourceInboxId: 0,
        isPinned: 0,
        sortOrder: 0,
        createdAt: now - 2 * DAY_MS,
        updatedAt: now - 2 * DAY_MS,
        reminderId: 0,
        startReminderType: 0,
        startReminderMessage: '',
        startReminderId: 0,
        nodeTargetDurations: '',
      },
      // 2. 高优先级，无截止
      {
        id: 0,
        title: '优化 SQLite 查询性能',
        content: '',
        tags: '["工作","技术"]',
        priority: TaskPriority.HIGH,
        status: TaskStatus.PENDING,
        scheduleType: TaskScheduleType.NONE,
        timeNodes: '',
        currentNodeIndex: 0,
        recurringRule: '',
        targetDuration: 0,
        accumulatedDuration: 0,
        reminderType: 0,
        reminderOffset: 0,
        reminderSound: '',
        reminderMessage: '',
        completionType: TaskCompletionType.MANUAL,
        completedAt: 0,
        sourceInboxId: 0,
        isPinned: 0,
        sortOrder: 1,
        createdAt: now - DAY_MS,
        updatedAt: now - DAY_MS,
        reminderId: 0,
        startReminderType: 0,
        startReminderMessage: '',
        startReminderId: 0,
        nodeTargetDurations: '',
      },
      // 3. 普通优先级，时长模式，已累计 30 分钟
      {
        id: 0,
        title: '学习 HarmonyOS ArkUI 布局',
        content: '专注阅读官方文档与示例代码',
        tags: '["学习"]',
        priority: TaskPriority.NORMAL,
        status: TaskStatus.PENDING,
        scheduleType: TaskScheduleType.NONE,
        timeNodes: '',
        currentNodeIndex: 0,
        recurringRule: '',
        targetDuration: 90,
        accumulatedDuration: 1800000,
        reminderType: 0,
        reminderOffset: 0,
        reminderSound: '',
        reminderMessage: '',
        completionType: TaskCompletionType.DURATION,
        completedAt: 0,
        sourceInboxId: 0,
        isPinned: 0,
        sortOrder: 2,
        createdAt: now - 3 * DAY_MS,
        updatedAt: now - 3 * DAY_MS,
        reminderId: 0,
        startReminderType: 0,
        startReminderMessage: '',
        startReminderId: 0,
        nodeTargetDurations: '',
      },
      // 4. 普通优先级，设计任务
      {
        id: 0,
        title: '设计用户引导流程图',
        content: '',
        tags: '["工作","设计"]',
        priority: TaskPriority.NORMAL,
        status: TaskStatus.PENDING,
        scheduleType: TaskScheduleType.NONE,
        timeNodes: '',
        currentNodeIndex: 0,
        recurringRule: '',
        targetDuration: 0,
        accumulatedDuration: 0,
        reminderType: 0,
        reminderOffset: 0,
        reminderSound: '',
        reminderMessage: '',
        completionType: TaskCompletionType.MANUAL,
        completedAt: 0,
        sourceInboxId: 0,
        isPinned: 0,
        sortOrder: 3,
        createdAt: now - 4 * DAY_MS,
        updatedAt: now - 4 * DAY_MS,
        reminderId: 0,
        startReminderType: 0,
        startReminderMessage: '',
        startReminderId: 0,
        nodeTargetDurations: '',
      },
      // 5. 低优先级，已完成（2 小时前）
      {
        id: 0,
        title: '整理本周会议纪要',
        content: '',
        tags: '',
        priority: TaskPriority.LOW,
        status: TaskStatus.COMPLETED,
        scheduleType: TaskScheduleType.NONE,
        timeNodes: '',
        currentNodeIndex: 0,
        recurringRule: '',
        targetDuration: 0,
        accumulatedDuration: 0,
        reminderType: 0,
        reminderOffset: 0,
        reminderSound: '',
        reminderMessage: '',
        completionType: TaskCompletionType.MANUAL,
        completedAt: now - 2 * HOUR_MS,
        sourceInboxId: 0,
        isPinned: 0,
        sortOrder: 4,
        createdAt: now - 5 * DAY_MS,
        updatedAt: now - 2 * HOUR_MS,
        reminderId: 0,
        startReminderType: 0,
        startReminderMessage: '',
        startReminderId: 0,
        nodeTargetDurations: '',
      },
    ];
  }

  /**
   * 根据归档任务配置项构建 TaskEntry。
   * @param seed 归档任务配置
   * @param now  当前时间戳（ms）
   */
  private static buildArchivedTask(seed: ArchivedSeed, now: number): TaskEntry {
    // 计算该任务所在当天的大致时间戳
    const archivedAt: number = now - seed.daysAgo * DAY_MS;
    // 计算所有计时段的总时长（ms）
    let totalMs: number = 0;
    for (let j: number = 0; j < seed.sessions.length; j++) {
      totalMs += seed.sessions[j][1] * MIN_MS;
    }
    return {
      id: 0,
      title: seed.title,
      content: '',
      tags: seed.tags,
      priority: seed.priority,
      status: TaskStatus.ARCHIVED,
      scheduleType: TaskScheduleType.NONE,
      timeNodes: '',
      currentNodeIndex: 0,
      recurringRule: '',
      targetDuration: 0,
      accumulatedDuration: totalMs,
      reminderType: 0,
      reminderOffset: 0,
      reminderSound: '',
      reminderMessage: '',
      completionType: TaskCompletionType.MANUAL,
      completedAt: archivedAt,
      sourceInboxId: 0,
      isPinned: 0,
      sortOrder: 0,
      createdAt: archivedAt - 8 * HOUR_MS,
      updatedAt: archivedAt,
      reminderId: 0,
      startReminderType: 0,
      startReminderMessage: '',
      startReminderId: 0,
      nodeTargetDurations: '',
    };
  }
}
