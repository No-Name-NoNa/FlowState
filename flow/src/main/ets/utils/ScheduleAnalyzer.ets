import { Schedule } from '../models/DataModels';

export interface ScheduleConflict {
  id: string;
  firstId: string;
  secondId: string;
  firstTitle: string;
  secondTitle: string;
  startAt: number;
  endAt: number;
  overlapMinutes: number;
}

export class ScheduleAnalyzer {
  static isActiveForPlanning(schedule: Schedule): boolean {
    return schedule.state !== 'completed' && schedule.state !== 'cancelled' && schedule.state !== 'deferred';
  }

  static buildDueAt(date: number, time: string): number {
    const parts = time.split(':');
    const hour = parseInt(parts[0]) || 0;
    const minute = parseInt(parts[1]) || 0;
    const due = new Date(date);
    due.setHours(hour, minute, 0, 0);
    return due.getTime();
  }

  static getDueAt(schedule: Schedule): number {
    if (schedule.dueAt) return schedule.dueAt;
    return ScheduleAnalyzer.buildDueAt(schedule.scheduledDate || new Date().setHours(0, 0, 0, 0), schedule.scheduledTime || '09:00');
  }

  static getStartAt(schedule: Schedule): number {
    return ScheduleAnalyzer.getDueAt(schedule) - schedule.estimatedTime * 60 * 1000;
  }

  static getConflicts(schedules: Schedule[]): ScheduleConflict[] {
    const active: Schedule[] = [];
    for (let schedule of schedules) {
      if (ScheduleAnalyzer.isActiveForPlanning(schedule)) {
        active.push(schedule);
      }
    }
    active.sort((a: Schedule, b: Schedule) => ScheduleAnalyzer.getStartAt(a) - ScheduleAnalyzer.getStartAt(b));

    const conflicts: ScheduleConflict[] = [];
    for (let i = 0; i < active.length; i++) {
      for (let j = i + 1; j < active.length; j++) {
        const first = active[i];
        const second = active[j];
        const firstStart = ScheduleAnalyzer.getStartAt(first);
        const firstEnd = ScheduleAnalyzer.getDueAt(first);
        const secondStart = ScheduleAnalyzer.getStartAt(second);
        const secondEnd = ScheduleAnalyzer.getDueAt(second);

        if (secondStart >= firstEnd) {
          break;
        }

        const overlapStart = Math.max(firstStart, secondStart);
        const overlapEnd = Math.min(firstEnd, secondEnd);
        if (overlapStart < overlapEnd) {
          conflicts.push({
            id: `${first.id}_${second.id}`,
            firstId: first.id,
            secondId: second.id,
            firstTitle: first.title,
            secondTitle: second.title,
            startAt: overlapStart,
            endAt: overlapEnd,
            overlapMinutes: Math.max(1, Math.round((overlapEnd - overlapStart) / 60000))
          });
        }
      }
    }
    return conflicts;
  }
}
