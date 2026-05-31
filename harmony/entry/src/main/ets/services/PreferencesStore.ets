/**
 * Generic preferences-backed key-value store.
 *
 * Replaces the three identical storage wrappers:
 * SessionStorage.ets, CollectionUsageStorage.ets, HostCollectionMemoryStorage.ets.
 *
 * Each only differed in the storage key and the serialize/parse functions.
 */
import hilog from '@ohos.hilog';
import { preferences } from '@kit.ArkData';

const PREFERENCES_NAME: string = 'linkwarden.preferences';

export interface PreferencesStoreOptions<T> {
  key: string;
  serialize: (state: T) => string;
  parse: (raw: string) => T;
}

export class PreferencesStore<T> {
  private storePromise: Promise<preferences.Preferences> | null = null;
  private readonly key: string;
  private readonly serialize: (state: T) => string;
  private readonly parse: (raw: string) => T;

  constructor(context: Context, opts: PreferencesStoreOptions<T>) {
    this.key = opts.key;
    this.serialize = opts.serialize;
    this.parse = opts.parse;
    this.storePromise = preferences.getPreferences(context, PREFERENCES_NAME);
  }

  private ensureStore(): Promise<preferences.Preferences> {
    return this.storePromise!;
  }

  async load(): Promise<T> {
    try {
      const store = await this.ensureStore();
      const raw = await store.get(this.key, '') as string;
      if (typeof raw === 'string' && raw.length > 0) {
        return this.parse(raw);
      }
    } catch (error) {
      hilog.warn(0x0001, 'PreferencesStore', 'load failed for key=%{public}s: %{public}s', this.key, String(error));
    }
    return this.parse('');
  }

  async save(state: T): Promise<void> {
    const store = await this.ensureStore();
    await store.put(this.key, this.serialize(state));
    await store.flush();
  }
}
