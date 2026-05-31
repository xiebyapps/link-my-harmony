import { extractHostname } from './UrlParser';
import { decayedScore, clampNonNegative } from './ScoredEntryList';

export interface HostCollectionEntry {
  host: string;
  collectionId: number;
  count: number;
  lastUsedAt: number;
}

export interface HostCollectionMemoryState {
  entries: Array<HostCollectionEntry>;
}

interface HostCollectionMemoryPayload {
  entries?: Array<HostCollectionEntryPayload>;
}

interface HostCollectionEntryPayload {
  host?: string;
  collectionId?: number;
  count?: number;
  lastUsedAt?: number;
}

export function createDefaultHostCollectionMemory(): HostCollectionMemoryState {
  return { entries: [] };
}

export function findHostCollectionEntry(
  state: HostCollectionMemoryState,
  host: string,
  collectionId: number,
): HostCollectionEntry | null {
  for (let i: number = 0; i < state.entries.length; i++) {
    const entry = state.entries[i];
    if (entry.host === host && entry.collectionId === collectionId) {
      return entry;
    }
  }
  return null;
}

export function recordHostChoice(
  state: HostCollectionMemoryState,
  hostOrUrl: string,
  collectionId: number,
  now: number,
): HostCollectionMemoryState {
  const host: string = extractHostname(hostOrUrl);
  if (host.length === 0 || collectionId <= 0) {
    return state;
  }
  const existing: HostCollectionEntry | null = findHostCollectionEntry(state, host, collectionId);
  const rest: Array<HostCollectionEntry> = state.entries.filter(
    (entry: HostCollectionEntry) => !(entry.host === host && entry.collectionId === collectionId),
  );
  const nextCount: number = existing === null ? 1 : existing.count + 1;
  const nextEntry: HostCollectionEntry = {
    host,
    collectionId,
    count: nextCount,
    lastUsedAt: now,
  };
  return { entries: [nextEntry].concat(rest) };
}

export function hostCollectionScore(
  entry: HostCollectionEntry | null,
  now: number,
): number {
  if (entry === null) {
    return 0;
  }
  return decayedScore(entry.count, entry.lastUsedAt, now);
}

export function pickBestCollectionForHost(
  state: HostCollectionMemoryState,
  hostOrUrl: string,
  now: number,
): number {
  const host: string = extractHostname(hostOrUrl);
  if (host.length === 0) {
    return 0;
  }
  let bestId: number = 0;
  let bestScore: number = 0;
  for (let i: number = 0; i < state.entries.length; i++) {
    const entry = state.entries[i];
    if (entry.host !== host) {
      continue;
    }
    const score: number = hostCollectionScore(entry, now);
    if (score > bestScore) {
      bestScore = score;
      bestId = entry.collectionId;
    }
  }
  return bestId;
}

export function serializeHostCollectionMemory(state: HostCollectionMemoryState): string {
  return JSON.stringify({ entries: state.entries });
}

export function parseHostCollectionMemory(raw: string): HostCollectionMemoryState {
  if (raw.length === 0) {
    return createDefaultHostCollectionMemory();
  }

  try {
    const parsed = JSON.parse(raw) as HostCollectionMemoryPayload;
    const rawEntries = parsed.entries;

    if (!Array.isArray(rawEntries)) {
      return createDefaultHostCollectionMemory();
    }

    const sanitized: Array<HostCollectionEntry> = [];
    for (let i: number = 0; i < rawEntries.length; i++) {
      const candidate: HostCollectionEntryPayload = rawEntries[i];
      const host = candidate.host;
      const collectionId = candidate.collectionId;
      const count = candidate.count;
      const lastUsedAt = candidate.lastUsedAt;
      if (
        typeof host === 'string'
        && host.length > 0
        && typeof collectionId === 'number'
        && typeof count === 'number'
        && typeof lastUsedAt === 'number'
      ) {
        sanitized.push({
          host,
          collectionId,
          count: clampNonNegative(count),
          lastUsedAt: clampNonNegative(lastUsedAt),
        });
      }
    }

    return { entries: sanitized };
  } catch (error) {
    return createDefaultHostCollectionMemory();
  }
}
