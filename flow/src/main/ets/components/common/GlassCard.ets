/**
 * 通用玻璃卡片组件
 */

@Component
export struct GlassCard {
  @Prop cardPadding: number = 18;
  @Prop cardBorderRadius: number = 8;
  @Prop cardBackgroundColor: string = '#FFFFFF';
  @BuilderParam content: () => void;

  build() {
    Column() {
      this.content();
    }
    .width('100%')
    .padding(this.cardPadding)
    .borderRadius(this.cardBorderRadius)
    .backgroundColor(this.cardBackgroundColor)
    .shadow({
      radius: 18,
      color: '#23313A0F',
      offsetX: 0,
      offsetY: 10
    })
  }
}
