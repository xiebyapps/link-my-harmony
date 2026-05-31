import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { filteredCollectionsForSearch, filteredTagsForSearch, filteredLinksForSearch, searchHasAnyResult, collectionPreviewSections } from './search-filter.mjs';

describe('filteredCollectionsForSearch', () => {
  it('returns empty array when query is empty', () => {
    const collections = [{ id: 1, name: 'Travel' }];
    assert.deepEqual(filteredCollectionsForSearch(collections, ''), []);
    assert.deepEqual(filteredCollectionsForSearch(collections, '   '), []);
  });

  it('returns empty array when no collections match', () => {
    const collections = [{ id: 1, name: 'Travel' }];
    assert.deepEqual(filteredCollectionsForSearch(collections, 'recipes'), []);
  });

  it('finds collection by exact name', () => {
    const collections = [
      { id: 1, name: 'Travel' },
      { id: 2, name: 'Recipes' },
    ];
    const result = filteredCollectionsForSearch(collections, 'Travel');
    assert.equal(result.length, 1);
    assert.equal(result[0].id, 1);
  });

  it('finds collection by partial name (case-insensitive)', () => {
    const collections = [
      { id: 1, name: 'Travel Tips' },
      { id: 2, name: 'Recipes' },
      { id: 3, name: 'travel blog' },
    ];
    const result = filteredCollectionsForSearch(collections, 'travel');
    assert.equal(result.length, 2);
    assert.equal(result[0].id, 1);
    assert.equal(result[1].id, 3);
  });

  it('returns all matching collections', () => {
    const collections = [
      { id: 1, name: 'Work' },
      { id: 2, name: 'Work Stuff' },
      { id: 3, name: 'Personal' },
    ];
    const result = filteredCollectionsForSearch(collections, 'work');
    assert.equal(result.length, 2);
  });
});

describe('filteredTagsForSearch', () => {
  it('returns empty array when query is empty', () => {
    assert.deepEqual(filteredTagsForSearch(['javascript', 'react'], ''), []);
    assert.deepEqual(filteredTagsForSearch(['javascript', 'react'], '   '), []);
  });

  it('returns empty array when no tags match', () => {
    assert.deepEqual(filteredTagsForSearch(['javascript', 'react'], 'python'), []);
  });

  it('finds tag by exact name', () => {
    const result = filteredTagsForSearch(['javascript', 'react', 'python'], 'react');
    assert.deepEqual(result, ['react']);
  });

  it('finds tag by partial name (case-insensitive)', () => {
    const result = filteredTagsForSearch(['JavaScript', 'React', 'java'], 'java');
    assert.deepEqual(result, ['JavaScript', 'java']);
  });

  it('returns all matching tags', () => {
    const result = filteredTagsForSearch(['web', 'webdev', 'backend'], 'web');
    assert.deepEqual(result, ['web', 'webdev']);
  });
});

describe('filteredLinksForSearch', () => {
  const links = [
    { id: 1, name: 'React Docs', url: 'https://react.dev', description: 'Official React documentation', tags: [{ name: 'javascript' }] },
    { id: 2, name: 'Python Guide', url: 'https://python.org', description: 'Learn Python', tags: [{ name: 'python' }] },
    { id: 3, name: 'My Blog', url: 'https://example.com/blog', description: '', tags: [{ name: 'web' }, { name: 'javascript' }] },
  ];

  it('returns empty array when query is empty', () => {
    assert.deepEqual(filteredLinksForSearch(links, ''), []);
    assert.deepEqual(filteredLinksForSearch(links, '   '), []);
  });

  it('finds link by title', () => {
    const result = filteredLinksForSearch(links, 'react');
    assert.equal(result.length, 1);
    assert.equal(result[0].id, 1);
  });

  it('finds link by URL', () => {
    const result = filteredLinksForSearch(links, 'python.org');
    assert.equal(result.length, 1);
    assert.equal(result[0].id, 2);
  });

  it('finds link by description', () => {
    const result = filteredLinksForSearch(links, 'official');
    assert.equal(result.length, 1);
    assert.equal(result[0].id, 1);
  });

  it('finds link by tag name', () => {
    const result = filteredLinksForSearch(links, 'python');
    assert.equal(result.length, 1);
    assert.equal(result[0].id, 2);
  });

  it('finds multiple links matching same tag', () => {
    const result = filteredLinksForSearch(links, 'javascript');
    assert.equal(result.length, 2);
    assert.equal(result[0].id, 1);
    assert.equal(result[1].id, 3);
  });

  it('search is case-insensitive', () => {
    const result = filteredLinksForSearch(links, 'PYTHON');
    assert.equal(result.length, 1);
    assert.equal(result[0].id, 2);
  });

  it('returns empty when nothing matches', () => {
    assert.deepEqual(filteredLinksForSearch(links, 'nonexistent'), []);
  });
});

describe('searchHasAnyResult', () => {
  it('returns false when all results are empty', () => {
    assert.equal(searchHasAnyResult([], [], []), false);
  });

  it('returns true when links exist', () => {
    assert.equal(searchHasAnyResult([{ id: 1 }], [], []), true);
  });

  it('returns true when collections exist', () => {
    assert.equal(searchHasAnyResult([], [{ id: 1 }], []), true);
  });

  it('returns true when tags exist', () => {
    assert.equal(searchHasAnyResult([], [], ['javascript']), true);
  });
});

describe('collectionPreviewSections', () => {
  const collections = [
    { id: 1, ownerId: 1, name: 'Travel', description: '', color: '#ff0000', parentId: 0, parentName: '', linkCount: 5 },
    { id: 2, ownerId: 1, name: 'Recipes', description: '', color: '#00ff00', parentId: 0, parentName: '', linkCount: 3 },
  ];

  it('returns empty when no preview links exist', () => {
    const result = collectionPreviewSections(collections, [], [], Date.now());
    assert.deepEqual(result, []);
  });

  it('groups links by collection', () => {
    const links = [
      { id: 1, collectionId: 1, name: 'Paris guide' },
      { id: 2, collectionId: 1, name: 'Tokyo guide' },
      { id: 3, collectionId: 2, name: 'Pasta recipe' },
    ];
    const result = collectionPreviewSections(collections, links, [], Date.now());
    assert.equal(result.length, 2);
    assert.equal(result[0].collection.name, 'Travel');
    assert.equal(result[0].links.length, 2);
    assert.equal(result[1].collection.name, 'Recipes');
    assert.equal(result[1].links.length, 1);
  });

  it('skips collections with no matching links', () => {
    const links = [
      { id: 1, collectionId: 1, name: 'Paris guide' },
    ];
    const result = collectionPreviewSections(collections, links, [], Date.now());
    assert.equal(result.length, 1);
    assert.equal(result[0].collection.id, 1);
  });

  it('ranks by usage score (higher score first)', () => {
    const links = [
      { id: 1, collectionId: 1, name: 'Paris guide' },
      { id: 2, collectionId: 2, name: 'Pasta recipe' },
    ];
    const usage = [
      { collectionId: 1, score: 5 },
      { collectionId: 2, score: 50 },
    ];
    const result = collectionPreviewSections(collections, links, usage, Date.now());
    assert.equal(result[0].collection.name, 'Recipes');
    assert.equal(result[1].collection.name, 'Travel');
  });

  it('adds unorganized links at the end', () => {
    const links = [
      { id: 1, collectionId: 1, name: 'Paris guide' },
      { id: 2, collectionId: 0, name: 'Random link' },
    ];
    const result = collectionPreviewSections(collections, links, [], Date.now());
    assert.equal(result.length, 2);
    assert.equal(result[0].collection.name, 'Travel');
    assert.equal(result[1].collection.name, 'Unorganized');
    assert.equal(result[1].collection.id, 0);
    assert.equal(result[1].links.length, 1);
  });

  it('does not add unorganized section when no unorganized links', () => {
    const links = [
      { id: 1, collectionId: 1, name: 'Paris guide' },
    ];
    const result = collectionPreviewSections(collections, links, [], Date.now());
    assert.equal(result.length, 1);
    assert.equal(result[0].collection.name, 'Travel');
  });

  it('limits links per section', () => {
    const links = [];
    for (let i = 0; i < 15; i++) {
      links.push({ id: i, collectionId: 1, name: `Link ${i}` });
    }
    const result = collectionPreviewSections(collections, links, [], Date.now(), 5);
    assert.equal(result[0].links.length, 5);
  });
});
