import { ThemeConfig } from '../models/DataModels';

export class ThemeTokens {
  static canvas(theme: ThemeConfig): string {
    return theme.backgroundColor;
  }

  static surface(theme: ThemeConfig): string {
    return theme.cardColor;
  }

  static elevated(theme: ThemeConfig): string {
    return theme.isDark ? '#24363F' : '#FCFEFE';
  }

  static paper(theme: ThemeConfig): string {
    return theme.isDark ? '#24363F' : '#FEFFFF';
  }

  static paperInset(theme: ThemeConfig): string {
    return theme.isDark ? '#1B2C34' : '#F5FAFA';
  }

  static paperSoft(theme: ThemeConfig): string {
    return theme.isDark ? '#2A3E47' : '#EEF6F6';
  }

  static paperBorder(theme: ThemeConfig): string {
    return theme.isDark ? '#405761' : '#DDE9EC';
  }

  static paperHighlight(theme: ThemeConfig): string {
    return theme.isDark ? '#4B6670' : '#FFFFFF';
  }

  static paperShadow(theme: ThemeConfig): string {
    return theme.isDark ? '#32000000' : '#14182126';
  }

  static paperThinShadow(theme: ThemeConfig): string {
    return theme.isDark ? '#22000000' : '#0A182126';
  }

  static tealWash(theme: ThemeConfig): string {
    return theme.isDark ? '#243F42' : '#E8F6F5';
  }

  static slateWash(theme: ThemeConfig): string {
    return theme.isDark ? '#2B3D45' : '#EEF3F5';
  }

  static lavenderWash(theme: ThemeConfig): string {
    return theme.isDark ? '#383449' : '#F1EFF8';
  }

  static greenWash(theme: ThemeConfig): string {
    return theme.isDark ? '#2C4338' : '#EEF7F0';
  }

  static subtle(theme: ThemeConfig): string {
    return theme.isDark ? '#2A3E47' : '#EEF4F5';
  }

  static mist(theme: ThemeConfig): string {
    return theme.isDark ? '#1B2C34' : '#F7FAFB';
  }

  static text(theme: ThemeConfig): string {
    return theme.textColor;
  }

  static muted(theme: ThemeConfig): string {
    return theme.isDark ? '#C0CDD2' : '#62727A';
  }

  static secondary(theme: ThemeConfig): string {
    return theme.isDark ? '#9EB0B8' : '#8A969B';
  }

  static primary(theme: ThemeConfig): string {
    return theme.primaryColor;
  }

  static accent(theme: ThemeConfig): string {
    return theme.accentColor;
  }

  static onPrimary(theme: ThemeConfig): string {
    return theme.isDark ? '#102026' : '#FFFFFF';
  }

  static calmFill(theme: ThemeConfig): string {
    return theme.isDark ? '#223640' : '#E8F0F2';
  }

  static hairline(theme: ThemeConfig): string {
    return theme.isDark ? '#405761' : '#DCE7EA';
  }

  static cardBorder(theme: ThemeConfig): string {
    return theme.isDark ? '#405761' : '#E3EBEE';
  }

  static cardShadow(theme: ThemeConfig): string {
    return theme.isDark ? '#26000000' : '#12182126';
  }

  static slate(theme: ThemeConfig): string {
    return theme.isDark ? '#B5C4CB' : '#607385';
  }

  static selectedSurface(theme: ThemeConfig): string {
    return theme.isDark ? '#2C4853' : '#E6F0F3';
  }

  static shadow(theme: ThemeConfig): string {
    return ThemeTokens.cardShadow(theme);
  }
}
