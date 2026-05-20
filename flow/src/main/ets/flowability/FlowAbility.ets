import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { KEY_APP_LANGUAGE, LANG_ZH_CN, LOG_DOMAIN } from '../constants/AppConstants';

export default class FlowAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(LOG_DOMAIN, 'FlowAbility', '设置颜色模式失败：%{public}s', JSON.stringify(err));
    }

    // 持久化语言偏好设置，确保应用重启后仍保留用户选择的语言
    PersistentStorage.persistProp<string>(KEY_APP_LANGUAGE, LANG_ZH_CN);

    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onWindowStageCreate');

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