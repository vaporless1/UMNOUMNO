/* ===== Общие настройки и помощники (кабинет + админка) ===== */
const CONFIG = {
  SUPABASE_URL: "https://oqwnpqjwznlcuudzvntp.supabase.co",
  SUPABASE_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xd25wcWp3em5sY3V1ZHp2bnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMzMDEwNjAsImV4cCI6MjEwODg3NzA2MH0.fBgSrNFTz07DE9uYzjyFTupOpZEw9E_xjnx9zq3-6LM"
};
// Если библиотека не загрузилась (блокировка CDN, плохая сеть) — показываем понятное сообщение вместо пустой страницы
if (typeof supabase === 'undefined') {
  document.addEventListener('DOMContentLoaded', () => { document.body.innerHTML = '<div style="max-width:420px;margin:12vh auto;padding:0 20px;text-align:center;font-family:system-ui,sans-serif"><h2 style="margin-bottom:12px">Не удалось загрузить сайт</h2><p style="color:#666;line-height:1.5;margin-bottom:20px">Проверьте интернет. Если включён VPN или блокировщик рекламы, отключите его и обновите страницу.</p><button onclick="location.reload()" style="border:0;background:#B07F5E;color:#fff;font:700 16px system-ui;padding:14px 28px;border-radius:99px">Обновить</button></div>' });
  throw new Error('supabase-js не загружен');
}
// На телефонах localStorage бывает недоступен (приватный режим, встроенные браузеры мессенджеров) — тогда храним сессию в памяти, а не падаем
const _mem = {}, safeStorage = {
  getItem: k => { try { return localStorage.getItem(k) } catch (e) { return _mem[k] ?? null } },
  setItem: (k, v) => { try { localStorage.setItem(k, v) } catch (e) { _mem[k] = v } },
  removeItem: k => { try { localStorage.removeItem(k) } catch (e) { delete _mem[k] } }
};
const sb = supabase.createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_KEY, { auth: { storage: safeStorage, persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } });
const $ = (s, r = document) => r.querySelector(s), $$ = (s, r = document) => [...r.querySelectorAll(s)];
const esc = t => String(t ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const say = (el, t, k) => { el.textContent = t; el.className = 'msg ' + (k || '') };
const uid = () => crypto.randomUUID();
const UNAME = /^[a-z0-9_]{3,20}$/;
const PLAN = { none: 'Нет подписки', trial: 'Пробный период', family: 'Семейный', year: 'Годовой' };
const fd = d => d ? new Date(d).toLocaleDateString('ru') : '—';
let _tt; function toast(m, err) { let t = $('#toast'); if (!t) { t = document.createElement('div'); t.id = 'toast'; document.body.append(t) } t.textContent = m; t.className = (err ? 'err ' : '') + 'on'; clearTimeout(_tt); _tt = setTimeout(() => t.className = '', 3400) }

const THEMES = { brown: ['#B07F5E', '#8f6246'], blue: ['#4f8ef7', '#2f6fd6'], pink: ['#e0709a', '#c2527c'], green: ['#4caf7d', '#2e8f5e'], purple: ['#8a63d2', '#6b45b8'], orange: ['#e8873a', '#c96a1f'] };
function applyTheme(k) { const t = THEMES[k] || THEMES.brown, r = document.documentElement.style; r.setProperty('--brown', t[0]); r.setProperty('--brown-d', t[1]) }

async function sha(s) { const b = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('umno:' + s)); return [...new Uint8Array(b)].map(x => x.toString(16).padStart(2, '0')).join('') }

async function resizeImg(file, max = 800, square = false) {
  const im = await createImageBitmap(file); let w = im.width, h = im.height, sx = 0, sy = 0, sw = w, sh = h;
  if (square) { const m = Math.min(w, h); sx = (w - m) / 2; sy = (h - m) / 2; sw = sh = m; w = h = Math.min(max, m) }
  else { const k = Math.min(1, max / Math.max(w, h)); w = Math.round(w * k); h = Math.round(h * k) }
  const c = document.createElement('canvas'); c.width = w; c.height = h; const x = c.getContext('2d');
  x.fillStyle = '#fff'; x.fillRect(0, 0, w, h); x.drawImage(im, sx, sy, sw, sh, 0, 0, w, h);
  return new Promise(r => c.toBlob(r, 'image/jpeg', .86));
}
async function uploadPublic(bucket, path, blob, type) {
  const { error } = await sb.storage.from(bucket).upload(path, blob, { upsert: true, contentType: type || blob.type });
  if (error) throw error;
  return sb.storage.from(bucket).getPublicUrl(path).data.publicUrl + '?v=' + Date.now();
}
function pickFile(accept) { return new Promise(r => { const i = document.createElement('input'); i.type = 'file'; i.accept = accept; i.onchange = () => r(i.files[0] || null); i.click() }) }

function embed(u) {
  if (!u) return ''; let m;
  if (m = u.match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/|shorts\/))([\w-]{11})/)) return `<iframe src="https://www.youtube-nocookie.com/embed/${m[1]}?rel=0" allow="fullscreen" allowfullscreen title="Видеоурок"></iframe>`;
  if (m = u.match(/rutube\.ru\/(?:video|play\/embed)\/([a-f0-9]{32})/)) return `<iframe src="https://rutube.ru/play/embed/${m[1]}" allow="fullscreen" allowfullscreen title="Видеоурок"></iframe>`;
  if (m = u.match(/vimeo\.com\/(?:video\/)?(\d+)/)) return `<iframe src="https://player.vimeo.com/video/${m[1]}" allow="fullscreen" allowfullscreen title="Видеоурок"></iframe>`;
  if (/^https:\/\//.test(u) && /\.(mp4|webm|mov)(\?|$)/i.test(u)) return `<video controls playsinline preload="metadata" src="${esc(u)}"></video>`;
  return '';
}

function injectIcons() {
  const P = {
    out: 'M9 4H5v16h4M16 8l4 4-4 4M20 12H9', x: 'M6 6l12 12M18 6L6 18', abc: 'M4 20L12 4l8 16M7.5 14h9', globe: 'M12 3a9 9 0 100 18 9 9 0 000-18zM3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18',
    puzzle: 'M10 4a2 2 0 114 0v2h4v4h-2a2 2 0 100 4h2v4h-4v-2a2 2 0 10-4 0v2H6v-4h2a2 2 0 100-4H6V6h4z', chat: 'M4 5h16v11H9l-5 4zM8 9h8M8 12h5',
    star: 'M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z', check: 'M5 12.5l4.5 4.5L19 7', user: 'M12 4a4 4 0 100 8 4 4 0 000-8zM4 21c0-4.4 3.6-7 8-7s8 2.6 8 7',
    plus: 'M12 5v14M5 12h14', trash: 'M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13', up: 'M12 19V5M6 11l6-6 6 6', down: 'M12 5v14M6 13l6 6 6-6',
    flame: 'M12 3c1 4 5 5 5 10a5 5 0 01-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-5 1-9z', trophy: 'M8 4h8v5a4 4 0 01-8 0zM8 6H4v2a3 3 0 003 3M16 6h4v2a3 3 0 01-3 3M12 13v4M8 20h8M9 17h6',
    book: 'M4 5a2 2 0 012-2h13v16H6a2 2 0 00-2 2zM4 19a2 2 0 012-2h13', music: 'M9 18V6l10-2v12M9 18a3 3 0 11-6 0 3 3 0 016 0zM19 16a3 3 0 11-6 0 3 3 0 016 0z',
    brush: 'M18 3l3 3-9 9-3-3zM9 12c-3 0-4 2-4 4 0 2-1 3-2 4 4 1 8 0 8-4', rocket: 'M14 5c3-2 6-2 6-2s0 3-2 6l-5 5-4-4zM9 15l-4 1 1 4 4-1M5 19c1-4 3-6 5-7',
    crown: 'M3 8l4 4 5-7 5 7 4-4-2 11H5z', lock: 'M6 11h12v9H6zM8 11V8a4 4 0 018 0v3', gear: 'M12 8a4 4 0 100 8 4 4 0 000-8zM12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2',
    home: 'M3 11l9-8 9 8M5 10v10h14V10', chart: 'M4 20V4M4 20h16M8 16v-5M12 16V8M16 16v-3', baby: 'M12 3a9 9 0 100 18 9 9 0 000-18zM9 10h.01M15 10h.01M9 15c1 1 5 1 6 0',
    image: 'M3 5h18v14H3zM3 16l5-5 4 4 3-3 6 5M16 9h.01', edit: 'M4 20h4L19 9l-4-4L4 16zM13 7l4 4', video: 'M3 6h13v12H3zM16 10l5-3v10l-5-3',
    sound: 'M4 9v6h4l5 4V5L8 9zM16.5 8.5a5 5 0 010 7M19 6a8.5 8.5 0 010 12', mute: 'M4 9v6h4l5 4V5L8 9zM17 9.5l4 5M21 9.5l-4 5',
    shop: 'M5 8h14l-1.2 12H6.2zM9 8V7a3 3 0 016 0v1', play: 'M7 4.5l12 7.5-12 7.5z', heart: 'M12 20s-8-5-8-11a4.5 4.5 0 018-2.8A4.5 4.5 0 0120 9c0 6-8 11-8 11z',
    clock: 'M12 3a9 9 0 100 18 9 9 0 000-18zM12 7v5l3 2', back: 'M15 5l-7 7 7 7', gift: 'M4 11h16v9H4zM3 8h18v3H3zM12 8v12M12 8C9 8 8 4 10.5 4S13 8 12 8zM12 8c3 0 4-4 1.5-4S11 8 12 8z'
  };
  const s = document.createElement('div'); s.style.cssText = 'position:absolute;width:0;height:0;overflow:hidden';
  s.innerHTML = '<svg><defs>' + Object.entries(P).map(([k, d]) => `<symbol id="i-${k}" viewBox="0 0 24 24"><path d="${d}"/></symbol>`).join('') + '</defs></svg>';
  document.body.prepend(s);
}
const ico = n => `<svg class="ic" aria-hidden="true"><use href="#i-${n}"/></svg>`;
