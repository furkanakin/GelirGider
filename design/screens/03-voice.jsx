// 03. Sesli kayıt aktif — büyük dalga animasyonu, transcribe akışı
const T3 = window.EVI_TOKENS;

function VoiceScreen() {
  // Dalga barlar
  const bars = Array.from({ length: 32 });

  return (
    <Screen label="03 Ses" activeTab="add" withTabBar={false} bg={T3.cream} dark={false}>
      <div style={{ padding: '8px 20px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <button style={{
          width: 36, height: 36, borderRadius: 999, border: 'none',
          background: T3.paper, color: T3.inkSoft, display: 'flex',
          alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }}>
          <Icon name="x" size={18}/>
        </button>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <div style={{ width: 8, height: 8, borderRadius: 999, background: T3.terracotta, animation: 'evi-pulse 1.4s infinite' }}/>
          <div className="num ff-sans" style={{ fontSize: 13, color: T3.inkSoft, fontWeight: 600 }}>0:14</div>
        </div>
        <div style={{ width: 36 }}/>
      </div>

      <div style={{ padding: '8px 24px 0' }}>
        <div className="ff-sans" style={{ fontSize: 12, color: T3.terracotta, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 8 }}>
          Dinliyorum…
        </div>
        <div className="ff-serif" style={{ fontSize: 26, lineHeight: '32px', color: T3.ink }}>
          "Bugün <span style={{ background: T3.terraTint, padding: '0 4px', borderRadius: 4 }}>Migros'tan</span> haftalık market yaptım, <span style={{ background: T3.terraTint, padding: '0 4px', borderRadius: 4 }}>847 lira</span> 50 kuruş, ayrıca sabah Mehmet <span style={{ background: T3.forestTint, padding: '0 4px', borderRadius: 4 }}>Espressolab'da</span> 65 lira kahve içmiş…<span style={{ background: T3.terracotta, color: '#fff', padding: '0 3px', borderRadius: 2, marginLeft: 2 }}>|</span>"
        </div>
      </div>

      {/* Dalgalar */}
      <div style={{ padding: '40px 24px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4, height: 140 }}>
        {bars.map((_, i) => {
          const h = 8 + Math.abs(Math.sin(i * 0.7)) * 70;
          const isActive = i < 22;
          return (
            <div key={i} style={{
              width: 4, height: h, borderRadius: 999,
              background: isActive ? T3.terracotta : T3.lineSoft,
              animation: isActive ? `evi-wave ${0.6 + (i % 5) * 0.1}s ease-in-out infinite` : 'none',
              animationDelay: `${i * 0.04}s`,
            }}/>
          );
        })}
      </div>

      {/* AI özet ön-izleme */}
      <div style={{ padding: '0 20px 16px' }}>
        <div style={{
          background: T3.forestTint, border: `1px solid ${T3.forestSoft}`,
          borderRadius: 18, padding: '14px 16px',
          display: 'flex', gap: 10,
        }}>
          <div style={{ width: 28, height: 28, borderRadius: 999, background: T3.forest, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Icon name="sparkle" size={14} stroke={2}/>
          </div>
          <div style={{ flex: 1 }}>
            <div className="ff-sans" style={{ fontSize: 11, color: T3.forest, fontWeight: 600, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 4 }}>AI tespit etti</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <div className="ff-sans" style={{ fontSize: 12, color: T3.forestDeep }}>• <b>Migros</b> — 847,50 ₺ <span style={{ color: T3.inkMute }}>(market)</span></div>
              <div className="ff-sans" style={{ fontSize: 12, color: T3.forestDeep }}>• <b>Espressolab</b> — 65 ₺ <span style={{ color: T3.inkMute }}>(yemek · Mehmet)</span></div>
            </div>
          </div>
        </div>
      </div>

      {/* Kontrol satırı */}
      <div style={{ padding: '20px 20px 28px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 36 }}>
        <button style={{
          width: 56, height: 56, borderRadius: 999, border: `1.5px solid ${T3.line}`,
          background: T3.surface || '#fff', color: T3.inkMute,
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }}>
          <Icon name="trash" size={20}/>
        </button>
        <button style={{
          width: 88, height: 88, borderRadius: 999, border: 'none',
          background: T3.terracotta, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer',
          boxShadow: '0 8px 24px rgba(196,89,60,0.4)',
          position: 'relative',
        }}>
          <div style={{ position: 'absolute', inset: -8, borderRadius: 999, border: `2px solid ${T3.terracotta}`, opacity: 0.3, animation: 'evi-pulse 2s infinite' }}/>
          <Icon name="pause" size={32} stroke={2}/>
        </button>
        <button style={{
          width: 56, height: 56, borderRadius: 999, border: 'none',
          background: T3.forest, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }}>
          <Icon name="check" size={22} stroke={2.2}/>
        </button>
      </div>
    </Screen>
  );
}

window.VoiceScreen = VoiceScreen;
