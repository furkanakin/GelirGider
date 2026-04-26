// 09. Kategoriler — grid
const T9 = window.EVI_TOKENS;

function CategoriesScreen() {
  const cats = window.EVI_CATEGORIES;
  const amounts = { market: 2410, fatura: 3250, ulasim: 980, yemek: 685, cocuk: 525, saglik: 220, eglence: 89, kira: 0, maas: 28500, ek: 4200 };

  return (
    <Screen label="09 Kategori" activeTab="chart" bg={T9.cream}>
      <ScreenHeader
        subtitle="NİSAN 2026"
        title="Kategoriler"
        right={
          <button style={{
            width: 36, height: 36, borderRadius: 999, border: 'none',
            background: T9.paper, color: T9.inkSoft, display: 'flex',
            alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          }}>
            <Icon name="plus" size={18}/>
          </button>
        }
      />

      {/* Tab: Gider | Gelir */}
      <div style={{ padding: '0 20px 16px' }}>
        <div style={{ background: T9.paper, borderRadius: 12, padding: 4, display: 'flex' }}>
          {['Gider', 'Gelir'].map((t, i) => (
            <div key={t} className="ff-sans" style={{
              flex: 1, textAlign: 'center', padding: '8px 0',
              fontSize: 13, fontWeight: 600,
              background: i === 0 ? '#fff' : 'transparent',
              color: i === 0 ? T9.ink : T9.inkMute,
              borderRadius: 9, boxShadow: i === 0 ? T9.shadowSm : 'none',
            }}>{t}</div>
          ))}
        </div>
      </div>

      {/* Grid */}
      <div style={{ padding: '0 20px 16px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {cats.filter(c => !c.income).map(c => {
          const amount = amounts[c.id] || 0;
          return (
            <div key={c.id} style={{
              background: T9.surface || '#fff', border: `1px solid ${T9.line}`, borderRadius: 16,
              padding: '14px 14px',
            }}>
              <div style={{
                width: 40, height: 40, borderRadius: 12, background: c.tint, color: c.color,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                marginBottom: 10,
              }}>
                <Icon name={c.icon} size={20} stroke={1.7}/>
              </div>
              <div className="ff-sans" style={{ fontSize: 13, color: T9.ink, fontWeight: 500, marginBottom: 2 }}>{c.label}</div>
              <div className="num ff-serif" style={{ fontSize: 18, color: T9.ink, lineHeight: '22px' }}>
                {amount > 0 ? formatTL(amount) : '—'}
                {amount > 0 && <span className="ff-sans" style={{ fontSize: 11, color: T9.inkMute, marginLeft: 3 }}>₺</span>}
              </div>
            </div>
          );
        })}

        {/* Yeni kategori ekle */}
        <div style={{
          background: 'transparent', border: `1.5px dashed ${T9.line}`, borderRadius: 16,
          padding: '14px 14px', display: 'flex', flexDirection: 'column', alignItems: 'center',
          justifyContent: 'center', minHeight: 110,
        }}>
          <div style={{ width: 36, height: 36, borderRadius: 999, background: T9.paper, color: T9.inkMute, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 6 }}>
            <Icon name="plus" size={18}/>
          </div>
          <div className="ff-sans" style={{ fontSize: 12, color: T9.inkMute, fontWeight: 500 }}>Yeni</div>
        </div>
      </div>
    </Screen>
  );
}

window.CategoriesScreen = CategoriesScreen;
