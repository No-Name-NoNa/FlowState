/**
 * Narrative review helpers for daily planning insight.
 */

import { FocusSession, Schedule, ScheduleArchiveEntry, ScheduleChange } from '../models/DataModels';
import { ScheduleAnalyzer, ScheduleConflict } from './ScheduleAnalyzer';
import { TimeFormatter } from './TimeFormatter';

export interface ReviewInsight {
  title: string;
  detail: string;
  color: string;
}

export interface ReviewReport {
  headline: string;
  summary: string;
  recommendation: string;
  estimateText: string;
  carryOverText: string;
  routineText: string;
  conflictText: string;
  plannedMinutes: number;
  completedMinutes: number;
  routineCount: number;
  incomingCarryOverCount: number;
  outgoingCarryOverCount: number;
  conflictCount: number;
  insights: ReviewInsight[];
}

export interface ReviewDayStat {
  dayStart: number;
  label: string;
  dateText: string;
  plannedBlocks: number;
  completedBlocks: number;
  plannedMinutes: number;
  focusMinutes: number;
  changeCount: number;
}

export class ReviewAnalyzer {
  static getTodayRange(): [number, number] {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return [today.getTime(), today.getTime() + 24 * 60 * 60 * 1000 - 1];
  }

  static isInRange(timestamp: number | undefined, range: [number, number]): boolean {
    if (timestamp === undefined) return false;
    return timestamp >= range[0] && timestamp <= range[1];
  }

  static getDueAt(schedule: Schedule): number {
    return ScheduleAnalyzer.getDueAt(schedule);
  }

  static isScheduledInRange(schedule: Schedule, range: [number, number]): boolean {
    const due = ReviewAnalyzer.getDueAt(schedule);
    return due >= range[0] && due <= range[1];
  }

  static getSchedulesInRange(schedules: Schedule[], range: [number, number]): Schedule[] {
    const result: Schedule[] = [];
    for (let schedule of schedules) {
      if (ReviewAnalyzer.isScheduledInRange(schedule, range)) {
        result.push(schedule);
      }
    }
    return result;
  }

  static getChangesInRange(schedules: Schedule[], range: [number, number]): ScheduleChange[] {
    const changes: ScheduleChange[] = [];
    for (let schedule of schedules) {
      for (let change of schedule.changeHistory || []) {
        if (ReviewAnalyzer.isInRange(change.timestamp, range)) {
          changes.push(change);
        }
      }
    }
    return changes;
  }

  static getCompletedFocusMinutes(focusSessions: FocusSession[], range: [number, number]): number {
    let minutes = 0;
    for (let session of focusSessions) {
      if (session.completed && ReviewAnalyzer.isInRange(session.startTime, range)) {
        minutes += session.duration;
      }
    }
    return minutes;
  }

  static getEstimateText(schedules: Schedule[], range: [number, number]): string {
    let delta = 0;
    let samples = 0;
    for (let schedule of schedules) {
      if (schedule.state === 'completed' && ReviewAnalyzer.isInRange(schedule.completedAt, range) && schedule.actualMinutes !== undefined) {
        delta += schedule.actualMinutes - schedule.estimatedTime;
        samples++;
      }
    }
    if (samples === 0) return '暂无足够样本';
    const average = Math.round(delta / samples);
    if (average === 0) return '估时接近准确';
    if (average > 0) return `平均超时 ${average} 分钟`;
    return `平均提前 ${Math.abs(average)} 分钟`;
  }

  static buildWeeklyDayStats(schedules: Schedule[], focusSessions: FocusSession[]): ReviewDayStat[] {
    const weekRange = TimeFormatter.getWeekRange();
    const dayLabels: string[] = ['一', '二', '三', '四', '五', '六', '日'];
    const dayMs = 24 * 60 * 60 * 1000;
    const result: ReviewDayStat[] = [];

    for (let i = 0; i < 7; i++) {
      const dayStart = weekRange[0] + i * dayMs;
      const dayEnd = dayStart + dayMs - 1;
      const range: [number, number] = [dayStart, dayEnd];
      const day = new Date(dayStart);
      let plannedBlocks = 0;
      let completedBlocks = 0;
      let plannedMinutes = 0;
      let focusMinutes = 0;
      let changeCount = 0;

      for (let schedule of schedules) {
        if (ReviewAnalyzer.isScheduledInRange(schedule, range)) {
          plannedBlocks++;
          if (schedule.state !== 'cancelled') {
            plannedMinutes += schedule.estimatedTime;
          }
        }
        if (schedule.state === 'completed' && ReviewAnalyzer.isInRange(schedule.completedAt, range)) {
          completedBlocks++;
        }
        for (let change of schedule.changeHistory || []) {
          if (ReviewAnalyzer.isInRange(change.timestamp, range)) {
            changeCount++;
          }
        }
      }

      for (let session of focusSessions) {
        if (session.completed && ReviewAnalyzer.isInRange(session.startTime, range)) {
          focusMinutes += session.duration;
        }
      }

      result.push({
        dayStart,
        label: dayLabels[i],
        dateText: `${day.getMonth() + 1}/${day.getDate()}`,
        plannedBlocks,
        completedBlocks,
        plannedMinutes,
        focusMinutes,
        changeCount
      });
    }

    return result;
  }

  static buildReport(schedules: Schedule[], archiveEntries: ScheduleArchiveEntry[], focusSessions: FocusSession[], dailyCapacity: number): ReviewReport {
    const range = ReviewAnalyzer.getTodayRange();
    return ReviewAnalyzer.buildReportForRange(schedules, archiveEntries, focusSessions, dailyCapacity, range, '今天');
  }

  static buildReportForRange(
    schedules: Schedule[],
    archiveEntries: ScheduleArchiveEntry[],
    focusSessions: FocusSession[],
    dailyCapacity: number,
    range: [number, number],
    rangeLabel: string
  ): ReviewReport {
    const rangeSchedules = ReviewAnalyzer.getSchedulesInRange(schedules, range);
    const changes = ReviewAnalyzer.getChangesInRange(schedules, range);
    const conflicts: ScheduleConflict[] = ScheduleAnalyzer.getConflicts(rangeSchedules);
    const capacityLimit = rangeLabel === '本周' ? dailyCapacity * 5 : dailyCapacity;

    let plannedMinutes = 0;
    let completedBlocks = 0;
    let routineCount = 0;
    let incomingCarryOverCount = 0;
    let outgoingCarryOverCount = 0;
    let delayedCount = 0;
    let editedCount = 0;

    for (let schedule of rangeSchedules) {
      if (schedule.state !== 'cancelled') {
        plannedMinutes += schedule.estimatedTime;
      }
      if (schedule.state === 'completed' && ReviewAnalyzer.isInRange(schedule.completedAt, range)) {
        completedBlocks++;
      }
      if (schedule.routineId) {
        routineCount++;
      }
      if (schedule.stateNote === '从昨天结转') {
        incomingCarryOverCount++;
      }
    }

    for (let change of changes) {
      if (change.type === 'carryover') {
        outgoingCarryOverCount++;
      }
      if (change.type === 'delay') {
        delayedCount++;
      }
      if (change.type === 'edit') {
        editedCount++;
      }
    }

    const completedMinutes = ReviewAnalyzer.getCompletedFocusMinutes(focusSessions, range);
    const estimateText = ReviewAnalyzer.getEstimateText(schedules, range);
    const insights: ReviewInsight[] = [];

    if (plannedMinutes > capacityLimit) {
      insights.push({
        title: `${rangeLabel}计划偏满`,
        detail: `已规划 ${plannedMinutes} 分钟，略过今日容量。下次少排一段，更稳。`,
        color: '#6F7F88'
      });
    } else if (plannedMinutes >= Math.round(capacityLimit * 0.8)) {
      insights.push({
        title: '计划接近上限',
        detail: `已规划 ${plannedMinutes} 分钟，余量不多。留一段空白，更能应变。`,
        color: '#8EA1AE'
      });
    } else {
      insights.push({
        title: '计划容量还健康',
        detail: `已规划 ${plannedMinutes} 分钟，节奏平稳，可继续保持。`,
        color: '#46AFA5'
      });
    }

    if (conflicts.length > 0) {
      const first = conflicts[0];
      insights.push({
        title: '存在时间冲突',
        detail: `${TimeFormatter.formatTime(first.startAt)}-${TimeFormatter.formatTime(first.endAt)} 有重叠，先让时间归位。`,
        color: '#6F7F88'
      });
    }

    if (outgoingCarryOverCount > 0 || incomingCarryOverCount > 0) {
      insights.push({
        title: '结转需要关注',
        detail: `${rangeLabel}有结转往来。常被顺延的事，宜拆小再做。`,
        color: '#8A7CC3'
      });
    }

    if (routineCount > 0) {
      insights.push({
        title: '模板帮你减少了重复安排',
        detail: `${rangeLabel}有 ${routineCount} 个常用模板。常用之事，贵在轻便。`,
        color: '#7BAE7F'
      });
    }

    if (archiveEntries.length > 0 || delayedCount + editedCount >= 3) {
      insights.push({
        title: '计划被频繁改动',
        detail: `${rangeLabel}多次调整。下次少排一点，节奏会更稳。`,
        color: '#8EA1AE'
      });
    }

    let headline = `${rangeLabel}还在积累节奏`;
    let summary = '先完成一段时间，复盘才有凭据。';
    if (rangeSchedules.length > 0 || completedMinutes > 0) {
      headline = completedBlocks > 0 ? `${rangeLabel}已经形成执行记录` : `${rangeLabel}已经形成计划`;
      summary = `${rangeLabel}规划 ${rangeSchedules.length} 个时间块，完成 ${completedBlocks} 个，专注 ${completedMinutes} 分钟。${estimateText}。`;
    }

    let recommendation = rangeLabel === '本周' ? '下周先轻起步，再慢慢加事。' : '明天先定最重要的一段。';
    if (plannedMinutes > capacityLimit) {
      recommendation = '下一次少排一段，给当天留白。';
    } else if (conflicts.length > 0) {
      recommendation = '先理顺冲突，再开始专注。';
    } else if (outgoingCarryOverCount > 0) {
      recommendation = '被结转的事，明天先拆小。';
    } else if (completedBlocks > 0 && completedMinutes > 0) {
      recommendation = `保留${rangeLabel}有效节奏，偏差大的块下次再调。`;
    }

    return {
      headline,
      summary,
      recommendation,
      estimateText,
      carryOverText: `接收 ${incomingCarryOverCount} · 结转 ${outgoingCarryOverCount}`,
      routineText: routineCount > 0 ? `${routineCount} 个模板块` : '未使用模板',
      conflictText: conflicts.length > 0 ? `${conflicts.length} 处冲突` : '无冲突',
      plannedMinutes,
      completedMinutes,
      routineCount,
      incomingCarryOverCount,
      outgoingCarryOverCount,
      conflictCount: conflicts.length,
      insights
    };
  }
}
