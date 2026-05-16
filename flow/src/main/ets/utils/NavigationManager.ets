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
  static push(uiContext: UIContext, url: string, params?: RouteParams): void {
    try {
      const options: router.RouterOptions = params === undefined ? { url } : { url, params: params as Object };
      uiContext.getRouter().pushUrl(options);
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
