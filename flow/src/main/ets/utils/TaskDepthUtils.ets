/**
 * Shared helpers for task notes, priority, and subtasks.
 */

import { Priority, Task, TaskStep } from '../models/DataModels';

export interface TaskDepthDraft {
  note: string;
  steps: TaskStep[];
  newStepTitle: string;
  expanded: boolean;
}

export class TaskDepthUtils {
  static emptyDraft(): TaskDepthDraft {
    return {
      note: '',
      steps: [],
      newStepTitle: '',
      expanded: false
    };
  }

  static createDraft(task: Task | null): TaskDepthDraft {
    return {
      note: TaskDepthUtils.getNote(task),
      steps: TaskDepthUtils.cloneSteps(TaskDepthUtils.getSteps(task)),
      newStepTitle: '',
      expanded: false
    };
  }

  static getNote(task: Task | null): string {
    return task && task.note ? task.note : '';
  }

  static getSteps(task: Task | null): TaskStep[] {
    return task && task.steps ? task.steps : [];
  }

  static cloneSteps(steps: TaskStep[]): TaskStep[] {
    const next: TaskStep[] = [];
    for (let step of steps) {
      next.push({
        id: step.id,
        title: step.title,
        completed: step.completed,
        createdAt: step.createdAt
      });
    }
    return next;
  }

  static getStepSummary(steps: TaskStep[]): string {
    if (steps.length === 0) return '';
    let completed = 0;
    for (let step of steps) {
      if (step.completed) {
        completed++;
      }
    }
    return `${completed}/${steps.length}`;
  }

  static getDraftStepSummary(steps: TaskStep[]): string {
    const summary = TaskDepthUtils.getStepSummary(steps);
    return summary.length > 0 ? summary : '0/0';
  }

  static getDepthHint(note: string, steps: TaskStep[]): string {
    const hasNote = note.trim().length > 0;
    const stepSummary = TaskDepthUtils.getStepSummary(steps);
    if (hasNote && stepSummary.length > 0) {
      return `有备注 · 子任务 ${stepSummary}`;
    }
    if (hasNote) {
      return '有备注';
    }
    if (stepSummary.length > 0) {
      return `子任务 ${stepSummary}`;
    }
    return '可选：备注、优先级、子任务';
  }

  static hasStepTitle(title: string): boolean {
    return title.trim().length > 0;
  }

  static addStep(steps: TaskStep[], title: string): TaskStep[] {
    const cleanTitle = title.trim();
    if (cleanTitle.length === 0) {
      return TaskDepthUtils.cloneSteps(steps);
    }
    const next = TaskDepthUtils.cloneSteps(steps);
    next.push({
      id: `step_${Date.now()}`,
      title: cleanTitle,
      completed: false,
      createdAt: Date.now()
    });
    return next;
  }

  static toggleStep(steps: TaskStep[], stepId: string): TaskStep[] {
    const next: TaskStep[] = [];
    for (let step of steps) {
      next.push({
        id: step.id,
        title: step.title,
        completed: step.id === stepId ? !step.completed : step.completed,
        createdAt: step.createdAt
      });
    }
    return next;
  }

  static deleteStep(steps: TaskStep[], stepId: string): TaskStep[] {
    const next: TaskStep[] = [];
    for (let step of steps) {
      if (step.id !== stepId) {
        next.push({
          id: step.id,
          title: step.title,
          completed: step.completed,
          createdAt: step.createdAt
        });
      }
    }
    return next;
  }

  static buildTaskWithToggledStep(task: Task, stepId: string): Task {
    return TaskDepthUtils.buildUpdatedTask(
      task,
      task.title,
      task.priority,
      task.note || '',
      TaskDepthUtils.toggleStep(task.steps || [], stepId)
    );
  }

  static buildUpdatedTask(task: Task, title: string, priority: Priority, note: string, steps: TaskStep[]): Task {
    return {
      id: task.id,
      title: title.trim().length > 0 ? title.trim() : task.title,
      color: task.color,
      priority,
      schedules: task.schedules,
      createdAt: task.createdAt,
      updatedAt: Date.now(),
      note,
      steps: TaskDepthUtils.cloneSteps(steps),
      isExpanded: task.isExpanded,
      routineId: task.routineId
    };
  }
}
