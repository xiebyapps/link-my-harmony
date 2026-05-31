// Dashboard panel component — extracted from Index.ets
// Renders shortcut cards, pinned/recent link strips, and collection previews.

import type { LinkItem, CollectionItem } from '../common/Models';
import type { ThemeMode } from '../common/SessionState';
import { createThemePalette, type ThemePalette } from '../common/UiDesign';

export interface CollectionPreviewSection {
  collection: CollectionItem;
  links: Array<LinkItem>;
}

export interface DashboardPanelCallbacks {
  onNavigateAllLinks: () => void;
  onNavigatePinnedLinks: () => void;
  onNavigateRecentLinks: () => void;
  onNavigateCollections: () => void;
  onNavigateTags: () => void;
  onNavigateCollection: (id: number) => void;
  onOpenLink: (url: string) => void;
  onLinkLongPress: (item: LinkItem) => void;
  onRecordCollectionView: (collectionId: number) => void;
}

@Component
export struct DashboardPanelComponent {
  @Prop pinnedLinks: Array<LinkItem> = [];
  @Prop dashboardLinks: Array<LinkItem> = [];
  @Prop collectionPreviewSections: Array<CollectionPreviewSection> = [];
  @Prop dashboardLoading: boolean = false;
  @Prop linksTotal: number = 0;
  @Prop tagsTotal: number = 0;
  @Prop pinnedTotal: number = 0;
  @Prop collectionsCount: number = 0;
  @Prop collectionsCountLabel: string = '0';
  @Prop highlightedLinkId: number = 0;
  @Prop themeMode: ThemeMode = 'system';
  @Prop deviceDarkMode: boolean = false;
  @Prop callbacks: DashboardPanelCallbacks = {} as DashboardPanelCallbacks;

  private palette(): ThemePalette {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  private formatCount(n: number): string {
    if (n >= 1000000) return `${(n / 1000000).toFixed(1)}M`;
    if (n >= 1000) return `${(n / 1000).toFixed(1)}K`;
    return `${n}`;
  }

  build() {
    Column({ space: 10 }) {
      // Shortcut cards
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          this.ShortcutCard($r('app.string.title_links'), 'link', this.formatCount(this.linksTotal), () => {
            this.callbacks.onNavigateAllLinks();
          });
          this.ShortcutCard($r('app.string.title_collections'), 'folder', this.collectionsCountLabel, () => {
            this.callbacks.onNavigateCollections();
          });
        }
        .width('100%');

        Row({ space: 8 }) {
          this.ShortcutCard($r('app.string.title_tags'), 'number', this.formatCount(this.tagsTotal), () => {
            this.callbacks.onNavigateTags();
          });
          this.ShortcutCard($r('app.string.btn_pinned'), 'pin', this.formatCount(this.pinnedTotal), () => {
            this.callbacks.onNavigatePinnedLinks();
          });
        }
        .width('100%');
      }
      .width('100%');

      // Pinned links strip
      this.LinkStripSection(
        '📌 ' + $r('app.string.title_pinned_links'),
        this.pinnedLinks.slice(0, 10),
        $r('app.string.msg_no_pinned_links'),
        () => { this.callbacks.onNavigatePinnedLinks(); }
      );

      // Recent links strip
      this.LinkStripSection(
        '🕘 ' + $r('app.string.title_recent_links'),
        this.dashboardLinks.slice(0, 10),
        this.dashboardLoading && this.dashboardLinks.length === 0 ? $r('app.string.msg_loading_dashboard') : $r('app.string.msg_no_recent_links'),
        () => { this.callbacks.onNavigateRecentLinks(); }
      );

      // Collection previews
      if (this.collectionPreviewSections.length === 0) {
        this.SectionTitle($r('app.string.title_collections'), () => {
          this.callbacks.onNavigateCollections();
        });

        Text($r('app.string.msg_no_collection_previews'))
          .fontSize(13)
          .fontColor(this.palette().textSecondary)
          .width('100%')
          .textAlign(TextAlign.Start);
      } else {
        ForEach(this.collectionPreviewSections, (section: CollectionPreviewSection) => {
          this.CollectionPreview(section);
        }, (section: CollectionPreviewSection) => `dashboard-collection-strip-${section.collection.id}`);
      }
    }
    .width('100%');
  }

  @Builder
  private ShortcutCard(title: string, iconKey: string, value: string, onClick: () => void) {
    Row({ space: 10 }) {
      SymbolGlyph($r('sys.symbol.' + iconKey))
        .fontSize(20)
        .width(28)
        .fontColor(this.palette().textPrimary)
        .textAlign(TextAlign.Center);

      Column({ space: 2 }) {
        Text(title)
          .fontSize(13)
          .fontColor(this.palette().textSecondary)
          .width('100%')
          .textAlign(TextAlign.Start);

        Text(value)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().textPrimary)
          .width('100%')
          .textAlign(TextAlign.Start);
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor(this.palette().card)
    .borderRadius(14)
    .onClick(() => {
      onClick();
    });
  }

  @Builder
  private LinkStripSection(title: string, items: Array<LinkItem>, emptyText: string, onNavigate: () => void) {
    Column({ space: 8 }) {
      this.SectionTitle(title, onNavigate);

      if (items.length === 0) {
        Text(emptyText)
          .fontSize(13)
          .fontColor(this.palette().textSecondary)
          .width('100%')
          .textAlign(TextAlign.Start);
      } else {
        List({ space: 10 }) {
          ForEach(items, (item: LinkItem) => {
            ListItem() {
              this.StripCard(item);
            }
          }, (item: LinkItem) => `${title}-${item.id}`);
        }
        .listDirection(Axis.Horizontal)
        .width('100%')
        .height(140)
        .scrollBar(BarState.Off)
        .nestedScroll({
          scrollForward: NestedScrollMode.PARENT_FIRST,
          scrollBackward: NestedScrollMode.SELF_FIRST,
        });
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }

  @Builder
  private SectionTitle(title: string, onClick: () => void) {
    Row({ space: 8 }) {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Start);

      Button($r('app.string.btn_view_all'))
        .backgroundColor(Color.Transparent)
        .fontColor(this.palette().textSecondary)
        .fontSize(12)
        .borderRadius(999)
        .padding({ left: 2, right: 2, top: 0, bottom: 0 })
        .height(24)
        .onClick(() => {
          onClick();
        });
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private StripCard(item: LinkItem) {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Text(item.name.length > 0 ? item.name : item.url)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().textPrimary)
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Start);

        if (item.pinned) {
          SymbolGlyph($r('sys.symbol.pin_fill'))
            .fontSize(11)
            .fontColor(this.palette().accent);
        }
      }
      .width('100%');

      Text(item.collectionName.length > 0 ? item.collectionName : $r('app.string.unorganized'))
        .fontSize(12)
        .fontColor(item.collectionColor.length > 0 ? item.collectionColor : this.palette().accent)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Start);

      Text(item.url)
        .fontSize(11)
        .fontColor(this.palette().textSecondary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Start);
    }
    .width(260)
    .height(124)
    .padding(12)
    .backgroundColor(this.palette().card)
    .borderRadius(14)
    .alignItems(HorizontalAlign.Start)
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
  private CollectionPreview(section: CollectionPreviewSection) {
    Column({ space: 8 }) {
      this.SectionTitle(section.collection.name.length > 0 ? section.collection.name : $r('app.string.label_untitled'), () => {
        this.callbacks.onNavigateCollection(section.collection.id);
      });

      List({ space: 10 }) {
        ForEach(section.links, (item: LinkItem) => {
          ListItem() {
            this.StripCard(item);
          }
        }, (item: LinkItem) => `collection-strip-${section.collection.id}-${item.id}`);
      }
      .listDirection(Axis.Horizontal)
      .width('100%')
      .height(140)
      .scrollBar(BarState.Off)
      .nestedScroll({
        scrollForward: NestedScrollMode.PARENT_FIRST,
        scrollBackward: NestedScrollMode.SELF_FIRST,
      });
    }
    .width('100%');
  }
}
