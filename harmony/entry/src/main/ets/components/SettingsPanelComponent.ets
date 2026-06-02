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
  onDebugAddTestBookmarks?: () => void;
  onDebugRemoveTestBookmarks?: () => void;
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

  private res(key: Resource): string {
    return this.getUIContext().getHostContext()!.resourceManager.getStringSync(key);
  }

  private themeModeLabel(): string {
    if (this.themeMode === 'system') return this.res($r('app.string.theme_system'));
    if (this.themeMode === 'dark') return this.res($r('app.string.theme_dark'));
    return this.res($r('app.string.theme_light'));
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        // Info card
        Column({ space: 6 }) {
          Text(this.instance.length > 0 ? this.instance : 'Linkwarden')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Text($r('app.string.label_version_theme', this.themeModeLabel()))
            .fontSize(11)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);
        }
        .padding(14)
        .backgroundColor(this.palette().card)
        .borderRadius(14)
        .width('100%');

        // Stats
        Row({ space: 8 }) {
          this.StatTile(this.formatCount(this.linksTotal), this.res($r('app.string.tab_links')));
          this.StatTile(this.formatCount(this.tagsTotal), this.res($r('app.string.tab_tags')));
          this.StatTile(this.formatCount(this.pinnedTotal), this.res($r('app.string.btn_pinned')));
        }
        .width('100%');

        // Theme
        Column({ space: 10 }) {
          Text($r('app.string.label_theme'))
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
        .padding(14)
        .backgroundColor(this.palette().card)
        .borderRadius(14)
        .width('100%');

        // Server
        Column({ space: 10 }) {
          Text($r('app.string.label_server'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Text($r('app.string.msg_change_server_desc'))
            .fontSize(12)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          TextInput({ placeholder: $r('app.string.label_server_url'), text: this.settingsInstance })
            .onChange((value: string) => {
              this.callbacks.onSettingsInstanceChange(value);
            })
            .backgroundColor(this.palette().input)
            .fontColor(this.palette().textPrimary)
            .borderRadius(12)
            .width('100%');

          Button($r('app.string.btn_apply'))
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
        .padding(14)
        .backgroundColor(this.palette().card)
        .borderRadius(14)
        .width('100%');

        // Local data
        Column({ space: 10 }) {
          Text($r('app.string.label_local_data'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Text($r('app.string.label_local_data_summary', this.localLinkCount, this.localCollectionCount))
            .fontSize(12)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Row({ space: 8 }) {
            Button(this.exportingLocal ? '…' : $r('app.string.btn_copy_backup'))
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

            Button(this.exportingLocal ? '…' : $r('app.string.btn_export_file'))
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

          Text($r('app.string.msg_import_desc'))
            .fontSize(12)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Row({ space: 8 }) {
            Button(this.importingLocal ? '…' : $r('app.string.btn_import_merge_short'))
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

            Button(this.importingLocal ? '…' : $r('app.string.btn_import_replace_short'))
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
            Button(this.importingLocal ? $r('app.string.btn_merging') : $r('app.string.btn_paste_import_merge'))
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

            Button(this.importingLocal ? $r('app.string.btn_replacing') : $r('app.string.btn_paste_import_replace'))
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
            Button(this.clearingLocal ? $r('app.string.btn_clearing') : $r('app.string.btn_clear_local'))
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
        .padding(14)
        .backgroundColor(this.palette().card)
        .borderRadius(14)
        .width('100%');

        // Preview
        if (this.previewVisible) {
          Column({ space: 10 }) {
            Text($r('app.string.title_import_preview'))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text($r('app.string.label_import_preview_count', this.previewLinkCount, this.previewCollectionCount, this.previewTagCount))
              .fontSize(12)
              .fontColor(this.palette().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text(this.previewExportedAt.length > 0 ? $r('app.string.label_exported_at', this.previewExportedAt) : $r('app.string.label_exported_not_recorded'))
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text(this.previewStrategy === 'replace'
              ? $r('app.string.msg_strategy_replace')
              : $r('app.string.msg_strategy_merge'))
              .fontSize(12)
              .fontColor(this.previewStrategy === 'replace' ? this.palette().danger : this.palette().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Row({ space: 8 }) {
              Button(this.importingLocal ? $r('app.string.btn_importing') : $r('app.string.btn_confirm_import'))
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
          .padding(14)
          .backgroundColor(this.palette().card)
          .borderRadius(14)
          .border({ width: 1, color: this.palette().accent })
          .width('100%');
        }

        // Sync
        if (this.sessionMode === 'online' && this.token.length > 0
            && (this.localLinkCount + this.localCollectionCount) > 0) {
          Column({ space: 10 }) {
            Text($r('app.string.msg_sync_title'))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text($r('app.string.label_not_on_server', this.localLinkCount))
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Button(this.localSyncRunning ? $r('app.string.btn_syncing') : $r('app.string.btn_upload_to', this.instance))
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
                Button($r('app.string.btn_keep_archive'))
                  .layoutWeight(1)
                  .height(44)
                  .backgroundColor(this.palette().accentSoft)
                  .fontColor(this.palette().accent)
                  .borderRadius(14)
                  .border({ width: 1, color: this.palette().accent })
                  .onClick(() => {
                    this.callbacks.onMergeArchiveKeep();
                  });

                Button(this.clearingLocal ? $r('app.string.btn_clearing') : $r('app.string.btn_clear_local_short'))
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
          .padding(14)
          .backgroundColor(this.palette().card)
          .borderRadius(14)
          .border({ width: 1, color: this.palette().border })
          .width('100%');
        }

        // Quick links
        Column({ space: 10 }) {
          Text($r('app.string.title_quick_links'))
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
        .padding(14)
        .backgroundColor(this.palette().card)
        .borderRadius(14)
        .width('100%');

        // Session
        Column({ space: 10 }) {
          Text($r('app.string.title_session'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textPrimary)
            .width('100%')
            .textAlign(TextAlign.Start);

          if (this.sessionMode === 'offline') {
            Text($r('app.string.msg_not_connected'))
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);

            if (this.token.length > 0) {
              Button(this.loading ? $r('app.string.btn_resuming') : $r('app.string.btn_resume_online'))
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
              Button($r('app.string.btn_connect_linkwarden'))
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
            Text($r('app.string.msg_signed_in_switch_hint'))
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Button(this.loading ? $r('app.string.btn_switching') : $r('app.string.btn_switch_offline'))
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

            Button($r('app.string.btn_sign_out'))
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
        .padding(14)
        .backgroundColor(this.palette().card)
        .borderRadius(14)
        .width('100%');

        // Debug tools
        if (this.callbacks.onDebugAddTestBookmarks !== undefined) {
          Column({ space: 10 }) {
            Text('Debug Tools')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().danger)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text('Add 30 test bookmarks with diverse tags and collections. Remove them with the button below.')
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Row({ space: 8 }) {
              Button('Add test data')
                .layoutWeight(1)
                .height(40)
                .backgroundColor(this.palette().accentSoft)
                .fontColor(this.palette().accent)
                .borderRadius(10)
                .onClick(() => {
                  this.callbacks.onDebugAddTestBookmarks!();
                });

              Button('Remove test data')
                .layoutWeight(1)
                .height(40)
                .backgroundColor('transparent')
                .fontColor(this.palette().danger)
                .borderRadius(10)
                .border({ width: 1, color: this.palette().danger })
                .onClick(() => {
                  this.callbacks.onDebugRemoveTestBookmarks!();
                });
            }
            .width('100%');
          }
          .padding(14)
          .backgroundColor(this.palette().card)
          .borderRadius(14)
          .border({ width: 1, color: this.palette().danger })
          .width('100%');
        }

        Text($r('app.string.msg_harmonyos_client'))
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
        Text($r('app.string.' + title))
          .fontSize(12)
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
