/**
 * Root tab navigation.
 */

import { TodayPage } from './TodayPage';
import { InboxPage } from './InboxPage';
import { PlanPage } from './PlanPage';
import { UpcomingPage } from './UpcomingPage';
import { ReviewPage } from './ReviewPage';
import { DataManager } from '../utils/DataManager';
import { ThemeManager } from '../utils/ThemeManager';
import { ThemeContext } from '../utils/ThemeContext';

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 0;
  @State dataReady: boolean = false;

  async aboutToAppear() {
    await DataManager.init(this.getUIContext().getHostContext() as Context);
    const theme = await ThemeManager.getCurrentTheme();
    ThemeContext.init(theme);
    this.dataReady = true;
  }

  @Builder
  TabBuilder(index: number, name: string, iconResource: Resource) {
    Column() {
      SymbolGlyph(iconResource)
        .fontSize(20)
        .fontColor([this.currentTabIndex === index ? '#256D85' : '#8A969B'])

      Text(name)
        .fontSize(9)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTabIndex === index ? '#256D85' : '#8A969B')
        .margin({ top: 3 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  LoadingState() {
    Column() {
      Text('Flow State')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182126')

      Text('正在准备本地数据')
        .fontSize(13)
        .fontColor('#62727A')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F7F8F6')
  }

  @Builder
  MainTabs() {
    Tabs({ index: this.currentTabIndex }) {
      TabContent() {
        TodayPage()
      }
      .tabBar(this.TabBuilder(0, '今天', $r('sys.symbol.calendar')))

      TabContent() {
        InboxPage()
      }
      .tabBar(this.TabBuilder(1, '收集', $r('sys.symbol.doc_text')))

      TabContent() {
        PlanPage()
      }
      .tabBar(this.TabBuilder(2, '规划', $r('sys.symbol.list_bullet')))

      TabContent() {
        UpcomingPage()
      }
      .tabBar(this.TabBuilder(3, '未来', $r('sys.symbol.clock')))

      TabContent() {
        ReviewPage()
      }
      .tabBar(this.TabBuilder(4, '复盘', $r('sys.symbol.arrow_clockwise')))
    }
    .width('100%')
    .height('100%')
    .barPosition(BarPosition.End)
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.currentTabIndex = index;
    })
    .backgroundColor('#F7F8F6')
  }

  build() {
    if (this.dataReady) {
      this.MainTabs()
    } else {
      this.LoadingState()
    }
  }
}
