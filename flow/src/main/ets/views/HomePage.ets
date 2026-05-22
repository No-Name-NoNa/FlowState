/**
 * HomePage.ets
 * 收集箱首页视图。
 * 包含：Header（问候语 + 搜索 + 设置）、可动画展开的搜索栏、
 * 标签筛选 chips、InboxListView 列表主体、底部「+ 新建」按钮。
 */
import { router } from '@kit.ArkUI';
import { I18nHelper } from '../util/I18nHelper';
import { I18nKeys } from '../constants/I18nKeys';
import {
  DIVIDER_STROKE_WIDTH,
  KEY_APP_LANGUAGE,
  KEY_INBOX_NEEDS_REFRESH,
  KEY_FONT_TOKENS, KEY_THEME_TOKENS,
  LANG_ZH_CN,
} from '../constants/AppConstants';
import { DEFAULT_THEME_TOKENS, ThemeTokens } from '../constants/ThemeConstants';
import { DEFAULT_FONT_TOKENS, FontSizeTokens } from '../constants/FontSizeConstants';
import { InboxViewModel } from '../viewmodel/InboxViewModel';
import { InboxEntry } from '../model/InboxEntry';
import { InboxListView } from './InboxListView';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

/** 首页视图组件（收集箱主视图） */
@Component
export struct HomePage {
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  /** 跨页刷新信号：编辑/新建页保存后设为 true，此处检测到后重新加载列表 */
  @Watch('onInboxRefreshChanged')
  @StorageLink(KEY_INBOX_NEEDS_REFRESH) inboxNeedsRefresh: boolean = false;
  /** 当前要渲染的过滤后条目（ForEach 数据源，确保编辑后动态刷新） */
  @State entries: InboxEntry[] = [];
  /** 所有标签的聚合列表，用于标签筛选 chips */
  @State tagList: string[] = [];
  /** 当前搜索关键词 */
  @State searchKeyword: string = '';
  /** 当前激活的标签筛选，空字符串表示全部 */
  @State activeTag: string = '';
  /** 搜索栏是否展开 */
  @State showSearch: boolean = false;
  /** 搜索栏动画高度（0 = 收起，48 = 展开） */
  @State searchBarHeight: number = 0;
  /** 标签筛选区是否展开 */
  @State showTagFilter: boolean = false;
  /** 标签筛选区动画高度（0 = 收起，40 = 展开） */
  @State tagFilterHeight: number = 0;
  /** 列表是否为空，控制 InboxListView 的空状态提示 */
  @State inboxIsEmpty: boolean = true;
  // ── 「+ 新建」按钮扩散特效状态 ─────────────────────────────────────────
  @State newBtnPressedIndex: number = -1;
  @State newBtnSpreadScale: number = 0;
  @State newBtnSpreadOpacity: number = 0;
  @State newBtnCenterX: number = 0;

  aboutToAppear(): void {
    this.loadData();
  }

  /** 从 DB 加载数据，刷新所有列表状态 */
  private loadData(): void {
    InboxViewModel.load().then(() => {
      this.refreshEntries();
    });
  }

  /** 将 ViewModel 过滤结果同步到视图状态（必须在每次数据变化后调用） */
  private refreshEntries(): void {
    // .slice() 生成新数组引用，确保 ArkUI @State 检测到变化并触发 ForEach 重渲染
    this.entries = InboxViewModel.filteredEntries.slice();
    this.tagList = InboxViewModel.getAllTags();
    this.inboxIsEmpty = this.entries.length === 0;
  }

  /** 跨页刷新信号回调：InboxEditorPage 保存后触发 */
  private onInboxRefreshChanged(): void {
    if (this.inboxNeedsRefresh) {
      // 重置信号，避免重复触发
      AppStorage.set<boolean>(KEY_INBOX_NEEDS_REFRESH, false);
      // InboxViewModel.update/create 内部已完成 DB 读取并更新 filteredEntries，
      // 直接调用 refreshEntries() 同步读取即可，无需再次异步查询 DB。
      this.refreshEntries();
    }
  }

  /** 切换搜索栏展开/收起（附带 250ms EaseOut 高度动画） */
  private toggleSearch(): void {
    animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showSearch = !this.showSearch;
      this.searchBarHeight = this.showSearch ? 48 : 0;
      // 收起时同步清除搜索关键词并刷新列表
      if (!this.showSearch) {
        this.searchKeyword = '';
        InboxViewModel.filter('', this.activeTag);
        this.refreshEntries();
      }
    });
  }

  /** 切换标签筛选区展开/收起（附带 250ms EaseOut 高度动画） */
  private toggleTagFilter(): void {
    animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
      this.showTagFilter = !this.showTagFilter;
      this.tagFilterHeight = this.showTagFilter ? 40 : 0;
      // 收起时重置标签筛选
      if (!this.showTagFilter) {
        this.activeTag = '';
        InboxViewModel.filter(this.searchKeyword, '');
        this.refreshEntries();
      }
    });
  }

  /** 是否处于过滤状态（搜索或标签筛选激活） */
  private isFiltered(): boolean {
    return this.searchKeyword !== '' || this.activeTag !== '';
  }

  /** 触发「+ 新建」按钮横向扩散特效 */
  private triggerNewBtnSpread(touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx: number) => {
        this.newBtnPressedIndex = idx;
      },
      (scale: number, opacity: number) => {
        this.newBtnSpreadScale = scale;
        this.newBtnSpreadOpacity = opacity;
      },
      (x: number) => {
        this.newBtnCenterX = x;
      },
      0,
      touchX,
    );
  }

  build() {
    Column() {
      // ── 顶部 Header ──────────────────────────────────────────────────────
      Row() {
        // 问候语（左）
        Text(I18nHelper.t(I18nKeys.HOME_GREETING, this.currentLanguage))
          .fontSize(this.fontTokens.headerTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .layoutWeight(1)

        // 搜索图标（切换搜索栏展开/收起）
        Image($r('app.media.ic_search'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.showSearch ? this.themeTokens.colorAccent : this.themeTokens.colorTextSecondary)
          .margin({ right: $r('app.float.spacing_md') })
          .onClick(() => {
            this.toggleSearch();
          })

        // 标签筛选图标（切换标签筛选区展开/收起）
        Image($r('app.media.ic_filter'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(
            this.showTagFilter ? this.themeTokens.colorAccent : this.themeTokens.colorTextSecondary
          )
          .margin({ right: $r('app.float.spacing_md') })
          .onClick(() => {
            this.toggleTagFilter();
          })

        // 设置入口图标
        Image($r('app.media.ic_settings'))
          .width($r('app.float.icon_size_md'))
          .height($r('app.float.icon_size_md'))
          .fillColor(this.themeTokens.colorTextSecondary)
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingsPage' });
          })
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)

      // ── 搜索栏（动画展开/收起，高度 0→48） ──────────────────────────────
      Row() {
        TextInput({
          text: this.searchKeyword,
          placeholder: I18nHelper.t(I18nKeys.INBOX_SEARCH_PLACEHOLDER, this.currentLanguage),
        })
          .layoutWeight(1)
          .height(36)
          .fontSize(this.fontTokens.body)
          .fontColor(this.themeTokens.colorTextPrimary)
          .placeholderColor(this.themeTokens.colorTextSecondary)
          .caretColor(this.themeTokens.colorAccent)
          .backgroundColor(this.themeTokens.colorDivider)
          .borderRadius(8)
          .padding({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
          .onChange((val: string) => {
            this.searchKeyword = val;
            InboxViewModel.filter(val, this.activeTag);
            this.refreshEntries();
          })
      }
      .width('100%')
      .height(this.searchBarHeight)
      .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
      .alignItems(VerticalAlign.Center)
      .clip(true)

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 标签筛选区（点击 Filter 图标触发，高度动画展开/收起） ──────────────
      Row() {
        Scroll() {
          Row({ space: $r('app.float.spacing_xs') }) {
            // 「全部」chip
            Text(I18nHelper.t(I18nKeys.INBOX_TAG_ALL, this.currentLanguage))
              .fontSize(this.fontTokens.label)
              .fontColor(this.activeTag === '' ? this.themeTokens.colorBackground : this.themeTokens.colorTextSecondary)
              .height($r('app.float.tag_chip_height'))
              .padding({ left: $r('app.float.tag_chip_padding_h'), right: $r('app.float.tag_chip_padding_h') })
              .backgroundColor(this.activeTag === '' ? this.themeTokens.colorAccent : Color.Transparent)
              .border({
                width: 0.5,
                color: this.activeTag === '' ? this.themeTokens.colorAccent : this.themeTokens.colorDivider,
                radius: 11,
              })
              .onClick(() => {
                animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                  this.activeTag = '';
                });
                InboxViewModel.filter(this.searchKeyword, '');
                this.refreshEntries();
              })

            // 各标签 chip
            ForEach(this.tagList, (tag: string) => {
              Text('#' + tag)
                .fontSize(this.fontTokens.label)
                .fontColor(
                  this.activeTag === tag
                    ? this.themeTokens.colorBackground
                    : this.themeTokens.colorAccent
                )
                .height($r('app.float.tag_chip_height'))
                .padding({ left: $r('app.float.tag_chip_padding_h'), right: $r('app.float.tag_chip_padding_h') })
                .backgroundColor(
                  this.activeTag === tag ? this.themeTokens.colorAccent : Color.Transparent
                )
                .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 11 })
                .onClick(() => {
                  const newTag: string = this.activeTag === tag ? '' : tag;
                  animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                    this.activeTag = newTag;
                  });
                  InboxViewModel.filter(this.searchKeyword, newTag);
                  this.refreshEntries();
                })
            }, (tag: string) => tag)
          }
          .padding({ left: $r('app.float.spacing_lg'), right: $r('app.float.spacing_lg') })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None)
        .width('100%')
      }
      .width('100%')
      .height(this.tagFilterHeight)
      .clip(true)

      // 标签筛选区展开时显示底部分割线
      if (this.showTagFilter) {
        Divider()
          .strokeWidth(DIVIDER_STROKE_WIDTH)
          .color(this.themeTokens.colorDivider)
          .width('100%')
      }

      // ── 列表主体 ─────────────────────────────────────────────────────────
      InboxListView({
        entries: $entries,
        isFiltered: this.isFiltered(),
        showEmptyHint: this.inboxIsEmpty,
        onDataChanged: () => {
          this.loadData();
        },
      })

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 底部「+ 新建」文字按钮 ─────────────────────────────────────────────
      Stack({ alignContent: Alignment.Center }) {
        // 横向扩散特效矩形
        if (this.newBtnPressedIndex === 0) {
          Rect()
            .width('100%')
            .height($r('app.float.inbox_input_bar_height'))
            .fill(this.themeTokens.colorAccent)
            .opacity(this.newBtnSpreadOpacity)
            .scale({ x: this.newBtnSpreadScale, y: 1.0, centerX: this.newBtnCenterX })
            .hitTestBehavior(HitTestMode.None)
        }

        Text(I18nHelper.t(I18nKeys.INBOX_NEW_BUTTON, this.currentLanguage))
          .fontSize(this.fontTokens.body)
          .fontColor(this.themeTokens.colorAccent)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height($r('app.float.inbox_input_bar_height'))
      .onTouch((e: TouchEvent) => {
        if (e.type === TouchType.Down) {
          this.triggerNewBtnSpread(e.touches[0].x);
        }
      })
      .onClick(() => {
        router.pushUrl({ url: 'pages/InboxEditorPage' });
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }
}
