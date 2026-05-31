import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  normalizedTagCandidate,
  normalizedTagsInput,
  parseTagsFromInput,
  appendTagToInput,
  removeTagFromInput,
  toggleTagInInput,
  tagsIncludingPendingQuery,
  canCreateTag,
  pendingTagCandidate,
  quickTagOptions,
} from './tag-parser.mjs';

describe('normalizedTagCandidate', () => {
  it('trims whitespace', () => {
    assert.equal(normalizedTagCandidate('  hello  '), 'hello');
  });

  it('strips leading # characters', () => {
    assert.equal(normalizedTagCandidate('##tag'), 'tag');
    assert.equal(normalizedTagCandidate('#tag'), 'tag');
  });

  it('returns empty for empty input', () => {
    assert.equal(normalizedTagCandidate(''), '');
    assert.equal(normalizedTagCandidate('   '), '');
    assert.equal(normalizedTagCandidate('###'), '');
  });
});

describe('normalizedTagsInput', () => {
  it('joins tags with comma and space', () => {
    assert.equal(normalizedTagsInput(['a', 'b', 'c']), 'a, b, c');
  });

  it('returns empty for empty array', () => {
    assert.equal(normalizedTagsInput([]), '');
  });
});

describe('parseTagsFromInput', () => {
  it('splits on commas', () => {
    assert.deepEqual(parseTagsFromInput('a,b,c'), ['a', 'b', 'c']);
  });

  it('splits on newlines', () => {
    assert.deepEqual(parseTagsFromInput('a\nb\nc'), ['a', 'b', 'c']);
  });

  it('deduplicates case-insensitively', () => {
    assert.deepEqual(parseTagsFromInput('Tag,tag,TAG'), ['Tag']);
  });

  it('strips leading #', () => {
    assert.deepEqual(parseTagsFromInput('#tag1, #tag2'), ['tag1', 'tag2']);
  });

  it('trims whitespace', () => {
    assert.deepEqual(parseTagsFromInput('  a ,  b  '), ['a', 'b']);
  });

  it('filters empty items', () => {
    assert.deepEqual(parseTagsFromInput('a,,b,'), ['a', 'b']);
  });

  it('returns empty for empty input', () => {
    assert.deepEqual(parseTagsFromInput(''), []);
  });
});

describe('appendTagToInput', () => {
  it('appends a new tag', () => {
    assert.equal(appendTagToInput('a', 'b'), 'a, b');
  });

  it('does not append duplicate (case-insensitive)', () => {
    assert.equal(appendTagToInput('a', 'A'), 'a');
  });

  it('handles empty input', () => {
    assert.equal(appendTagToInput('', 'tag'), 'tag');
  });

  it('ignores empty tag', () => {
    assert.equal(appendTagToInput('a', ''), 'a');
  });

  it('strips leading # from tag', () => {
    assert.equal(appendTagToInput('', '#tag'), 'tag');
  });
});

describe('removeTagFromInput', () => {
  it('removes a tag case-insensitively', () => {
    assert.equal(removeTagFromInput('a, b, c', 'B'), 'a, c');
  });

  it('returns same if tag not found', () => {
    assert.equal(removeTagFromInput('a, b', 'c'), 'a, b');
  });

  it('removes tag when rawTag has leading #', () => {
    assert.equal(removeTagFromInput('mytag, other', '#mytag'), 'other');
  });
});

describe('toggleTagInInput', () => {
  it('appends if not present', () => {
    assert.equal(toggleTagInInput('a', 'b'), 'a, b');
  });

  it('removes if present', () => {
    assert.equal(toggleTagInInput('a, b, c', 'b'), 'a, c');
  });

  it('toggles case-insensitively', () => {
    assert.equal(toggleTagInInput('Tag', 'tag'), '');
  });
});

describe('tagsIncludingPendingQuery', () => {
  it('includes pending query if not already present', () => {
    assert.deepEqual(tagsIncludingPendingQuery('a', 'b'), ['a', 'b']);
  });

  it('does not duplicate existing tag', () => {
    assert.deepEqual(tagsIncludingPendingQuery('a', 'A'), ['a']);
  });

  it('ignores empty query', () => {
    assert.deepEqual(tagsIncludingPendingQuery('a', ''), ['a']);
  });
});

describe('canCreateTag', () => {
  it('returns true when tag is new', () => {
    assert.equal(canCreateTag('new', ['a'], ['b']), true);
  });

  it('returns false when already selected', () => {
    assert.equal(canCreateTag('a', ['a'], []), false);
  });

  it('returns false when in library', () => {
    assert.equal(canCreateTag('b', [], ['b']), false);
  });

  it('returns false for empty query', () => {
    assert.equal(canCreateTag('', [], []), false);
  });

  it('is case-insensitive', () => {
    assert.equal(canCreateTag('A', ['a'], []), false);
    assert.equal(canCreateTag('B', [], ['b']), false);
  });
});

describe('pendingTagCandidate', () => {
  it('returns candidate if not selected', () => {
    assert.equal(pendingTagCandidate('new', ['a']), 'new');
  });

  it('returns empty if already selected', () => {
    assert.equal(pendingTagCandidate('a', ['a']), '');
  });

  it('returns empty for empty query', () => {
    assert.equal(pendingTagCandidate('', []), '');
  });
});

describe('quickTagOptions', () => {
  it('returns all tags when query is empty', () => {
    const result = quickTagOptions('', ['a'], ['b', 'c']);
    assert.deepEqual(result, ['a', 'b', 'c']);
  });

  it('filters by query', () => {
    const result = quickTagOptions('b', ['a', 'beta'], ['b', 'gamma']);
    assert.deepEqual(result, ['beta', 'b']);
  });

  it('selected tags come first', () => {
    const result = quickTagOptions('', ['z'], ['a']);
    assert.deepEqual(result, ['z', 'a']);
  });

  it('does not duplicate tags', () => {
    const result = quickTagOptions('', ['a'], ['a', 'b']);
    assert.deepEqual(result, ['a', 'b']);
  });
});
