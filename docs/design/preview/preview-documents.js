(function (browser) {
  'use strict';
  class PreviewDocumentStore {
    constructor() {
      this.documents = [{ id: 'chapter-1', kind: 'chapters', title: '第一章', body: '', memo: '', edited: false }];
      this.nextId = 2;
      this.projectName = '未命名小说';
      this.listeners = new Set();
      this.segmenter = typeof Intl.Segmenter === 'function' ? new Intl.Segmenter('zh-CN', { granularity: 'grapheme' }) : null;
    }
    get(id) { return this.documents.find(item => item.id === id); }
    list(kind) { return this.documents.filter(item => item.kind === kind); }
    count(text) {
      const value = text.replace(/\s/gu, '');
      return this.segmenter ? Array.from(this.segmenter.segment(value)).length : Array.from(value).length;
    }
    create(kind) {
      const document = { id: 'document-' + this.nextId++, kind,
        title: kind === 'chapters' ? '第' + (this.list(kind).length + 1) + '章' : '未命名笔记',
        body: '', memo: '', edited: false };
      this.documents.push(document);
      this.notify(document.id);
      return document;
    }
    update(id, patch) {
      const document = this.get(id);
      if (!document) return;
      for (const key of ['title', 'body', 'memo']) if (key in patch) document[key] = patch[key];
      document.edited = true;
      this.notify(id);
    }
    subscribe(listener) { this.listeners.add(listener); return () => this.listeners.delete(listener); }
    notify(id) { for (const listener of this.listeners) listener(id); }
  }
  Object.assign(browser.NovelEnginePreview ||= {}, { PreviewDocumentStore });
})(window);
