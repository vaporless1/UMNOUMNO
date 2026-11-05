/* УМНО · админка: вкладка «События» (карточки на главной странице кабинета) */
let EV = [], evSel = null;
const evToLocal = iso => iso ? new Date(new Date(iso) - new Date(iso).getTimezoneOffset() * 6e4).toISOString().slice(0, 16) : '';
const evFromLocal = v => v ? new Date(v).toISOString() : null;
const evPath = url => { const m = /\/object\/public\/events\/([^?]+)/.exec(url || ''); return m ? decodeURIComponent(m[1]) : null };

async function loadEvents() {
  const { data, error } = await sb.from('events').select('*').order('created_at', { ascending: false });
  if (error) { $('#evList').innerHTML = '<p class="msg err">Не загрузилось: ' + esc(error.message) + '<br>Выполнен ли файл schema14_events.sql в Supabase?</p>'; return }
  EV = data || []; drawEvList();
}
function evState(e) {
  if (!e.published) return ['черновик', ''];
  if (e.expires_at && new Date(e.expires_at) <= new Date()) return ['срок истёк', 'red'];
  if (e.publish_at && new Date(e.publish_at) > new Date()) return ['отложено', ''];
  return ['на главной', 'ok'];
}
function drawEvList() {
  $('#evList').innerHTML = `<div class="row" style="margin:0 0 14px"><button class="btn sm" id="evNew">+ Событие</button></div>` + (EV.map(e => {
    const [lbl, cls] = evState(e);
    return `<div class="li ${evSel === e.id ? 'on' : ''}" data-ev="${e.id}">${e.image_url ? `<img class="th" src="${esc(e.image_url)}" alt="">` : ''}<span style="flex:1;min-width:0"><b>${esc(e.title)}</b> <span class="tag ${cls}">${lbl}</span>${e.pinned ? '<span class="tag">закреплено</span>' : ''}<br><small class="muted">${e.starts_at ? dt(e.starts_at) : 'без даты'}${e.place ? ' · ' + esc(e.place) : ''}</small></span></div>`;
  }).join('') || '<p class="muted">Событий пока нет. Создайте первое, например: «Вебинар для родителей» или «Новый курс».</p>');
  $('#evNew').onclick = newEvent;
  $$('#evList [data-ev]').forEach(b => b.onclick = () => { evSel = b.dataset.ev; drawEvList(); editEvent(evSel) });
}
async function newEvent() {
  const { data, error } = await sb.from('events').insert({ title: 'Новое событие', published: false }).select().single();
  if (error) return toast(error.message, 1); evSel = data.id; await loadEvents(); editEvent(data.id);
}
function editEvent(id) {
  const e = EV.find(x => x.id === id); if (!e) return; let img = e.image_url;
  const paint = () => $('#eImg').innerHTML = img ? `<img src="${esc(img)}" alt="" style="width:100%;max-height:220px;object-fit:cover;border-radius:16px">` : '<div class="muted" style="padding:20px;background:var(--soft);border-radius:16px;text-align:center">Картинка не выбрана</div>';
  $('#evEdit').innerHTML = `<h2 style="font-size:18px;margin-bottom:14px">Событие</h2>
   <div id="eImg"></div><div class="row" style="margin:10px 0 14px"><button class="btn line sm" id="eUp" type="button">Загрузить картинку</button><button class="link" id="eRm" type="button">убрать</button><span class="hintx">Лучше горизонтальная, 1200×600.</span></div>
   <div class="fg"><div class="full"><label>Заголовок</label><input class="in" id="eTitle" maxlength="100" value="${esc(e.title)}"></div>
    <div class="full"><label>Описание</label><textarea class="in" id="eBody" maxlength="1000" style="min-height:110px;resize:vertical">${esc(e.body || '')}</textarea></div>
    <div><label>Дата и время события (необязательно)</label><input class="in" id="eStart" type="datetime-local" value="${evToLocal(e.starts_at)}"></div>
    <div><label>Место или формат (необязательно)</label><input class="in" id="ePlace" maxlength="120" value="${esc(e.place || '')}" placeholder="Онлайн, в приложении…"></div>
    <div><label>Ссылка кнопки</label><input class="in" id="eLink" maxlength="300" value="${esc(e.link_url || '')}" placeholder="https://… или cabinet.html"></div>
    <div><label>Текст кнопки</label><input class="in" id="eLabel" maxlength="30" value="${esc(e.link_label || '')}" placeholder="Записаться"></div>
    <div><label>Показать с (необязательно)</label><input class="in" id="eFrom" type="datetime-local" value="${evToLocal(e.publish_at)}"></div>
    <div><label>Скрыть после (необязательно)</label><input class="in" id="eTo" type="datetime-local" value="${evToLocal(e.expires_at)}"></div></div>
   <label class="ck" style="margin-top:12px"><input type="checkbox" id="ePin" ${e.pinned ? 'checked' : ''}> Закрепить сверху</label>
   <label class="ck" style="margin-top:8px"><input type="checkbox" id="ePub" ${e.published ? 'checked' : ''}> Опубликовать на главной странице кабинета</label>
   <div class="row" style="margin-top:16px"><button class="btn" id="eSave">Сохранить</button><button class="btn red sm" id="eDel" style="margin-left:auto">Удалить</button></div>`;
  paint();
  $('#eUp').onclick = async () => { const f = await pickFile('image/*'); if (!f) return; toast('Загружаем…');
    try { img = await uploadPublic('events', `${id}/${uid()}.jpg`, await coverImg(f, 1200, 600), 'image/jpeg'); paint(); toast('Загружено. Нажмите «Сохранить».') } catch (er) { toast(er.message, 1) } };
  $('#eRm').onclick = () => { img = null; paint() };
  $('#eSave').onclick = async () => {
    const link = $('#eLink').value.trim() || null, title = $('#eTitle').value.trim();
    if (!title) return toast('Введите заголовок', 1);
    if (link && !/^(https:\/\/|cabinet\.html|index\.html|#)/.test(link)) return toast('Ссылка должна начинаться с https:// (или cabinet.html)', 1);
    const from = evFromLocal($('#eFrom').value), to = evFromLocal($('#eTo').value);
    if (from && to && new Date(to) <= new Date(from)) return toast('«Скрыть после» должно быть позже «Показать с»', 1);
    const row = { title, body: $('#eBody').value.trim() || null, image_url: img, starts_at: evFromLocal($('#eStart').value), place: $('#ePlace').value.trim() || null, link_url: link, link_label: $('#eLabel').value.trim() || null,
      pinned: $('#ePin').checked, published: $('#ePub').checked, publish_at: from, expires_at: to };
    const old = evPath(e.image_url); const { error } = await sb.from('events').update(row).eq('id', id); if (error) return toast(error.message, 1);
    if (old && evPath(img) !== old) sb.storage.from('events').remove([old]).catch(() => { });
    toast('Сохранено'); await loadEvents(); editEvent(id);
  };
  $('#eDel').onclick = async () => {
    if (!confirm(`Удалить событие «${e.title}»?`)) return;
    const { error } = await sb.from('events').delete().eq('id', id); if (error) return toast(error.message, 1);
    const p = evPath(e.image_url); if (p) sb.storage.from('events').remove([p]).catch(() => { });
    evSel = null; $('#evEdit').innerHTML = '<p class="muted">Событие удалено.</p>'; loadEvents();
  };
}
