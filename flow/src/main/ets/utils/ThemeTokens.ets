import { ThemeConfig } from '../models/DataModels';

export class ThemeTokens {
  static canvas(theme: ThemeConfig): string {
    return theme.backgroundColor;
  }

  static surface(theme: ThemeConfig): string {
    return theme.cardColor;
  }

  static elevated(theme: ThemeConfig): string {
    return theme.isDark ? '#263C45' : '#FEFFFF';
  }

  static paper(theme: ThemeConfig): string {
    return theme.isDark ? '#263B44' : '#FFFFFF';
  }

  static paperInset(theme: ThemeConfig): string {
    return theme.isDark ? '#1C3038' : '#F5FAFB';
  }

  static paperSoft(theme: ThemeConfig): string {
    return theme.isDark ? '#2E4650' : '#F0F7F8';
  }

  static paperBorder(theme: ThemeConfig): string {
    return theme.isDark ? '#4B6873' : '#D9E8EC';
  }

  static paperHighlight(theme: ThemeConfig): string {
    return theme.isDark ? '#5E7D88' : '#FFFFFF';
  }

  static paperShadow(theme: ThemeConfig): string {
    return theme.isDark ? '#44000000' : '#1D16324A';
  }

  static paperThinShadow(theme: ThemeConfig): string {
    return theme.isDark ? '#2E000000' : '#14163242';
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
    return theme.isDark ? '#2D434C' : '#F0F5F6';
  }

  static mist(theme: ThemeConfig): string {
    return theme.isDark ? '#1D3038' : '#F8FBFC';
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
    return theme.isDark ? '#455F69' : '#D9E7EA';
  }

  static cardBorder(theme: ThemeConfig): string {
    return theme.isDark ? '#4B6873' : '#DCEAED';
  }

  static cardShadow(theme: ThemeConfig): string {
    return theme.isDark ? '#42000000' : '#1A17364A';
  }

  static slate(theme: ThemeConfig): string {
    return theme.isDark ? '#B5C4CB' : '#607385';
  }

  static selectedSurface(theme: ThemeConfig): string {
    return theme.isDark ? '#31545F' : '#E7F3F6';
  }

  static shadow(theme: ThemeConfig): string {
    return ThemeTokens.cardShadow(theme);
  }

  static actionSurface(theme: ThemeConfig): string {
    return theme.isDark ? '#DDF7F4' : '#1F7C92';
  }

  static actionText(theme: ThemeConfig): string {
    return theme.isDark ? '#10252B' : '#FFFFFF';
  }

  static quietAction(theme: ThemeConfig): string {
    return theme.isDark ? '#324D57' : '#E8F3F6';
  }

  static brandLine(theme: ThemeConfig): string {
    return theme.isDark ? '#8DE5DE' : '#39AFA9';
  }

  static brandBlue(theme: ThemeConfig): string {
    return theme.isDark ? '#A7DCEF' : '#2F86A1';
  }

  static brandLavender(theme: ThemeConfig): string {
    return theme.isDark ? '#C9C0F4' : '#8D7BC7';
  }

  static glassVeil(theme: ThemeConfig): string {
    return theme.isDark ? '#253F49' : '#F8FCFD';
  }
}
