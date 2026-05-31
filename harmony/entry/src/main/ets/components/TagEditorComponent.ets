// Shared tag editor component — used by both AddLink and EditLink overlays.
// Handles tag display, search/create input, and quick tag suggestions.

import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, type ThemePalette } from '../common/UiDesign';
import {
  normalizedTagCandidate,
  appendTagToInput,
  parseTagsFromInput,
  quickTagOptions,
} from '../common/TagParser';

export interface TagEditorCallbacks {
  onTagsInputChange: (value: string) => void;
  onTagPickerQueryChange: (value: string) => void;
  onTagToggle: (tag: string) => void;
}

@Component
export struct TagEditorComponent {
  @Prop tagsInput: string = '';
  @Prop tagPickerQuery: string = '';
  @Prop knownTagNames: Array<string> = [];
  @Prop themeMode: ThemeMode = 'system';
  @Prop deviceDarkMode: boolean = false;
  @Prop callbacks: TagEditorCallbacks = {} as TagEditorCallbacks;

  private palette(): ThemePalette {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  private parsedTags(): Array<string> {
    return parseTagsFromInput(this.tagsInput);
  }

  private tagOptions(): Array<string> {
    return quickTagOptions(this.tagPickerQuery, this.parsedTags(), this.knownTagNames);
  }

  build() {
    Column({ space: 10 }) {
      Text($r('app.string.label_tags'))
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textSecondary)
        .width('100%')
        .textAlign(TextAlign.Start);

      // Selected tags
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
            }, (tag: string) => `tag-sel-${tag}`);
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

      // Search/create input
      Row({ space: 10 }) {
        TextInput({ placeholder: $r('app.string.hint_search_or_create_tag'), text: this.tagPickerQuery })
          .onChange((value: string) => {
            this.callbacks.onTagPickerQueryChange(value);
          })
          .layoutWeight(1)
          .backgroundColor(this.palette().surface)
          .fontColor(this.palette().textPrimary)
          .borderRadius(10);

        if (normalizedTagCandidate(this.tagPickerQuery).length > 0) {
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
                appendTagToInput(this.tagsInput, this.tagPickerQuery)
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

      // Quick tag suggestions
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
            }, (tag: string) => `tag-opt-${tag}`);
          }
          .alignItems(VerticalAlign.Center);
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');
      }
    }
    .padding(14)
    .backgroundColor(this.palette().card)
    .borderRadius(14)
    .width('100%');
  }
}
