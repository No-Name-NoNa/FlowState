/**
 * 记录页
 */

import { DataManager } from '../utils/DataManager';
import { TimeFormatter } from '../utils/TimeFormatter';
import { MoodEntry, FocusSession } from '../models/DataModels';

interface TimeRangeOption {
  value: string;
  label: string;
}

@Entry
@Component
export struct RecordsPage {
  @State timeRange: 'today' | 'week' | 'month' = 'today';
  @State moodEntries: MoodEntry[] = [];
  @State focusSessions: FocusSession[] = [];
  @State totalFocusTime: number = 0;
  @State completedCount: number = 0;
  @State averageMood: number = 50;

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    let startTime = 0;
    let endTime = Date.now();

    if (this.timeRange === 'today') {
      startTime = new Date().setHours(0, 0, 0, 0);
    } else if (this.timeRange === 'week') {
      const weekRange = TimeFormatter.getWeekRange();
      startTime = weekRange[0];
      endTime = weekRange[1];
    } else {
      const monthRange = TimeFormatter.getMonthRange();
      startTime = monthRange[0];
      endTime = monthRange[1];
    }

    const allMoods = await DataManager.getAllMoodEntries();
    this.moodEntries = allMoods.filter(m => m.timestamp >= startTime && m.timestamp <= endTime);
    this.focusSessions = await DataManager.getFocusSessionsInRange(startTime, endTime);
    this.totalFocusTime = this.focusSessions.reduce((sum, s) => sum + (s.completed ? s.duration : 0), 0);
    this.completedCount = this.focusSessions.filter(s => s.completed).length;

    if (this.moodEntries.length > 0) {
      const sumMood = this.moodEntries.reduce((sum, m) => sum + m.moodValue, 0);
      this.averageMood = Math.round(sumMood / this.moodEntries.length);
    } else {
      this.averageMood = 50;
    }
  }

  getMoodColor(value: number): string {
    if (value <= 30) return '#8EA1AE';
    if (value <= 55) return '#7E86A8';
    if (value <= 80) return '#2F6F86';
    return '#58B7AE';
  }

  getLowMoodCount(): number {
    return this.moodEntries.filter(m => m.moodValue <= 40).length;
  }

  getStableMoodCount(): number {
    return this.moodEntries.filter(m => m.moodValue > 40 && m.moodValue < 80).length;
  }

  getHighMoodCount(): number {
    return this.moodEntries.filter(m => m.moodValue >= 80).length;
  }

  getCompletionRate(): number {
    if (this.focusSessions.length === 0) return 0;
    return Math.round(this.completedCount * 100 / this.focusSessions.length);
  }

  @Builder
  Header() {
    Column() {
      Text('记录')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#151C22')

      Text('看见专注节奏，而不是堆砌流水账')
        .fontSize(12)
        .fontColor('#6C7A84')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 8 })
  }

  @Builder
  TimeRangeSelector() {
    Row() {
      ForEach([
        { value: 'today', label: '今天' },
        { value: 'week', label: '本周' },
        { value: 'month', label: '本月' }
      ], (range: TimeRangeOption) => {
        Text(range.label)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.timeRange === range.value ? '#FFFFFF' : '#52626D')
          .padding({ left: 24, right: 24, top: 10, bottom: 10 })
          .backgroundColor(this.timeRange === range.value ? '#2F6F86' : '#FFFFFF')
          .borderRadius(8)
          .onClick(async () => {
            this.timeRange = range.value as 'today' | 'week' | 'month';
            await this.loadData();
          })
      }, (range: TimeRangeOption) => range.value)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 6 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  SummaryPanel() {
    Column() {
      Row() {
        Column() {
          Text('总览')
            .fontSize(13)
            .fontColor('#9BAAB2')
            .fontWeight(FontWeight.Medium)

          Text(TimeFormatter.formatHours(this.totalFocusTime))
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 8 })

          Text('专注小时')
            .fontSize(12)
            .fontColor('#C7D4DA')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Stack({ alignContent: Alignment.Center }) {
          Progress({ value: this.getCompletionRate(), total: 100, type: ProgressType.Ring })
            .width(84)
            .height(84)
            .color('#58B7AE')

          Column() {
            Text(`${this.getCompletionRate()}%`)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('完成率')
              .fontSize(10)
              .fontColor('#AAB7BE')
          }
        }
        .width(92)
        .height(92)
      }
      .width('100%')

      Row() {
        this.DarkMetric(this.completedCount.toString(), '完成')
        this.DarkMetric(this.focusSessions.length.toString(), '专注段')
        this.DarkMetric(this.averageMood.toString(), '平均心情')
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 22, bottom: 22 })
    .backgroundColor('#17212A')
    .borderRadius(8)
  }

  @Builder
  DarkMetric(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(19)
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
  MoodDistribution() {
    Column() {
      Text('心情分布')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#151C22')

      Row() {
        this.DistributionItem('低能量', this.getLowMoodCount(), '#8EA1AE')
        this.DistributionItem('稳定', this.getStableMoodCount(), '#2F6F86')
        this.DistributionItem('充沛', this.getHighMoodCount(), '#58B7AE')
      }
      .width('100%')
      .margin({ top: 18 })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 18, color: '#23313A0F', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  DistributionItem(label: string, count: number, color: string) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Progress({ value: count, total: Math.max(this.moodEntries.length, 1), type: ProgressType.Ring })
          .width(66)
          .height(66)
          .color(color)

        Text(count.toString())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')
      }

      Text(label)
        .fontSize(12)
        .fontColor('#6C7A84')
        .margin({ top: 8 })
    }
    .layoutWeight(1)
  }

  @Builder
  MoodTrend() {
    Column() {
      Text('心情变化')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#151C22')
        .margin({ bottom: 14 })

      if (this.moodEntries.length === 0) {
        this.EmptyLine('暂无心情记录')
      } else {
        ForEach(this.moodEntries.slice(-7), (entry: MoodEntry) => {
          Row() {
            Text(TimeFormatter.formatTime(entry.timestamp))
              .fontSize(12)
              .fontColor('#6C7A84')
              .width(58)

            Progress({ value: entry.moodValue, total: 100, type: ProgressType.Linear })
              .layoutWeight(1)
              .height(6)
              .color(this.getMoodColor(entry.moodValue))

            Text(entry.moodLabel)
              .fontSize(12)
              .fontColor('#151C22')
              .width(46)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .margin({ bottom: 12 })
        }, (entry: MoodEntry) => entry.id)
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
  FocusHistory() {
    Column() {
      Text('专注记录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#151C22')
        .margin({ bottom: 12 })

      if (this.focusSessions.length === 0) {
        this.EmptyLine('暂无专注记录')
      } else {
        ForEach(this.focusSessions.slice(-8).reverse(), (session: FocusSession) => {
          this.SessionRow(session)
        }, (session: FocusSession) => session.id)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 18, color: '#23313A0F', offsetX: 0, offsetY: 10 })
    .margin({ top: 14, bottom: 24 })
  }

  @Builder
  SessionRow(session: FocusSession) {
    Row() {
      Text()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(session.completed ? '#58B7AE' : '#8EA1AE')
        .margin({ right: 12 })

      Column() {
        Text(session.completed ? '完成专注' : '中断专注')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#151C22')

        Text(TimeFormatter.formatDateTime(session.startTime))
          .fontSize(11)
          .fontColor('#6C7A84')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(`${session.duration} 分钟`)
        .fontSize(12)
        .fontColor('#52626D')
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  EmptyLine(text: string) {
    Text(text)
      .fontSize(13)
      .fontColor('#8EA1AE')
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding({ top: 28, bottom: 28 })
  }

  build() {
    Column() {
      this.Header()
      this.TimeRangeSelector()

      Scroll() {
        Column() {
          this.SummaryPanel()
          this.MoodDistribution()
          this.MoodTrend()
          this.FocusHistory()
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
