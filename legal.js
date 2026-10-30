/* ===== Реквизиты оператора и юридические помощники =====
   ЗАПОЛНИТЕ значения ниже ОДИН РАЗ — они подставятся во все документы.
   Всё, что осталось в [квадратных скобках], на страницах подсвечивается жёлтым. */
const LEGAL = {
  ver: '2026-10-30',
  site: 'umno-umno.online',
  op_name: 'Носков Кирилл Олегович',
  op_status: 'физическое лицо',
  op_addr: 'почтовый адрес не публикуется, обращения принимаются по e-mail',
  op_email: 'noskovkirill220@gmail.com',
  op_resp: 'сам Оператор (физическое лицо)',
  op_rkn: '[номер из реестра операторов Роскомнадзора, после подачи уведомления]',
  op_vat: '',
  storage: '[название хостинга/дата-центра и город в РФ, где расположена база данных]',
  prov_db: 'Supabase, Inc. (пока; будет заменён на российского провайдера)', prov_db_c: '[регион проекта: Supabase → Settings → Infrastructure]',
  prov_host: 'GitHub Pages (GitHub, Inc.) — пока сайт размещён там', prov_host_c: 'США',
  prov_mail: 'Supabase Auth (письма входа и сброса пароля), Resend (недельный отчёт)', prov_mail_c: 'США',
  prov_form: 'Web3Forms (пока подключён форм-сервис) — замените при смене', prov_form_c: 'США',
  prov_pay: 'не подключён (платежи не принимаются)', prov_pay_c: '—',
  pay_methods: 'не подключены',
  paid: false, // поставьте true, когда появятся платные тарифы и оферта вступит в силу
  prov_fonts: 'Google Fonts (Google LLC)'
};
(function () {
  const $$ = (s, r) => [].slice.call((r || document).querySelectorAll(s));
  window.LEGAL = LEGAL;
  $$('[data-l]').forEach(el => { const v = LEGAL[el.dataset.l]; if (v == null) return; el.textContent = v; if (/^\[|\[/.test(v)) el.classList.add('todo') });
  $$('[data-mail]').forEach(a => { const v = LEGAL[a.dataset.mail]; if (v && v[0] !== '[') a.href = 'mailto:' + v; else a.removeAttribute('href') });
  // ссылки-подвал для страниц, где есть <div id="lfoot">
  const lf = document.getElementById('lfoot');
  if (lf) {
    lf.className = 'lfoot';
    lf.innerHTML = '<a href="privacy.html">Политика конфиденциальности</a><a href="terms.html">Пользовательское соглашение</a>'+(LEGAL.paid?'<a href="offer.html">Оферта</a>':'')+'<a href="consent.html">Согласие на обработку ПДн</a><a href="cookies.html">Cookie</a><span>0+</span>';
  }
  // баннер cookie (только информирование: используем лишь технические данные)
  let seen = false; try { seen = !!localStorage.getItem('umno_cookie') } catch (e) { }
  if (!seen && !document.getElementById('ckb') && document.body) {
    const b = document.createElement('div'); b.id = 'ckb'; b.setAttribute('role', 'dialog'); b.setAttribute('aria-label', 'Уведомление об использовании cookie');
    b.innerHTML = '<span>Мы используем только технические cookie и локальное хранилище — для входа и настроек. Рекламы и аналитики нет. <a href="cookies.html">Подробнее</a></span><button type="button">Понятно</button>';
    b.querySelector('button').onclick = () => { try { localStorage.setItem('umno_cookie', '1') } catch (e) { } b.remove() };
    document.body.appendChild(b);
  }
})();
