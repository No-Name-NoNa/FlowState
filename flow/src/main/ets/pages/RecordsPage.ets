/**
 * 记录页
 */

import { GlassCard } from '../components/common/GlassCard';
import { DataManager } from '../utils/DataManager';
import { TimeFormatter } from '../utils/TimeFormatter';
import { MoodEntry, FocusSession } from '../models/DataModels';

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
    } else if (this.timeRange === 'month') {
      const monthRange = TimeFormatter.getMonthRange();
      startTime = monthRange[0];
      endTime = monthRange[1];
    }

    // 加载情绪记录
    const allMoods = await DataManager.getAllMoodEntries();
    this.moodEntries = allMoods.filter(m => m.timestamp >= startTime && m.timestamp <= endTime);

    // 加载专注记录
    this.focusSessions = await DataManager.getFocusSessionsInRange(startTime, endTime);

    // 计算统计数据
    this.totalFocusTime = this.focusSessions.reduce((sum, s) => sum + (s.completed ? s.duration : 0), 0);
    this.completedCount = this.focusSessions.filter(s => s.completed).length;

    if (this.moodEntries.length > 0) {
      const sumMood = this.moodEntries.reduce((sum, m) => sum + m.moodValue, 0);
      this.averageMood = Math.round(sumMood / this.moodEntries.length);
    }
  }

  // 时间范围选择器
  @Builder
  TimeRangeSelector() {
    Row() {
      ForEach([
        { value: 'today', label: '今天' },
        { value: 'week', label: '本周' },
        { value: 'month', label: '本月' }
      ], (range: { value: string, label: string }) => {
        Button(range.label)
          .fontSize($r('app.float.body_font_size'))
          .backgroundColor(this.timeRange === range.value ? $r('app.color.primary_color') : $r('app.color.card_color'))
          .fontColor(this.timeRange === range.value ? '#FFFFFF' : $r('app.color.text_color'))
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .onClick(async () => {
            this.timeRange = range.value as 'today' | 'week' | 'month';
            await this.loadData();
          })
      }, (range: { value: string, label: string }) => range.value)
    }
    .width('100%')
    .padding($r('app.float.padding_md'))
    .justifyContent(FlexAlign.SpaceAround)
  }

  // 统计卡片
  @Builder
  StatsCard() {
    GlassCard({ content: (): void => this.StatsContent() })
      .margin({ top: 12, left: 16, right: 16 })
  }

  @Builder
  StatsContent() {
    Row() {
      Column() {
        Text(TimeFormatter.formatHours(this.totalFocusTime))
          .fontSize($r('app.float.large_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_color'))

        Text('专注时长(h)')
          .fontSize($r('app.float.caption_font_size'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }

      Blank()

      Column() {
        Text(this.completedCount.toString())
          .fontSize($r('app.float.large_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.accent_color'))

        Text('完成次数')
          .fontSize($r('app.float.caption_font_size'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }

      Blank()

      Column() {
        Text(this.averageMood.toString())
          .fontSize($r('app.float.large_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.warning_color'))

        Text('平均心情')
          .fontSize($r('app.float.caption_font_size'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
    }
    .width('100%')
  }

  // 情绪热力图
  @Builder
  MoodHeatmap() {
    GlassCard({ content: (): void => this.HeatmapContent() })
      .margin({ top: 16, left: 16, right: 16 })
  }

  @Builder
  HeatmapContent() {
    Column() {
      Text('情绪变化')
        .fontSize($r('app.float.subtitle_font_size'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      // 简化的热力图显示
      Column() {
        ForEach(this.moodEntries.slice(-7), (entry: MoodEntry) => {
          Row() {
            Text(TimeFormatter.formatDateTime(entry.timestamp))
              .fontSize($r('app.float.caption_font_size'))
              .fontColor($r('app.color.text_secondary'))
              .width(120)

            Progress({
              value: entry.moodValue,
              total: 100,
              type: ProgressType.Linear
            })
              .width(150)
              .color(
                entry.moodValue >= 80 ? $r('app.color.success_color') :
                  entry.moodValue >= 60 ? $r('app.color.primary_color') :
                    entry.moodValue >= 40 ? $r('app.color.warning_color') :
                      $r('app.color.error_color')
              )

            Text(entry.moodLabel)
              .fontSize($r('app.float.caption_font_size'))
              .fontColor($r('app.color.text_color'))
              .margin({ left: 12 })
          }
          .width('100%')
          .margin({ bottom: 12 })
        });
      }
    }
  }

  // 专注记录时间轴
  @Builder
  FocusTimeline() {
    GlassCard({ content: (): void => this.TimelineContent() })
      .margin({ top: 16, left: 16, right: 16, bottom: 16 })
  }

  @Builder
  TimelineContent() {
    Column() {
      Text('专注记录')
        .fontSize($r('app.float.subtitle_font_size'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      if (this.focusSessions.length === 0) {
        Text('暂无专注记录')
          .fontSize($r('app.float.body_font_size'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 32, bottom: 32 })
      } else {
        Column() {
          ForEach(this.focusSessions.slice(-10).reverse(), (session: FocusSession) => {
            Row() {
              // 时间轴圆点
              Column() {
                Text()
                  .width(12)
                  .height(12)
                  .borderRadius(6)
                  .backgroundColor(session.completed ? $r('app.color.success_color') : $r('app.color.text_secondary'))

                if (this.focusSessions.indexOf(session) < this.focusSessions.length - 1) {
                  Text()
                    .width(2)
                    .height(40)
                    .backgroundColor($r('app.color.border_color'))
                }
              }
              .width(20)
              .margin({ right: 12 })

              Column() {
                Row() {
                  Text(session.completed ? '✓ 已完成' : '✗ 未完成')
                    .fontSize($r('app.float.body_font_size'))
                    .fontColor(session.completed ? $r('app.color.success_color') : $r('app.color.text_secondary'))
                    .fontWeight(FontWeight.Medium)

                  Blank()

                  Text(`${session.duration} 分钟`)
                    .fontSize($r('app.float.caption_font_size'))
                    .fontColor($r('app.color.text_secondary'))
                }
                .width('100%')

                Text(TimeFormatter.formatDateTime(session.startTime))
                  .fontSize($r('app.float.caption_font_size'))
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ top: 4 })

                if (session.reflection) {
                  Text(session.reflection)
                    .fontSize($r('app.float.caption_font_size'))
                    .fontColor($r('app.color.text_color'))
                    .margin({ top: 8 })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
              }
              .layoutWeight(1)
              .padding({ bottom: 16 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          });
        }
      }
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('记录')
          .fontSize($r('app.float.title_font_size'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding($r('app.float.padding_md'))

      // 时间范围选择
      this.TimeRangeSelector()

      // 滚动内容区
      Scroll() {
        Column() {
          this.StatsCard()
          this.MoodHeatmap()
          this.FocusTimeline()
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
  }
}
