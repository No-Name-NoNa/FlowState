/**
 * NotificationSettingsViewModel.ets
 * 全局通知设置业务逻辑层。
 * 启动时由 FlowAbility.onCreate() 调用 initFromStorage()。
 * 全局设置包含：
 *  - 开始提醒默认消息文字（区间任务开始时通知的兜底文本）
 *  - 结束提醒默认消息文字（任务截止/完成通知的兜底文本）
 * 提醒类型均在任务编辑页单独配置，此处无全局默认类型。
 */
import { PreferencesHelper } from '../util/PreferencesHelper';

/** 全局通知设置 ViewModel，所有方法均为静态 */
export class NotificationSettingsViewModel {
  /**
   * 从 Preferences 读取全局通知设置并初始化。
   * 必须在 PreferencesHelper.init() 之后、任何页面加载之前调用。
   */
  static initFromStorage(): void {
    // 当前仅需预热消息文字缓存，无 AppStorage key 需要同步
  }

  /**
   * 读取当前全局默认「结束/完成」通知消息文本。
   * @returns 消息文本（空字符串表示使用 App 自动生成）
   */
  static getDefaultMessage(): string {
    return PreferencesHelper.getNotifMessage();
  }

  /**
   * 更新全局默认「结束/完成」通知消息文本，持久化到磁盘。
   * @param message 消息文本，空字符串表示使用 App 自动生成
   */
  static setDefaultMessage(message: string): void {
    PreferencesHelper.saveNotifMessage(message);
  }

  /**
   * 读取当前全局默认「开始提醒」通知消息文本。
   * @returns 消息文本（空字符串表示使用 App 自动生成）
   */
  static getDefaultStartMessage(): string {
    return PreferencesHelper.getNotifStartMessage();
  }

  /**
   * 更新全局默认「开始提醒」通知消息文本，持久化到磁盘。
   * @param message 消息文本，空字符串表示使用 App 自动生成
   */
  static setDefaultStartMessage(message: string): void {
    PreferencesHelper.saveNotifStartMessage(message);
  }
}
