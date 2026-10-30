/* ===== Движок заданий. Q.run(root, tasks, opts) — используется в кабинете и в предпросмотре админки ===== */
const Q = (() => {
  const PRAISE = ['Молодец!', 'Верно!', 'Отлично!', 'Умница!', 'Так держать!'];
  const TRY = ['Почти!', 'Попробуем ещё!', 'Не страшно!'];
  const pick = a => a[Math.floor(Math.random() * a.length)];
  const norm = s => String(s ?? '').toLowerCase().replace(/ё/g, 'е').replace(/\s+/g, ' ').trim();
  const opt = o => typeof o === 'string' ? { t: o } : (o || {});
  const shuffle = a => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]] } return a };
  const optHtml = o => `${o.img ? `<img src="${esc(o.img)}" alt="">` : ''}${o.t ? `<span>${esc(o.t)}</span>` : ''}`;
  const starsFor = (s, t) => !t ? 1 : s >= t ? 3 : s * 2 >= t ? 2 : 1;
  const COL = ['#4f8ef7', '#e0709a', '#4caf7d', '#e8873a', '#8a63d2', '#d9b300', '#17a2b8', '#795548'];
  let ac;
  function beep(ok) {
    try {
      ac = ac || new (window.AudioContext || window.webkitAudioContext)();
      const o = ac.createOscillator(), g = ac.createGain(), t = ac.currentTime; o.connect(g); g.connect(ac.destination);
      const f = ok ? [660, 880] : [300, 220]; o.frequency.setValueAtTime(f[0], t); o.frequency.setValueAtTime(f[1], t + .12);
      g.gain.setValueAtTime(.1, t); g.gain.exponentialRampToValueAtTime(.001, t + .3); o.start(t); o.stop(t + .3);
    } catch { }
  }

  /* ---------- автоозвучка (Web Speech API): читает любое задание само, ничего настраивать не нужно ---------- */
  const SS = 'speechSynthesis' in window && 'SpeechSynthesisUtterance' in window;
  const V = { on: false, voice: null };
  const pickVoice = () => { if (!SS) return; const vs = speechSynthesis.getVoices().filter(v => /^ru/i.test(v.lang));
    V.voice = vs.find(v => /milena|alena|irina|katya|yuri|google|enhanced|premium/i.test(v.name)) || vs[0] || null; };
  if (SS) { pickVoice(); speechSynthesis.onvoiceschanged = pickVoice }
  const plain = h => { const d = document.createElement('div'); d.innerHTML = h || ''; return d.textContent.replace(/\s+/g, ' ').trim() };
  const stopSpeech = () => { if (SS) { try { speechSynthesis.cancel() } catch { } } };
  function speak(parts) {
    if (!SS) return; stopSpeech();
    const list = (Array.isArray(parts) ? parts : [parts]).map(plain).filter(Boolean);
    setTimeout(() => list.forEach(p => { const u = new SpeechSynthesisUtterance(p); u.lang = 'ru-RU'; if (V.voice) u.voice = V.voice; u.rate = .9; u.pitch = 1.12; speechSynthesis.speak(u) }), 60);
  }
  function taskParts(t) {
    const type = t.type || 'choice', d = t.data || {}, names = (t.options || []).map(opt).map(o => o.t).filter(Boolean), p = [t.question];
    if (type === 'choice') p.push(...names);
    else if (type === 'multi') p.push('Выбери все подходящие ответы.', ...names);
    else if (type === 'text') p.push('Напиши ответ.');
    else if (type === 'word') p.push('Составь слово из букв.');
    else if (type === 'match') p.push('Соедини пары. Нажми на картинку слева, потом на пару справа.');
    else if (type === 'draw') p.push('Обведи букву пальцем или мышкой.');
    return p;
  }

  function renderTask(t, host, done) {
    const type = t.type || 'choice', d = t.data || {};
    host.classList.remove('lock');
    host.innerHTML = (t.image_url ? `<img class="qi" src="${esc(t.image_url)}" alt="">` : '') + `<h3 class="qq">${esc(t.question)}</h3><div class="qb"></div><div class="fbh"></div>`;
    const body = host.querySelector('.qb'), fb = host.querySelector('.fbh');
    let over = false;
    const finish = (ok, extra) => {
      if (over) return; over = true; host.classList.add('lock'); beep(ok);
      const word = pick(ok ? PRAISE : TRY);
      fb.innerHTML = `<div class="fb ${ok ? 'ok' : 'no'}">${word}${t.explanation ? `<small>${esc(t.explanation)}</small>` : ''}${extra ? `<small>${extra}</small>` : ''}</div>`;
      if (V.on) speak([word, t.explanation, extra]);
      done(ok);
    };
    const chkBtn = (label = 'Проверить') => `<div class="qa"><button type="button" class="btn chk" disabled>${label}</button></div>`;

    if (type === 'choice') {
      const os = (t.options || []).map(opt), im = os.some(o => o.img);
      body.innerHTML = `<div class="og ${im ? 'im' : ''}">${os.map((o, i) => `<button type="button" class="op" data-i="${i}">${optHtml(o)}</button>`).join('')}</div>`;
      body.querySelectorAll('.op').forEach(b => b.onclick = () => {
        if (over) return; const ok = +b.dataset.i === +t.correct;
        b.classList.add(ok ? 'good' : 'bad'); if (!ok) body.querySelector(`.op[data-i="${t.correct}"]`)?.classList.add('good');
        finish(ok);
      });
    }

    else if (type === 'multi') {
      const os = (t.options || []).map(opt), im = os.some(o => o.img), right = new Set((d.correct || []).map(Number)), sel = new Set();
      body.innerHTML = `<p class="muted" style="margin-bottom:10px">Выбери все подходящие ответы</p><div class="og ${im ? 'im' : ''}">${os.map((o, i) => `<button type="button" class="op" data-i="${i}">${optHtml(o)}</button>`).join('')}</div>` + chkBtn();
      const btn = body.querySelector('.chk');
      body.querySelectorAll('.op').forEach(b => b.onclick = () => { const i = +b.dataset.i; sel.has(i) ? sel.delete(i) : sel.add(i); b.classList.toggle('sel', sel.has(i)); btn.disabled = !sel.size });
      btn.onclick = () => {
        const ok = sel.size === right.size && [...sel].every(i => right.has(i));
        body.querySelectorAll('.op').forEach(b => { const i = +b.dataset.i; b.classList.remove('sel'); if (right.has(i)) b.classList.add('good'); else if (sel.has(i)) b.classList.add('bad') });
        btn.remove(); finish(ok);
      };
    }

    else if (type === 'text') {
      body.innerHTML = `<input class="in big" placeholder="Напиши ответ" autocomplete="off" autocapitalize="off">` + chkBtn();
      const inp = body.querySelector('input'), btn = body.querySelector('.chk');
      inp.oninput = () => btn.disabled = !norm(inp.value);
      const go = () => { if (over || !norm(inp.value)) return; const ok = (d.answers || []).some(a => norm(a) === norm(inp.value)); inp.classList.add(ok ? 'good' : 'bad'); btn.remove(); finish(ok, ok ? '' : `Правильный ответ: ${esc((d.answers || [])[0] || '')}`) };
      btn.onclick = go; inp.onkeydown = e => { if (e.key === 'Enter') go() };
    }

    else if (type === 'word') {
      const word = String(d.word || '').toUpperCase().replace(/\s/g, ''), extra = String(d.extra || '').toUpperCase().replace(/\s/g, '');
      const pool = shuffle([...word, ...extra]).map((c, i) => ({ c, i })); let slots = [], cls = [];
      body.innerHTML = `<div class="slots"></div><div class="og" style="grid-template-columns:repeat(auto-fit,minmax(64px,1fr))"></div>` + chkBtn();
      const sl = body.querySelector('.slots'), pl = body.querySelector('.og'), btn = body.querySelector('.chk');
      const draw = () => {
        sl.innerHTML = [...word].map((_, k) => `<button type="button" class="sl ${cls[k] || ''}" data-k="${k}">${slots[k] != null ? esc(pool[slots[k]].c) : ''}</button>`).join('');
        pl.innerHTML = pool.map(p => `<button type="button" class="op ${slots.includes(p.i) ? 'used' : ''}" data-i="${p.i}">${esc(p.c)}</button>`).join('');
        btn.disabled = slots.length !== word.length;
        sl.querySelectorAll('.sl').forEach(b => b.onclick = () => { if (over) return; const k = +b.dataset.k; if (slots[k] != null) { slots.splice(k, 1); draw() } });
        pl.querySelectorAll('.op').forEach(b => b.onclick = () => { if (over || slots.length >= word.length) return; slots.push(+b.dataset.i); draw() });
      };
      draw();
      btn.onclick = () => { const got = slots.map(i => pool[i].c); cls = got.map((c, k) => c === word[k] ? 'good' : 'bad'); const ok = got.join('') === word; draw(); btn.remove(); finish(ok, ok ? '' : `Правильно: ${esc(word)}`) };
    }

    else if (type === 'match') {
      const pairs = (d.pairs || []).map(p => ({ l: opt(p.l), r: opt(p.r) })), order = shuffle(pairs.map((_, i) => i));
      let pend = null, link = {}, graded = null;
      body.innerHTML = `<p class="muted" style="margin-bottom:10px">Нажми на картинку слева, потом на пару справа</p><div class="mt"><div class="mc ml"></div><div class="mc mr"></div></div>` + chkBtn();
      const ml = body.querySelector('.ml'), mr = body.querySelector('.mr'), btn = body.querySelector('.chk');
      const draw = () => {
        const owner = {}; Object.entries(link).forEach(([l, r]) => owner[r] = +l);
        ml.innerHTML = pairs.map((p, i) => `<button type="button" class="op ${pend === i ? 'sel' : ''} ${graded ? (link[i] === i ? 'good' : 'bad') : ''}" data-l="${i}" style="${link[i] != null ? `border-color:${COL[i % 8]}` : ''}">${optHtml(p.l)}</button>`).join('');
        mr.innerHTML = order.map(r => `<button type="button" class="op ${graded && owner[r] != null ? (owner[r] === r ? 'good' : 'bad') : ''}" data-r="${r}" style="${owner[r] != null ? `border-color:${COL[owner[r] % 8]}` : ''}">${optHtml(pairs[r].r)}</button>`).join('');
        btn.disabled = Object.keys(link).length !== pairs.length;
        ml.querySelectorAll('.op').forEach(b => b.onclick = () => { if (over) return; const i = +b.dataset.l; delete link[i]; pend = i; draw() });
        mr.querySelectorAll('.op').forEach(b => b.onclick = () => { if (over || pend == null) return; const r = +b.dataset.r; Object.keys(link).forEach(k => { if (link[k] === r) delete link[k] }); link[pend] = r; pend = null; draw() });
      };
      draw();
      btn.onclick = () => { graded = true; const ok = pairs.every((_, i) => link[i] === i); draw(); btn.remove(); finish(ok) };
    }

    else if (type === 'draw') {
      body.innerHTML = `<div class="dw"><div style="position:absolute;inset:0;display:grid;place-items:center;font:800 clamp(150px,42vw,240px)/1 Unbounded,sans-serif;color:#ececec;pointer-events:none;user-select:none">${esc(d.letter || '')}</div><canvas></canvas></div><div class="row" style="justify-content:center"><button type="button" class="btn line sm clr">Стереть</button><button type="button" class="btn chk">Готово</button></div><div class="hint"></div>`;
      const cv = body.querySelector('canvas'), box = body.querySelector('.dw'); let x, drew = false, down = false, lx = 0, ly = 0;
      requestAnimationFrame(() => {
        const r = box.getBoundingClientRect(), k = window.devicePixelRatio || 1; cv.width = r.width * k; cv.height = r.height * k;
        x = cv.getContext('2d'); x.scale(k, k); x.lineCap = x.lineJoin = 'round'; x.lineWidth = 14; x.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--brown') || '#B07F5E';
      });
      const pos = e => { const r = cv.getBoundingClientRect(); return [e.clientX - r.left, e.clientY - r.top] };
      cv.onpointerdown = e => { if (!x || over) return; down = true; [lx, ly] = pos(e); cv.setPointerCapture(e.pointerId); x.beginPath(); x.moveTo(lx, ly); x.lineTo(lx + .1, ly); x.stroke(); drew = true };
      cv.onpointermove = e => { if (!down) return; const [px, py] = pos(e); x.beginPath(); x.moveTo(lx, ly); x.lineTo(px, py); x.stroke(); lx = px; ly = py };
      cv.onpointerup = cv.onpointercancel = () => down = false;
      body.querySelector('.clr').onclick = () => { if (!over && x) { x.clearRect(0, 0, cv.width, cv.height); drew = false } };
      body.querySelector('.chk').onclick = () => { if (!drew) { body.querySelector('.hint').textContent = 'Нарисуй пальцем или мышкой по серой букве'; return } body.querySelector('.row').remove(); body.querySelector('.hint').textContent = ''; finish(true) };
    }
  }

  function run(root, tasks, o = {}) {
    let i = 0, score = 0; const res = []; if (o.voice !== undefined) V.on = !!o.voice;
    const vbar = cur => SS ? `<div class="qv"><button type="button" class="qsp" data-v="say" title="Послушать задание" aria-label="Послушать задание">${ico('sound')}</button><button type="button" class="qsp ${V.on ? '' : 'off'}" data-v="auto" title="Автоозвучка: ${V.on ? 'включена' : 'выключена'}" aria-label="Автоозвучка">${ico(V.on ? 'sound' : 'mute')}<small>авто</small></button></div>` : '';
    const wire = (cur) => root.querySelectorAll('[data-v]').forEach(b => b.onclick = () => {
      if (b.dataset.v === 'say') return speak(cur ? taskParts(cur) : []);
      V.on = !V.on; if (!V.on) stopSpeech(); else if (cur) speak(taskParts(cur)); o.onVoice && o.onVoice(V.on);
      root.querySelectorAll('[data-v=auto]').forEach(x => { x.classList.toggle('off', !V.on); x.innerHTML = ico(V.on ? 'sound' : 'mute') + '<small>авто</small>'; x.title = 'Автоозвучка: ' + (V.on ? 'включена' : 'выключена') }) });
    const step = () => {
      if (i >= tasks.length) return end();
      stopSpeech();
      root.innerHTML = `<div class="qz">${vbar()}<div class="dots">${tasks.map((_, k) => `<i class="${k < i ? (res[k] ? 'g' : 'b') : k === i ? 'c' : ''}"></i>`).join('')}</div><div class="qt"></div><div class="qa nx"></div></div>`;
      const host = root.querySelector('.qt'), nx = root.querySelector('.nx'), idx = i; wire(tasks[idx]);
      if (V.on) speak(taskParts(tasks[idx]));
      renderTask(tasks[idx], host, ok => {
        res[idx] = ok; if (ok) score++;
        nx.innerHTML = `<button type="button" class="btn nb">${idx + 1 < tasks.length ? 'Дальше' : 'Готово'}</button>`;
        nx.querySelector('.nb').onclick = () => { i++; step() }; nx.querySelector('.nb').focus();
      });
    };
    async function end() {
      const st = starsFor(score, tasks.length);
      if (V.on) speak(['Урок пройден!', `Ты правильно ответил на ${score} из ${tasks.length}.`]);
      root.innerHTML = `<div class="qz"><h2 class="qq">Урок пройден!</h2><div class="stars">${[1, 2, 3].map(k => `<span class="${k <= st ? 'on' : ''}" style="animation-delay:${k * .25}s">${ico('star')}</span>`).join('')}</div><p class="qq">Верно: ${score} из ${tasks.length}</p><div class="sv muted"></div><div class="nbd"></div><div class="qa act row" style="justify-content:center"></div></div>`;
      const sv = root.querySelector('.sv'); let info = null;
      if (o.onFinish) { sv.textContent = 'Сохраняем результат…'; try { info = await o.onFinish(score, tasks.length); sv.textContent = '' } catch (e) { sv.innerHTML = `<span class="msg err">Не удалось сохранить: ${esc(e.message || e)}</span>` } }
      if (info && info.badges && info.badges.length) root.querySelector('.nbd').innerHTML = info.badges.map(b => `<div class="fb ok" style="margin:10px 0">${ico(b.icon)} Новая награда: ${esc(b.title)}</div>`).join('');
      o.actions && o.actions(root.querySelector('.act'), { score, total: tasks.length, stars: st });
    }
    step();
  }
  return { run, starsFor, renderTask, stop: stopSpeech, voice: { get on() { return V.on }, set(v) { V.on = !!v; if (!v) stopSpeech() }, supported: SS, ru: () => !!V.voice } };
})();
