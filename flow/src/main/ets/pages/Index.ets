/**
 * 主页面 - Tab 导航
 */

import { HomePage } from './HomePage';
import { TaskPage } from './TaskPage';
import { RecordsPage } from './RecordsPage';
import { DataManager } from '../utils/DataManager';
import { ThemeManager } from '../utils/ThemeManager';
import { ThemeContext } from '../utils/ThemeContext';

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 1;

  async aboutToAppear() {
    await DataManager.init(this.getUIContext().getHostContext() as Context);
    const theme = await ThemeManager.getCurrentTheme();
    ThemeContext.init(theme);
  }

  @Builder
  TabBuilder(index: number, name: string, iconResource: Resource) {
    Column() {
      SymbolGlyph(iconResource)
        .fontSize(22)
        .fontColor([this.currentTabIndex === index ? '#2F6F86' : '#7D8C96'])

      Text(name)
        .fontSize(11)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTabIndex === index ? '#2F6F86' : '#7D8C96')
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
      .tabBar(this.TabBuilder(2, '记录', $r('sys.symbol.clock')))
    }
    .width('100%')
    .height('100%')
    .barPosition(BarPosition.End)
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.currentTabIndex = index;
    })
    .backgroundColor('#F4F7F8')
  }
}
