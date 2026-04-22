/**
 * 通用玻璃卡片组件
 */

@Component
export struct GlassCard {
  @Prop padding: number = 16;
  @Prop borderRadius: number = 16;
  @Prop backgroundColor: string = '#FFFFFFCC';
  @BuilderParam content: () => void;

  build() {
    Column() {
      this.content();
    }
    .width('100%')
    .padding(this.padding)
    .borderRadius(this.borderRadius)
    .backgroundColor(this.backgroundColor)
    .backdropBlur(20)
    .shadow({
      radius: 12,
      color: '#00000010',
      offsetX: 0,
      offsetY: 4
    })
  }
}
