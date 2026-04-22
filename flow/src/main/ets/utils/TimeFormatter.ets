/**
 * 时间格式化工具类
 */

export class TimeFormatter {
  /**
   * 格式化日期为 YYYY-MM-DD
   */
  static formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 格式化时间为 HH:MM
   */
  static formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * 格式化日期时间为 MM-DD HH:MM
   */
  static formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${month}-${day} ${hours}:${minutes}`;
  }

  /**
   * 格式化分钟为 HH:MM 格式
   */
  static formatMinutes(minutes: number): string {
    const hours = Math.floor(minutes / 60);
    const mins = Math.floor(minutes % 60);
    if (hours > 0) {
      return `${hours}:${String(mins).padStart(2, '0')}`;
    }
    return `${mins}`;
  }

  /**
   * 格式化秒数为 MM:SS
   */
  static formatSeconds(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }

  /**
   * 格式化小时数（保留一位小数）
   */
  static formatHours(minutes: number): string {
    const hours = minutes / 60;
    return hours.toFixed(1);
  }

  /**
   * 获取今天的日期字符串
   */
  static getTodayString(): string {
    return TimeFormatter.formatDate(Date.now());
  }

  /**
   * 获取星期几的中文
   */
  static getWeekdayName(timestamp: number): string {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const date = new Date(timestamp);
    return weekdays[date.getDay()];
  }

  /**
   * 获取相对时间描述
   */
  static getRelativeTime(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp;
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}天前`;
    if (hours > 0) return `${hours}小时前`;
    if (minutes > 0) return `${minutes}分钟前`;
    return '刚刚';
  }

  /**
   * 检查是否是今天
   */
  static isToday(timestamp: number): boolean {
    const today = TimeFormatter.formatDate(Date.now());
    const target = TimeFormatter.formatDate(timestamp);
    return today === target;
  }

  /**
   * 获取本周的开始和结束时间
   */
  static getWeekRange(): [number, number] {
    const now = new Date();
    const day = now.getDay();
    const diff = now.getDate() - day + (day === 0 ? -6 : 1); // 周一为起始
    const monday = new Date(now.setDate(diff));
    monday.setHours(0, 0, 0, 0);
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    sunday.setHours(23, 59, 59, 999);
    return [monday.getTime(), sunday.getTime()];
  }

  /**
   * 获取本月的开始和结束时间
   */
  static getMonthRange(): [number, number] {
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
    firstDay.setHours(0, 0, 0, 0);
    const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    lastDay.setHours(23, 59, 59, 999);
    return [firstDay.getTime(), lastDay.getTime()];
  }
}
