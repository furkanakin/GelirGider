// 08. Aylık rapor — donut, hikaye, karşılaştırma
const T8 = window.EVI_TOKENS;

function MonthlyScreen() {
  const segments = [
    { cat: 'fatura', amount: 3250, color: '#3D5A4A' },
    { cat: 'market', amount: 2410, color: '#C4593C' },
    { cat: 'ulasim', amount: 980,  color: '#7A6F65' },
    { cat: 'yemek',  amount: 685,  color: '#A4452C' },
    { cat: 'cocuk',  amount: 525,  color: '#C9933A' },
  ];
  const total = segments.reduce((a, b) => a + b.amount, 0);

  // donut paths
  let acc = 0;
  const cx = 100, cy = 100, r = 70, sw = 28;
  const arcs = segments.map(s => {
    const start = acc / total;
    acc += s.amount;
    const end = acc / total;
    const a0 = start * Math.PI * 2 - Math.PI / 2;
    const a1 = end * Math.PI * 2 - Math.PI / 2;
    const x0 = cx + r * Math.cos(a0), y0 = cy + r * Math.sin(a0);
    const x1 = cx + r * Math.cos(a1), y1 = cy + r * Math.sin(a1);
    const large = end - start > 0.5 ? 1 : 0;
    return { d: `M ${x0} ${y0} A ${r} ${r} 0 ${large} 1 ${x1} ${y1}`, color: s.color };
  });

  return (
    <Screen label="08 Aylik" activeTab="chart" bg={T8.cream}>
      <ScreenHeader
        subtitle="NİSAN 2026"
        title={<span>Ay <span style={{ fontStyle: 'italic' }}>özeti</span></span>}
        right={
          <button style={{
            width: 36, height: 36, borderRadius: 999, border: 'none',
            background: T8.paper, color: T8.inkSoft, display: 'flex',
            alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
            fontFamily: "'DM Sans', sans-serif", fontSize: 12, fontWeight: 600,
          }}>
            <Icon name="calendar" size={16}/>
          </button>
        }
      />

      {/* Donut + center */}
      <div style={{ padding: '0 20px 20px', display: 'flex', justifyContent: 'center' }}>
        <div style={{ position: 'relative', width: 200, height: 200 }}>
          <svg width="200" height="200" viewBox="0 0 200 200">
            <circle cx={cx} cy={cy} r={r} fill="none" stroke={T8.lineSoft} strokeWidth={sw}/>
            {arcs.map((a, i) => (
              <path key={i} d={a.d} fill="none" stroke={a.color} strokeWidth={sw} strokeLinecap="butt"/>
            ))}
          </svg>
          <div style={{
            position: 'absolute', inset: 0, display: 'flex',
            flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          }}>
            <div className="ff-sans" style={{ fontSize: 11, color: T8.inkMute, marginBottom: 2 }}>Toplam</div>
            <div className="num ff-serif" style={{ fontSize: 28, color: T8.ink, lineHeight: '32px' }}>{formatTL(total)}</div>
            <div className="ff-sans" style={{ fontSize: 12, color: T8.inkMute }}>₺ harcandı</div>
          </div>
        </div>
      </div>

      {/* Karşılaştırma kartları */}
      <div style={{ padding: '0 20px 16px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <div style={{ background: T8.forestTint, border: `1px solid ${T8.forestSoft}`, borderRadius: 16, padding: '12px 14px' }}>
          <div className="ff-sans" style={{ fontSize: 11, color: T8.forest, fontWeight: 600, letterSpacing: 0.3, marginBottom: 4 }}>NET KAZANÇ</div>
          <div className="num ff-serif" style={{ fontSize: 22, color: T8.forestDeep }}>+{formatTL(24850)}</div>
          <div className="ff-sans" style={{ fontSize: 11, color: T8.forest, marginTop: 2 }}>↑ Mart'tan %12 fazla</div>
        </div>
        <div style={{ background: T8.surface || '#fff', border: `1px solid ${T8.line}`, borderRadius: 16, padding: '12px 14px' }}>
          <div className="ff-sans" style={{ fontSize: 11, color: T8.inkMute, fontWeight: 600, letterSpacing: 0.3, marginBottom: 4 }}>BÜTÇE</div>
          <div className="num ff-serif" style={{ fontSize: 22, color: T8.ink }}>%43</div>
          <div className="ff-sans" style={{ fontSize: 11, color: T8.inkMute, marginTop: 2 }}>kullanıldı · 7 gün kaldı</div>
        </div>
      </div>

      {/* Kategori dağılımı */}
      <div style={{ padding: '0 20px 16px' }}>
        <div className="ff-sans" style={{ fontSize: 11, color: T8.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 10, paddingLeft: 4 }}>
          Nereye gitti
        </div>
        <div style={{ background: T8.surface || '#fff', border: `1px solid ${T8.line}`, borderRadius: 16, padding: '4px 14px' }}>
          {segments.map((s, i) => {
            const c = window.EVI_CAT_BY_ID[s.cat];
            const pct = Math.round((s.amount / total) * 100);
            return (
              <div key={s.cat} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '10px 0',
                borderBottom: i < segments.length - 1 ? `1px solid ${T8.lineSoft}` : 'none',
              }}>
                <div style={{ width: 8, height: 8, borderRadius: 999, background: s.color }}/>
                <div className="ff-sans" style={{ flex: 1, fontSize: 13, color: T8.ink, fontWeight: 500 }}>{c.label}</div>
                <div className="ff-sans" style={{ fontSize: 11, color: T8.inkMute, width: 30, textAlign: 'right' }}>%{pct}</div>
                <div className="num ff-sans" style={{ fontSize: 13, color: T8.ink, fontWeight: 600, width: 70, textAlign: 'right' }}>{formatTL(s.amount)} ₺</div>
              </div>
            );
          })}
        </div>
      </div>

      {/* AI hikaye */}
      <div style={{ padding: '0 20px 24px' }}>
        <div style={{
          background: T8.terracotta, color: '#fff', borderRadius: 18,
          padding: '16px 18px',
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', right: -20, top: -20, width: 100, height: 100, borderRadius: '50%', background: 'rgba(255,255,255,0.08)' }}/>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <Icon name="sparkle" size={14} stroke={2}/>
            <div className="ff-sans" style={{ fontSize: 11, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>Ay hikayesi</div>
          </div>
          <div className="ff-serif" style={{ fontSize: 17, lineHeight: '24px' }}>
            Bu ay <i>düzenli</i> bir aysınız. Kira ve faturalar zamanında, market harcaması son 3 aya göre <b>%18 düştü</b>. Mehmet'in yakıtı geçen ayla aynı.
          </div>
        </div>
      </div>
    </Screen>
  );
}

window.MonthlyScreen = MonthlyScreen;
