/**
 * 设置页
 */

import { DataManager } from '../utils/DataManager';
import { CURRENT_DATA_SCHEMA_VERSION } from '../utils/DataMigration';
import { NavigationManager } from '../utils/NavigationManager';
import { ThemeManager } from '../utils/ThemeManager';
import { ThemeContext } from '../utils/ThemeContext';
import { UserSettings, ThemeConfig } from '../models/DataModels';

@Entry
@Component
struct SettingsPage {
  @State settings: UserSettings = {
    defaultFocusTime: 25,
    defaultRestTime: 5,
    dailyCapacityMinutes: 300,
    autoStartRest: false,
    notificationEnabled: true,
    soundEnabled: true,
    vibrationEnabled: false,
    currentTheme: 'light'
  };
  @State themes: ThemeConfig[] = [];
  @State showThemeSelector: boolean = false;
  @State taskCount: number = 0;
  @State scheduleCount: number = 0;
  @State focusSessionCount: number = 0;
  @State archiveCount: number = 0;
  @StorageLink(ThemeContext.getThemeLink()) currentTheme: ThemeConfig = ThemeContext.getCurrentTheme();

  async aboutToAppear() {
    this.settings = await DataManager.getUserSettings();
    this.themes = await ThemeManager.getAllThemes();
    await this.loadDataStatus();
  }

  async saveSettings() {
    await DataManager.saveUserSettings(this.settings);
  }

  async handleThemeChange(themeId: string) {
    await ThemeManager.setTheme(themeId);
    const newTheme = await ThemeManager.getCurrentTheme();
    ThemeContext.updateTheme(newTheme);
    this.settings.currentTheme = themeId;
    await this.saveSettings();
    this.showThemeSelector = false;
  }

  async loadDataStatus() {
    const tasks = await DataManager.getAllTasks();
    const schedules = await DataManager.getAllSchedules();
    const sessions = await DataManager.getAllFocusSessions();
    const archives = await DataManager.getAllScheduleArchiveEntries();
    this.taskCount = tasks.length;
    this.scheduleCount = schedules.length;
    this.focusSessionCount = sessions.length;
    this.archiveCount = archives.length;
  }

  getMutedTextColor(): string {
    return this.currentTheme.isDark ? '#A7B6BE' : '#6C7A84';
  }

  getSubtleSurfaceColor(): string {
    return this.currentTheme.isDark ? '#22313A' : '#F4F7F8';
  }

  getOverlayColor(): string {
    return this.currentTheme.isDark ? '#99050B0F' : '#6617212A';
  }

  getCurrentThemeName(): string {
    for (let theme of this.themes) {
      if (theme.id === this.settings.currentTheme) {
        return theme.name;
      }
    }
    return this.settings.currentTheme;
  }

  @Builder
  Header() {
    Row() {
      Button() {
        Text('<')
          .fontSize(22)
          .fontColor(this.currentTheme.textColor)
      }
      .width(42)
      .height(42)
      .borderRadius(8)
      .backgroundColor(this.currentTheme.cardColor)
      .margin({ right: 12 })
      .onClick(() => {
        NavigationManager.back(this.getUIContext());
      })

      Column() {
        Text('设置')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTheme.textColor)

        Text('只保留影响体验的选项')
          .fontSize(12)
          .fontColor(this.getMutedTextColor())
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 8 })
  }

  @Builder
  FocusSettings() {
    Column() {
      this.SectionTitle('专注节奏')
      this.NumberRow('默认专注', this.settings.defaultFocusTime, '分钟', (value: number) => {
        this.settings.defaultFocusTime = value;
        this.saveSettings();
      })
      this.NumberRow('默认休息', this.settings.defaultRestTime, '分钟', (value: number) => {
        this.settings.defaultRestTime = value;
        this.saveSettings();
      })
      this.NumberRow('每日容量', this.settings.dailyCapacityMinutes || 300, '分钟', (value: number) => {
        this.settings.dailyCapacityMinutes = this.clampDailyCapacity(value);
        this.saveSettings();
      })
      this.ToggleRow($r('sys.symbol.arrow_clockwise'), '自动开始休息', this.settings.autoStartRest, (value: boolean) => {
        this.settings.autoStartRest = value;
        this.saveSettings();
      })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.currentTheme.cardColor)
    .borderRadius(8)
    .shadow({ radius: 18, color: '#0F23313A', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  FlowLineCard() {
    Column() {
      this.SectionTitle('主线')
      Row() {
        this.FlowNode('收集', '写下', '#8A7CC3')
        this.FlowConnector()
        this.FlowNode('安排', '定时', '#256D85')
        this.FlowConnector()
        this.FlowNode('专注', '执行', '#46AFA5')
        this.FlowConnector()
        this.FlowNode('复盘', '改进', '#7BAE7F')
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.currentTheme.cardColor)
    .borderRadius(8)
    .shadow({ radius: 18, color: '#0F23313A', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  NotificationSettings() {
    Column() {
      this.SectionTitle('提醒偏好')
      this.SectionNote('先保存偏好。真机验证后，会接入系统通知。')
      this.ToggleRow($r('sys.symbol.bell'), '通知偏好', this.settings.notificationEnabled, (value: boolean) => {
        this.settings.notificationEnabled = value;
        this.saveSettings();
      })
      this.ToggleRow($r('sys.symbol.speaker_wave_2'), '声音偏好', this.settings.soundEnabled, (value: boolean) => {
        this.settings.soundEnabled = value;
        this.saveSettings();
      })
      this.ToggleRow($r('sys.symbol.dot_radiowaves_left_and_right'), '振动偏好', this.settings.vibrationEnabled, (value: boolean) => {
        this.settings.vibrationEnabled = value;
        this.saveSettings();
      })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.currentTheme.cardColor)
    .borderRadius(8)
    .shadow({ radius: 18, color: '#0F23313A', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  CapabilityStatus() {
    Column() {
      this.SectionTitle('应用能力')
      this.CapabilityRow('核心流程', '收集、安排、专注、复盘已经连通', '#46AFA5')
      this.CapabilityRow('本地数据', '任务、日程、设置会保存在本机', '#46AFA5')
      this.CapabilityRow('系统提醒', '偏好已保存，真实通知待真机验证', '#8EA1AE')
      this.CapabilityRow('发布签名', '发布前需要配置正式签名', '#8A7CC3')
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.currentTheme.cardColor)
    .borderRadius(8)
    .shadow({ radius: 18, color: '#0F23313A', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  ReleaseReadiness() {
    Column() {
      this.SectionTitle('体验状态')
      this.SectionNote('当前版本适合走完整主流程体验；正式发布前还需要真机点按、签名和系统提醒能力验证。')
      this.CapabilityRow('静态构建', 'assembleApp 当前可通过', '#46AFA5')
      this.CapabilityRow('真机点按', '等待 hdc 识别到设备或模拟器', '#8EA1AE')
      this.CapabilityRow('系统提醒', '偏好可保存，通知投递尚未接入', '#8EA1AE')
      this.CapabilityRow('发布签名', '正式分发前仍需配置签名', '#8A7CC3')
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.currentTheme.cardColor)
    .borderRadius(8)
    .shadow({ radius: 18, color: '#0F23313A', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  DataStatus() {
    Column() {
      this.SectionTitle('本地数据')
      this.SectionNote(`当前数据结构 v${CURRENT_DATA_SCHEMA_VERSION}。任务、日程、专注和归档记录保存在本机；导入导出需要后续存储权限审查后再开放。`)
      Row() {
        this.DataMetric(`${this.taskCount}`, '任务')
        this.DataMetric(`${this.scheduleCount}`, '日程')
        this.DataMetric(`${this.focusSessionCount}`, '专注')
        this.DataMetric(`${this.archiveCount}`, '归档')
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.currentTheme.cardColor)
    .borderRadius(8)
    .shadow({ radius: 18, color: '#0F23313A', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  FlowNode(title: string, label: string, color: string) {
    Column() {
      Text()
        .width(28)
        .height(4)
        .borderRadius(2)
        .backgroundColor(color)
        .margin({ bottom: 8 })

      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTheme.textColor)
      Text(label)
        .fontSize(10)
        .fontColor(this.getMutedTextColor())
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  @Builder
  FlowConnector() {
    Text('›')
      .fontSize(18)
      .fontColor('#B3BEC4')
      .width(16)
      .textAlign(TextAlign.Center)
  }

  @Builder
  DataMetric(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTheme.textColor)
      Text(label)
        .fontSize(10)
        .fontColor(this.getMutedTextColor())
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  AppearanceSettings() {
    Column() {
      this.SectionTitle('外观')
      Row() {
        SymbolGlyph($r('sys.symbol.paintpalette'))
          .fontSize(20)
          .fontColor([this.currentTheme.primaryColor])
          .margin({ right: 12 })

        Column() {
          Text('主题')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.currentTheme.textColor)
          Text('当前：' + this.getCurrentThemeName())
            .fontSize(11)
            .fontColor(this.getMutedTextColor())
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('更换')
          .fontSize(13)
          .fontColor(this.currentTheme.primaryColor)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .onClick(() => {
        this.showThemeSelector = true;
      })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.currentTheme.cardColor)
    .borderRadius(8)
    .shadow({ radius: 18, color: '#0F23313A', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  AboutCard() {
    Column() {
      this.SectionTitle('关于')
      Text('流序')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTheme.textColor)
      Text('体验版 0.9.7 · 时间线计划工具')
        .fontSize(12)
        .fontColor(this.getMutedTextColor())
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.currentTheme.cardColor)
    .borderRadius(8)
    .shadow({ radius: 18, color: '#0F23313A', offsetX: 0, offsetY: 10 })
    .margin({ top: 14, bottom: 24 })
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.currentTheme.textColor)
      .width('100%')
      .margin({ bottom: 10 })
  }

  @Builder
  SectionNote(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor(this.getMutedTextColor())
      .lineHeight(18)
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(this.getSubtleSurfaceColor())
      .borderRadius(8)
      .margin({ bottom: 8 })
  }

  @Builder
  CapabilityRow(title: string, detail: string, color: string) {
    Row() {
      Text()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(color)
        .margin({ right: 12 })

      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentTheme.textColor)
        Text(detail)
          .fontSize(11)
          .fontColor(this.getMutedTextColor())
          .lineHeight(16)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  NumberRow(title: string, value: number, unit: string, onChange: (value: number) => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor(this.currentTheme.textColor)
        .layoutWeight(1)

      TextInput({ text: value.toString() })
        .type(InputType.Number)
        .width(74)
        .height(40)
        .fontColor(this.currentTheme.textColor)
        .placeholderColor(this.getMutedTextColor())
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getSubtleSurfaceColor())
        .borderRadius(8)
        .onChange((input: string) => {
          onChange(parseInt(input) || value);
        })

      Text(unit)
        .fontSize(12)
        .fontColor(this.getMutedTextColor())
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  clampDailyCapacity(value: number): number {
    if (value < 60) return 60;
    if (value > 720) return 720;
    return value;
  }

  @Builder
  ToggleRow(iconResource: Resource, title: string, value: boolean, onChange: (value: boolean) => void) {
    Row() {
      SymbolGlyph(iconResource)
        .fontSize(20)
        .fontColor([this.currentTheme.primaryColor])
        .margin({ right: 12 })

      Text(title)
        .fontSize(15)
        .fontColor(this.currentTheme.textColor)
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(this.currentTheme.primaryColor)
        .onChange((isOn: boolean) => {
          onChange(isOn);
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  ThemeSelector() {
    if (this.showThemeSelector) {
      Column() {
        Text('选择主题')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentTheme.textColor)
          .margin({ bottom: 16 })

        ForEach(this.themes, (theme: ThemeConfig) => {
          Row() {
            Text()
              .width(20)
              .height(20)
              .borderRadius(4)
              .backgroundColor(theme.primaryColor)
              .margin({ right: 12 })

            Column() {
              Text(theme.name)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.currentTheme.textColor)
              Text(theme.isDark ? '深色' : '浅色')
                .fontSize(11)
                .fontColor(this.getMutedTextColor())
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            if (this.settings.currentTheme === theme.id) {
              Text('当前')
                .fontSize(12)
                .fontColor(this.currentTheme.primaryColor)
                .fontWeight(FontWeight.Bold)
            }
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .backgroundColor(this.settings.currentTheme === theme.id ? (this.currentTheme.isDark ? '#213641' : '#EAF2F5') : this.getSubtleSurfaceColor())
          .borderRadius(8)
          .margin({ bottom: 10 })
          .onClick(() => {
            this.handleThemeChange(theme.id);
          })
        }, (theme: ThemeConfig) => theme.id)

        Button('关闭')
          .width('100%')
          .height(44)
          .fontColor(this.getMutedTextColor())
          .backgroundColor(this.getSubtleSurfaceColor())
          .borderRadius(8)
          .onClick(() => {
            this.showThemeSelector = false;
          })
      }
      .width('90%')
      .padding({ left: 20, right: 20, top: 22, bottom: 20 })
      .backgroundColor(this.currentTheme.cardColor)
      .borderRadius(8)
    }
  }

  build() {
    Stack() {
      Column() {
        this.Header()

        Scroll() {
          Column() {
            this.FlowLineCard()
            this.FocusSettings()
            this.NotificationSettings()
            this.AppearanceSettings()
            this.CapabilityStatus()
            this.ReleaseReadiness()
            this.DataStatus()
            this.AboutCard()
          }
          .padding({ left: 16, right: 16, top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.currentTheme.backgroundColor)

      if (this.showThemeSelector) {
        Column() {
          this.ThemeSelector()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.getOverlayColor())
      }
    }
  }
}
