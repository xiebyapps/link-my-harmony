// Elements panel component — extracted from Index.ets
// Renders the library view with tabs for Links, Collections, Tags.

import type { LinkItem, CollectionItem } from '../common/Models';
import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, type ThemePalette } from '../common/UiDesign';

export interface ElementsPanelCallbacks {
  onTabChange: (tab: string) => void;
  onRefreshLinks: () => void;
  onRefreshDashboard: () => void;
  onAddLink: () => void;
  onPinnedFilterToggle: () => void;
  onSearchQueryChange: (query: string) => void;
  onCollectionFilterClear: () => void;
  onCollectionSearchChange: (query: string) => void;
  onTagSearchChange: (query: string) => void;
  onLinkClick: (item: LinkItem) => void;
  onLinkLongPress: (item: LinkItem) => void;
  onCollectionClick: (id: number) => void;
  onTagClick: (tag: string) => void;
  onLoadMore: () => void;
  onRecordCollectionView: (collectionId: number) => void;
  onOpenLink: (url: string) => void;
  onPullRefreshLinks: () => void;
  onPullRefreshCollections: () => void;
  onPullRefreshTags: () => void;
}

@Component
export struct ElementsPanelComponent {
  @Prop currentTab: string = 'links';
  @Prop links: Array<LinkItem> = [];
  @Prop collections: Array<CollectionItem> = [];
  @Prop filteredCollections: Array<CollectionItem> = [];
  @Prop filteredTags: Array<string> = [];
  @Prop loading: boolean = false;
  @Prop loadingMore: boolean = false;
  @Prop hasMore: boolean = false;
  @Prop showPinnedOnly: boolean = false;
  @Prop selectedCollectionFilterId: number = 0;
  @Prop activeCollectionName: string = '';
  @Prop searchQuery: string = '';
  @Prop collectionSearchQuery: string = '';
  @Prop tagSearchQuery: string = '';
  @Prop linksRefreshing: boolean = false;
  @Prop collectionsRefreshing: boolean = false;
  @Prop tagsRefreshing: boolean = false;
  private tagUsageCount(tagName: string): number {
    return this.links.filter((item: LinkItem) =>
      item.tags.some((tag) => tag.name.toLowerCase() === tagName.toLowerCase())
    ).length;
  }
  @Prop themeMode: ThemeMode = 'system';
  @Prop deviceDarkMode: boolean = false;
  @Prop callbacks: ElementsPanelCallbacks = {} as ElementsPanelCallbacks;

  private palette(): ThemePalette {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  build() {
    Column({ space: 12 }) {
      // Segmented control
      Row() {
        Text('Links')
          .layoutWeight(1)
          .height(32)
          .fontSize(13)
          .fontWeight(this.currentTab === 'links' ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentTab === 'links' ? this.palette().accentText : this.palette().textSecondary)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.currentTab === 'links' ? this.palette().accentStrong : Color.Transparent)
          .borderRadius(8)
          .onClick(() => {
            this.callbacks.onTabChange('links');
            this.callbacks.onRefreshLinks();
          });

        Text('Collections')
          .layoutWeight(1)
          .height(32)
          .fontSize(13)
          .fontWeight(this.currentTab === 'collections' ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentTab === 'collections' ? this.palette().accentText : this.palette().textSecondary)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.currentTab === 'collections' ? this.palette().accentStrong : Color.Transparent)
          .borderRadius(8)
          .onClick(() => {
            this.callbacks.onTabChange('collections');
            this.callbacks.onRefreshDashboard();
          });

        Text('Tags')
          .layoutWeight(1)
          .height(32)
          .fontSize(13)
          .fontWeight(this.currentTab === 'tags' ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentTab === 'tags' ? this.palette().accentText : this.palette().textSecondary)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.currentTab === 'tags' ? this.palette().accentStrong : Color.Transparent)
          .borderRadius(8)
          .onClick(() => {
            this.callbacks.onTabChange('tags');
          });
      }
      .width('100%')
      .padding(4)
      .backgroundColor(this.palette().input)
      .borderRadius(12);

      if (this.currentTab === 'links') {
        Column() {
          this.LinksTab();
        }
        .layoutWeight(1)
        .width('100%');
      } else if (this.currentTab === 'collections') {
        Column() {
          this.CollectionsTab();
        }
        .layoutWeight(1)
        .width('100%');
      } else {
        Column() {
          this.TagsTab();
        }
        .layoutWeight(1)
        .width('100%');
      }
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private LinksTab() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text(`${this.links.length} links`)
          .fontSize(12)
          .fontColor(this.palette().textSecondary)
          .layoutWeight(1)
          .textAlign(TextAlign.Start);

        Button() {
          Text('＋')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().accentText)
            .width('100%')
            .textAlign(TextAlign.Center);
        }
        .width(40)
        .height(40)
        .backgroundColor(this.palette().accentStrong)
        .borderRadius(20)
        .padding(0)
        .onClick(() => {
          this.callbacks.onAddLink();
        });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center);

      Row({ space: 8 }) {
        Text(this.showPinnedOnly ? '📌 Pinned' : '≡ All')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.showPinnedOnly ? this.palette().accentText : this.palette().textSecondary)
          .padding({ left: 12, right: 12 })
          .height(36)
          .backgroundColor(this.showPinnedOnly ? this.palette().accentStrong : this.palette().input)
          .borderRadius(999)
          .onClick(() => {
            this.callbacks.onPinnedFilterToggle();
          });

        TextInput({ placeholder: '🔍  Search links', text: this.searchQuery })
          .onChange((value: string) => {
            this.callbacks.onSearchQueryChange(value);
          })
          .backgroundColor(this.palette().input)
          .fontColor(this.palette().textPrimary)
          .borderRadius(12)
          .height(36)
          .layoutWeight(1);
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      if (this.selectedCollectionFilterId > 0) {
        Row({ space: 6 }) {
          Text('🗂')
            .fontSize(12);
          Text(this.activeCollectionName)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.palette().accentText)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1);
          Text('✕')
            .fontSize(12)
            .fontColor(this.palette().accentText)
            .onClick(() => {
              this.callbacks.onCollectionFilterClear();
            });
        }
        .width('100%')
        .padding({ left: 12, right: 12 })
        .height(32)
        .backgroundColor(this.palette().accentStrong)
        .borderRadius(999)
        .alignItems(VerticalAlign.Center);
      }

      if (this.links.length === 0) {
        Text(this.loading ? 'Loading links…' : 'No links yet.')
          .fontSize(13)
          .fontColor(this.palette().textSecondary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 24, bottom: 8 });
      }

      List({ space: 8 }) {
        ForEach(this.links, (item: LinkItem) => {
          ListItem() {
            this.LinkCard(item);
          };
        }, (item: LinkItem) => `${item.id}-${item.url}`)
      }
      .divider({ strokeWidth: 0 })
      .width('100%')
      .height('100%')
      .onReachEnd(() => {
        if (this.hasMore && !this.loadingMore && !this.loading) {
          this.callbacks.onLoadMore();
        }
      });

      if (this.loadingMore) {
        Text('Loading more…')
          .fontSize(12)
          .fontColor(this.palette().textSecondary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 8 });
      } else if (!this.hasMore && this.links.length > 0) {
        Text('No more links.')
          .fontSize(12)
          .fontColor(this.palette().textSecondary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 8 });
      }
    }
    .height('100%')
    .width('100%');
  }

  @Builder
  private CollectionsTab() {
    Column({ space: 10 }) {
      Text(`${this.filteredCollections.length} collections`)
        .fontSize(13)
        .fontColor(this.palette().textSecondary)
        .width('100%')
        .textAlign(TextAlign.Start);

      TextInput({ placeholder: 'Search collections', text: this.collectionSearchQuery })
        .onChange((value: string) => {
          this.callbacks.onCollectionSearchChange(value);
        })
        .backgroundColor(this.palette().input)
        .fontColor(this.palette().textPrimary)
        .borderRadius(12)
        .width('100%');

      if (this.filteredCollections.length === 0) {
        Text(this.collections.length === 0 ? 'No collections.' : 'No collections match this search.')
          .fontSize(13)
          .fontColor(this.palette().textSecondary)
          .width('100%')
          .textAlign(TextAlign.Start)
          .padding({ top: 8, bottom: 8 });
      }

      List({ space: 8 }) {
        ForEach(this.filteredCollections, (collection: CollectionItem) => {
          ListItem() {
            this.CollectionRow(collection);
          };
        }, (collection: CollectionItem) => `collection-panel-${collection.id}`)
      }
      .divider({ strokeWidth: 0 })
      .width('100%')
      .height('100%');
    }
    .height('100%')
    .width('100%');
  }

  @Builder
  private TagsTab() {
    Scroll() {
      Column({ space: 8 }) {
        Text(`${this.filteredTags.length} tags`)
          .fontSize(13)
          .fontColor(this.palette().textSecondary)
          .width('100%')
          .textAlign(TextAlign.Start);

        TextInput({ placeholder: 'Search tags', text: this.tagSearchQuery })
          .onChange((value: string) => {
            this.callbacks.onTagSearchChange(value);
          })
          .backgroundColor(this.palette().input)
          .fontColor(this.palette().textPrimary)
          .borderRadius(12)
          .width('100%');

        if (this.filteredTags.length === 0) {
          Text('No tags.')
            .fontSize(13)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start)
            .padding({ top: 8, bottom: 8 });
        } else {
          ForEach(this.filteredTags, (tag: string) => {
            this.TagRow(tag);
          }, (tag: string) => `tag-${tag}`);
        }
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ bottom: 96 });
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off);
  }

  @Builder
  private LinkCard(item: LinkItem) {
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
  private CollectionRow(collection: CollectionItem) {
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

        if (collection.parentName !== undefined && collection.parentName.length > 0) {
          Text(collection.parentName)
            .fontSize(12)
            .fontColor(this.palette().textSecondary)
            .width('100%')
            .textAlign(TextAlign.Start)
            .maxLines(1);
        } else if (collection.description.length > 0) {
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
    .onClick(() => {
      this.callbacks.onCollectionClick(collection.id);
    });
  }

  @Builder
  private TagRow(tag: string) {
    Row({ space: 0 }) {
      Text('#')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().accent)
        .padding({ left: 14, right: 4 });

      Text(tag)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis });

      Text(`${this.tagUsageCount(tag)}`)
        .fontSize(12)
        .fontColor(this.palette().textSecondary)
        .padding({ left: 8, right: 14, top: 12, bottom: 12 });
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.palette().card)
    .borderRadius(12)
    .onClick(() => {
      this.callbacks.onTagClick(tag);
    });
  }
}
