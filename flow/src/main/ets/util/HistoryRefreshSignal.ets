import { KEY_HISTORY_NEEDS_REFRESH } from '../constants/AppConstants';

export class HistoryRefreshSignal {
  static bump(): void {
    const current: Object | undefined = AppStorage.get(KEY_HISTORY_NEEDS_REFRESH);
    const next: number = typeof current === 'number' ? current + 1 : 1;
    AppStorage.setOrCreate<number>(KEY_HISTORY_NEEDS_REFRESH, next);
  }
}
