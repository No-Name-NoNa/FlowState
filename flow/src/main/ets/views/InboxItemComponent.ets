/**
 * InboxItemComponent.ets
 * 收集箱单条目组件。
 * 每条条目独立 @State 隔离扩散特效，避免父级重绘影响。
 *
 * 关键设计：
 *  - 所有数据字段以基本类型 @Prop 传入（id/text/content/tags/isPinned/updatedAt）。
 *    ArkUI 对接口/对象类型 @Prop 在 ForEach key 稳定时不可靠下推；
 *    基本类型 @Prop 保证父 @State 变化时强制刷新，彻底消除「文本静态」Bug。
 *  - 扩散 Rect 始终挂载，用 opacity 控制可见性；避免条件挂载时
 *    Stack 测量不稳定导致 height('100%') 解析为父容器全高而溢出到下方条目。
 *
 * 功能：
 *  - 标题行：标题（省略）→ 第一个标签 → 时间戳（均在一行，宽度统一）
 *  - 置顶时左侧 3vp 彩色竖条边框（始终占位，仅颜色变化）
 *  - 右侧三点按钮（bindMenu，不占用长按手势）
 *  - 单击主内容区跳转编辑页
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import { KEY_APP_LANGUAGE, KEY_THEME_TOKENS, LANG_ZH_CN } from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { InboxViewModel } from '../viewmodel/InboxViewModel';
import { formatTimestamp, parseTags } from '../model/InboxEntry';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

/** 收集箱单条目视图组件 */
@Component
export struct InboxItemComponent {
  // ── 基本类型 @Prop（保证 ForEach 父状态变化时强制下推刷新） ──────────────
  /** 条目主键 */
  @Prop entryId: number = 0;
  /** 条目标题 */
  @Prop entryText: string = '';
  /** 条目正文（仅菜单/跳转用，列表不渲染） */
  @Prop entryContent: string = '';
  /** 标签 JSON 字符串 */
  @Prop entryTags: string = '';
  /** 是否置顶（0/1） */
  @Prop entryIsPinned: number = 0;
  /** 最后修改时间戳（ms） */
  @Prop entryUpdatedAt: number = 0;
  /** 列表中的显示序号（1-based，仅视觉用，不存 DB） */
  @Prop entryIndex: number = 0;
  /** 是否处于拖拽排序模式（过滤期间为 false） */
  @Prop isEditMode: boolean = false;
  /** 数据变化回调：增删改置顶后通知父组件刷新 */
  onDataChanged: () => void = () => {
  };
  @StorageLink(KEY_APP_LANGUAGE) private lang: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) private themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  // ── 条目点击横向扩散特效状态（独立于其他条目，彻底消除整列重绘） ──────────
  @State private spreadScale: number = 0;
  @State private spreadOpacity: number = 0;
  @State private spreadCenterX: number = 0;

  /** 触发横向扩散特效（Rect 始终挂载，用 opacity 控制可见性，无需 pressedIndex） */
  private triggerSpread(touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx: number) => { /* Rect 始终挂载，无需 pressedIndex 控制 */
      },
      (scale: number, opacity: number) => {
        this.spreadScale = scale;
        this.spreadOpacity = opacity;
      },
      (x: number) => {
        this.spreadCenterX = x;
      },
      0,
      touchX,
    );
  }

  /** 三点菜单内容（bindMenu @Builder，点击三点按钮时展示） */
  @Builder
  buildItemMenu(): void {
    Menu() {
      // 移到顶部（同组内排序，不改变置顶状态）
      MenuItem({
        content: I18nHelper.t(I18nKeys.INBOX_MENU_MOVE_TO_TOP, this.lang),
      })
        .onClick(() => {
          InboxViewModel.moveToTop(this.entryId).then(() => {
            this.onDataChanged();
          });
        })

      // 置顶 / 取消置顶
      MenuItem({
        content: I18nHelper.t(
          this.entryIsPinned === 1 ? I18nKeys.INBOX_MENU_UNPIN : I18nKeys.INBOX_MENU_PIN,
          this.lang,
        ),
      })
        .onClick(() => {
          InboxViewModel.togglePin(this.entryId).then(() => {
            this.onDataChanged();
          });
        })

      // 编辑（跳转 InboxEditorPage）
      MenuItem({ content: I18nHelper.t(I18nKeys.INBOX_MENU_EDIT, this.lang) })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/InboxEditorPage',
            params: { entryId: this.entryId },
          });
        })

      // 删除
      MenuItem({ content: I18nHelper.t(I18nKeys.INBOX_MENU_DELETE, this.lang) })
        .onClick(() => {
          InboxViewModel.delete(this.entryId).then(() => {
            this.onDataChanged();
          });
        })
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // ── 横向扩散点击特效矩形（始终挂载，用 opacity/scale 控制可见性） ────
      Rect()
        .width('100%')
        .height($r('app.float.inbox_item_min_height'))
        .fill(this.themeTokens.colorTextPrimary)
        .opacity(this.spreadOpacity)
        .scale({ x: this.spreadScale, y: 1.0, centerX: this.spreadCenterX })
        .hitTestBehavior(HitTestMode.None)

      Row({ space: 10 }) { // 【修改点】略微拉开序号和标题的间距
        // ── 序号（1-based，固定宽，次要色，随拖拽排序自动更新） ────────────────
        Text(this.entryIndex.toString())
          .fontSize(16) // 【修改点1】将极小的 label 变量替换为确定的 16，放大字号
          .fontColor(this.themeTokens.colorTextSecondary)
          .width(26)    // 【修改点2】配合大字体，略微加宽防止两位数时被截断
          .textAlign(TextAlign.Start) // 【修改点3】由 End 改为 Start，让序号更贴近屏幕最左侧边缘
          .flexShrink(0)

        // ── 左侧主内容区（单击跳转编辑页） ────────────────────────────────────
        Row({ space: 6 }) {
          Text(this.entryText)
            .fontSize(16) // 【修改点4】同步将标题放大到 16，使得数字和标题协调
            .fontColor(this.themeTokens.colorTextPrimary)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // 第一个标签（若有），紧邻日期
          if (this.entryTags !== '') {
            Text('#' + parseTags(this.entryTags)[0])
              .fontSize($r('app.float.font_size_label'))
              .fontColor(this.themeTokens.colorAccent)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: 80 })
              .flexShrink(0)
          }

          Text(formatTimestamp(this.entryUpdatedAt, this.lang))
            .fontSize($r('app.float.font_size_label'))
            .fontColor(this.themeTokens.colorTextSecondary)
            .maxLines(1)
            .flexShrink(0)
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/InboxEditorPage',
            params: { entryId: this.entryId },
          });
        })

        // ── 三点菜单按钮（点击弹菜单，不干扰长按拖拽） ───────────────────────
        Image($r('sys.media.ohos_ic_public_more'))
          .width($r('app.float.icon_size_sm'))
          .height($r('app.float.icon_size_sm'))
          .fillColor(this.themeTokens.colorTextSecondary)
          .padding(4)
          .flexShrink(0)
          .bindMenu(this.buildItemMenu)
      }
      .width('100%')
      .constraintSize({ minHeight: $r('app.float.inbox_item_min_height') })
      // 【修改点5】重构 padding：废弃过大的左侧 spacing_lg 变量，直接使用紧凑的硬编码数值
      .padding({
        left: 12, // 强制变小，紧贴左边界
        right: 16,
        top: 14,
        bottom: 14,
      })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .clip(true)
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.triggerSpread(e.touches[0].x);
      }
    })
    .borderWidth({ left: 3 })
    .borderColor({
      left: this.entryIsPinned === 1 ? this.themeTokens.colorAccent : Color.Transparent,
    })
    .borderStyle({ left: BorderStyle.Solid })
  }
}