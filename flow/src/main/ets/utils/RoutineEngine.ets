/**
 * Lightweight routine templates for repeatable daily blocks.
 */

import { RoutineTemplate, Schedule, Task, TaskStep } from '../models/DataModels';

export class RoutineEngine {
  static getDefaultTemplates(): RoutineTemplate[] {
    return [
      {
        id: 'morning_plan',
        title: '晨间规划',
        description: '整理今天，选出第一段任务',
        scheduledTime: '09:00',
        estimatedTime: 15,
        priority: 'P2',
        color: '#7BAE7F',
        steps: ['查看收集箱', '确认第一段']
      },
      {
        id: 'deep_work',
        title: '深度工作',
        description: '留给最重要的一段专注',
        scheduledTime: '10:30',
        estimatedTime: 50,
        priority: 'P1',
        color: '#256D85',
        steps: ['关闭干扰', '完成一个明确产出']
      },
      {
        id: 'day_review',
        title: '收尾复盘',
        description: '回看完成、延后和明天准备',
        scheduledTime: '21:00',
        estimatedTime: 15,
        priority: 'P2',
        color: '#8A7CC3',
        steps: ['标记完成项', '挑出明天第一件事']
      }
    ];
  }

  static getDueAt(dayStart: number, time: string): number {
    const parts = time.split(':');
    const hour = parseInt(parts[0]) || 0;
    const minute = parseInt(parts[1]) || 0;
    const due = new Date(dayStart);
    due.setHours(hour, minute, 0, 0);
    return due.getTime();
  }

  static isTemplateScheduled(template: RoutineTemplate, schedules: Schedule[]): boolean {
    for (let schedule of schedules) {
      if (schedule.routineId === template.id && schedule.state !== 'cancelled') {
        return true;
      }
    }
    return false;
  }

  static getAvailableTemplates(schedules: Schedule[]): RoutineTemplate[] {
    const available: RoutineTemplate[] = [];
    for (let template of RoutineEngine.getDefaultTemplates()) {
      if (!RoutineEngine.isTemplateScheduled(template, schedules)) {
        available.push(template);
      }
    }
    return available;
  }

  static buildSteps(template: RoutineTemplate): TaskStep[] {
    const steps: TaskStep[] = [];
    const source = template.steps || [];
    for (let i = 0; i < source.length; i++) {
      steps.push({
        id: `step_${Date.now()}_${i}`,
        title: source[i],
        completed: false,
        createdAt: Date.now()
      });
    }
    return steps;
  }

  static buildTask(template: RoutineTemplate): Task {
    return {
      id: `task_${Date.now()}_${template.id}`,
      title: template.title,
      color: template.color,
      priority: template.priority,
      schedules: [],
      createdAt: Date.now(),
      updatedAt: Date.now(),
      note: template.description,
      steps: RoutineEngine.buildSteps(template),
      routineId: template.id
    };
  }

  static buildSchedule(template: RoutineTemplate, taskId: string, dayStart: number): Schedule {
    const dueAt = RoutineEngine.getDueAt(dayStart, template.scheduledTime);
    return {
      id: `schedule_${Date.now()}_${template.id}`,
      taskId,
      title: template.title,
      estimatedTime: template.estimatedTime,
      priority: template.priority,
      scheduledDate: dayStart,
      scheduledTime: template.scheduledTime,
      dueAt,
      reminderMinutes: -1,
      createdAt: Date.now(),
      stats: [0, 0, 0, 0, 0, 0],
      changeHistory: [],
      state: 'planned',
      stateNote: '常用模板',
      routineId: template.id
    };
  }
}
