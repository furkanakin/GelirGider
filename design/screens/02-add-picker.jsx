// 02. Hızlı giriş seçici — modal-style "Nasıl ekleyelim?" ekranı
const T2 = window.EVI_TOKENS;

function AddPickerScreen() {
  const methods = [
    {
      id: 'voice', icon: 'mic', label: 'Sesli anlat',
      desc: '"Bugün markete 320 lira verdim..."',
      bg: T2.terracotta, color: '#fff', tint: T2.terraTint,
    },
    {
      id: 'photo', icon: 'camera', label: 'Fiş çek',
      desc: 'Fişi çek, AI satır satır okusun',
      bg: T2.forest, color: '#fff', tint: T2.forestTint,
    },
    {
      id: 'text', icon: 'pen', label: 'Yaz',
      desc: 'Klasik usul, tek satır da olur',
      bg: '#1A1A1A', color: '#fff', tint: T2.paper,
    },
  ];

  return (
    <Screen label="02 Ekle" activeTab="add" withTabBar={false} bg={T2.cream}>
      <div style={{ padding: '8px 20px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <button style={{
          width: 36, height: 36, borderRadius: 999, border: 'none',
          background: T2.paper, color: T2.inkSoft, display: 'flex',
          alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }}>
          <Icon name="x" size={18}/>
        </button>
        <div className="ff-sans" style={{ fontSize: 13, color: T2.inkMute, fontWeight: 500 }}>Yeni kayıt</div>
        <div style={{ width: 36 }}/>
      </div>

      <div style={{ padding: '20px 24px 8px' }}>
        <div className="ff-serif" style={{ fontSize: 32, lineHeight: '36px', color: T2.ink, marginBottom: 6 }}>
          Nasıl <span style={{ fontStyle: 'italic' }}>ekleyelim?</span>
        </div>
        <div className="ff-sans" style={{ fontSize: 14, color: T2.inkMute, lineHeight: '20px' }}>
          AI seninle birlikte, satır satır kaydeder.
        </div>
      </div>

      <div style={{ padding: '20px 20px 8px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {methods.map(m => (
          <button key={m.id} style={{
            background: T2.surface || '#fff', border: `1px solid ${T2.line}`, borderRadius: 20,
            padding: '18px 18px', display: 'flex', alignItems: 'center', gap: 14,
            cursor: 'pointer', textAlign: 'left',
          }}>
            <div style={{
              width: 52, height: 52, borderRadius: 16, background: m.bg, color: m.color,
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <Icon name={m.icon} size={24} stroke={1.8}/>
            </div>
            <div style={{ flex: 1 }}>
              <div className="ff-sans" style={{ fontSize: 16, fontWeight: 600, color: T2.ink, marginBottom: 2 }}>{m.label}</div>
              <div className="ff-sans" style={{ fontSize: 12, color: T2.inkMute, lineHeight: '16px' }}>{m.desc}</div>
            </div>
            <Icon name="chevron-right" size={20} color={T2.inkFaint}/>
          </button>
        ))}
      </div>

      {/* Tekrar eden işlemler */}
      <div style={{ padding: '20px 20px 16px' }}>
        <div className="ff-sans" style={{ fontSize: 12, color: T2.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 10, paddingLeft: 4 }}>
          Sık kullanılan
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          {[
            { cat: 'market', label: 'Market', amount: '~ 800' },
            { cat: 'yemek', label: 'Kahve',  amount: '~ 65' },
            { cat: 'ulasim', label: 'Benzin', amount: '~ 320' },
            { cat: 'fatura', label: 'Fatura', amount: '~ 1.250' },
          ].map(s => (
            <button key={s.label} style={{
              background: T2.surface || '#fff', border: `1px solid ${T2.line}`, borderRadius: 14,
              padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 10,
              cursor: 'pointer', textAlign: 'left',
            }}>
              <CatChip id={s.cat} size={32}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="ff-sans" style={{ fontSize: 13, fontWeight: 500, color: T2.ink }}>{s.label}</div>
                <div className="num ff-sans" style={{ fontSize: 11, color: T2.inkMute }}>{s.amount} ₺</div>
              </div>
            </button>
          ))}
        </div>
      </div>
    </Screen>
  );
}

window.AddPickerScreen = AddPickerScreen;
