import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { notificationManager } from '@kit.NotificationKit';
import { KEY_APP_LANGUAGE, LOG_DOMAIN } from '../constants/AppConstants';
import { I18nHelper } from '../util/I18nHelper';
import { InboxDatabase } from '../util/InboxDatabase';
import { TaskDatabase } from '../util/TaskDatabase';
import { PreferencesHelper } from '../util/PreferencesHelper';
import { ThemeHelper } from '../util/ThemeHelper';
import { NotificationSettingsViewModel } from '../viewmodel/NotificationSettingsViewModel';

export default class FlowAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'FlowAbility', '设置颜色模式失败：%{public}s', JSON.stringify(err));
    }

    // 初始化偏好设置，同步读取上次保存的语言值
    PreferencesHelper.init(this.context);

    // 将已保存的语言写入 AppStorage，供全局 @StorageLink 组件使用
    // 必须在任何页面加载（onWindowStageCreate）之前完成，确保组件初始化时即读到正确语言
    AppStorage.setOrCreate<string>(KEY_APP_LANGUAGE, PreferencesHelper.getLanguage());

    // 从持久化存储恢复主题 ID 和颜色 tokens，写入 AppStorage
    // 必须在页面加载前完成，确保组件初始化时即读到正确的主题配色
    ThemeHelper.initFromStorage();

    // 从持久化存储恢复全局通知设置，写入 AppStorage
    NotificationSettingsViewModel.initFromStorage();

    // 预加载所有语言翻译文件，为 I18nHelper.t() 提供数据
    I18nHelper.init(this.context);

    // 初始化收集箱 RDB 数据库（异步，不阻塞页面加载）
    InboxDatabase.init(this.context);

    // 初始化任务 RDB 数据库（异步，不阻塞页面加载）
    TaskDatabase.init(this.context);

    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onWindowStageCreate');

    // 请求通知权限（弹出系统授权对话框，用户首次使用时确认）
    notificationManager.requestEnableNotification(this.context).catch((err: Error) => {
      hilog.warn(LOG_DOMAIN, 'FlowAbility', '通知权限请求未通过：%{public}s', JSON.stringify(err));
    });

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(LOG_DOMAIN, 'FlowAbility', '加载页面内容失败：%{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(LOG_DOMAIN, 'FlowAbility', '页面内容加载成功');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onBackground');
  }
}