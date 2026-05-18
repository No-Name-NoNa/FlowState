/**
 * UIContext Router wrapper.
 */

import { UIContext, router } from '@kit.ArkUI';

export interface RouteParams {
  duration?: number;
  scheduleId?: string;
  taskId?: string;
  autoStart?: boolean;
}

export class NavigationManager {
  private static readonly MAIN_TAB_KEY: string = 'flowMainTabIndex';
  private static readonly TAB_BAR_COVER_KEY: string = 'flowTabBarCovered';

  static getMainTabLink(): string {
    return NavigationManager.MAIN_TAB_KEY;
  }

  static getTabBarCoverLink(): string {
    return NavigationManager.TAB_BAR_COVER_KEY;
  }

  static setTabBarCovered(covered: boolean): void {
    AppStorage.setOrCreate(NavigationManager.TAB_BAR_COVER_KEY, covered);
  }

  static setMainTabIndex(index: number): void {
    AppStorage.setOrCreate(NavigationManager.MAIN_TAB_KEY, index);
    NavigationManager.setTabBarCovered(false);
  }

  static openMainTab(url: string): boolean {
    const index = NavigationManager.getMainTabIndex(url);
    if (index < 0) {
      return false;
    }
    NavigationManager.setMainTabIndex(index);
    return true;
  }

  static getMainTabIndex(url: string): number {
    if (url === 'pages/TodayPage') return 0;
    if (url === 'pages/InboxPage') return 1;
    if (url === 'pages/PlanPage') return 2;
    if (url === 'pages/UpcomingPage') return 3;
    if (url === 'pages/ReviewPage') return 4;
    return -1;
  }

  static push(uiContext: UIContext, url: string, params?: RouteParams): void {
    try {
      const options: router.RouterOptions = params === undefined ? { url } : { url, params: params as Object };
      uiContext.getRouter().pushUrl(options);
    } catch (err) {
    }
  }

  static replace(uiContext: UIContext, url: string, params?: RouteParams): void {
    try {
      const options: router.RouterOptions = params === undefined ? { url } : { url, params: params as Object };
      uiContext.getRouter().replaceUrl(options);
    } catch (err) {
    }
  }

  static back(uiContext: UIContext): void {
    try {
      uiContext.getRouter().back();
    } catch (err) {
    }
  }

  static getParams(uiContext: UIContext): Record<string, Object> {
    try {
      const params = uiContext.getRouter().getParams();
      return params as Record<string, Object>;
    } catch (err) {
      return {};
    }
  }
}
