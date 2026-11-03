/* УМНО · админка: вкладка «Истории» (темы, истории, кадры 9:16, хэштеги, аудитория, статистика) */
let ST = { topics: [], stories: [], slides: [], stats: { stories: {}, followers: {} } }, stSel = null;   // stSel = { type: 'topic'|'story', id }
const AUDL = { parents: 'Родителям (кабинет)', kids: 'Детям (детский режим)', both: 'Родителям и детям' };
const AUDS = { parents: 'родителям', kids: 'детям', both: 'всем' };
const toLocal = iso => iso ? new Date(new Date(iso) - new Date(iso).getTimezoneOffset() * 6e4).toISOString().slice(0, 16) : '';
const fromLocal = v => v ? new Date(v).toISOString() : null;
const parseTags = v => [...new Set(String(v || '').split(/[\s,;]+/).map(x => x.replace(/^#+/, '').toLowerCase()).filter(x => x && x.length <= 30))].slice(0, 8);
const stPath = url => { const m = /\/object\/public\/stories\/([^?]+)/.exec(url || ''); return m ? decodeURIComponent(m[1]) : null };
const stRemoveFiles = urls => { const p = urls.map(stPath).filter(Boolean); if (p.length) sb.storage.from('stories').remove(p).catch(() => { }) };

async function loadStories() {
  const [t, s, k, st] = await Promise.all([
    sb.from('story_topics').select('*').order('sort').order('created_at'), sb.from('stories').select('*').order('sort').order('created_at', { ascending: false }),
    sb.from('story_slides').select('id,story_id,kind').order('sort'), sb.rpc('admin_story_stats')]);
  if (t.error) { $('#stList').innerHTML = '<p class="msg err">Не загрузилось: ' + esc(t.error.message) + '<br>Выполнен ли файл schema13_stories.sql в Supabase?</p>'; return }
  ST.topics = t.data || []; ST.stories = s.data || []; ST.slideCount = {}; (k.data || []).forEach(x => ST.slideCount[x.story_id] = (ST.slideCount[x.story_id] || 0) + 1);
  ST.stats = st.data || { stories: {}, followers: {} };
  drawStList();
}
function stState(s) {
  if (s.status !== 'published') return ['черновик', ''];
  if (s.expires_at && new Date(s.expires_at) <= new Date()) return ['срок истёк', 'red'];
  if (s.publish_at && new Date(s.publish_at) > new Date()) return ['отложена', ''];
  return ['в эфире', 'ok'];
}
function drawStList() {
  const on = (type, id) => stSel && stSel.type === type && stSel.id === id ? 'on' : '';
  $('#stList').innerHTML = `<div class="row" style="margin:0 0 14px"><button class="btn sm" id="stNewTopic">+ Тема</button></div>` + (ST.topics.map(t => {
    const ss = ST.stories.filter(s => s.topic_id === t.id);
    return `<div class="cg"><div class="ch"><div class="li ${on('topic', t.id)}" data-topic="${t.id}" style="flex:1;margin:0">${t.avatar_url ? `<img class="th" src="${esc(t.avatar_url)}" alt="" style="border-radius:50%;width:34px;height:34px">` : ''}<span style="flex:1;min-width:0"><b>${esc(t.title)}</b> ${t.active ? '' : '<span class="tag red">скрыта</span>'}<br><small class="muted">${t.default_on ? 'видна всем' : 'по подписке · ' + (ST.stats.followers[t.id] || 0) + ' подп.'} · историй: ${ss.length}</small></span></div>
      <button class="btn line sm" data-newstory="${t.id}" title="Добавить историю в тему">+ История</button></div>
      ${ss.map(s => { const [lbl, cls] = stState(s), n = ST.stats.stories[s.id] || {}; return `<div class="li ${on('story', s.id)}" data-story="${s.id}" style="margin-left:18px">${s.cover_url ? `<img class="th" src="${esc(s.cover_url)}" alt="" style="border-radius:50%;width:34px;height:34px">` : ''}<span style="flex:1;min-width:0"><b>${esc(s.title)}</b> <span class="tag ${cls}">${lbl}</span><span class="tag">${AUDS[s.audience]}</span><br><small class="muted">кадров: ${ST.slideCount[s.id] || 0} · 👁 ${n.views || 0} · до конца ${n.done || 0} · кликов ${n.clicks || 0}</small></span></div>` }).join('')}</div>`;
  }).join('') || '<p class="muted">Тем пока нет. Создайте первую: например, «Новости УМНО».</p>');
  $('#stNewTopic').onclick = () => newTopic();
  $$('#stList [data-topic]').forEach(b => b.onclick = () => { stSel = { type: 'topic', id: b.dataset.topic }; drawStList(); editTopic(b.dataset.topic) });
  $$('#stList [data-story]').forEach(b => b.onclick = () => { stSel = { type: 'story', id: b.dataset.story }; drawStList(); editStory(b.dataset.story) });
  $$('#stList [data-newstory]').forEach(b => b.onclick = () => newStory(b.dataset.newstory));
}

// ---------- тема ----------
async function newTopic() {
  const { data, error } = await sb.from('story_topics').insert({ title: 'Новая тема', sort: (ST.topics.length + 1) * 10 }).select().single();
  if (error) return toast(error.message, 1); await loadStories(); stSel = { type: 'topic', id: data.id }; drawStList(); editTopic(data.id);
}
function editTopic(id) {
  const t = ST.topics.find(x => x.id === id); if (!t) return; let av = t.avatar_url;
  $('#stEdit').innerHTML = `<h2 style="font-size:18px;margin-bottom:14px">Тема</h2>
   <div class="row" style="margin:0 0 12px;flex-wrap:nowrap"><div id="tAv">${av ? `<img class="th" src="${esc(av)}" style="border-radius:50%;width:64px;height:64px" alt="">` : '<div class="th" style="border-radius:50%;width:64px;height:64px;background:var(--soft)"></div>'}</div>
    <div><button class="btn line sm" id="tUp" type="button">Загрузить аватарку</button> ${av ? '<button class="link" id="tRm" type="button">убрать</button>' : ''}<div class="hintx">Квадрат, показывается в круглой рамке.</div></div></div>
   <div class="fg"><div class="full"><label>Название темы</label><input class="in" id="tTitle" maxlength="60" value="${esc(t.title)}"></div>
    <div class="full"><label>Описание (видно в списке подписок)</label><textarea class="in" id="tDesc" maxlength="300" style="min-height:70px;resize:vertical">${esc(t.description || '')}</textarea></div>
    <div><label>Порядок (меньше — левее)</label><input class="in" id="tSort" type="number" value="${t.sort}"></div></div>
   <label class="ck" style="margin-top:12px"><input type="checkbox" id="tDef" ${t.default_on ? 'checked' : ''}> Показывать всем без подписки (например, «Новости УМНО»)</label>
   <label class="ck" style="margin-top:8px"><input type="checkbox" id="tAct" ${t.active ? 'checked' : ''}> Тема включена</label>
   <p class="hintx">Если «без подписки» выключено, родитель увидит тему только после подписки в разделе «Темы». Подписки действуют и в детском режиме.</p>
   <div class="row" style="margin-top:14px"><button class="btn" id="tSave">Сохранить</button><button class="btn red sm" id="tDel" style="margin-left:auto">Удалить тему</button></div>`;
  $('#tUp').onclick = async () => { const f = await pickFile('image/*'); if (!f) return; toast('Загружаем…'); try { av = await uploadPublic('stories', `topics/${id}.jpg`, await resizeImg(f, 256, true), 'image/jpeg'); $('#tAv').innerHTML = `<img class="th" src="${esc(av)}" style="border-radius:50%;width:64px;height:64px" alt="">`; toast('Загружено. Нажмите «Сохранить».') } catch (e) { toast(e.message, 1) } };
  $('#tRm')?.addEventListener('click', () => { av = null; $('#tAv').innerHTML = '<div class="th" style="border-radius:50%;width:64px;height:64px;background:var(--soft)"></div>' });
  $('#tSave').onclick = async () => {
    const title = $('#tTitle').value.trim(); if (!title) return toast('Введите название', 1);
    const { error } = await sb.from('story_topics').update({ title, description: $('#tDesc').value.trim() || null, avatar_url: av, sort: parseInt($('#tSort').value, 10) || 0, default_on: $('#tDef').checked, active: $('#tAct').checked }).eq('id', id);
    if (error) return toast(error.message, 1); toast('Сохранено'); await loadStories(); editTopic(id);
  };
  $('#tDel').onclick = async () => {
    const n = ST.stories.filter(s => s.topic_id === id).length;
    if (!confirm(`Удалить тему «${t.title}» вместе с историями (${n})? Это нельзя отменить.`)) return;
    const { error } = await sb.from('story_topics').delete().eq('id', id); if (error) return toast(error.message, 1);
    stSel = null; $('#stEdit').innerHTML = '<p class="muted">Тема удалена.</p>'; loadStories();
  };
}

// ---------- история ----------
async function newStory(topicId) {
  const { data, error } = await sb.from('stories').insert({ topic_id: topicId, title: 'Новая история', status: 'draft', sort: (ST.stories.filter(s => s.topic_id === topicId).length + 1) * 10 }).select().single();
  if (error) return toast(error.message, 1); await loadStories(); stSel = { type: 'story', id: data.id }; drawStList(); editStory(data.id);
}
let SK = [];   // кадры редактируемой истории
async function editStory(id) {
  const s = ST.stories.find(x => x.id === id); if (!s) return; let cover = s.cover_url;
  const r = await sb.from('story_slides').select('*').eq('story_id', id).order('sort').order('id'); if (r.error) return toast(r.error.message, 1); SK = r.data || [];
  const n = ST.stats.stories[id] || {};
  $('#stEdit').innerHTML = `<div class="head"><h2 style="font-size:18px">История</h2><div class="muted">👁 ${n.views || 0} · до конца ${n.done || 0} · кликов ${n.clicks || 0}</div></div>
   <div class="row" style="margin:12px 0;flex-wrap:nowrap"><div id="sCov">${cover ? `<img class="th" src="${esc(cover)}" style="border-radius:50%;width:64px;height:64px" alt="">` : '<div class="th" style="border-radius:50%;width:64px;height:64px;background:var(--soft)"></div>'}</div>
    <div><button class="btn line sm" id="sUp" type="button">Аватарка истории</button> ${cover ? '<button class="link" id="sRm" type="button">убрать</button>' : ''}<div class="hintx">Если не загрузить, возьмётся аватарка темы.</div></div></div>
   <div class="fg"><div class="full"><label>Название</label><input class="in" id="sTitle" maxlength="80" value="${esc(s.title)}"></div>
    <div class="full"><label>Описание (показывается на первом кадре)</label><textarea class="in" id="sDesc" maxlength="500" style="min-height:70px;resize:vertical">${esc(s.description || '')}</textarea></div>
    <div class="full"><label>Хэштеги (до 8, через пробел или запятую)</label><input class="in" id="sTags" value="${esc((s.hashtags || []).map(x => '#' + x).join(' '))}" placeholder="#новости #логика #советы" autocapitalize="off"></div>
    <div><label>Тема</label><select class="in" id="sTopic">${ST.topics.map(t => `<option value="${t.id}" ${t.id === s.topic_id ? 'selected' : ''}>${esc(t.title)}</option>`).join('')}</select></div>
    <div><label>Кому показывать</label><select class="in" id="sAud">${Object.entries(AUDL).map(([k, v]) => `<option value="${k}" ${k === s.audience ? 'selected' : ''}>${v}</option>`).join('')}</select></div>
    <div><label>Статус</label><select class="in" id="sStatus"><option value="draft" ${s.status === 'draft' ? 'selected' : ''}>Черновик (не виден)</option><option value="published" ${s.status === 'published' ? 'selected' : ''}>Опубликована</option></select></div>
    <div><label>Порядок в теме</label><input class="in" id="sSort" type="number" value="${s.sort}"></div>
    <div><label>Показать с (необязательно)</label><input class="in" id="sFrom" type="datetime-local" value="${toLocal(s.publish_at)}"></div>
    <div><label>Скрыть после (необязательно)</label><input class="in" id="sTo" type="datetime-local" value="${toLocal(s.expires_at)}"></div></div>
   <h3 style="margin:20px 0 4px;font-size:14px">Кадры (формат 9:16)</h3>
   <p class="hintx" style="margin:0 0 10px">Фото обрезается по центру до 9:16 автоматически. Видео — до 30 секунд, MP4 (H.264), лучше снимать вертикально, до 30 МБ. До 12 кадров.</p>
   <div id="sSlides"></div>
   <div class="addb"><button class="btn line sm" id="addImg" type="button">+ Фото</button><button class="btn line sm" id="addVid" type="button">+ Видео до 30 сек</button></div>
   <div class="row" style="margin-top:18px"><button class="btn" id="sSave">Сохранить</button><button class="btn line" id="sPrev" type="button">Предпросмотр</button><button class="btn red sm" id="sDel" style="margin-left:auto">Удалить историю</button></div>
   <div class="hintx" id="sMsg"></div>`;
  drawSlides();
  $('#sUp').onclick = async () => { const f = await pickFile('image/*'); if (!f) return; toast('Загружаем…'); try { cover = await uploadPublic('stories', `covers/${id}.jpg`, await resizeImg(f, 256, true), 'image/jpeg'); $('#sCov').innerHTML = `<img class="th" src="${esc(cover)}" style="border-radius:50%;width:64px;height:64px" alt="">`; toast('Загружено. Нажмите «Сохранить».') } catch (e) { toast(e.message, 1) } };
  $('#sRm')?.addEventListener('click', () => { cover = null; $('#sCov').innerHTML = '<div class="th" style="border-radius:50%;width:64px;height:64px;background:var(--soft)"></div>' });
  $('#addImg').onclick = () => addSlide(id, 'image'); $('#addVid').onclick = () => addSlide(id, 'video');
  const collect = () => ({ title: $('#sTitle').value.trim(), description: $('#sDesc').value.trim() || null, hashtags: parseTags($('#sTags').value), topic_id: $('#sTopic').value, audience: $('#sAud').value, status: $('#sStatus').value,
    sort: parseInt($('#sSort').value, 10) || 0, publish_at: fromLocal($('#sFrom').value), expires_at: fromLocal($('#sTo').value), cover_url: cover });
  $('#sSave').onclick = async () => {
    const row = collect(); if (!row.title) return toast('Введите название', 1);
    if (row.status === 'published' && !SK.length) return toast('Добавьте хотя бы один кадр, прежде чем публиковать', 1);
    if (row.publish_at && row.expires_at && new Date(row.expires_at) <= new Date(row.publish_at)) return toast('«Скрыть после» должно быть позже «Показать с»', 1);
    readSlides(); const b = $('#sSave'); b.disabled = true;
    let { error } = await sb.from('stories').update(row).eq('id', id);
    if (!error) for (const [i, k] of SK.entries()) { const r = await sb.from('story_slides').update({ caption: k.caption, link_url: k.link_url, link_label: k.link_label, duration_ms: k.duration_ms, sort: i }).eq('id', k.id); if (r.error) { error = r.error; break } }
    b.disabled = false; if (error) return toast(error.message, 1); toast('Сохранено'); await loadStories(); editStory(id);
  };
  $('#sPrev').onclick = () => { const row = collect(); readSlides(); if (!SK.length) return toast('Нет кадров для просмотра', 1);
    const tp = ST.topics.find(t => t.id === row.topic_id) || {}; Stories.open([{ title: tp.title || '', avatar_url: tp.avatar_url, unseen: 0, stories: [{ id, title: row.title, description: row.description, cover_url: row.cover_url, hashtags: row.hashtags, seen: true,
      slides: SK.map(k => ({ id: k.id, kind: k.kind, url: k.media_url, poster: k.poster_url, ms: k.duration_ms, caption: k.caption, link: k.link_url, label: k.link_label })) }] }], 0, { mode: row.audience === 'kids' ? 'kids' : 'parents', modal, sb: null }) };
  $('#sDel').onclick = async () => {
    if (!confirm(`Удалить историю «${s.title}»? Кадры и статистика тоже удалятся.`)) return;
    const urls = SK.flatMap(k => [k.media_url, k.poster_url]).concat([s.cover_url]); const { error } = await sb.from('stories').delete().eq('id', id); if (error) return toast(error.message, 1);
    stRemoveFiles(urls); stSel = null; $('#stEdit').innerHTML = '<p class="muted">История удалена.</p>'; loadStories();
  };
}
function drawSlides() {
  $('#sSlides').innerHTML = SK.length ? SK.map((k, i) => `<div class="kb sl" data-i="${i}" style="display:flex;gap:12px;align-items:flex-start;flex-wrap:wrap">
    <div style="width:72px;height:128px;border-radius:12px;overflow:hidden;background:#000;flex:none;position:relative">${k.kind === 'video' ? `<video src="${esc(k.media_url)}" ${k.poster_url ? `poster="${esc(k.poster_url)}"` : ''} muted playsinline preload="metadata" style="width:100%;height:100%;object-fit:cover"></video><span class="tag" style="position:absolute;left:4px;bottom:4px;margin:0">${Math.round(k.duration_ms / 1000)} с</span>` : `<img src="${esc(k.media_url)}" alt="" style="width:100%;height:100%;object-fit:cover">`}</div>
    <div style="flex:1;min-width:200px;display:grid;gap:8px">
     <div class="row" style="margin:0"><b>Кадр ${i + 1}</b> <span class="muted">${k.kind === 'video' ? 'видео' : 'фото'}</span><span style="flex:1"></span>
      <button class="ib" data-up title="Выше" ${i ? '' : 'disabled'}>↑</button><button class="ib" data-dn title="Ниже" ${i < SK.length - 1 ? '' : 'disabled'}>↓</button><button class="ib" data-rm title="Удалить кадр">✕</button></div>
     <input class="in" data-cap maxlength="200" placeholder="Подпись на кадре (необязательно)" value="${esc(k.caption || '')}">
     <div class="row" style="margin:0"><input class="in" data-link maxlength="300" placeholder="Ссылка кнопки: https://… или cabinet.html (необязательно)" value="${esc(k.link_url || '')}"><input class="in" data-label maxlength="30" placeholder="Текст кнопки" value="${esc(k.link_label || '')}" style="max-width:170px"></div>
     ${k.kind === 'image' ? `<div class="row" style="margin:0"><label class="muted" style="font-size:12px">Показывать, секунд:</label><input class="in" data-sec type="number" min="2" max="15" value="${Math.round(k.duration_ms / 1000)}" style="max-width:90px"></div>` : ''}
    </div></div>`).join('') : '<p class="muted">Кадров пока нет — добавьте фото или видео.</p>';
  $$('#sSlides .sl').forEach(el => { const i = +el.dataset.i;
    el.querySelector('[data-up]')?.addEventListener('click', () => { readSlides(); [SK[i - 1], SK[i]] = [SK[i], SK[i - 1]]; drawSlides() });
    el.querySelector('[data-dn]')?.addEventListener('click', () => { readSlides(); [SK[i + 1], SK[i]] = [SK[i], SK[i + 1]]; drawSlides() });
    el.querySelector('[data-rm]').addEventListener('click', async () => { if (!confirm('Удалить кадр?')) return; readSlides(); const k = SK[i], { error } = await sb.from('story_slides').delete().eq('id', k.id); if (error) return toast(error.message, 1); stRemoveFiles([k.media_url, k.poster_url]); SK.splice(i, 1); drawSlides() });
  });
}
function readSlides() {
  $$('#sSlides .sl').forEach(el => { const k = SK[+el.dataset.i]; if (!k) return;
    k.caption = el.querySelector('[data-cap]').value.trim() || null; k.link_url = el.querySelector('[data-link]').value.trim() || null; k.link_label = el.querySelector('[data-label]').value.trim() || null;
    const sec = el.querySelector('[data-sec]'); if (sec) k.duration_ms = Math.min(15, Math.max(2, parseInt(sec.value, 10) || 5)) * 1000;
    if (k.link_url && !/^(https:\/\/|cabinet\.html|index\.html|#)/.test(k.link_url)) { toast('Ссылка должна начинаться с https:// (или cabinet.html)', 1); k.link_url = null }
  });
}
// метаданные видео: длительность, пропорции, первый кадр
function probeVideo(file) {
  return new Promise((res, rej) => { const v = document.createElement('video'), url = URL.createObjectURL(file); v.preload = 'metadata'; v.muted = true; v.playsInline = true;
    v.onloadedmetadata = () => { const out = { dur: v.duration, w: v.videoWidth, h: v.videoHeight }; v.currentTime = Math.min(.2, v.duration / 2) ;
      v.onseeked = () => { try { const c = document.createElement('canvas'), k = Math.min(1, 720 / Math.max(out.w, out.h)); c.width = Math.round(out.w * k); c.height = Math.round(out.h * k); c.getContext('2d').drawImage(v, 0, 0, c.width, c.height); c.toBlob(b => { URL.revokeObjectURL(url); out.poster = b; res(out) }, 'image/jpeg', .82) } catch { URL.revokeObjectURL(url); res(out) } };
      v.onerror = () => { URL.revokeObjectURL(url); res(out) } };
    v.onerror = () => { URL.revokeObjectURL(url); rej(new Error('Не удалось прочитать видео. Нужен MP4 (H.264).')) }; v.src = url });
}
async function addSlide(storyId, kind) {
  if (SK.length >= 12) return toast('В истории не больше 12 кадров', 1);
  const f = await pickFile(kind === 'video' ? 'video/mp4,video/quicktime,video/webm' : 'image/*'); if (!f) return;
  const msg = t => $('#sMsg').textContent = t; readSlides();
  try {
    let media, poster = null, ms = 5000;
    if (kind === 'video') {
      if (f.size > 30 * 1024 * 1024) return toast('Видео больше 30 МБ. Сожмите его или обрежьте.', 1);
      msg('Проверяем видео…'); const p = await probeVideo(f);
      if (!(p.dur > 0)) return toast('Не удалось определить длительность видео. Нужен MP4 (H.264).', 1);
      if (p.dur > 30.4) return toast(`Видео длится ${Math.round(p.dur)} с — максимум 30 секунд. Обрежьте его.`, 1);
      if (p.w && p.h && Math.abs(p.w / p.h - 9 / 16) > .06 && !confirm(`Пропорции видео ${p.w}×${p.h} не 9:16 — края будут обрезаны. Загрузить всё равно?`)) return msg('');
      ms = Math.max(1000, Math.round(p.dur * 1000));
      msg('Загружаем видео… не закрывайте страницу.'); const ext = (f.name.split('.').pop() || 'mp4').toLowerCase().replace(/[^a-z0-9]/g, '') || 'mp4';
      media = await uploadPublic('stories', `s/${storyId}/${uid()}.${ext}`, f, f.type || 'video/mp4');
      if (p.poster) poster = await uploadPublic('stories', `s/${storyId}/${uid()}.jpg`, p.poster, 'image/jpeg');
    } else {
      msg('Загружаем фото…'); media = await uploadPublic('stories', `s/${storyId}/${uid()}.jpg`, await coverImg(f, 900, 1600), 'image/jpeg');
    }
    const { data, error } = await sb.from('story_slides').insert({ story_id: storyId, kind, media_url: media, poster_url: poster, duration_ms: ms, sort: SK.length }).select().single();
    if (error) { stRemoveFiles([media, poster]); throw error }
    SK.push(data); drawSlides(); msg('Кадр добавлен. Не забудьте нажать «Сохранить».');
  } catch (e) { msg(''); toast('Не удалось добавить: ' + (e.message || e), 1) }
}
