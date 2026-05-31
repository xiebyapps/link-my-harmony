// Collection modals — extracted from Index.ets
// Renders create-collection and collection-picker bottom sheets.

import type { CollectionItem } from '../common/Models';
import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, type ThemePalette } from '../common/UiDesign';
import { matchedCollectionByQuery } from '../common/CollectionMatcher';

// --- Create Collection Overlay ---

export interface CollectionOverlayCallbacks {
  onClose: () => void;
  onCreate: () => void;
  onReset: () => void;
  onNameChange: (value: string) => void;
  onDescriptionChange: (value: string) => void;
  onParentQueryChange: (value: string) => void;
  onColorChange: (color: string) => void;
}

@Component
export struct CollectionOverlayComponent {
  @Prop visible: boolean = false;
  @Prop saving: boolean = false;
  @Prop name: string = '';
  @Prop description: string = '';
  @Prop color: string = '#2563eb';
  @Prop parentQuery: string = '';
  @Prop collections: Array<CollectionItem> = [];
  @Prop themeMode: ThemeMode = 'system';
  @Prop deviceDarkMode: boolean = false;
  @Prop callbacks: CollectionOverlayCallbacks = {} as CollectionOverlayCallbacks;

  private palette(): ThemePalette {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  private matchedParent(): CollectionItem | null {
    return matchedCollectionByQuery(this.collections, this.parentQuery);
  }

  private parentSummary(): string {
    const matched = this.matchedParent();
    if (matched === null) {
      return 'NO_PARENT';
    }
    return matched.name;
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

      Column({ space: 12 }) {
        Row() {
          Column({ space: 4 }) {
            Text($r('app.string.title_create_collection'))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.palette().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text($r('app.string.msg_create_here_hint'))
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);

          Button($r('app.string.btn_back'))
            .backgroundColor(this.palette().card)
            .fontColor(this.palette().textPrimary)
            .borderRadius(999)
            .onClick(() => {
              this.callbacks.onClose();
            });
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);

        Column({ space: 10 }) {
          TextInput({ placeholder: $r('app.string.hint_name'), text: this.name })
            .onChange((value: string) => {
              this.callbacks.onNameChange(value);
            })
            .width('100%');

          TextInput({ placeholder: $r('app.string.label_description_optional'), text: this.description })
            .onChange((value: string) => {
              this.callbacks.onDescriptionChange(value);
            })
            .height(88)
            .width('100%');

          TextInput({ placeholder: $r('app.string.hint_parent_collection_optional'), text: this.parentQuery })
            .onChange((value: string) => {
              this.callbacks.onParentQueryChange(value);
            })
            .width('100%');

          if (this.parentQuery.trim().length > 0) {
            Text(this.parentSummary() === 'NO_PARENT'
              ? $r('app.string.msg_no_parent_found')
              : $r('app.string.label_parent_collection', this.parentSummary()))
              .fontSize(12)
              .fontColor(this.matchedParent() !== null ? this.palette().textSecondary : this.palette().danger)
              .width('100%')
              .textAlign(TextAlign.Start);
          }

          Row({ space: 8 }) {
            this.ColorOption('#2563eb');
            this.ColorOption('#0f766e');
            this.ColorOption('#dc2626');
            this.ColorOption('#7c3aed');
            this.ColorOption('#f59e0b');
          }
          .width('100%');

          Text($r('app.string.label_color', this.color))
            .fontSize(12)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start);
        }
        .padding(14)
        .backgroundColor(this.palette().card)
        .borderRadius(14)
        .width('100%');

        Row({ space: 8 }) {
          Button($r('app.string.btn_reset'))
            .layoutWeight(1)
            .backgroundColor(this.palette().card)
            .fontColor(this.palette().textPrimary)
            .borderRadius(12)
            .onClick(() => {
              this.callbacks.onReset();
            });

          Button(this.saving ? $r('app.string.btn_creating') : $r('app.string.btn_create'))
            .layoutWeight(1)
            .backgroundColor(this.palette().accentStrong)
            .fontColor(this.palette().accentText)
            .borderRadius(12)
            .enabled(!this.saving)
            .onClick(() => {
              this.callbacks.onCreate();
            });
        }
        .width('100%');
      }
      .onClick(() => {})
      .width('100%')
      .padding(12)
      .backgroundColor(this.palette().surface)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .constraintSize({ maxHeight: '80%' });
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private ColorOption(c: string) {
    Button('')
      .width(28)
      .height(28)
      .backgroundColor(c)
      .borderRadius(14)
      .padding(0)
      .border({ width: this.color === c ? 3 : 0, color: '#ffffff' })
      .onClick(() => {
        this.callbacks.onColorChange(c);
      });
  }
}

// --- Collection Picker Overlay ---

export interface CollectionPickerOverlayCallbacks {
  onClose: () => void;
  onSelect: (collection: CollectionItem | null) => void;
  onCreateNew: () => void;
  onQueryChange: (value: string) => void;
}

@Component
export struct CollectionPickerOverlayComponent {
  @Prop visible: boolean = false;
  @Prop query: string = '';
  @Prop collections: Array<CollectionItem> = [];
  @Prop selectedId: number = -1;
  @Prop createButtonText: string = 'New Collection';
  @Prop themeMode: ThemeMode = 'system';
  @Prop deviceDarkMode: boolean = false;
  @Prop callbacks: CollectionPickerOverlayCallbacks = {} as CollectionPickerOverlayCallbacks;

  private palette(): ThemePalette {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  private filteredCollections(): Array<CollectionItem> {
    const term = this.query.trim().toLowerCase();
    if (term.length === 0) {
      return this.collections;
    }
    return this.collections.filter((item) => item.name.toLowerCase().indexOf(term) >= 0);
  }

  private itemHint(item: CollectionItem): string {
    if (item.parentName.length > 0) {
      return `${item.linkCount} links · Parent: ${item.parentName}`;
    }
    return `${item.linkCount} links`;
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

      Column({ space: 12 }) {
        Row() {
          Column({ space: 4 }) {
            Text($r('app.string.title_choose_collection'))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.palette().textPrimary)
              .width('100%')
              .textAlign(TextAlign.Start);

            Text($r('app.string.msg_search_collections_or_create'))
              .fontSize(12)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start);
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);

          Button($r('app.string.btn_back'))
            .backgroundColor(this.palette().card)
            .fontColor(this.palette().textPrimary)
            .borderRadius(999)
            .onClick(() => {
              this.callbacks.onClose();
            });
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);

        TextInput({ placeholder: $r('app.string.hint_search_collections'), text: this.query })
          .onChange((value: string) => {
            this.callbacks.onQueryChange(value);
          })
          .width('100%');

        Row({ space: 8 }) {
          Button($r('app.string.unorganized'))
            .layoutWeight(1)
            .backgroundColor(this.selectedId === 0 ? this.palette().accentStrong : this.palette().card)
            .fontColor(this.selectedId === 0 ? this.palette().accentText : this.palette().textPrimary)
            .borderRadius(12)
            .onClick(() => {
              this.callbacks.onSelect(null);
            });

          Button(this.createButtonText)
            .layoutWeight(1)
            .backgroundColor(this.palette().card)
            .fontColor(this.palette().textPrimary)
            .borderRadius(12)
            .onClick(() => {
              this.callbacks.onCreateNew();
            });
        }
        .width('100%');

        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.filteredCollections(), (item: CollectionItem) => {
              Row({ space: 10 }) {
                Column({ space: 4 }) {
                  Text(item.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.palette().textPrimary)
                    .width('100%')
                    .textAlign(TextAlign.Start);

                  Text(this.itemHint(item))
                    .fontSize(12)
                    .fontColor(this.palette().textSecondary)
                    .width('100%')
                    .textAlign(TextAlign.Start);
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start);

                if (this.selectedId === item.id) {
                  Text($r('app.string.label_selected'))
                    .fontSize(12)
                    .fontColor(this.palette().accent);
                }
              }
              .padding({ left: 14, right: 14, top: 14, bottom: 14 })
              .backgroundColor(this.selectedId === item.id ? this.palette().surface : this.palette().card)
              .borderRadius(12)
              .width('100%')
              .onClick(() => {
                this.callbacks.onSelect(item);
              });
            }, (item: CollectionItem) => `${item.id}`);

            if (this.filteredCollections().length === 0) {
              Text($r('app.string.msg_no_collections_match'))
                .fontSize(12)
                .fontColor(this.palette().textSecondary)
                .width('100%')
                .textAlign(TextAlign.Start)
                .padding(12);
            }
          }
          .width('100%');
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .constraintSize({ maxHeight: '58%' });
      }
      .onClick(() => {})
      .width('100%')
      .padding(12)
      .backgroundColor(this.palette().surface)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .constraintSize({ maxHeight: '85%' });
    }
    .width('100%')
    .height('100%');
  }
}
