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
 *  - 布局与任务列表条目保持一致：双行（标题行 + 元信息行）。
 *
 * 功能：
 *  - 标题行：标题（省略）→「置顶」chip（仅置顶时，accent 色圆角边框）
 *  - 元信息行：最多 2 个标签（左侧）+ 修改时间戳（右侧）
 *  - 左侧 3vp 竖条边框：置顶时 accent 色，未置顶透明（无优先级冲突）
 *  - 右侧三点按钮（bindMenu，不占用长按手势）
 *  - 单击主内容区跳转编辑页
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import { KEY_APP_LANGUAGE, KEY_FONT_TOKENS, KEY_THEME_TOKENS, LANG_ZH_CN } from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
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
  @StorageLink(KEY_APP_LANGUAGE) private lang: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) private themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) private fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  // ── 条目点击横向扩散特效状态（独立于其他条目，彻底消除整列重绘） ──────────
  @State private spreadScale: number = 0;
  @State private spreadOpacity: number = 0;
  @State private spreadCenterX: number = 0;
  /** 数据变化回调：增删改置顶后通知父组件刷新 */
  onDataChanged: () => void = () => {
  };

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
          AlertDialog.show({
            title: I18nHelper.t(I18nKeys.INBOX_MENU_DELETE, this.lang),
            message: I18nHelper.t(I18nKeys.DIALOG_DELETE_MSG, this.lang),
            primaryButton: {
              value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.lang),
              action: () => {
                InboxViewModel.delete(this.entryId).then(() => {
                  this.onDataChanged();
                });
              },
            },
            secondaryButton: {
              value: I18nHelper.t(I18nKeys.DIALOG_CANCEL, this.lang),
              action: () => {
              },
            },
            autoCancel: true,
          });
        })

      // 添加到任务（跳转任务编辑页，预填数据；保存后由编辑页负责删除本条目）
      MenuItem({ content: I18nHelper.t(I18nKeys.INBOX_MENU_ADD_TO_TASK, this.lang) })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/TaskEditorPage',
            params: { taskId: 0, fromInboxId: this.entryId },
          });
        })
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // ── 横向扩散点击特效矩形（始终挂载，用 opacity/scale 控制可见性） ────
      Rect()
        .width('100%')
        .height(this.fontTokens.inboxItemMinHeight)
        .fill(this.themeTokens.colorTextPrimary)
        .opacity(this.spreadOpacity)
        .scale({ x: this.spreadScale, y: 1.0, centerX: this.spreadCenterX })
        .hitTestBehavior(HitTestMode.None)

      Row({ space: 10 }) {
        // ── 序号（1-based，固定宽，次要色） ────────────────────────────────
        Text(this.entryIndex.toString())
          .fontSize(this.fontTokens.body)
          .fontColor(this.themeTokens.colorTextSecondary)
          .width(26)
          .textAlign(TextAlign.Start)
          .flexShrink(0)

        // ── 主内容区（双行：标题行 + 元信息行，单击跳转编辑页） ──────────────
        Column({ space: 4 }) {
          // 标题行：标题文本 + 置顶 chip（仅置顶时显示）
          Row({ space: 6 }) {
            Text(this.entryText)
              .fontSize(this.fontTokens.body)
              .fontColor(this.themeTokens.colorTextPrimary)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            // 置顶标识 chip（与任务列表保持一致）
            if (this.entryIsPinned === 1) {
              Text(I18nHelper.t(I18nKeys.INBOX_MENU_PIN, this.lang))
                .fontSize(this.fontTokens.label)
                .fontColor(this.themeTokens.colorAccent)
                .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 4 })
                .padding({
                  left: 4,
                  right: 4,
                  top: 1,
                  bottom: 1
                })
                .flexShrink(0)
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 元信息行：标签（左，弹性宽，碰撞时省略号截断）+ 修改时间戳（右，固定宽）
          Row({ space: 6 }) {
            // 标签文字：最多 2 个，撑满剩余空间；与右侧碰撞时从左侧截断并显示省略号
            Text(this.buildTagsText())
              .fontSize(this.fontTokens.label)
              .fontColor(this.themeTokens.colorAccent)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            Text(formatTimestamp(this.entryUpdatedAt, this.lang))
              .fontSize(this.fontTokens.label)
              .fontColor(this.themeTokens.colorTextSecondary)
              .maxLines(1)
              .flexShrink(0)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
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
      .constraintSize({ minHeight: this.fontTokens.inboxItemMinHeight })
      .padding({
        left: 12,
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
    // 左侧 3vp 竖条：置顶时 accent 色，未置顶时透明（无优先级概念，竖条仅用于置顶提示）
    .borderWidth({ left: 3 })
    .borderColor({
      left: this.entryIsPinned === 1 ? this.themeTokens.colorAccent : Color.Transparent,
    })
    .borderStyle({ left: BorderStyle.Solid })
  }

  /**
   * 将标签列表格式化为可显示的字符串。
   * 根据右侧时间戳的宽度估算标签区可用字符单元数，贪心地尽可能多显示标签；
   * 若不能全部显示，末尾追加 " …" 提示还有更多标签。
   * 每个标签名超过 8 字符时截断并加 "…"。
   */
  private buildTagsText(): string {
    if (this.entryTags === '') {
      return '';
    }
    const allTags: string[] = parseTags(this.entryTags);
    const MAX_TAG_CHARS: number = 8;

    // 估算右侧时间戳占用宽度单元（CJK 字符算 2 单元，其余算 1）
    const rightText: string = formatTimestamp(this.entryUpdatedAt, this.lang);
    let rightUnits: number = 0;
    for (let c: number = 0; c < rightText.length; c++) {
      rightUnits += rightText.charCodeAt(c) > 255 ? 2 : 1;
    }
    // 内容列总单元约 38（对应 ~285vp 宽度、label 字体），减去右侧和间距
    const tagsUnits: number = Math.max(8, 38 - rightUnits - 1);

    const pieces: string[] = [];
    let usedUnits: number = 0;
    let truncated: boolean = false;

    for (let i: number = 0; i < allTags.length; i++) {
      const rawTag: string = allTags[i];
      const tagName: string = rawTag.length > MAX_TAG_CHARS
        ? rawTag.slice(0, MAX_TAG_CHARS) + '…'
        : rawTag;
      const piece: string = '#' + tagName;
      const sepUnits: number = pieces.length > 0 ? 1 : 0;

      let pieceUnits: number = 0;
      for (let c: number = 0; c < piece.length; c++) {
        pieceUnits += piece.charCodeAt(c) > 255 ? 2 : 1;
      }
      // 非最后一个标签时，预留 2 个单元给末尾的 " …" 指示符
      const isLastTag: boolean = i === allTags.length - 1;
      const reserve: number = isLastTag ? 0 : 2;

      if (usedUnits + sepUnits + pieceUnits > tagsUnits - reserve) {
        truncated = true;
        break;
      }
      usedUnits += sepUnits + pieceUnits;
      pieces.push(piece);
    }

    let result: string = pieces.join(' ');
    if (truncated) {
      result += pieces.length > 0 ? ' …' : '…';
    }
    return result;
  }

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
}