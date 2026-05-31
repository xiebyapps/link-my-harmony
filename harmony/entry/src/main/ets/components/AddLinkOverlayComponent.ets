// Add link overlay component — extracted from Index.ets
// Renders the add-link bottom sheet with URL/title inputs, collection picker, tag editor.

import type { CollectionItem } from '../common/Models';
import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, type ThemePalette } from '../common/UiDesign';
import {
  normalizedTagCandidate,
  appendTagToInput,
  toggleTagInInput,
  parseTagsFromInput,
  quickTagOptions,
} from '../common/TagParser';
import { extractUrlAndTitle } from '../common/UrlParser';

export interface AddLinkOverlayCallbacks {
  onClose: () => void;
  onAdd: () => void;
  onOpenCollectionPicker: () => void;
  onUrlChange: (value: string) => void;
  onTitleChange: (value: string) => void;
  onCollectionQueryChange: (value: string) => void;
  onTagsInputChange: (value: string) => void;
  onTagPickerQueryChange: (value: string) => void;
  onTagToggle: (tag: string) => void;
}

@Component
export struct AddLinkOverlayComponent {
  @Prop visible: boolean = false;
  @Prop loading: boolean = false;
  @Prop newLinkUrl: string = '';
  @Prop newLinkTitle: string = '';
  @Prop newLinkCollectionQuery: string = '';
  @Prop newLinkTagsInput: string = '';
  @Prop newTagPickerQuery: string = '';
  @Prop collections: Array<CollectionItem> = [];
  @Prop knownTagNames: Array<string> = [];
  @Prop themeMode: ThemeMode = 'system';
  @Prop deviceDarkMode: boolean = false;
  @Prop callbacks: AddLinkOverlayCallbacks = {} as AddLinkOverlayCallbacks;

  private palette(): ThemePalette {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  private parsedTags(): Array<string> {
    return parseTagsFromInput(this.newLinkTagsInput);
  }

  private tagOptions(): Array<string> {
    return quickTagOptions(this.newTagPickerQuery, this.parsedTags(), this.knownTagNames);
  }

  private hasResolvedUrl(): boolean {
    const trimmed = this.newLinkUrl.trim();
    if (trimmed.length === 0) return false;
    const result = extractUrlAndTitle(trimmed);
    return result.url.length > 0;
  }

  private urlSummary(): string {
    const trimmed = this.newLinkUrl.trim();
    if (trimmed.length === 0) return '';
    const result = extractUrlAndTitle(trimmed);
    if (result.url.length === 0) return 'No URL detected';
    const host = result.url.replace(/^https?:\/\//, '').split('/')[0];
    return result.title.length > 0 ? `${host} — ${result.title}` : host;
  }

  private collectionLabel(): string {
    if (this.newLinkCollectionQuery.trim().length > 0) {
      const match = this.collections.find((c) =>
        c.name.toLowerCase() === this.newLinkCollectionQuery.trim().toLowerCase()
      );
      if (match !== undefined) {
        return match.name;
      }
    }
    return this.newLinkCollectionQuery.length > 0 ? this.newLinkCollectionQuery : 'Unorganized';
  }

  private collectionHint(): string {
    if (this.newLinkCollectionQuery.trim().length > 0) {
      const match = this.collections.find((c) =>
        c.name.toLowerCase() === this.newLinkCollectionQuery.trim().toLowerCase()
      );
      if (match !== undefined) {
        return match.description.length > 0 ? match.description : 'Collection';
      }
      return 'New collection';
    }
    return 'Tap to choose';
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .opacity(this.visible ? 1 : 0)
        .animation({ duration: 250, curve: Curve.EaseOut })
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
          Text('Add Link')
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
            // URL + Title
            Column({ space: 12 }) {
              Text('Link')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.palette().textSecondary)
                .width('100%')
                .textAlign(TextAlign.Start);

              TextInput({ placeholder: 'Paste a URL or text containing a URL', text: this.newLinkUrl })
                .onChange((value: string) => {
                  this.callbacks.onUrlChange(value);
                })
                .backgroundColor(this.palette().surface)
                .fontColor(this.palette().textPrimary)
                .borderRadius(10)
                .width('100%');

              if (this.newLinkUrl.trim().length > 0) {
                Text(this.urlSummary())
                  .fontSize(12)
                  .fontColor(this.hasResolvedUrl() ? this.palette().textSecondary : this.palette().danger)
                  .width('100%')
                  .textAlign(TextAlign.Start);
              }

              TextInput({ placeholder: 'Title (optional)', text: this.newLinkTitle })
                .onChange((value: string) => {
                  this.callbacks.onTitleChange(value);
                })
                .backgroundColor(this.palette().surface)
                .fontColor(this.palette().textPrimary)
                .borderRadius(10)
                .width('100%');
            }
            .padding(16)
            .backgroundColor(this.palette().card)
            .borderRadius(16)
            .width('100%');

            // Collection
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

            // Add button
            Button(this.loading ? 'Adding...' : 'Add Link')
              .width('100%')
              .height(52)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.palette().accentStrong)
              .fontColor(this.palette().accentText)
              .borderRadius(16)
              .border({ width: 1, color: this.palette().accent })
              .shadow({ radius: 14, color: this.palette().dockShadow, offsetX: 0, offsetY: 8 })
              .enabled(!this.loading)
              .onClick(() => {
                this.callbacks.onAdd();
              });
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
  private TagEditor() {
    Column({ space: 10 }) {
      Text('Tags')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textSecondary)
        .width('100%')
        .textAlign(TextAlign.Start);

      if (this.parsedTags().length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.parsedTags(), (tag: string) => {
              Button(tag)
                .fontSize(12)
                .height(30)
                .backgroundColor(this.palette().accentSoft)
                .fontColor(this.palette().accent)
                .borderRadius(999)
                .onClick(() => {
                  this.callbacks.onTagToggle(tag);
                });
            }, (tag: string) => `draft-sel-${tag}`);
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
        TextInput({ placeholder: 'Search or create tag…', text: this.newTagPickerQuery })
          .onChange((value: string) => {
            this.callbacks.onTagPickerQueryChange(value);
          })
          .layoutWeight(1)
          .backgroundColor(this.palette().surface)
          .fontColor(this.palette().textPrimary)
          .borderRadius(10);

        if (normalizedTagCandidate(this.newTagPickerQuery).length > 0) {
          Button('＋')
            .fontSize(18)
            .width(40)
            .height(40)
            .padding(0)
            .backgroundColor(this.palette().accentStrong)
            .fontColor(this.palette().accentText)
            .borderRadius(10)
            .onClick(() => {
              this.callbacks.onTagsInputChange(
                appendTagToInput(this.newLinkTagsInput, this.newTagPickerQuery)
              );
              this.callbacks.onTagPickerQueryChange('');
            });
        }

        if (this.parsedTags().length > 0) {
          Button('✕')
            .fontSize(13)
            .width(34)
            .height(40)
            .padding(0)
            .backgroundColor('transparent')
            .fontColor(this.palette().danger)
            .borderRadius(10)
            .onClick(() => {
              this.callbacks.onTagsInputChange('');
              this.callbacks.onTagPickerQueryChange('');
            });
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      if (this.tagOptions().length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.tagOptions(), (tag: string) => {
              Button(tag)
                .fontSize(12)
                .height(30)
                .backgroundColor(this.parsedTags().some((s: string) => s.toLowerCase() === tag.toLowerCase())
                  ? this.palette().accentSoft : this.palette().input)
                .fontColor(this.parsedTags().some((s: string) => s.toLowerCase() === tag.toLowerCase())
                  ? this.palette().accent : this.palette().textPrimary)
                .borderRadius(999)
                .onClick(() => {
                  this.callbacks.onTagToggle(tag);
                });
            }, (tag: string) => `draft-opt-${tag}`);
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
