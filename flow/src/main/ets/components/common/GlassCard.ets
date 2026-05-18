/**
 * 通用玻璃卡片组件
 */

@Component
export struct GlassCard {
  @Prop cardPadding: number = 18;
  @Prop cardBorderRadius: number = 18;
  @Prop cardBackgroundColor: string = '#FCFEFE';
  @BuilderParam content: () => void;

  build() {
    Column() {
      this.content();
    }
    .width('100%')
    .padding(this.cardPadding)
    .borderRadius(this.cardBorderRadius)
    .backgroundColor(this.cardBackgroundColor)
    .border({ width: 1, color: '#E3EBEE' })
    .shadow({
      radius: 22,
      color: '#0F23313A',
      offsetX: 0,
      offsetY: 10
    })
  }
}
