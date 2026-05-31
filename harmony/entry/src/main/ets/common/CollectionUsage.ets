import { decayedScore, clampNonNegative } from './ScoredEntryList';

export interface CollectionUsageEntry {
  collectionId: number;
  viewCount: number;
  lastViewedAt: number;
}

export interface CollectionUsageState {
  entries: Array<CollectionUsageEntry>;
}

interface CollectionUsagePayload {
  entries?: Array<CollectionUsageEntryPayload>;
}

interface CollectionUsageEntryPayload {
  collectionId?: number;
  viewCount?: number;
  lastViewedAt?: number;
}

export function createDefaultCollectionUsage(): CollectionUsageState {
  return { entries: [] };
}

export function findCollectionUsageEntry(
  state: CollectionUsageState,
  collectionId: number,
): CollectionUsageEntry | null {
  for (let i: number = 0; i < state.entries.length; i++) {
    if (state.entries[i].collectionId === collectionId) {
      return state.entries[i];
    }
  }
  return null;
}

export function recordCollectionView(
  state: CollectionUsageState,
  collectionId: number,
  now: number,
): CollectionUsageState {
  const rest: Array<CollectionUsageEntry> = state.entries.filter(
    (entry: CollectionUsageEntry) => entry.collectionId !== collectionId,
  );
  const existing: CollectionUsageEntry | null = findCollectionUsageEntry(state, collectionId);
  const nextCount: number = existing === null ? 1 : existing.viewCount + 1;
  const nextEntry: CollectionUsageEntry = {
    collectionId,
    viewCount: nextCount,
    lastViewedAt: now,
  };
  return { entries: [nextEntry].concat(rest) };
}

export function collectionUsageScore(
  entry: CollectionUsageEntry | null,
  now: number,
): number {
  if (entry === null) {
    return 0;
  }
  return decayedScore(entry.viewCount, entry.lastViewedAt, now);
}

export function serializeCollectionUsage(state: CollectionUsageState): string {
  return JSON.stringify({ entries: state.entries });
}

export function parseCollectionUsage(raw: string): CollectionUsageState {
  if (raw.length === 0) {
    return createDefaultCollectionUsage();
  }

  try {
    const parsed = JSON.parse(raw) as CollectionUsagePayload;
    const rawEntries = parsed.entries;

    if (!Array.isArray(rawEntries)) {
      return createDefaultCollectionUsage();
    }

    const sanitized: Array<CollectionUsageEntry> = [];
    for (let i: number = 0; i < rawEntries.length; i++) {
      const candidate: CollectionUsageEntryPayload = rawEntries[i];
      const collectionId = candidate.collectionId;
      const viewCount = candidate.viewCount;
      const lastViewedAt = candidate.lastViewedAt;
      if (
        typeof collectionId === 'number'
        && typeof viewCount === 'number'
        && typeof lastViewedAt === 'number'
      ) {
        sanitized.push({
          collectionId,
          viewCount: clampNonNegative(viewCount),
          lastViewedAt: clampNonNegative(lastViewedAt),
        });
      }
    }

    return { entries: sanitized };
  } catch (error) {
    return createDefaultCollectionUsage();
  }
}
