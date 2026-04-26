// Design tokens — Sıcak, ev odaklı palet
// Tek HTML içinde global olarak kullanılır.

window.T = window.EVI_TOKENS = {
  // Colors — warm, family
  cream:      '#FAF7F2',
  paper:      '#F2EDE3',
  paperDeep:  '#E8E0D0',
  ink:        '#1A1A1A',
  inkSoft:    '#2B2622',
  inkMute:    '#7A6F65',
  inkFaint:   '#B5A99B',
  line:       '#E5DCC9',
  lineSoft:   '#EFE8DA',

  terracotta: '#C4593C',
  terraDeep:  '#A4452C',
  terraSoft:  '#E8B5A0',
  terraTint:  '#F6E4D8',

  forest:     '#3D5A4A',
  forestDeep: '#2A4234',
  forestSoft: '#9BB3A4',
  forestTint: '#DCE7DF',

  butter:     '#E8C77A',
  butterTint: '#F6E9C0',

  alert:      '#A4452C',
  ok:         '#3D5A4A',

  // Radii
  rSm: '8px', rMd: '14px', rLg: '20px', rXl: '28px', rPill: '999px',

  // Shadows (warm, soft)
  shadowSm: '0 1px 2px rgba(60,40,20,0.06), 0 2px 6px rgba(60,40,20,0.04)',
  shadowMd: '0 2px 6px rgba(60,40,20,0.08), 0 8px 24px rgba(60,40,20,0.06)',
  shadowLg: '0 8px 30px rgba(60,40,20,0.12), 0 24px 60px rgba(60,40,20,0.08)',
};

// Global style injection
if (!document.getElementById('evi-fonts')) {
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = 'https://fonts.googleapis.com/css2?family=Geist:wght@300;400;500;600;700&family=Geist+Mono:wght@400;500&display=swap';
  document.head.appendChild(link);

  const s = document.createElement('style');
  s.id = 'evi-fonts';
  s.textContent = `
    /* Modern: Geist for everything */
    .ff-serif { font-family: 'Geist', -apple-system, system-ui, sans-serif; letter-spacing: -0.035em; font-weight: 500; }
    .ff-sans  { font-family: 'Geist', -apple-system, system-ui, sans-serif; letter-spacing: -0.01em; }
    .ff-mono  { font-family: 'Geist Mono', ui-monospace, monospace; }
    .num      { font-feature-settings: 'tnum' 1, 'ss01' 1; font-variant-numeric: tabular-nums; }

    /* Hide scrollbars inside artboards */
    .scroll-hide::-webkit-scrollbar { display: none; }
    .scroll-hide { scrollbar-width: none; }

    /* Subtle grain (used on hero panels) */
    .grain {
      position: relative;
    }
    .grain::after {
      content: ''; position: absolute; inset: 0; pointer-events: none;
      background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='160' height='160'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2' stitchTiles='stitch'/><feColorMatrix values='0 0 0 0 0.4  0 0 0 0 0.3  0 0 0 0 0.2  0 0 0 0.6 0'/></filter><rect width='100%' height='100%' filter='url(%23n)' opacity='0.5'/></svg>");
      mix-blend-mode: multiply;
      opacity: 0.06;
    }

    @keyframes evi-pulse {
      0%, 100% { transform: scale(1); opacity: 0.7; }
      50% { transform: scale(1.4); opacity: 0; }
    }
    @keyframes evi-wave {
      0%, 100% { transform: scaleY(0.3); }
      50% { transform: scaleY(1); }
    }
    @keyframes evi-shimmer {
      0% { background-position: -200% 0; }
      100% { background-position: 200% 0; }
    }
  `;
  document.head.appendChild(s);
}
