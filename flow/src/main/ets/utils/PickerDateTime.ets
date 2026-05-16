export class PickerDateTime {
  static getStartDate(): Date {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return start;
  }

  static getEndDate(): Date {
    const end = new Date();
    end.setHours(0, 0, 0, 0);
    end.setDate(end.getDate() + 60);
    return end;
  }

  static buildDueAt(date: number, time: string): number {
    const parts = time.split(':');
    const hour = parseInt(parts[0]) || 0;
    const minute = parseInt(parts[1]) || 0;
    const due = new Date(date);
    due.setHours(hour, minute, 0, 0);
    return due.getTime();
  }

  static getSelectedDate(date: number): Date {
    return new Date(date);
  }

  static getSelectedTime(date: number, time: string): Date {
    return new Date(PickerDateTime.buildDueAt(date, time));
  }

  static dateFromSelectedDate(selected: Date): number {
    const next = new Date(selected.getTime());
    next.setHours(0, 0, 0, 0);
    return next.getTime();
  }

  static dateFromPickerResult(currentDate: number, result: DatePickerResult): number {
    const current = new Date(currentDate);
    const year = result.year === undefined ? current.getFullYear() : result.year;
    const month = result.month === undefined ? current.getMonth() : result.month;
    const day = result.day === undefined ? current.getDate() : result.day;
    const next = new Date(year, month, day);
    next.setHours(0, 0, 0, 0);
    return next.getTime();
  }

  static timeFromPickerResult(currentTime: string, result: TimePickerResult): string {
    const parts = currentTime.split(':');
    const currentHour = parseInt(parts[0]) || 0;
    const currentMinute = parseInt(parts[1]) || 0;
    const hour = result.hour === undefined ? currentHour : result.hour;
    const minute = result.minute === undefined ? currentMinute : result.minute;
    return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
  }
}
