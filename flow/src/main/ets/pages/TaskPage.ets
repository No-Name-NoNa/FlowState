/**
 * 任务页
 */

import { router } from '@kit.ArkUI';
import { GlassCard } from '../components/common/GlassCard';
import { DataManager } from '../utils/DataManager';
import { Task, Schedule, Priority } from '../models/DataModels';

@Entry
@Component
export struct TaskPage {
  @State tasks: Task[] = [];
  @State showAddTask: boolean = false;
  @State newTaskTitle: string = '';
  @State newTaskPriority: Priority = 'P2';
  @State newTaskColor: string = 'blue';
  @State selectedTask: Task | null = null;
  @State showAddSchedule: boolean = false;
  @State newScheduleTitle: string = '';
  @State newScheduleDuration: number = 25;
  @State showTaskStats: boolean = false;
  @State statsTask: Task | null = null;

  async aboutToAppear() {
    await this.loadTasks();
  }

  async loadTasks() {
    this.tasks = await DataManager.getAllTasks();
    // 加载每个任务的日程
    for (let task of this.tasks) {
      task.schedules = await DataManager.getTaskSchedules(task.id);
    }
  }

  async handleAddTask() {
    if (!this.newTaskTitle.trim()) return;

    const task: Task = {
      id: `task_${Date.now()}`,
      title: this.newTaskTitle,
      color: this.newTaskColor,
      priority: this.newTaskPriority,
      schedules: [],
      createdAt: Date.now(),
      isExpanded: false
    };

    await DataManager.saveTask(task);
    this.newTaskTitle = '';
    this.showAddTask = false;
    await this.loadTasks();
  }

  async handleAddSchedule() {
    if (!this.newScheduleTitle.trim() || !this.selectedTask) return;

    const schedule: Schedule = {
      id: `schedule_${Date.now()}`,
      taskId: this.selectedTask.id,
      title: this.newScheduleTitle,
      estimatedTime: this.newScheduleDuration,
      priority: this.selectedTask.priority,
      createdAt: Date.now(),
      stats: [0, 0, 0, 0, 0, 0] // 初始化统计数据
    };

    await DataManager.saveSchedule(schedule);
    this.newScheduleTitle = '';
    this.newScheduleDuration = 25;
    this.showAddSchedule = false;
    this.selectedTask = null;
    await this.loadTasks();
  }

  async toggleTaskExpand(task: Task) {
    task.isExpanded = !task.isExpanded;
    this.tasks = [...this.tasks]; // 触发更新
  }

  async handleDeleteTask(taskId: string) {
    await DataManager.deleteTask(taskId);
    // 删除该任务的所有日程
    const schedules = await DataManager.getTaskSchedules(taskId);
    for (let schedule of schedules) {
      await DataManager.deleteSchedule(schedule.id);
    }
    await this.loadTasks();
  }

  async handleDeleteSchedule(scheduleId: string) {
    await DataManager.deleteSchedule(scheduleId);
    await this.loadTasks();
  }

  // 任务项组件
  @Builder
  TaskItem(task: Task) {
    GlassCard({ content: (): void => this.TaskItemContent(task) })
      .margin({ top: 12, left: 16, right: 16 })
  }

  @Builder
  TaskItemContent(task: Task) {
    Column() {
      Row() {
        // 颜色条
        Text()
          .width(4)
          .height(20)
          .backgroundColor(task.color === 'blue' ? $r('app.color.task_blue') : $r('app.color.task_gray'))
          .borderRadius(2)
          .margin({ right: 12 })

        Text(task.title)
          .fontSize($r('app.float.subtitle_font_size'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        // 优先级标签
        Text(task.priority)
          .fontSize($r('app.float.caption_font_size'))
          .fontColor('#FFFFFF')
          .backgroundColor(
            task.priority === 'P0' ? $r('app.color.priority_p0') :
              task.priority === 'P1' ? $r('app.color.priority_p1') :
                $r('app.color.priority_p2')
          )
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(8)
          .margin({ right: 8 })

        // 统计图标
        Text('📊')
          .fontSize(20)
          .margin({ right: 8 })
          .onClick(() => {
            this.statsTask = task;
            this.showTaskStats = true;
          })

        // 展开/收起图标
        Text(task.isExpanded ? '▼' : '▶')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .onClick(() => {
            this.toggleTaskExpand(task);
          })
      }
      .width('100%')

      // 展开后显示日程列表
      if (task.isExpanded) {
        Column() {
          ForEach(task.schedules, (schedule: Schedule) => {
            this.ScheduleItem(schedule, task);
          });

          // 添加日程按钮
          Row() {
            Text('+ 添加日程')
              .fontSize($r('app.float.body_font_size'))
              .fontColor($r('app.color.primary_color'))
          }
          .width('100%')
          .padding($r('app.float.padding_sm'))
          .margin({ top: 8 })
          .borderRadius($r('app.float.button_radius'))
          .border({
            width: 1,
            color: $r('app.color.border_color'),
            style: BorderStyle.Dashed
          })
          .onClick(() => {
            this.selectedTask = task;
            this.showAddSchedule = true;
          })
        }
        .width('100%')
        .margin({ top: 12 })
      }
    }
  }

  // 日程项组件
  @Builder
  ScheduleItem(schedule: Schedule, task: Task) {
    Row() {
      Column() {
        Text(schedule.title)
          .fontSize($r('app.float.body_font_size'))
          .fontWeight(FontWeight.Medium)

        Text(`预计 ${schedule.estimatedTime} 分钟`)
          .fontSize($r('app.float.caption_font_size'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button('开始')
        .fontSize($r('app.float.caption_font_size'))
        .backgroundColor($r('app.color.accent_color'))
        .padding({ left: 16, right: 16, top: 6, bottom: 6 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/FocusPage',
            params: {
              scheduleId: schedule.id,
              taskId: task.id,
              duration: schedule.estimatedTime
            }
          });
        })
    }
    .width('100%')
    .padding($r('app.float.padding_sm'))
    .margin({ top: 8 })
    .backgroundColor('#F5F5F7')
    .borderRadius($r('app.float.button_radius'))
  }

  // 添加任务对话框
  @Builder
  AddTaskDialog() {
    if (this.showAddTask) {
      Column() {
        Text('添加任务')
          .fontSize($r('app.float.subtitle_font_size'))
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        TextInput({ placeholder: '任务标题', text: this.newTaskTitle })
          .onChange((value: string) => {
            this.newTaskTitle = value;
          })

        Row() {
          Text('优先级:')
            .margin({ right: 8 })

          Radio({ value: 'P0', group: 'priority' })
            .checked(this.newTaskPriority === 'P0')
            .onChange(() => {
              this.newTaskPriority = 'P0';
            })
          Text('P0').margin({ right: 16 })

          Radio({ value: 'P1', group: 'priority' })
            .checked(this.newTaskPriority === 'P1')
            .onChange(() => {
              this.newTaskPriority = 'P1';
            })
          Text('P1').margin({ right: 16 })

          Radio({ value: 'P2', group: 'priority' })
            .checked(this.newTaskPriority === 'P2')
            .onChange(() => {
              this.newTaskPriority = 'P2';
            })
          Text('P2')
        }
        .width('100%')
        .margin({ top: 16 })

        Row() {
          Button('取消')
            .backgroundColor($r('app.color.text_secondary'))
            .layoutWeight(1)
            .onClick(() => {
              this.showAddTask = false;
              this.newTaskTitle = '';
            })

          Button('确认')
            .backgroundColor($r('app.color.primary_color'))
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.handleAddTask();
            })
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .padding($r('app.float.padding_lg'))
      .backgroundColor($r('app.color.card_color'))
      .borderRadius($r('app.float.card_radius'))
      .width('90%')
    }
  }

  // 添加日程对话框
  @Builder
  AddScheduleDialog() {
    if (this.showAddSchedule) {
      Column() {
        Text('添加日程')
          .fontSize($r('app.float.subtitle_font_size'))
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        TextInput({ placeholder: '日程标题', text: this.newScheduleTitle })
          .onChange((value: string) => {
            this.newScheduleTitle = value;
          })

        Row() {
          Text('预估时长:')
            .margin({ right: 8 })

          TextInput({ placeholder: '25', text: this.newScheduleDuration.toString() })
            .type(InputType.Number)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.newScheduleDuration = parseInt(value) || 25;
            })

          Text('分钟')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 16 })

        Row() {
          Button('取消')
            .backgroundColor($r('app.color.text_secondary'))
            .layoutWeight(1)
            .onClick(() => {
              this.showAddSchedule = false;
              this.newScheduleTitle = '';
              this.selectedTask = null;
            })

          Button('确认')
            .backgroundColor($r('app.color.primary_color'))
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.handleAddSchedule();
            })
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .padding($r('app.float.padding_lg'))
      .backgroundColor($r('app.color.card_color'))
      .borderRadius($r('app.float.card_radius'))
      .width('90%')
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部标题栏
        Row() {
          Text('任务管理')
            .fontSize($r('app.float.title_font_size'))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding($r('app.float.padding_md'))

        // 任务列表
        Scroll() {
          Column() {
            ForEach(this.tasks, (task: Task) => {
              this.TaskItem(task);
            });

            // 添加任务按钮
            GlassCard({ content: (): void => this.AddTaskButton() })
              .margin({ top: 12, left: 16, right: 16, bottom: 16 })
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_color'))

      // 对话框层
      if (this.showAddTask || this.showAddSchedule) {
        Column() {
          this.AddTaskDialog()
          this.AddScheduleDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000040')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.showAddTask = false;
          this.showAddSchedule = false;
        })
      }
    }
  }

  @Builder
  AddTaskButton() {
    Row() {
      Text('+ 添加任务')
        .fontSize($r('app.float.body_font_size'))
        .fontColor($r('app.color.primary_color'))
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.showAddTask = true;
    })
  }
}
