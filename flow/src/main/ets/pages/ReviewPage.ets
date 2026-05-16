/**
 * Review-first analytics surface.
 */

import { DataManager } from '../utils/DataManager';
import { NavigationManager } from '../utils/NavigationManager';
import { ReviewAnalyzer, ReviewDayStat, ReviewInsight, ReviewReport } from '../utils/ReviewAnalyzer';
import { TimeFormatter } from '../utils/TimeFormatter';
import { FocusSession, MoodEntry, Schedule, ScheduleArchiveEntry, ScheduleChange } from '../models/DataModels';

type ReviewRange = 'today' | 'week';

@Component
export struct ReviewPage {
  @State focusSessions: FocusSession[] = [];
  @State moodEntries: MoodEntry[] = [];
  @State schedules: Schedule[] = [];
  @State archiveEntries: ScheduleArchiveEntry[] = [];
  @State changes: ScheduleChange[] = [];
  @State totalFocusMinutes: number = 0;
  @State completedCount: number = 0;
  @State completedScheduleCount: number = 0;
  @State plannedBlockCount: number = 0;
  @State delayedCount: number = 0;
  @State advancedCount: number = 0;
  @State editedCount: number = 0;
  @State deletedCount: number = 0;
  @State averageMood: number = 50;
  @State estimateDeltaMinutes: number = 0;
  @State dailyCapacityMinutes: number = 300;
  @State selectedRange: ReviewRange = 'today';
  @State weekStats: ReviewDayStat[] = [];
  @State reviewReport: ReviewReport = ReviewAnalyzer.buildReport([], [], [], 300);

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    const range = this.getActiveRange();
    const settings = await DataManager.getUserSettings();
    const allFocusSessions = await DataManager.getAllFocusSessions();
    const allMoodEntries = await DataManager.getAllMoodEntries();
    this.dailyCapacityMinutes = settings.dailyCapacityMinutes || 300;
    this.focusSessions = allFocusSessions.filter((session: FocusSession) => this.isTimestampInRange(session.startTime, range));
    this.moodEntries = allMoodEntries.filter((entry: MoodEntry) => this.isTimestampInRange(entry.timestamp, range));
    this.schedules = await DataManager.getAllSchedules();
    this.weekStats = ReviewAnalyzer.buildWeeklyDayStats(this.schedules, allFocusSessions);
    this.archiveEntries = await DataManager.getScheduleArchiveEntriesInRange(range[0], range[1]);
    this.changes = [];
    this.totalFocusMinutes = 0;
    this.completedCount = 0;
    this.completedScheduleCount = 0;
    this.plannedBlockCount = 0;
    this.delayedCount = 0;
    this.advancedCount = 0;
    this.editedCount = 0;
    this.deletedCount = this.archiveEntries.length;
    this.estimateDeltaMinutes = 0;
    this.averageMood = 50;

    for (let session of this.focusSessions) {
      if (session.completed) {
        this.completedCount++;
        this.totalFocusMinutes += session.duration;
      }
    }

    let estimateSamples = 0;
    for (let schedule of this.schedules) {
      if (this.isScheduleRelevantInRange(schedule, range)) {
        this.plannedBlockCount++;
      }
      if (schedule.state === 'completed' && schedule.completedAt && this.isTimestampInRange(schedule.completedAt, range)) {
        this.completedScheduleCount++;
        if (schedule.actualMinutes !== undefined) {
          this.estimateDeltaMinutes += schedule.actualMinutes - schedule.estimatedTime;
          estimateSamples++;
        }
      }
      for (let change of schedule.changeHistory || []) {
        if (this.isTimestampInRange(change.timestamp, range)) {
          this.changes.push(change);
          if (change.type === 'delay' || change.type === 'carryover') this.delayedCount++;
          if (change.type === 'advance') this.advancedCount++;
          if (change.type === 'edit') this.editedCount++;
        }
      }
    }

    if (estimateSamples > 0) {
      this.estimateDeltaMinutes = Math.round(this.estimateDeltaMinutes / estimateSamples);
    }

    if (this.moodEntries.length > 0) {
      let sum = 0;
      for (let mood of this.moodEntries) {
        sum += mood.moodValue;
      }
      this.averageMood = Math.round(sum / this.moodEntries.length);
    }

    this.reviewReport = ReviewAnalyzer.buildReportForRange(this.schedules, this.archiveEntries, this.focusSessions, this.dailyCapacityMinutes, range, this.getRangeLabel());
  }

  getTodayRange(): [number, number] {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return [today.getTime(), today.getTime() + 24 * 60 * 60 * 1000 - 1];
  }

  isTimestampToday(timestamp: number): boolean {
    const range = this.getTodayRange();
    return timestamp >= range[0] && timestamp <= range[1];
  }

  getActiveRange(): [number, number] {
    if (this.selectedRange === 'week') {
      return TimeFormatter.getWeekRange();
    }
    return this.getTodayRange();
  }

  getRangeLabel(): string {
    if (this.selectedRange === 'week') return '本周';
    return '今天';
  }

  isTimestampInRange(timestamp: number, range: [number, number]): boolean {
    return timestamp >= range[0] && timestamp <= range[1];
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

  isScheduleRelevantInRange(schedule: Schedule, range: [number, number]): boolean {
    if (this.isTimestampInRange(this.getScheduleDueAt(schedule), range)) return true;
    if (schedule.completedAt && this.isTimestampInRange(schedule.completedAt, range)) return true;
    if (schedule.deferredAt && this.isTimestampInRange(schedule.deferredAt, range)) return true;
    for (let change of schedule.changeHistory || []) {
      if (this.isTimestampInRange(change.timestamp, range)) return true;
    }
    return false;
  }

  getCompletionRate(): number {
    if (this.plannedBlockCount === 0) return 0;
    return Math.round(this.completedScheduleCount * 100 / this.plannedBlockCount);
  }

  getPlanningChangeCount(): number {
    return this.delayedCount + this.advancedCount + this.editedCount + this.deletedCount;
  }

  getNarrative(): string {
    return this.reviewReport.summary;
  }

  getEstimateText(): string {
    if (this.completedScheduleCount === 0) return '暂无样本';
    if (this.estimateDeltaMinutes === 0) return '估时接近准确';
    if (this.estimateDeltaMinutes > 0) return `平均超时 ${this.estimateDeltaMinutes} 分钟`;
    return `平均提前 ${Math.abs(this.estimateDeltaMinutes)} 分钟`;
  }

  getMoodColor(): string {
    if (this.averageMood <= 40) return '#D96B5F';
    if (this.averageMood <= 70) return '#D59A45';
    return '#46AFA5';
  }

  getChangeLabel(change: ScheduleChange): string {
    if (change.type === 'delay') return '顺延';
    if (change.type === 'carryover') return '结转';
    if (change.type === 'advance') return '提前';
    if (change.type === 'complete') return '完成';
    if (change.type === 'delete') return '删除';
    return '调整';
  }

  getChangeColor(change: ScheduleChange): string {
    if (change.type === 'delay') return '#8A7CC3';
    if (change.type === 'carryover') return '#8A7CC3';
    if (change.type === 'advance') return '#46AFA5';
    if (change.type === 'complete') return '#7BAE7F';
    if (change.type === 'delete') return '#D96B5F';
    return '#607385';
  }

  getNextActionHint(): string {
    const label = this.getRangeLabel();
    if (this.plannedBlockCount === 0) return `${label}还没有可复盘的时间线，先回到规划，把下一段安排出来。`;
    if (this.completedScheduleCount === 0) return `${label}已经有计划但还没有完成记录，回到今天页开始下一段最直接。`;
    if (this.getPlanningChangeCount() > 2) return `${label}调整较多，下一次规划先少排一点，让时间线更稳。`;
    return '复盘已经足够，下一步回到今天继续执行，或打开规划微调剩余安排。';
  }

  hasReviewData(): boolean {
    return this.plannedBlockCount > 0 || this.completedScheduleCount > 0 || this.totalFocusMinutes > 0 || this.changes.length > 0 || this.archiveEntries.length > 0;
  }

  getChangeTimeText(timestamp: number): string {
    if (this.selectedRange === 'week') {
      return TimeFormatter.formatDateTime(timestamp);
    }
    return TimeFormatter.formatTime(timestamp);
  }

  getMaxWeekMinutes(): number {
    let maxMinutes = 60;
    for (let stat of this.weekStats) {
      if (stat.plannedMinutes > maxMinutes) maxMinutes = stat.plannedMinutes;
      if (stat.focusMinutes > maxMinutes) maxMinutes = stat.focusMinutes;
    }
    return maxMinutes;
  }

  getWeekBarWidth(minutes: number): string {
    if (minutes <= 0) return '4%';
    return `${Math.max(6, Math.round(minutes * 100 / this.getMaxWeekMinutes()))}%`;
  }

  getWeekRhythmHint(): string {
    let activeDays = 0;
    let overloadedDays = 0;
    let totalFocus = 0;
    for (let stat of this.weekStats) {
      if (stat.plannedBlocks > 0 || stat.focusMinutes > 0) activeDays++;
      if (stat.plannedMinutes > this.dailyCapacityMinutes) overloadedDays++;
      totalFocus += stat.focusMinutes;
    }

    if (activeDays === 0) return '本周还没有形成稳定时间线，先把今天安排清楚就够了。';
    if (overloadedDays > 0) return `本周有 ${overloadedDays} 天计划偏满，下次先给这些天留出缓冲。`;
    if (activeDays <= 2) return '本周任务集中在少数几天，适合把可拆分任务往空白日分摊。';
    if (totalFocus > 0) return '本周已经有可复用的节奏，下一步是保留稳定日期，减少临时改动。';
    return '本周有规划但执行样本还少，先完成一个时间块再复盘会更准。';
  }

  navigateTo(url: string) {
    NavigationManager.push(this.getUIContext(), url);
  }

  @Builder
  Header() {
    Column() {
      Text('复盘')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182126')

      Text(`${this.getRangeLabel()}复盘要解释节奏，而不是只摆几组数字。`)
        .fontSize(12)
        .fontColor('#62727A')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 8 })
  }

  @Builder
  RangeSwitch() {
    Row() {
      this.RangeChip('today', '今天')
      this.RangeChip('week', '本周')
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 8 })
  }

  @Builder
  RangeChip(range: ReviewRange, label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.selectedRange === range ? '#FFFFFF' : '#607385')
      .textAlign(TextAlign.Center)
      .height(36)
      .layoutWeight(1)
      .backgroundColor(this.selectedRange === range ? '#256D85' : '#EEF4F5')
      .borderRadius(10)
      .margin({ right: range === 'today' ? 8 : 0 })
      .onClick(() => {
        if (this.selectedRange !== range) {
          this.selectedRange = range;
          this.loadData();
        }
      })
  }

  @Builder
  ActionPanel() {
    Column() {
      Text('下一步')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182126')

      Text(this.getNextActionHint())
        .fontSize(12)
        .fontColor('#62727A')
        .lineHeight(18)
        .margin({ top: 8, bottom: 14 })

      Row() {
        Button('回到今天')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .height(42)
          .backgroundColor('#256D85')
          .borderRadius(10)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('pages/TodayPage');
          })

        Button('调整规划')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#256D85')
          .height(42)
          .backgroundColor('#EAF2F5')
          .borderRadius(10)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.navigateTo('pages/PlanPage');
          })
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
    .margin({ top: 12 })
  }

  @Builder
  NarrativePanel() {
    Column() {
      Text(this.reviewReport.headline)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182126')

      Text(this.getNarrative())
        .fontSize(13)
        .fontColor('#62727A')
        .lineHeight(20)
        .margin({ top: 10 })

      Text(this.reviewReport.recommendation)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#256D85')
        .lineHeight(18)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#EAF2F5')
        .borderRadius(10)
        .margin({ top: 12 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
  }

  @Builder
  StatsPanel() {
    Column() {
      Row() {
        Column() {
          Text(TimeFormatter.formatHours(this.totalFocusMinutes))
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182126')
          Text('专注小时')
            .fontSize(12)
            .fontColor('#62727A')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Stack({ alignContent: Alignment.Center }) {
          Progress({ value: this.getCompletionRate(), total: 100, type: ProgressType.Ring })
            .width(82)
            .height(82)
            .color('#46AFA5')

          Text(`${this.getCompletionRate()}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182126')
        }
        .width(90)
        .height(90)
      }
      .width('100%')

      Row() {
        this.ReviewMetric(`${this.completedScheduleCount}`, '完成块', '#182126')
        this.ReviewMetric(`${this.plannedBlockCount}`, '相关块', '#182126')
        this.ReviewMetric(`${this.averageMood}`, '心情', this.getMoodColor())
      }
      .width('100%')
      .margin({ top: 18 })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
    .margin({ top: 12 })
  }

  @Builder
  EmptyReviewGuide() {
    Column() {
      Text('先建立一条可复盘的时间线')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182126')

      Text('复盘需要至少一个被安排或执行过的时间块。先完成下面任一步，回来这里就会有真实解释。')
        .fontSize(12)
        .fontColor('#62727A')
        .lineHeight(18)
        .margin({ top: 8, bottom: 12 })

      this.EmptyGuideRow('1', '收集任务', '把脑子里的事先放进收集箱。', '#8A7CC3')
      this.EmptyGuideRow('2', '安排时间', '把任务放到今天或本周的具体时间。', '#256D85')
      this.EmptyGuideRow('3', '开始专注', '完成一次专注后，复盘会解释节奏。', '#46AFA5')

      Row() {
        Button('去收集')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .height(42)
          .backgroundColor('#256D85')
          .borderRadius(10)
          .layoutWeight(1)
          .onClick(() => {
            this.navigateTo('pages/InboxPage');
          })

        Button('去规划')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#256D85')
          .height(42)
          .backgroundColor('#EAF2F5')
          .borderRadius(10)
          .layoutWeight(1)
          .margin({ left: 10 })
          .onClick(() => {
            this.navigateTo('pages/PlanPage');
          })
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
    .margin({ top: 12 })
  }

  @Builder
  EmptyGuideRow(index: string, title: string, detail: string, color: string) {
    Row() {
      Text(index)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(24)
        .height(24)
        .borderRadius(12)
        .backgroundColor(color)
        .margin({ right: 12 })

      Column() {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182126')
        Text(detail)
          .fontSize(11)
          .fontColor('#62727A')
          .lineHeight(16)
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  ReviewMetric(value: string, label: string, color: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(10)
        .fontColor('#62727A')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  PlanningPanel() {
    Column() {
      Row() {
        Text('计划质量')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182126')
          .layoutWeight(1)

        Text(this.reviewReport.conflictText)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.reviewReport.conflictCount > 0 ? '#D96B5F' : '#62727A')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#F7F8F6')
          .borderRadius(8)
      }
      .width('100%')

      Row() {
        this.ReviewMetric(`${this.reviewReport.plannedMinutes}`, '规划分钟', '#182126')
        this.ReviewMetric(`${this.reviewReport.completedMinutes}`, '专注分钟', '#46AFA5')
        this.ReviewMetric(this.reviewReport.carryOverText, '结转', '#8A7CC3')
        this.ReviewMetric(this.reviewReport.routineText, '模板', '#7BAE7F')
      }
      .width('100%')
      .margin({ top: 16 })

      Text(this.reviewReport.estimateText)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#182126')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#F0F4F3')
        .borderRadius(10)
        .margin({ top: 14 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
    .margin({ top: 12 })
  }

  @Builder
  WeeklyRhythmPanel() {
    Column() {
      Row() {
        Text('本周节奏')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182126')
          .layoutWeight(1)

        Text('计划 / 专注')
          .fontSize(11)
          .fontColor('#8A969B')
      }
      .width('100%')

      Text(this.getWeekRhythmHint())
        .fontSize(12)
        .fontColor('#62727A')
        .lineHeight(18)
        .margin({ top: 8, bottom: 10 })

      ForEach(this.weekStats, (stat: ReviewDayStat) => {
        this.WeekDayRow(stat)
      }, (stat: ReviewDayStat) => `${stat.dayStart}`)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
    .margin({ top: 12 })
  }

  @Builder
  WeekDayRow(stat: ReviewDayStat) {
    Row() {
      Column() {
        Text(`周${stat.label}`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182126')
        Text(stat.dateText)
          .fontSize(9)
          .fontColor('#8A969B')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .width(42)

      Column() {
        Stack({ alignContent: Alignment.Start }) {
          Text()
            .height(8)
            .width('100%')
            .borderRadius(4)
            .backgroundColor('#EDF2F2')
          Text()
            .height(8)
            .width(this.getWeekBarWidth(stat.plannedMinutes))
            .borderRadius(4)
            .backgroundColor('#AEC4CC')
        }
        .width('100%')
        .height(8)

        Stack({ alignContent: Alignment.Start }) {
          Text()
            .height(8)
            .width('100%')
            .borderRadius(4)
            .backgroundColor('#EDF2F2')
          Text()
            .height(8)
            .width(this.getWeekBarWidth(stat.focusMinutes))
            .borderRadius(4)
            .backgroundColor('#46AFA5')
        }
        .width('100%')
        .height(8)
        .margin({ top: 6 })
      }
      .layoutWeight(1)
      .margin({ left: 10, right: 10 })

      Column() {
        Text(`${stat.completedBlocks}/${stat.plannedBlocks}`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182126')
        Text(stat.changeCount > 0 ? `${stat.changeCount} 改` : '稳定')
          .fontSize(9)
          .fontColor(stat.changeCount > 0 ? '#D59A45' : '#46AFA5')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.End)
      .width(44)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: { bottom: 1 }, color: '#EEF2F1' })
  }

  @Builder
  InsightPanel() {
    Column() {
      Text('关键洞察')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182126')

      ForEach(this.reviewReport.insights.slice(0, 4), (insight: ReviewInsight) => {
        this.InsightRow(insight)
      }, (insight: ReviewInsight) => insight.title)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
    .margin({ top: 12 })
  }

  @Builder
  InsightRow(insight: ReviewInsight) {
    Row() {
      Text()
        .width(4)
        .height(46)
        .borderRadius(2)
        .backgroundColor(insight.color)
        .margin({ right: 12 })

      Column() {
        Text(insight.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182126')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(insight.detail)
          .fontSize(12)
          .fontColor('#62727A')
          .lineHeight(18)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 12, bottom: 10 })
    .border({ width: { bottom: 1 }, color: '#EEF2F1' })
  }

  @Builder
  ChangeFeed() {
    Column() {
      Text('变更记录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182126')

      if (this.changes.length === 0 && this.archiveEntries.length === 0) {
        Text(`${this.getRangeLabel()}还没有调整记录。完成、顺延、删除时间块后，这里会显示原因和时间。`)
          .fontSize(12)
          .fontColor('#62727A')
          .lineHeight(18)
          .margin({ top: 10 })
      } else {
        ForEach(this.changes.slice(0, 5), (change: ScheduleChange) => {
          this.ChangeRow(this.getChangeLabel(change), change.note, change.timestamp, this.getChangeColor(change))
        }, (change: ScheduleChange) => change.id)
        ForEach(this.archiveEntries.slice(0, 3), (entry: ScheduleArchiveEntry) => {
          this.ChangeRow('删除', entry.title, entry.archivedAt, '#D96B5F')
        }, (entry: ScheduleArchiveEntry) => entry.id)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#1821260D', offsetX: 0, offsetY: 8 })
    .margin({ top: 12, bottom: 24 })
  }

  @Builder
  ChangeRow(title: string, detail: string, timestamp: number, color: string) {
    Row() {
      Text()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor(color)
        .margin({ right: 10 })

      Column() {
        Row() {
          Text(title)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182126')
            .layoutWeight(1)
          Text(this.getChangeTimeText(timestamp))
            .fontSize(10)
            .fontColor('#8A969B')
        }
        .width('100%')

        Text(detail.length > 0 ? detail : '没有备注')
          .fontSize(11)
          .fontColor('#62727A')
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: 14 })
  }

  build() {
    Column() {
      this.Header()
      this.RangeSwitch()
      Scroll() {
        Column() {
          this.NarrativePanel()
          this.ActionPanel()
          if (this.hasReviewData()) {
            this.StatsPanel()
            if (this.selectedRange === 'week') {
              this.WeeklyRhythmPanel()
            }
            this.PlanningPanel()
            this.InsightPanel()
            this.ChangeFeed()
          } else {
            this.EmptyReviewGuide()
          }
        }
        .padding({ left: 16, right: 16, top: 8 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8F6')
  }
}

@Entry
@Component
struct ReviewPageEntry {
  build() {
    Column() {
      ReviewPage()
    }
    .width('100%')
    .height('100%')
  }
}
