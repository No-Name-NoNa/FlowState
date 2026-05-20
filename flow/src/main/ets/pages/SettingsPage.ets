/**
 * SettingsPage.ets
 * 应用设置页。
 * 通过全屏路由从首页 Header 的设置图标跳转进入。
 * 当前阶段提供语言偏好设置，后续可在此扩展更多配置项。
 * 遵循去卡片化原则：无卡片阴影，以细分隔线和留白进行视觉分层。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { SettingsViewModel } from '../viewmodel/SettingsViewModel';
import { KEY_APP_LANGUAGE, LANG_ZH_CN, LANG_EN_US, DIVIDER_STROKE_WIDTH } from '../constants/AppConstants';

/** 设置页 */
@Entry
@Component
struct SettingsPage {
  /** 当前语言，绑定全局 AppStorage，切换后整个应用实时响应 */
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;

  /**
   * 构建单个语言选项行。
   * 选中项以主色文字 + 右侧勾选图标标识，未选中项以次要色显示。
   * @param langCode    语言标识代码
   * @param displayName 展示给用户的语言名称
   */
  @Builder
  languageOptionItem(langCode: string, displayName: string): void {
    Row() {
      Text(displayName)
        .fontSize($r('app.float.font_size_body'))
        .fontColor(this.currentLanguage === langCode
          ? $r('app.color.color_settings_selected')
          : $r('app.color.color_text_secondary'))
        .fontWeight(this.currentLanguage === langCode
          ? FontWeight.Medium
          : FontWeight.Regular)
        .layoutWeight(1)

      // 选中时展示勾选图标
      if (this.currentLanguage === langCode) {
        Image($r('sys.media.ohos_ic_public_ok'))
          .width($r('app.float.icon_size_sm'))
          .height($r('app.float.icon_size_sm'))
          .fillColor($r('app.color.color_settings_selected'))
      }
    }
    .width('100%')
    .height($r('app.float.settings_item_height'))
    .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      // 委托 ViewModel 写入语言偏好，触发全局 @StorageLink 响应式更新
      SettingsViewModel.setLanguage(langCode);
    })
  }

  build() {
    Column() {
      // ── 顶部导航栏：返回按钮 + 页面标题 ──────────────────────────────────
      Row() {
        // 返回按钮
        Image($r('sys.media.ohos_ic_back'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor($r('app.color.color_text_primary'))
          .onClick(() => {
            router.back();
          })

        // 页面标题
        Text(I18nHelper.getSettingsTitle(this.currentLanguage))
          .fontSize($r('app.float.font_size_header_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 右侧占位，保持标题视觉居中
        Row()
          .width($r('app.float.icon_size_md'))
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
      .alignItems(VerticalAlign.Center)

      // 顶部分隔线
      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color($r('app.color.color_divider'))
        .width('100%')

      // ── 设置内容区 ────────────────────────────────────────────────────────
      Column() {
        // 语言分区标题
        Text(I18nHelper.getLanguageLabel(this.currentLanguage))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.color_text_secondary'))
          .width('100%')
          .padding({
            left: $r('app.float.spacing_lg'),
            right: $r('app.float.spacing_lg'),
            top: $r('app.float.spacing_lg'),
            bottom: $r('app.float.spacing_sm')
          })

        // 语言选项：简体中文
        this.languageOptionItem(LANG_ZH_CN, '简体中文')

        // 选项间分隔线
        Divider()
          .strokeWidth(DIVIDER_STROKE_WIDTH)
          .color($r('app.color.color_divider'))
          .margin({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })

        // 语言选项：English
        this.languageOptionItem(LANG_EN_US, 'English')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 底部弹性空白，将内容推至顶部
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_background'))
  }
}
