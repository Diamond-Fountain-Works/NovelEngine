(function () {
  'use strict';
  const { WorkspaceLayout, PreviewDocumentStore } = window.NovelEnginePreview;
  const $ = id => document.getElementById(id);

  class WorkspacePreview {
    constructor() {
      this.store = new PreviewDocumentStore();
      this.layout = new WorkspaceLayout('chapter-1');
      this.section = 'chapters';
      this.theme = 'light';
      this.focused = false;
      this.inspectorVisible = false;
      this.compact = $('app-window').getBoundingClientRect().width <= 720;
      this.views = new Map();
      this.viewState = new Map();
      this.observer = new ResizeObserver(() => requestAnimationFrame(() => { this.growAll(); this.updateSplitControls(); }));
      this.store.subscribe(() => this.refreshAll());
      this.bindControls();
      this.renderWorkspace();
      this.windowObserver = new ResizeObserver(entries => {
        const compact = entries[0].contentRect.width <= 720;
        if (compact !== this.compact) {
          this.captureViewState(); this.compact = compact; this.renderWorkspace();
        }
      });
      this.windowObserver.observe($('app-window'));
      const parameters = new URLSearchParams(location.search);
      if (parameters.get('theme') === 'dark') this.setTheme('dark');
      const device = parameters.get('device');
      if (['desktop', 'tablet', 'duo', 'phone'].includes(device)) this.setDevice(device);
      document.fonts.ready.then(() => this.growAll());
    }
    icon(name) {
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.classList.add('icon'); svg.setAttribute('aria-hidden', 'true');
      const use = document.createElementNS('http://www.w3.org/2000/svg', 'use');
      use.setAttribute('href', '#i-' + name); svg.append(use); return svg;
    }
    activePane() { return this.layout.find(this.layout.activePaneId); }
    role(view, name) { return view.querySelector('[data-role="' + name + '"]'); }
    activate(paneId) {
      if (paneId === this.layout.activePaneId) return;
      const needsRender = this.compact && !this.views.has(paneId);
      if (needsRender) this.captureViewState();
      this.layout.activate(paneId);
      const doc = this.store.get(this.activePane().documentId);
      if (doc) this.section = doc.kind;
      if (needsRender) this.renderWorkspace(); else this.refreshAll();
    }
    captureViewState() {
      for (const [id, view] of this.views) {
        const body = this.role(view, 'prose');
        this.viewState.set(id, { scroll: this.role(view, 'editor-scroll').scrollTop,
          start: body.selectionStart, end: body.selectionEnd });
      }
    }
    renderWorkspace() {
      this.observer.disconnect(); this.views.clear();
      const root = this.focused || this.compact ? this.activePane() : this.layout.root;
      $('layout-root').replaceChildren(this.renderNode(root));
      $('app-window').classList.toggle('focus-mode', this.focused);
      this.refreshAll(); this.growAll();
      for (const [id, view] of this.views) {
        const previous = this.viewState.get(id);
        if (previous) {
          this.role(view, 'editor-scroll').scrollTop = previous.scroll;
          this.role(view, 'prose').setSelectionRange(previous.start, previous.end);
        }
      }
    }
    renderNode(node) {
      if (node.type === 'pane') return this.makeEditor(node);
      const split = document.createElement('div');
      split.className = 'split-node axis-' + node.axis;
      split.dataset.splitId = node.id;
      const first = document.createElement('div'), second = document.createElement('div');
      first.className = second.className = 'split-child';
      first.append(this.renderNode(node.first)); second.append(this.renderNode(node.second));
      const divider = document.createElement('div');
      divider.className = 'pane-divider'; divider.tabIndex = 0;
      divider.setAttribute('role', 'separator');
      divider.setAttribute('aria-label', node.axis === 'horizontal' ? '调整左右分栏大小' : '调整上下分栏大小');
      divider.setAttribute('aria-orientation', node.axis === 'horizontal' ? 'vertical' : 'horizontal');
      divider.setAttribute('aria-valuemin', '10'); divider.setAttribute('aria-valuemax', '90');
      divider.title = '拖动调整大小；右键合并分栏';
      const applyRatio = () => {
        first.style.flexGrow = node.ratio;
        second.style.flexGrow = 1 - node.ratio;
        divider.setAttribute('aria-valuenow', String(Math.round(node.ratio * 100)));
      };
      applyRatio();
      divider.addEventListener('pointerdown', event => {
        if (event.button !== 0) return;
        event.preventDefault(); this.closeMenus(); divider.focus({ preventScroll: true });
        divider.setPointerCapture(event.pointerId);
        let changed = false;
        divider.onpointermove = move => {
          const frame = split.getBoundingClientRect();
          const size = node.axis === 'horizontal' ? frame.width : frame.height;
          const position = node.axis === 'horizontal' ? move.clientX - frame.left : move.clientY - frame.top;
          const margin = Math.min(.42, 140 / size);
          if (!changed) { this.layout.checkpoint(); changed = true; }
          this.layout.resize(node.id, Math.min(1 - margin, Math.max(margin, position / size)));
          applyRatio();
        };
        const stop = () => { divider.onpointermove = null; divider.onpointerup = null; divider.onpointercancel = null; };
        divider.onpointerup = stop; divider.onpointercancel = stop;
      });
      divider.addEventListener('keydown', event => {
        const allowed = node.axis === 'horizontal' ? ['ArrowLeft', 'ArrowRight'] : ['ArrowUp', 'ArrowDown'];
        if (allowed.includes(event.key)) {
          event.preventDefault(); this.layout.checkpoint();
          this.layout.resize(node.id, node.ratio + (event.key === allowed[0] ? -.05 : .05)); applyRatio();
        }
        if (event.key === 'Enter' || (event.shiftKey && event.key === 'F10')) {
          event.preventDefault(); const box = divider.getBoundingClientRect();
          this.showJoinMenu(node, box.left + 4, box.top + 10);
        }
      });
      divider.addEventListener('dblclick', () => { this.layout.checkpoint(); this.layout.resize(node.id, .5); applyRatio(); });
      divider.addEventListener('contextmenu', event => { event.preventDefault(); this.showJoinMenu(node, event.clientX, event.clientY); });
      split.append(first, divider, second); return split;
    }
    makeEditor(node) {
      const view = $('editor-template').content.firstElementChild.cloneNode(true);
      view.dataset.paneId = node.id;
      this.views.set(node.id, view);
      view.addEventListener('pointerdown', () => this.activate(node.id));
      view.addEventListener('focusin', () => this.activate(node.id));
      const field = name => this.role(view, name);
      for (const name of ['chapter-title', 'prose', 'chapter-memo']) {
        field(name).id = node.id + '-' + name;
        field(name).addEventListener('compositionstart', () => field(name).dataset.composing = 'true');
        const update = () => {
          if (field(name).dataset.composing === 'true') return;
          const key = { 'chapter-title': 'title', prose: 'body', 'chapter-memo': 'memo' }[name];
          this.store.update(node.documentId, { [key]: field(name).value });
        };
        field(name).addEventListener('input', update);
        field(name).addEventListener('compositionend', () => { delete field(name).dataset.composing; update(); });
      }
      view.querySelector('label[for="chapter-memo"]').htmlFor = node.id + '-chapter-memo';
      field('tab-add').addEventListener('click', () => this.newDocument());
      field('mobile-sidebar').addEventListener('click', () => this.toggleSidebar());
      field('format-toggle').addEventListener('click', event => this.openTypography(event.currentTarget));
      field('focus-toggle').addEventListener('click', () => {
        this.captureViewState(); this.focused = !this.focused;
        this.inspectorVisible = false; this.closeMenus(); this.renderWorkspace();
      });
      field('inspector-close').addEventListener('click', () => { this.inspectorVisible = false; this.refreshAll(); });
      view.addEventListener('contextmenu', event => {
        if (event.target.closest('input,textarea')) return;
        const rect = view.getBoundingClientRect();
        if (!event.target.closest('.tabs,.editor-toolbar') && event.clientX > rect.left + 8 && event.clientX < rect.right - 8) return;
        event.preventDefault(); this.activate(node.id); this.showJoinMenu(null, event.clientX, event.clientY);
      });
      this.observer.observe(field('editor-scroll'));
      return view;
    }
    refreshAll() {
      for (const [id, view] of this.views) this.syncEditor(this.layout.find(id), view);
      this.renderSidebar();
      $('inspector-toggle').setAttribute('aria-expanded', String(this.inspectorVisible));
      $('workspace-layout-toggle').setAttribute('aria-label', '布局操作，当前 ' + this.layout.leaves().length + ' 个分栏');
      this.updateSplitControls();
    }
    syncEditor(node, view) {
      if (!node) return;
      const doc = this.store.get(node.documentId), active = node.id === this.layout.activePaneId;
      const field = name => this.role(view, name), kind = doc?.kind === 'notes' ? '笔记' : '章节';
      view.classList.toggle('is-active', active);
      view.setAttribute('aria-label', (active ? '当前分栏：' : '分栏：') + (doc?.title || '未打开文档'));
      for (const [name, key] of [['chapter-title', 'title'], ['prose', 'body'], ['chapter-memo', 'memo']]) {
        const control = field(name); control.disabled = !doc;
        if (document.activeElement !== control && control.dataset.composing !== 'true') control.value = doc?.[key] || '';
      }
      field('chapter-title').placeholder = '未命名' + kind;
      field('prose').placeholder = doc ? '开始输入' + (doc.kind === 'notes' ? '笔记…' : '正文…') : '点击 + 新建文档';
      field('tab-title').textContent = doc?.title || '未打开文档';
      field('project-crumb').textContent = this.store.projectName || '未命名小说';
      field('document-kind').textContent = kind; field('info-kind').textContent = kind;
      field('inspector-title').textContent = kind + '信息';
      field('tab-add').setAttribute('aria-label', '新建' + kind);
      const amount = this.store.count(doc?.body || ''), paragraphs = (doc?.body || '').split(/\n+/).filter(x => x.trim()).length;
      field('word-count').textContent = amount + ' 字'; field('info-count').textContent = String(amount);
      field('paragraph-count').textContent = paragraphs + ' 段'; field('info-paragraphs').textContent = String(paragraphs);
      field('edit-status').textContent = doc?.edited ? '已修改' : doc ? '空白文档' : '未打开文档';
      field('edited-mark').hidden = !doc?.edited;
      field('inspector').hidden = !(this.inspectorVisible && active && !this.focused);
      field('format-toggle').setAttribute('aria-expanded', String(active && !$('typography').hidden));
      field('focus-toggle').setAttribute('aria-pressed', String(this.focused));
      field('focus-toggle').querySelector('use').setAttribute('href', '#i-' + (this.focused ? 'arrows-pointing-in' : 'arrows-pointing-out'));
      this.grow(view);
    }
    grow(view) {
      const body = this.role(view, 'prose'); body.style.height = 'auto';
      body.style.height = Math.max(120, body.scrollHeight) + 'px';
    }
    growAll() { for (const view of this.views.values()) this.grow(view); }
    renderSidebar() {
      const tree = $('document-tree'), items = this.store.list(this.section);
      tree.replaceChildren();
      if (this.section === 'chapters') {
        const group = document.createElement('div'); group.className = 'group-title';
        group.append(this.icon('chevron-down'), document.createTextNode('正文')); tree.append(group);
      }
      const query = $('chapter-search').value.trim().toLocaleLowerCase();
      const visible = items.filter(doc => doc.title.toLocaleLowerCase().includes(query));
      if (!visible.length) {
        const empty = document.createElement('div'); empty.className = 'tree-empty';
        empty.textContent = query ? '没有匹配项' : this.section === 'notes' ? '暂无笔记' : '暂无章节'; tree.append(empty);
      }
      for (const doc of visible) {
        const row = document.createElement('button'); row.type = 'button'; row.className = 'chapter-row';
        row.setAttribute('aria-current', String(doc.id === this.activePane().documentId));
        row.append(this.icon(this.section === 'chapters' ? 'document-text' : 'pencil-square'));
        const label = document.createElement('span'); label.className = 'row-label';
        const title = document.createElement('strong'), count = document.createElement('small');
        title.textContent = doc.title || '未命名'; count.textContent = this.store.count(doc.body) + ' 字';
        label.append(title, count); row.append(label);
        row.addEventListener('click', () => { this.layout.openDocument(doc.id); this.refreshAll(); $('app-window').classList.remove('sidebar-open'); });
        tree.append(row);
      }
      $('document-count').textContent = items.length + (this.section === 'chapters' ? ' 章' : ' 篇笔记');
      $('total-count').textContent = items.reduce((sum, doc) => sum + this.store.count(doc.body), 0) + ' 字';
      document.querySelectorAll('[data-section]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.section === this.section)));
      $('rail-chapters').setAttribute('aria-pressed', String(this.section === 'chapters'));
      $('rail-notes').setAttribute('aria-pressed', String(this.section === 'notes'));
      $('chapter-search').placeholder = this.section === 'chapters' ? '搜索章节' : '搜索笔记';
      $('add-document').setAttribute('aria-label', this.section === 'chapters' ? '新建章节' : '新建笔记');
    }
    switchSection(section) {
      this.section = section; $('chapter-search').value = '';
      this.layout.openDocument(this.store.list(section)[0]?.id || null); this.refreshAll();
    }
    newDocument() {
      const doc = this.store.create(this.section); this.layout.openDocument(doc.id);
      $('chapter-search').value = ''; $('app-window').classList.remove('sidebar-open'); this.refreshAll();
      const title = this.role(this.views.get(this.layout.activePaneId), 'chapter-title'); title.focus(); title.select();
    }
    canSplit(direction) {
      if (this.compact || this.focused) return false;
      const frame = this.views.get(this.layout.activePaneId).getBoundingClientRect();
      return ['left', 'right'].includes(direction) ? frame.width >= 480 : frame.height >= 360;
    }
    split(direction) {
      if (!this.canSplit(direction)) return;
      this.captureViewState(); this.layout.split(direction); this.closeMenus(); this.renderWorkspace();
      this.role(this.views.get(this.layout.activePaneId), 'prose').focus();
    }
    updateSplitControls() {
      if (!this.views.has(this.layout.activePaneId)) return;
      for (const button of document.querySelectorAll('[data-split]')) {
        button.disabled = !this.canSplit(button.dataset.split);
        button.title = button.disabled ? this.focused ? '退出专注后分栏' : '空间不足' : button.getAttribute('aria-label');
      }
    }
    positionMenu(menu, x, y, withinApp = false) {
      menu.hidden = false;
      const app = $('app-window').getBoundingClientRect(), rect = menu.getBoundingClientRect();
      const left = withinApp ? app.left + 8 : 8, top = withinApp ? app.top + 8 : 8;
      const right = withinApp ? app.right - 8 : innerWidth - 8, bottom = withinApp ? app.bottom - 8 : innerHeight - 8;
      menu.style.left = Math.max(left, Math.min(x, right - rect.width)) + 'px';
      menu.style.top = Math.max(top, Math.min(y, bottom - rect.height)) + 'px';
    }
    openLayoutMenu() {
      if (!$('layout-popover').hidden) { this.closeMenus(); return; }
      this.closeMenus();
      const openPanes = $('layout-open-panes'); openPanes.replaceChildren();
      if (this.compact && this.layout.leaves().length > 1) {
        this.layout.leaves().forEach((pane, index) => {
          const button = document.createElement('button'); button.type = 'button'; button.setAttribute('role', 'menuitem');
          button.textContent = '分栏 ' + (index + 1) + ' · ' + (this.store.get(pane.documentId)?.title || '未打开文档');
          button.setAttribute('aria-current', String(pane.id === this.layout.activePaneId));
          button.addEventListener('click', () => { this.closeMenus(); this.activate(pane.id); }); openPanes.append(button);
        });
      }
      $('layout-undo').disabled = !this.layout.history.length;
      $('layout-reset').disabled = this.layout.leaves().length === 1;
      const anchor = $('workspace-layout-toggle').getBoundingClientRect();
      this.positionMenu($('layout-popover'), anchor.right - 192, anchor.bottom + 5, true);
      $('workspace-layout-toggle').setAttribute('aria-expanded', 'true');
    }
    showJoinMenu(split, x, y) {
      this.closeMenus();
      const choices = this.compact ? [] : split ? ['first', 'second'].map((keep, index) => ({ splitId: split.id, keep,
        direction: (split.axis === 'horizontal' ? ['Left', 'Right'] : ['Up', 'Down'])[index],
        paneCount: this.layout.leaves(split[keep]).length })) : this.layout.joinChoices();
      const items = $('join-items'); items.replaceChildren();
      if (!choices.length) {
        for (const direction of ['Left', 'Right']) { const button = document.createElement('button'); button.type = 'button';
          button.className = 'join-command'; button.disabled = true; button.textContent = 'Join ' + direction; items.append(button); }
      }
      const order = ['Right', 'Left', 'Down', 'Up'];
      for (const choice of choices.sort((a, b) => order.indexOf(a.direction) - order.indexOf(b.direction))) {
        const button = document.createElement('button'); button.type = 'button'; button.className = 'join-command'; button.setAttribute('role', 'menuitem');
        const label = document.createElement('span');
        label.textContent = 'Join ' + choice.direction;
        const icon = this.icon('chevron-right'); icon.classList.add('join-direction', 'direction-' + choice.direction.toLowerCase());
        button.append(icon, label);
        button.addEventListener('click', () => { this.captureViewState(); this.layout.join(choice.splitId, choice.keep); this.closeMenus(); this.renderWorkspace(); });
        items.append(button);
      }
      this.positionMenu($('join-menu'), x, y);
    }
    closeMenus() {
      for (const id of ['layout-popover', 'join-menu', 'typography']) $(id).hidden = true;
      $('workspace-layout-toggle').setAttribute('aria-expanded', 'false');
      for (const view of this.views.values()) this.role(view, 'format-toggle').setAttribute('aria-expanded', 'false');
    }
    openTypography(anchor) {
      const wasOpen = !$('typography').hidden;
      this.closeMenus(); this.inspectorVisible = false; this.refreshAll();
      if (wasOpen) return;
      const rect = anchor.getBoundingClientRect();
      this.positionMenu($('typography'), rect.right - 252, rect.bottom + 7, true);
      anchor.setAttribute('aria-expanded', 'true');
    }
    toggleSidebar() {
      this.closeMenus(); this.inspectorVisible = false; this.refreshAll();
      const app = $('app-window');
      app.classList.toggle(app.getBoundingClientRect().width <= 720 ? 'sidebar-open' : 'sidebar-hidden');
    }
    setTheme(theme) {
      this.theme = theme; document.documentElement.dataset.theme = theme;
      document.querySelectorAll('[data-theme-button]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.themeButton === theme)));
      $('theme-toggle').replaceChildren(this.icon(theme === 'dark' ? 'sun' : 'moon'));
    }
    setDevice(device) {
      $('app-window').dataset.device = device;
      document.querySelectorAll('[data-device-button]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.deviceButton === device)));
      $('app-window').classList.remove('sidebar-open', 'sidebar-hidden'); this.closeMenus();
    }
    bindControls() {
      document.querySelectorAll('[data-theme-button]').forEach(button => button.addEventListener('click', () => this.setTheme(button.dataset.themeButton)));
      document.querySelectorAll('[data-device-button]').forEach(button => button.addEventListener('click', () => this.setDevice(button.dataset.deviceButton)));
      document.querySelectorAll('[data-section]').forEach(button => button.addEventListener('click', () => this.switchSection(button.dataset.section)));
      $('rail-chapters').addEventListener('click', () => this.switchSection('chapters'));
      $('rail-notes').addEventListener('click', () => this.switchSection('notes'));
      $('add-document').addEventListener('click', () => this.newDocument());
      $('chapter-search').addEventListener('input', () => this.renderSidebar());
      $('project-name').addEventListener('input', () => { this.store.projectName = $('project-name').value; this.refreshAll(); });
      $('theme-toggle').addEventListener('click', () => this.setTheme(this.theme === 'light' ? 'dark' : 'light'));
      $('sidebar-toggle').addEventListener('click', () => this.toggleSidebar());
      for (const id of ['sidebar-close', 'sidebar-scrim']) $(id).addEventListener('click', () => $('app-window').classList.remove('sidebar-open'));
      $('inspector-toggle').addEventListener('click', () => { this.closeMenus(); this.inspectorVisible = !this.inspectorVisible; this.refreshAll(); });
      $('rail-format').addEventListener('click', event => this.openTypography(event.currentTarget));
      $('format-close').addEventListener('click', () => this.closeMenus());
      $('workspace-layout-toggle').addEventListener('click', () => this.openLayoutMenu());
      document.querySelectorAll('[data-split]').forEach(button => button.addEventListener('click', () => this.split(button.dataset.split)));
      $('layout-undo').addEventListener('click', () => { this.captureViewState(); this.layout.undo(); this.closeMenus(); this.renderWorkspace(); });
      $('layout-reset').addEventListener('click', () => { this.captureViewState(); this.layout.reset(); this.closeMenus(); this.renderWorkspace(); });
      document.querySelector('.sidebar').addEventListener('contextmenu', event => {
        if (event.target.closest('input,textarea')) return;
        event.preventDefault(); this.showJoinMenu(null, event.clientX, event.clientY);
      });
      $('font-size').addEventListener('input', event => { document.documentElement.style.setProperty('--size', event.target.value + 'px'); $('font-size-value').textContent = event.target.value; this.growAll(); });
      $('line-width').addEventListener('input', event => { document.documentElement.style.setProperty('--measure', event.target.value + 'px'); $('line-width-value').textContent = event.target.value; this.growAll(); });
      for (const id of ['font-serif', 'font-sans']) $(id).addEventListener('click', () => {
        document.documentElement.style.setProperty('--prose', id === 'font-serif' ? "'Songti SC','STSong','Noto Serif CJK SC',Georgia,serif" : "-apple-system,BlinkMacSystemFont,'PingFang SC','Microsoft YaHei',sans-serif");
        $('font-serif').setAttribute('aria-pressed', String(id === 'font-serif')); $('font-sans').setAttribute('aria-pressed', String(id === 'font-sans')); this.growAll();
      });
      document.addEventListener('keydown', event => {
        if (event.key === 'Escape') { this.closeMenus(); this.inspectorVisible = false; $('app-window').classList.remove('sidebar-open'); this.refreshAll(); }
        if (['ArrowDown', 'ArrowUp'].includes(event.key) && event.target.closest('[role="menu"]')) {
          const buttons = [...event.target.closest('[role="menu"]').querySelectorAll('button:not(:disabled)')];
          if (buttons.length) { event.preventDefault(); const index = buttons.indexOf(document.activeElement); buttons[(index + (event.key === 'ArrowDown' ? 1 : buttons.length - 1)) % buttons.length].focus(); }
        }
      });
      document.addEventListener('pointerdown', event => {
        if (!event.target.closest('#layout-popover,#join-menu,#typography,#workspace-layout-toggle,[data-role="format-toggle"],#rail-format')) this.closeMenus();
      });
      document.querySelectorAll('svg.icon').forEach(svg => { svg.setAttribute('aria-hidden', 'true'); svg.setAttribute('focusable', 'false'); });
    }
  }
  new WorkspacePreview();
})();
