// Search panel component — extracted from Index.ets
// Renders global search with links, collections, and tags results.

import type { LinkItem, CollectionItem } from '../common/Models';
import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, type ThemePalette } from '../common/UiDesign';

export interface SearchPanelCallbacks {
  onSearchQueryChange: (query: string) => void;
  onSearch: () => void;
  onToggleShowAllLinks: () => void;
  onToggleShowAllCollections: () => void;
  onToggleShowAllTags: () => void;
  onLinkClick: (item: LinkItem) => void;
  onLinkLongPress: (item: LinkItem) => void;
  onCollectionClick: (id: number) => void;
  onTagClick: (tag: string) => void;
  onRecordCollectionView: (collectionId: number) => void;
  onOpenLink: (url: string) => void;
}

@Component
export struct SearchPanelComponent {
  @Prop searchQuery: string = '';
  @Prop showAllLinks: boolean = false;
  @Prop showAllCollections: boolean = false;
  @Prop showAllTags: boolean = false;
  @Prop filteredLinks: Array<LinkItem> = [];
  @Prop filteredCollections: Array<CollectionItem> = [];
  @Prop filteredTags: Array<string> = [];
  @Prop hasAnyResult: boolean = false;
  @Prop highlightedLinkId: number = 0;
  @Prop themeMode: ThemeMode = 'system';
  @Prop deviceDarkMode: boolean = false;
  @Prop callbacks: SearchPanelCallbacks = {} as SearchPanelCallbacks;

  private palette(): ThemePalette {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
        // Title
        Text('Search')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().textPrimary)
          .width('100%')
          .textAlign(TextAlign.Start);

        // Search input
        Row({ space: 8 }) {
          TextInput({ placeholder: 'Search links, collections, tags', text: this.searchQuery })
            .onChange((value: string) => {
              this.callbacks.onSearchQueryChange(value);
            })
            .backgroundColor(this.palette().input)
            .fontColor(this.palette().textPrimary)
            .borderRadius(12)
            .layoutWeight(1);

          Button('Search')
            .height(44)
            .backgroundColor(this.palette().accentSoft)
            .fontColor(this.palette().accent)
            .borderRadius(12)
            .border({ width: 1, color: this.palette().accent })
            .onClick(() => {
              this.callbacks.onSearch();
            });
        }
        .width('100%');

        if (this.searchQuery.trim().length === 0) {
          Text('Insert a search term to search links, collections and tags.')
            .fontSize(13)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start)
            .padding({ top: 8, bottom: 8 });
        } else {
          if (!this.hasAnyResult) {
            Text('No results found for this search term.')
              .fontSize(13)
              .fontColor(this.palette().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Start)
              .padding({ top: 8, bottom: 8 });
          }

          // Links
          this.ResultGroup('Links', this.filteredLinks.length);
          ForEach(this.filteredLinks.slice(0, this.showAllLinks ? this.filteredLinks.length : 5), (item: LinkItem) => {
            this.LinkResultCard(item);
          }, (item: LinkItem) => `search-link-${item.id}`);
          if (this.filteredLinks.length > 5) {
            Button(this.showAllLinks ? 'Show Less' : 'Show More')
              .fontColor(this.palette().accent)
              .backgroundColor(this.palette().card)
              .borderRadius(10)
              .onClick(() => {
                this.callbacks.onToggleShowAllLinks();
              });
          }

          // Collections
          this.ResultGroup('Collections', this.filteredCollections.length);
          ForEach(this.filteredCollections.slice(0, this.showAllCollections ? this.filteredCollections.length : 5), (collection: CollectionItem) => {
            this.CollectionResultRow(collection);
          }, (collection: CollectionItem) => `search-collection-${collection.id}`);
          if (this.filteredCollections.length > 5) {
            Button(this.showAllCollections ? 'Show Less' : 'Show More')
              .fontColor(this.palette().accent)
              .backgroundColor(this.palette().card)
              .borderRadius(10)
              .onClick(() => {
                this.callbacks.onToggleShowAllCollections();
              });
          }

          // Tags
          this.ResultGroup('Tags', this.filteredTags.length);
          ForEach(this.filteredTags.slice(0, this.showAllTags ? this.filteredTags.length : 10), (tag: string) => {
            this.TagResultRow(tag);
          }, (tag: string) => `search-tag-${tag}`);
          if (this.filteredTags.length > 10) {
            Button(this.showAllTags ? 'Show Less' : 'Show More')
              .fontColor(this.palette().accent)
              .backgroundColor(this.palette().card)
              .borderRadius(10)
              .onClick(() => {
                this.callbacks.onToggleShowAllTags();
              });
          }
        }
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 96 });
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off);
  }

  @Builder
  private ResultGroup(title: string, total: number) {
    Row({ space: 8 }) {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary);
      Text(`${total}`)
        .fontSize(12)
        .fontColor(this.palette().textSecondary);
    }
    .width('100%');
  }

  @Builder
  private LinkResultCard(item: LinkItem) {
    Column({ space: 0 }) {
      Row({ space: 8 }) {
        Text(item.name.length > 0 ? item.name : item.url)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.Start);

        if (item.pinned) {
          Text('📌')
            .fontSize(13);
        }
      }
      .width('100%')
      .padding({ bottom: 4 });

      Text(item.url)
        .fontSize(11)
        .fontColor(this.palette().textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Start)
        .opacity(0.8);

      if (item.description.length > 0) {
        Text(item.description)
          .fontSize(12)
          .fontColor(this.palette().textSecondary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)
          .padding({ top: 4 });
      }

      Row({ space: 6 }) {
        Text(item.collectionName.length > 0 ? item.collectionName : 'Unorganized')
          .fontSize(11)
          .fontColor(item.collectionColor.length > 0 ? item.collectionColor : this.palette().accent)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.palette().input)
          .borderRadius(999)
          .maxLines(1);

        if (item.tags.length > 0) {
          Text(item.tags.map((t) => `#${t.name}`).join(' '))
            .fontSize(11)
            .fontColor(this.palette().textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1);
        }
      }
      .width('100%')
      .padding({ top: 8 })
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.palette().card)
    .borderRadius(14)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.callbacks.onRecordCollectionView(item.collectionId);
      this.callbacks.onOpenLink(item.url);
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          this.callbacks.onLinkLongPress(item);
        })
    );
  }

  @Builder
  private CollectionResultRow(collection: CollectionItem) {
    Row({ space: 10 }) {
      if (collection.color.length > 0) {
        Circle({ width: 10, height: 10 })
          .fill(collection.color);
      }

      Column({ space: 2 }) {
        Text(collection.name.length > 0 ? collection.name : 'Untitled')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().textPrimary)
          .width('100%')
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        if (collection.description.length > 0) {
          Text(collection.description)
            .fontSize(12)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Text(`${collection.linkCount}`)
        .fontSize(13)
        .fontColor(this.palette().textSecondary)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .backgroundColor(this.palette().input)
        .borderRadius(999);
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.palette().card)
    .borderRadius(14)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.callbacks.onCollectionClick(collection.id);
    });
  }

  @Builder
  private TagResultRow(tag: string) {
    Row({ space: 10 }) {
      Text('#')
        .fontSize(15)
        .fontColor(this.palette().accent)
        .fontWeight(FontWeight.Bold)
        .width(20)
        .textAlign(TextAlign.Center);

      Text(tag)
        .fontSize(15)
        .fontColor(this.palette().textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.palette().card)
    .borderRadius(14)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.callbacks.onTagClick(tag);
    });
  }
}
