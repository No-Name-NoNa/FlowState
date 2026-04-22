/**
 * 情绪推荐引擎
 * 基于情绪值推荐专注模式和时长
 */

import { RecommendMode } from '../models/DataModels';
import { RECOMMEND_RULES } from './Constants';

export class MoodEngine {
  /**
   * 根据情绪值获取推荐模式
   */
  static getRecommendation(moodValue: number): RecommendMode {
    for (const rule of RECOMMEND_RULES) {
      if (moodValue >= rule.moodRange[0] && moodValue <= rule.moodRange[1]) {
        return rule;
      }
    }
    // 默认返回标准任务
    return RECOMMEND_RULES[2];
  }

  /**
   * 获取情绪标签
   */
  static getMoodLabel(moodValue: number): string {
    if (moodValue <= 20) return '休息';
    if (moodValue <= 40) return '疲惫';
    if (moodValue <= 60) return '焦虑';
    if (moodValue <= 75) return '平淡';
    if (moodValue <= 85) return '平静';
    return '充沛';
  }

  /**
   * 获取情绪表情
   */
  static getMoodEmoji(moodValue: number): string {
    if (moodValue <= 20) return '😴';
    if (moodValue <= 40) return '😰';
    if (moodValue <= 60) return '😐';
    if (moodValue <= 80) return '🙂';
    return '⚡';
  }

  /**
   * 计算平均情绪值
   */
  static getAverageMood(moodValues: number[]): number {
    if (moodValues.length === 0) return 50;
    const sum = moodValues.reduce((acc, val) => acc + val, 0);
    return Math.round(sum / moodValues.length);
  }

  /**
   * 获取情绪趋势
   */
  static getMoodTrend(moodValues: number[]): 'up' | 'down' | 'stable' {
    if (moodValues.length < 2) return 'stable';
    const recent = moodValues.slice(-3);
    const avg1 = recent.slice(0, Math.ceil(recent.length / 2)).reduce((a, b) => a + b, 0) / Math.ceil(recent.length / 2);
    const avg2 = recent.slice(Math.ceil(recent.length / 2)).reduce((a, b) => a + b, 0) / Math.floor(recent.length / 2);
    const diff = avg2 - avg1;
    if (diff > 5) return 'up';
    if (diff < -5) return 'down';
    return 'stable';
  }

  /**
   * 生成模拟 AI 洞察
   */
  static generateAIInsight(
    totalMinutes: number,
    moodValues: number[],
    taskCount: number
  ): string {
    const hours = (totalMinutes / 60).toFixed(1);
    const avgMood = this.getAverageMood(moodValues);
    const trend = this.getMoodTrend(moodValues);

    let insight = `今日专注 ${hours} 小时，完成 ${taskCount} 项任务。`;

    if (avgMood >= 80) {
      insight += ' 精力充沛，保持高效状态！';
    } else if (avgMood >= 60) {
      insight += ' 状态稳定，继续保持。';
    } else if (avgMood >= 40) {
      insight += ' 建议适当休息调整。';
    } else {
      insight += ' 今天辛苦了，早点休息吧。';
    }

    if (trend === 'up') {
      insight += ' 情绪呈上升趋势。';
    } else if (trend === 'down') {
      insight += ' 注意调节情绪。';
    }

    return insight;
  }
}
