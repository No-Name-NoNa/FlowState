/**
 * InboxEntry.ets
 * 收集箱条目数据模型及工具函数。
 */
import { LANG_EN_US } from '../constants/AppConstants';

/** 收集箱条目数据结构 */
export interface InboxEntry {
  /** 数据库自增主键，新建时传 0 */
  id: number;

  /** 条目标题（单行） */
  text: string;

  /** 条目正文详情（多行，可选，空字符串表示无） */
  content: string;

  /** 标签列表，JSON 字符串存储，如 '["工作","想法"]'；无标签时为空字符串 */
  tags: string;

  /** 用户自定义排序值，越小越靠前 */
  sortOrder: number;

  /** 是否置顶：0 = 普通，1 = 置顶 */
  isPinned: number;

  /** 创建时间戳（ms） */
  createdAt: number;

  /** 最后修改时间戳（ms） */
  updatedAt: number;
}

/**
 * 从 JSON 字符串解析标签数组。
 * @param tagsJson 标签 JSON 字符串
 * @returns 标签字符串数组，解析失败时返回空数组
 */
export function parseTags(tagsJson: string): string[] {
  if (tagsJson === '') {
    return [];
  }
  try {
    return JSON.parse(tagsJson) as string[];
  } catch {
    return [];
  }
}

/**
 * 将标签数组序列化为 JSON 字符串。
 * @param tags 标签字符串数组
 * @returns JSON 字符串，无标签时返回空字符串
 */
export function serializeTags(tags: string[]): string {
  if (tags.length === 0) {
    return '';
  }
  return JSON.stringify(tags);
}

/**
 * 将时间戳格式化为相对时间（近期）或绝对日期（较久前）。
 * @param timestamp 时间戳（ms）
 * @param lang      当前语言标识
 * @returns 格式化后的时间字符串
 */
export function formatTimestamp(timestamp: number, lang: string): string {
  const now: number = Date.now();
  const diff: number = now - timestamp;
  const ONE_MIN: number = 60000;
  const ONE_HOUR: number = 3600000;
  const ONE_DAY: number = 86400000;

  if (diff < ONE_MIN) {
    return lang === LANG_EN_US ? 'Just now' : '刚刚';
  }
  if (diff < ONE_HOUR) {
    const mins: number = Math.floor(diff / ONE_MIN);
    return lang === LANG_EN_US ? `${mins}m ago` : `${mins}分钟前`;
  }
  if (diff < ONE_DAY) {
    const hours: number = Math.floor(diff / ONE_HOUR);
    return lang === LANG_EN_US ? `${hours}h ago` : `${hours}小时前`;
  }
  if (diff < ONE_DAY * 7) {
    const days: number = Math.floor(diff / ONE_DAY);
    return lang === LANG_EN_US ? `${days}d ago` : `${days}天前`;
  }
  // 超过 7 天显示绝对日期
  const d: Date = new Date(timestamp);
  const year: string = d.getFullYear().toString();
  const month: string = (d.getMonth() + 1).toString().padStart(2, '0');
  const day: string = d.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}
