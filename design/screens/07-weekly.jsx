// 07. Haftalık rapor — büyük rakamlar, hikaye gibi
const T7 = window.EVI_TOKENS;

function WeeklyScreen() {
  // 7 gün bar verisi
  const days = [
    { d: 'P',  v: 240 },
    { d: 'S',  v: 380 },
    { d: 'Ç',  v: 95  },
    { d: 'P',  v: 1250 },
    { d: 'C',  v: 175 },
    { d: 'C',  v: 65  },
    { d: 'P',  v: 912 },
  ];
  const max = Math.max(...days.map(d => d.v));

  return (
    <Screen label="07 Haftalik" activeTab="chart" bg={T7.cream}>
      <ScreenHeader
        subtitle="17 — 23 NİSAN"
        title={<span><span style={{ fontStyle: 'italic' }}>Bu</span> hafta</span>}
        right={
          <button style={{
            width: 36, height: 36, borderRadius: 999, border: 'none',
            background: T7.paper, color: T7.inkSoft, display: 'flex',
            alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          }}>
            <Icon name="calendar" size={18}/>
          </button>
        }
      />

      {/* Hikaye satırı — AI özet */}
      <div style={{ padding: '0 24px 18px' }}>
        <div className="ff-serif" style={{ fontSize: 22, lineHeight: '30px', color: T7.inkSoft }}>
          Bu hafta <span style={{ color: T7.terracotta, fontStyle: 'italic' }}>3.117 ₺</span> harcadınız —
          geçen haftadan <span style={{ color: T7.forest, fontWeight: 500 }}>%14 daha az</span>.
          En yoğun gün <span style={{ background: T7.butterTint, padding: '0 4px', borderRadius: 4 }}>Perşembe</span>'ydi.
        </div>
      </div>

      {/* Bar chart */}
      <div style={{ padding: '0 20px 20px' }}>
        <div style={{
          background: T7.surface || '#fff', border: `1px solid ${T7.line}`, borderRadius: 20,
          padding: '20px 18px',
        }}>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10, height: 140 }}>
            {days.map((d, i) => {
              const h = (d.v / max) * 110;
              const isMax = d.v === max;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                  <div className="num ff-sans" style={{ fontSize: 9, color: isMax ? T7.terracotta : T7.inkFaint, fontWeight: 600, opacity: isMax ? 1 : 0 }}>
                    {d.v >= 1000 ? `${(d.v/1000).toFixed(1)}k` : d.v}
                  </div>
                  <div style={{
                    width: '100%', height: h, borderRadius: 6,
                    background: isMax ? T7.terracotta : T7.terraSoft,
                  }}/>
                  <div className="ff-sans" style={{ fontSize: 11, color: T7.inkMute, fontWeight: 500 }}>{d.d}</div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Top 3 kategori */}
      <div style={{ padding: '0 20px 16px' }}>
        <div className="ff-sans" style={{ fontSize: 11, color: T7.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 10, paddingLeft: 4 }}>
          Hafta yıldızları
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { cat: 'fatura', amount: 1250, pct: 40, count: 1 },
            { cat: 'market', amount: 912, pct: 29, count: 2 },
            { cat: 'ulasim', amount: 320, pct: 10, count: 1 },
          ].map(r => {
            const c = window.EVI_CAT_BY_ID[r.cat];
            return (
              <div key={r.cat} style={{
                background: T7.surface || '#fff', border: `1px solid ${T7.line}`, borderRadius: 14,
                padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12,
              }}>
                <CatChip id={r.cat} size={36}/>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 4 }}>
                    <div className="ff-sans" style={{ fontSize: 14, fontWeight: 500, color: T7.ink }}>{c.label}</div>
                    <div className="num ff-sans" style={{ fontSize: 14, fontWeight: 600, color: T7.ink }}>{formatTL(r.amount)} ₺</div>
                  </div>
                  <div style={{ height: 4, background: T7.lineSoft, borderRadius: 999, overflow: 'hidden' }}>
                    <div style={{ width: `${r.pct}%`, height: '100%', background: c.color, borderRadius: 999 }}/>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Aile katkı */}
      <div style={{ padding: '0 20px 24px' }}>
        <div className="ff-sans" style={{ fontSize: 11, color: T7.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 10, paddingLeft: 4 }}>
          Kim ne kadar harcadı
        </div>
        <div style={{ background: T7.surface || '#fff', border: `1px solid ${T7.line}`, borderRadius: 16, padding: '14px 16px' }}>
          {[
            { id: 'a', amount: 1657, pct: 53 },
            { id: 'm', amount: 1145, pct: 37 },
            { id: 'k', amount: 250, pct: 8 },
            { id: 'z', amount: 65, pct: 2 },
          ].map((p, i) => {
            const who = window.EVI_FAMILY.find(f => f.id === p.id);
            return (
              <div key={p.id} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: i < 3 ? 10 : 0 }}>
                <Avatar name={who.name} size={28} color={who.color}/>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                    <div className="ff-sans" style={{ fontSize: 13, color: T7.ink, fontWeight: 500 }}>{who.name}</div>
                    <div className="num ff-sans" style={{ fontSize: 12, color: T7.inkMute }}>{formatTL(p.amount)} ₺</div>
                  </div>
                  <div style={{ height: 4, background: T7.lineSoft, borderRadius: 999, overflow: 'hidden' }}>
                    <div style={{ width: `${p.pct}%`, height: '100%', background: who.color, borderRadius: 999 }}/>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </Screen>
  );
}

window.WeeklyScreen = WeeklyScreen;
