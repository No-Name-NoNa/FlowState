/**
 * 加载指示器组件
 */

@Component
export struct LoadingIndicator {
  @Prop size: number = 48;
  @Prop color: string = '#4A90E2';

  build() {
    LoadingProgress()
      .width(this.size)
      .height(this.size)
      .color(this.color)
  }
}
