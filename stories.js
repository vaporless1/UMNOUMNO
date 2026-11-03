/* УМНО: истории (как в Instagram) — лента кружков и полноэкранный просмотр 9:16.
   Работает в кабинете родителя (mode='parents') и в детском режиме (mode='kids'). */
const Stories = (() => {
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const initial = t => (String(t || '?').trim()[0] || '?').toUpperCase();
  const avatar = (url, title, cls = '') => url ? `<img class="sa ${cls}" src="${esc(url)}" alt="" loading="lazy" draggable="false">` : `<span class="sa ph ${cls}">${esc(initial(title))}</span>`;
  const IMG_DEFAULT = 5000;
  let muted = true;   // звук включается кнопкой в просмотре и остаётся до закрытия

  async function load(sb, mode, child) {
    const { data, error } = await sb.rpc('stories_feed', { p_mode: mode, p_child: child || null });
    if (error) { console.warn('stories:', error.message); return null }   // null — schema13 ещё не запущена
    return data || [];
  }

  // ---------- лента кружков ----------
  function stripHtml(topics, withCatalog) {
    return `<div class="sstrip" role="list">${topics.map((t, i) => `<button type="button" class="sit ${t.unseen ? 'new' : ''}" data-ti="${i}" role="listitem" aria-label="${esc(t.title)}${t.unseen ? ': есть новое' : ''}"><span class="ring">${avatar(t.avatar_url, t.title)}</span><b>${esc(t.title)}</b></button>`).join('')}`
      + (withCatalog ? `<button type="button" class="sit add" data-cat aria-label="Темы и подписки"><span class="ring"><span class="sa ph">+</span></span><b>Темы</b></button>` : '') + '</div>';
  }
  async function mount(sel, o) {
    const host = document.querySelector(sel); if (!host) return;
    const child = o.getChild ? o.getChild() : null;
    let topics = await load(o.sb, o.mode, child);
    if (!host.isConnected) return;
    if (topics === null) return host.remove();
    const parents = o.mode === 'parents';
    if (!topics.length) {
      if (!parents) return host.remove();
      const c = await o.sb.rpc('stories_catalog'); if (c.error || !(c.data || []).length) return host.remove();
    }
    const draw = () => {
      host.className = 'sbox'; host.innerHTML = stripHtml(topics, parents);
      host.querySelectorAll('[data-ti]').forEach(b => b.onclick = () => open(topics, +b.dataset.ti, { ...o, child, onClose: refresh }));
      host.querySelector('[data-cat]')?.addEventListener('click', () => catalog({ ...o, onClose: refresh }));
    };
    const refresh = async () => { const t = await load(o.sb, o.mode, child); if (t && host.isConnected) { topics = t; draw() } };
    draw();
  }

  // ---------- подписки на темы ----------
  async function catalog(o) {
    const m = o.modal(`<h2 style="font-family:Unbounded;font-size:19px;margin-bottom:6px">Темы историй</h2><p class="muted" style="margin-bottom:12px">Подпишитесь на то, что интересно. Подписки действуют и в режиме ребёнка.</p><div id="catBox"><p class="muted">Загружаем…</p></div><div class="row"><button class="btn line" id="catX">Закрыть</button></div>`);
    const AUD = { parents: 'для родителей', kids: 'для детей' };
    let list = [];
    const draw = () => {
      m.querySelector('#catBox').innerHTML = list.length ? list.map(t => `<div class="ctopic" data-id="${t.id}">${avatar(t.avatar_url, t.title, 'sm')}<div class="ct"><b>${esc(t.title)}</b>${t.description ? `<small>${esc(t.description)}</small>` : ''}
        <div class="ctags">${(t.audiences || []).filter(a => AUD[a]).map(a => `<em>${AUD[a]}</em>`).join('')}${(t.tags || []).slice(0, 5).map(x => `<span>#${esc(x)}</span>`).join('')}</div></div>
        ${t.default_on ? '<span class="cfix">всегда</span>' : `<button class="btn ${t.followed ? 'line' : ''} sm" data-f="${t.followed ? 0 : 1}">${t.followed ? 'Вы подписаны' : 'Подписаться'}</button>`}</div>`).join('') : '<p class="muted">Пока тем нет.</p>';
      m.querySelectorAll('[data-f]').forEach(b => b.onclick = async () => {
        const id = b.closest('.ctopic').dataset.id, on = b.dataset.f === '1'; b.disabled = true;
        const { error } = await o.sb.rpc('story_follow', { p_topic: id, p_on: on });
        if (error) { b.disabled = false; return o.toast(error.message, 1) }
        list.find(x => x.id === id).followed = on; draw();
      });
    };
    const close = () => { m.remove(); o.onClose && o.onClose() };
    m.querySelector('#catX').onclick = close;
    const { data, error } = await o.sb.rpc('stories_catalog');
    if (error) { m.querySelector('#catBox').innerHTML = '<p class="msg err">Не удалось загрузить темы.</p>'; return }
    list = data || []; draw();
  }

  // ---------- хэштег: список историй ----------
  function tagList(tag, topics, o) {
    const items = []; topics.forEach((t, ti) => t.stories.forEach((s, si) => { if ((s.hashtags || []).includes(tag)) items.push({ t, s, ti, si }) }));
    const m = o.modal(`<h2 style="font-family:Unbounded;font-size:19px;margin-bottom:12px">#${esc(tag)}</h2><div class="taglist">${items.map((x, i) => `<button type="button" class="tl" data-i="${i}">${avatar(x.s.cover_url || x.t.avatar_url, x.s.title, 'sm')}<span><b>${esc(x.s.title)}</b><small>${esc(x.t.title)}</small></span></button>`).join('') || '<p class="muted">Историй с таким тегом пока нет.</p>'}</div><div class="row"><button class="btn line" id="tgX">Закрыть</button></div>`);
    m.querySelector('#tgX').onclick = () => m.remove();
    m.querySelectorAll('[data-i]').forEach(b => b.onclick = () => { const x = items[+b.dataset.i]; m.remove(); open(topics, x.ti, { ...o, startStory: x.si }) });
  }

  // ---------- просмотр ----------
  let V = null;   // состояние открытого просмотра
  function lockPage() {
    const y = window.scrollY, h = document.documentElement, b = document.body;
    V.restore = { y, pos: b.style.position, top: b.style.top, w: b.style.width };
    b.style.position = 'fixed'; b.style.top = -y + 'px'; b.style.width = '100%'; h.classList.add('sv-lock');
  }
  function unlockPage() {
    const b = document.body, r = V.restore; document.documentElement.classList.remove('sv-lock');
    b.style.position = r.pos; b.style.top = r.top; b.style.width = r.w; window.scrollTo(0, r.y);
  }

  function open(topics, ti, o) {
    if (V) close(false);
    if (!topics[ti] || !topics[ti].stories.length) return;
    const t0 = topics[ti], first = o.startStory != null ? o.startStory : Math.max(0, t0.stories.findIndex(s => !s.seen));
    V = { topics, o, ti, si: first, ki: 0, paused: false, elapsed: 0, dur: IMG_DEFAULT, raf: 0, last: 0, ready: false, el: null, media: null };
    const el = document.createElement('div'); el.className = 'sv'; el.setAttribute('role', 'dialog'); el.setAttribute('aria-modal', 'true'); el.setAttribute('aria-label', 'Истории');
    el.innerHTML = `<div class="sv-stage"><div class="sv-media"></div><div class="sv-shade"></div>
      <div class="sv-bars"></div>
      <div class="sv-head"><span class="sv-av"></span><div class="sv-t"><b></b><small></small></div><button type="button" class="sv-b" data-mute data-ng aria-label="Звук"></button><button type="button" class="sv-b" data-x data-ng aria-label="Закрыть">✕</button></div>
      <div class="sv-load"></div>
      <div class="sv-foot"><div class="sv-cap"></div><div class="sv-desc"></div><div class="sv-tags"></div><a class="sv-link btn" data-ng hidden></a></div></div>`;
    document.body.append(el); V.el = el; lockPage();
    el.querySelector('[data-x]').onclick = () => close(true);
    el.querySelector('[data-mute]').onclick = e => { muted = !muted; if (V.media && V.media.tagName === 'VIDEO') V.media.muted = muted; paintMute() };
    bindGestures(); document.addEventListener('keydown', onKey);
    el.querySelector('.sv-link').addEventListener('click', onLink);
    show();
  }
  const cur = () => { const t = V.topics[V.ti], s = t.stories[V.si]; return { t, s, k: s.slides[V.ki] } };
  const paintMute = () => { const b = V.el.querySelector('[data-mute]'); const v = V.media && V.media.tagName === 'VIDEO'; b.hidden = !v; b.textContent = muted ? '🔇' : '🔊'; b.setAttribute('aria-label', muted ? 'Включить звук' : 'Выключить звук') };

  function show() {
    cancelAnimationFrame(V.raf); const { t, s, k } = cur(), el = V.el, host = el.querySelector('.sv-media');
    V.elapsed = 0; V.ready = false; V.dur = k.ms || IMG_DEFAULT;
    // шапка, полоски, подписи
    el.querySelector('.sv-av').innerHTML = avatar(s.cover_url || t.avatar_url, s.title, 'sm');
    el.querySelector('.sv-t b').textContent = s.title;
    el.querySelector('.sv-t small').textContent = t.title + (t.stories.length > 1 ? ` · ${V.si + 1} из ${t.stories.length}` : '');
    el.querySelector('.sv-bars').innerHTML = s.slides.map((_, i) => `<i><u style="width:${i < V.ki ? 100 : 0}%"></u></i>`).join('');
    el.querySelector('.sv-cap').textContent = k.caption || ''; el.querySelector('.sv-cap').hidden = !k.caption;
    const d = el.querySelector('.sv-desc'); d.textContent = s.description || ''; d.hidden = !s.description || V.ki > 0;
    const tg = el.querySelector('.sv-tags'); tg.hidden = !(s.hashtags || []).length; tg.innerHTML = (s.hashtags || []).map(x => `<button type="button" class="sv-tag" data-ng data-tag="${esc(x)}">#${esc(x)}</button>`).join('');
    tg.querySelectorAll('[data-tag]').forEach(b => b.onclick = () => { const tag = b.dataset.tag, topics = V.topics, oo = V.o; close(true); tagList(tag, topics, oo) });
    const a = el.querySelector('.sv-link'), isExt = k.link && /^https:/i.test(k.link), allowed = k.link && !(V.o.mode === 'kids' && isExt);   // детям внешние ссылки не показываем
    a.hidden = !allowed; if (allowed) { a.textContent = k.label || 'Открыть'; a.dataset.href = k.link; a.dataset.slide = k.id; a.href = isExt ? k.link : k.link }
    // медиа
    host.innerHTML = ''; el.classList.add('loading'); V.media = null;
    let node;
    if (k.kind === 'video') {
      node = document.createElement('video'); node.setAttribute('playsinline', ''); node.setAttribute('webkit-playsinline', ''); node.muted = muted; node.preload = 'auto'; node.controls = false;
      node.disablePictureInPicture = true; if (k.poster) node.poster = k.poster; node.src = k.url;
      node.onloadeddata = () => ready(Math.min(30000, (node.duration || 0) * 1000) || V.dur);
      node.onerror = () => ready(4000, true);
      node.onended = () => next();
    } else {
      node = new Image(); node.alt = ''; node.draggable = false; node.onload = () => ready(V.dur); node.onerror = () => ready(3000, true); node.src = k.url;
    }
    node.className = 'sv-m'; host.append(node); V.media = node; paintMute();
    markSeen(false); preload();
  }
  function ready(ms, failed) {
    if (!V || !V.el) return; V.ready = true; V.dur = ms; V.el.classList.remove('loading');
    if (failed) V.el.querySelector('.sv-load').dataset.err = '1'; else delete V.el.querySelector('.sv-load').dataset.err;
    if (V.media && V.media.tagName === 'VIDEO' && !failed) { const p = V.media.play(); if (p && p.catch) p.catch(() => { }) }
    V.last = performance.now(); tick();
  }
  function tick() {
    cancelAnimationFrame(V.raf);
    const loop = now => {
      if (!V) return; const dt = now - V.last; V.last = now;
      if (!V.paused && V.ready) {
        const vid = V.media && V.media.tagName === 'VIDEO' && !V.media.error;
        V.elapsed = vid ? V.media.currentTime * 1000 : V.elapsed + dt;
        const bar = V.el.querySelectorAll('.sv-bars u')[V.ki]; if (bar) bar.style.width = Math.min(100, V.elapsed / V.dur * 100) + '%';
        if (!vid && V.elapsed >= V.dur) return next();
      }
      V.raf = requestAnimationFrame(loop);
    };
    V.raf = requestAnimationFrame(loop);
  }
  function preload() {   // следующий кадр заранее
    const { t, s } = cur(); let n = s.slides[V.ki + 1] || (t.stories[V.si + 1] || {}).slides?.[0];
    if (n && n.kind === 'image') { const i = new Image(); i.src = n.url } else if (n && n.poster) { const i = new Image(); i.src = n.poster }
  }
  function markSeen(done) {
    const { s } = cur(); if (s._sent && !done) return; s._sent = true;
    if (V.o.sb) V.o.sb.rpc('story_seen', { p_story: s.id, p_child: V.o.mode === 'kids' ? V.o.child : null, p_done: !!done }).then(() => { }, () => { });
    if (done || !s.seen) { s.seen = true; const t = V.topics[V.ti]; t.unseen = t.stories.filter(x => !x.seen).length }
  }
  function next() {
    const { t, s } = cur();
    if (V.ki < s.slides.length - 1) { V.ki++; return show() }
    markSeen(true);
    if (V.si < t.stories.length - 1) { V.si++; V.ki = 0; return show() }
    nextTopic(true);
  }
  function prev() {
    if (V.elapsed > 1200 || (V.ki === 0 && V.si === 0 && V.ti === 0)) { return show() }   // в начале — перезапуск кадра
    if (V.ki > 0) { V.ki--; return show() }
    if (V.si > 0) { V.si--; V.ki = cur().s.slides.length - 1; return show() }
    prevTopic();
  }
  function nextTopic(end) {
    if (V.ti < V.topics.length - 1) { V.ti++; V.si = Math.max(0, V.topics[V.ti].stories.findIndex(s => !s.seen)); V.ki = 0; return show() }
    close(true);
  }
  function prevTopic() { if (V.ti > 0) { V.ti--; V.si = 0; V.ki = 0; show() } else show() }
  function setPause(p) { if (!V) return; V.paused = p; V.el.classList.toggle('paused', p); const m = V.media; if (m && m.tagName === 'VIDEO') { p ? m.pause() : m.play().catch(() => { }) } V.last = performance.now() }
  function onKey(e) { if (!V) return; if (e.key === 'Escape') close(true); else if (e.key === 'ArrowRight') next(); else if (e.key === 'ArrowLeft') prev() }
  function onLink(e) {
    const a = e.currentTarget, href = a.dataset.href; if (!href) return; e.preventDefault();
    if (V.o.sb) V.o.sb.rpc('story_click', { p_slide: a.dataset.slide }).then(() => { }, () => { });
    if (/^https:/i.test(href)) { window.open(href, '_blank', 'noopener'); return }
    close(true); if (href.startsWith('#')) location.hash = href; else location.href = href;
  }
  function close(callback) {
    if (!V) return; cancelAnimationFrame(V.raf); document.removeEventListener('keydown', onKey);
    const m = V.media; if (m && m.tagName === 'VIDEO') { m.pause(); m.removeAttribute('src'); m.load() }
    V.el.remove(); unlockPage(); const cb = V.o.onClose; V = null; if (callback && cb) cb();
  }

  // жесты: тап слева/справа, удержание — пауза, свайп вниз — закрыть, влево/вправо — другая тема
  function bindGestures() {
    const st = V.el.querySelector('.sv-stage'); let g = null;
    st.addEventListener('pointerdown', e => {
      if (e.target.closest('[data-ng]')) return; if (e.pointerType === 'mouse' && e.button !== 0) return;
      try { st.setPointerCapture(e.pointerId) } catch { }
      g = { x: e.clientX, y: e.clientY, t: performance.now(), held: false, dx: 0, dy: 0, id: e.pointerId };
      g.timer = setTimeout(() => { if (g) { g.held = true; setPause(true) } }, 220);
    });
    st.addEventListener('pointermove', e => {
      if (!g || e.pointerId !== g.id) return; g.dx = e.clientX - g.x; g.dy = e.clientY - g.y;
      if (Math.abs(g.dx) > 10 || Math.abs(g.dy) > 10) { clearTimeout(g.timer); if (!g.held) setPause(true), g.held = true }
      if (g.dy > 0 && g.dy > Math.abs(g.dx)) { st.style.transform = `translateY(${g.dy * .6}px) scale(${1 - Math.min(g.dy, 400) / 2400})`; st.style.transition = 'none'; V.el.style.background = `rgba(0,0,0,${Math.max(.2, 1 - g.dy / 500)})` }
    });
    const end = e => {
      if (!g || e.pointerId !== g.id) return; clearTimeout(g.timer); const { dx, dy, held } = g, dt = performance.now() - g.t; g = null;
      st.style.transition = 'transform .2s'; st.style.transform = ''; V.el.style.background = '';
      if (e.type === 'pointercancel') { setPause(false); return }
      if (dy > 110 && dy > Math.abs(dx)) { setPause(false); return close(true) }
      if (Math.abs(dx) > 70 && Math.abs(dx) > Math.abs(dy)) { setPause(false); return dx < 0 ? nextTopic() : prevTopic() }
      if (held && dt > 220) { setPause(false); return }   // удержание: просто продолжаем
      setPause(false); const r = st.getBoundingClientRect(); (e.clientX - r.left) < r.width * .33 ? prev() : next();
    };
    st.addEventListener('pointerup', end); st.addEventListener('pointercancel', end);
    st.addEventListener('contextmenu', e => e.preventDefault());
  }

  document.addEventListener('visibilitychange', () => { if (V) setPause(document.hidden) });
  return { mount, open, load, catalog, stripHtml };
})();
