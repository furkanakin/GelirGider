// 04. Foto/fiş tarama — kamera arayüzü, OCR overlay
const T4 = window.EVI_TOKENS;

function PhotoScreen() {
  return (
    <Screen label="04 Foto" activeTab="add" withTabBar={false} bg="#1A1A1A" dark={true}>
      {/* Üst bar */}
      <div style={{ padding: '8px 20px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'relative', zIndex: 2 }}>
        <button style={{
          width: 36, height: 36, borderRadius: 999, border: 'none',
          background: 'rgba(255,255,255,0.12)', color: '#fff', display: 'flex',
          alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }}>
          <Icon name="x" size={18}/>
        </button>
        <div className="ff-sans" style={{ fontSize: 13, color: '#fff', fontWeight: 500 }}>Fişi çerçevele</div>
        <button style={{
          width: 36, height: 36, borderRadius: 999, border: 'none',
          background: 'rgba(255,255,255,0.12)', color: '#fff', display: 'flex',
          alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }}>
          <Icon name="flash" size={18}/>
        </button>
      </div>

      {/* Vesika alanı */}
      <div style={{ position: 'absolute', top: 110, left: 24, right: 24, bottom: 220 }}>
        {/* Sahte fiş */}
        <div style={{
          position: 'absolute', inset: 0, background: '#F2EDE3', borderRadius: 8,
          padding: '20px 18px', transform: 'rotate(-2deg)',
          boxShadow: '0 20px 40px rgba(0,0,0,0.4)',
          fontFamily: "'JetBrains Mono', monospace", fontSize: 9, color: '#3a3530',
          lineHeight: '14px',
        }}>
          <div style={{ textAlign: 'center', fontWeight: 700, fontSize: 12, marginBottom: 2 }}>MİGROS</div>
          <div style={{ textAlign: 'center', fontSize: 8, marginBottom: 8, opacity: 0.7 }}>Bağdat Cad. No: 142</div>
          <div style={{ borderTop: '1px dashed #aaa', borderBottom: '1px dashed #aaa', padding: '6px 0', marginBottom: 8 }}>
            23.04.2026 · 14:32 · FIŞ #4892
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>EKMEK BÜYÜK</span><span>12,50</span></div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>SÜT 1L (3)</span><span>87,00</span></div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>YOĞURT 1KG</span><span>48,90</span></div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>DOMATES KG</span><span>34,75</span></div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>DETERJAN</span><span>129,00</span></div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>TAVUK GÖĞÜS</span><span>184,50</span></div>
          <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>SEBZE KARIŞ.</span><span>67,90</span></div>
          <div style={{ display: 'flex', justifyContent: 'space-between', borderTop: '1px dashed #aaa', marginTop: 6, paddingTop: 6, fontWeight: 700, fontSize: 11 }}><span>TOPLAM</span><span>847,50 ₺</span></div>
        </div>

        {/* Köşe çerçevesi */}
        <div style={{ position: 'absolute', inset: -12, pointerEvents: 'none' }}>
          {[
            { top: 0, left: 0, borderTop: 1, borderLeft: 1 },
            { top: 0, right: 0, borderTop: 1, borderRight: 1 },
            { bottom: 0, left: 0, borderBottom: 1, borderLeft: 1 },
            { bottom: 0, right: 0, borderBottom: 1, borderRight: 1 },
          ].map((c, i) => (
            <div key={i} style={{
              position: 'absolute',
              top: c.top, left: c.left, right: c.right, bottom: c.bottom,
              width: 28, height: 28,
              borderTop: c.borderTop ? `3px solid ${T4.terracotta}` : 'none',
              borderLeft: c.borderLeft ? `3px solid ${T4.terracotta}` : 'none',
              borderRight: c.borderRight ? `3px solid ${T4.terracotta}` : 'none',
              borderBottom: c.borderBottom ? `3px solid ${T4.terracotta}` : 'none',
              borderTopLeftRadius: c.borderTop && c.borderLeft ? 8 : 0,
              borderTopRightRadius: c.borderTop && c.borderRight ? 8 : 0,
              borderBottomLeftRadius: c.borderBottom && c.borderLeft ? 8 : 0,
              borderBottomRightRadius: c.borderBottom && c.borderRight ? 8 : 0,
            }}/>
          ))}
        </div>

        {/* AI tespit chip */}
        <div style={{
          position: 'absolute', bottom: -16, left: '50%', transform: 'translateX(-50%) rotate(-2deg)',
          background: T4.terracotta, color: '#fff', borderRadius: 999,
          padding: '6px 14px', fontSize: 11, fontWeight: 600,
          fontFamily: "'DM Sans', sans-serif",
          display: 'flex', alignItems: 'center', gap: 6,
          boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
        }}>
          <Icon name="sparkle" size={12} stroke={2}/>
          7 satır algılandı · Migros
        </div>
      </div>

      {/* Alt kontrol */}
      <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '20px 20px 36px' }}>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 18, marginBottom: 18 }}>
          {['Tek satır', 'Fiş', 'Fatura'].map((t, i) => (
            <div key={t} className="ff-sans" style={{
              fontSize: 12, fontWeight: i === 1 ? 700 : 500,
              color: i === 1 ? '#fff' : 'rgba(255,255,255,0.5)',
              borderBottom: i === 1 ? `2px solid ${T4.terracotta}` : 'none',
              paddingBottom: 4,
            }}>{t}</div>
          ))}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <button style={{
            width: 48, height: 48, borderRadius: 12, border: 'none',
            background: 'rgba(255,255,255,0.12)', color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          }}>
            <Icon name="image" size={22}/>
          </button>
          <button style={{
            width: 76, height: 76, borderRadius: 999, border: '4px solid #fff',
            background: 'transparent', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{ width: 60, height: 60, borderRadius: 999, background: T4.surface || '#fff' }}/>
          </button>
          <button style={{
            width: 48, height: 48, borderRadius: 12, border: 'none',
            background: 'rgba(255,255,255,0.12)', color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          }}>
            <Icon name="rotate" size={22}/>
          </button>
        </div>
      </div>
    </Screen>
  );
}

window.PhotoScreen = PhotoScreen;
