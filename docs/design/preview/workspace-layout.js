/* Design preview layout model. Document data is owned by the document store. */
(function (browser, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (browser) Object.assign(browser.NovelEnginePreview ||= {}, api);
})(typeof window === 'undefined' ? null : window, function () {
  'use strict';
  const copy = value => JSON.parse(JSON.stringify(value));

  class WorkspaceLayout {
    constructor(documentId) {
      this.sequence = 1;
      this.root = this.makePane(documentId);
      this.activePaneId = this.root.id;
      this.history = [];
    }
    makePane(documentId) {
      return { type: 'pane', id: 'pane-' + this.sequence++, documentId };
    }
    leaves(node = this.root) {
      return node.type === 'pane' ? [node] : [...this.leaves(node.first), ...this.leaves(node.second)];
    }
    find(id, node = this.root) {
      if (node.id === id) return node;
      return node.type === 'split' ? this.find(id, node.first) || this.find(id, node.second) : null;
    }
    path(id, node = this.root, ancestors = []) {
      if (node.id === id) return ancestors;
      if (node.type === 'pane') return null;
      return this.path(id, node.first, [...ancestors, node]) || this.path(id, node.second, [...ancestors, node]);
    }
    replace(id, replacement, node = this.root) {
      if (node.id === id) return replacement;
      if (node.type === 'pane') return node;
      node.first = this.replace(id, replacement, node.first);
      node.second = this.replace(id, replacement, node.second);
      return node;
    }
    checkpoint() {
      this.history.push({ root: copy(this.root), activePaneId: this.activePaneId });
      if (this.history.length > 40) this.history.shift();
    }
    activate(paneId) {
      if (this.find(paneId)?.type !== 'pane') return false;
      this.activePaneId = paneId;
      return true;
    }
    openDocument(documentId) {
      this.find(this.activePaneId).documentId = documentId;
    }
    split(direction) {
      if (!['left', 'right', 'up', 'down'].includes(direction)) throw new Error('Invalid split direction');
      const current = this.find(this.activePaneId);
      if (!current || current.type !== 'pane') return null;
      this.checkpoint();
      const added = this.makePane(current.documentId);
      const before = direction === 'left' || direction === 'up';
      const split = {
        type: 'split', id: 'split-' + this.sequence++,
        axis: ['left', 'right'].includes(direction) ? 'horizontal' : 'vertical', ratio: 0.5,
        first: before ? added : current, second: before ? current : added
      };
      this.root = this.replace(current.id, split);
      this.activePaneId = added.id;
      return added;
    }
    join(splitId, keep) {
      const split = this.find(splitId);
      if (!split || split.type !== 'split' || !['first', 'second'].includes(keep)) return false;
      this.checkpoint();
      const survivor = split[keep];
      this.root = this.replace(splitId, survivor);
      if (!this.find(this.activePaneId)) this.activePaneId = this.leaves(survivor)[0].id;
      return true;
    }
    resize(splitId, ratio) {
      const split = this.find(splitId);
      if (!split || split.type !== 'split' || !Number.isFinite(ratio)) return false;
      split.ratio = Math.min(0.9, Math.max(0.1, ratio));
      return true;
    }
    joinChoices(paneId = this.activePaneId) {
      const ancestors = (this.path(paneId) || []).slice().reverse();
      const axes = new Set(), result = [];
      for (const split of ancestors) {
        if (axes.has(split.axis)) continue;
        axes.add(split.axis);
        const directions = split.axis === 'horizontal' ? ['Left', 'Right'] : ['Up', 'Down'];
        for (const [index, keep] of ['first', 'second'].entries()) {
          result.push({ splitId: split.id, keep, direction: directions[index], paneCount: this.leaves(split[keep]).length });
        }
      }
      return result;
    }
    undo() {
      const previous = this.history.pop();
      if (!previous) return false;
      this.root = previous.root;
      this.activePaneId = previous.activePaneId;
      return true;
    }
    reset() {
      if (this.root.type === 'pane') return false;
      this.checkpoint();
      this.root = this.find(this.activePaneId);
      return true;
    }
  }
  return { WorkspaceLayout };
});
