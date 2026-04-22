/**
 * 主页面 - TabBar 导航
 */

import { HomePage } from './HomePage';
import { TaskPage } from './TaskPage';
import { RecordsPage } from './RecordsPage';
import { DataManager } from '../utils/DataManager';

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 1; // 默认首页

  async aboutToAppear() {
    // 初始化数据管理器
    await DataManager.init(getContext(this));
  }

  @Builder
  TabBuilder(index: number, name: string, icon: string) {
    Column() {
      Text(icon)
        .fontSize(24)
        .fontColor(this.currentTabIndex === index ? $r('app.color.primary_color') : $r('app.color.text_secondary'))

      Text(name)
        .fontSize($r('app.float.caption_font_size'))
        .fontColor(this.currentTabIndex === index ? $r('app.color.primary_color') : $r('app.color.text_secondary'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ index: this.currentTabIndex }) {
      TabContent() {
        TaskPage()
      }
      .tabBar(this.TabBuilder(0, '任务', '📋'))

      TabContent() {
        HomePage()
      }
      .tabBar(this.TabBuilder(1, '首页', '🏠'))

      TabContent() {
        RecordsPage()
      }
      .tabBar(this.TabBuilder(2, '记录', '📊'))
    }
    .width('100%')
    .height('100%')
    .barPosition(BarPosition.End)
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.currentTabIndex = index;
    })
    .backgroundColor($r('app.color.background_color'))
  }
}
