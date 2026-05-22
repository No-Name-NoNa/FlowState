/**
 * InboxEditorPage.ets
 * 收集箱条目创建/编辑独立页。
 * 通过 router params 传入 entryId > 0 进入编辑模式，无参数或 entryId == 0 则为新建模式。
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
import { InboxDatabase } from '../util/InboxDatabase';
import { InboxViewModel } from '../viewmodel/InboxViewModel';
import { formatTimestamp, InboxEntry, parseTags, serializeTags } from '../model/InboxEntry';
import { SpreadEffectHelper } from '../util/SpreadEffectHelper';

/** router.getParams() 的参数结构 */
interface EditorRouterParams {
  entryId: number;
}

@Entry
@Component
struct InboxEditorPage {
  @StorageLink(KEY_APP_LANGUAGE) currentLanguage: string = LANG_ZH_CN;
  @StorageLink(KEY_THEME_TOKENS) themeTokens: ThemeTokens = DEFAULT_THEME_TOKENS;
  @StorageLink(KEY_FONT_TOKENS) fontTokens: FontSizeTokens = DEFAULT_FONT_TOKENS;
  /** 编辑模式目标条目 ID，0 表示新建 */
  @State entryId: number = 0;
  /** 是否处于编辑模式 */
  @State isEditMode: boolean = false;
  /** 标题（单行） */
  @State text: string = '';
  /** 正文详情（多行，可选） */
  @State content: string = '';
  /** 当前标签数组 */
  @State tags: string[] = [];
  /** 标签输入框的当前文本 */
  @State tagInput: string = '';
  /** 系统中现有的标签（从 ViewModel 加载，供快速勾选） */
  @State existingTags: string[] = [];
  /** 原始条目（编辑模式用，持有 sortOrder/isPinned/createdAt 等不可编辑字段） */
  @State originalEntry: InboxEntry = {
    id: 0,
    text: '',
    content: '',
    tags: '',
    sortOrder: 0,
    isPinned: 0,
    createdAt: 0,
    updatedAt: 0,
  };
  // ── 保存按钮扩散特效状态 ─────────────────────────────────────────────────
  @State savePressedIndex: number = -1;
  @State saveSpreadScale: number = 0;
  @State saveSpreadOpacity: number = 0;
  @State saveCenterX: number = 0;
  // ── 返回按钮扩散特效状态 ─────────────────────────────────────────────────
  @State backPressedIndex: number = -1;
  @State backSpreadScale: number = 0;
  @State backSpreadOpacity: number = 0;
  @State backCenterX: number = 0;

  aboutToAppear(): void {
    // 加载所有已有标签，用于快速勾选
    this.existingTags = InboxViewModel.getAllTags();

    const params = router.getParams();
    if (params !== null && params !== undefined) {
      const p: EditorRouterParams = params as EditorRouterParams;
      if (p.entryId !== undefined && p.entryId > 0) {
        this.entryId = p.entryId;
        this.isEditMode = true;
        // 异步加载条目数据填充表单
        InboxDatabase.getById(this.entryId).then((entry: InboxEntry | null) => {
          if (entry !== null) {
            this.originalEntry = entry;
            this.text = entry.text;
            this.content = entry.content;
            this.tags = parseTags(entry.tags);
          }
        });
      }
    }
  }

  /** 触发保存按钮横向扩散特效 */
  private triggerSaveSpread(touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx: number) => {
        this.savePressedIndex = idx;
      },
      (scale: number, opacity: number) => {
        this.saveSpreadScale = scale;
        this.saveSpreadOpacity = opacity;
      },
      (x: number) => {
        this.saveCenterX = x;
      },
      0,
      touchX,
    );
  }

  /** 触发返回按钮横向扩散特效 */
  private triggerBackSpread(touchX: number): void {
    SpreadEffectHelper.trigger(
      (idx: number) => {
        this.backPressedIndex = idx;
      },
      (scale: number, opacity: number) => {
        this.backSpreadScale = scale;
        this.backSpreadOpacity = opacity;
      },
      (x: number) => {
        this.backCenterX = x;
      },
      0,
      touchX,
    );
  }

  /**
   * 确认添加标签输入框中的内容为新标签。
   * 自动 trim，忽略空内容及重复标签。
   */
  private addTag(): void {
    // 移除中英文逗号、首尾空格
    const trimmed: string = this.tagInput.trim().replace(/，/g, '').replace(/,/g, '');
    if (trimmed === '' || this.tags.indexOf(trimmed) >= 0) {
      this.tagInput = '';
      return;
    }
    const newTags: string[] = [];
    for (const t of this.tags) {
      newTags.push(t);
    }
    newTags.push(trimmed);
    this.tags = newTags;
    this.tagInput = '';
  }

  /** 移除指定索引的标签 */
  private removeTag(index: number): void {
    const newTags: string[] = [];
    for (let i: number = 0; i < this.tags.length; i++) {
      if (i !== index) {
        newTags.push(this.tags[i]);
      }
    }
    this.tags = newTags;
  }

  /** 验证并保存，成功后发送跨页刷新信号并返回上一页 */
  private async doSave(): Promise<void> {
    const trimmedText: string = this.text.trim();
    if (trimmedText === '') {
      return;
    }
    if (this.isEditMode) {
      const updated: InboxEntry = {
        id: this.originalEntry.id,
        text: trimmedText,
        content: this.content.trim(),
        tags: serializeTags(this.tags),
        sortOrder: this.originalEntry.sortOrder,
        isPinned: this.originalEntry.isPinned,
        createdAt: this.originalEntry.createdAt,
        updatedAt: this.originalEntry.updatedAt,
      };
      await InboxViewModel.update(updated);
    } else {
      await InboxViewModel.create(trimmedText, this.content.trim(), this.tags);
    }
    // 通知首页刷新列表
    AppStorage.set<boolean>(KEY_INBOX_NEEDS_REFRESH, true);
    router.back();
  }

  /** 单个已添加标签的 chip（含移除按钮） */
  @Builder
  tagChip(tag: string, index: number): void {
    Row({ space: 2 }) {
      Text('#' + tag)
        .fontSize(this.fontTokens.label)
        .fontColor(this.themeTokens.colorAccent)

      Image($r('sys.media.ohos_ic_public_cancel'))
        .width(14)
        .height(14)
        .fillColor(this.themeTokens.colorTextSecondary)
        .onClick(() => {
          this.removeTag(index);
        })
    }
    .height($r('app.float.tag_chip_height'))
    .padding({ left: $r('app.float.tag_chip_padding_h'), right: $r('app.float.tag_chip_padding_h') })
    .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 11 })
    .margin({ right: $r('app.float.spacing_xs'), bottom: $r('app.float.spacing_xs') })
  }

  build() {
    Column() {
      // ── 顶部导航栏 ───────────────────────────────────────────────────────
      Row() {
        // 返回按钮（带扩散特效）
        Stack({ alignContent: Alignment.Center }) {
          if (this.backPressedIndex === 0) {
            Rect()
              .width(40)
              .height(40)
              .fill(this.themeTokens.colorTextPrimary)
              .opacity(this.backSpreadOpacity)
              .scale({ x: this.backSpreadScale, y: 1.0, centerX: this.backCenterX })
              .hitTestBehavior(HitTestMode.None)
              .borderRadius(20)
          }
          Image($r('sys.media.ohos_ic_back'))
            .width($r('app.float.icon_size_md'))
            .height($r('app.float.icon_size_md'))
            .fillColor(this.themeTokens.colorTextPrimary)
        }
        .width(40)
        .height(40)
        .onTouch((e: TouchEvent) => {
          if (e.type === TouchType.Down) {
            this.triggerBackSpread(e.touches[0].x);
          }
        })
        .onClick(() => {
          router.back();
        })

        // 标题输入框（恢复到顶部导航栏中）
        TextInput({
          text: this.text,
          placeholder: I18nHelper.t(I18nKeys.INBOX_EDITOR_TITLE_PLACEHOLDER, this.currentLanguage),
        })
          .layoutWeight(1)
          .height(40)
          .fontSize(this.fontTokens.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeTokens.colorTextPrimary)
          .placeholderColor(this.themeTokens.colorTextSecondary)
          .caretColor(this.themeTokens.colorAccent)
          .backgroundColor(Color.Transparent)
          .padding({ left: $r('app.float.spacing_sm'), right: $r('app.float.spacing_sm') })
          .borderRadius(0)
          .onChange((val: string) => {
            this.text = val;
          })

        // 保存按钮（文字，带扩散特效）
        Stack({ alignContent: Alignment.Center }) {
          if (this.savePressedIndex === 0) {
            Rect()
              .width(56)
              .height(36)
              .fill(this.themeTokens.colorAccent)
              .opacity(this.saveSpreadOpacity)
              .scale({ x: this.saveSpreadScale, y: 1.0, centerX: this.saveCenterX })
              .hitTestBehavior(HitTestMode.None)
              .borderRadius(4)
          }
          Text(I18nHelper.t(I18nKeys.INBOX_EDITOR_SAVE, this.currentLanguage))
            .fontSize(this.fontTokens.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(
              this.text.trim() !== ''
                ? this.themeTokens.colorAccent
                : this.themeTokens.colorTextSecondary
            )
        }
        .width(56)
        .height(36)
        .onTouch((e: TouchEvent) => {
          if (e.type === TouchType.Down) {
            this.triggerSaveSpread(e.touches[0].x);
          }
        })
        .onClick(() => {
          this.doSave();
        })
      }
      .width('100%')
      .height($r('app.float.header_height'))
      .padding({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
      .alignItems(VerticalAlign.Center)

      Divider()
        .strokeWidth(DIVIDER_STROKE_WIDTH)
        .color(this.themeTokens.colorDivider)
        .width('100%')

      // ── 可滚动内容区 ─────────────────────────────────────────────────────
      Scroll() {
        Column() {
          // 正文多行输入区
          TextArea({
            text: this.content,
            placeholder: I18nHelper.t(I18nKeys.INBOX_EDITOR_CONTENT_PLACEHOLDER, this.currentLanguage),
          })
            .width('100%')
            .constraintSize({ minHeight: 120 })
            .fontSize(this.fontTokens.body)
            .fontColor(this.themeTokens.colorTextPrimary)
            .placeholderColor(this.themeTokens.colorTextSecondary)
            .caretColor(this.themeTokens.colorAccent)
            .backgroundColor(Color.Transparent)
            // 【关键修复】大幅减小了 top padding，让文字紧贴上方的 Divider；同时添加了左对齐和顶部对齐规则。
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_sm'), // 这里原来使用了 lg，导致了巨大的顶部空白
              bottom: $r('app.float.spacing_lg')
            })
            .textAlign(TextAlign.Start)
            .align(Alignment.TopStart)
            .borderRadius(0)
            .onChange((val: string) => {
              this.content = val;
            })

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .width('100%')

          // ── 标签区：已有标签快速勾选 + 已选 chip + 输入框 ─────────────────
          Column({ space: 0 }) {
            // 快速勾选已有标签（有已有标签时展示）
            if (this.existingTags.length > 0) {
              Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
                ForEach(this.existingTags, (tag: string) => {
                  Text('#' + tag)
                    .fontSize(this.fontTokens.label)
                    .fontColor(
                      this.tags.indexOf(tag) >= 0
                        ? this.themeTokens.colorBackground
                        : this.themeTokens.colorAccent
                    )
                    .height($r('app.float.tag_chip_height'))
                    .padding({ left: $r('app.float.tag_chip_padding_h'), right: $r('app.float.tag_chip_padding_h') })
                    .backgroundColor(
                      this.tags.indexOf(tag) >= 0 ? this.themeTokens.colorAccent : Color.Transparent
                    )
                    .border({ width: 0.5, color: this.themeTokens.colorAccent, radius: 11 })
                    .margin({ right: $r('app.float.spacing_xs'), bottom: $r('app.float.spacing_xs') })
                    .onClick(() => {
                      const idx: number = this.tags.indexOf(tag);
                      const newTags: string[] = [];
                      for (const t of this.tags) {
                        newTags.push(t);
                      }
                      if (idx >= 0) {
                        newTags.splice(idx, 1);
                      } else {
                        newTags.push(tag);
                      }
                      this.tags = newTags;
                    })
                }, (tag: string) => tag)
              }
              .width('100%')
              .padding({
                left: $r('app.float.spacing_lg'),
                right: $r('app.float.spacing_lg'),
                top: $r('app.float.spacing_sm'),
                bottom: $r('app.float.spacing_xs'),
              })

              Divider()
                .strokeWidth(DIVIDER_STROKE_WIDTH)
                .color(this.themeTokens.colorDivider)
                .width('100%')
            }

            // 已添加标签 chip + 内联输入框
            Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
              ForEach(this.tags, (tag: string, index: number) => {
                this.tagChip(tag, index);
              }, (tag: string) => tag)

              // 内联标签输入框（跟在已有 chip 之后）
              TextInput({
                text: this.tagInput,
                placeholder: I18nHelper.t(I18nKeys.INBOX_TAG_PLACEHOLDER, this.currentLanguage),
              })
                .height($r('app.float.tag_chip_height'))
                .constraintSize({ minWidth: 80 })
                .layoutWeight(1)
                .fontSize(this.fontTokens.label)
                .fontColor(this.themeTokens.colorTextPrimary)
                .placeholderColor(this.themeTokens.colorTextSecondary)
                .caretColor(this.themeTokens.colorAccent)
                .backgroundColor(Color.Transparent)
                .padding({
                  left: $r('app.float.spacing_xs'),
                  right: 0,
                  top: 0,
                  bottom: 0
                })
                .borderRadius(0)
                .onChange((val: string) => {
                  // 检测到中英文逗号时触发添加
                  if (val.endsWith(',') || val.endsWith('，')) {
                    this.tagInput = val.substring(0, val.length - 1);
                    this.addTag();
                  } else {
                    this.tagInput = val;
                  }
                })
                .onSubmit((enterKey: EnterKeyType) => {
                  this.addTag();
                })
            }
            .width('100%')
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
          }
          .width('100%')

          Divider()
            .strokeWidth(DIVIDER_STROKE_WIDTH)
            .color(this.themeTokens.colorDivider)
            .width('100%')

          // 时间戳区域（仅编辑模式且已加载到条目时显示）
          if (this.isEditMode && this.originalEntry.createdAt > 0) {
            Column({ space: 6 }) {
              Row({ space: 6 }) {
                Text(I18nHelper.t(I18nKeys.INBOX_CREATED_AT, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
                Text(formatTimestamp(this.originalEntry.createdAt, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
              }

              Row({ space: 6 }) {
                Text(I18nHelper.t(I18nKeys.INBOX_UPDATED_AT, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
                Text(formatTimestamp(this.originalEntry.updatedAt, this.currentLanguage))
                  .fontSize(this.fontTokens.label)
                  .fontColor(this.themeTokens.colorTextSecondary)
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding({
              left: $r('app.float.spacing_lg'),
              right: $r('app.float.spacing_lg'),
              top: $r('app.float.spacing_md'),
              bottom: $r('app.float.spacing_md'),
            })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start) // 【关键修复】确保 Column 内部的内容直接从顶端开始排列
      }
      .layoutWeight(1)
      .align(Alignment.TopStart) // 【关键修复】确保 Scroll 的子容器始终置于顶部，避免被系统默认居中
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeTokens.colorBackground)
  }
}