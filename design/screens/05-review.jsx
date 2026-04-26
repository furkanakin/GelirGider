// 05. AI analiz / onay — satır satır düzenleme
const T5 = window.EVI_TOKENS;

function ReviewScreen() {
  const lines = [
    { id: 1, label: 'Migros — Haftalık market', amount: 847.50, cat: 'market', who: 'a', confidence: 0.96 },
    { id: 2, label: 'Espressolab — 2 kahve, 1 sandviç', amount: 65.00, cat: 'yemek', who: 'm', confidence: 0.88 },
    { id: 3, label: 'Shell — Benzin', amount: 320.00, cat: 'ulasim', who: 'm', confidence: 0.92 },
  ];

  return (
    <Screen label="05 Onay" activeTab="add" withTabBar={false} bg={T5.cream}>
      <ScreenHeader
        subtitle="AI ÖZET"
        title={<span><span style={{ fontStyle: 'italic' }}>3 işlem</span> hazır</span>}
        onBack={() => {}}
        right={
          <button style={{
            background: T5.forestTint, border: `1px solid ${T5.forestSoft}`, color: T5.forest,
            padding: '6px 12px', borderRadius: 999, fontSize: 12, fontWeight: 600,
            display: 'flex', alignItems: 'center', gap: 4, cursor: 'pointer',
            fontFamily: "'DM Sans', sans-serif",
          }}>
            <Icon name="sparkle" size={12} stroke={2}/> 0:14
          </button>
        }
      />

      <div style={{ padding: '0 20px 12px' }}>
        <div className="ff-sans" style={{ fontSize: 13, color: T5.inkMute, lineHeight: '18px', marginBottom: 4 }}>
          Her satıra dokunarak düzenle. Onayladıktan sonra deftere işlenir.
        </div>
      </div>

      {/* Satırlar */}
      <div style={{ padding: '8px 20px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {lines.map((ln, i) => {
          const cat = window.EVI_CAT_BY_ID[ln.cat];
          const who = window.EVI_FAMILY.find(f => f.id === ln.who);
          const expanded = i === 0;
          return (
            <div key={ln.id} style={{
              background: T5.surface || '#fff', border: expanded ? `1.5px solid ${T5.terracotta}` : `1px solid ${T5.line}`,
              borderRadius: 18, overflow: 'hidden',
              boxShadow: expanded ? '0 4px 16px rgba(196,89,60,0.12)' : 'none',
            }}>
              <div style={{ padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12 }}>
                <CatChip id={ln.cat} size={40}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="ff-sans" style={{ fontSize: 14, fontWeight: 500, color: T5.ink, marginBottom: 2 }}>{ln.label}</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <div style={{ background: cat.tint, color: cat.color, padding: '1px 7px', borderRadius: 999, fontSize: 10, fontWeight: 600 }}>{cat.label}</div>
                    <span style={{ fontSize: 10, color: T5.inkMute }}>·</span>
                    <Avatar name={who.name} size={14} color={who.color}/>
                    <div className="ff-sans" style={{ fontSize: 10, color: T5.inkMute }}>{who.name}</div>
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div className="num ff-serif" style={{ fontSize: 20, fontWeight: 400, color: T5.ink }}>−{formatTL(ln.amount, { decimals: 2 })}</div>
                  <div className="ff-sans" style={{ fontSize: 10, color: T5.inkMute }}>₺ · %{Math.round(ln.confidence * 100)}</div>
                </div>
              </div>

              {expanded && (
                <div style={{ borderTop: `1px solid ${T5.lineSoft}`, padding: '12px 14px', background: T5.paper }}>
                  <div className="ff-sans" style={{ fontSize: 11, color: T5.inkMute, fontWeight: 600, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 8 }}>Düzenle</div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 8 }}>
                    <div style={{ background: T5.surface || '#fff', border: `1px solid ${T5.line}`, borderRadius: 10, padding: '8px 10px' }}>
                      <div className="ff-sans" style={{ fontSize: 10, color: T5.inkMute, marginBottom: 2 }}>Kategori</div>
                      <div className="ff-sans" style={{ fontSize: 13, color: T5.ink, fontWeight: 500, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        Market <Icon name="chevron-down" size={14} color={T5.inkMute}/>
                      </div>
                    </div>
                    <div style={{ background: T5.surface || '#fff', border: `1px solid ${T5.line}`, borderRadius: 10, padding: '8px 10px' }}>
                      <div className="ff-sans" style={{ fontSize: 10, color: T5.inkMute, marginBottom: 2 }}>Kim</div>
                      <div className="ff-sans" style={{ fontSize: 13, color: T5.ink, fontWeight: 500, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        Ayşe <Icon name="chevron-down" size={14} color={T5.inkMute}/>
                      </div>
                    </div>
                  </div>
                  <div style={{ background: T5.surface || '#fff', border: `1px solid ${T5.line}`, borderRadius: 10, padding: '8px 10px' }}>
                    <div className="ff-sans" style={{ fontSize: 10, color: T5.inkMute, marginBottom: 2 }}>Not</div>
                    <div className="ff-sans" style={{ fontSize: 13, color: T5.ink, fontWeight: 500 }}>
                      Haftalık alışveriş<span style={{ background: T5.terracotta, color: '#fff', padding: '0 1px', marginLeft: 1, fontSize: 11 }}>|</span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Toplam ve onay */}
      <div style={{ padding: '4px 20px 24px' }}>
        <div style={{
          background: T5.ink, color: '#fff', borderRadius: 20,
          padding: '16px 18px',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
            <div className="ff-sans" style={{ fontSize: 13, opacity: 0.7 }}>Toplam gider</div>
            <div className="num ff-serif" style={{ fontSize: 28, fontWeight: 400 }}>−{formatTL(1232.50, { decimals: 2 })} ₺</div>
          </div>
          <button style={{
            width: '100%', padding: '14px', borderRadius: 14,
            background: T5.terracotta, border: 'none', color: '#fff',
            fontSize: 15, fontWeight: 600, cursor: 'pointer',
            fontFamily: "'DM Sans', sans-serif",
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}>
            <Icon name="check" size={18} stroke={2.2}/> Deftere işle
          </button>
        </div>
      </div>
    </Screen>
  );
}

window.ReviewScreen = ReviewScreen;
