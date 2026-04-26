// Atomic UI parts: ikonlar, para formatı, küçük chip/badge
// Hepsi sıcak/aile tonunda, minimal stroke ikonlar.

// ─────── Para formatı ───────
const Tp = window.EVI_TOKENS;

function formatTL(n, opts = {}) {
  const { sign = false, decimals = 0 } = opts;
  const abs = Math.abs(n);
  const parts = abs.toLocaleString('tr-TR', { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
  const s = n < 0 ? '−' : sign ? '+' : '';
  return `${s}${parts}`;
}

// ─────── İkon (stroke, 24×24, currentColor) ───────
function Icon({ name, size = 22, stroke = 1.6, color = 'currentColor', style }) {
  const p = { width: size, height: size, viewBox: '0 0 24 24', fill: 'none',
              stroke: color, strokeWidth: stroke, strokeLinecap: 'round', strokeLinejoin: 'round',
              style };
  switch (name) {
    case 'home':   return <svg {...p}><path d="M3 11.5L12 4l9 7.5"/><path d="M5 10.5V20h14V10.5"/><path d="M10 20v-5h4v5"/></svg>;
    case 'list':   return <svg {...p}><path d="M4 7h16M4 12h16M4 17h10"/></svg>;
    case 'plus':   return <svg {...p}><path d="M12 5v14M5 12h14"/></svg>;
    case 'chart':  return <svg {...p}><path d="M4 20V10M10 20V4M16 20v-6M22 20H2"/></svg>;
    case 'people': return <svg {...p}><circle cx="9" cy="9" r="3.2"/><path d="M3 19c0-3 2.7-5 6-5s6 2 6 5"/><circle cx="17" cy="8" r="2.5"/><path d="M15 14c3 0 6 1.5 6 4"/></svg>;
    case 'mic':    return <svg {...p}><rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0"/><path d="M12 18v3"/></svg>;
    case 'camera': return <svg {...p}><path d="M3 8h3l2-2.5h8L18 8h3v11H3z"/><circle cx="12" cy="13" r="3.5"/></svg>;
    case 'pen':    return <svg {...p}><path d="M4 20l4-1L20 7l-3-3L5 16l-1 4z"/></svg>;
    case 'sparkle':return <svg {...p}><path d="M12 3v6M12 15v6M3 12h6M15 12h6M6 6l3 3M15 15l3 3M6 18l3-3M15 9l3-3"/></svg>;
    case 'check':  return <svg {...p}><path d="M5 12.5l4 4 10-10"/></svg>;
    case 'x':      return <svg {...p}><path d="M5 5l14 14M19 5L5 19"/></svg>;
    case 'arrow-right': return <svg {...p}><path d="M5 12h14M13 6l6 6-6 6"/></svg>;
    case 'arrow-left':  return <svg {...p}><path d="M19 12H5M11 18l-6-6 6-6"/></svg>;
    case 'arrow-up':    return <svg {...p}><path d="M12 19V5M6 11l6-6 6 6"/></svg>;
    case 'arrow-down':  return <svg {...p}><path d="M12 5v14M6 13l6 6 6-6"/></svg>;
    case 'chevron-right':return <svg {...p}><path d="M9 6l6 6-6 6"/></svg>;
    case 'chevron-down':return <svg {...p}><path d="M6 9l6 6 6-6"/></svg>;
    case 'settings':return <svg {...p}><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2"/></svg>;
    case 'bell':   return <svg {...p}><path d="M6 9a6 6 0 0 1 12 0c0 4 1.5 6 1.5 6h-15S6 13 6 9z"/><path d="M10 19a2 2 0 0 0 4 0"/></svg>;
    case 'search': return <svg {...p}><circle cx="11" cy="11" r="6"/><path d="M16 16l4 4"/></svg>;
    case 'filter': return <svg {...p}><path d="M3 5h18l-7 9v6l-4-2v-4z"/></svg>;
    case 'wallet': return <svg {...p}><rect x="3" y="6" width="18" height="13" rx="2"/><path d="M3 10h18"/><circle cx="16" cy="14.5" r="1"/></svg>;
    case 'pie':    return <svg {...p}><path d="M12 3v9h9a9 9 0 1 1-9-9z"/><path d="M14 3a8 8 0 0 1 7 7h-7z"/></svg>;
    case 'calendar':return <svg {...p}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></svg>;
    case 'tag':    return <svg {...p}><path d="M3 12V4h8l10 10-8 8z"/><circle cx="8" cy="8" r="1.5"/></svg>;
    case 'cart':   return <svg {...p}><path d="M3 4h2l2.5 11h11l2-8H7"/><circle cx="9" cy="20" r="1.3"/><circle cx="18" cy="20" r="1.3"/></svg>;
    case 'cup':    return <svg {...p}><path d="M5 8h12v6a4 4 0 0 1-4 4H9a4 4 0 0 1-4-4z"/><path d="M17 9h2a2 2 0 0 1 0 4h-2"/><path d="M8 4l1 2M12 4l1 2"/></svg>;
    case 'fuel':   return <svg {...p}><rect x="4" y="4" width="10" height="16" rx="1"/><path d="M14 9h2.5a2 2 0 0 1 2 2v6a1.5 1.5 0 0 0 3 0V8l-2-2"/></svg>;
    case 'bolt':   return <svg {...p}><path d="M13 3L5 14h6l-2 7 8-11h-6z"/></svg>;
    case 'house-heart':return <svg {...p}><path d="M3 11l9-7 9 7v9H3z"/><path d="M9 14c0-1.5 1.5-2.5 3-1 1.5-1.5 3-.5 3 1 0 2-3 4-3 4s-3-2-3-4z"/></svg>;
    case 'play':   return <svg {...p}><path d="M7 4l13 8-13 8z"/></svg>;
    case 'pause':  return <svg {...p}><rect x="6" y="5" width="4" height="14"/><rect x="14" y="5" width="4" height="14"/></svg>;
    case 'image':  return <svg {...p}><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M21 16l-5-5-9 9"/></svg>;
    case 'flash':  return <svg {...p}><path d="M13 3L5 14h6l-2 7 8-11h-6z"/></svg>;
    case 'rotate': return <svg {...p}><path d="M3 12a9 9 0 0 1 16-5l2-2v6h-6l2-2"/><path d="M21 12a9 9 0 0 1-16 5l-2 2v-6h6l-2 2"/></svg>;
    case 'trash':  return <svg {...p}><path d="M4 7h16M9 7V4h6v3M6 7v13h12V7"/></svg>;
    case 'refresh':return <svg {...p}><path d="M3 12a9 9 0 0 1 15.5-6L21 4"/><path d="M21 4v5h-5"/><path d="M21 12a9 9 0 0 1-15.5 6L3 20"/><path d="M3 20v-5h5"/></svg>;
    case 'star':   return <svg {...p}><path d="M12 3l3 6 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1z"/></svg>;
    case 'leaf':   return <svg {...p}><path d="M5 19c0-9 6-15 15-15 0 9-6 15-15 15z"/><path d="M5 19l7-7"/></svg>;
    case 'gift':   return <svg {...p}><rect x="3" y="9" width="18" height="11" rx="1"/><path d="M3 13h18M12 9v11M8 9c-2 0-3-1-3-2.5S6 4 8 4c2 0 4 5 4 5s2-5 4-5c2 0 3 1 3 2.5S18 9 16 9"/></svg>;
    case 'baby':   return <svg {...p}><circle cx="12" cy="9" r="4"/><path d="M9 9h.01M15 9h.01M10 12c.5.5 1 .8 2 .8s1.5-.3 2-.8"/><path d="M5 21c1-4 4-6 7-6s6 2 7 6"/></svg>;
    case 'spark2': return <svg {...p}><path d="M12 3l1.8 5.7L19 10l-5.2 1.3L12 17l-1.8-5.7L5 10l5.2-1.3z"/><path d="M19 4v3M21 5h-3M5 18v3M7 19H4"/></svg>;
    case 'doc':    return <svg {...p}><path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5M9 13h6M9 17h4"/></svg>;
    case 'send':   return <svg {...p}><path d="M21 4L3 11l7 3 3 7z"/><path d="M21 4l-11 11"/></svg>;
    case 'lock':   return <svg {...p}><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>;
    case 'globe':  return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></svg>;
    case 'phone':  return <svg {...p}><rect x="6" y="2" width="12" height="20" rx="2"/><path d="M10 18h4"/></svg>;
    case 'web':    return <svg {...p}><rect x="2" y="4" width="20" height="14" rx="2"/><path d="M2 9h20M5 6.5h.01M8 6.5h.01M11 6.5h.01"/></svg>;
    case 'hand':   return <svg {...p}><path d="M9 11V5a1.5 1.5 0 0 1 3 0v6"/><path d="M12 11V4.5a1.5 1.5 0 0 1 3 0V11"/><path d="M15 11V6a1.5 1.5 0 0 1 3 0v9c0 3.5-2.5 6-6 6s-6-2-7-5l-2-4c-.5-1 .5-2 1.5-1.5L7 12V8a1.5 1.5 0 0 1 3 0v3"/></svg>;
    case 'menu-dots': return <svg {...p}><circle cx="5" cy="12" r="1.2"/><circle cx="12" cy="12" r="1.2"/><circle cx="19" cy="12" r="1.2"/></svg>;
    case 'food':   return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>;
    default: return <svg {...p}><circle cx="12" cy="12" r="9"/></svg>;
  }
}

// ─────── Avatar (initials over warm tint) ───────
function Avatar({ name, size = 32, color, ring = false }) {
  const c = color || Tp.terraSoft;
  const initials = name.split(' ').map(s => s[0]).slice(0,2).join('').toUpperCase();
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: c, color: Tp.inkSoft,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: "'DM Sans', sans-serif", fontWeight: 600, fontSize: size * 0.42,
      flexShrink: 0,
      boxShadow: ring ? `0 0 0 2px ${Tp.cream}, 0 0 0 4px ${c}` : 'none',
    }}>{initials}</div>
  );
}

// ─────── Aile üyeleri (sabit veri) ───────
window.EVI_FAMILY = [
  { id: 'a', name: 'Ayşe',   color: '#E8B5A0', role: 'Anne' },
  { id: 'm', name: 'Mehmet', color: '#9BB3A4', role: 'Baba' },
  { id: 'z', name: 'Zeynep', color: '#F0D396', role: 'Kız' },
  { id: 'k', name: 'Kerem',  color: '#C9B8E0', role: 'Oğul' },
];

// ─────── Kategoriler ───────
window.EVI_CATEGORIES = [
  { id: 'market',    label: 'Market',     icon: 'cart',     color: '#C4593C', tint: '#F6E4D8' },
  { id: 'fatura',    label: 'Faturalar',  icon: 'bolt',     color: '#3D5A4A', tint: '#DCE7DF' },
  { id: 'ulasim',    label: 'Ulaşım',     icon: 'fuel',     color: '#7A6F65', tint: '#EFE8DA' },
  { id: 'yemek',     label: 'Yemek',      icon: 'cup',      color: '#A4452C', tint: '#F0D9CC' },
  { id: 'cocuk',     label: 'Çocuklar',   icon: 'baby',     color: '#C9933A', tint: '#F6E9C0' },
  { id: 'saglik',    label: 'Sağlık',     icon: 'leaf',     color: '#3D5A4A', tint: '#DCE7DF' },
  { id: 'eglence',   label: 'Eğlence',    icon: 'gift',     color: '#8B5A8B', tint: '#EBDBEB' },
  { id: 'kira',      label: 'Kira',       icon: 'house-heart', color: '#1A1A1A', tint: '#E8E0D0' },
  { id: 'maas',      label: 'Maaş',       icon: 'wallet',   color: '#3D5A4A', tint: '#DCE7DF', income: true },
  { id: 'ek',        label: 'Ek Gelir',   icon: 'spark2',   color: '#C9933A', tint: '#F6E9C0', income: true },
];

window.EVI_CAT_BY_ID = Object.fromEntries(window.EVI_CATEGORIES.map(c => [c.id, c]));

// ─────── Kategori chip ───────
function CatChip({ id, size = 36 }) {
  const c = window.EVI_CAT_BY_ID[id];
  if (!c) return null;
  return (
    <div style={{
      width: size, height: size, borderRadius: 12, background: c.tint,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: c.color, flexShrink: 0,
    }}>
      <Icon name={c.icon} size={size * 0.55} stroke={1.7}/>
    </div>
  );
}

// ─────── Sample transactions ───────
window.EVI_TRANSACTIONS = [
  { id: 1, type: 'expense', amount: 847.50, cat: 'market',  who: 'a', merchant: 'Migros',         note: 'Haftalık alışveriş', date: 'Bugün',   time: '14:32', source: 'photo' },
  { id: 2, type: 'expense', amount: 65.00,  cat: 'yemek',   who: 'm', merchant: 'Espressolab',    note: '2 kahve, 1 sandviç', date: 'Bugün',   time: '09:15', source: 'voice' },
  { id: 3, type: 'expense', amount: 320.00, cat: 'ulasim',  who: 'm', merchant: 'Shell',          note: 'Benzin',             date: 'Dün',     time: '18:40', source: 'voice' },
  { id: 4, type: 'income',  amount: 28500,  cat: 'maas',    who: 'm', merchant: 'Şirket maaşı',   note: 'Nisan maaşı',        date: 'Dün',     time: '09:00', source: 'auto' },
  { id: 5, type: 'expense', amount: 1250,   cat: 'fatura',  who: 'a', merchant: 'Boğaziçi El.',   note: 'Elektrik',           date: '2 gün',   time: '11:00', source: 'photo' },
  { id: 6, type: 'expense', amount: 175,    cat: 'cocuk',   who: 'a', merchant: 'Toyzz Shop',     note: 'Zeynep doğum günü',  date: '3 gün',   time: '16:20', source: 'text' },
  { id: 7, type: 'expense', amount: 89.90,  cat: 'eglence', who: 'k', merchant: 'Spotify',        note: 'Aile aboneliği',     date: '4 gün',   time: '00:00', source: 'auto' },
  { id: 8, type: 'income',  amount: 4200,   cat: 'ek',      who: 'a', merchant: 'Freelance',      note: 'Logo tasarımı',      date: '5 gün',   time: '20:00', source: 'text' },
  { id: 9, type: 'expense', amount: 220,    cat: 'saglik',  who: 'a', merchant: 'Eczane Aile',    note: 'Reçete',             date: '6 gün',   time: '10:15', source: 'photo' },
];

Object.assign(window, { Icon, Avatar, CatChip, formatTL });
