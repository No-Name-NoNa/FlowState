/**
 * 设置页
 */

import { router } from '@kit.ArkUI';
import { DataManager } from '../utils/DataManager';
import { ThemeManager } from '../utils/ThemeManager';
import { ThemeContext } from '../utils/ThemeContext';
import { UserSettings, ThemeConfig } from '../models/DataModels';

@Entry
@Component
struct SettingsPage {
  @State settings: UserSettings = {
    defaultFocusTime: 25,
    defaultRestTime: 5,
    autoStartRest: false,
    notificationEnabled: true,
    soundEnabled: true,
    vibrationEnabled: false,
    currentTheme: 'light'
  };
  @State themes: ThemeConfig[] = [];
  @State showThemeSelector: boolean = false;
  @StorageLink(ThemeContext.getThemeLink()) currentTheme: ThemeConfig = ThemeContext.getCurrentTheme();

  async aboutToAppear() {
    this.settings = await DataManager.getUserSettings();
    this.themes = await ThemeManager.getAllThemes();
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

  @Builder
  Header() {
    Row() {
      Button() {
        Text('<')
          .fontSize(22)
          .fontColor('#151C22')
      }
      .width(42)
      .height(42)
      .borderRadius(8)
      .backgroundColor('#FFFFFF')
      .margin({ right: 12 })
      .onClick(() => {
        router.back();
      })

      Column() {
        Text('设置')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#151C22')

        Text('只保留影响体验的选项')
          .fontSize(12)
          .fontColor('#6C7A84')
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
      this.ToggleRow($r('sys.symbol.arrow_clockwise'), '自动开始休息', this.settings.autoStartRest, (value: boolean) => {
        this.settings.autoStartRest = value;
        this.saveSettings();
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
  NotificationSettings() {
    Column() {
      this.SectionTitle('提醒反馈')
      this.ToggleRow($r('sys.symbol.bell'), '通知提醒', this.settings.notificationEnabled, (value: boolean) => {
        this.settings.notificationEnabled = value;
        this.saveSettings();
      })
      this.ToggleRow($r('sys.symbol.speaker_wave_2'), '声音提示', this.settings.soundEnabled, (value: boolean) => {
        this.settings.soundEnabled = value;
        this.saveSettings();
      })
      this.ToggleRow($r('sys.symbol.dot_radiowaves_left_and_right'), '振动反馈', this.settings.vibrationEnabled, (value: boolean) => {
        this.settings.vibrationEnabled = value;
        this.saveSettings();
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
  AppearanceSettings() {
    Column() {
      this.SectionTitle('外观')
      Row() {
        SymbolGlyph($r('sys.symbol.paintpalette'))
          .fontSize(20)
          .fontColor(['#2F6F86'])
          .margin({ right: 12 })

        Column() {
          Text('主题')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#151C22')
          Text('当前：' + this.settings.currentTheme)
            .fontSize(11)
            .fontColor('#6C7A84')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('更换')
          .fontSize(13)
          .fontColor('#2F6F86')
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
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 18, color: '#23313A0F', offsetX: 0, offsetY: 10 })
    .margin({ top: 14 })
  }

  @Builder
  AboutCard() {
    Column() {
      this.SectionTitle('关于')
      Text('Flow State')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#151C22')
      Text('版本 1.0.0 · 专注与计划工具')
        .fontSize(12)
        .fontColor('#6C7A84')
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 18, color: '#23313A0F', offsetX: 0, offsetY: 10 })
    .margin({ top: 14, bottom: 24 })
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#151C22')
      .width('100%')
      .margin({ bottom: 10 })
  }

  @Builder
  NumberRow(title: string, value: number, unit: string, onChange: (value: number) => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#151C22')
        .layoutWeight(1)

      TextInput({ text: value.toString() })
        .type(InputType.Number)
        .width(74)
        .height(40)
        .backgroundColor('#F4F7F8')
        .borderRadius(8)
        .onChange((input: string) => {
          onChange(parseInt(input) || value);
        })

      Text(unit)
        .fontSize(12)
        .fontColor('#6C7A84')
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  ToggleRow(iconResource: Resource, title: string, value: boolean, onChange: (value: boolean) => void) {
    Row() {
      SymbolGlyph(iconResource)
        .fontSize(20)
        .fontColor(['#2F6F86'])
        .margin({ right: 12 })

      Text(title)
        .fontSize(15)
        .fontColor('#151C22')
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#2F6F86')
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
          .fontColor('#151C22')
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
                .fontColor('#151C22')
              Text(theme.isDark ? '深色' : '浅色')
                .fontSize(11)
                .fontColor('#6C7A84')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            if (this.settings.currentTheme === theme.id) {
              Text('当前')
                .fontSize(12)
                .fontColor('#2F6F86')
                .fontWeight(FontWeight.Bold)
            }
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .backgroundColor(this.settings.currentTheme === theme.id ? '#EAF2F5' : '#F4F7F8')
          .borderRadius(8)
          .margin({ bottom: 10 })
          .onClick(() => {
            this.handleThemeChange(theme.id);
          })
        }, (theme: ThemeConfig) => theme.id)

        Button('关闭')
          .width('100%')
          .height(44)
          .fontColor('#52626D')
          .backgroundColor('#F0F3F5')
          .borderRadius(8)
          .onClick(() => {
            this.showThemeSelector = false;
          })
      }
      .width('90%')
      .padding({ left: 20, right: 20, top: 22, bottom: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
    }
  }

  build() {
    Stack() {
      Column() {
        this.Header()

        Scroll() {
          Column() {
            this.FocusSettings()
            this.NotificationSettings()
            this.AppearanceSettings()
            this.AboutCard()
          }
          .padding({ left: 16, right: 16, top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F4F7F8')

      if (this.showThemeSelector) {
        Column() {
          this.ThemeSelector()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#17212A66')
      }
    }
  }
}
