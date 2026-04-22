/**
 * 登录页
 */

import { router } from '@kit.ArkUI';
import { GlassCard } from '../components/common/GlassCard';
import { DataManager } from '../utils/DataManager';
import { UserInfo } from '../models/DataModels';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State isLoggedIn: boolean = false;
  @State userInfo: UserInfo = { isLoggedIn: false };

  async aboutToAppear() {
    this.userInfo = await DataManager.getUserInfo();
    this.isLoggedIn = this.userInfo.isLoggedIn;
    if (this.userInfo.username) {
      this.username = this.userInfo.username;
    }
  }

  async handleLogin() {
    if (!this.username.trim()) {
      return;
    }

    this.userInfo = {
      id: `user_${Date.now()}`,
      username: this.username,
      isLoggedIn: true,
      avatar: undefined,
      email: undefined
    };

    await DataManager.saveUserInfo(this.userInfo);
    this.isLoggedIn = true;
  }

  async handleLogout() {
    this.userInfo = {
      isLoggedIn: false
    };

    await DataManager.saveUserInfo(this.userInfo);
    this.isLoggedIn = false;
    this.username = '';
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(32)
          .fontColor($r('app.color.text_color'))
          .onClick(() => {
            router.back();
          })

        Text('账号')
          .fontSize($r('app.float.title_font_size'))
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding($r('app.float.padding_md'))

      Column() {
        if (!this.isLoggedIn) {
          // 未登录状态
          GlassCard({ content: (): void => this.LoginForm() })
            .margin({ top: 60, left: 32, right: 32 })
        } else {
          // 已登录状态
          GlassCard({ content: (): void => this.UserProfile() })
            .margin({ top: 60, left: 32, right: 32 })
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
  }

  @Builder
  LoginForm() {
    Column() {
      Text('👤')
        .fontSize(64)
        .margin({ bottom: 32 })

      Text('欢迎使用 Flow State')
        .fontSize($r('app.float.title_font_size'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      Text('登录后可同步数据到云端')
        .fontSize($r('app.float.body_font_size'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 32 })

      TextInput({ placeholder: '请输入用户名', text: this.username })
        .width('100%')
        .margin({ bottom: 24 })
        .onChange((value: string) => {
          this.username = value;
        })

      Button('登录')
        .width('100%')
        .backgroundColor($r('app.color.primary_color'))
        .onClick(() => {
          this.handleLogin();
        })

      Text('暂时跳过')
        .fontSize($r('app.float.body_font_size'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 24 })
        .onClick(() => {
          router.back();
        })
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  UserProfile() {
    Column() {
      Text('👤')
        .fontSize(64)
        .margin({ bottom: 24 })

      Text(this.userInfo.username || '用户')
        .fontSize($r('app.float.title_font_size'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      Text('已登录')
        .fontSize($r('app.float.body_font_size'))
        .fontColor($r('app.color.success_color'))
        .margin({ bottom: 32 })

      Row() {
        Column() {
          Text('本地数据')
            .fontSize($r('app.float.caption_font_size'))
            .fontColor($r('app.color.text_secondary'))

          Text('已同步')
            .fontSize($r('app.float.body_font_size'))
            .fontWeight(FontWeight.Medium)
            .margin({ top: 4 })
        }

        Blank()

        Column() {
          Text('云端备份')
            .fontSize($r('app.float.caption_font_size'))
            .fontColor($r('app.color.text_secondary'))

          Text('正常')
            .fontSize($r('app.float.body_font_size'))
            .fontWeight(FontWeight.Medium)
            .margin({ top: 4 })
        }
      }
      .width('100%')
      .padding($r('app.float.padding_md'))
      .backgroundColor('#F5F5F7')
      .borderRadius($r('app.float.button_radius'))
      .margin({ bottom: 24 })

      Button('退出登录')
        .width('100%')
        .backgroundColor($r('app.color.error_color'))
        .onClick(() => {
          this.handleLogout();
        })
    }
    .alignItems(HorizontalAlign.Center)
  }
}
