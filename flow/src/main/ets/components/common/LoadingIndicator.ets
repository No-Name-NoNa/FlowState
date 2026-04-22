/**
 * 加载指示器组件
 */

@Component
export struct LoadingIndicator {
  @Prop indicatorSize: number = 48;
  @Prop color: string = '#4A90E2';

  build() {
    LoadingProgress()
      .width(this.indicatorSize)
      .height(this.indicatorSize)
      .color(this.color)
  }
}