import { ThemeConfig } from '../../models/DataModels';
import { ThemeContext } from '../../utils/ThemeContext';
import { ThemeTokens } from '../../utils/ThemeTokens';

@Component
export struct GlassCard {
  @StorageLink(ThemeContext.getThemeLink()) currentTheme: ThemeConfig = ThemeContext.getCurrentTheme();
  @Prop cardPadding: number = 18;
  @Prop cardBorderRadius: number = 22;
  @Prop cardBackgroundColor: string = '';
  @Prop accentColor: string = '';
  @Prop showAccent: boolean = false;
  @BuilderParam content: () => void;

  build() {
    Column() {
      if (this.showAccent) {
        Text()
          .width(44)
          .height(3)
          .borderRadius(2)
          .backgroundColor(this.accentColor.length > 0 ? this.accentColor : ThemeTokens.brandLine(this.currentTheme))
          .margin({ bottom: 14 })
      }

      this.content();
    }
    .width('100%')
    .padding(this.cardPadding)
    .borderRadius(this.cardBorderRadius)
    .backgroundColor(this.cardBackgroundColor.length > 0 ? this.cardBackgroundColor : ThemeTokens.paper(this.currentTheme))
    .border({ width: 1, color: ThemeTokens.paperBorder(this.currentTheme) })
    .shadow({
      radius: 30,
      color: ThemeTokens.paperShadow(this.currentTheme),
      offsetX: 0,
      offsetY: 14
    })
  }
}
