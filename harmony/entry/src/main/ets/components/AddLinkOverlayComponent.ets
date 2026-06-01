// Add link overlay component — extracted from Index.ets
// Renders the add-link bottom sheet with URL/title inputs, collection picker, tag editor.

import type { CollectionItem } from '../common/Models';
import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, type ThemePalette } from '../common/UiDesign';
import { extractUrlAndTitle } from '../common/UrlParser';
import { TagEditorComponent, type TagEditorCallbacks } from './TagEditorComponent';

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
    if (result.url.length === 0) return 'NO_URL';
    const host = result.url.replace(/^https?:\/\//, '').split('/')[0];
    return result.title.length > 0 ? `${host} — ${result.title}` : host;
  }

  private matchedCollection(): CollectionItem | undefined {
    const q = this.newLinkCollectionQuery.trim();
    if (q.length === 0) return undefined;
    return this.collections.find((c) => c.name.toLowerCase() === q.toLowerCase());
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
          Text($r('app.string.btn_add_link'))
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
            // URL + Title
            Column({ space: 12 }) {
              Text($r('app.string.label_link_section'))
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.palette().textSecondary)
                .width('100%')
                .textAlign(TextAlign.Start);

              TextInput({ placeholder: $r('app.string.hint_paste_url'), text: this.newLinkUrl })
                .onChange((value: string) => {
                  this.callbacks.onUrlChange(value);
                })
                .backgroundColor(this.palette().surface)
                .fontColor(this.palette().textPrimary)
                .borderRadius(10)
                .width('100%');

              if (this.newLinkUrl.trim().length > 0) {
                Text(this.urlSummary() === 'NO_URL' ? $r('app.string.msg_no_url_detected') : this.urlSummary())
                  .fontSize(12)
                  .fontColor(this.hasResolvedUrl() ? this.palette().textSecondary : this.palette().danger)
                  .width('100%')
                  .textAlign(TextAlign.Start);
              }

              TextInput({ placeholder: $r('app.string.hint_title_optional'), text: this.newLinkTitle })
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
            .borderRadius(14)
            .width('100%');

            // Collection
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
                    : (this.newLinkCollectionQuery.length > 0 ? this.newLinkCollectionQuery : $r('app.string.unorganized')))
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.palette().textPrimary)
                    .width('100%')
                    .textAlign(TextAlign.Start);

                  Text(this.matchedCollection() !== undefined
                    ? (this.matchedCollection()!.description.length > 0 ? this.matchedCollection()!.description : $r('app.string.label_collection'))
                    : (this.newLinkCollectionQuery.length > 0 ? $r('app.string.label_new_collection') : $r('app.string.hint_tap_to_choose')))
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
              tagsInput: this.newLinkTagsInput,
              tagPickerQuery: this.newTagPickerQuery,
              knownTagNames: this.knownTagNames,
              themeMode: this.themeMode,
              deviceDarkMode: this.deviceDarkMode,
              callbacks: {
                onTagsInputChange: (v: string) => { this.newLinkTagsInput = v; },
                onTagPickerQueryChange: (v: string) => { this.newTagPickerQuery = v; },
                onTagToggle: (tag: string) => this.callbacks.onTagToggle(tag),
              },
            });

            // Add button
            Button(this.loading ? $r('app.string.btn_adding') : $r('app.string.btn_add_link'))
              .width('100%')
              .height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.palette().accentStrong)
              .fontColor(this.palette().accentText)
              .borderRadius(14)
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
}
