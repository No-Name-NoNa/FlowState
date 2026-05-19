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
import { NavigationManager } from '../utils/NavigationManager';
import { ThemeTokens } from '../utils/ThemeTokens';
import { ThemeConfig } from '../models/DataModels';

@Entry
@Component
struct Index {
  @StorageLink(NavigationManager.getMainTabLink()) currentTabIndex: number = 0;
  @StorageLink(NavigationManager.getTabBarCoverLink()) tabBarCovered: boolean = false;
  @StorageLink(ThemeContext.getThemeLink()) currentTheme: ThemeConfig = ThemeContext.getCurrentTheme();
  @State dataReady: boolean = false;

  async aboutToAppear() {
    await DataManager.init(this.getUIContext().getHostContext() as Context);
    const theme = await ThemeManager.getCurrentTheme();
    ThemeContext.init(theme);
    NavigationManager.setTabBarCovered(false);
    this.dataReady = true;
  }

  @Builder
  TabBuilder(index: number, name: string, iconResource: Resource) {
    Column() {
      Column() {
        SymbolGlyph(iconResource)
          .fontSize(this.currentTabIndex === index ? 21 : 20)
          .fontColor([this.currentTabIndex === index ? this.currentTheme.primaryColor : ThemeTokens.secondary(this.currentTheme)])
      }
      .width(38)
      .height(30)
      .borderRadius(14)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.currentTabIndex === index ? ThemeTokens.selectedSurface(this.currentTheme) : '#00000000')
      .border({
        width: this.currentTabIndex === index ? 1 : 0,
        color: this.currentTabIndex === index ? ThemeTokens.cardBorder(this.currentTheme) : '#00000000'
      })
      .shadow({
        radius: this.currentTabIndex === index ? 8 : 0,
        color: this.currentTabIndex === index ? ThemeTokens.paperThinShadow(this.currentTheme) : '#00000000',
        offsetX: 0,
        offsetY: 3
      })

      Text(name)
        .fontSize(9)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTabIndex === index ? this.currentTheme.primaryColor : ThemeTokens.secondary(this.currentTheme))
        .margin({ top: 3 })
    }
    .width(64)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  LoadingState() {
    Column() {
      Text('流序')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTheme.textColor)

      Text('万事入序，稍候即启。')
        .fontSize(13)
        .fontColor(ThemeTokens.muted(this.currentTheme))
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.currentTheme.backgroundColor)
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
    .barHeight(this.tabBarCovered ? 0 : 64)
    .onChange((index: number) => {
      this.currentTabIndex = index;
      NavigationManager.setTabBarCovered(false);
    })
    .backgroundColor(this.currentTheme.backgroundColor)
  }

  build() {
    if (this.dataReady) {
      this.MainTabs()
    } else {
      this.LoadingState()
    }
  }
}
