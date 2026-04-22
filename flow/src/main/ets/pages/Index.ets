/**
 * 主页面 - TabBar 导航
 */

import { HomePage } from './HomePage';
import { TaskPage } from './TaskPage';
import { RecordsPage } from './RecordsPage';
import { DataManager } from '../utils/DataManager';
import { ThemeManager } from '../utils/ThemeManager';
import { ThemeContext } from '../utils/ThemeContext';
import { ThemeConfig } from '../models/DataModels';

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 1; // 默认首页
  @StorageLink(ThemeContext.getThemeLink()) currentTheme: ThemeConfig = ThemeContext.getCurrentTheme();

  async aboutToAppear() {
    // 初始化数据管理器
    await DataManager.init(this.getUIContext().getHostContext() as Context);

    // 初始化主题
    const theme = await ThemeManager.getCurrentTheme();
    ThemeContext.init(theme);
  }

  @Builder
  TabBuilder(index: number, name: string, iconResource: Resource) {
    Column() {
      SymbolGlyph(iconResource)
        .fontSize(24)
        .fontColor([this.currentTabIndex === index ? this.currentTheme.primaryColor : this.currentTheme.textColor])

      Text(name)
        .fontSize($r('app.float.caption_font_size'))
        .fontColor(this.currentTabIndex === index ? this.currentTheme.primaryColor : this.currentTheme.textColor)
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
      .tabBar(this.TabBuilder(0, '任务', $r('sys.symbol.doc_text')))

      TabContent() {
        HomePage()
      }
      .tabBar(this.TabBuilder(1, '首页', $r('sys.symbol.house')))

      TabContent() {
        RecordsPage()
      }
      .tabBar(this.TabBuilder(2, '记录', $r('sys.symbol.chart_bar')))
    }
    .width('100%')
    .height('100%')
    .barPosition(BarPosition.End)
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.currentTabIndex = index;
    })
    .backgroundColor(this.currentTheme.backgroundColor)
  }
}
