// Edit link overlay component — extracted from Index.ets
// Renders the edit-link bottom sheet with detail form, tag editor, and error/loading states.

import type { LinkItem, CollectionItem, LinkTag } from '../common/Models';
import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, type ThemePalette } from '../common/UiDesign';
import { TagEditorComponent, type TagEditorCallbacks } from './TagEditorComponent';

export interface EditLinkOverlayCallbacks {
  onClose: () => void;
  onSave: () => void;
  onDelete: () => void;
  onRetry: () => void;
  onTogglePin: () => void;
  onOpenCollectionPicker: () => void;
  onEditNameChange: (value: string) => void;
  onEditUrlChange: (value: string) => void;
  onEditDescriptionChange: (value: string) => void;
  onEditCollectionQueryChange: (value: string) => void;
  onEditTagsInputChange: (value: string) => void;
  onEditTagPickerQueryChange: (value: string) => void;
  onEditTagToggle: (tag: string) => void;
}

@Component
export struct EditLinkOverlayComponent {
  @Prop visible: boolean = false;
  @Prop selectedLink: LinkItem = {} as LinkItem;
  @Prop detailLoading: boolean = false;
  @Prop detailSaving: boolean = false;
  @Prop detailDeleting: boolean = false;
  @Prop detailFailedLinkId: number = 0;
  @Prop editName: string = '';
  @Prop editUrl: string = '';
  @Prop editDescription: string = '';
  @Prop editPinned: boolean = false;
  @Prop editCollectionQuery: string = '';
  @Prop editTagsInput: string = '';
  @Prop editTagPickerQuery: string = '';
  @Prop pinSaving: boolean = false;
  @Prop collections: Array<CollectionItem> = [];
  @Prop knownTagNames: Array<string> = [];
  @Prop themeMode: ThemeMode = 'system';
  @Prop deviceDarkMode: boolean = false;
  @Prop callbacks: EditLinkOverlayCallbacks = {} as EditLinkOverlayCallbacks;

  private palette(): ThemePalette {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  private res(name: string): string {
    try {
      return this.getUIContext().getHostContext()!.resourceManager.getStringByNameSync(name);
    } catch (_) {
      return name;
    }
  }

  private matchedCollection(): CollectionItem | undefined {
    const q = this.editCollectionQuery.trim();
    if (q.length === 0) return undefined;
    return this.collections.find((c) => c.name.toLowerCase() === q.toLowerCase());
  }

  private formatDateLabel(dateStr: string): string {
    if (dateStr.length === 0) return '';
    try {
      const d = new Date(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return `${months[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
    } catch (_) {
      return dateStr;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          this.callbacks.onClose();
        });

      Column() {
        Row()
          .width(44)
          .height(4)
          .borderRadius(999)
          .backgroundColor(this.palette().textSecondary)
          .opacity(0.25)
          .alignSelf(ItemAlign.Center)
          .margin({ top: 12, bottom: 6 });

        Row() {
          Text(this.detailLoading ? $r('app.string.label_loading') : $r('app.string.title_edit_link'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().textPrimary)
            .layoutWeight(1)
            .textAlign(TextAlign.Start);

          Button() {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(15)
              .fontColor([this.palette().textSecondary]);
          }
            .width(34)
            .height(34)
            .backgroundColor(this.palette().card)
            .borderRadius(999)
            .padding(0)
            .onClick(() => {
              this.callbacks.onClose();
            });
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 16 });

        Scroll() {
          Column({ space: 16 }) {
            this.DetailContent();
          }
          .width('100%')
          .padding({ bottom: 24 });
        }
        .width('100%')
        .scrollBar(BarState.Off);
      }
      .onClick(() => {})
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.palette().surface)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .constraintSize({ maxHeight: '92%' })
      .translate({ y: this.visible ? 0 : 200 })
      .animation({ duration: 200, curve: Curve.FastOutSlowIn });
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private DetailContent() {
    Column({ space: 16 }) {
      if (!this.detailLoading && this.selectedLink.id !== 0) {
        // Collection info + pin
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(this.selectedLink.collectionName.length > 0 ? this.selectedLink.collectionName : $r('app.string.unorganized'))
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.selectedLink.collectionColor.length > 0 ? this.selectedLink.collectionColor : this.palette().accent)
                .textAlign(TextAlign.Start);

              if (this.selectedLink.createdAt.length > 0) {
                Text($r('app.string.label_saved_date', this.formatDateLabel(this.selectedLink.createdAt)))
                  .fontSize(12)
                  .fontColor(this.palette().textSecondary)
                  .textAlign(TextAlign.Start);
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            Button(this.pinSaving ? '…' : (this.editPinned ? '📌 ' + this.res('btn_pinned') : this.res('btn_pin')))
              .fontSize(13)
              .height(34)
              .backgroundColor(this.editPinned ? this.palette().accentStrong : this.palette().surface)
              .fontColor(this.editPinned ? this.palette().accentText : this.palette().textPrimary)
              .borderRadius(999)
              .enabled(!this.pinSaving && !this.detailSaving && !this.detailDeleting)
              .onClick(() => {
                this.callbacks.onTogglePin();
              });
          }
          .width('100%')
          .alignItems(VerticalAlign.Center);
        }
        .padding(16)
        .backgroundColor(this.palette().card)
        .borderRadius(14)
        .width('100%');

        // Link fields
        Column({ space: 12 }) {
          Text($r('app.string.label_link_section'))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          TextInput({ placeholder: $r('app.string.label_link_name'), text: this.editName })
            .onChange((value: string) => {
              this.callbacks.onEditNameChange(value);
            })
            .backgroundColor(this.palette().surface)
            .borderRadius(10)
            .width('100%');

          TextInput({ placeholder: $r('app.string.label_link_url'), text: this.editUrl })
            .onChange((value: string) => {
              this.callbacks.onEditUrlChange(value);
            })
            .backgroundColor(this.palette().surface)
            .borderRadius(10)
            .width('100%');

          TextInput({ placeholder: $r('app.string.label_description'), text: this.editDescription })
            .onChange((value: string) => {
              this.callbacks.onEditDescriptionChange(value);
            })
            .height(96)
            .backgroundColor(this.palette().surface)
            .borderRadius(10)
            .width('100%');
        }
        .padding(16)
        .backgroundColor(this.palette().card)
        .borderRadius(14)
        .width('100%');

        // Collection picker
        Column({ space: 12 }) {
          Text($r('app.string.label_collection_section'))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.folder'))
              .fontSize(18)
              .fontColor([this.palette().accent]);

            Column({ space: 3 }) {
              Text(this.matchedCollection() !== undefined
                ? this.matchedCollection()!.name
                : (this.editCollectionQuery.length > 0 ? this.editCollectionQuery : $r('app.string.unorganized')))
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.palette().textPrimary)
                .width('100%')
                .textAlign(TextAlign.Start);

              Text(this.matchedCollection() !== undefined
                ? (this.matchedCollection()!.description.length > 0 ? this.matchedCollection()!.description : $r('app.string.label_collection'))
                : (this.editCollectionQuery.length > 0 ? $r('app.string.label_new_collection') : $r('app.string.hint_tap_to_choose')))
                .fontSize(12)
                .fontColor(this.palette().textSecondary)
                .width('100%')
                .textAlign(TextAlign.Start);
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(18)
              .fontColor([this.palette().textSecondary]);
          }
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .borderRadius(12)
          .backgroundColor(this.palette().surface)
          .width('100%')
          .onClick(() => {
            this.callbacks.onOpenCollectionPicker();
          });
        }
        .padding(16)
        .backgroundColor(this.palette().card)
        .borderRadius(14)
        .width('100%');

        // Tag editor
        TagEditorComponent({
          tagsInput: this.editTagsInput,
          tagPickerQuery: this.editTagPickerQuery,
          knownTagNames: this.knownTagNames,
          themeMode: this.themeMode,
          deviceDarkMode: this.deviceDarkMode,
          callbacks: {
            onTagsInputChange: (v: string) => { this.editTagsInput = v; },
            onTagPickerQueryChange: (v: string) => { this.editTagPickerQuery = v; },
            onTagToggle: (tag: string) => this.callbacks.onEditTagToggle(tag),
          },
        });

        // Save button
        Button(this.detailSaving ? $r('app.string.btn_saving') : $r('app.string.btn_save_changes'))
          .width('100%')
          .height(50)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.palette().accentStrong)
          .fontColor(this.palette().accentText)
          .borderRadius(14)
          .enabled(!this.detailSaving && !this.detailDeleting)
          .onClick(() => {
            this.callbacks.onSave();
          });

        // Delete button
        Button(this.detailDeleting ? $r('app.string.btn_deleting') : $r('app.string.btn_delete_link'))
          .width('100%')
          .height(44)
          .fontSize(14)
          .backgroundColor('transparent')
          .fontColor(this.palette().danger)
          .borderRadius(14)
          .enabled(!this.detailSaving && !this.detailDeleting)
          .onClick(() => {
            this.callbacks.onDelete();
          });
      } else if (!this.detailLoading && this.detailFailedLinkId > 0) {
        // Error state
        Column({ space: 12 }) {
          Text($r('app.string.title_failed_load'))
            .fontSize(14)
            .fontColor(this.palette().danger)
            .width('100%')
            .textAlign(TextAlign.Center);

          Row({ space: 12 }) {
            Button($r('app.string.btn_retry'))
              .fontSize(14)
              .height(40)
              .layoutWeight(1)
              .backgroundColor(this.palette().accentStrong)
              .fontColor(this.palette().accentText)
              .borderRadius(10)
              .onClick(() => {
                this.callbacks.onRetry();
              });

            Button($r('app.string.btn_close'))
              .fontSize(14)
              .height(40)
              .layoutWeight(1)
              .backgroundColor(this.palette().surface)
              .fontColor(this.palette().textPrimary)
              .borderRadius(10)
              .onClick(() => {
                this.callbacks.onClose();
              });
          }
          .width('100%');
        }
        .padding(16)
        .width('100%');
      } else {
        // Loading state
        Column({ space: 12 }) {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(16)
              .height(16)
              .color(this.palette().textSecondary);
            Text($r('app.string.label_loading_detail'))
              .fontSize(13)
              .fontColor(this.palette().textSecondary);
          }
          .width('100%');

          Button($r('app.string.btn_cancel'))
            .fontSize(13)
            .height(36)
            .backgroundColor(this.palette().surface)
            .fontColor(this.palette().textSecondary)
            .borderRadius(10)
            .width('100%')
            .onClick(() => {
              this.callbacks.onClose();
            });
        }
        .padding(14)
        .width('100%');
      }
    }
    .width('100%');
  }
}
