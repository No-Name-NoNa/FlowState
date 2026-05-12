/**
 * 首页
 */

import { router } from '@kit.ArkUI';
import { DataManager } from '../utils/DataManager';
import { MoodEngine } from '../utils/MoodEngine';
import { TimeFormatter } from '../utils/TimeFormatter';
import { MoodEntry, RecommendMode, Schedule } from '../models/DataModels';

interface MoodOption {
  label: string;
  value: number;
  icon: Resource;
}

@Entry
@Component
export struct HomePage {
  @State todayDate: string = '';
  @State currentMood: number = 50;
  @State moodHistory: number[] = [];
  @State recommendation: RecommendMode | null = null;
  @State totalFocusTime: number = 0;
  @State completedCount: number = 0;
  @State showMoodSheet: boolean = false;
  @State moodNote: string = '';
  @State nextScheduleTitle: string = '';
  @State nextScheduleMeta: string = '';
  @State nextScheduleId: string = '';
  @State nextTaskId: string = '';
  @State nextDuration: number = 25;
  @State plannedMinutes: number = 0;
  @State scheduledCount: number = 0;

  private readonly moodOptions: MoodOption[] = [
    { label: '疲惫', value: 25, icon: $r('sys.symbol.face_sleeping') },
    { label: '焦虑', value: 50, icon: $r('sys.symbol.face_sading') },
    { label: '平稳', value: 75, icon: $r('sys.symbol.face') },
    { label: '平静', value: 85, icon: $r('sys.symbol.face_smiling') },
    { label: '充沛', value: 100, icon: $r('sys.symbol.face_smiling_fill') }
  ];

  async aboutToAppear() {
    this.todayDate = TimeFormatter.formatDate(Date.now());
    await this.loadData();
  }

  async loadData() {
    const todayMoods = await DataManager.getTodayMoodEntries();
    if (todayMoods.length > 0) {
      const latest = todayMoods[todayMoods.length - 1];
      this.currentMood = latest.moodValue;
      this.moodHistory = todayMoods.map(m => m.moodValue);
    }

    this.recommendation = MoodEngine.getRecommendation(this.currentMood);
    this.totalFocusTime = await DataManager.getTodayTotalFocusTime();
    this.completedCount = await DataManager.getTodayCompletedCount();
    await this.loadNextAction();
  }

  async loadNextAction() {
    const schedules = await DataManager.getAllSchedules();
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStart = today.getTime();
    const todayEnd = todayStart + 24 * 60 * 60 * 1000;
    this.scheduledCount = 0;
    this.plannedMinutes = 0;
    for (let schedule of schedules) {
      const due = this.getScheduleDueAt(schedule);
      if (due >= todayStart && due < todayEnd) {
        this.scheduledCount++;
        this.plannedMinutes += schedule.estimatedTime;
      }
    }

    const now = Date.now();
    const upcoming = schedules
      .filter((schedule: Schedule) => this.getScheduleDueAt(schedule) >= now)
      .sort((a: Schedule, b: Schedule) => this.getScheduleDueAt(a) - this.getScheduleDueAt(b));

    if (upcoming.length > 0) {
      const next = upcoming[0];
      this.nextScheduleTitle = next.title;
      this.nextScheduleMeta = `${this.formatScheduleDateTime(next)} · ${next.estimatedTime} 分钟`;
      this.nextScheduleId = next.id;
      this.nextTaskId = next.taskId;
      this.nextDuration = next.estimatedTime;
    } else {
      this.nextScheduleTitle = '安排下一段时间';
      this.nextScheduleMeta = '从任务页挑一个目标，放进今天的时间线';
      this.nextScheduleId = '';
      this.nextTaskId = '';
      this.nextDuration = this.getSuggestedDuration();
    }
  }

  async saveMood() {
    const entry: MoodEntry = {
      id: `mood_${Date.now()}`,
      timestamp: Date.now(),
      moodValue: this.currentMood,
      moodLabel: MoodEngine.getMoodLabel(this.currentMood),
      note: this.moodNote
    };

    await DataManager.saveMoodEntry(entry);
    this.showMoodSheet = false;
    this.moodNote = '';
    await this.loadData();
  }

  getSuggestedDuration(): number {
    return this.recommendation?.suggestedDuration || 25;
  }

  getMoodAccent(value: number): string {
    if (value <= 30) return '#8EA1AE';
    if (value <= 55) return '#7E86A8';
    if (value <= 80) return '#2F6F86';
    return '#58B7AE';
  }

  getScheduleDueAt(schedule: Schedule): number {
    if (schedule.dueAt) return schedule.dueAt;
    const date = schedule.scheduledDate || new Date().setHours(0, 0, 0, 0);
    const time = schedule.scheduledTime || '09:00';
    const parts = time.split(':');
    const hour = parseInt(parts[0]) || 0;
    const minute = parseInt(parts[1]) || 0;
    const due = new Date(date);
    due.setHours(hour, minute, 0, 0);
    return due.getTime();
  }

  formatScheduleDateTime(schedule: Schedule): string {
    const date = schedule.scheduledDate || new Date().setHours(0, 0, 0, 0);
    const target = new Date(date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const diff = Math.round((target.getTime() - today.getTime()) / (24 * 60 * 60 * 1000));
    let label = `${target.getMonth() + 1}/${target.getDate()}`;
    if (diff === 0) label = '今天';
    if (diff === 1) label = '明天';
    return `${label} ${schedule.scheduledTime || '09:00'}`;
  }

  hasNextSchedule(): boolean {
    return this.nextScheduleId.length > 0;
  }

  @Builder
  AppHeader() {
    Row() {
      Column() {
        Text('Flow State')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')

        Text(`${this.todayDate} ${TimeFormatter.getWeekdayName(Date.now())}`)
          .fontSize(12)
          .fontColor('#6C7A84')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button() {
        SymbolGlyph($r('sys.symbol.barrage_setting'))
          .fontSize(22)
          .fontColor(['#151C22'])
      }
      .width(44)
      .height(44)
      .borderRadius(8)
      .backgroundColor('#FFFFFF')
      .onClick(() => {
        router.pushUrl({ url: 'pages/SettingsPage' });
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 8 })
  }

  @Builder
  TodayDashboard() {
    Column() {
      Row() {
        Column() {
          Text('今日状态')
            .fontSize(13)
            .fontColor('#AAB7BE')
            .fontWeight(FontWeight.Medium)

          Text(this.recommendation ? this.recommendation.modeName : '标准专注')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 8 })

          Text(this.recommendation ? this.recommendation.description : '从一个明确的小任务开始。')
            .fontSize(13)
            .fontColor('#C7D4DA')
            .margin({ top: 8 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Stack({ alignContent: Alignment.Center }) {
          Progress({ value: this.currentMood, total: 100, type: ProgressType.Ring })
            .width(76)
            .height(76)
            .color(this.getMoodAccent(this.currentMood))

          Column() {
            Text(this.currentMood.toString())
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            Text('心情')
              .fontSize(10)
              .fontColor('#AAB7BE')
          }
        }
        .width(84)
        .height(84)
      }
      .width('100%')

      Row() {
        this.DashboardMetric(TimeFormatter.formatHours(this.totalFocusTime), '专注小时')
        this.DashboardMetric(this.completedCount.toString(), '完成次数')
        this.DashboardMetric(this.scheduledCount.toString(), '已排日程')
      }
      .width('100%')
      .margin({ top: 22 })

      Button() {
        Row() {
          SymbolGlyph($r('sys.symbol.clock'))
            .fontSize(18)
            .fontColor(['#FFFFFF'])
            .margin({ right: 8 })

          Text('开始专注')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height(50)
      .margin({ top: 22 })
      .borderRadius(8)
      .backgroundColor('#2F6F86')
      .onClick(() => {
        router.pushUrl({
          url: 'pages/FocusPage',
          params: { duration: this.getSuggestedDuration() }
        });
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 22, bottom: 22 })
    .backgroundColor('#17212A')
    .borderRadius(8)
  }

  @Builder
  NextActionCard() {
    Row() {
      Column() {
        Text('下一步')
          .fontSize(12)
          .fontColor('#6C7A84')
          .fontWeight(FontWeight.Medium)

        Text(this.nextScheduleTitle)
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })

        Text(this.nextScheduleMeta)
          .fontSize(12)
          .fontColor('#6C7A84')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button(this.hasNextSchedule() ? '开始' : '计划')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(72)
        .height(44)
        .borderRadius(8)
        .backgroundColor(this.hasNextSchedule() ? '#58B7AE' : '#2F6F86')
        .onClick(() => {
          if (this.hasNextSchedule()) {
            router.pushUrl({
              url: 'pages/FocusPage',
              params: {
                duration: this.nextDuration,
                scheduleId: this.nextScheduleId,
                taskId: this.nextTaskId
              }
            });
          } else {
            router.pushUrl({ url: 'pages/TaskPage' });
          }
        })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 18, color: '#23313A0F', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  DashboardMetric(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text(label)
        .fontSize(11)
        .fontColor('#9BAAB2')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  MoodPanel() {
    Column() {
      Row() {
        Column() {
          Text('心情校准')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#151C22')

          Text(MoodEngine.getMoodLabel(this.currentMood))
            .fontSize(12)
            .fontColor(this.getMoodAccent(this.currentMood))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button(this.showMoodSheet ? '收起' : '记录')
          .fontSize(12)
          .fontColor('#2F6F86')
          .backgroundColor('#EAF2F5')
          .borderRadius(8)
          .onClick(() => {
            this.showMoodSheet = !this.showMoodSheet;
          })
      }
      .width('100%')

      Row() {
        ForEach(this.moodOptions, (mood: MoodOption) => {
          this.MoodChip(mood)
        }, (mood: MoodOption) => mood.label)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 16 })

      if (this.showMoodSheet) {
        TextArea({ placeholder: '给当前状态留一句备注', text: this.moodNote })
          .width('100%')
          .height(88)
          .margin({ top: 16 })
          .backgroundColor('#F5F8F9')
          .borderRadius(8)
          .onChange((value: string) => {
            this.moodNote = value;
          })

        Button('保存心情')
          .width('100%')
          .height(44)
          .fontColor('#FFFFFF')
          .backgroundColor('#2F6F86')
          .borderRadius(8)
          .margin({ top: 12 })
          .onClick(() => {
            this.saveMood();
          })
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 18, color: '#23313A0F', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  MoodChip(mood: MoodOption) {
    Column() {
      SymbolGlyph(mood.icon)
        .fontSize(18)
        .fontColor([this.currentMood === mood.value ? '#FFFFFF' : this.getMoodAccent(mood.value)])

      Text(mood.label)
        .fontSize(11)
        .fontColor(this.currentMood === mood.value ? '#FFFFFF' : '#51606A')
        .margin({ top: 4 })
    }
    .width(54)
    .height(58)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.currentMood === mood.value ? this.getMoodAccent(mood.value) : '#F4F7F8')
    .borderRadius(8)
    .onClick(() => {
      this.currentMood = mood.value;
      this.recommendation = MoodEngine.getRecommendation(this.currentMood);
    })
  }

  @Builder
  RhythmCard() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.calendar'))
          .fontSize(20)
          .fontColor(['#2F6F86'])
          .margin({ right: 8 })

        Text('今日节律')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')
      }
      .width('100%')

      Row() {
        this.RhythmItem('下一段', `${this.getSuggestedDuration()} 分钟`)
        this.RhythmItem('计划量', `${this.plannedMinutes} 分钟`)
        this.RhythmItem('状态', MoodEngine.getMoodLabel(this.currentMood))
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 18, color: '#23313A0F', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  RhythmItem(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#151C22')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(label)
        .fontSize(11)
        .fontColor('#6C7A84')
        .margin({ top: 5 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  QuickActions() {
    Row() {
      this.ActionButton('整理任务', '进入计划页', 'pages/TaskPage')
      Blank()
      this.ActionButton('查看记录', '复盘节奏', 'pages/RecordsPage')
    }
    .width('100%')
    .margin({ top: 14, bottom: 24 })
  }

  @Builder
  ActionButton(title: string, subtitle: string, url: string) {
    Column() {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#151C22')

      Text(subtitle)
        .fontSize(11)
        .fontColor('#6C7A84')
        .margin({ top: 5 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding({ left: 16, right: 16, top: 15, bottom: 15 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      router.pushUrl({ url });
    })
  }

  build() {
    Column() {
      this.AppHeader()

      Scroll() {
        Column() {
          this.TodayDashboard()
          this.NextActionCard()
          this.MoodPanel()
          this.RhythmCard()
          this.QuickActions()
        }
        .padding({ left: 16, right: 16, top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F7F8')
  }
}
