import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { createPreferencesStore } from './preferences-store.mjs';

describe('PreferencesStore', () => {
  it('load returns parsed default when empty', async () => {
    const store = createPreferencesStore({
      key: 'test',
      serialize: (s) => JSON.stringify(s),
      parse: (raw) => raw ? JSON.parse(raw) : { entries: [] },
    });
    const result = await store.load();
    assert.deepEqual(result, { entries: [] });
  });

  it('save then load round-trips', async () => {
    const store = createPreferencesStore({
      key: 'test',
      serialize: (s) => JSON.stringify(s),
      parse: (raw) => raw ? JSON.parse(raw) : { entries: [] },
    });
    await store.save({ entries: [{ id: 1 }] });
    const result = await store.load();
    assert.deepEqual(result, { entries: [{ id: 1 }] });
  });

  it('different keys are isolated', async () => {
    const storeA = createPreferencesStore({
      key: 'a',
      serialize: (s) => JSON.stringify(s),
      parse: (raw) => raw ? JSON.parse(raw) : null,
    });
    const storeB = createPreferencesStore({
      key: 'b',
      serialize: (s) => JSON.stringify(s),
      parse: (raw) => raw ? JSON.parse(raw) : null,
    });
    await storeA.save({ value: 'fromA' });
    const resultB = await storeB.load();
    assert.equal(resultB, null);
  });

  it('handles parse errors gracefully', async () => {
    const store = createPreferencesStore({
      key: 'test',
      serialize: (s) => JSON.stringify(s),
      parse: (raw) => {
        if (!raw) return { entries: [] };
        throw new Error('parse failed');
      },
    });
    store._setData({ test: 'invalid' });
    const result = await store.load();
    assert.deepEqual(result, { entries: [] });
  });

  it('serialize is called on save', async () => {
    let serializeCalled = false;
    const store = createPreferencesStore({
      key: 'test',
      serialize: (s) => { serializeCalled = true; return JSON.stringify(s); },
      parse: (raw) => raw ? JSON.parse(raw) : {},
    });
    await store.save({ data: true });
    assert.equal(serializeCalled, true);
  });
});
