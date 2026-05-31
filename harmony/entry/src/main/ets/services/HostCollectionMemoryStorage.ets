import {
  parseHostCollectionMemory,
  serializeHostCollectionMemory,
  type HostCollectionMemoryState,
} from '../common/HostCollectionMemory';
import { PreferencesStore } from './PreferencesStore';

export class HostCollectionMemoryStorage {
  private readonly store: PreferencesStore<HostCollectionMemoryState>;

  constructor(context: Context) {
    this.store = new PreferencesStore<HostCollectionMemoryState>(context, {
      key: 'host_collection_memory',
      serialize: serializeHostCollectionMemory,
      parse: parseHostCollectionMemory,
    });
  }

  async load(): Promise<HostCollectionMemoryState> {
    return this.store.load();
  }

  async save(state: HostCollectionMemoryState): Promise<void> {
    return this.store.save(state);
  }
}
