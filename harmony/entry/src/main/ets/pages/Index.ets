import type common from '@ohos.app.ability.common';
import pasteboard from '@ohos.pasteboard';
import picker from '@ohos.file.picker';
import { emptyLinkItem, type LinkItem, type CollectionItem, type LinkTag } from '../common/Models';
import type { DashboardTotals } from '../services/LinkwardenApi';
import { BookmarkService } from '../services/BookmarkService';
import { MergeRunner } from '../services/MergeRunner';
import type { MergeProgress, MergeSummary } from '../services/MergeRunner';
import { DEFAULT_INSTANCE_URL, normalizeInstanceUrl } from '../common/Query';
import {
  createDefaultSessionState,
  normalizeThemeMode,
  type SessionMode,
  type ThemeMode,
} from '../common/SessionState';
import { parseBackupEnvelope } from '../services/LocalDatabase';
import type { ImportStrategy, ImportSummary, BackupEnvelope } from '../common/LocalStore';
import { createQuickMenuActions, createThemeOptions, createThemePalette, shouldReturnToDashboard, type MainView, type QuickMenuAction, type ThemeOption } from '../common/UiDesign';
import { SessionStorage } from '../services/SessionStorage';
import { CollectionUsageStorage } from '../services/CollectionUsageStorage';
import {
  collectionUsageScore,
  createDefaultCollectionUsage,
  findCollectionUsageEntry,
  recordCollectionView,
  type CollectionUsageEntry,
  type CollectionUsageState,
} from '../common/CollectionUsage';
import { HostCollectionMemoryStorage } from '../services/HostCollectionMemoryStorage';
import {
  createDefaultHostCollectionMemory,
  pickBestCollectionForHost,
  recordHostChoice,
  type HostCollectionMemoryState,
} from '../common/HostCollectionMemory';
import { consumePendingSharedIntent } from '../common/ShareIntent';
import { extractUrlAndTitle } from '../common/UrlParser';
import { isNetworkError, formatSignInError } from '../common/SessionValidator';
import {
  parseTagsFromInput,
  normalizedTagCandidate,
  appendTagToInput,
  toggleTagInInput,
  tagsIncludingPendingQuery,
  quickTagOptions,
} from '../common/TagParser';
import { writeFileSafe, readFileSafe } from '../common/FileUtils';
import { matchedCollectionByQuery, collectionLabelForQuery } from '../common/CollectionMatcher';
import { SettingsPanelComponent, type SettingsPanelCallbacks } from '../components/SettingsPanelComponent';
import { ThemePickerComponent } from '../components/ThemePickerComponent';
import { DashboardPanelComponent, type DashboardPanelCallbacks, type CollectionPreviewSection } from '../components/DashboardPanelComponent';
import { SearchPanelComponent, type SearchPanelCallbacks } from '../components/SearchPanelComponent';
import { EditLinkOverlayComponent, type EditLinkOverlayCallbacks } from '../components/EditLinkOverlayComponent';
import { AddLinkOverlayComponent, type AddLinkOverlayCallbacks } from '../components/AddLinkOverlayComponent';
import { ElementsPanelComponent, type ElementsPanelCallbacks } from '../components/ElementsPanelComponent';
import { CollectionOverlayComponent, type CollectionOverlayCallbacks, CollectionPickerOverlayComponent, type CollectionPickerOverlayCallbacks } from '../components/CollectionModalsComponent';

type ElementsView = 'links' | 'collections' | 'tags';
type ActiveModal = 'none' | 'add' | 'edit' | 'collection' | 'collection-picker';
type CollectionFormSource = 'add' | 'edit';

interface ScoredCollectionPreview {
  section: CollectionPreviewSection;
  order: number;
  score: number;
}

@Entry
@Component
struct Index {
  @State instance: string = DEFAULT_INSTANCE_URL;
  @State username: string = '';
  @State password: string = '';
  @State token: string = '';
  @State currentUserId: number = 0;
  @State themeMode: ThemeMode = 'system';
  @State sessionMode: SessionMode = 'online';

  @State searchQuery: string = '';
  @State newLinkUrl: string = '';
  @State newLinkTitle: string = '';
  @State newLinkTitleEdited: boolean = false;
  @State newLinkCollectionQuery: string = '';
  @State newLinkTagsInput: string = '';
  @State newTagPickerQuery: string = '';
  @State mainView: MainView = 'dashboard';
  @State elementsView: ElementsView = 'links';
  @State selectedCollectionFilterId: number = 0;
  @State showPinnedOnly: boolean = false;
  @State searchPageQuery: string = '';
  @State collectionSearchQuery: string = '';
  @State tagSearchQuery: string = '';
  @State searchShowAllLinks: boolean = false;
  @State searchShowAllCollections: boolean = false;
  @State searchShowAllTags: boolean = false;

  @State links: Array<LinkItem> = [];
  @State dashboardLinks: Array<LinkItem> = [];
  @State pinnedLinks: Array<LinkItem> = [];
  @State homePreviewLinks: Array<LinkItem> = [];
  @State collections: Array<CollectionItem> = [];
  @State knownTagNames: Array<string> = [];
  @State allTags: Array<LinkTag> = [];
  @State pinnedTotal: number = -1;
  @State tagsTotal: number = -1;
  @State linksTotal: number = -1;
  @State nextCursor: number = 0;
  @State hasMore: boolean = true;

  @State loading: boolean = false;
  @State dashboardLoading: boolean = false;
  @State dashboardRefreshing: boolean = false;
  @State loadingMore: boolean = false;
  @State linksRefreshing: boolean = false;
  @State collectionsRefreshing: boolean = false;
  @State tagsRefreshing: boolean = false;
  @State restoring: boolean = true;
  @State notice: string = '';
  @State noticeIsError: boolean = false;

  @State settingsInstance: string = DEFAULT_INSTANCE_URL;

  @State selectedLink: LinkItem = emptyLinkItem();
  @State detailLoading: boolean = false;
  @State detailSaving: boolean = false;
  @State detailDeleting: boolean = false;
  @State detailFailedLinkId: number = 0;
  @State highlightedLinkId: number = 0;

  @State editName: string = '';
  @State editUrl: string = '';
  @State editDescription: string = '';
  @State editPinned: boolean = false;
  @State editCollectionQuery: string = '';
  @State editTagsInput: string = '';
  @State editTagPickerQuery: string = '';
  @State activeModal: ActiveModal = 'none';
  @State collectionModalReturn: ActiveModal = 'add';
  @State collectionModalSource: CollectionFormSource = 'add';
  @State collectionPickerSource: CollectionFormSource = 'add';
  @State collectionPickerQuery: string = '';
  @State newCollectionName: string = '';
  @State newCollectionDescription: string = '';
  @State newCollectionColor: string = '#2563eb';
  @State newCollectionParentQuery: string = '';
  @State collectionSaving: boolean = false;
  @State pinSaving: boolean = false;
  @State quickMenuOpen: boolean = false;
  @State collectionUsage: CollectionUsageState = createDefaultCollectionUsage();
  @State hostMemory: HostCollectionMemoryState = createDefaultHostCollectionMemory();
  @State lastAddedCollectionId: number = 0;
  @State collectionManuallyPicked: boolean = false;
  @State localSyncRunning: boolean = false;
  @State lastMergeSummary: string = '';
  @State lastMergeHasResult: boolean = false;
  @State syncProgressText: string = '';
  @State importPayload: string = '';
  @State exportingLocal: boolean = false;
  @State importingLocal: boolean = false;
  @State clearingLocal: boolean = false;
  @State localLinkCount: number = 0;
  @State localCollectionCount: number = 0;
  @State previewRaw: string = '';
  @State previewLinkCount: number = 0;
  @State previewCollectionCount: number = 0;
  @State previewTagCount: number = 0;
  @State previewExportedAt: string = '';
  @State previewStrategy: ImportStrategy = 'merge';
  @State previewSource: string = '';
  @State previewVisible: boolean = false;
  @StorageLink('safeAreaTop') safeAreaTop: number = 44;
  @StorageLink('deviceDarkMode') deviceDarkMode: boolean = false;

  private service: BookmarkService = new BookmarkService(DEFAULT_INSTANCE_URL, '', 'online');
  private storage: SessionStorage | null = null;
  private usageStorage: CollectionUsageStorage | null = null;
  private hostMemoryStorage: HostCollectionMemoryStorage | null = null;
  private hasRestoredSession: boolean = false;
  private sharePollTimer: number = -1;
  private noticeTimer: number = -1;
  private searchDebounceTimer: number = -1;

  aboutToAppear(): void {
    console.info('Index aboutToAppear');
    if (this.hasRestoredSession) {
      this.startSharePolling();
      return;
    }

    this.hasRestoredSession = true;
    this.startSharePolling();
    this.storage = new SessionStorage(this.getUIContext().getHostContext()!);
    this.usageStorage = new CollectionUsageStorage(this.getUIContext().getHostContext()!);
    this.hostMemoryStorage = new HostCollectionMemoryStorage(this.getUIContext().getHostContext()!);
    this.restoreSession();
  }

  aboutToDisappear(): void {
    if (this.sharePollTimer >= 0) {
      clearInterval(this.sharePollTimer);
      this.sharePollTimer = -1;
      console.info('Index share poll stopped');
    }

    if (this.noticeTimer >= 0) {
      clearTimeout(this.noticeTimer);
      this.noticeTimer = -1;
    }

    if (this.searchDebounceTimer >= 0) {
      clearTimeout(this.searchDebounceTimer);
      this.searchDebounceTimer = -1;
    }
  }

  onPageShow(): void {
    console.info(`Index onPageShow restoring=${this.restoring}`);
    if (this.restoring) {
      return;
    }

    this.consumeSharedUrlAndMaybeSave().catch((error: Object) => {
      this.setNotice(`Share handling failed: ${this.formatError(error)}`, true);
    });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.restoring) {
          Column({ space: 12 }) {
            Text($r('app.string.msg_restoring'))
              .fontSize(14)
              .fontColor(this.secondaryTextColor())
              .width('100%')
              .textAlign(TextAlign.Start);
          }
          .layoutWeight(1)
          .width('100%')
          .padding({ left: 12, right: 12, top: 20, bottom: 24 });
        } else if (this.token.length === 0 && this.sessionMode !== 'offline') {
          Scroll() {
            Column({ space: 12 }) {
              this.LoginPanel();
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 20, bottom: 24 });
          }
          .layoutWeight(1)
          .width('100%')
          .padding({ top: this.safeAreaTop })
          .scrollBar(BarState.Off);
        } else {
          this.MainPanel();
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.pageColor());

      if (!this.restoring && (this.token.length > 0 || this.sessionMode === 'offline')) {
        Column() {
          Column({ space: 6 }) {
            if (this.mainView === 'dashboard') {
              Column() {
                this.QuickMenuDropdown();
              }
              .scale({ x: this.quickMenuOpen ? 1 : 0.85, y: this.quickMenuOpen ? 1 : 0.85 })
              .opacity(this.quickMenuOpen ? 1 : 0)
              .animation({
                duration: 120,
                curve: Curve.FastOutSlowIn,
              });
              this.QuickMenuButton();
            } else {
              this.HomeButton();
            }
          }
          .alignItems(HorizontalAlign.End);
        }
        .width('100%')
        .alignItems(HorizontalAlign.End)
        .padding({ bottom: 100, right: 20 })
        .hitTestBehavior(HitTestMode.Transparent)
        .zIndex(100)
        .visibility(this.activeModal === 'none' ? Visibility.Visible : Visibility.Hidden)
        .opacity(this.activeModal === 'none' ? 1 : 0)
        .animation({ duration: 200 });
      }

      Column() {
        this.NoticeToast();
      }
      .margin({ bottom: 20 })
      .align(Alignment.Bottom)
      .translate({ y: this.notice.length > 0 ? 0 : 30 })
      .opacity(this.notice.length > 0 ? 1 : 0)
      .animation({
        duration: 150,
        curve: Curve.FastOutSlowIn,
      });

      if (this.activeModal === 'add') {
        AddLinkOverlayComponent({
          visible: this.activeModal === 'add',
          loading: this.loading,
          newLinkUrl: this.newLinkUrl,
          newLinkTitle: this.newLinkTitle,
          newLinkCollectionQuery: this.newLinkCollectionQuery,
          newLinkTagsInput: this.newLinkTagsInput,
          newTagPickerQuery: this.newTagPickerQuery,
          collections: this.collections,
          knownTagNames: this.knownTagNames,
          themeMode: this.themeMode,
          deviceDarkMode: this.deviceDarkMode,
          callbacks: this.addLinkCallbacks(),
        });
      }

      if (this.activeModal === 'edit') {
        EditLinkOverlayComponent({
          visible: this.activeModal === 'edit',
          selectedLink: this.selectedLink,
          detailLoading: this.detailLoading,
          detailSaving: this.detailSaving,
          detailDeleting: this.detailDeleting,
          detailFailedLinkId: this.detailFailedLinkId,
          editName: this.editName,
          editUrl: this.editUrl,
          editDescription: this.editDescription,
          editPinned: this.editPinned,
          editCollectionQuery: this.editCollectionQuery,
          editTagsInput: this.editTagsInput,
          editTagPickerQuery: this.editTagPickerQuery,
          pinSaving: this.pinSaving,
          collections: this.collections,
          knownTagNames: this.knownTagNames,
          themeMode: this.themeMode,
          deviceDarkMode: this.deviceDarkMode,
          callbacks: this.editLinkCallbacks(),
        });
      }

      if (this.activeModal === 'collection') {
        CollectionOverlayComponent({
          visible: this.activeModal === 'collection',
          saving: this.collectionSaving,
          name: this.newCollectionName,
          description: this.newCollectionDescription,
          color: this.newCollectionColor,
          parentQuery: this.newCollectionParentQuery,
          collections: this.collections,
          themeMode: this.themeMode,
          deviceDarkMode: this.deviceDarkMode,
          callbacks: this.collectionOverlayCallbacks(),
        });
      }

      if (this.activeModal === 'collection-picker') {
        CollectionPickerOverlayComponent({
          visible: this.activeModal === 'collection-picker',
          query: this.collectionPickerQuery,
          collections: this.collections,
          selectedId: this.selectedCollectionPickerId(),
          createButtonText: this.collectionCreateButtonText(),
          themeMode: this.themeMode,
          deviceDarkMode: this.deviceDarkMode,
          callbacks: this.collectionPickerCallbacks(),
        });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageColor());
  }

  @Builder
  private LoginPanel() {
    Column({ space: 10 }) {
      this.SectionSubtitle($r('app.string.msg_offline_desc'));

      TextInput({ placeholder: $r('app.string.label_server_url'), text: this.instance })
        .onChange((value: string) => {
          this.instance = value;
        })
        .backgroundColor(this.inputBackgroundColor())
        .fontColor(this.primaryTextColor())
        .borderRadius(12)
        .width('100%');

      TextInput({ placeholder: $r('app.string.label_username'), text: this.username })
        .onChange((value: string) => {
          this.username = value;
        })
        .backgroundColor(this.inputBackgroundColor())
        .fontColor(this.primaryTextColor())
        .borderRadius(12)
        .width('100%');

      TextInput({ placeholder: $r('app.string.label_password'), text: this.password })
        .type(InputType.Password)
        .onChange((value: string) => {
          this.password = value;
        })
        .backgroundColor(this.inputBackgroundColor())
        .fontColor(this.primaryTextColor())
        .borderRadius(12)
        .width('100%');

      ThemePickerComponent({
        themeMode: this.themeMode,
        deviceDarkMode: this.deviceDarkMode,
        handlers: {
          onThemeChange: (mode: ThemeMode) => {
            this.themeMode = mode;
            this.persistSessionState().catch((e: Object) => {
              console.warn('Theme persist failed: ' + String(e));
            });
          },
        },
      });

      Button(this.loading ? $r('app.string.btn_signing_in') : $r('app.string.btn_sign_in'))
        .enabled(!this.loading)
        .width('100%')
        .onClick(() => {
          this.handleSignIn();
        });

      Button($r('app.string.btn_use_offline'))
        .backgroundColor(Color.Transparent)
        .fontColor(this.primaryTextColor())
        .borderColor(this.inputBackgroundColor())
        .borderWidth(1)
        .borderRadius(12)
        .width('100%')
        .onClick(() => {
          this.handleEnterOfflineMode();
        });

      Text($r('app.string.msg_offline_desc'))
        .fontSize(12)
        .fontColor(this.secondaryTextColor())
        .width('100%')
        .textAlign(TextAlign.Start);
    }
    .padding(12)
    .backgroundColor(this.cardColor())
    .borderRadius(12)
    .width('100%');
  }

  @Builder
  private MainPanel() {
    Column({ space: 0 }) {
      Row() {
        Column({ space: 2 }) {
          Text(this.mainViewTitle())
            .fontSize(this.mainView === 'dashboard' ? 24 : 20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryTextColor())
            .width('100%')
            .textAlign(TextAlign.Start);

          Text(this.mainViewSubtitle())
            .fontSize(12)
            .fontColor(this.secondaryTextColor())
            .width('100%')
            .textAlign(TextAlign.Start)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .padding({ right: this.mainView === 'dashboard' ? 60 : 90 });
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 12 });

      if (this.mainView === 'dashboard') {
        Column() {
          Refresh({ refreshing: $$this.dashboardRefreshing }) {
            Scroll() {
              Column({ space: 10 }) {
                DashboardPanelComponent({
              pinnedLinks: this.pinnedLinks,
              dashboardLinks: this.dashboardLinks,
              collectionPreviewSections: this.collectionPreviewSections(),
              dashboardLoading: this.dashboardLoading,
              linksTotal: this.linksTotal,
              tagsTotal: this.tagsTotal,
              pinnedTotal: this.pinnedTotal,
              collectionsCount: this.collections.length,
              collectionsCountLabel: this.formatCollectionsCount(),
              highlightedLinkId: this.highlightedLinkId,
              themeMode: this.themeMode,
              deviceDarkMode: this.deviceDarkMode,
              callbacks: this.dashboardCallbacks(),
            });
              }
              .padding({ left: 12, right: 12, top: 12, bottom: 24 })
              .width('100%');
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off);
          }
          .layoutWeight(1)
          .width('100%')
          .onStateChange((state: RefreshStatus) => {
            if (state === RefreshStatus.Refresh) {
              this.handleDashboardPullRefresh();
            }
          });
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(this.surfaceColor())
        .borderRadius(18);
      } else {
        Column() {
          if (this.mainView === 'elements') {
            ElementsPanelComponent({
              currentTab: this.elementsView,
              links: this.links,
              collections: this.collections,
              filteredCollections: this.filteredCollections(),
              filteredTags: this.filteredTags(),
              loading: this.loading,
              loadingMore: this.loadingMore,
              hasMore: this.hasMore,
              showPinnedOnly: this.showPinnedOnly,
              selectedCollectionFilterId: this.selectedCollectionFilterId,
              activeCollectionName: this.activeCollectionName(),
              searchQuery: this.searchQuery,
              collectionSearchQuery: this.collectionSearchQuery,
              tagSearchQuery: this.tagSearchQuery,
              linksRefreshing: this.linksRefreshing,
              collectionsRefreshing: this.collectionsRefreshing,
              tagsRefreshing: this.tagsRefreshing,
              themeMode: this.themeMode,
              deviceDarkMode: this.deviceDarkMode,
              callbacks: this.elementsCallbacks(),
            });
          } else if (this.mainView === 'search') {
            SearchPanelComponent({
              searchQuery: this.searchPageQuery,
              showAllLinks: this.searchShowAllLinks,
              showAllCollections: this.searchShowAllCollections,
              showAllTags: this.searchShowAllTags,
              filteredLinks: this.filteredLinksForSearch(),
              filteredCollections: this.filteredCollectionsForSearch(),
              filteredTags: this.filteredTagsForSearch(),
              hasAnyResult: this.searchHasAnyResult(),
              highlightedLinkId: this.highlightedLinkId,
              themeMode: this.themeMode,
              deviceDarkMode: this.deviceDarkMode,
              callbacks: this.searchCallbacks(),
            });
          } else {
            SettingsPanelComponent({
              instance: this.instance,
              settingsInstance: this.settingsInstance,
              sessionMode: this.sessionMode,
              token: this.token,
              themeMode: this.themeMode,
              loading: this.loading,
              linksTotal: this.linksTotal,
              tagsTotal: this.tagsTotal,
              pinnedTotal: this.pinnedTotal,
              localLinkCount: this.localLinkCount,
              localCollectionCount: this.localCollectionCount,
              localSyncRunning: this.localSyncRunning,
              syncProgressText: this.syncProgressText,
              exportingLocal: this.exportingLocal,
              importingLocal: this.importingLocal,
              clearingLocal: this.clearingLocal,
              lastMergeHasResult: this.lastMergeHasResult,
              lastMergeSummary: this.lastMergeSummary,
              importPayload: this.importPayload,
              previewVisible: this.previewVisible,
              previewLinkCount: this.previewLinkCount,
              previewCollectionCount: this.previewCollectionCount,
              previewTagCount: this.previewTagCount,
              previewExportedAt: this.previewExportedAt,
              previewStrategy: this.previewStrategy,
              previewSource: this.previewSource,
              deviceDarkMode: this.deviceDarkMode,
              callbacks: this.settingsCallbacks(),
            });
          }
        }
        .layoutWeight(1)
        .padding(12)
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(this.surfaceColor())
        .borderRadius(18);
      }
    }
    .padding({ left: 12, right: 12, top: this.safeAreaTop + 12, bottom: 12 })
    .width('100%')
    .height('100%');
  }


  @Builder
  private QuickMenuButton() {
    Button() {
      SymbolGlyph($r('sys.symbol.ellipsis_circle'))
        .fontSize(24)
        .fontColor([this.accentColor()]);
    }
    .type(ButtonType.Normal)
    .width(48)
    .height(48)
    .padding(0)
    .backgroundColor(this.fabBackgroundColor())
    .border({ width: 1, color: this.fabBorderColor() })
    .borderRadius(999)
    .shadow({ radius: 12, color: this.floatingDockShadowColor(), offsetX: 0, offsetY: 4 })
    .onClick(() => {
      this.quickMenuOpen = !this.quickMenuOpen;
    });
  }

  @Builder
  private HomeButton() {
    Button() {
      SymbolGlyph($r('sys.symbol.house_fill'))
        .fontSize(22)
        .fontColor([this.accentColor()]);
    }
    .type(ButtonType.Normal)
    .width(48)
    .height(48)
    .padding(0)
    .backgroundColor(this.fabBackgroundColor())
    .border({ width: 1, color: this.fabBorderColor() })
    .borderRadius(999)
    .shadow({ radius: 12, color: this.floatingDockShadowColor(), offsetX: 0, offsetY: 4 })
    .onClick(() => {
      this.quickMenuOpen = false;
      this.mainView = 'dashboard';
      this.refreshDashboard();
    });
  }

  @Builder
  private QuickMenuDropdown() {
    Column({ space: 6 }) {
      ForEach(createQuickMenuActions(), (action: QuickMenuAction) => {
        this.QuickMenuItem(action);
      }, (action: QuickMenuAction) => action.id);
    }
    .width(168)
    .padding(8)
    .backgroundColor(this.cardColor())
    .border({ width: 1, color: this.panelBorderColor() })
    .borderRadius(18)
    .shadow({ radius: 18, color: this.floatingDockShadowColor(), offsetX: 0, offsetY: 10 });
  }

  @Builder
  private QuickMenuItem(action: QuickMenuAction) {
    Button() {
      Row({ space: 12 }) {
        SymbolGlyph($r('sys.symbol.' + action.symbolKey))
          .fontSize(18)
          .fontColor([this.accentColor()])
          .width(22)
          .height(22);

        Text(action.label)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primaryTextColor())
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .height(44)
    .padding({ left: 14, right: 14 })
    .backgroundColor(Color.Transparent)
    .borderRadius(12)
    .onClick(() => {
      this.handleQuickMenuAction(action.id);
    });
  }

  @Builder
  private NoticeToast() {
    Row() {
      Text(this.notice)
        .fontSize(13)
        .fontColor('#ffffff')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start);
    }
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .backgroundColor(this.noticeIsError ? '#D14343' : '#1F7A5A')
    .borderRadius(14)
    .shadow({ radius: 12, color: '#33000000', offsetX: 0, offsetY: 6 })
    .constraintSize({ maxWidth: '78%' })
    .margin({ bottom: 28 });
  }






  @Builder
  private SectionTitle(value: Resource | string) {
    Text(value)
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.primaryTextColor())
      .width('100%')
      .textAlign(TextAlign.Start);
  }

  @Builder
  private SectionSubtitle(value: Resource | string) {
    Text(value)
      .fontSize(12)
      .fontColor(this.secondaryTextColor())
      .width('100%')
      .textAlign(TextAlign.Start);
  }


  private mergeTagsFromLinks(links: Array<LinkItem>): void {
    const existingKeys = new Set(this.knownTagNames.map((t) => t.toLowerCase()));
    const additions: Array<string> = [];
    links.forEach((item: LinkItem) => {
      item.tags.forEach((tag) => {
        const value = tag.name.trim();
        if (value.length > 0) {
          const key = value.toLowerCase();
          if (!existingKeys.has(key)) {
            existingKeys.add(key);
            additions.push(value);
          }
        }
      });
    });
    if (additions.length > 0) {
      this.knownTagNames = [...this.knownTagNames, ...additions].sort((a, b) =>
        a.toLowerCase().localeCompare(b.toLowerCase())
      );
    }
  }

  private mergeTagNamesFromTags(tags: Array<LinkTag>): void {
    const names = tags
      .map((tag) => tag.name.trim())
      .filter((name) => name.length > 0);
    const existingKeys = new Set(this.knownTagNames.map((t) => t.toLowerCase()));
    const additions: Array<string> = [];
    names.forEach((name) => {
      const key = name.toLowerCase();
      if (!existingKeys.has(key)) {
        existingKeys.add(key);
        additions.push(name);
      }
    });
    if (additions.length > 0) {
      this.knownTagNames = [...this.knownTagNames, ...additions].sort((a, b) =>
        a.toLowerCase().localeCompare(b.toLowerCase())
      );
    }
  }

  private uniqueTags(): Array<string> {
    return this.knownTagNames;
  }

  private formatCount(value: number): string {
    return value < 0 ? '–' : `${value}`;
  }

  private formatCollectionsCount(): string {
    if (this.collections.length > 0) {
      return `${this.collections.length}`;
    }
    return this.dashboardLoading ? '–' : '0';
  }

  private activeCollectionName(): string {
    const id = this.selectedCollectionFilterId;
    const matches = this.collections.filter((c: CollectionItem) => c.id === id);
    return matches.length > 0 ? matches[0].name : `Collection #${id}`;
  }

  private filteredCollections(): Array<CollectionItem> {
    const query = this.collectionSearchQuery.trim().toLowerCase();
    if (query.length === 0) {
      return this.collections;
    }

    return this.collections.filter((item) => item.name.toLowerCase().indexOf(query) >= 0);
  }

  private filteredTags(): Array<string> {
    const query = this.tagSearchQuery.trim().toLowerCase();
    const tags = this.uniqueTags();
    if (query.length === 0) {
      return tags;
    }

    return tags.filter((tag) => tag.indexOf(query) >= 0);
  }

  private filteredLinksForSearch(): Array<LinkItem> {
    const query = this.searchPageQuery.trim().toLowerCase();
    if (query.length === 0) {
      return [];
    }

    return this.links.filter((item) => {
      const inTitle = item.name.toLowerCase().indexOf(query) >= 0;
      const inUrl = item.url.toLowerCase().indexOf(query) >= 0;
      const inDesc = item.description.toLowerCase().indexOf(query) >= 0;
      const inTags = item.tags.some((tag) => tag.name.toLowerCase().indexOf(query) >= 0);
      return inTitle || inUrl || inDesc || inTags;
    });
  }

  private filteredCollectionsForSearch(): Array<CollectionItem> {
    const query = this.searchPageQuery.trim().toLowerCase();
    if (query.length === 0) {
      return [];
    }

    return this.collections.filter((item) => item.name.toLowerCase().indexOf(query) >= 0);
  }

  private filteredTagsForSearch(): Array<string> {
    const query = this.searchPageQuery.trim().toLowerCase();
    if (query.length === 0) {
      return [];
    }

    return this.uniqueTags().filter((tag) => tag.indexOf(query) >= 0);
  }

  private searchHasAnyResult(): boolean {
    return this.filteredLinksForSearch().length > 0
      || this.filteredCollectionsForSearch().length > 0
      || this.filteredTagsForSearch().length > 0;
  }

  private floatingDockShadowColor(): string {
    return this.themePalette().dockShadow;
  }

  private handleQuickMenuAction(actionId: 'add' | 'search' | 'settings'): void {
    this.quickMenuOpen = false;

    if (actionId === 'add') {
      this.openAddModal();
      return;
    }

    if (actionId === 'search') {
      this.mainView = 'search';
      this.refreshLinks(true);
      this.refreshDashboard();
      return;
    }

    this.mainView = 'settings';
    this.settingsInstance = this.instance;
    this.refreshLocalCounts();
  }

  private mainViewTitle(): Resource {
    if (this.mainView === 'dashboard') {
      return $r('app.string.nav_home');
    }

    if (this.mainView === 'elements') {
      return $r('app.string.nav_library');
    }

    if (this.mainView === 'search') {
      return $r('app.string.nav_search');
    }

    return $r('app.string.nav_menu');
  }

  private mainViewSubtitle(): Resource {
    if (this.mainView === 'dashboard') {
      return $r('app.string.subtitle_home');
    }

    if (this.mainView === 'elements') {
      return $r('app.string.subtitle_library');
    }

    if (this.mainView === 'search') {
      return $r('app.string.subtitle_search');
    }

    return $r('app.string.subtitle_menu');
  }

  private handleNewLinkUrlChange(value: string): void {
    this.newLinkUrl = value;
    if (!this.newLinkTitleEdited) {
      this.newLinkTitle = extractUrlAndTitle(value).title;
    }
    this.maybeAutoPickCollection();
  }

  private handleNewLinkTitleChange(value: string): void {
    this.newLinkTitle = value;
    this.newLinkTitleEdited = value.trim().length > 0;
  }

  private draftHasResolvedUrl(): boolean {
    return extractUrlAndTitle(this.newLinkUrl).url.length > 0;
  }

  private detectedUrlSummaryText(): string {
    const parsed = extractUrlAndTitle(this.newLinkUrl);
    if (parsed.url.length === 0) {
      return 'No valid URL detected yet.';
    }

    return `Detected URL: ${parsed.url}`;
  }

  private matchedDraftCollection(): CollectionItem | null {
    return matchedCollectionByQuery(this.collections, this.newLinkCollectionQuery);
  }

  private draftCollectionMatches(): Array<CollectionItem> {
    const query = this.newLinkCollectionQuery.trim().toLowerCase();
    if (query.length === 0) {
      return [];
    }

    return this.collections.filter((item) => item.name.toLowerCase().indexOf(query) >= 0);
  }

  private detectedCollectionSummaryText(): string {
    const matchedCollection = this.matchedDraftCollection();
    if (matchedCollection === null) {
      return 'No matching collection found.';
    }

    return `Matched collection: ${matchedCollection.name}`;
  }

  private parsedDraftTags(): Array<string> {
    return parseTagsFromInput(this.newLinkTagsInput);
  }

  private matchedEditCollection(): CollectionItem | null {
    return matchedCollectionByQuery(this.collections,this.editCollectionQuery);
  }

  private editCollectionMatches(): Array<CollectionItem> {
    const query = this.editCollectionQuery.trim().toLowerCase();
    if (query.length === 0) {
      return [];
    }

    return this.collections.filter((item) => item.name.toLowerCase().indexOf(query) >= 0);
  }

  private matchedParentCollection(): CollectionItem | null {
    return matchedCollectionByQuery(this.collections,this.newCollectionParentQuery);
  }

  private detectedParentCollectionSummaryText(): string {
    const matchedCollection = this.matchedParentCollection();
    if (matchedCollection === null) {
      return 'No matching parent collection found.';
    }

    return `Parent collection: ${matchedCollection.name}`;
  }

  private detectedEditCollectionSummaryText(): string {
    const matchedCollection = this.matchedEditCollection();
    if (matchedCollection === null) {
      return 'No matching collection found.';
    }

    return `Matched collection: ${matchedCollection.name}`;
  }

  private parsedEditTags(): Array<string> {
    return parseTagsFromInput(this.editTagsInput);
  }

  private draftTagSummaryText(): string {
    return this.tagSummaryText(this.resolvedDraftTags());
  }

  private editTagSummaryText(): string {
    return this.tagSummaryText(this.resolvedEditTags());
  }

  private resolvedDraftTags(): Array<string> {
    return tagsIncludingPendingQuery(this.newLinkTagsInput, this.newTagPickerQuery);
  }

  private resolvedEditTags(): Array<string> {
    return tagsIncludingPendingQuery(this.editTagsInput, this.editTagPickerQuery);
  }

  private handleDraftTagToggle(tag: string): void {
    this.newLinkTagsInput = toggleTagInInput(this.newLinkTagsInput, tag);
  }

  private handleEditTagToggle(tag: string): void {
    this.editTagsInput = toggleTagInInput(this.editTagsInput, tag);
  }

  private collectionLabelForQuery(rawQuery: string): string {
    return collectionLabelForQuery(this.collections, rawQuery);
  }

  private collectionHintForQuery(rawQuery: string): string {
    const query = rawQuery.trim();
    if (query.length === 0) {
      return 'No collection will be assigned.';
    }

    const matched = matchedCollectionByQuery(this.collections,query);
    if (matched !== null) {
      return matched.parentName.length > 0 ? `Inside ${matched.parentName}` : 'Existing collection';
    }

    return 'Not matched yet. Use picker to select or create it.';
  }

  private filteredCollectionsForPicker(): Array<CollectionItem> {
    const query = this.collectionPickerQuery.trim().toLowerCase();
    if (query.length === 0) {
      return this.collections;
    }

    return this.collections.filter((item) => item.name.toLowerCase().indexOf(query) >= 0);
  }

  private selectedCollectionPickerId(): number {
    const currentQuery = this.collectionPickerSource === 'add'
      ? this.newLinkCollectionQuery
      : this.editCollectionQuery;
    const matched = matchedCollectionByQuery(this.collections,currentQuery);
    if (matched !== null) {
      return matched.id;
    }

    return currentQuery.trim().length === 0 ? 0 : -1;
  }

  private collectionPickerItemHint(item: CollectionItem): string {
    if (item.parentName.length > 0) {
      return `${item.linkCount} links · Parent: ${item.parentName}`;
    }

    return `${item.linkCount} links`;
  }

  private collectionCreateButtonText(): string {
    const candidate = this.collectionPickerQuery.trim();
    return candidate.length > 0 ? `New "${candidate}"` : 'New Collection';
  }

  private openCollectionPicker(source: CollectionFormSource): void {
    this.collectionPickerSource = source;
    this.collectionPickerQuery = '';
    this.activeModal = 'collection-picker';
  }

  private selectCollectionFromPicker(collection: CollectionItem | null): void {
    if (this.collectionPickerSource === 'add') {
      this.newLinkCollectionQuery = collection === null ? '' : collection.name;
      this.collectionManuallyPicked = true;
      this.activeModal = 'add';
      return;
    }

    this.editCollectionQuery = collection === null ? '' : collection.name;
    this.activeModal = 'edit';
  }

  private openCollectionCreateFromPicker(): void {
    if (this.collectionPickerSource === 'add') {
      this.newLinkCollectionQuery = this.collectionPickerQuery.trim();
    } else {
      this.editCollectionQuery = this.collectionPickerQuery.trim();
    }

    this.openCollectionModal(this.collectionPickerSource);
  }

  private tagSummaryText(tags: Array<string>): string {
    if (tags.length === 0) {
      return '';
    }

    const existingTags = this.uniqueTags();
    const newTags = tags.filter((tag) => !existingTags.some((item) => item.toLowerCase() === tag.toLowerCase()));
    if (newTags.length === 0) {
      return 'All tags already exist.';
    }

    return `Will create: ${newTags.map((tag) => `#${tag}`).join(' ')}`;
  }

  private clearNewLinkDraft(): void {
    this.newLinkUrl = '';
    this.newLinkTitle = '';
    this.newLinkTitleEdited = false;
    this.newLinkCollectionQuery = '';
    this.newLinkTagsInput = '';
    this.newTagPickerQuery = '';
    this.collectionManuallyPicked = false;
  }

  private resetCollectionDraft(): void {
    this.newCollectionName = '';
    this.newCollectionDescription = '';
    this.newCollectionColor = '#2563eb';
    this.newCollectionParentQuery = '';
  }

  private applyNewLinkDraft(url: string, title: string = ''): void {
    this.newLinkUrl = url;
    this.newLinkTitle = title.length > 0 ? title : extractUrlAndTitle(url).title;
    this.newLinkTitleEdited = false;
    this.newLinkCollectionQuery = '';
    this.newLinkTagsInput = '';
    this.newTagPickerQuery = '';
    this.collectionManuallyPicked = false;
    this.maybeAutoPickCollection();
  }

  private navigateToCollection(collectionId: number): void {
    this.recordCollectionViewUsage(collectionId);
    this.mainView = 'elements';
    this.elementsView = 'links';
    this.selectedCollectionFilterId = collectionId;
    this.showPinnedOnly = false;
    this.refreshLinks(true);
  }

  private recordCollectionViewUsage(collectionId: number): void {
    if (collectionId <= 0) {
      return;
    }
    this.collectionUsage = recordCollectionView(this.collectionUsage, collectionId, Date.now());
    this.persistCollectionUsage();
  }

  private async persistCollectionUsage(): Promise<void> {
    if (this.usageStorage === null) {
      this.usageStorage = new CollectionUsageStorage(this.getUIContext().getHostContext()!);
    }
    try {
      await this.usageStorage.save(this.collectionUsage);
    } catch (error) {
      console.warn(`persist collection usage failed: ${this.formatError(error)}`);
    }
  }

  private maybeAutoPickCollection(): void {
    if (this.collectionManuallyPicked) {
      return;
    }
    if (this.newLinkCollectionQuery.trim().length > 0) {
      return;
    }
    const urlCandidate = extractUrlAndTitle(this.newLinkUrl).url;
    const predictedId = this.predictCollectionForUrl(urlCandidate);
    if (predictedId === 0) {
      return;
    }
    const collection = this.collections.find((item: CollectionItem) => item.id === predictedId);
    if (collection === undefined) {
      return;
    }
    this.newLinkCollectionQuery = collection.name;
  }

  private predictCollectionForUrl(url: string): number {
    const now: number = Date.now();
    if (url.length > 0) {
      const hostPick: number = pickBestCollectionForHost(this.hostMemory, url, now);
      if (hostPick > 0 && this.collections.some((item: CollectionItem) => item.id === hostPick)) {
        return hostPick;
      }
    }

    if (this.lastAddedCollectionId !== 0 && this.collections.some((item: CollectionItem) => item.id === this.lastAddedCollectionId)) {
      return this.lastAddedCollectionId;
    }

    let bestId: number = 0;
    let bestScore: number = 0;
    this.collectionUsage.entries.forEach((entry: CollectionUsageEntry) => {
      if (!this.collections.some((item: CollectionItem) => item.id === entry.collectionId)) {
        return;
      }
      const score: number = collectionUsageScore(entry, now);
      if (score > bestScore) {
        bestScore = score;
        bestId = entry.collectionId;
      }
    });
    return bestId;
  }

  private async persistHostMemory(): Promise<void> {
    if (this.hostMemoryStorage === null) {
      this.hostMemoryStorage = new HostCollectionMemoryStorage(this.getUIContext().getHostContext()!);
    }
    try {
      await this.hostMemoryStorage.save(this.hostMemory);
    } catch (error) {
      console.warn(`persist host memory failed: ${this.formatError(error)}`);
    }
  }

  private navigateToAllLinks(): void {
    this.mainView = 'elements';
    this.elementsView = 'links';
    this.selectedCollectionFilterId = 0;
    this.showPinnedOnly = false;
    this.refreshLinks(true);
  }

  private navigateToPinnedLinks(): void {
    this.mainView = 'elements';
    this.elementsView = 'links';
    this.selectedCollectionFilterId = 0;
    this.showPinnedOnly = true;
    this.refreshLinks(true);
  }

  private navigateToCollections(): void {
    this.mainView = 'elements';
    this.elementsView = 'collections';
    this.collectionSearchQuery = '';
    this.refreshDashboard();
  }

  private navigateToTags(): void {
    this.mainView = 'elements';
    this.elementsView = 'tags';
    this.tagSearchQuery = '';
  }

  private navigateToTag(tag: string): void {
    this.mainView = 'elements';
    this.elementsView = 'links';
    this.selectedCollectionFilterId = 0;
    this.showPinnedOnly = false;
    this.searchQuery = `#${tag}`;
    this.refreshLinks(true);
  }

  private navigateToRecentLinks(): void {
    this.mainView = 'elements';
    this.elementsView = 'links';
    this.selectedCollectionFilterId = 0;
    this.showPinnedOnly = false;
    this.refreshLinks(true);
  }

  private openAddModal(): void {
    this.quickMenuOpen = false;
    this.newTagPickerQuery = '';
    this.collectionManuallyPicked = false;
    this.maybeAutoPickCollection();
    this.activeModal = 'add';
  }

  private openCollectionModal(source: CollectionFormSource): void {
    this.collectionModalSource = source;
    this.collectionModalReturn = source === 'add' ? 'add' : 'edit';
    this.resetCollectionDraft();
    this.newCollectionName = source === 'add' ? this.newLinkCollectionQuery.trim() : this.editCollectionQuery.trim();
    this.activeModal = 'collection';
  }

  private closeCurrentModal(): void {
    if (this.activeModal === 'collection') {
      this.activeModal = this.collectionModalReturn;
      return;
    }

    if (this.activeModal === 'collection-picker') {
      this.activeModal = this.collectionPickerSource === 'add' ? 'add' : 'edit';
      return;
    }

    this.activeModal = 'none';
  }

  private collectionPreviewSections(): Array<CollectionPreviewSection> {
    const grouped: Array<CollectionPreviewSection> = [];

    this.collections.forEach((collection: CollectionItem) => {
      const links = this.homePreviewLinks
        .filter((item: LinkItem) => item.collectionId === collection.id)
        .slice(0, 10);

      if (links.length > 0) {
        grouped.push({ collection, links });
      }
    });

    const now: number = Date.now();
    const usage: CollectionUsageState = this.collectionUsage;
    const ranked: Array<ScoredCollectionPreview> = [];
    for (let i: number = 0; i < grouped.length; i++) {
      const section: CollectionPreviewSection = grouped[i];
      const entry: CollectionUsageEntry | null = findCollectionUsageEntry(usage, section.collection.id);
      ranked.push({
        section,
        order: i,
        score: collectionUsageScore(entry, now),
      });
    }
    ranked.sort((a: ScoredCollectionPreview, b: ScoredCollectionPreview) => {
      if (a.score !== b.score) {
        return b.score - a.score;
      }
      return a.order - b.order;
    });
    const sorted: Array<CollectionPreviewSection> = ranked.map(
      (item: ScoredCollectionPreview) => item.section,
    );

    const unorganizedLinks = this.homePreviewLinks
      .filter((item: LinkItem) => item.collectionId === 0)
      .slice(0, 10);

    if (unorganizedLinks.length > 0) {
      sorted.push({
        collection: {
          id: 0,
          ownerId: 0,
          name: 'Unorganized',
          description: '',
          color: '',
          parentId: 0,
          parentName: '',
          linkCount: unorganizedLinks.length,
        },
        links: unorganizedLinks,
      });
    }

    return sorted;
  }

  private tabActiveColor(): string {
    return this.themePalette().accentStrong;
  }

  private tabActiveTextColor(): string {
    return '#ffffff';
  }

  private surfaceColor(): string {
    return this.themePalette().surface;
  }

  private pageColor(): string {
    return this.themePalette().page;
  }

  private cardColor(): string {
    return this.themePalette().card;
  }

  private selectedCardColor(): string {
    return this.themePalette().cardSelected;
  }

  private newlyAddedCardColor(): string {
    return this.themePalette().cardSuccess;
  }

  private primaryTextColor(): string {
    return this.themePalette().textPrimary;
  }

  private secondaryTextColor(): string {
    return this.themePalette().textSecondary;
  }

  private accentColor(): string {
    return this.themePalette().accent;
  }

  private dangerColor(): string {
    return this.themePalette().danger;
  }

  private panelBorderColor(): string {
    return this.themePalette().border;
  }

  private inputBackgroundColor(): string {
    return this.themePalette().input;
  }

  private primaryActionBackgroundColor(): string {
    return this.isDarkTheme() ? this.tabActiveColor() : this.themePalette().accentStrong;
  }

  private primaryActionTextColor(): string {
    return '#ffffff';
  }

  private primaryActionShadowColor(): string {
    return this.isDarkTheme() ? '#30000000' : '#1f2563eb';
  }

  private fabBackgroundColor(): string {
    return this.cardColor();
  }

  private fabIconColor(): string {
    return this.accentColor();
  }

  private fabBorderColor(): string {
    return this.themePalette().border;
  }

  private secondaryActionBackgroundColor(): string {
    return this.themePalette().accentSoft;
  }

  private secondaryActionTextColor(): string {
    return this.accentColor();
  }

  private themeModeLabel(): string {
    if (this.themeMode === 'dark') {
      return 'Dark';
    }

    if (this.themeMode === 'light') {
      return 'Light';
    }

    return 'System';
  }

  private isThemeOptionSelected(mode: ThemeMode): boolean {
    return this.themeMode === mode;
  }

  private collectionOverlayCallbacks(): CollectionOverlayCallbacks {
    return {
      onClose: () => this.closeCurrentModal(),
      onCreate: () => this.handleCreateCollection(),
      onReset: () => this.resetCollectionDraft(),
      onNameChange: (v: string) => { this.newCollectionName = v; },
      onDescriptionChange: (v: string) => { this.newCollectionDescription = v; },
      onParentQueryChange: (v: string) => { this.newCollectionParentQuery = v; },
      onColorChange: (c: string) => { this.newCollectionColor = c; },
    };
  }

  private collectionPickerCallbacks(): CollectionPickerOverlayCallbacks {
    return {
      onClose: () => this.closeCurrentModal(),
      onSelect: (collection: CollectionItem | null) => this.selectCollectionFromPicker(collection),
      onCreateNew: () => this.openCollectionCreateFromPicker(),
      onQueryChange: (v: string) => { this.collectionPickerQuery = v; },
    };
  }

  private elementsCallbacks(): ElementsPanelCallbacks {
    return {
      onTabChange: (tab: string) => { this.elementsView = tab as ElementsView; },
      onRefreshLinks: () => this.refreshLinks(true),
      onRefreshDashboard: () => this.refreshDashboard(),
      onAddLink: () => this.openAddModal(),
      onPinnedFilterToggle: () => {
        this.selectedCollectionFilterId = 0;
        this.showPinnedOnly = !this.showPinnedOnly;
        this.refreshLinks(true);
      },
      onSearchQueryChange: (query: string) => {
        this.searchQuery = query;
        if (this.searchDebounceTimer >= 0) {
          clearTimeout(this.searchDebounceTimer);
        }
        this.searchDebounceTimer = setTimeout(() => {
          this.searchDebounceTimer = -1;
          this.refreshLinks(true);
        }, 300);
      },
      onCollectionFilterClear: () => {
        this.selectedCollectionFilterId = 0;
        this.refreshLinks(true);
      },
      onCollectionSearchChange: (query: string) => { this.collectionSearchQuery = query; },
      onTagSearchChange: (query: string) => { this.tagSearchQuery = query; },
      onLinkClick: (item: LinkItem) => {
        this.recordCollectionViewUsage(item.collectionId);
        this.openLinkInBrowser(item.url);
      },
      onLinkLongPress: (item: LinkItem) => this.handleLinkLongPress(item),
      onCollectionClick: (id: number) => this.navigateToCollection(id),
      onTagClick: (tag: string) => this.navigateToTag(tag),
      onLoadMore: () => this.refreshLinks(false),
      onRecordCollectionView: (id: number) => this.recordCollectionViewUsage(id),
      onOpenLink: (url: string) => this.openLinkInBrowser(url),
      onPullRefreshLinks: () => this.handleLibraryLinksPullRefresh(),
      onPullRefreshCollections: () => this.handleLibraryCollectionsPullRefresh(),
      onPullRefreshTags: () => this.handleLibraryTagsPullRefresh(),
    };
  }

  private addLinkCallbacks(): AddLinkOverlayCallbacks {
    return {
      onClose: () => this.closeCurrentModal(),
      onAdd: () => this.handleAddLink(),
      onOpenCollectionPicker: () => this.openCollectionPicker('add'),
      onUrlChange: (v: string) => this.handleNewLinkUrlChange(v),
      onTitleChange: (v: string) => this.handleNewLinkTitleChange(v),
      onCollectionQueryChange: (v: string) => { this.newLinkCollectionQuery = v; },
      onTagsInputChange: (v: string) => { this.newLinkTagsInput = v; },
      onTagPickerQueryChange: (v: string) => { this.newTagPickerQuery = v; },
      onTagToggle: (tag: string) => this.handleDraftTagToggle(tag),
    };
  }

  private editLinkCallbacks(): EditLinkOverlayCallbacks {
    return {
      onClose: () => this.closeCurrentModal(),
      onSave: () => this.handleSaveLink(),
      onDelete: () => this.handleDeleteLink(),
      onRetry: () => this.handleSelectLink(this.detailFailedLinkId),
      onTogglePin: () => this.handleTogglePin(),
      onOpenCollectionPicker: () => this.openCollectionPicker('edit'),
      onEditNameChange: (v: string) => { this.editName = v; },
      onEditUrlChange: (v: string) => { this.editUrl = v; },
      onEditDescriptionChange: (v: string) => { this.editDescription = v; },
      onEditCollectionQueryChange: (v: string) => { this.editCollectionQuery = v; },
      onEditTagsInputChange: (v: string) => { this.editTagsInput = v; },
      onEditTagPickerQueryChange: (v: string) => { this.editTagPickerQuery = v; },
      onEditTagToggle: (tag: string) => this.handleEditTagToggle(tag),
    };
  }

  private searchCallbacks(): SearchPanelCallbacks {
    return {
      onSearchQueryChange: (query: string) => {
        this.searchPageQuery = query;
        this.searchShowAllLinks = false;
        this.searchShowAllCollections = false;
        this.searchShowAllTags = false;
      },
      onSearch: () => {
        this.refreshLinks(true);
        this.refreshDashboard();
      },
      onToggleShowAllLinks: () => { this.searchShowAllLinks = !this.searchShowAllLinks; },
      onToggleShowAllCollections: () => { this.searchShowAllCollections = !this.searchShowAllCollections; },
      onToggleShowAllTags: () => { this.searchShowAllTags = !this.searchShowAllTags; },
      onLinkClick: (item: LinkItem) => {
        this.recordCollectionViewUsage(item.collectionId);
        this.openLinkInBrowser(item.url);
      },
      onLinkLongPress: (item: LinkItem) => this.handleLinkLongPress(item),
      onCollectionClick: (id: number) => this.navigateToCollection(id),
      onTagClick: (tag: string) => this.navigateToTag(tag),
      onRecordCollectionView: (id: number) => this.recordCollectionViewUsage(id),
      onOpenLink: (url: string) => this.openLinkInBrowser(url),
    };
  }

  private dashboardCallbacks(): DashboardPanelCallbacks {
    return {
      onNavigateAllLinks: () => this.navigateToAllLinks(),
      onNavigatePinnedLinks: () => this.navigateToPinnedLinks(),
      onNavigateRecentLinks: () => this.navigateToRecentLinks(),
      onNavigateCollections: () => this.navigateToCollections(),
      onNavigateTags: () => this.navigateToTags(),
      onNavigateCollection: (id: number) => this.navigateToCollection(id),
      onOpenLink: (url: string) => this.openLinkInBrowser(url),
      onLinkLongPress: (item: LinkItem) => this.handleLinkLongPress(item),
      onRecordCollectionView: (id: number) => this.recordCollectionViewUsage(id),
    };
  }

  private settingsCallbacks(): SettingsPanelCallbacks {
    return {
      onSaveSettings: () => this.handleSaveSettings(),
      onSignOut: () => this.handleSignOut(),
      onSwitchToOffline: () => this.handleSwitchToOffline(),
      onResumeOnline: () => this.handleResumeOnline(),
      onConnectToLinkwarden: () => this.handleConnectToLinkwarden(),
      onExportLocal: () => this.handleExportLocal(),
      onExportToFile: () => this.handleExportToFile(),
      onImportFromFile: (s: string) => this.handleImportFromFile(s as ImportStrategy),
      onImportLocal: (s: string) => this.handleImportLocal(s as ImportStrategy),
      onClearLocal: () => this.handleClearLocal(),
      onConfirmPreview: () => this.handleConfirmPreview(),
      onCancelPreview: () => this.handleCancelPreview(),
      onSyncLocalToServer: () => this.handleSyncLocalToServer(),
      onMergeArchiveKeep: () => this.handleMergeArchiveKeep(),
      onMergeArchiveClear: () => this.handleMergeArchiveClear(),
      onOpenLink: (url: string) => this.openLinkInBrowser(url),
      onSettingsInstanceChange: (v: string) => { this.settingsInstance = v; },
      onImportPayloadChange: (v: string) => { this.importPayload = v; },
      onThemeChange: (mode: ThemeMode) => {
        this.themeMode = mode;
        this.persistSessionState().catch((e: Object) => {
          console.warn('Theme persist failed: ' + String(e));
        });
      },
    };
  }

  private themePalette() {
    const effectiveMode: ThemeMode =
      (this.themeMode === 'system' && this.deviceDarkMode) ? 'dark' : this.themeMode;
    return createThemePalette(effectiveMode);
  }

  private isDarkTheme(): boolean {
    return this.themeMode === 'dark' || (this.themeMode === 'system' && this.deviceDarkMode);
  }

  private syncApiContext(): void {
    this.instance = normalizeInstanceUrl(this.instance);
    this.service.setInstance(this.instance);
    this.service.setToken(this.token);
    this.service.setMode(this.sessionMode);
    this.settingsInstance = this.instance;

    this.service.onlineClient().onUnauthorized = () => {
      this.token = '';
      this.sessionMode = 'offline';
      this.service.setMode('offline');
      this.persistSessionState();
      this.setNotice('Session expired. Switched to offline mode.', true);
    };
  }

  onBackPress(): boolean {
    if (this.quickMenuOpen) {
      this.quickMenuOpen = false;
      return true;
    }

    if (this.activeModal !== 'none') {
      this.closeCurrentModal();
      return true;
    }

    if (shouldReturnToDashboard(this.mainView)) {
      this.mainView = 'dashboard';
      this.refreshDashboard();
      return true;
    }

    return false;
  }

  private async ensureCurrentUserId(): Promise<void> {
    if (this.sessionMode === 'offline') {
      this.currentUserId = 0;
      return;
    }
    if (this.currentUserId > 0) {
      return;
    }

    this.syncApiContext();
    this.currentUserId = await this.service.fetchCurrentUserId();
  }

  private async restoreSession(): Promise<void> {
    const fallback = createDefaultSessionState();

    try {
      if (this.storage === null) {
        this.storage = new SessionStorage(this.getUIContext().getHostContext()!);
      }

      await this.service.attachContext(this.getUIContext().getHostContext()!);

      const state = await this.storage.load();
      this.instance = normalizeInstanceUrl(state.instance);
      this.settingsInstance = this.instance;
      this.token = state.token;
      this.currentUserId = 0;
      this.themeMode = normalizeThemeMode(state.theme);
      this.sessionMode = state.mode;
      this.syncApiContext();

      if (this.usageStorage === null) {
        this.usageStorage = new CollectionUsageStorage(this.getUIContext().getHostContext()!);
      }
      try {
        this.collectionUsage = await this.usageStorage.load();
      } catch (usageError) {
        this.collectionUsage = createDefaultCollectionUsage();
      }

      if (this.hostMemoryStorage === null) {
        this.hostMemoryStorage = new HostCollectionMemoryStorage(this.getUIContext().getHostContext()!);
      }
      try {
        this.hostMemory = await this.hostMemoryStorage.load();
      } catch (memoryError) {
        this.hostMemory = createDefaultHostCollectionMemory();
      }

      try {
        this.lastAddedCollectionId = await this.storage.loadLastAddedCollectionId();
      } catch (_) {
        this.lastAddedCollectionId = 0;
      }

      if (this.sessionMode === 'offline') {
        await Promise.all([this.refreshLinks(true), this.refreshDashboard()]);
        await this.consumeSharedUrlAndMaybeSave();
        if (this.notice.length === 0) {
          this.setNotice('Offline mode — data stays on this device.', false);
        }
      } else if (this.token.length > 0) {
        await this.ensureCurrentUserId();
        await Promise.all([this.refreshLinks(true), this.refreshDashboard()]);
        await this.consumeSharedUrlAndMaybeSave();

        if (this.notice.length === 0) {
          this.setNotice('Session restored.', false);
        }
      }

      await this.refreshLocalCounts();
    } catch (error) {
      this.instance = fallback.instance;
      this.settingsInstance = fallback.instance;
      this.token = fallback.token;
      this.currentUserId = 0;
      this.themeMode = fallback.theme;
      this.sessionMode = fallback.mode;
      this.setNotice(`Restore failed: ${this.formatError(error)}`, true);
    } finally {
      this.restoring = false;
    }
  }

  private async persistSessionState(): Promise<void> {
    if (this.storage === null) {
      this.storage = new SessionStorage(this.getUIContext().getHostContext()!);
    }

    await this.storage.save({
      instance: normalizeInstanceUrl(this.instance),
      token: this.token,
      theme: this.themeMode,
      mode: this.sessionMode,
    });
  }

  private applySelectedLink(link: LinkItem): void {
    this.selectedLink = link;
    this.editName = link.name;
    this.editUrl = link.url;
    this.editDescription = link.description;
    this.editPinned = link.pinned;
    this.editCollectionQuery = link.collectionName;
    this.editTagsInput = link.tags.map((tag) => tag.name).join(', ');
    this.editTagPickerQuery = '';
  }

  private clearSelectedLink(): void {
    this.selectedLink = emptyLinkItem();
    this.editName = '';
    this.editUrl = '';
    this.editDescription = '';
    this.editPinned = false;
    this.editCollectionQuery = '';
    this.editTagsInput = '';
    this.editTagPickerQuery = '';
    this.detailLoading = false;
    this.detailSaving = false;
    this.detailFailedLinkId = 0;
    this.detailDeleting = false;
    this.pinSaving = false;
  }

  private markLinkAsRecentlyAdded(linkId: number): void {
    this.highlightedLinkId = linkId > 0 ? linkId : 0;
  }

  private replaceLinkInList(link: LinkItem): void {
    this.links = this.links.map((item: LinkItem) => {
      if (item.id === link.id) {
        return link;
      }

      return item;
    });
    this.homePreviewLinks = this.homePreviewLinks.map((item: LinkItem) => item.id === link.id ? link : item);
    this.dashboardLinks = this.dashboardLinks.map((item: LinkItem) => item.id === link.id ? link : item);
    this.pinnedLinks = this.pinnedLinks.map((item: LinkItem) => item.id === link.id ? link : item);
    if (link.pinned) {
      const exists = this.pinnedLinks.some((item: LinkItem) => item.id === link.id);
      if (!exists) {
        this.pinnedLinks = [link].concat(this.pinnedLinks);
      }
    } else {
      this.pinnedLinks = this.pinnedLinks.filter((item: LinkItem) => item.id !== link.id);
    }
  }

  private removeLinkFromList(linkId: number): void {
    this.links = this.links.filter((item: LinkItem) => item.id !== linkId);
    this.homePreviewLinks = this.homePreviewLinks.filter((item: LinkItem) => item.id !== linkId);
  }

  private async handleSaveSettings(): Promise<void> {
    const previousInstance = this.instance;
    const nextInstance = normalizeInstanceUrl(this.settingsInstance);
    const changedServer = previousInstance !== nextInstance;

    this.instance = nextInstance;
    this.syncApiContext();

    if (changedServer && this.sessionMode !== 'offline') {
      this.token = '';
      this.currentUserId = 0;
      this.links = [];
      this.dashboardLinks = [];
      this.pinnedLinks = [];
      this.homePreviewLinks = [];
      this.collections = [];
      this.knownTagNames = [];
      this.allTags = [];
      this.pinnedTotal = -1;
      this.tagsTotal = -1;
      this.linksTotal = -1;
      this.nextCursor = 0;
      this.hasMore = true;
      this.selectedCollectionFilterId = 0;
      this.showPinnedOnly = false;
      this.clearSelectedLink();
      this.activeModal = 'none';
      this.resetCollectionDraft();
      this.clearNewLinkDraft();
      this.username = '';
      this.password = '';
      this.syncApiContext();
      this.setNotice('Settings saved. Server changed, please sign in again.', false);
    } else {
      this.setNotice('Settings saved.', false);
    }

    try {
      await this.persistSessionState();
      this.mainView = 'settings';
    } catch (error) {
      this.setNotice(`Save settings failed: ${this.formatError(error)}`, true);
    }
  }

  private async handleSignIn(): Promise<void> {
    if (this.loading) {
      return;
    }

    this.loading = true;
    this.setNotice('', false);

    const previousMode: SessionMode = this.sessionMode;

    try {
      this.sessionMode = 'online';
      this.syncApiContext();
      const token = await this.service.signIn(this.username.trim(), this.password);
      this.token = token;
      this.syncApiContext();
      this.currentUserId = await this.service.fetchCurrentUserId();
      await this.persistSessionState();

      // Always check for local data after sign-in. The user may have seeded
      // their device via offline mode OR imported a backup earlier.
      await this.maybeOfferLocalSync();

      this.dashboardRefreshing = true;
      await Promise.all([this.refreshLinks(true), this.refreshDashboard()]);
      await this.consumeSharedUrlAndMaybeSave();
      if (this.notice.length === 0) {
        this.setNotice('Signed in successfully.', false);
      }
    } catch (error) {
      // If sign-in failed and we came from offline mode, bounce back so
      // the user does not lose access to their local data.
      if (previousMode === 'offline') {
        this.sessionMode = 'offline';
        this.token = '';
        this.syncApiContext();
      }
      const message: string = this.formatError(error);
      const networkIssue: boolean = isNetworkError(message);
      this.setNotice(formatSignInError(message, networkIssue), true);
    } finally {
      this.dashboardRefreshing = false;
      this.loading = false;
    }
  }

  private async handleEnterOfflineMode(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    this.setNotice('', false);
    try {
      this.sessionMode = 'offline';
      this.token = '';
      this.currentUserId = 0;
      this.username = '';
      this.password = '';
      this.syncApiContext();
      await this.persistSessionState();
      await Promise.all([this.refreshLinks(true), this.refreshDashboard()]);
      await this.consumeSharedUrlAndMaybeSave();
      this.setNotice('Offline mode — changes stay on this device.', false);
    } catch (error) {
      this.setNotice(`Enter offline failed: ${this.formatError(error)}`, true);
    } finally {
      this.loading = false;
    }
  }

  private async maybeOfferLocalSync(): Promise<void> {
    try {
      const hasLocal: boolean = await this.service.hasLocalData();
      if (!hasLocal) {
        return;
      }
      const count: number = await this.service.countLocalLinks();
      this.setNotice(
        `${count} local bookmarks detected. Open Settings → Local data to sync them to the server.`,
        false,
      );
    } catch (error) {
      console.warn(`maybeOfferLocalSync: ${this.formatError(error)}`);
    }
  }

  private async refreshLocalCounts(): Promise<void> {
    try {
      const count: number = await this.service.countLocalLinks();
      this.localLinkCount = count;
      const cols: Array<CollectionItem> = await this.service.localDatabase().listCollections();
      this.localCollectionCount = cols.length;
    } catch (error) {
      // Swallow — counts are best-effort UI helpers, not critical.
      console.warn(`refreshLocalCounts: ${this.formatError(error)}`);
    }
  }

  private async handleExportLocal(): Promise<void> {
    if (this.exportingLocal) {
      return;
    }
    this.exportingLocal = true;
    try {
      const raw: string = await this.service.exportLocal();
      const board = pasteboard.getSystemPasteboard();
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, raw);
      await board.setData(data);
      this.setNotice(`Backup copied to clipboard (${raw.length} chars). Save it somewhere safe.`, false);
    } catch (error) {
      this.setNotice(`Export failed: ${this.formatError(error)}`, true);
    } finally {
      this.exportingLocal = false;
    }
  }

  private async handleExportToFile(): Promise<void> {
    if (this.exportingLocal) {
      return;
    }
    this.exportingLocal = true;
    try {
      const raw: string = await this.service.exportLocal();
      const stamp: string = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
      const suggestedName: string = `folio-backup-${stamp}.json`;
      const saveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [suggestedName];
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker();
      const uris: Array<string> = await documentPicker.save(saveOptions);
      if (!Array.isArray(uris) || uris.length === 0) {
        this.setNotice('Export cancelled.', false);
        return;
      }
      const uri: string = uris[0];
      await writeFileSafe(uri, raw);
      this.setNotice(`Backup saved: ${uri}`, false);
    } catch (error) {
      this.setNotice(`Export failed: ${this.formatError(error)}`, true);
    } finally {
      this.exportingLocal = false;
    }
  }

  private async handleImportFromFile(strategy: ImportStrategy): Promise<void> {
    if (this.importingLocal) {
      return;
    }
    try {
      const selectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      selectOptions.maxSelectNumber = 1;
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker();
      const selected: Array<string> = await documentPicker.select(selectOptions);
      if (!Array.isArray(selected) || selected.length === 0) {
        this.setNotice('Import cancelled.', false);
        return;
      }
      const uri: string = selected[0];
      const raw: string = await readFileSafe(uri);
      this.showImportPreview(raw, strategy, 'file');
    } catch (error) {
      this.setNotice(`Import failed: ${this.formatError(error)}`, true);
    }
  }

  private async handleImportLocal(strategy: ImportStrategy): Promise<void> {
    const payload: string = this.importPayload.trim();
    if (payload.length === 0) {
      this.setNotice('Paste a folio-backup JSON first.', true);
      return;
    }
    this.showImportPreview(payload, strategy, 'paste');
  }

  private showImportPreview(raw: string, strategy: ImportStrategy, source: string): void {
    try {
      const envelope: BackupEnvelope = parseBackupEnvelope(raw);
      this.previewRaw = raw;
      this.previewLinkCount = envelope.links.length;
      this.previewCollectionCount = envelope.collections.length;
      this.previewTagCount = envelope.tags.length;
      this.previewExportedAt = envelope.exportedAt;
      this.previewStrategy = strategy;
      this.previewSource = source;
      this.previewVisible = true;
      this.setNotice('', false);
    } catch (error) {
      this.previewVisible = false;
      this.previewRaw = '';
      this.setNotice(`Preview failed: ${this.formatError(error)}`, true);
    }
  }

  private async handleConfirmPreview(): Promise<void> {
    if (this.importingLocal) {
      return;
    }
    if (this.previewRaw.length === 0) {
      this.previewVisible = false;
      return;
    }
    this.importingLocal = true;
    const raw: string = this.previewRaw;
    const strategy: ImportStrategy = this.previewStrategy;
    const source: string = this.previewSource;
    try {
      const summary: ImportSummary = await this.service.importLocal(raw, strategy);
      this.previewVisible = false;
      this.previewRaw = '';
      if (source === 'paste') {
        this.importPayload = '';
      }
      await this.refreshLocalCounts();
      if (this.sessionMode === 'offline') {
        await Promise.all([this.refreshLinks(true), this.refreshDashboard()]);
      }
      const parts: Array<string> = [
        `${summary.linksImported} links imported`,
      ];
      if (summary.linksSkipped > 0) {
        parts.push(`${summary.linksSkipped} skipped`);
      }
      if (summary.collectionsImported > 0 || summary.collectionsReused > 0) {
        parts.push(`${summary.collectionsImported} new / ${summary.collectionsReused} reused collections`);
      }
      this.setNotice(parts.join(', ') + '.', false);
    } catch (error) {
      this.setNotice(`Import failed: ${this.formatError(error)}`, true);
    } finally {
      this.importingLocal = false;
    }
  }

  private handleCancelPreview(): void {
    this.previewVisible = false;
    this.previewRaw = '';
    this.setNotice('Import cancelled.', false);
  }

  private async handleClearLocal(): Promise<void> {
    if (this.clearingLocal) {
      return;
    }
    this.clearingLocal = true;
    try {
      await this.service.clearLocal();
      await this.refreshLocalCounts();
      if (this.sessionMode === 'offline') {
        await Promise.all([this.refreshLinks(true), this.refreshDashboard()]);
      }
      this.setNotice('Local data cleared.', false);
    } catch (error) {
      this.setNotice(`Clear failed: ${this.formatError(error)}`, true);
    } finally {
      this.clearingLocal = false;
    }
  }

  private handleConnectToLinkwarden(): void {
    // From offline mode → bounce back to login. The build() gate shows the
    // login panel whenever token is empty AND sessionMode !== 'offline'.
    this.sessionMode = 'online';
    this.token = '';
    this.username = '';
    this.password = '';
    this.mainView = 'dashboard';
    this.syncApiContext();
  }

  private async handleSwitchToOffline(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    this.setNotice('', false);
    try {
      this.sessionMode = 'offline';
      // Keep the stored token so `Resume online mode` can re-enter without
      // re-entering credentials.
      this.syncApiContext();
      await this.persistSessionState();
      await Promise.all([this.refreshLinks(true), this.refreshDashboard()]);
      await this.refreshLocalCounts();
      this.setNotice('Switched to offline — data stays on this device.', false);
    } catch (error) {
      this.setNotice(`Switch failed: ${this.formatError(error)}`, true);
    } finally {
      this.loading = false;
    }
  }

  private async handleResumeOnline(): Promise<void> {
    if (this.loading) {
      return;
    }
    if (this.token.length === 0) {
      // No stored token — fall through to the login screen.
      this.handleConnectToLinkwarden();
      return;
    }
    this.loading = true;
    this.setNotice('', false);
    try {
      this.sessionMode = 'online';
      this.syncApiContext();
      if (this.currentUserId === 0) {
        try {
          this.currentUserId = await this.service.fetchCurrentUserId();
        } catch (idError) {
          // Token is stale — surface the error and bounce back to login.
          this.sessionMode = 'offline';
          this.syncApiContext();
          this.setNotice(
            `Stored session is no longer valid (${this.formatError(idError)}). Tap "Connect to Linkwarden" to sign in again.`,
            true,
          );
          this.token = '';
          await this.persistSessionState();
          return;
        }
      }
      await this.persistSessionState();
      await Promise.all([this.refreshLinks(true), this.refreshDashboard()]);
      await this.refreshLocalCounts();
      this.setNotice('Online — syncing from the server.', false);
    } catch (error) {
      this.setNotice(`Resume failed: ${this.formatError(error)}`, true);
    } finally {
      this.loading = false;
    }
  }

  private async handleSyncLocalToServer(): Promise<void> {
    if (this.localSyncRunning || this.sessionMode !== 'online' || this.token.length === 0) {
      return;
    }
    this.localSyncRunning = true;
    this.lastMergeHasResult = false;
    this.syncProgressText = 'Preparing…';
    this.setNotice('', false);
    try {
      const runner = new MergeRunner(this.service.localDatabase(), this.service.onlineClient());
      const summary: MergeSummary = await runner.run((progress: MergeProgress) => {
        if (progress.phase === 'preparing') {
          this.syncProgressText = 'Preparing…';
        } else if (progress.phase === 'collections') {
          this.syncProgressText = `Collections ${progress.current}/${progress.total}`;
        } else if (progress.phase === 'links') {
          this.syncProgressText = `Links ${progress.current}/${progress.total}`;
        } else {
          this.syncProgressText = 'Finishing…';
        }
      });
      const parts: Array<string> = [
        `${summary.linksCreated} links uploaded`,
        `${summary.linksSkipped} duplicates skipped`,
      ];
      if (summary.linksFailed > 0) {
        parts.push(`${summary.linksFailed} failed`);
      }
      if (summary.collectionsCreated > 0 || summary.collectionsReused > 0) {
        parts.push(
          `${summary.collectionsCreated} new / ${summary.collectionsReused} reused collections`,
        );
      }
      if (summary.collectionsFailed > 0) {
        parts.push(`${summary.collectionsFailed} collection errors`);
      }
      this.lastMergeSummary = parts.join(', ') + '.';
      this.lastMergeHasResult = true;
      await this.refreshLocalCounts();
      await this.refreshDashboard();
      this.setNotice('Sync complete.', false);
    } catch (error) {
      this.setNotice(`Sync failed: ${this.formatError(error)}`, true);
    } finally {
      this.localSyncRunning = false;
      this.syncProgressText = '';
    }
  }

  private async handleMergeArchiveKeep(): Promise<void> {
    this.lastMergeHasResult = false;
    this.lastMergeSummary = '';
    this.setNotice('Local archive kept. Access it from offline mode.', false);
  }

  private async handleMergeArchiveClear(): Promise<void> {
    if (this.clearingLocal) {
      return;
    }
    this.clearingLocal = true;
    try {
      await this.service.clearLocal();
      await this.refreshLocalCounts();
      this.lastMergeHasResult = false;
      this.lastMergeSummary = '';
      this.setNotice('Local archive cleared.', false);
    } catch (error) {
      this.setNotice(`Clear failed: ${this.formatError(error)}`, true);
    } finally {
      this.clearingLocal = false;
    }
  }

  private async handleAddLink(): Promise<void> {
    const parsedInput = extractUrlAndTitle(this.newLinkUrl);
    if (parsedInput.url.length === 0) {
      this.setNotice('Please enter a URL.', true);
      return;
    }

    const matchedCollection = this.matchedDraftCollection();
    if (this.newLinkCollectionQuery.trim().length > 0 && matchedCollection === null) {
      this.setNotice('Collection not found. Use an existing collection name.', true);
      return;
    }

    const normalizedUrl = /^https?:\/\//i.test(parsedInput.url)
      ? parsedInput.url
      : `https://${parsedInput.url}`;

    this.loading = true;
    this.setNotice('', false);

    try {
      this.syncApiContext();
      this.selectedCollectionFilterId = 0;
      this.showPinnedOnly = false;
      this.searchQuery = '';
      const title = this.newLinkTitle.trim().length > 0 ? this.newLinkTitle.trim() : parsedInput.title;
      const createdLink = await this.service.addLink(normalizedUrl, title, {
        tagNames: this.resolvedDraftTags(),
        collection: matchedCollection,
      });
      if (matchedCollection !== null) {
        this.hostMemory = recordHostChoice(
          this.hostMemory,
          normalizedUrl,
          matchedCollection.id,
          Date.now(),
        );
        this.persistHostMemory();
        this.lastAddedCollectionId = matchedCollection.id;
        this.storage?.saveLastAddedCollectionId(matchedCollection.id);
      }
      this.clearNewLinkDraft();
      await this.refreshLinks(true);
      await this.refreshDashboard();
      this.markLinkAsRecentlyAdded(createdLink.id);
      this.mainView = 'elements';
      this.elementsView = 'links';
      this.activeModal = 'none';
      this.setNotice('Link added.', false);
    } catch (error) {
      this.setNotice(`Add link failed: ${this.formatError(error)}`, true);
    } finally {
      this.loading = false;
    }
  }

  private async handleSelectLink(linkId: number): Promise<void> {
    this.activeModal = 'edit';
    this.detailLoading = true;
    this.detailFailedLinkId = 0;
    this.setNotice('', false);

    try {
      this.syncApiContext();
      const timeoutMs = 10000;
      const link = await Promise.race([
        this.service.getLink(linkId),
        new Promise<never>((_, reject) => {
          setTimeout(() => reject(new Error(`Timeout after ${timeoutMs}ms`)), timeoutMs);
        }),
      ]);
      this.applySelectedLink(link);
    } catch (error) {
      this.detailFailedLinkId = linkId;
      this.setNotice(`Load detail failed: ${this.formatError(error)}`, true);
    } finally {
      this.detailLoading = false;
    }
  }

  private async handleSaveLink(): Promise<void> {
    if (this.selectedLink.id === 0 || this.detailSaving) {
      return;
    }

    const rawUrl = this.editUrl.trim();
    if (rawUrl.length === 0) {
      this.setNotice('URL cannot be empty.', true);
      return;
    }

    const normalizedUrl = /^https?:\/\//i.test(rawUrl) ? rawUrl : `https://${rawUrl}`;
    const matchedCollection = this.matchedEditCollection();
    if (this.editCollectionQuery.trim().length > 0 && matchedCollection === null) {
      this.setNotice('Collection not found. Use an existing collection name.', true);
      return;
    }

    const nextCollectionId = matchedCollection !== null ? matchedCollection.id : this.selectedLink.collectionId;
    const nextCollectionOwnerId = matchedCollection !== null ? matchedCollection.ownerId : this.selectedLink.collectionOwnerId;
    const nextCollectionName = matchedCollection !== null ? matchedCollection.name : this.selectedLink.collectionName;
    const nextCollectionColor = matchedCollection !== null ? matchedCollection.color : this.selectedLink.collectionColor;
    const nextTags: Array<LinkTag> = this.resolvedEditTags().map((name: string, index: number) => {
      const tag: LinkTag = {
        id: -(index + 1),
        name,
      };
      return tag;
    });
    const nextLink: LinkItem = {
      id: this.selectedLink.id,
      name: this.editName.trim(),
      url: normalizedUrl,
      description: this.editDescription.trim(),
      createdAt: this.selectedLink.createdAt,
      collectionId: nextCollectionId,
      collectionOwnerId: nextCollectionOwnerId,
      collectionName: nextCollectionName,
      collectionColor: nextCollectionColor,
      pinned: this.selectedLink.pinned,
      tags: nextTags,
    };

    this.detailSaving = true;
    this.setNotice('', false);

    try {
      this.syncApiContext();
      const savedLink = await this.service.updateLink(nextLink);
      this.applySelectedLink(savedLink);
      this.replaceLinkInList(savedLink);
      await this.refreshDashboard();
      this.activeModal = 'none';
      this.setNotice('Link updated.', false);
    } catch (error) {
      this.setNotice(`Save failed: ${this.formatError(error)}`, true);
    } finally {
      this.detailSaving = false;
    }
  }

  private async handleDeleteLink(): Promise<void> {
    if (this.selectedLink.id === 0 || this.detailDeleting) {
      return;
    }

    this.detailDeleting = true;
    this.setNotice('', false);

    try {
      this.syncApiContext();
      const deletingId = this.selectedLink.id;
      await this.service.deleteLink(deletingId);
      this.removeLinkFromList(deletingId);
      this.clearSelectedLink();
      this.activeModal = 'none';
      await this.refreshDashboard();
      this.setNotice('Link deleted.', false);
    } catch (error) {
      this.setNotice(`Delete failed: ${this.formatError(error)}`, true);
    } finally {
      this.detailDeleting = false;
    }
  }

  private async deleteLinkById(linkId: number): Promise<void> {
    if (linkId <= 0 || this.detailDeleting) {
      return;
    }

    this.detailDeleting = true;
    this.setNotice('', false);

    try {
      this.syncApiContext();
      await this.service.deleteLink(linkId);
      this.removeLinkFromList(linkId);
      this.dashboardLinks = this.dashboardLinks.filter((item: LinkItem) => item.id !== linkId);
      this.pinnedLinks = this.pinnedLinks.filter((item: LinkItem) => item.id !== linkId);
      if (this.selectedLink.id === linkId) {
        this.clearSelectedLink();
        this.activeModal = 'none';
      }
      await this.refreshDashboard();
      this.setNotice('Link deleted.', false);
    } catch (error) {
      this.setNotice(`Delete failed: ${this.formatError(error)}`, true);
    } finally {
      this.detailDeleting = false;
    }
  }

  private handleLinkLongPress(item: LinkItem): void {
    this.handleSelectLink(item.id).catch(() => {});
  }

  private async handleTogglePin(): Promise<void> {
    if (this.selectedLink.id === 0 || this.pinSaving) {
      return;
    }

    this.pinSaving = true;
    this.setNotice('', false);

    try {
      await this.ensureCurrentUserId();
      this.syncApiContext();
      const savedLink = await this.service.setPinned(this.selectedLink, !this.editPinned, this.currentUserId);
      this.applySelectedLink(savedLink);
      this.replaceLinkInList(savedLink);
      await this.refreshDashboard();
      this.setNotice(savedLink.pinned ? 'Pinned to dashboard.' : 'Removed from dashboard.', false);
    } catch (error) {
      this.setNotice(`Pin update failed: ${this.formatError(error)}`, true);
    } finally {
      this.pinSaving = false;
    }
  }

  private async handleCreateCollection(): Promise<void> {
    const collectionName = this.newCollectionName.trim();
    if (collectionName.length === 0) {
      this.setNotice('Collection name cannot be empty.', true);
      return;
    }

    const matchedParent = this.matchedParentCollection();
    if (this.newCollectionParentQuery.trim().length > 0 && matchedParent === null) {
      this.setNotice('Parent collection not found. Use an existing collection name.', true);
      return;
    }

    this.collectionSaving = true;
    this.setNotice('', false);

    try {
      this.syncApiContext();
      const createdCollection = await this.service.createCollection(collectionName, {
        description: this.newCollectionDescription,
        color: this.newCollectionColor,
        parentId: matchedParent !== null ? matchedParent.id : undefined,
      });
      await this.refreshDashboard();
      if (this.collectionModalSource === 'add') {
        this.newLinkCollectionQuery = createdCollection.name;
        this.collectionManuallyPicked = true;
      } else {
        this.editCollectionQuery = createdCollection.name;
      }
      this.activeModal = this.collectionModalReturn;
      this.setNotice('Collection created.', false);
    } catch (error) {
      this.setNotice(`Create collection failed: ${this.formatError(error)}`, true);
    } finally {
      this.collectionSaving = false;
    }
  }

  private async handleSignOut(): Promise<void> {
    this.token = '';
    this.currentUserId = 0;
    this.sessionMode = 'online';
    this.links = [];
    this.dashboardLinks = [];
    this.pinnedLinks = [];
    this.homePreviewLinks = [];
    this.collections = [];
    this.knownTagNames = [];
    this.allTags = [];
    this.pinnedTotal = -1;
    this.tagsTotal = -1;
    this.linksTotal = -1;
    this.nextCursor = 0;
    this.hasMore = true;
    this.selectedCollectionFilterId = 0;
    this.showPinnedOnly = false;
    this.password = '';
    this.activeModal = 'none';
    this.lastMergeHasResult = false;
    this.lastMergeSummary = '';
    this.resetCollectionDraft();
    this.clearNewLinkDraft();
    this.clearSelectedLink();
    this.syncApiContext();

    try {
      await this.persistSessionState();
    } catch (error) {
      this.setNotice(`Sign out storage update failed: ${this.formatError(error)}`, true);
      return;
    }

    this.setNotice('Signed out.', false);
  }


  private async handleDashboardPullRefresh(): Promise<void> {
    this.dashboardRefreshing = true;
    try {
      await Promise.all([
        this.refreshDashboard(),
        this.refreshLinks(true),
      ]);
    } finally {
      this.dashboardRefreshing = false;
    }
  }

  private async handleLibraryLinksPullRefresh(): Promise<void> {
    this.linksRefreshing = true;
    try {
      await this.refreshLinks(true);
    } finally {
      this.linksRefreshing = false;
    }
  }

  private async handleLibraryCollectionsPullRefresh(): Promise<void> {
    this.collectionsRefreshing = true;
    try {
      await this.refreshDashboard();
    } finally {
      this.collectionsRefreshing = false;
    }
  }

  private async handleLibraryTagsPullRefresh(): Promise<void> {
    this.tagsRefreshing = true;
    try {
      await this.refreshDashboard();
    } finally {
      this.tagsRefreshing = false;
    }
  }

  private async refreshLinks(reset: boolean): Promise<void> {
    if (this.token.length === 0 && this.sessionMode !== 'offline') {
      return;
    }

    if (reset) {
      this.loading = true;
      this.nextCursor = 0;
      this.hasMore = true;
    } else {
      if (!this.hasMore || this.loadingMore) {
        return;
      }
      this.loadingMore = true;
    }

    try {
      this.syncApiContext();
      const page = await this.service.fetchLinks(
        reset ? 0 : this.nextCursor,
        this.searchQuery,
        this.selectedCollectionFilterId,
        this.showPinnedOnly
      );

      if (reset) {
        this.links = page.links;
      } else {
        this.links = this.links.concat(page.links);
      }
      this.mergeTagsFromLinks(page.links);

      this.nextCursor = page.nextCursor;
      this.hasMore = page.nextCursor >= 0;
    } catch (error) {
      if (reset && this.isAuthFailure(error)) {
        this.token = '';
        await this.persistSessionState();
      }
      this.setNotice(`Fetch links failed: ${this.formatError(error)}`, true);
    } finally {
      if (reset) {
        this.loading = false;
      }
      this.loadingMore = false;
    }
  }

  private async refreshDashboard(): Promise<void> {
    if (this.token.length === 0 && this.sessionMode !== 'offline') {
      return;
    }

    this.dashboardLoading = true;
    try {
      this.syncApiContext();
      const result = await Promise.all([
        this.service.fetchDashboardLinks(),
        this.service.fetchPinnedLinks(),
        this.service.fetchCollections(),
        this.service.fetchLinks(0, '', 0, false),
        this.fetchTagsOrEmpty(),
        this.fetchDashboardTotalsOrNull(),
      ]);
      this.dashboardLinks = result[0];
      this.pinnedLinks = result[1];
      this.collections = result[2];
      this.homePreviewLinks = result[3].links;
      this.allTags = result[4];
      const totals: DashboardTotals | null = result[5];
      this.pinnedTotal = totals !== null ? totals.numberOfPinnedLinks : result[1].length;
      this.tagsTotal = totals !== null && totals.numberOfTags !== null
        ? totals.numberOfTags
        : result[4].length;
      this.linksTotal = result[2].reduce((sum: number, c: CollectionItem) => sum + c.linkCount, 0);
      this.mergeTagNamesFromTags(result[4]);
    } catch (error) {
      this.setNotice(`Fetch dashboard failed: ${this.formatError(error)}`, true);
    } finally {
      this.dashboardLoading = false;
    }
  }

  private async fetchTagsOrEmpty(): Promise<Array<LinkTag>> {
    try {
      return await this.service.fetchTags();
    } catch (error) {
      console.info(`Index fetchTags failed: ${this.formatError(error)}`);
      return [];
    }
  }

  private async fetchDashboardTotalsOrNull(): Promise<DashboardTotals | null> {
    try {
      return await this.service.fetchDashboardTotals();
    } catch (error) {
      console.info(`Index fetchDashboardTotals failed: ${this.formatError(error)}`);
      return null;
    }
  }

  private openLinkInBrowser(rawUrl: string): void {
    const normalizedUrl = /^https?:\/\//i.test(rawUrl.trim()) ? rawUrl.trim() : `https://${rawUrl.trim()}`;
    if (normalizedUrl.length === 0) {
      this.setNotice('Invalid URL.', true);
      return;
    }

    const context = this.getUIContext().getHostContext()! as common.UIAbilityContext;
    context.startAbility({
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: normalizedUrl,
      type: 'text/html',
    }).catch((error: Error) => {
      this.setNotice(`Open URL failed: ${this.formatError(error)}`, true);
    });
  }

  private isAuthFailure(error: Object): boolean {
    const message = this.formatError(error);
    return message.indexOf('HTTP_401') >= 0 || message.indexOf('HTTP_403') >= 0;
  }

  private setNotice(value: string, isError: boolean): void {
    this.notice = value;
    this.noticeIsError = isError;

    if (this.noticeTimer >= 0) {
      clearTimeout(this.noticeTimer);
      this.noticeTimer = -1;
    }

    if (value.length > 0) {
      this.noticeTimer = setTimeout(() => {
        this.notice = '';
        this.noticeTimer = -1;
      }, isError ? 2600 : 1800);
    }
  }

  private formatDateLabel(value: string): string {
    try {
      return new Date(value).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
      });
    } catch (error) {
      return value;
    }
  }

  private formatError(error: Object): string {
    if (!(error instanceof Error)) {
      return `${error}`;
    }

    const msg = error.message;

    // HTTP errors: HTTP_401:..., HTTP_404:..., etc.
    if (msg.startsWith('HTTP_')) {
      const code = msg.substring(5, 8);
      if (code === '401') return 'Authentication failed — please sign in again.';
      if (code === '403') return 'Access denied.';
      if (code === '404') return 'Resource not found.';
      if (code === '409') return 'Conflict — resource already exists.';
      if (code === '422') return 'Invalid data sent to server.';
      if (code === '429') return 'Too many requests — please wait.';
      if (code.startsWith('5')) return 'Server error — please try later.';
      return `Server returned ${code}.`;
    }

    // Network errors
    if (msg.startsWith('REQUEST_')) return 'Network error — check your connection.';
    if (msg.indexOf('Timeout') >= 0) return 'Request timed out.';

    return msg;
  }

  private startSharePolling(): void {
    if (this.sharePollTimer >= 0) {
      return;
    }

    this.sharePollTimer = setInterval(() => {
      if (this.restoring) {
        return;
      }

      this.consumeSharedUrlAndMaybeSave().catch((error: Object) => {
        this.setNotice(`Share polling failed: ${this.formatError(error)}`, true);
      });
    }, 1200);
    console.info('Index share poll started');
  }

  private async consumeSharedUrlAndMaybeSave(): Promise<void> {
    const sharedIntent = consumePendingSharedIntent();
    const sharedUrl = sharedIntent.url;
    const sharedTitle = sharedIntent.title;
    if (sharedUrl.length === 0) {
      return;
    }
    console.info(`Index consumeSharedUrlAndMaybeSave got sharedUrl=${sharedUrl}, sharedTitle=${sharedTitle}`);

    this.applyNewLinkDraft(sharedUrl, sharedTitle);

    if (this.token.length === 0 && this.sessionMode !== 'offline') {
      console.info('Index shared url captured but no token and not offline');
      this.setNotice('Shared URL captured. Sign in or tap "Use offline" to save it.', false);
      return;
    }

    this.openAddModal();
    this.setNotice(
      this.sessionMode === 'offline'
        ? 'Shared URL captured. Saving locally — set collection and tags before confirming.'
        : 'Shared URL captured. You can set collection and tags before saving.',
      false,
    );
  }
}
