/**
 * Pure-JS mirror of services/PreferencesStore.ets
 *
 * Functional version that tests the core logic without HarmonyOS SDK.
 */

export function createPreferencesStore(opts) {
  const { key, serialize, parse } = opts;
  let data = {};

  return {
    async load() {
      try {
        const raw = data[key];
        if (typeof raw === 'string' && raw.length > 0) {
          return parse(raw);
        }
      } catch (error) {
        console.warn(`PreferencesStore load failed for key=${key}: ${error}`);
      }
      return parse('');
    },
    async save(state) {
      data[key] = serialize(state);
    },
    _getData() {
      return { ...data };
    },
    _setData(newData) {
      data = { ...newData };
    },
  };
}
