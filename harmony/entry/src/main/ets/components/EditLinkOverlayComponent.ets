// Edit link overlay component — extracted from Index.ets
// Renders the edit-link bottom sheet with detail form, tag editor, and error/loading states.

import type { LinkItem, CollectionItem, LinkTag } from '../common/Models';
import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, type ThemePalette } from '../common/UiDesign';
import {
  parseTagsFromInput,
  normalizedTagCandidate,
  appendTagToInput,
  toggleTagInInput,
  tagsIncludingPendingQuery,
  quickTagOptions,
} from '../common/TagParser';

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

  private parsedEditTags(): Array<string> {
    return parseTagsFromInput(this.editTagsInput);
  }

  private editTagOptions(): Array<string> {
    return quickTagOptions(this.editTagPickerQuery, this.parsedEditTags(), this.knownTagNames);
  }

  private collectionLabel(): string {
    if (this.editCollectionQuery.trim().length > 0) {
      const match = this.collections.find((c) =>
        c.name.toLowerCase() === this.editCollectionQuery.trim().toLowerCase()
      );
      if (match !== undefined) {
        return match.name;
      }
    }
    return this.editCollectionQuery.length > 0 ? this.editCollectionQuery : 'Unorganized';
  }

  private collectionHint(): string {
    if (this.editCollectionQuery.trim().length > 0) {
      const match = this.collections.find((c) =>
        c.name.toLowerCase() === this.editCollectionQuery.trim().toLowerCase()
      );
      if (match !== undefined) {
        return match.description.length > 0 ? match.description : 'Collection';
      }
      return 'New collection';
    }
    return 'Tap to choose';
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
          Text(this.detailLoading ? 'Loading...' : 'Edit Link')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().textPrimary)
            .layoutWeight(1)
            .textAlign(TextAlign.Start);

          Button('✕')
            .fontSize(15)
            .width(34)
            .height(34)
            .backgroundColor(this.palette().card)
            .fontColor(this.palette().textSecondary)
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
              Text(this.selectedLink.collectionName.length > 0 ? this.selectedLink.collectionName : 'Unorganized')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.selectedLink.collectionColor.length > 0 ? this.selectedLink.collectionColor : this.palette().accent)
                .textAlign(TextAlign.Start);

              if (this.selectedLink.createdAt.length > 0) {
                Text(`Saved ${this.formatDateLabel(this.selectedLink.createdAt)}`)
                  .fontSize(12)
                  .fontColor(this.palette().textSecondary)
                  .textAlign(TextAlign.Start);
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            Button(this.pinSaving ? '…' : (this.editPinned ? '📌 Pinned' : 'Pin'))
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
        .borderRadius(16)
        .width('100%');

        // Link fields
        Column({ space: 12 }) {
          Text('Link')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          TextInput({ placeholder: 'Title', text: this.editName })
            .onChange((value: string) => {
              this.callbacks.onEditNameChange(value);
            })
            .backgroundColor(this.palette().surface)
            .borderRadius(10)
            .width('100%');

          TextInput({ placeholder: 'URL', text: this.editUrl })
            .onChange((value: string) => {
              this.callbacks.onEditUrlChange(value);
            })
            .backgroundColor(this.palette().surface)
            .borderRadius(10)
            .width('100%');

          TextInput({ placeholder: 'Description', text: this.editDescription })
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
        .borderRadius(16)
        .width('100%');

        // Collection picker
        Column({ space: 12 }) {
          Text('Collection')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);

          Row({ space: 12 }) {
            Text('📁')
              .fontSize(18);

            Column({ space: 3 }) {
              Text(this.collectionLabel())
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.palette().textPrimary)
                .width('100%')
                .textAlign(TextAlign.Start);

              Text(this.collectionHint())
                .fontSize(12)
                .fontColor(this.palette().textSecondary)
                .width('100%')
                .textAlign(TextAlign.Start);
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            Text('›')
              .fontSize(24)
              .fontColor(this.palette().textSecondary)
              .fontWeight(FontWeight.Lighter);
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
        .borderRadius(16)
        .width('100%');

        // Tag editor
        this.TagEditor();

        // Save button
        Button(this.detailSaving ? 'Saving...' : 'Save Changes')
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
        Button(this.detailDeleting ? 'Deleting...' : 'Delete Link')
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
          Text('Failed to load link detail.')
            .fontSize(14)
            .fontColor(this.palette().danger)
            .width('100%')
            .textAlign(TextAlign.Center);

          Row({ space: 12 }) {
            Button('Retry')
              .fontSize(14)
              .height(40)
              .layoutWeight(1)
              .backgroundColor(this.palette().accentStrong)
              .fontColor(this.palette().accentText)
              .borderRadius(10)
              .onClick(() => {
                this.callbacks.onRetry();
              });

            Button('Close')
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
            Text('Loading detail...')
              .fontSize(13)
              .fontColor(this.palette().textSecondary);
          }
          .width('100%');

          Button('Cancel')
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
        .padding(16)
        .width('100%');
      }
    }
    .width('100%');
  }

  @Builder
  private TagEditor() {
    Column({ space: 10 }) {
      Text('Tags')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textSecondary)
        .width('100%')
        .textAlign(TextAlign.Start);

      if (this.parsedEditTags().length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.parsedEditTags(), (tag: string) => {
              Button(tag)
                .fontSize(12)
                .height(30)
                .backgroundColor(this.palette().accentSoft)
                .fontColor(this.palette().accent)
                .borderRadius(999)
                .onClick(() => {
                  this.callbacks.onEditTagToggle(tag);
                });
            }, (tag: string) => `edit-sel-${tag}`);
          }
          .alignItems(VerticalAlign.Center);
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');

        Row()
          .width('100%')
          .height(1)
          .backgroundColor(this.palette().textSecondary)
          .opacity(0.12);
      }

      Row({ space: 10 }) {
        TextInput({ placeholder: 'Search or create tag…', text: this.editTagPickerQuery })
          .onChange((value: string) => {
            this.callbacks.onEditTagPickerQueryChange(value);
          })
          .layoutWeight(1)
          .backgroundColor(this.palette().surface)
          .fontColor(this.palette().textPrimary)
          .borderRadius(10);

        if (normalizedTagCandidate(this.editTagPickerQuery).length > 0) {
          Button('＋')
            .fontSize(18)
            .width(40)
            .height(40)
            .padding(0)
            .backgroundColor(this.palette().accentStrong)
            .fontColor(this.palette().accentText)
            .borderRadius(10)
            .onClick(() => {
              this.callbacks.onEditTagsInputChange(
                appendTagToInput(this.editTagsInput, this.editTagPickerQuery)
              );
              this.callbacks.onEditTagPickerQueryChange('');
            });
        }

        if (this.parsedEditTags().length > 0) {
          Button('✕')
            .fontSize(13)
            .width(34)
            .height(40)
            .padding(0)
            .backgroundColor('transparent')
            .fontColor(this.palette().danger)
            .borderRadius(10)
            .onClick(() => {
              this.callbacks.onEditTagsInputChange('');
              this.callbacks.onEditTagPickerQueryChange('');
            });
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      if (this.editTagOptions().length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.editTagOptions(), (tag: string) => {
              Button(tag)
                .fontSize(12)
                .height(30)
                .backgroundColor(this.parsedEditTags().some((s: string) => s.toLowerCase() === tag.toLowerCase())
                  ? this.palette().accentSoft : this.palette().input)
                .fontColor(this.parsedEditTags().some((s: string) => s.toLowerCase() === tag.toLowerCase())
                  ? this.palette().accent : this.palette().textPrimary)
                .borderRadius(999)
                .onClick(() => {
                  this.callbacks.onEditTagToggle(tag);
                });
            }, (tag: string) => `edit-opt-${tag}`);
          }
          .alignItems(VerticalAlign.Center);
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');
      }
    }
    .padding(16)
    .backgroundColor(this.palette().card)
    .borderRadius(16)
    .width('100%');
  }
}
