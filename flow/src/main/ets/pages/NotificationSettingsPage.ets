import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_FONT_TOKENS,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { NotificationSettingsViewModel } from '../viewmodel/NotificationSettingsViewModel';

@Entry
@Component
struct NotificationSettingsPage {
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  @State notifMessage: string = '';

  aboutToAppear(): void {
    this.notifMessage = NotificationSettingsViewModel.getDefaultMessage();
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_back'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextPrimary)
          .onClick(() => {
            router.back();
          })

        Text(I18nHelper.t(I18nKeys.NOTIF_PAGE_TITLE, this.currentLanguage))
          .fontSize(this.fontTokens.headerTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row()
          .width($r('app.float.icon_size_md'))
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
      .alignItems(VerticalAlign.Center)

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      Scroll() {
        Column() {
          Column() {
            Text(I18nHelper.t(I18nKeys.NOTIF_DEFAULT_MESSAGE_LABEL, this.currentLanguage))
              .fontSize(this.fontTokens.caption)
              .fontColor(this.themeTokens.colorTextSecondary)
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_lg'),
                bottom: $r('app.float.spacing_sm'),
              })

            TextInput({
              placeholder: I18nHelper.t(I18nKeys.NOTIF_DEFAULT_MESSAGE_PLACEHOLDER, this.currentLanguage),
              text: this.notifMessage,
            })
              .fontSize(this.fontTokens.body)
              .fontColor(this.themeTokens.colorTextPrimary)
              .placeholderColor(this.themeTokens.colorTextSecondary)
              .backgroundColor(this.themeTokens.colorBackground)
              .borderWidth({ bottom: 1 })
              .borderColor(this.themeTokens.colorDivider)
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                bottom: $r('app.float.spacing_md'),
              })
              .onChange((value: string) => {
                this.notifMessage = value;
                NotificationSettingsViewModel.setDefaultMessage(value);
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor(this.themeTokens.colorBackground)
  }
}