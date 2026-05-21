/**
 * SpreadEffectHelper.ets
 * 横向矩形扩散点击特效工具类。
 * 封装统一的动效参数与 animateTo 执行逻辑，供各页面调用，消除重复代码。
 *
 * 使用方式：
 *   各组件保留自身 @State（ArkUI 依赖追踪要求状态属于组件本身），
 *   通过回调将状态变更注入工具方法，即可复用动效逻辑：
 *
 *   SpreadEffectHelper.trigger(
 *     (idx)          => { this.pressedRowIndex = idx; },
 *     (scale, opacity) => {
 *       this.rowSpreadScale   = scale;
 *       this.rowSpreadOpacity = opacity;
 *     },
 *     (x) => { this.spreadCenterX = x; },
 *     rowIndex,
 *     touchX,
 *   );
 */

/** 横向矩形扩散特效工具类 */
export class SpreadEffectHelper {
  /** 动效时长（ms） */
  static readonly DURATION: number = 350;
  /** 起始横向缩放比 */
  static readonly SCALE_START: number = 0.02;
  /** 起始透明度 */
  static readonly OPACITY_START: number = 0.12;
  /** 终止横向缩放比 */
  static readonly SCALE_END: number = 1.4;

  /**
   * 触发横向矩形扩散动效。
   * 矩形以触摸点为变换中心，向两侧以 EaseOut 曲线横向扩散并淡出，无涟漪圆环。
   * @param setIndex    设置当前激活行索引的回调（动效结束后自动传入 -1 重置）
   * @param setValues   同时设置缩放比和透明度的回调
   * @param setCenterX  设置 scale 变换中心 X 坐标（vp）的回调，应传入触摸点 X
   * @param rowIndex    被点击行的索引
   * @param touchX      触摸点相对于目标元素左边缘的 X 坐标（vp），来自 TouchEvent.touches[0].x
   */
  static trigger(
    setIndex: (index: number) => void,
    setValues: (scale: number, opacity: number) => void,
    setCenterX: (x: number) => void,
    rowIndex: number,
    touchX: number,
  ): void {
    setIndex(rowIndex);
    setCenterX(touchX);
    setValues(SpreadEffectHelper.SCALE_START, SpreadEffectHelper.OPACITY_START);
    animateTo(
      {
        duration: SpreadEffectHelper.DURATION,
        curve: Curve.EaseOut,
        onFinish: () => {
          setIndex(-1);
        },
      },
      () => {
        setValues(SpreadEffectHelper.SCALE_END, 0);
      },
    );
  }
}
