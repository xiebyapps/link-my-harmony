import preferences from '@ohos.data.preferences';
import {
  createDefaultSessionState,
  parseSessionState,
  serializeSessionState,
  type SessionState,
} from '../common/SessionState';
import { PreferencesStore } from './PreferencesStore';

const SESSION_STATE_KEY: string = 'session_state';
const LAST_ADDED_COLLECTION_KEY: string = 'last_added_collection_id';
const PREFERENCES_NAME: string = 'linkwarden.preferences';

export class SessionStorage {
  private readonly store: PreferencesStore<SessionState>;
  private readonly context: Context;

  constructor(context: Context) {
    this.context = context;
    this.store = new PreferencesStore<SessionState>(context, {
      key: SESSION_STATE_KEY,
      serialize: serializeSessionState,
      parse: parseSessionState,
    });
  }

  async load(): Promise<SessionState> {
    return this.store.load();
  }

  async save(state: SessionState): Promise<void> {
    return this.store.save(state);
  }

  async clear(): Promise<void> {
    await this.save(createDefaultSessionState());
  }

  // last_added_collection_id is stored as a raw number (not JSON-serialized),
  // so it uses the preferences API directly instead of PreferencesStore<T>.
  async loadLastAddedCollectionId(): Promise<number> {
    const pref = await preferences.getPreferences(this.context, PREFERENCES_NAME);
    const raw = await pref.get(LAST_ADDED_COLLECTION_KEY, 0);
    return typeof raw === 'number' ? raw : 0;
  }

  async saveLastAddedCollectionId(id: number): Promise<void> {
    const pref = await preferences.getPreferences(this.context, PREFERENCES_NAME);
    await pref.put(LAST_ADDED_COLLECTION_KEY, id);
    await pref.flush();
  }
}
