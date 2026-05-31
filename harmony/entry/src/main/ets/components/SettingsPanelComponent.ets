// Settings panel component — extracted from Index.ets
// Handles server config, theme, local data management, import/export, sync, session controls.

import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, createThemeOptions, type ThemePalette, type ThemeOption } from '../common/UiDesign';

export interface SettingsPanelCallbacks {
  onSaveSettings: () => void;
  onSignOut: () => void;
  onSwitchToOffline: () => void;
  onResumeOnline: () => void;
  onConnectToLinkwarden: () => void;
  onExportLocal: () => void;
  onExportToFile: () => void;
  onImportFromFile: (strategy: string) => void;
  onImportLocal: (strategy: string) => void;
  onClearLocal: () => void;
  onConfirmPreview: () => void;
  onCancelPreview: () => void;
  onSyncLocalToServer: () => void;
  onMergeArchiveKeep: () => void;
  onMergeArchiveClear: () => void;
  onOpenLink: (url: string) => void;
  onSettingsInstanceChange: (value: string) => void;
  onImportPayloadChange: (value: string) => void;
  onThemeChange: (mode: ThemeMode) => void;
}

@Component
export struct SettingsPanelComponent {
  // Display state
  @Prop instance: string = '';
  @Prop settingsInstance: string = '';
  @Prop sessionMode: string = 'offline';
  @Prop token: string = '';
  @Prop themeMode: ThemeMode = 'system';
  @Prop loading: boolean = false;
  @Prop linksTotal: number = 0;
  @Prop tagsTotal: number = 0;
  @Prop pinnedTotal: number = 0;
  @Prop localLinkCount: number = 0;
  @Prop localCollectionCount: number = 0;
  @Prop localSyncRunning: boolean = false;
  @Prop syncProgressText: string = '';
  @Prop exportingLocal: boolean = false;
  @Prop importingLocal: boolean = false;
  @Prop clearingLocal: boolean = false;
  @Prop lastMergeHasResult: boolean = false;
  @Prop lastMergeSummary: string = '';
  @Prop importPayload: string = '';
  @Prop previewVisible: boolean = false;
  @Prop previewLinkCount: number = 0;
  @Prop previewCollectionCount: number = 0;
  @Prop previewTagCount: number = 0;
  @Prop previewExportedAt: string = '';
  @Prop previewStrategy: string = 'merge';
  @Prop previewSource: string = '';
  @Prop deviceDarkMode: boolean = false;
  @Prop callbacks: SettingsPanelCallbacks = {} as SettingsPanelCallbacks;

  private palette(): ThemePalette {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  private isDark(): boolean {
    return this.themeMode === 'dark' || (this.themeMode === 'system' && this.deviceDarkMode);
  }

  private isThemeOptionSelected(mode: ThemeMode): boolean {
    return this.themeMode === mode;
  }

  private formatCount(n: number): string {
    if (n >= 1000000) return `${(n / 1000000).toFixed(1)}M`;
    if (n >= 1000) return `${(n / 1000).toFixed(1)}K`;
    return `${n}`;
  }

  private themeModeLabel(): string {
    if (this.themeMode === 'system') return 'System';
    if (this.themeMode === 'dark') return 'Dark';
    return 'Light';
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Info card
        Column({ space: 6 }) {
          Text(this.instance.length > 0 ? this.instance : 'Linkwarden')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Text(`v0.1.0 · ${this.themeModeLabel()} theme`)
            .fontSize(11)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);
        }
        .padding(18)
        .backgroundColor(this.palette().card)
        .borderRadius(18)
        .border({ width: 1, color: this.palette().border })
        .width('100%');

        // Stats
        Row({ space: 8 }) {
          this.StatTile(this.formatCount(this.linksTotal), 'Links');
          this.StatTile(this.formatCount(this.tagsTotal), 'Tags');
          this.StatTile(this.formatCount(this.pinnedTotal), 'Pinned');
        }
        .width('100%');

        // Theme
        Column({ space: 10 }) {
          Text('Theme')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Row({ space: 8 }) {
            ForEach(createThemeOptions(), (option: ThemeOption) => {
              this.ThemeOptionButton(option.mode, option.title, option.subtitle);
            }, (option: ThemeOption) => option.mode);
          }
          .width('100%');
        }
        .padding(18)
        .backgroundColor(this.palette().card)
        .borderRadius(18)
        .border({ width: 1, color: this.palette().border })
        .width('100%');

        // Server
        Column({ space: 10 }) {
          Text('Server')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Text('Change the Linkwarden server URL.')
            .fontSize(12)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          TextInput({ placeholder: 'Server URL', text: this.settingsInstance })
            .onChange((value: string) => {
              this.callbacks.onSettingsInstanceChange(value);
            })
            .backgroundColor(this.palette().input)
            .fontColor(this.palette().textPrimary)
            .borderRadius(12)
            .width('100%');

          Button('Apply')
            .width('100%')
            .height(44)
            .backgroundColor(this.palette().accentSoft)
            .fontColor(this.palette().accent)
            .borderRadius(14)
            .border({ width: 1, color: this.palette().accent })
            .onClick(() => {
              this.callbacks.onSaveSettings();
            });
        }
        .padding(18)
        .backgroundColor(this.palette().card)
        .borderRadius(18)
        .border({ width: 1, color: this.palette().border })
        .width('100%');

        // Local data
        Column({ space: 10 }) {
          Text('Local Data')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Text(`${this.localLinkCount} links, ${this.localCollectionCount} collections stored locally. Back up regularly — data is in the app sandbox.`)
            .fontSize(12)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Row({ space: 8 }) {
            Button(this.exportingLocal ? '…' : 'Copy backup')
              .enabled(!this.exportingLocal)
              .layoutWeight(1)
              .height(44)
              .backgroundColor(this.palette().accentSoft)
              .fontColor(this.palette().accent)
              .borderRadius(14)
              .border({ width: 1, color: this.palette().accent })
              .onClick(() => {
                this.callbacks.onExportLocal();
              });

            Button(this.exportingLocal ? '…' : 'Export file')
              .enabled(!this.exportingLocal)
              .layoutWeight(1)
              .height(44)
              .backgroundColor(this.palette().accentSoft)
              .fontColor(this.palette().accent)
              .borderRadius(14)
              .border({ width: 1, color: this.palette().accent })
              .onClick(() => {
                this.callbacks.onExportToFile();
              });
          }
          .width('100%');

          Text('Import from file or paste JSON backup.')
            .fontSize(12)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Row({ space: 8 }) {
            Button(this.importingLocal ? '…' : 'Import (merge)')
              .enabled(!this.importingLocal)
              .layoutWeight(1)
              .height(44)
              .backgroundColor(this.palette().accentSoft)
              .fontColor(this.palette().accent)
              .borderRadius(14)
              .border({ width: 1, color: this.palette().accent })
              .onClick(() => {
                this.callbacks.onImportFromFile('merge');
              });

            Button(this.importingLocal ? '…' : 'Import (replace)')
              .enabled(!this.importingLocal)
              .layoutWeight(1)
              .height(44)
              .backgroundColor('transparent')
              .fontColor(this.palette().danger)
              .borderRadius(14)
              .border({ width: 1, color: this.palette().danger })
              .onClick(() => {
                this.callbacks.onImportFromFile('replace');
              });
          }
          .width('100%');

          TextArea({ placeholder: '{"format":"folio-backup",...}', text: this.importPayload })
            .onChange((value: string) => {
              this.callbacks.onImportPayloadChange(value);
            })
            .backgroundColor(this.palette().input)
            .fontColor(this.palette().textPrimary)
            .borderRadius(12)
            .width('100%')
            .height(120);

          Row({ space: 8 }) {
            Button(this.importingLocal ? 'Merging…' : 'Paste import (merge)')
              .enabled(!this.importingLocal)
              .layoutWeight(1)
              .height(44)
              .backgroundColor('transparent')
              .fontColor(this.palette().textPrimary)
              .borderRadius(14)
              .border({ width: 1, color: this.palette().border })
              .onClick(() => {
                this.callbacks.onImportLocal('merge');
              });

            Button(this.importingLocal ? 'Replacing…' : 'Paste import (replace)')
              .enabled(!this.importingLocal)
              .layoutWeight(1)
              .height(44)
              .backgroundColor('transparent')
              .fontColor(this.palette().danger)
              .borderRadius(14)
              .border({ width: 1, color: this.palette().danger })
              .onClick(() => {
                this.callbacks.onImportLocal('replace');
              });
          }
          .width('100%');

          if (this.clearingLocal || (this.localLinkCount + this.localCollectionCount) > 0) {
            Button(this.clearingLocal ? 'Clearing…' : 'Clear local data')
              .enabled(!this.clearingLocal)
              .width('100%')
              .height(44)
              .backgroundColor('transparent')
              .fontColor(this.palette().danger)
              .borderRadius(14)
              .border({ width: 1, color: this.palette().danger })
              .onClick(() => {
                this.callbacks.onClearLocal();
              });
          }
        }
        .padding(18)
        .backgroundColor(this.palette().card)
        .borderRadius(18)
        .border({ width: 1, color: this.palette().border })
        .width('100%');

        // Preview
        if (this.previewVisible) {
          Column({ space: 10 }) {
            Text('Import preview')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text(`Contains ${this.previewLinkCount} links, ${this.previewCollectionCount} collections, ${this.previewTagCount} tags.`)
              .fontSize(12)
              .fontColor(this.palette().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text(this.previewExportedAt.length > 0 ? `Exported ${this.previewExportedAt}` : 'Exported date not recorded.')
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text(this.previewStrategy === 'replace'
              ? 'Strategy: REPLACE — all current local data will be wiped.'
              : 'Strategy: MERGE — existing rows kept; duplicates skipped.')
              .fontSize(12)
              .fontColor(this.previewStrategy === 'replace' ? this.palette().danger : this.palette().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Row({ space: 8 }) {
              Button(this.importingLocal ? 'Importing…' : 'Confirm import')
                .enabled(!this.importingLocal)
                .layoutWeight(1)
                .height(44)
                .backgroundColor(this.previewStrategy === 'replace' ? 'transparent' : this.palette().accentSoft)
                .fontColor(this.previewStrategy === 'replace' ? this.palette().danger : this.palette().accent)
                .borderRadius(14)
                .border({ width: 1, color: this.previewStrategy === 'replace' ? this.palette().danger : this.palette().accent })
                .onClick(() => {
                  this.callbacks.onConfirmPreview();
                });

              Button('Cancel')
                .enabled(!this.importingLocal)
                .layoutWeight(1)
                .height(44)
                .backgroundColor('transparent')
                .fontColor(this.palette().textPrimary)
                .borderRadius(14)
                .border({ width: 1, color: this.palette().border })
                .onClick(() => {
                  this.callbacks.onCancelPreview();
                });
            }
            .width('100%');
          }
          .padding(18)
          .backgroundColor(this.palette().card)
          .borderRadius(18)
          .border({ width: 1, color: this.palette().accent })
          .width('100%');
        }

        // Sync
        if (this.sessionMode === 'online' && this.token.length > 0
            && (this.localLinkCount + this.localCollectionCount) > 0) {
          Column({ space: 10 }) {
            Text('Sync local → Linkwarden')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text(`${this.localLinkCount} bookmarks not on server yet.`)
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Button(this.localSyncRunning ? 'Syncing…' : `Upload to ${this.instance}`)
              .enabled(!this.localSyncRunning)
              .width('100%')
              .height(44)
              .backgroundColor(this.palette().accentSoft)
              .fontColor(this.palette().accent)
              .borderRadius(14)
              .border({ width: 1, color: this.palette().accent })
              .onClick(() => {
                this.callbacks.onSyncLocalToServer();
              });

            if (this.localSyncRunning && this.syncProgressText.length > 0) {
              Text(this.syncProgressText)
                .fontSize(12)
                .fontColor(this.palette().textSecondary)
                .width('100%')
                .textAlign(TextAlign.Start);
            }

            if (this.lastMergeHasResult) {
              Text(this.lastMergeSummary)
                .fontSize(12)
                .fontColor(this.palette().textPrimary)
                .width('100%')
                .textAlign(TextAlign.Start);

              Row({ space: 8 }) {
                Button('Keep as archive')
                  .layoutWeight(1)
                  .height(44)
                  .backgroundColor(this.palette().accentSoft)
                  .fontColor(this.palette().accent)
                  .borderRadius(14)
                  .border({ width: 1, color: this.palette().accent })
                  .onClick(() => {
                    this.callbacks.onMergeArchiveKeep();
                  });

                Button(this.clearingLocal ? 'Clearing…' : 'Clear local')
                  .enabled(!this.clearingLocal)
                  .layoutWeight(1)
                  .height(44)
                  .backgroundColor('transparent')
                  .fontColor(this.palette().danger)
                  .borderRadius(14)
                  .border({ width: 1, color: this.palette().danger })
                  .onClick(() => {
                    this.callbacks.onMergeArchiveClear();
                  });
              }
              .width('100%');
            }
          }
          .padding(18)
          .backgroundColor(this.palette().card)
          .borderRadius(18)
          .border({ width: 1, color: this.palette().border })
          .width('100%');
        }

        // Quick links
        Column({ space: 10 }) {
          Text('Quick Links')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Row({ space: 10 }) {
            this.LinkTile('Website', () => {
              this.callbacks.onOpenLink('https://linkwarden.app');
            });
            this.LinkTile('GitHub', () => {
              this.callbacks.onOpenLink('https://github.com/linkwarden/linkwarden');
            });
            this.LinkTile('Source', () => {
              this.callbacks.onOpenLink('https://github.com/xiebaiyuan/link-my-harmony');
            });
          }
          .width('100%');
        }
        .padding(18)
        .backgroundColor(this.palette().card)
        .borderRadius(18)
        .border({ width: 1, color: this.palette().border })
        .width('100%');

        // Session
        Column({ space: 10 }) {
          Text('Session')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
            .width('100%')
            .textAlign(TextAlign.Start);

          if (this.sessionMode === 'offline') {
            Text('Not connected. Sign in to sync across devices.')
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);

            if (this.token.length > 0) {
              Button(this.loading ? 'Resuming…' : 'Resume online mode')
                .enabled(!this.loading)
                .width('100%')
                .height(44)
                .backgroundColor(this.palette().accentSoft)
                .fontColor(this.palette().accent)
                .borderRadius(14)
                .border({ width: 1, color: this.palette().accent })
                .onClick(() => {
                  this.callbacks.onResumeOnline();
                });
            } else {
              Button('Connect to Linkwarden')
                .width('100%')
                .height(44)
                .backgroundColor(this.palette().accentSoft)
                .fontColor(this.palette().accent)
                .borderRadius(14)
                .border({ width: 1, color: this.palette().accent })
                .onClick(() => {
                  this.callbacks.onConnectToLinkwarden();
                });
            }
          } else {
            Text('Signed in. Switch to offline to work without server.')
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Button(this.loading ? 'Switching…' : 'Switch to offline (keep signed in)')
              .enabled(!this.loading)
              .width('100%')
              .height(44)
              .backgroundColor('transparent')
              .fontColor(this.palette().textPrimary)
              .borderRadius(14)
              .border({ width: 1, color: this.palette().border })
              .onClick(() => {
                this.callbacks.onSwitchToOffline();
              });

            Button('Sign Out')
              .width('100%')
              .height(44)
              .backgroundColor('transparent')
              .fontColor(this.palette().danger)
              .borderRadius(14)
              .border({ width: 1, color: this.palette().danger })
              .onClick(() => {
                this.callbacks.onSignOut();
              });
          }
        }
        .padding(18)
        .backgroundColor(this.palette().card)
        .borderRadius(18)
        .border({ width: 1, color: this.palette().border })
        .width('100%');

        Text('HarmonyOS Native Client')
          .fontSize(12)
          .fontColor(this.palette().textSecondary)
          .width('100%')
          .textAlign(TextAlign.Start);
      }
      .padding({ left: 12, right: 12, top: 12, bottom: 108 })
      .width('100%');
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off);
  }

  @Builder
  private StatTile(value: string, label: string) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().textPrimary)
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1);
      Text(label)
        .fontSize(10)
        .fontColor(this.palette().textSecondary)
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1);
    }
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(this.palette().input)
    .borderRadius(14)
    .border({ width: 1, color: this.palette().border });
  }

  @Builder
  private ThemeOptionButton(mode: ThemeMode, title: string, subtitle: string) {
    Button() {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isThemeOptionSelected(mode) ? this.palette().accentText : this.palette().textPrimary)
          .width('100%')
          .textAlign(TextAlign.Start)
          .maxLines(1);

        Text(subtitle)
          .fontSize(11)
          .fontColor(this.isThemeOptionSelected(mode) ? this.palette().accentText : this.palette().textSecondary)
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
    .backgroundColor(this.isThemeOptionSelected(mode) ? this.palette().accentStrong : this.palette().input)
    .borderRadius(14)
    .border({ width: 1, color: this.isThemeOptionSelected(mode) ? this.palette().accent : this.palette().border })
    .onClick(() => {
      this.callbacks.onThemeChange(mode);
    });
  }

  @Builder
  private LinkTile(title: string, onClick: () => void) {
    Button(title)
      .layoutWeight(1)
      .height(36)
      .fontSize(12)
      .backgroundColor(this.palette().input)
      .fontColor(this.palette().textPrimary)
      .borderRadius(10)
      .border({ width: 1, color: this.palette().border })
      .onClick(() => {
        onClick();
      });
  }
}
