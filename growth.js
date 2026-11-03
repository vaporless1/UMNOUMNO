/* УМНО: рост — «Пригласи друга», грамоты (PDF), подсказка установки на iPhone */
const Growth = (() => {
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const ls = { get: k => { try { return localStorage.getItem(k) } catch { return null } }, set: (k, v) => { try { localStorage.setItem(k, v) } catch { } }, del: k => { try { localStorage.removeItem(k) } catch { } } };
  const REF_RE = /^[A-Za-z0-9]{4,12}$/;

  // ---------- код приглашения из ссылки ?ref=КОД ----------
  function captureRef() {
    try { const r = new URLSearchParams(location.search).get('ref'); if (r && REF_RE.test(r)) ls.set('umno_ref', r.toUpperCase()) } catch { }
    return savedRef();
  }
  const savedRef = () => { const r = ls.get('umno_ref'); return r && REF_RE.test(r) ? r : null };
  const clearRef = () => ls.del('umno_ref');
  const link = code => new URL('cabinet.html', location.href).origin + new URL('cabinet.html', location.href).pathname + '?ref=' + encodeURIComponent(code);

  // ---------- блок «Пригласи друга» ----------
  async function referralPane(host, { sb, toast, plural }) {
    host.innerHTML = '<div class="pane">Загружаем…</div>';
    const { data: r, error } = await sb.rpc('my_referral');
    if (error || !r) { host.innerHTML = ''; return false }
    const url = link(r.code), text = 'Занимаемся с ребёнком в УМНО: уроки, задания и награды. Регистрируйся по моей ссылке — получишь +' + r.days_each + ' дней «Премиум».';
    host.innerHTML = `<div class="pane refpane">
      <p>Подарите другу неделю «Премиум». Когда его ребёнок пройдёт первый урок, <b>вы оба получите +${r.days_each} дней «Премиум»</b> (за один раз у вас может быть до ${r.cap} таких бонусов).</p>
      <div class="refbox"><input class="in" id="refUrl" readonly value="${esc(url)}" aria-label="Ваша ссылка"><button class="btn sm" id="refCopy" type="button">Скопировать</button><button class="btn line sm" id="refShare" type="button">Поделиться</button></div>
      <div class="refstat"><div><b>${r.invited}</b><span>зарегистрировались по вашей ссылке</span></div><div><b>${r.rewarded}</b><span>начали заниматься — бонус получен</span></div></div>
      ${r.referred_by ? `<div class="cnt">Вас пригласил друг${r.referred_done ? ': бонус уже начислен.' : '. Бонус придёт, когда ваш ребёнок пройдёт первый урок.'}</div>`
        : `<div class="refcode"><label for="refIn">Есть код друга?</label><div class="row"><input class="in" id="refIn" maxlength="12" placeholder="Например, AB12CD34" autocomplete="off" autocapitalize="characters" style="max-width:220px;text-transform:uppercase"><button class="btn line sm" id="refGo" type="button">Применить</button></div></div>`}
      <div id="refMsg" class="msg" role="status"></div></div>`;
    const say = (t, k) => { const m = host.querySelector('#refMsg'); m.textContent = t; m.className = 'msg ' + (k || '') };
    host.querySelector('#refCopy').onclick = async () => { try { await navigator.clipboard.writeText(url); toast('Ссылка скопирована') } catch { const i = host.querySelector('#refUrl'); i.select(); document.execCommand && document.execCommand('copy'); toast('Ссылка скопирована') } };
    host.querySelector('#refShare').onclick = async () => { if (navigator.share) { try { await navigator.share({ title: 'УМНО', text, url }) } catch { } } else host.querySelector('#refCopy').click() };
    host.querySelector('#refGo')?.addEventListener('click', async () => {
      const code = host.querySelector('#refIn').value.trim(); if (!code) return say('Введите код', 'err');
      const { data, error } = await sb.rpc('apply_referral', { p_code: code }); if (error) return say(error.message, 'err');
      clearRef(); toast(data || 'Код принят'); referralPane(host, { sb, toast, plural }) });
    return true;
  }

  // ---------- грамота (PDF) ----------
  const CW = 1754, CH = 1240;   // A4 альбомная, 150 dpi
  const fitText = (x, txt, maxW, size, weight, fam) => { let s = size; do { x.font = `${weight} ${s}px ${fam}`; s -= 2 } while (x.measureText(txt).width > maxW && s > 28); return s };
  const fmtDate = d => new Date(d).toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', year: 'numeric' });
  function wrap(x, txt, cx, y, maxW, lh) { const w = txt.split(' '); let line = ''; const out = []; w.forEach(t => { const n = line ? line + ' ' + t : t; if (x.measureText(n).width > maxW && line) { out.push(line); line = t } else line = n }); out.push(line); out.forEach((l, i) => x.fillText(l, cx, y + i * lh)); return y + out.length * lh }
  function svgImg(svg, w, h) { return new Promise(res => { const im = new Image(); im.width = w; im.height = h; im.onload = () => res(im); im.onerror = () => res(null); im.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg) }) }

  async function certCanvas(c, opts = {}) {
    try { await Promise.all([document.fonts.load('800 80px Unbounded'), document.fonts.load('900 80px Nunito'), document.fonts.load('600 30px Nunito')]) } catch { }
    const cv = document.createElement('canvas'); cv.width = CW; cv.height = CH; const x = cv.getContext('2d');
    const BR = '#B07F5E', DK = '#4a2410', GOLD = '#e8b230', NU = 'Nunito, Manrope, Arial, sans-serif', UN = 'Unbounded, Nunito, Arial, sans-serif';
    x.fillStyle = '#fffaf2'; x.fillRect(0, 0, CW, CH);
    // фон-горошек
    x.fillStyle = 'rgba(176,127,94,.07)'; for (let i = 0; i < 70; i++) { const px = (i * 241) % CW, py = (i * 397) % CH; x.beginPath(); x.arc(px, py, 6 + (i % 5) * 3, 0, 7); x.fill() }
    // рамка
    x.lineWidth = 16; x.strokeStyle = BR; x.strokeRect(48, 48, CW - 96, CH - 96);
    x.lineWidth = 4; x.strokeStyle = GOLD; x.strokeRect(78, 78, CW - 156, CH - 156);
    [[78, 78], [CW - 78, 78], [78, CH - 78], [CW - 78, CH - 78]].forEach(([px, py]) => { x.fillStyle = GOLD; x.beginPath(); x.arc(px, py, 20, 0, 7); x.fill(); x.fillStyle = '#fffaf2'; x.beginPath(); x.arc(px, py, 9, 0, 7); x.fill() });
    x.textAlign = 'center'; x.textBaseline = 'alphabetic';
    x.fillStyle = BR; x.font = `800 40px ${UN}`; x.fillText('УМНО', CW / 2, 180);
    x.fillStyle = DK; x.font = `800 128px ${UN}`; x.fillText('ГРАМОТА', CW / 2, 330);
    // звёзды
    const star = (px, py, r) => { x.beginPath(); for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, rr = i % 2 ? r * .45 : r; x.lineTo(px + Math.cos(a) * rr, py + Math.sin(a) * rr) } x.closePath(); x.fillStyle = GOLD; x.fill() };
    [-1, 0, 1].forEach(i => star(CW / 2 + i * 70, 395, i ? 26 : 34));
    x.fillStyle = '#7a6a5c'; x.font = `700 40px ${NU}`; x.fillText('награждается', CW / 2, 490);
    const name = String(c.child || '').trim() || 'Малыш', fs = fitText(x, name, 1250, 150, 900, NU);
    x.fillStyle = BR; x.font = `900 ${fs}px ${NU}`; x.fillText(name, CW / 2, 640);
    x.strokeStyle = GOLD; x.lineWidth = 5; x.beginPath(); x.moveTo(CW / 2 - 420, 672); x.lineTo(CW / 2 + 420, 672); x.stroke();
    x.fillStyle = DK; x.font = `700 46px ${NU}`;
    let y = wrap(x, `за успешное прохождение курса «${c.course}»`, CW / 2, 750, 1150, 62);
    x.fillStyle = '#7a6a5c'; x.font = `600 38px ${NU}`;
    const n = +c.lessons || 0, pl = (k, a, b, d) => { const m = k % 10, h = k % 100; return h > 10 && h < 15 ? d : m === 1 ? a : m > 1 && m < 5 ? b : d };
    x.fillText(`Пройдено ${n} ${pl(n, 'урок', 'урока', 'уроков')}` + (c.stars ? ` · заработано ${c.stars} ★` : ''), CW / 2, y + 14);
    // мишка
    const hat = opts.hat || '';
    if (typeof Kid !== 'undefined' && Kid.mascotG) {
      const im = await svgImg(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="20 -64 260 450" width="260" height="450">${Kid.mascotG(hat, { mood: 'cheer' })}</svg>`, 260, 450);
      if (im) { x.drawImage(im, 130, 730, 170, 295); x.save(); x.translate(CW, 0); x.scale(-1, 1); x.drawImage(im, 130, 730, 170, 295); x.restore() }
    }
    // подвал
    x.fillStyle = '#7a6a5c'; x.font = `600 30px ${NU}`; x.textAlign = 'left'; x.fillText(fmtDate(c.issued_at), 190, CH - 120);
    x.textAlign = 'right'; x.fillText('№ ' + c.number, CW - 190, CH - 120);
    x.textAlign = 'center'; x.fillStyle = BR; x.font = `700 28px ${NU}`; x.fillText('umno-umno.online', CW / 2, CH - 120);
    return cv;
  }

  // PDF из одного JPEG (без библиотек)
  function pdfFromJpeg(jpeg, pxW, pxH) {
    const W = 842, H = Math.round(842 * pxH / pxW), enc = new TextEncoder(), parts = []; let len = 0; const offs = [];
    const add = b => { const u = typeof b === 'string' ? enc.encode(b) : b; parts.push(u); len += u.length };
    const obj = (n, body) => { offs[n] = len; add(`${n} 0 obj\n`); body(); add('\nendobj\n') };
    add('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');
    obj(1, () => add('<< /Type /Catalog /Pages 2 0 R >>'));
    obj(2, () => add('<< /Type /Pages /Kids [3 0 R] /Count 1 >>'));
    obj(3, () => add(`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${W} ${H}] /Resources << /XObject << /Im0 4 0 R >> >> /Contents 5 0 R >>`));
    obj(4, () => { add(`<< /Type /XObject /Subtype /Image /Width ${pxW} /Height ${pxH} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpeg.length} >>\nstream\n`); add(jpeg); add('\nendstream') });
    const content = `q ${W} 0 0 ${H} 0 0 cm /Im0 Do Q`;
    obj(5, () => add(`<< /Length ${content.length} >>\nstream\n${content}\nendstream`));
    obj(6, () => add('<< /Title (UMNO certificate) /Producer (UMNO) >>'));
    const xr = len; add('xref\n0 7\n0000000000 65535 f \n');
    for (let i = 1; i <= 6; i++) add(String(offs[i]).padStart(10, '0') + ' 00000 n \n');
    add(`trailer\n<< /Size 7 /Root 1 0 R /Info 6 0 R >>\nstartxref\n${xr}\n%%EOF`);
    return new Blob(parts, { type: 'application/pdf' });
  }
  const fileName = c => 'Gramota-' + String(c.child || 'umno').replace(/[^\p{L}\p{N}]+/gu, '_').replace(/^_|_$/g, '') + '-' + String(c.course_id).replace(/[^\w-]/g, '') + '.pdf';

  async function makeCert(c, opts) {
    const cv = await certCanvas(c, opts), dataUrl = cv.toDataURL('image/jpeg', .92), bin = atob(dataUrl.split(',')[1]), u = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i);
    return { pdf: pdfFromJpeg(u, CW, CH), preview: dataUrl, name: fileName(c) };
  }
  async function savePdf(r) {
    const file = new File([r.pdf], r.name, { type: 'application/pdf' });
    // iPhone/iPad: через меню «Поделиться» → «Сохранить в Файлы»
    if (navigator.canShare && navigator.canShare({ files: [file] })) { try { await navigator.share({ files: [file], title: 'Грамота УМНО' }); return 'shared' } catch (e) { if (e && e.name === 'AbortError') return 'cancel' } }
    const url = URL.createObjectURL(r.pdf), a = document.createElement('a'); a.href = url; a.download = r.name; document.body.append(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 60000); return 'download';
  }
  // окно с предпросмотром и кнопкой «Скачать PDF»
  async function showCert(c, { modal, toast, hat }) {
    const m = modal(`<h2 style="font-family:Unbounded;font-size:19px;margin-bottom:10px">Грамота: ${esc(c.child)}</h2><div class="certprev"><p class="muted">Готовим грамоту…</p></div><div class="row"><button class="btn" id="cDl" disabled>Скачать PDF</button><button class="btn line" id="cX">Закрыть</button></div>`);
    m.querySelector('#cX').onclick = () => m.remove();
    try {
      const r = await makeCert(c, { hat }); m.querySelector('.certprev').innerHTML = `<img src="${r.preview}" alt="Грамота ${esc(c.child)}" style="width:100%;border-radius:12px;box-shadow:0 4px 18px rgba(0,0,0,.15)">`;
      const b = m.querySelector('#cDl'); b.disabled = false; b.onclick = async () => { b.disabled = true; const s = await savePdf(r); b.disabled = false; if (s === 'download') toast('Грамота сохранена') };
    } catch (e) { console.error(e); m.querySelector('.certprev').innerHTML = '<p class="msg err">Не удалось создать грамоту. Попробуйте ещё раз.</p>' }
    return m;
  }
  // список грамот ребёнка
  function certsHtml(list, kid) {
    if (!list.length) return `<p class="muted">${kid ? 'Пройди все уроки курса — и получишь свою грамоту!' : 'Грамота появится, когда ребёнок пройдёт все уроки курса.'}</p>`;
    return `<div class="certs">${list.map((c, i) => `<button class="cert" data-cert="${i}" type="button"><span class="cert-i">🏅</span><b>${esc(c.course)}</b><small>${esc(fmtDate(c.issued_at))}</small><em>Открыть PDF</em></button>`).join('')}</div>`;
  }

  // ---------- установка на iPhone ----------
  const isIOS = () => /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const standalone = () => window.navigator.standalone === true || (window.matchMedia && matchMedia('(display-mode: standalone)').matches);
  function iosHint() {
    if (!isIOS() || standalone() || document.getElementById('iosHint')) return;
    const t = +ls.get('umno_ios_hint') || 0; if (t && Date.now() - t < 30 * 864e5) return;
    const el = document.createElement('div'); el.id = 'iosHint'; el.setAttribute('role', 'dialog');
    el.innerHTML = `<button class="x" aria-label="Закрыть" type="button">×</button><div class="ih-i"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3v12M8 7l4-4 4 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"/></svg></div><div><b>Установите УМНО на iPhone</b><span>Нажмите «Поделиться» <i>⬆︎</i> в Safari и выберите «На экран “Домой”». Откроется как приложение, без адресной строки.</span></div>`;
    el.querySelector('.x').onclick = () => { ls.set('umno_ios_hint', Date.now()); el.remove() };
    document.body.append(el);
  }

  return { captureRef, savedRef, clearRef, link, referralPane, showCert, certsHtml, makeCert, savePdf, iosHint, isIOS, standalone };
})();

// Service worker (нужен для установки и офлайн-оболочки)
if ('serviceWorker' in navigator && /^https?:$/.test(location.protocol)) addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => { }));
