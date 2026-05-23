/**
 * InboxListView.ets
 * 收集箱条目列表组件。
 *
 * 关键设计：
 *  - ForEach 全量渲染（数据量小，性能可接受），保证编辑后数据动态刷新。
 *  - 拖拽使用 ArkUI 新版 `List.onMove((from, to))` API，自动启用长按拖拽，
 *    与旧版 `editMode + editable + onItemMove` 相比避免与 swipeAction 手势竞争。
 *  - 给 InboxItemComponent 传**基本类型** props（id/text/content/tags/isPinned/updatedAt），
 *    保证 ArkUI 强制下推刷新（避免 @Prop 对象类型在 key 稳定时的复用陷阱）。
 */
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
import { InboxViewModel } from '../viewmodel/InboxViewModel';
import { InboxEntry } from '../model/InboxEntry';
import { InboxItemComponent } from './InboxItemComponent';

/** 收集箱条目列表组件 */
@Component
export struct InboxListView {
  /** 当前要渲染的条目数组（@Link 直接绑定父组件 @State，保证动态刷新） */
  @Link entries: InboxEntry[];
  /** 是否处于过滤状态（搜索或标签筛选激活时为 true），过滤期间禁用拖拽排序 */
  @Prop isFiltered: boolean = false;
  /** 是否显示空状态提示（由父组件根据数据源长度决定） */
  @Prop showEmptyHint: boolean = false;
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  /** 数据变化回调：删除、置顶等操作完成后，通知父组件刷新 */
  onDataChanged: () => void = () => {
  };

  /** 左滑显示的红色删除按钮 */
  @Builder
  deleteButton(entryId: number): void {
    Row() {
      Image($r('sys.media.ohos_ic_public_cancel'))
        .width($r('app.float.icon_size_md'))
        .height($r('app.float.icon_size_md'))
        .fillColor(this.themeTokens.colorBackground)
    }
    .width(72)
    .height('100%')
    .backgroundColor(this.themeTokens.colorTextPrimary)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      AlertDialog.show({
        title: I18nHelper.t(I18nKeys.INBOX_MENU_DELETE, this.currentLanguage),
        message: I18nHelper.t(I18nKeys.DIALOG_DELETE_MSG, this.currentLanguage),
        primaryButton: {
          value: I18nHelper.t(I18nKeys.DIALOG_CONFIRM, this.currentLanguage),
          action: () => {
            InboxViewModel.delete(entryId).then(() => {
              this.onDataChanged();
            });
          },
        },
        secondaryButton: {
          value: I18nHelper.t(I18nKeys.DIALOG_CANCEL, this.currentLanguage),
          action: () => {
          },
        },
        autoCancel: true,
      });
    })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      List() {
        ForEach(this.entries, (entry: InboxEntry, index: number) => {
          ListItem() {
            // 将所有字段以基本类型 prop 传入，保证 ArkUI 强制下推刷新
            InboxItemComponent({
              entryId: entry.id,
              entryText: entry.text,
              entryContent: entry.content,
              entryTags: entry.tags,
              entryIsPinned: entry.isPinned,
              entryUpdatedAt: entry.updatedAt,
              entryIndex: index + 1,
              isEditMode: !this.isFiltered,
              onDataChanged: this.onDataChanged,
            })
          }
          // 左滑显示删除按钮
          .swipeAction({
            end: (): void => {
              this.deleteButton(entry.id);
            }
          })
        }, (entry: InboxEntry) => entry.id.toString() + '_' + entry.updatedAt.toString())
        // ForEach.onMove：List 完成视觉移位后触发，同步更新 @Link entries（直接推入父 @State），
        // 再 fire-and-forget 写 DB，彻底避免异步 DB reload 与视觉位置竞态导致的列表抖动。
          .onMove((from: number, to: number) => {
            if (this.isFiltered) {
              return;
            }
            // 同步重建数组（新引用），ArkUI ForEach 立即感知顺序变化
            const newEntries: InboxEntry[] = this.entries.slice();
            const moved: InboxEntry[] = newEntries.splice(from, 1);
            newEntries.splice(to, 0, moved[0]);
            this.entries = newEntries; // @Link → 直接更新父组件 @State
            InboxViewModel.syncReorder(newEntries); // 异步写 DB，不阻塞 UI
          })
      }
      .width('100%')
      .height('100%')
      .divider({ strokeWidth: DIVIDER_STROKE_WIDTH, color: this.themeTokens.colorDivider })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 空状态提示（覆盖在空列表上方，不影响触摸）
      if (this.showEmptyHint) {
        Column() {
          Text(I18nHelper.t(I18nKeys.INBOX_EMPTY_HINT, this.currentLanguage))
            .fontSize(this.fontTokens.caption)
            .fontColor(this.themeTokens.colorTextSecondary)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.None)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }
}
