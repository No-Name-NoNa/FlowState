/**
 * DebugPage.ets
 * 调试工具页。
 * 提供演示数据生成与数据重置功能，方便快速构造展示环境。
 * 页面风格与设置页保持一致：去卡片化，细分隔线分层，点击行带扩散特效。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_FONT_TOKENS,
  KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';
import { DebugViewModel } from '../viewmodel/DebugViewModel';

/** 破坏性操作文字颜色（固定红色，与归档详情页一致） */
const COLOR_DESTRUCTIVE: string = '#E84040';

/** 调试工具页 */
@Entry
@Component
struct DebugPage {
  /** 订阅语言变化 */
  @StorageLink(KEY_APP_LANGUAGE) private lang: string = LANG_ZH_CN;
  /** 订阅主题 tokens */
  @StorageLink(KEY_THEME_TOKENS) private themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  /** 订阅字体 tokens */
  @StorageLink(KEY_FONT_TOKENS) private fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  // ── 操作执行状态 ─────────────────────────────────────────────────────────────
  /** 是否正在执行异步操作，防止重复触发 */
  @State private isWorking: boolean = false;
  /** 最近操作结果文字，完成或失败时更新 */
  @State private statusMsg: string = '';
  // ── 行点击扩散特效状态 ───────────────────────────────────────────────────────
  /** 当前正在播放扩散动效的行索引，-1 表示无动效 */
  @State private pressedRowIndex: number = -1;
  /** 扩散矩形横向缩放比 */
  @State private rowSpreadScale: number = 0;
  /** 扩散矩形透明度 */
  @State private rowSpreadOpacity: number = 0;
  /** 扩散矩形 scale 变换中心 X（vp） */
  @State private spreadCenterX: number = 0;
  // ── 操作行高（两行文字，比标准设置行高略高） ──────────────────────────────────
  private readonly ROW_HEIGHT: number = 64;

  build() {
    Column() {
      // ── 顶部导航栏 ──────────────────────────────────────────────────────────
      Row() {
        Image($r('sys.media.ohos_ic_back'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextPrimary)
          .onClick(() => {
            router.back();
          })

        Text(I18nHelper.t(I18nKeys.DEBUG_PAGE_TITLE, this.lang))
          .fontSize(this.fontTokens.headerTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 右侧占位，保持标题视觉居中
        Row()
          .width($r('app.float.icon_size_md'))
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
      .alignItems(VerticalAlign.Center)

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)

      // ── 内容区（可滚动） ────────────────────────────────────────────────────
      Scroll() {
        Column() {
          // ── 第一节：生成演示数据 ────────────────────────────────────────────
          this.sectionLabel(I18nKeys.DEBUG_SECTION_GENERATE)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)

          this.generateTasksRow()

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })

          this.generateInboxRow()

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)

          // ── 第二节：重置数据 ──────────────────────────────────────────────
          this.sectionLabel(I18nKeys.DEBUG_SECTION_RESET)

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)

          this.clearTasksRow()

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })

          this.clearInboxRow()

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .margin({ left: $r('app.float.spacing_lg') })

          this.clearAllRow()

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)

          // ── 状态提示 ──────────────────────────────────────────────────────
          if (this.statusMsg !== '') {
            Text(this.statusMsg)
              .fontSize(this.fontTokens.caption)
              .fontColor(this.themeTokens.colorTextSecondary)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: $r('app.float.spacing_md'), bottom: $r('app.float.spacing_xs') })
          }

          // 底部安全间距
          Column().height(40)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }

  /** 节标题行：小号灰色文字，含上下留白 */
  @Builder
  private sectionLabel(key: I18nKeys): void {
    Text(I18nHelper.t(key, this.lang))
      .fontSize(this.fontTokens.caption)
      .fontColor(this.themeTokens.colorTextSecondary)
      .width('100%')
      .padding({
        left: $r('app.float.spacing_lg'),
        top: $r('app.float.spacing_md'),
        bottom: $r('app.float.spacing_xs'),
      })
  }

  /** 生成演示任务行（带箭头，点击后异步执行） */
  @Builder
  private generateTasksRow(): void {
    Stack({ alignContent: Alignment.Center }) {
      if (this.pressedRowIndex === 0) {
        Rect()
          .width('100%')
          .height(this.ROW_HEIGHT)
          .fill(this.themeTokens.colorTextPrimary)
          .opacity(this.rowSpreadOpacity)
          .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
          .hitTestBehavior(HitTestMode.None)
      }
      Row() {
        Column() {
          Text(I18nHelper.t(I18nKeys.DEBUG_GEN_TASKS_LABEL, this.lang))
            .fontSize(this.fontTokens.body)
            .fontColor(this.themeTokens.colorTextPrimary)
          Text(I18nHelper.t(I18nKeys.DEBUG_GEN_TASKS_DESC, this.lang))
            .fontSize(this.fontTokens.caption)
            .fontColor(this.themeTokens.colorTextSecondary)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width($r('app.float.icon_size_sm'))
          .height($r('app.float.icon_size_sm'))
          .fillColor(this.isWorking
            ? this.themeTokens.colorTextSecondary
            : this.themeTokens.colorTextSecondary)
      }
      .width('100%')
      .height(this.ROW_HEIGHT)
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down && !this.isWorking) {
          this.triggerRowSpread(0, e.touches[0].x);
        }
      })
      .onClick(() => {
        this.execGenerateTasks();
      })
    }
    .width('100%')
    .height(this.ROW_HEIGHT)
  }

  /** 生成演示收集箱行（带箭头，点击后异步执行） */
  @Builder
  private generateInboxRow(): void {
    Stack({ alignContent: Alignment.Center }) {
      if (this.pressedRowIndex === 1) {
        Rect()
          .width('100%')
          .height(this.ROW_HEIGHT)
          .fill(this.themeTokens.colorTextPrimary)
          .opacity(this.rowSpreadOpacity)
          .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
          .hitTestBehavior(HitTestMode.None)
      }
      Row() {
        Column() {
          Text(I18nHelper.t(I18nKeys.DEBUG_GEN_INBOX_LABEL, this.lang))
            .fontSize(this.fontTokens.body)
            .fontColor(this.themeTokens.colorTextPrimary)
          Text(I18nHelper.t(I18nKeys.DEBUG_GEN_INBOX_DESC, this.lang))
            .fontSize(this.fontTokens.caption)
            .fontColor(this.themeTokens.colorTextSecondary)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width($r('app.float.icon_size_sm'))
          .height($r('app.float.icon_size_sm'))
          .fillColor(this.themeTokens.colorTextSecondary)
      }
      .width('100%')
      .height(this.ROW_HEIGHT)
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down && !this.isWorking) {
          this.triggerRowSpread(1, e.touches[0].x);
        }
      })
      .onClick(() => {
        this.execGenerateInbox();
      })
    }
    .width('100%')
    .height(this.ROW_HEIGHT)
  }

  /** 清空任务数据行（破坏性，点击弹确认框） */
  @Builder
  private clearTasksRow(): void {
    Stack({ alignContent: Alignment.Center }) {
      if (this.pressedRowIndex === 2) {
        Rect()
          .width('100%')
          .height(this.ROW_HEIGHT)
          .fill(this.themeTokens.colorTextPrimary)
          .opacity(this.rowSpreadOpacity)
          .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
          .hitTestBehavior(HitTestMode.None)
      }
      Row() {
        Column() {
          Text(I18nHelper.t(I18nKeys.DEBUG_CLEAR_TASKS_LABEL, this.lang))
            .fontSize(this.fontTokens.body)
            .fontColor(COLOR_DESTRUCTIVE)
          Text(I18nHelper.t(I18nKeys.DEBUG_CLEAR_TASKS_DESC, this.lang))
            .fontSize(this.fontTokens.caption)
            .fontColor(this.themeTokens.colorTextSecondary)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .height(this.ROW_HEIGHT)
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down && !this.isWorking) {
          this.triggerRowSpread(2, e.touches[0].x);
        }
      })
      .onClick(() => {
        this.showClearTasksDialog();
      })
    }
    .width('100%')
    .height(this.ROW_HEIGHT)
  }

  /** 清空收集箱行（破坏性，点击弹确认框） */
  @Builder
  private clearInboxRow(): void {
    Stack({ alignContent: Alignment.Center }) {
      if (this.pressedRowIndex === 3) {
        Rect()
          .width('100%')
          .height(this.ROW_HEIGHT)
          .fill(this.themeTokens.colorTextPrimary)
          .opacity(this.rowSpreadOpacity)
          .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
          .hitTestBehavior(HitTestMode.None)
      }
      Row() {
        Column() {
          Text(I18nHelper.t(I18nKeys.DEBUG_CLEAR_INBOX_LABEL, this.lang))
            .fontSize(this.fontTokens.body)
            .fontColor(COLOR_DESTRUCTIVE)
          Text(I18nHelper.t(I18nKeys.DEBUG_CLEAR_INBOX_DESC, this.lang))
            .fontSize(this.fontTokens.caption)
            .fontColor(this.themeTokens.colorTextSecondary)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .height(this.ROW_HEIGHT)
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down && !this.isWorking) {
          this.triggerRowSpread(3, e.touches[0].x);
        }
      })
      .onClick(() => {
        this.showClearInboxDialog();
      })
    }
    .width('100%')
    .height(this.ROW_HEIGHT)
  }

  /** 清空全部数据行（破坏性，点击弹确认框） */
  @Builder
  private clearAllRow(): void {
    Stack({ alignContent: Alignment.Center }) {
      if (this.pressedRowIndex === 4) {
        Rect()
          .width('100%')
          .height(this.ROW_HEIGHT)
          .fill(this.themeTokens.colorTextPrimary)
          .opacity(this.rowSpreadOpacity)
          .scale({ x: this.rowSpreadScale, y: 1, centerX: this.spreadCenterX })
          .hitTestBehavior(HitTestMode.None)
      }
      Row() {
        Column() {
          Text(I18nHelper.t(I18nKeys.DEBUG_CLEAR_ALL_LABEL, this.lang))
            .fontSize(this.fontTokens.body)
            .fontColor(COLOR_DESTRUCTIVE)
            .fontWeight(FontWeight.Medium)
          Text(I18nHelper.t(I18nKeys.DEBUG_CLEAR_ALL_DESC, this.lang))
            .fontSize(this.fontTokens.caption)
            .fontColor(this.themeTokens.colorTextSecondary)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .height(this.ROW_HEIGHT)
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down && !this.isWorking) {
          this.triggerRowSpread(4, e.touches[0].x);
        }
      })
      .onClick(() => {
        this.showClearAllDialog();
      })
    }
    .width('100%')
    .height(this.ROW_HEIGHT)
  }

  // ── 异步操作执行方法 ───────────────────────────────────────────────────────────

  /** 执行"生成演示任务"操作 */
  private execGenerateTasks(): void {
    if (this.isWorking) {
      return;
    }
    this.isWorking = true;
    this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_WORKING, this.lang);
    DebugViewModel.generateDemoTasks()
      .then(() => {
        this.isWorking = false;
        this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_DONE, this.lang);
      })
      .catch(() => {
        this.isWorking = false;
        this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_DONE, this.lang);
      });
  }

  /** 执行"生成演示收集箱"操作 */
  private execGenerateInbox(): void {
    if (this.isWorking) {
      return;
    }
    this.isWorking = true;
    this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_WORKING, this.lang);
    DebugViewModel.generateDemoInbox()
      .then(() => {
        this.isWorking = false;
        this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_DONE, this.lang);
      })
      .catch(() => {
        this.isWorking = false;
        this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_DONE, this.lang);
      });
  }

  /** 执行"清空任务数据"操作 */
  private execClearTasks(): void {
    if (this.isWorking) {
      return;
    }
    this.isWorking = true;
    this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_WORKING, this.lang);
    DebugViewModel.clearAllTasks()
      .then(() => {
        this.isWorking = false;
        this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_DONE, this.lang);
      })
      .catch(() => {
        this.isWorking = false;
        this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_DONE, this.lang);
      });
  }

  /** 执行"清空收集箱"操作 */
  private execClearInbox(): void {
    if (this.isWorking) {
      return;
    }
    this.isWorking = true;
    this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_WORKING, this.lang);
    DebugViewModel.clearAllInbox()
      .then(() => {
        this.isWorking = false;
        this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_DONE, this.lang);
      })
      .catch(() => {
        this.isWorking = false;
        this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_DONE, this.lang);
      });
  }

  /** 执行"清空全部数据"操作 */
  private execClearAll(): void {
    if (this.isWorking) {
      return;
    }
    this.isWorking = true;
    this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_WORKING, this.lang);
    DebugViewModel.clearAll()
      .then(() => {
        this.isWorking = false;
        this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_DONE, this.lang);
      })
      .catch(() => {
        this.isWorking = false;
        this.statusMsg = I18nHelper.t(I18nKeys.DEBUG_DONE, this.lang);
      });
  }

  // ── 确认弹窗 ──────────────────────────────────────────────────────────────────

  /** 清空任务数据确认弹窗 */
  private showClearTasksDialog(): void {
    AlertDialog.show({
      title: I18nHelper.t(I18nKeys.DEBUG_CLEAR_TASKS_LABEL, this.lang),
      message: I18nHelper.t(I18nKeys.DEBUG_CONFIRM_CLEAR_TASKS, this.lang),
      primaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
        fontColor: COLOR_DESTRUCTIVE,
        action: () => {
          this.execClearTasks();
        },
      },
      secondaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CANCEL, this.lang),
        action: () => {
        },
      },
      autoCancel: true,
    });
  }

  /** 清空收集箱确认弹窗 */
  private showClearInboxDialog(): void {
    AlertDialog.show({
      title: I18nHelper.t(I18nKeys.DEBUG_CLEAR_INBOX_LABEL, this.lang),
      message: I18nHelper.t(I18nKeys.DEBUG_CONFIRM_CLEAR_INBOX, this.lang),
      primaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
        fontColor: COLOR_DESTRUCTIVE,
        action: () => {
          this.execClearInbox();
        },
      },
      secondaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CANCEL, this.lang),
        action: () => {
        },
      },
      autoCancel: true,
    });
  }

  /** 清空全部数据确认弹窗 */
  private showClearAllDialog(): void {
    AlertDialog.show({
      title: I18nHelper.t(I18nKeys.DEBUG_CLEAR_ALL_LABEL, this.lang),
      message: I18nHelper.t(I18nKeys.DEBUG_CONFIRM_CLEAR_ALL, this.lang),
      primaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
        fontColor: COLOR_DESTRUCTIVE,
        action: () => {
          this.execClearAll();
        },
      },
      secondaryButton: {
        value: I18nHelper.t(I18nKeys.DIALOG_CANCEL, this.lang),
        action: () => {
        },
      },
      autoCancel: true,
    });
  }

  /**
   * 触发指定行的横向矩形扩散特效。
   * @param rowIndex 被点击的行索引
   * @param touchX   触摸点相对于行元素的 X 坐标（vp）
   */
  private triggerRowSpread(rowIndex: number, touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx) => {
        this.pressedRowIndex = idx;
      },
      (scale, opacity) => {
        this.rowSpreadScale = scale;
        this.rowSpreadOpacity = opacity;
      },
      (x) => {
        this.spreadCenterX = x;
      },
      rowIndex,
      touchX,
    );
  }
}
