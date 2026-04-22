/**
 * 设置页
 */

import { router } from '@kit.ArkUI';
import { GlassCard } from '../components/common/GlassCard';
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
  SettingItem(iconResource: Resource, title: string, action: () => void) {
    Row() {
      SymbolGlyph(iconResource)
        .fontSize(24)
        .fontColor([$r('app.color.primary_color')])
        .margin({ right: 12 })

      Text(title)
        .fontSize($r('app.float.body_font_size'))
        .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('app.color.text_secondary')])
    }
    .width('100%')
    .padding($r('app.float.padding_md'))
    .onClick(action)
  }

  @Builder
  ToggleItem(iconResource: Resource, title: string, value: boolean, onChange: (val: boolean) => void) {
    Row() {
      SymbolGlyph(iconResource)
        .fontSize(24)
        .fontColor([$r('app.color.primary_color')])
        .margin({ right: 12 })

      Text(title)
        .fontSize($r('app.float.body_font_size'))
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .onChange(onChange)
    }
    .width('100%')
    .padding($r('app.float.padding_md'))
  }

  @Builder
  ThemeSelector() {
    if (this.showThemeSelector) {
      Column() {
        Text('选择主题')
          .fontSize($r('app.float.subtitle_font_size'))
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 24 })

        Scroll() {
          Column() {
            ForEach(this.themes, (theme: ThemeConfig) => {
              Row() {
                Column() {
                  Row() {
                    Text()
                      .width(40)
                      .height(40)
                      .backgroundColor(theme.primaryColor)
                      .borderRadius(8)
                      .margin({ right: 12 })

                    Column() {
                      Text(theme.name)
                        .fontSize($r('app.float.body_font_size'))
                        .fontWeight(FontWeight.Medium)

                      Text(theme.isDark ? '深色' : '浅色')
                        .fontSize($r('app.float.caption_font_size'))
                        .fontColor($r('app.color.text_secondary'))
                        .margin({ top: 4 })
                    }
                    .alignItems(HorizontalAlign.Start)
                  }

                  Blank()

                  if (this.settings.currentTheme === theme.id) {
                    SymbolGlyph($r('sys.symbol.checkmark'))
                      .fontSize(24)
                      .fontColor([$r('app.color.success_color')])
                  }
                }
                .width('100%')
                .padding($r('app.float.padding_md'))
                .backgroundColor(this.settings.currentTheme === theme.id ? '#F0F0F0' : $r('app.color.card_color'))
                .borderRadius($r('app.float.button_radius'))
                .margin({ bottom: 12 })
                .onClick(() => {
                  this.handleThemeChange(theme.id);
                })
              }
            });
          }
        }
        .layoutWeight(1)

        Button('关闭')
          .width('100%')
          .margin({ top: 16 })
          .onClick(() => {
            this.showThemeSelector = false;
          })
      }
      .padding($r('app.float.padding_xl'))
      .backgroundColor($r('app.color.card_color'))
      .borderRadius($r('app.float.card_radius'))
      .width('90%')
      .height('70%')
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航栏
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(28)
            .fontColor([$r('app.color.text_color')])
            .onClick(() => {
              router.back();
            })

          Text('设置')
            .fontSize($r('app.float.title_font_size'))
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding($r('app.float.padding_md'))

        Scroll() {
          Column() {
            // 专注偏好
            GlassCard({ content: (): void => this.FocusPreferences() })
              .margin({ top: 12, left: 16, right: 16 })

            // 通知设置
            GlassCard({ content: (): void => this.NotificationSettings() })
              .margin({ top: 16, left: 16, right: 16 })

            // 主题设置
            GlassCard({ content: (): void => this.ThemeSettings() })
              .margin({ top: 16, left: 16, right: 16 })

            // 关于
            GlassCard({ content: (): void => this.AboutSection() })
              .margin({ top: 16, left: 16, right: 16, bottom: 16 })
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_color'))

      // 主题选择器对话框
      if (this.showThemeSelector) {
        Column() {
          this.ThemeSelector()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000040')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.showThemeSelector = false;
        })
      }
    }
  }

  @Builder
  FocusPreferences() {
    Column() {
      Text('专注偏好')
        .fontSize($r('app.float.subtitle_font_size'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      Row() {
        Text('默认专注时长')
          .fontSize($r('app.float.body_font_size'))
          .layoutWeight(1)

        TextInput({ text: this.settings.defaultFocusTime.toString() })
          .type(InputType.Number)
          .width(80)
          .onChange((value: string) => {
            this.settings.defaultFocusTime = parseInt(value) || 25;
            this.saveSettings();
          })

        Text('分钟')
          .fontSize($r('app.float.body_font_size'))
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row() {
        Text('默认休息时长')
          .fontSize($r('app.float.body_font_size'))
          .layoutWeight(1)

        TextInput({ text: this.settings.defaultRestTime.toString() })
          .type(InputType.Number)
          .width(80)
          .onChange((value: string) => {
            this.settings.defaultRestTime = parseInt(value) || 5;
            this.saveSettings();
          })

        Text('分钟')
          .fontSize($r('app.float.body_font_size'))
          .margin({ left: 8 })
      }
      .width('100%')

      this.ToggleItem($r('sys.symbol.arrow_clockwise'), '自动开始休息', this.settings.autoStartRest, (value: boolean) => {
        this.settings.autoStartRest = value;
        this.saveSettings();
      })
    }
  }

  @Builder
  NotificationSettings() {
    Column() {
      Text('通知设置')
        .fontSize($r('app.float.subtitle_font_size'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      this.ToggleItem($r('sys.symbol.bell'), '通知提醒', this.settings.notificationEnabled, (value: boolean) => {
        this.settings.notificationEnabled = value;
        this.saveSettings();
      })

      this.ToggleItem($r('sys.symbol.speaker_wave_2'), '声音提示', this.settings.soundEnabled, (value: boolean) => {
        this.settings.soundEnabled = value;
        this.saveSettings();
      })

      this.ToggleItem($r('sys.symbol.iphone_radiowaves_left_and_right'), '振动反馈', this.settings.vibrationEnabled, (value: boolean) => {
        this.settings.vibrationEnabled = value;
        this.saveSettings();
      })
    }
  }

  @Builder
  ThemeSettings() {
    Column() {
      Text('主题设置')
        .fontSize($r('app.float.subtitle_font_size'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      this.SettingItem($r('sys.symbol.paintpalette'), '切换主题', () => {
        this.showThemeSelector = true;
      })

      this.SettingItem($r('sys.symbol.photo'), '自定义背景', () => {
        // TODO: 实现背景图片选择
      })
    }
  }

  @Builder
  AboutSection() {
    Column() {
      Text('关于')
        .fontSize($r('app.float.subtitle_font_size'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      Text('Flow State')
        .fontSize($r('app.float.body_font_size'))
        .fontWeight(FontWeight.Medium)

      Text('版本 1.0.0')
        .fontSize($r('app.float.caption_font_size'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 4 })

      Text('沉浸式任务管理应用')
        .fontSize($r('app.float.caption_font_size'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })
    }
  }
}
