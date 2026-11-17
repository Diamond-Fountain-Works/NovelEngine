const test = require('node:test');
const assert = require('node:assert/strict');
const { WorkspaceLayout } = require('../workspace-layout.js');

for (const direction of ['left', 'right', 'up', 'down']) {
  test('split ' + direction + ' preserves the document and uses the correct axis/order', () => {
    const layout = new WorkspaceLayout('chapter-a');
    const original = layout.activePaneId;
    const added = layout.split(direction);
    assert.equal(layout.leaves().length, 2);
    assert.equal(layout.root.axis, ['left', 'right'].includes(direction) ? 'horizontal' : 'vertical');
    assert.equal(layout.root.first.id, ['left', 'up'].includes(direction) ? added.id : original);
    assert.deepEqual(layout.leaves().map(p => p.documentId), ['chapter-a', 'chapter-a']);
    assert.equal(layout.activePaneId, added.id);
  });
}
test('joining either side retains the chosen document and selects a surviving pane', () => {
  for (const keep of ['first', 'second']) {
    const layout = new WorkspaceLayout('a');
    layout.split('right'); layout.openDocument('b');
    const survivor = layout.root[keep];
    assert.equal(layout.join(layout.root.id, keep), true);
    assert.equal(layout.root.id, survivor.id);
    assert.equal(layout.activePaneId, survivor.id);
  }
});
test('nested joins retain the surviving group and undo restores the exact tree', () => {
  const layout = new WorkspaceLayout('a');
  layout.split('right'); layout.split('down');
  const before = structuredClone(layout.root), active = layout.activePaneId;
  assert.equal(layout.joinChoices().length, 4);
  layout.join(layout.root.id, 'second');
  assert.equal(layout.leaves().length, 2);
  layout.undo();
  assert.deepEqual(layout.root, before); assert.equal(layout.activePaneId, active);
});
test('resize is bounded and rejects non-finite values without corrupting the tree', () => {
  const layout = new WorkspaceLayout('a'); layout.split('right');
  assert.equal(layout.resize(layout.root.id, NaN), false); assert.equal(layout.root.ratio, .5);
  layout.resize(layout.root.id, 2); assert.equal(layout.root.ratio, .9);
  layout.resize(layout.root.id, -1); assert.equal(layout.root.ratio, .1);
});
test('reset retains the active document and is reversible', () => {
  const layout = new WorkspaceLayout('a'); layout.split('down'); layout.openDocument('b');
  layout.reset(); assert.equal(layout.root.documentId, 'b'); assert.equal(layout.leaves().length, 1);
  layout.undo(); assert.equal(layout.leaves().length, 2);
});
test('pane IDs remain unique after undo followed by a different split', () => {
  const layout = new WorkspaceLayout('a'); const discarded = layout.split('right').id;
  layout.undo(); const newId = layout.split('left').id;
  assert.notEqual(newId, discarded); assert.equal(new Set(layout.leaves().map(p => p.id)).size, 2);
});
test('invalid join and split do not discard the current layout', () => {
  const layout = new WorkspaceLayout('a');
  assert.equal(layout.join('not-a-split', 'first'), false);
  assert.throws(() => layout.split('diagonal'), /Invalid split direction/);
  assert.equal(layout.leaves().length, 1); assert.equal(layout.history.length, 0);
});
