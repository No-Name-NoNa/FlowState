/**
 * 通用玻璃卡片组件
 */

@Component
export struct GlassCard {
  @Prop cardPadding: number = 16;
  @Prop cardBorderRadius: number = 16;
  @Prop cardBackgroundColor: string = '#FFFFFFCC';
  @BuilderParam content: () => void;

  build() {
    Column() {
      this.content();
    }
    .width('100%')
    .padding(this.cardPadding)
    .borderRadius(this.cardBorderRadius)
    .backgroundColor(this.cardBackgroundColor)
    .backdropBlur(20)
    .shadow({
      radius: 12,
      color: '#00000010',
      offsetX: 0,
      offsetY: 4
    })
  }
}
