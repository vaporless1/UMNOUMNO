// УМНО: service worker. Сеть в приоритете (чтобы обновления сайта доходили сразу), кэш — на случай плохой связи.
const V = 'umno-v12', SHELL = ['cabinet.html', 'common.css', 'common.js', 'kid.css', 'kid.js', 'quiz.js', 'growth.js', 'legal.js', 'icons/icon-192.png'];
self.addEventListener('install', e => { e.waitUntil(caches.open(V).then(c => Promise.all(SHELL.map(u => c.add(u).catch(() => { })))).then(() => self.skipWaiting())) });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(k => Promise.all(k.filter(x => x !== V).map(x => caches.delete(x)))).then(() => self.clients.claim())) });
self.addEventListener('fetch', e => {
  const r = e.request, u = new URL(r.url);
  if (r.method !== 'GET' || u.origin !== location.origin || r.headers.has('range')) return;   // Supabase, шрифты, видео — мимо кэша
  e.respondWith(fetch(r).then(res => { if (res.ok && res.type === 'basic') { const c = res.clone(); caches.open(V).then(ch => ch.put(r, c)) } return res })
    .catch(() => caches.match(r, { ignoreSearch: true }).then(m => m || (r.mode === 'navigate' ? caches.match('cabinet.html') : Response.error()))));
});
