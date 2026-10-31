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
  let curAudio = null, gen = 0;
  const stopSpeech = () => { gen++; if (curAudio) { try { curAudio.pause() } catch { } curAudio = null } if (SS) { try { speechSynthesis.cancel() } catch { } } };
  /* живая озвучка: готовые mp3 из /audio/ (имя = первые 16 символов SHA-1 текста); если файла нет — синтез браузера */
  const normT = s => s.replace(/[\u{1F000}-\u{1FFFF}\u2600-\u27BF]/gu, '').replace(/\s+/g, ' ').trim();
  const keyOf = async s => { const b = await crypto.subtle.digest('SHA-1', new TextEncoder().encode(s)); return [...new Uint8Array(b)].map(x => x.toString(16).padStart(2, '0')).join('').slice(0, 16) };
  const clip = (text, my) => new Promise(async res => { try { const a = new Audio('/audio/' + await keyOf(text) + '.mp3'); if (my !== gen) return res(true); curAudio = a; a.onended = () => res(true); a.onerror = () => res(false); await a.play() } catch { res(false) } });
  const say = text => new Promise(res => { if (!SS) return res(); const u = new SpeechSynthesisUtterance(text); u.lang = 'ru-RU'; if (V.voice) u.voice = V.voice; u.rate = .9; u.onend = u.onerror = () => res(); speechSynthesis.speak(u) });
  async function speak(parts) {
    stopSpeech(); const my = gen;
    const list = (Array.isArray(parts) ? parts : [parts]).map(plain).map(normT).filter(Boolean);
    for (const t of list) { if (my !== gen) return; const ok = await clip(t, my); if (my !== gen) return; if (!ok) await say(t) }
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
      /* Обводка буквы с проверкой: рисунок сверяется с маской буквы.
         1) «границы»: штрих вне буквы (с допуском) окрашивается красным и не засчитывается;
         2) «правильность»: должно быть закрашено не меньше 70% буквы, а доля штриха вне границ — не больше 25%. */
      const letter = String(d.letter || '').trim().slice(0, 1);
      body.innerHTML = `<div class="dw"><canvas class="gl"></canvas><canvas class="pen"></canvas></div><div class="row" style="justify-content:center"><button type="button" class="btn line sm clr">Стереть</button><button type="button" class="btn chk">Готово</button></div><div class="hint"></div>`;
      const box = body.querySelector('.dw'), gl = body.querySelector('.gl'), cv = body.querySelector('.pen'), hint = body.querySelector('.hint');
      const BRUSH = 14, TOL = 13, HIT = .7, OUT = .25;
      let W = 0, H = 0, x, letterM, allowM, ink, inkWide, down = false, lx = 0, ly = 0, len = 0, tries = 0, ready = false;
      const brown = (getComputedStyle(document.documentElement).getPropertyValue('--brown') || '#B07F5E').trim() || '#B07F5E';
      const font = '800 100px Unbounded, Nunito, sans-serif';
      const off = () => { const c = document.createElement('canvas'); c.width = W; c.height = H; const t = c.getContext('2d', { willReadFrequently: true }); t.lineCap = t.lineJoin = 'round'; return [c, t] };
      // рисуем букву по центру и вписываем в поле
      const putLetter = (t, mode, lw) => {
        t.font = font; t.textBaseline = 'alphabetic'; t.textAlign = 'left';
        const m = t.measureText(letter), bw = m.actualBoundingBoxLeft + m.actualBoundingBoxRight, bh = m.actualBoundingBoxAscent + m.actualBoundingBoxDescent;
        const sc = Math.min(W * .74 / bw, H * .74 / bh), cx = W / 2, cy = H / 2;
        t.save(); t.translate(cx, cy); t.scale(sc, sc); t.translate(-(bw / 2 - m.actualBoundingBoxLeft), (bh / 2 - m.actualBoundingBoxDescent));
        t.font = font;
        if (mode === 'allow') { t.lineWidth = lw / sc; t.strokeText(letter, 0, 0) }
        t.fillText(letter, 0, 0); t.restore();
      };
      const init = async () => {
        try { await document.fonts.load(font, letter) } catch { }
        const r = box.getBoundingClientRect(); W = Math.round(r.width); H = Math.round(r.height); if (!W || !H) return;
        const k = window.devicePixelRatio || 1;
        for (const c of [gl, cv]) { c.width = W * k; c.height = H * k }
        const g = gl.getContext('2d'); g.scale(k, k); g.fillStyle = '#e3e3e3'; putLetter(g, 'fill');
        // маска буквы и «разрешённая зона» (буква + допуск по краям)
        const [, lt] = off(); lt.fillStyle = '#000'; putLetter(lt, 'fill'); letterM = lt.getImageData(0, 0, W, H).data;
        const [, at] = off(); at.fillStyle = at.strokeStyle = '#000'; putLetter(at, 'allow', TOL * 2); allowM = at.getImageData(0, 0, W, H).data;
        let c1, c2; [c1, ink] = off(); [c2, inkWide] = off(); ink.strokeStyle = ink.fillStyle = '#000'; inkWide.strokeStyle = inkWide.fillStyle = '#000';
        ink.lineWidth = BRUSH; inkWide.lineWidth = BRUSH + TOL * 2;
        x = cv.getContext('2d'); x.scale(k, k); x.lineCap = x.lineJoin = 'round'; x.lineWidth = BRUSH;
        ready = true;
      };
      init();
      const inside = (px, py) => { const i = ((py | 0) * W + (px | 0)) * 4 + 3; return px >= 0 && py >= 0 && px < W && py < H && allowM[i] > 40 };
      const seg = (ax, ay, bx, by) => {
        x.strokeStyle = inside(bx, by) ? brown : '#d9534f';
        x.beginPath(); x.moveTo(ax, ay); x.lineTo(bx, by); x.stroke();
        for (const t of [ink, inkWide]) { t.beginPath(); t.moveTo(ax, ay); t.lineTo(bx, by); t.stroke() }
        len += Math.hypot(bx - ax, by - ay);
      };
      const pos = e => { const r = cv.getBoundingClientRect(); return [(e.clientX - r.left) * W / r.width, (e.clientY - r.top) * H / r.height] };
      cv.onpointerdown = e => { if (!ready || over) return; down = true; [lx, ly] = pos(e); cv.setPointerCapture(e.pointerId); seg(lx, ly, lx + .1, ly); hint.textContent = '' };
      cv.onpointermove = e => { if (!down) return; const [px, py] = pos(e); seg(lx, ly, px, py); lx = px; ly = py };
      cv.onpointerup = cv.onpointercancel = () => down = false;
      const clear = () => { x.save(); x.setTransform(1, 0, 0, 1, 0, 0); x.clearRect(0, 0, cv.width, cv.height); x.restore(); ink.clearRect(0, 0, W, H); inkWide.clearRect(0, 0, W, H); len = 0 };
      body.querySelector('.clr').onclick = () => { if (!over && ready) { clear(); hint.textContent = '' } };
      // оценка рисунка
      const grade = () => {
        const a = ink.getImageData(0, 0, W, H).data, w = inkWide.getImageData(0, 0, W, H).data;
        let lt = 0, lc = 0, it = 0, io = 0;
        for (let i = 3; i < a.length; i += 4) {
          if (letterM[i] > 128) { lt++; if (w[i] > 40) lc++ }
          if (a[i] > 40) { it++; if (allowM[i] <= 40) io++ }
        }
        return { cover: lt ? lc / lt : 0, outside: it ? io / it : 1, ink: it };
      };
      body.querySelector('.chk').onclick = () => {
        if (!ready || over) return;
        if (len < 20) { hint.textContent = 'Обведи пальцем или мышкой серую букву'; return }
        const g = grade(); tries++;
        if (g.cover >= HIT && g.outside <= OUT) { body.querySelector('.row').remove(); hint.textContent = ''; return finish(true) }
        if (tries >= 3) { body.querySelector('.row').remove(); hint.textContent = ''; return finish(false, 'Буква: ' + esc(letter)) }
        hint.textContent = g.outside > OUT ? 'Рисуй внутри серой буквы — красные линии выходят за её край. Нажми «Стереть» и попробуй ещё.' : 'Обведи всю букву до конца — пока закрашено ' + Math.round(g.cover * 100) + '%.';
      };
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
