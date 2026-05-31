import {
  parseCollectionUsage,
  serializeCollectionUsage,
  type CollectionUsageState,
} from '../common/CollectionUsage';
import { PreferencesStore } from './PreferencesStore';

export class CollectionUsageStorage {
  private readonly store: PreferencesStore<CollectionUsageState>;

  constructor(context: Context) {
    this.store = new PreferencesStore<CollectionUsageState>(context, {
      key: 'collection_usage',
      serialize: serializeCollectionUsage,
      parse: parseCollectionUsage,
    });
  }

  async load(): Promise<CollectionUsageState> {
    return this.store.load();
  }

  async save(state: CollectionUsageState): Promise<void> {
    return this.store.save(state);
  }
}
