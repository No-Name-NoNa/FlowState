/**
 * InboxViewModel.ets
 * 收集箱业务逻辑层。
 * InboxDataSource 实现 IDataSource，供 LazyForEach 使用；
 * InboxViewModel 静态类封装 CRUD、搜索过滤、标签聚合、置顶、拖拽排序逻辑。
 */
import { InboxDatabase } from '../util/InboxDatabase';
import { InboxEntry, parseTags, serializeTags } from '../model/InboxEntry';

/**
 * 收集箱数据源，实现 IDataSource 供 List.LazyForEach 使用。
 * 所有数据变更通过 replaceAll() 驱动，触发 onDataReloaded 整体重载通知。
 */
export class InboxDataSource implements IDataSource {
  private data: InboxEntry[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.data.length;
  }

  getData(index: number): InboxEntry {
    return this.data[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx: number = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }

  /** 替换全量数据并通知 List 整体重载 */
  replaceAll(entries: InboxEntry[]): void {
    this.data = entries;
    for (const listener of this.listeners) {
      listener.onDataReloaded();
    }
  }

  /**
   * 内存中执行拖拽移位，不触发通知（List.onMove 已处理视觉更新）。
   * @param from 原始索引
   * @param to   目标索引
   */
  moveEntry(from: number, to: number): void {
    const moved: InboxEntry[] = this.data.splice(from, 1);
    this.data.splice(to, 0, moved[0]);
  }

  /** 返回当前数据数组的浅拷贝，供批量写 DB 使用 */
  snapshot(): InboxEntry[] {
    return this.data.slice();
  }
}

/** 收集箱 ViewModel，所有方法为静态，供 View 层直接调用 */
export class InboxViewModel {
  /** 全量数据缓存（未过滤，DB 排序：置顶 DESC、sortOrder ASC） */
  private static allEntries: InboxEntry[] = [];
  /**
   * 过滤后的条目数组（供 ForEach 直接驱动渲染）。
   * 比 dataSource 更适合用于 @State 驱动的 ForEach，可确保编辑后文本实时刷新。
   */
  static filteredEntries: InboxEntry[] = [];
  /** LazyForEach 数据源（保留兼容，applyFilter 同步更新） */
  static readonly dataSource: InboxDataSource = new InboxDataSource();
  /** 当前搜索关键词（小写） */
  private static currentKeyword: string = '';
  /** 当前激活的标签筛选，空字符串表示全部 */
  private static currentTag: string = '';

  /**
   * 从数据库加载全量数据并应用当前过滤条件，刷新 dataSource。
   * 任何 CRUD 操作完成后调用。
   */
  static async load(): Promise<void> {
    InboxViewModel.allEntries = await InboxDatabase.queryAll();
    InboxViewModel.applyFilter();
  }

  /**
   * 更新搜索/标签过滤条件并立即刷新 dataSource。
   * @param keyword   搜索关键词（空字符串 = 不过滤）
   * @param activeTag 激活的标签筛选（空字符串 = 全部）
   */
  static filter(keyword: string, activeTag: string): void {
    InboxViewModel.currentKeyword = keyword;
    InboxViewModel.currentTag = activeTag;
    InboxViewModel.applyFilter();
  }

  /** 应用当前过滤条件，将结果写入 dataSource */
  private static applyFilter(): void {
    let filtered: InboxEntry[] = InboxViewModel.allEntries;
    const kw: string = InboxViewModel.currentKeyword.trim().toLowerCase();

    // 关键词过滤：匹配标题、正文或标签字段
    if (kw !== '') {
      const kwResult: InboxEntry[] = [];
      for (const e of filtered) {
        if (
          e.text.toLowerCase().indexOf(kw) >= 0 ||
            e.content.toLowerCase().indexOf(kw) >= 0 ||
            e.tags.toLowerCase().indexOf(kw) >= 0
        ) {
          kwResult.push(e);
        }
      }
      filtered = kwResult;
    }

    // 标签过滤：条目标签数组中包含目标标签
    if (InboxViewModel.currentTag !== '') {
      const tag: string = InboxViewModel.currentTag;
      const tagResult: InboxEntry[] = [];
      for (const e of filtered) {
        if (parseTags(e.tags).indexOf(tag) >= 0) {
          tagResult.push(e);
        }
      }
      filtered = tagResult;
    }

    InboxViewModel.filteredEntries = filtered;
    InboxViewModel.dataSource.replaceAll(filtered);
  }

  /**
   * 聚合全量数据中的所有标签（去重）。
   * 使用数组去重（ArkTS 不支持 Set<T>）。
   * @returns 标签字符串数组
   */
  static getAllTags(): string[] {
    const result: string[] = [];
    for (const entry of InboxViewModel.allEntries) {
      const tags: string[] = parseTags(entry.tags);
      for (const tag of tags) {
        if (result.indexOf(tag) < 0) {
          result.push(tag);
        }
      }
    }
    return result;
  }

  /**
   * 新建条目，插入到非置顶区域的顶部（sortOrder = 现有最小值 - 1）。
   * @param text    标题（已 trim）
   * @param content 正文详情（可为空字符串）
   * @param tags    标签数组
   */
  static async create(text: string, content: string, tags: string[]): Promise<void> {
    // 计算 sortOrder：比当前所有普通条目的最小值再小 1，使新条目排在最前
    let minOrder: number = 0;
    for (const e of InboxViewModel.allEntries) {
      if (e.isPinned === 0 && e.sortOrder < minOrder) {
        minOrder = e.sortOrder;
      }
    }
    const now: number = Date.now();
    const newEntry: InboxEntry = {
      id: 0,
      text: text,
      content: content,
      tags: serializeTags(tags),
      sortOrder: minOrder - 1,
      isPinned: 0,
      createdAt: now,
      updatedAt: now,
    };
    await InboxDatabase.insert(newEntry);
    await InboxViewModel.load();
  }

  /**
   * 更新现有条目的文字、正文和标签，自动刷新 updatedAt。
   * @param entry 含有效 id 的完整条目（updatedAt 由此方法重新设置）
   */
  static async update(entry: InboxEntry): Promise<void> {
    const updated: InboxEntry = {
      id: entry.id,
      text: entry.text,
      content: entry.content,
      tags: entry.tags,
      sortOrder: entry.sortOrder,
      isPinned: entry.isPinned,
      createdAt: entry.createdAt,
      updatedAt: Date.now(),
    };
    await InboxDatabase.update(updated);
    await InboxViewModel.load();
  }

  /**
   * 删除指定条目。
   * @param id 条目主键
   */
  static async delete(id: number): Promise<void> {
    await InboxDatabase.delete(id);
    await InboxViewModel.load();
  }

  /**
   * 切换指定条目的置顶状态。
   * 置顶时 sortOrder 设为置顶区最小值 - 1，使其出现在置顶区顶部。
   * @param id 条目主键
   */
  static async togglePin(id: number): Promise<void> {
    const idx: number = InboxViewModel.allEntries.findIndex((e: InboxEntry) => e.id === id);
    if (idx < 0) {
      return;
    }
    const entry: InboxEntry = InboxViewModel.allEntries[idx];
    const newPinned: number = entry.isPinned === 1 ? 0 : 1;

    // 置顶时计算新的 sortOrder：比现有置顶区最小值再小 1
    let targetSortOrder: number = entry.sortOrder;
    if (newPinned === 1) {
      let pinnedMin: number = 0;
      for (const e of InboxViewModel.allEntries) {
        if (e.isPinned === 1 && e.sortOrder < pinnedMin) {
          pinnedMin = e.sortOrder;
        }
      }
      targetSortOrder = pinnedMin - 1;
    }

    const updated: InboxEntry = {
      id: entry.id,
      text: entry.text,
      content: entry.content,
      tags: entry.tags,
      sortOrder: targetSortOrder,
      isPinned: newPinned,
      createdAt: entry.createdAt,
      // 更新 updatedAt，使 ForEach key（id + '_' + updatedAt）改变，
      // 强制 ArkUI 销毁并重建 InboxItemComponent，确保 @Prop entryIsPinned 立即刷新
      updatedAt: Date.now(),
    };
    await InboxDatabase.update(updated);
    await InboxViewModel.load();
  }

  /**
   * 处理拖拽排序：先同步更新内存数据源，再异步批量写 DB。
   * List.onMove 在调用前已完成视觉位移，故此方法不触发 notifyDataReloaded。
   * @param from 拖拽起始索引（dataSource 中的位置）
   * @param to   拖拽目标索引（dataSource 中的位置）
   */
  static async onMove(from: number, to: number): Promise<void> {
    // 同步更新内存数据源（无通知，List 已自行处理视觉）
    InboxViewModel.dataSource.moveEntry(from, to);
    // 取移位后的快照，重新计算全局 sortOrder 并写 DB
    const snapshot: InboxEntry[] = InboxViewModel.dataSource.snapshot();
    await InboxDatabase.updateOrder(snapshot);
    // 同步 allEntries，保持内存与 DB 一致
    for (let i: number = 0; i < snapshot.length; i++) {
      snapshot[i] = {
        id: snapshot[i].id,
        text: snapshot[i].text,
        content: snapshot[i].content,
        tags: snapshot[i].tags,
        sortOrder: i,
        isPinned: snapshot[i].isPinned,
        createdAt: snapshot[i].createdAt,
        updatedAt: snapshot[i].updatedAt,
      };
    }
    InboxViewModel.allEntries = snapshot;
  }

  /**
   * 内存同步重排（供 List.onMove 回调使用，无 DB 竞态风险）。
   * 同步更新 allEntries 与 filteredEntries，异步写 DB（fire-and-forget）。
   * 调用方（InboxListView.onMove）已通过 @Link 直接更新视图层 @State，
   * 此方法仅保证 ViewModel 缓存与 DB 最终一致，不触发任何 UI 通知。
   * @param reordered 完成视觉移位后的最新条目快照（@Link 赋值后的浅拷贝）
   */
  static syncReorder(reordered: InboxEntry[]): void {
    InboxViewModel.allEntries = reordered.slice();
    InboxViewModel.filteredEntries = reordered.slice();
    // fire-and-forget：不 await，避免 onMove 回调阻塞 UI 线程
    InboxDatabase.updateOrder(reordered).then(() => {
    }).catch(() => {
    });
  }

  /**
   * 将指定条目在同组（置顶区 or 普通区）内移动到最前。
   * 不改变 isPinned，仅调整 sortOrder = 组内最小值 - 1。
   * @param id 条目主键
   */
  static async moveToTop(id: number): Promise<void> {
    const idx: number = InboxViewModel.allEntries.findIndex((e: InboxEntry) => e.id === id);
    if (idx < 0) {
      return;
    }
    const entry: InboxEntry = InboxViewModel.allEntries[idx];
    // 找到同组（相同 isPinned）中的最小 sortOrder
    let groupMin: number = entry.sortOrder;
    for (const e of InboxViewModel.allEntries) {
      if (e.isPinned === entry.isPinned && e.sortOrder < groupMin) {
        groupMin = e.sortOrder;
      }
    }
    const updated: InboxEntry = {
      id: entry.id,
      text: entry.text,
      content: entry.content,
      tags: entry.tags,
      sortOrder: groupMin - 1,
      isPinned: entry.isPinned,
      createdAt: entry.createdAt,
      // 更新 updatedAt，确保 ForEach key 改变，触发组件重建以刷新序号显示
      updatedAt: Date.now(),
    };
    await InboxDatabase.update(updated);
    await InboxViewModel.load();
  }
}