/**
 * 首页
 */

import { router } from '@kit.ArkUI';
import { GlassCard } from '../components/common/GlassCard';
import { DataManager } from '../utils/DataManager';
import { MoodEngine } from '../utils/MoodEngine';
import { TimeFormatter } from '../utils/TimeFormatter';
import { MoodEntry, RecommendMode } from '../models/DataModels';

interface MoodOption {
  label: string;
  value: number;
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

  async aboutToAppear() {
    this.todayDate = TimeFormatter.formatDate(Date.now());
    await this.loadData();
  }

  async loadData() {
    // 加载今日情绪记录
    const todayMoods = await DataManager.getTodayMoodEntries();
    if (todayMoods.length > 0) {
      const latest = todayMoods[todayMoods.length - 1];
      this.currentMood = latest.moodValue;
      this.moodHistory = todayMoods.map(m => m.moodValue);
    }

    // 获取推荐
    this.recommendation = MoodEngine.getRecommendation(this.currentMood);

    // 加载今日专注数据
    this.totalFocusTime = await DataManager.getTodayTotalFocusTime();
    this.completedCount = await DataManager.getTodayCompletedCount();
  }

  async handleMoodCheckIn() {
    if (!this.showMoodSheet) {
      this.showMoodSheet = true;
      return;
    }

    // 保存情绪记录
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

  // 心情快捷打卡
  @Builder
  MoodQuickCheckIn() {
    Row() {
      ForEach([
        { label: '😴 疲惫', value: 25 },
        { label: '😰 焦虑', value: 50 },
        { label: '😐 平淡', value: 75 },
        { label: '🙂 平静', value: 85 },
        { label: '⚡ 充沛', value: 100 }
      ], (mood: MoodOption) => {
        Button(mood.label)
          .backgroundColor('#FFFFFF')
          .fontColor($r('app.color.text_color'))
          .fontSize($r('app.float.body_font_size'))
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius($r('app.float.button_radius'))
          .onClick(async () => {
            this.currentMood = mood.value;
            await this.handleMoodCheckIn();
          })
      }, (mood: MoodOption) => mood.label)
    }
    .width('100%')
    .padding($r('app.float.padding_md'))
    .justifyContent(FlexAlign.SpaceBetween)
  }

  // 心情记录卡片
  @Builder
  MoodRecordCard() {
    GlassCard({ content: (): void => this.MoodRecordContent() })
      .margin({ top: 16, left: 16, right: 16 })
  }

  @Builder
  MoodRecordContent() {
    Column() {
      Row() {
        Text('当前心情')
          .fontSize($r('app.float.subtitle_font_size'))
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(MoodEngine.getMoodEmoji(this.currentMood) + ' ' + MoodEngine.getMoodLabel(this.currentMood))
          .fontSize($r('app.float.body_font_size'))
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')

      // 心情值滑块
      Row() {
        Slider({
          value: this.currentMood,
          min: 0,
          max: 100,
          step: 5
        })
          .width('100%')
          .onChange((value: number) => {
            this.currentMood = value;
          })
      }
      .margin({ top: 16 })

      // 推荐模式
      if (this.recommendation) {
        Text(`推荐: ${this.recommendation.modeName} (${this.recommendation.suggestedDuration}分钟)`)
          .fontSize($r('app.float.caption_font_size'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 8 })

        Text(this.recommendation.description)
          .fontSize($r('app.float.caption_font_size'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }

      // 备注输入
      if (this.showMoodSheet) {
        TextInput({ placeholder: '记录此刻心境（可选）', text: this.moodNote })
          .width('100%')
          .margin({ top: 16 })
          .onChange((value: string) => {
            this.moodNote = value;
          })
      }

      // 打卡按钮
      Button(this.showMoodSheet ? '确认打卡' : '心情打卡')
        .width('100%')
        .margin({ top: 16 })
        .backgroundColor($r('app.color.primary_color'))
        .onClick(() => {
          this.handleMoodCheckIn();
        })
    }
  }

  // 专注快捷卡片
  @Builder
  FocusQuickCard() {
    GlassCard({ content: (): void => this.FocusContent() })
      .margin({ top: 16, left: 16, right: 16 })
  }

  @Builder
  FocusContent() {
    Row() {
      Column() {
        Text('🎯 开始专注')
          .fontSize($r('app.float.subtitle_font_size'))
          .fontWeight(FontWeight.Bold)

        if (this.recommendation) {
          Text(`建议时长: ${this.recommendation.suggestedDuration}分钟`)
            .fontSize($r('app.float.caption_font_size'))
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Button('开始')
        .backgroundColor($r('app.color.accent_color'))
        .onClick(() => {
          router.pushUrl({
            url: 'pages/FocusPage',
            params: {
              duration: this.recommendation?.suggestedDuration || 25
            }
          });
        })
    }
    .width('100%')
  }

  // AI 节律洞察卡片
  @Builder
  AIInsightCard() {
    GlassCard({ content: (): void => this.AIInsightContent() })
      .margin({ top: 16, left: 16, right: 16 })
  }

  @Builder
  AIInsightContent() {
    Column() {
      Row() {
        Text('🧠 AI 节律洞察')
          .fontSize($r('app.float.subtitle_font_size'))
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')

      Row() {
        Column() {
          Text(TimeFormatter.formatHours(this.totalFocusTime))
            .fontSize($r('app.float.large_font_size'))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.primary_color'))

          Text('专注时长(h)')
            .fontSize($r('app.float.caption_font_size'))
            .fontColor($r('app.color.text_secondary'))
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
        }
      }
      .width('100%')
      .margin({ top: 16 })

      Text(MoodEngine.generateAIInsight(this.totalFocusTime, this.moodHistory, this.completedCount))
        .fontSize($r('app.float.body_font_size'))
        .fontColor($r('app.color.text_color'))
        .margin({ top: 16 })
    }
  }

  // AI 计划制定卡片
  @Builder
  AIPlanCard() {
    GlassCard({ content: (): void => this.AIPlanContent() })
      .margin({ top: 16, left: 16, right: 16, bottom: 16 })
  }

  @Builder
  AIPlanContent() {
    Column() {
      Text('🤖 AI 计划制定')
        .fontSize($r('app.float.subtitle_font_size'))
        .fontWeight(FontWeight.Bold)

      Text('告诉我你的目标，让 AI 帮你拆解任务')
        .fontSize($r('app.float.caption_font_size'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })

      Button('开始制定')
        .width('100%')
        .margin({ top: 16 })
        .backgroundColor($r('app.color.primary_color'))
        .onClick(() => {
          // TODO: 实现 AI 计划制定功能
        })
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Column() {
          Text('Flow State')
            .fontSize($r('app.float.title_font_size'))
            .fontWeight(FontWeight.Bold)

          Text(this.todayDate + ' ' + TimeFormatter.getWeekdayName(Date.now()))
            .fontSize($r('app.float.caption_font_size'))
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Row() {
          Image($r('app.media.startIcon'))
            .width(32)
            .height(32)
            .borderRadius(16)
            .margin({ right: 12 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/LoginPage' });
            })

          Text('⚙️')
            .fontSize(24)
            .onClick(() => {
              router.pushUrl({ url: 'pages/SettingsPage' });
            })
        }
      }
      .width('100%')
      .padding($r('app.float.padding_md'))

      // 滚动内容区
      Scroll() {
        Column() {
          this.MoodQuickCheckIn()
          this.MoodRecordCard()
          this.FocusQuickCard()
          this.AIInsightCard()
          this.AIPlanCard()
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
  }
}
