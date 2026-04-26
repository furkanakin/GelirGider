// Ortak ekran iskeleti — iPhone içinde scrollable bir ekran
// Tüm ekranlar 320×680 boyutunda, kendi alt navigasyonuyla.

// Üst başlık satırı (greeting + bildirim)
const Tc = window.EVI_TOKENS;

function ScreenHeader({ title, subtitle, right, onBack }) {
  return (
    <div style={{
      padding: '8px 20px 12px', display: 'flex', alignItems: 'flex-start', gap: 10,
    }}>
      {onBack && (
        <button onClick={onBack} style={{
          width: 36, height: 36, borderRadius: 999, border: 'none',
          background: Tc.paper, color: Tc.inkSoft, display: 'flex',
          alignItems: 'center', justifyContent: 'center', cursor: 'pointer', flexShrink: 0,
        }}>
          <Icon name="arrow-left" size={18}/>
        </button>
      )}
      <div style={{ flex: 1, minWidth: 0 }}>
        {subtitle && <div className="ff-sans" style={{ fontSize: 12, color: Tc.inkMute, fontWeight: 500, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 2 }}>{subtitle}</div>}
        <div className="ff-serif" style={{ fontSize: 28, lineHeight: '32px', color: Tc.ink, fontWeight: 400 }}>{title}</div>
      </div>
      {right}
    </div>
  );
}

// Alt tab bar (5 sekme)
function TabBar({ active = 'home', dark = false }) {
  const items = [
    { id: 'home',   icon: 'house-heart', label: 'Ev' },
    { id: 'list',   icon: 'list',        label: 'İşlemler' },
    { id: 'add',    icon: 'plus',        label: '' },
    { id: 'chart',  icon: 'pie',         label: 'Rapor' },
    { id: 'people', icon: 'people',      label: 'Aile' },
  ];
  const isGlow = !!Tc.isGlow;
  const isDark = !!Tc.isDark;
  const fade = Tc.cream;
  // Bar surface
  const barBg = isGlow
    ? 'linear-gradient(155deg, rgba(34,26,68,0.92), rgba(14,10,26,0.96))'
    : isDark ? Tc.paper : '#fff';
  const barBorder = isGlow
    ? '1px solid rgba(244,241,255,0.08)'
    : `1px solid ${isDark ? Tc.line : Tc.line}`;
  const barShadow = isGlow
    ? '0 8px 24px rgba(0,0,0,0.45), inset 0 1px 0 rgba(255,255,255,0.05)'
    : '0 4px 12px rgba(60,40,20,0.06)';
  const inactiveColor = isGlow ? '#8a83a8' : (isDark ? '#9A9388' : Tc.inkMute);
  const activeColor = isGlow ? '#f4f1ff' : Tc.terracotta;
  const fabBg = isGlow ? 'linear-gradient(135deg, #ff5e7a 0%, #8b5cff 100%)' : Tc.terracotta;
  const fabShadow = isGlow
    ? '0 8px 22px rgba(255,94,122,0.45), 0 3px 10px rgba(139,92,255,0.3), inset 0 1px 0 rgba(255,255,255,0.25)'
    : '0 4px 12px rgba(196,89,60,0.4)';

  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      padding: '10px 12px 28px',
      background: `linear-gradient(180deg, transparent 0%, ${fade} 60%)`,
      pointerEvents: 'none',
    }}>
      <div style={{
        background: barBg, border: barBorder,
        borderRadius: 28, padding: '8px 6px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-around',
        boxShadow: barShadow,
        pointerEvents: 'auto',
      }}>
        {items.map(it => {
          const isActive = it.id === active;
          if (it.id === 'add') {
            return (
              <button key={it.id} style={{
                width: 48, height: 48, borderRadius: 999,
                background: fabBg, border: 'none', color: '#fff',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                cursor: 'pointer', boxShadow: fabShadow,
                marginTop: -16, marginBottom: -4,
              }}>
                <Icon name="plus" size={24} stroke={2}/>
              </button>
            );
          }
          return (
            <button key={it.id} style={{
              flex: 1, padding: '6px 4px', border: 'none', background: 'transparent',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
              color: isActive ? activeColor : inactiveColor,
              cursor: 'pointer',
            }}>
              <Icon name={it.icon} size={22} stroke={isActive ? 2 : 1.6}/>
              <span className="ff-sans" style={{ fontSize: 10, fontWeight: isActive ? 600 : 500 }}>{it.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// Ortak ekran çerçevesi — iPhone IÇINE girer
function Screen({ children, bg, label, withTabBar = true, activeTab = 'home', dark = false, onTabBack }) {
  const isGlow = !!Tc.isGlow;
  const screenBg = bg || (isGlow
    ? 'radial-gradient(ellipse 400px 500px at 30% 10%, rgba(74,26,72,0.45) 0%, transparent 60%), radial-gradient(ellipse 350px 400px at 80% 90%, rgba(42,20,84,0.55) 0%, transparent 55%), #0e0a1a'
    : Tc.cream);
  return (
    <div style={{
      width: '100%', height: '100%', background: screenBg,
      position: 'relative', overflow: 'hidden',
      fontFamily: "'Geist', -apple-system, sans-serif",
      color: Tc.ink,
    }} data-screen-label={label}>
      <div className="scroll-hide" style={{
        position: 'absolute', inset: 0,
        overflowY: 'auto', overflowX: 'hidden',
        paddingTop: 50, // status bar boşluğu
        paddingBottom: withTabBar ? 110 : 24,
      }}>
        {children}
      </div>
      {withTabBar && <TabBar active={activeTab} dark={dark}/>}
    </div>
  );
}

Object.assign(window, { Screen, ScreenHeader, TabBar });
