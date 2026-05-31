// Shared theme picker component.
// Used by both LoginPanel (in Index) and SettingsPanel.

import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, createThemeOptions, type ThemePalette, type ThemeOption } from '../common/UiDesign';

@Component
export struct ThemePickerComponent {
  @Prop themeMode: ThemeMode = 'system';
  @Prop deviceDarkMode: boolean = false;
  @Prop onThemeChange: (mode: ThemeMode) => void = () => {};

  private palette(): ThemePalette {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  private isSelected(mode: ThemeMode): boolean {
    return this.themeMode === mode;
  }

  build() {
    Column({ space: 8 }) {
      Text('Theme')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary)
        .width('100%')
        .textAlign(TextAlign.Start);

      Row({ space: 8 }) {
        ForEach(createThemeOptions(), (option: ThemeOption) => {
          Button() {
            Column({ space: 4 }) {
              Text(option.title)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.isSelected(option.mode) ? this.palette().accentText : this.palette().textPrimary)
                .width('100%')
                .textAlign(TextAlign.Start)
                .maxLines(1);

              Text(option.subtitle)
                .fontSize(11)
                .fontColor(this.isSelected(option.mode) ? this.palette().accentText : this.palette().textSecondary)
                .width('100%')
                .textAlign(TextAlign.Start)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis });
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start);
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor(this.isSelected(option.mode) ? this.palette().accentStrong : this.palette().input)
          .borderRadius(14)
          .border({ width: 1, color: this.isSelected(option.mode) ? this.palette().accent : this.palette().border })
          .onClick(() => {
            this.onThemeChange(option.mode);
          });
        }, (option: ThemeOption) => option.mode);
      }
      .width('100%');
    }
    .width('100%');
  }
}
