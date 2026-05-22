import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { notificationManager } from '@kit.NotificationKit';
import {
  KEY_APP_LANGUAGE,
  KEY_NOTIFY_TAB_INDEX,
  KEY_PENDING_ARCHIVE_TASK_ID,
  KEY_PENDING_OPEN_TASK_ID,
  KEY_TASK_NEEDS_REFRESH,
  LOG_DOMAIN,
  WANT_PARAM_ARCHIVE_TASK_ID,
  WANT_PARAM_NOTIFY_TAB,
  WANT_PARAM_OPEN_TASK_ID,
} from '../constants/AppConstants';
import { I18nHelper } from '../util/I18nHelper';
import { InboxDatabase } from '../util/InboxDatabase';
import { TaskDatabase } from '../util/TaskDatabase';
import { PreferencesHelper } from '../util/PreferencesHelper';
import { ThemeHelper } from '../util/ThemeHelper';
import { FontSizeHelper } from '../util/FontSizeHelper';
import { NotificationSettingsViewModel } from '../viewmodel/NotificationSettingsViewModel';
import { TaskViewModel } from '../viewmodel/TaskViewModel';

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

    // 从持久化存储恢复字体缩放档位，写入 AppStorage
    // 必须在页面加载前完成，确保组件初始化时即读到正确的字号 tokens
    FontSizeHelper.initFromStorage();

    // 从持久化存储恢复全局通知设置，写入 AppStorage
    NotificationSettingsViewModel.initFromStorage();

    // 预加载所有语言翻译文件，为 I18nHelper.t() 提供数据
    I18nHelper.init(this.context);

    // 初始化收集箱 RDB 数据库（异步，不阻塞页面加载）
    InboxDatabase.init(this.context);

    // 初始化任务 RDB 数据库（异步，不阻塞页面加载）
    TaskDatabase.init(this.context);

    // 启动时协调提醒定时器：为全部活跃任务重新调度内存定时器（fire-and-forget）
    TaskViewModel.reconcileReminders().catch((err: Error) => {
      hilog.error(LOG_DOMAIN, 'FlowAbility', '提醒协调异常：%{public}s', JSON.stringify(err));
    });

    // 冷启动时读取 Want 参数：若携带归档任务 ID，暂存到 AppStorage 等 DB 加载完后处理
    this.handleWantParams(want, false);

    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onCreate');
  }

  /**
   * App 处于后台或已销毁 Ability 被通知再次唤醒时触发（热启动）。
   * 此时 DB 已就绪，可直接执行归档操作。
   */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onNewWant');
    this.handleWantParams(want, true);
  }

  /**
   * 解析 Want 参数并按冷/热启动分别处理。
   * 热启动（isHot=true）：DB 已就绪，直接执行归档并触发列表刷新。
   * 冷启动（isHot=false）：DB 尚未加载，将 archiveTaskId 写入 AppStorage
   *                        等 TaskPage 加载完数据后再处理。
   */
  private handleWantParams(want: Want, isHot: boolean): void {
    if (want.parameters === undefined) {
      return;
    }

    // 读取归档任务 ID（0 或 undefined 表示无需归档）
    const archiveId: number = want.parameters[WANT_PARAM_ARCHIVE_TASK_ID] as number ?? 0;
    if (archiveId > 0) {
      if (isHot) {
        // 热启动：DB 就绪，直接归档并触发列表刷新
        TaskViewModel.archive(archiveId).then(() => {
          AppStorage.setOrCreate<boolean>(KEY_TASK_NEEDS_REFRESH, true);
        }).catch((err: Error) => {
          hilog.error(LOG_DOMAIN, 'FlowAbility', '热启动归档失败（taskId=%{public}d）：%{public}s',
            archiveId, JSON.stringify(err));
        });
      } else {
        // 冷启动：DB 未就绪，暂存 ID，等 TaskPage 加载完后处理
        AppStorage.setOrCreate<number>(KEY_PENDING_ARCHIVE_TASK_ID, archiveId);
      }
    }

    // 读取 Tab 切换参数，无论冷热均写入 AppStorage
    const tabIdx: number = want.parameters[WANT_PARAM_NOTIFY_TAB] as number ?? -1;
    if (tabIdx >= 0) {
      AppStorage.setOrCreate<number>(KEY_NOTIFY_TAB_INDEX, tabIdx);
    }

    // 读取「打开任务详情」参数，无论冷热均写入 AppStorage，由 Index.ets @Watch 消费
    const openTaskId: number = want.parameters[WANT_PARAM_OPEN_TASK_ID] as number ?? 0;
    if (openTaskId > 0) {
      AppStorage.setOrCreate<number>(KEY_PENDING_OPEN_TASK_ID, openTaskId);
    }
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
    // 每次进入前台时限频协调提醒，补调度应用存活期间可能遗漏的定时器
    TaskViewModel.maybeReconcile().catch((err: Error) => {
      hilog.error(LOG_DOMAIN, 'FlowAbility', '前台提醒协调异常：%{public}s', JSON.stringify(err));
    });
  }

  onBackground(): void {
    hilog.info(LOG_DOMAIN, 'FlowAbility', 'Ability onBackground');
  }
}