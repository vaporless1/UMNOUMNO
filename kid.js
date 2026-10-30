/* ===== УМНО: детский режим — маскот, фоны-сцены, рамки, конфетти ===== */
const Kid = (() => {
  const rng = s => () => (s = s * 16807 % 2147483647) / 2147483647;
  const r1 = n => Math.round(n * 10) / 10;
  let N = 0;

  /* ---------- маскот: мишка ---------- */
  const HATS = {
    bow: '<path d="M214 46l-34-20v40z M214 46l34-20v40z" fill="#ff5c8a" stroke="#d93a6a" stroke-width="3" stroke-linejoin="round"/><circle cx="214" cy="46" r="9" fill="#e63e6d"/>',
    cap: '<path d="M66 86C64 14 236 14 234 86z" fill="#3b82f6"/><path d="M150 20v66" stroke="#2f6fe0" stroke-width="3" opacity=".5"/><path d="M56 88h152q40 2 52 16q-58-8-204-4z" fill="#1d4ed8"/><circle cx="150" cy="22" r="8" fill="#1d4ed8"/>',
    glasses: '<g fill="rgba(255,255,255,.4)" stroke="#27303f" stroke-width="6"><circle cx="116" cy="112" r="27"/><circle cx="184" cy="112" r="27"/></g><path d="M143 110q7-7 14 0M90 106L62 96M210 106l28-10" stroke="#27303f" stroke-width="6" fill="none" stroke-linecap="round"/>',
    party: '<path d="M102 48L150-40 198 48z" fill="#a855f7"/><path d="M118 22h64M128 0h44" stroke="#fde047" stroke-width="7" stroke-linecap="round"/><circle cx="150" cy="-42" r="13" fill="#fde047"/>',
    astro: '<circle cx="150" cy="120" r="110" fill="rgba(186,230,253,.3)" stroke="#e5e7eb" stroke-width="9"/><path d="M92 54q24-26 62-28" stroke="#fff" stroke-width="8" fill="none" stroke-linecap="round" opacity=".75"/><path d="M150 10v-30" stroke="#e5e7eb" stroke-width="6"/><circle cx="150" cy="-24" r="9" fill="#ef4444"/>',
    crown: '<path d="M96 52L102-4 128 26 150-16 172 26 198-4 204 52z" fill="#fbbf24" stroke="#d99a06" stroke-width="5" stroke-linejoin="round"/><circle cx="102" cy="-4" r="6" fill="#ef4444"/><circle cx="150" cy="-16" r="7" fill="#3b82f6"/><circle cx="198" cy="-4" r="6" fill="#22c55e"/>'
  };
  function mascotG(hat, o = {}) {
    const mouth = o.mood === 'wow'
      ? '<path d="M130 158q20 36 40 0z" fill="#7a2a1a"/><path d="M142 174q8 6 16 0" fill="#ff7a8a"/>'
      : '<path d="M150 148v10M128 160q22 22 44 0" stroke="#4a2410" stroke-width="5" fill="none" stroke-linecap="round"/>';
    return `<ellipse cx="150" cy="352" rx="104" ry="14" fill="rgba(0,0,0,.15)"/>
    <ellipse cx="100" cy="334" rx="46" ry="28" fill="#a8582a"/><ellipse cx="200" cy="334" rx="46" ry="28" fill="#a8582a"/>
    <ellipse cx="104" cy="338" rx="22" ry="13" fill="#f3c9a0"/><ellipse cx="196" cy="338" rx="22" ry="13" fill="#f3c9a0"/>
    <ellipse cx="150" cy="250" rx="94" ry="100" fill="#b9652f"/><ellipse cx="150" cy="268" rx="58" ry="70" fill="#f3c9a0"/>
    <ellipse cx="62" cy="250" rx="26" ry="52" transform="rotate(22 62 250)" fill="#a8582a"/>
    <ellipse class="m-wave" cx="254" cy="170" rx="26" ry="52" transform="rotate(-24 254 170)" fill="#a8582a"/>
    <circle cx="84" cy="54" r="36" fill="#a8582a"/><circle cx="84" cy="54" r="20" fill="#f3c9a0"/><circle cx="216" cy="54" r="36" fill="#a8582a"/><circle cx="216" cy="54" r="20" fill="#f3c9a0"/>
    <circle cx="150" cy="120" r="94" fill="#b9652f"/>
    <circle cx="88" cy="154" r="16" fill="#ff8aa1" opacity=".55"/><circle cx="212" cy="154" r="16" fill="#ff8aa1" opacity=".55"/>
    <g class="m-eye"><ellipse cx="116" cy="108" rx="17" ry="23" fill="#fff"/><circle cx="120" cy="112" r="12" fill="#3a1d0e"/><circle cx="124" cy="106" r="4" fill="#fff"/></g>
    <g class="m-eye"><ellipse cx="184" cy="108" rx="17" ry="23" fill="#fff"/><circle cx="188" cy="112" r="12" fill="#3a1d0e"/><circle cx="192" cy="106" r="4" fill="#fff"/></g>
    <ellipse cx="150" cy="152" rx="46" ry="36" fill="#f3c9a0"/><ellipse cx="150" cy="138" rx="16" ry="11" fill="#4a2410"/>${mouth}${HATS[hat] || ''}`;
  }
  const mascotSvg = (hat, o = {}) => `<svg class="mas ${o.cls || ''}" viewBox="${o.view || '0 -50 300 420'}" aria-hidden="true">${mascotG(hat, o)}</svg>`;

  /* ---------- детали сцен ---------- */
  const cloud = (x, y, s, dur, fill = '#fff', op = 1) => `<g transform="translate(${x} ${y}) scale(${s})"><g class="cl" style="animation-duration:${dur}s;animation-delay:-${r1(dur / 3)}s" fill="${fill}" opacity="${op}"><ellipse cx="0" cy="0" rx="74" ry="28"/><circle cx="-28" cy="-18" r="27"/><circle cx="14" cy="-30" r="34"/><circle cx="50" cy="-8" r="23"/></g></g>`;
  const pine = (x, y, s, c, snow) => `<g transform="translate(${x} ${y}) scale(${s})"><rect x="-9" y="-6" width="18" height="40" rx="4" fill="#7a4a24"/><path d="M0-150L-54-62H-30L-70-6H70L30-62H54z" fill="${c}"/>${snow ? '<path d="M0-150L-26-102Q0-92 26-102zM-30-62L-44-40Q-30-30-14-40zM30-62l14 22Q30-30 14-40zM-36-10l-12 12Q-20 12 0 4 20 12 48 2L36-10z" fill="#fff"/>' : ''}</g>`;
  const rays = (n, r0, r1_, w, fill) => Array.from({ length: n }, (_, i) => `<rect x="${-w / 2}" y="${-r1_}" width="${w}" height="${r1_ - r0}" rx="${w / 2}" fill="${fill}" transform="rotate(${i * 360 / n})"/>`).join('');

  const SCENES = {
    meadow(u) {
      const R = rng(7); let fl = '';
      for (let i = 0; i < 34; i++) { const x = R() * 1600, y = 800 + R() * 85, s = .7 + R() * .7, c = ['#ff6b9d', '#ffd23f', '#ffffff', '#ff9f43', '#c084fc'][i % 5];
        fl += `<g transform="translate(${r1(x)} ${r1(y)}) scale(${r1(s)})"><path d="M0 0v36" stroke="#2f9e44" stroke-width="4"/><g fill="${c}"><circle cx="0" cy="-9" r="7"/><circle cx="9" cy="-2" r="7"/><circle cx="-9" cy="-2" r="7"/><circle cx="5" cy="7" r="7"/><circle cx="-5" cy="7" r="7"/></g><circle r="5" fill="#ffd23f"/></g>` }
      const arcs = ['#ff5a5f', '#ff9f43', '#ffd93d', '#6bcf63', '#4dabf7', '#9775fa'].map((c, i) => { const r = 430 - i * 24; return `<path d="M${330 - r} 730A${r} ${r} 0 0 1 ${330 + r} 730" stroke="${c}" stroke-width="24" fill="none" opacity=".85"/>` }).join('');
      return `<defs><linearGradient id="m${u}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6ec6ff"/><stop offset="1" stop-color="#e3f6ff"/></linearGradient></defs>
      <rect width="1600" height="900" fill="url(#m${u})"/>
      <g transform="translate(1380 150)"><g class="spin">${rays(12, 86, 124, 14, '#ffd23f')}</g><circle r="68" fill="#ffd23f"/><circle r="54" fill="#ffe46b"/><circle cx="-19" cy="-6" r="5.5" fill="#6b4a00"/><circle cx="19" cy="-6" r="5.5" fill="#6b4a00"/><path d="M-20 14q20 18 40 0" stroke="#6b4a00" stroke-width="5" fill="none" stroke-linecap="round"/></g>
      ${arcs}${cloud(260, 150, 1.25, 70)}${cloud(720, 95, .9, 90)}${cloud(1010, 250, 1.4, 110)}${cloud(120, 330, .8, 80)}
      <path d="M0 650Q300 530 640 630T1260 610T1600 570V900H0z" fill="#86d96f"/>
      <g transform="translate(250 560)"><rect x="-10" y="0" width="20" height="70" rx="6" fill="#8a5a2b"/><circle cx="0" cy="-20" r="62" fill="#3f9e4a"/><circle cx="-34" cy="-4" r="38" fill="#4cb35a"/><circle cx="36" cy="-6" r="40" fill="#4cb35a"/><circle cx="-14" cy="-28" r="9" fill="#ff5a5f"/><circle cx="24" cy="-18" r="9" fill="#ff5a5f"/><circle cx="2" cy="6" r="9" fill="#ff5a5f"/></g>
      <path d="M0 730Q420 610 820 710T1600 690V900H0z" fill="#5ec562"/>
      <path d="M0 820Q520 740 1020 810T1600 780V900H0z" fill="#3fae4f"/>${fl}
      <g transform="translate(560 560)"><g class="fly"><ellipse cx="-10" cy="-4" rx="11" ry="16" fill="#ff6b9d" transform="rotate(-30 -10 -4)"/><ellipse cx="10" cy="-4" rx="11" ry="16" fill="#ff6b9d" transform="rotate(30 10 -4)"/><rect x="-2" y="-14" width="4" height="28" rx="2" fill="#4a2f1a"/></g></g>
      <g transform="translate(1180 520)"><g class="fly" style="animation-delay:-1.5s"><ellipse cx="-10" cy="-4" rx="11" ry="16" fill="#ffa94d" transform="rotate(-30 -10 -4)"/><ellipse cx="10" cy="-4" rx="11" ry="16" fill="#ffa94d" transform="rotate(30 10 -4)"/><rect x="-2" y="-14" width="4" height="28" rx="2" fill="#4a2f1a"/></g></g>`;
    },
    space(u) {
      const R = rng(21); let st = '';
      for (let i = 0; i < 120; i++) st += `<circle cx="${r1(R() * 1600)}" cy="${r1(R() * 760)}" r="${r1(.7 + R() * 2)}" fill="#fff" ${i % 3 === 0 ? `class="tw" style="animation-delay:-${r1(R() * 4)}s"` : 'opacity=".8"'}/>`;
      let cr = ''; for (let i = 0; i < 12; i++) cr += `<ellipse cx="${r1(60 + R() * 1480)}" cy="${r1(830 + R() * 50)}" rx="${r1(26 + R() * 50)}" ry="${r1(7 + R() * 12)}" fill="#5b5f86" opacity=".7"/>`;
      return `<defs><linearGradient id="s${u}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#070a1f"/><stop offset=".6" stop-color="#241660"/><stop offset="1" stop-color="#5a2a8c"/></linearGradient></defs>
      <rect width="1600" height="900" fill="url(#s${u})"/>${st}
      <g transform="translate(1290 230)"><ellipse rx="146" ry="34" fill="none" stroke="#fcd34d" stroke-width="13" transform="rotate(-18)"/><circle r="80" fill="#f59e0b"/><path d="M-70-34Q0-52 70-34M-78 6Q0-10 78 6M-64 44Q0 30 64 44" stroke="#fbbf24" stroke-width="10" fill="none" opacity=".75"/><ellipse rx="146" ry="34" fill="none" stroke="#fde68a" stroke-width="9" transform="rotate(-18)" stroke-dasharray="230 400" stroke-dashoffset="-60"/></g>
      <g transform="translate(250 190)"><circle r="54" fill="#60a5fa"/><circle cx="-18" cy="-14" r="11" fill="#3b82f6"/><circle cx="20" cy="18" r="14" fill="#3b82f6"/><circle cx="22" cy="-22" r="7" fill="#3b82f6"/></g>
      <g transform="translate(760 150)"><circle r="30" fill="#fde68a"/><circle cx="-8" cy="-6" r="6" fill="#fcd34d"/><circle cx="9" cy="8" r="8" fill="#fcd34d"/></g>
      <g transform="translate(1000 420) rotate(38)"><g class="rk"><path d="M0-70Q34-30 30 30H-30Q-34-30 0-70z" fill="#f8fafc"/><circle cy="-14" r="13" fill="#38bdf8" stroke="#94a3b8" stroke-width="4"/><path d="M-30 12L-56 46 -30 36zM30 12L56 46 30 36z" fill="#ef4444"/><path class="fl" d="M-16 30Q0 94 16 30z" fill="#fb923c"/></g></g>
      <g transform="translate(430 480)"><g class="ufo"><ellipse cy="10" rx="70" ry="20" fill="#94a3b8"/><path d="M-36 6Q0-50 36 6z" fill="#7dd3fc" opacity=".9"/><circle cx="-40" cy="14" r="5" fill="#fde047"/><circle cx="0" cy="18" r="5" fill="#fde047"/><circle cx="40" cy="14" r="5" fill="#fde047"/></g></g>
      <path d="M0 780Q400 700 840 770T1600 740V900H0z" fill="#8c90b0"/><path d="M0 850Q500 790 1000 845T1600 820V900H0z" fill="#6f7396"/>${cr}`;
    },
    sea(u) {
      const R = rng(33); let bub = '', sw = '';
      for (let i = 0; i < 26; i++) { const x = r1(R() * 1600), y = r1(300 + R() * 560), r = r1(5 + R() * 13); bub += `<circle class="bub" cx="${x}" cy="${y}" r="${r}" fill="rgba(255,255,255,.18)" stroke="#fff" stroke-width="2" style="animation-delay:-${r1(R() * 9)}s;animation-duration:${r1(6 + R() * 6)}s"/>` }
      for (let i = 0; i < 9; i++) { const x = 60 + i * 190 + R() * 60, h = 0.7 + R() * .8; sw += `<g transform="translate(${r1(x)} 850) scale(${r1(h)})"><path class="sw" style="animation-delay:-${r1(R() * 3)}s" d="M0 0q-22-44 0-88t0-88q-18-40 0-80" stroke="${['#1fa35a', '#2bbf6a', '#14864b'][i % 3]}" stroke-width="15" fill="none" stroke-linecap="round"/></g>` }
      const fish = (x, y, c, d, s) => `<g transform="translate(${x} ${y}) scale(${s})"><g class="fish" style="animation-duration:${d}s"><ellipse rx="44" ry="26" fill="${c}"/><path d="M38 0L72-24V24z" fill="${c}"/><path d="M-4-26Q10-48 24-24z" fill="${c}" opacity=".8"/><circle cx="-22" cy="-6" r="7" fill="#fff"/><circle cx="-24" cy="-6" r="3.5" fill="#1f2937"/><path d="M6-22v44" stroke="#fff" stroke-width="6" opacity=".5"/></g></g>`;
      return `<defs><linearGradient id="w${u}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8be3ff"/><stop offset=".55" stop-color="#2f9be0"/><stop offset="1" stop-color="#0c4a9a"/></linearGradient></defs>
      <rect width="1600" height="900" fill="url(#w${u})"/>
      <g fill="#fff" opacity=".13"><path d="M200 0L330 0 90 900H-80z"/><path d="M620 0L720 0 560 900H420z"/><path d="M1020 0L1150 0 1010 900H820z"/><path d="M1400 0L1500 0 1480 900H1300z"/></g>${bub}
      <g transform="translate(1250 270)"><g class="jelly"><path d="M-46 0Q-46-56 0-56T46 0z" fill="#f9a8d4"/><path d="M-30 0v54M-10 0v70M10 0v50M30 0v64" stroke="#f9a8d4" stroke-width="6" stroke-linecap="round" fill="none"/><circle cx="-16" cy="-18" r="5" fill="#fff" opacity=".7"/></g></g>
      ${fish(320, 360, '#ff9f43', 14, 1.1)}${fish(980, 520, '#fde047', 18, .8)}${fish(620, 250, '#f472b6', 22, .9)}
      <path d="M0 830Q400 790 820 830T1600 815V900H0z" fill="#f2d08a"/>${sw}<path d="M0 870Q500 840 1000 870T1600 860V900H0z" fill="#e0b867"/>
      <g transform="translate(180 855)"><path d="M0-34L10-10 36-8 16 8 22 34 0 20-22 34-16 8-36-8-10-10z" fill="#fb7185"/></g>
      <g transform="translate(1380 850) scale(1.2)"><path d="M0 0v-60M0-30l-26-30M0-20l24-26M-26-60v-26M24-46v-22" stroke="#fb923c" stroke-width="12" stroke-linecap="round" fill="none"/></g>
      <g transform="translate(900 872)"><path d="M-30 0Q-30-40 0-40T30 0z" fill="#fbcfe8"/><path d="M-20 0v-30M0 0v-38M20 0v-30" stroke="#f9a8d4" stroke-width="4"/></g>`;
    },
    forest(u) {
      let back = '', mid = '', mush = '', ff = ''; const R = rng(5);
      for (let i = 0; i < 12; i++) back += pine(80 + i * 140 + R() * 40, 610 + R() * 30, .8 + R() * .4, '#2f8f5b');
      for (let i = 0; i < 9; i++) mid += pine(30 + i * 190 + R() * 60, 740 + R() * 20, 1.1 + R() * .5, '#3fae6b');
      for (let i = 0; i < 7; i++) { const x = 100 + i * 230 + R() * 70, y = 830 + R() * 40, s = .8 + R() * .7; mush += `<g transform="translate(${r1(x)} ${r1(y)}) scale(${r1(s)})"><rect x="-12" y="-4" width="24" height="34" rx="9" fill="#fde9c9"/><path d="M-42 0Q-40-50 0-52T42 0z" fill="#ef4444"/><circle cx="-18" cy="-24" r="7" fill="#fff"/><circle cx="12" cy="-34" r="6" fill="#fff"/><circle cx="22" cy="-14" r="5" fill="#fff"/></g>` }
      for (let i = 0; i < 22; i++) ff += `<circle class="tw" cx="${r1(R() * 1600)}" cy="${r1(300 + R() * 520)}" r="${r1(3 + R() * 3)}" fill="#fde047" style="animation-delay:-${r1(R() * 4)}s"/>`;
      return `<defs><linearGradient id="f${u}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#bff3d0"/><stop offset="1" stop-color="#f3fddd"/></linearGradient></defs>
      <rect width="1600" height="900" fill="url(#f${u})"/>
      <g fill="#fffbd0" opacity=".4"><path d="M120 0L330 0 640 900H300z"/><path d="M520 0L650 0 1000 900H740z"/><path d="M880 0L960 0 1320 900H1100z"/></g>
      ${cloud(1240, 140, 1, 100, '#fff', .9)}${cloud(300, 120, .8, 80, '#fff', .9)}
      <path d="M0 640Q400 580 800 640T1600 620V900H0z" fill="#6fcf97"/>${back}
      <path d="M0 740Q420 680 840 740T1600 720V900H0z" fill="#4fbf7e"/>${mid}
      <path d="M0 830Q500 780 1000 830T1600 810V900H0z" fill="#33a864"/>${mush}${ff}`;
    },
    winter(u) {
      const R = rng(11); let sf = '';
      for (let i = 0; i < 46; i++) sf += `<circle class="sf" cx="${r1(R() * 1600)}" cy="-20" r="${r1(2.5 + R() * 4)}" fill="#fff" style="animation-duration:${r1(8 + R() * 9)}s;animation-delay:-${r1(R() * 14)}s"/>`;
      return `<defs><linearGradient id="t${u}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9fd3ff"/><stop offset="1" stop-color="#eef8ff"/></linearGradient></defs>
      <rect width="1600" height="900" fill="url(#t${u})"/>
      <circle cx="1320" cy="150" r="90" fill="#fff" opacity=".35"/><circle cx="1320" cy="150" r="56" fill="#fff7c9"/>
      ${cloud(300, 140, 1.2, 100, '#fff', .95)}${cloud(780, 100, .9, 120, '#fff', .9)}${cloud(1000, 280, 1.1, 90, '#fff', .9)}
      <path d="M0 660Q400 580 820 650T1600 620V900H0z" fill="#e6f2ff"/>
      ${pine(160, 690, 1.1, '#2b7a5b', 1)}${pine(330, 670, .8, '#2b7a5b', 1)}${pine(1360, 680, 1.2, '#2b7a5b', 1)}${pine(1210, 690, .8, '#2b7a5b', 1)}
      <path d="M0 740Q460 670 900 740T1600 720V900H0z" fill="#f7fbff"/>
      <g transform="translate(260 760)"><circle cy="0" r="62" fill="#fff" stroke="#d6e8fa" stroke-width="3"/><circle cy="-84" r="46" fill="#fff" stroke="#d6e8fa" stroke-width="3"/><circle cx="-14" cy="-92" r="5" fill="#1f2937"/><circle cx="14" cy="-92" r="5" fill="#1f2937"/><path d="M0-82l32 8-32 8z" fill="#fb923c"/><path d="M-46-52Q0-34 46-52V-40Q0-22-46-40z" fill="#ef4444"/><rect x="-30" y="-142" width="60" height="30" rx="4" fill="#334155"/><rect x="-44" y="-116" width="88" height="10" rx="4" fill="#334155"/><circle cy="-8" r="5" fill="#1f2937"/><circle cy="14" r="5" fill="#1f2937"/></g>
      <path d="M0 830Q500 780 1000 830T1600 810V900H0z" fill="#fff"/>${sf}`;
    },
    candy(u) {
      const R = rng(3); let sp = '', lol = '', fr = '';
      for (let i = 0; i < 70; i++) sp += `<rect x="${r1(R() * 1600)}" y="${r1(R() * 700)}" width="14" height="5" rx="2.5" fill="${['#ff6b9d', '#ffd23f', '#6bcf63', '#4dabf7', '#9775fa', '#ff9f43'][i % 6]}" transform="rotate(${r1(R() * 180)} 0 0)" opacity=".8"/>`;
      for (let i = 0; i < 6; i++) { const x = 120 + i * 270 + R() * 50, y = 600 + R() * 40, c = ['#ff6b9d', '#4dabf7', '#ffd23f', '#9775fa', '#51cf66', '#ff922b'][i];
        let spiral = 'M0 0'; for (let a = 0; a < 18; a += .4) spiral += `L${r1(Math.cos(a) * a * 2.7)} ${r1(Math.sin(a) * a * 2.7)}`;
        lol += `<g transform="translate(${r1(x)} ${r1(y)})"><rect x="-5" y="20" width="10" height="170" rx="5" fill="#fff" stroke="#e5d9f2" stroke-width="2"/><circle r="52" fill="${c}"/><path d="${spiral}" stroke="#fff" stroke-width="7" fill="none" stroke-linecap="round" transform="translate(0 0) scale(.95)"/></g>` }
      for (let x = 0; x < 1600; x += 80) fr += `<path d="M${x} 760q40 46 80 0" fill="#fff"/>`;
      const cane = (x, y, h) => `<g transform="translate(${x} ${y})"><path d="M0 0V-${h}a32 32 0 0 1 64 0" stroke="#fff" stroke-width="24" fill="none" stroke-linecap="round"/><path d="M0 0V-${h}a32 32 0 0 1 64 0" stroke="#ef4444" stroke-width="24" fill="none" stroke-dasharray="18 18"/></g>`;
      return `<defs><linearGradient id="c${u}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffd0ee"/><stop offset=".6" stop-color="#fff0fa"/><stop offset="1" stop-color="#e2d7ff"/></linearGradient></defs>
      <rect width="1600" height="900" fill="url(#c${u})"/>${sp}
      ${cloud(280, 150, 1.3, 100, '#ffc2e6', .95)}${cloud(900, 110, 1, 120, '#c9e8ff', .95)}${cloud(1300, 240, 1.2, 90, '#ffc2e6', .95)}
      <path d="M0 700Q360 620 760 690T1600 650V900H0z" fill="#ffb3dc"/>${lol}
      <path d="M0 760Q440 690 880 760T1600 740V900H0z" fill="#ff8ec9"/>${fr}
      ${cane(80, 800, 90)}${cane(1440, 800, 100)}
      <g transform="translate(700 820)"><path d="M-36 0L-28 50H28L36 0z" fill="#fcd34d"/><path d="M-40 0Q-44-24-14-26Q0-48 18-28Q44-26 40 0z" fill="#fff"/><circle cy="-34" r="9" fill="#ef4444"/></g>
      <path d="M0 850Q500 800 1000 850T1600 835V900H0z" fill="#ff6fb5"/>`;
    }
  };
  const ART = { bg: Object.keys(SCENES), frame: ['gold', 'rainbow', 'stars', 'hearts'], hat: Object.keys(HATS) };

  function sceneSvg(id, o = {}) {
    const u = ++N;
    return `<svg class="scn ${o.cls || ''}" viewBox="${o.view || '0 0 1600 900'}" preserveAspectRatio="${o.par || 'xMidYMax slice'}" aria-hidden="true">${(SCENES[id] || SCENES.meadow)(u)}${o.mascot !== undefined ? `<g transform="translate(${o.mx || 868} ${o.my || 536}) scale(${o.ms || .95})">${mascotG(o.mascot, { mood: o.mood })}</g>` : ''}</svg>`;
  }
  function applyScene(id) {
    let el = document.getElementById('scene');
    if (!el) { el = document.createElement('div'); el.id = 'scene'; document.body.prepend(el) }
    if (el.dataset.s !== id) { el.dataset.s = id; el.innerHTML = sceneSvg(id) }
    el.classList.remove('hide');
  }
  const clearScene = () => { const el = document.getElementById('scene'); if (el) { el.classList.add('hide') } };

  /* ---------- рамки аватарок ---------- */
  function ringUrl(shape, c1, c2) {
    const pts = Array.from({ length: 10 }, (_, i) => { const a = i / 10 * Math.PI * 2, x = 50 + Math.cos(a) * 49, y = 50 + Math.sin(a) * 49;
      return shape === 'star' ? `<path d="M0-9L2.6-3 9-2.6 4 1.8 5.6 8 0 4.6-5.6 8-4 1.8-9-2.6-2.6-3z" transform="translate(${r1(x)} ${r1(y)}) rotate(${i * 36})" fill="${i % 2 ? c1 : c2}"/>`
        : `<path d="M0 7C-12-2-7-11 0-5 7-11 12-2 0 7z" transform="translate(${r1(x)} ${r1(y)}) scale(1.1)" fill="${i % 2 ? c1 : c2}"/>` }).join('');
    return `url("data:image/svg+xml;utf8,${encodeURIComponent(`<svg xmlns='http://www.w3.org/2000/svg' viewBox='-6 -6 112 112'>${pts}</svg>`)}")`;
  }
  (function css() {
    const s = document.createElement('style');
    s.textContent = `.fr-stars::after{background-image:${ringUrl('star', '#fde047', '#fff')}}.fr-hearts::after{background-image:${ringUrl('heart', '#fff', '#ffe4ef')}}`;
    document.head.append(s);
  })();
  function avatar(url, name, color, cls, frame) {
    const inner = `<span class="av ${cls || ''}" style="${color ? `background:${color}` : ''}">${url ? `<img src="${esc(url)}" alt="">` : esc((name || '?')[0].toUpperCase())}</span>`;
    return frame && ART.frame.includes(frame) ? `<span class="fw fr-${frame}">${inner}</span>` : inner;
  }

  /* ---------- превью для магазина ---------- */
  function thumb(kind, art, o = {}) {
    if (kind === 'bg') return sceneSvg(art, { view: '0 330 1600 570', par: 'xMidYMid slice', cls: 'thumb' });
    if (kind === 'frame') return avatar(o.url, o.name || '?', o.color || '#B07F5E', 'l', art);
    return mascotSvg(art, { view: '20 -64 260 270', cls: 'thumb-hat' });
  }
  function confetti(n = 46) {
    const box = document.createElement('div'); box.className = 'confetti';
    for (let i = 0; i < n; i++) { const p = document.createElement('i'); p.style.cssText = `left:${Math.random() * 100}%;background:${['#ff6b9d', '#ffd23f', '#51cf66', '#4dabf7', '#9775fa', '#ff922b'][i % 6]};animation-delay:${Math.random() * .5}s;animation-duration:${1.6 + Math.random() * 1.2}s;transform:rotate(${Math.random() * 360}deg);border-radius:${i % 3 ? '2px' : '50%'}`; box.append(p) }
    document.body.append(box); setTimeout(() => box.remove(), 3200);
  }
  return { mascotSvg, mascotG, sceneSvg, applyScene, clearScene, avatar, thumb, confetti, ART };
})();
