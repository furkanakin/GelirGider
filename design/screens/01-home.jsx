// 01. Ana ekran (Dashboard) — sıcak özet
const T1 = window.EVI_TOKENS;

function HomeScreen() {
  const balance = 24850;
  const income = 32700;
  const spent = 7850;
  const budget = 18000;
  const pct = Math.min(100, (spent / budget) * 100);

  const recent = window.EVI_TRANSACTIONS.slice(0, 3);

  return (
    <Screen label="01 Ev" activeTab="home">
      {/* Selamlama */}
      <ScreenHeader
        subtitle="Salı, 23 Nisan"
        title={<span>Merhaba, <span style={{ fontStyle: 'italic' }}>Ayşe</span></span>}
        right={
          <button style={{
            width: 36, height: 36, borderRadius: 999, border: 'none',
            background: T1.paper, color: T1.inkSoft, display: 'flex',
            alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
            position: 'relative',
          }}>
            <Icon name="bell" size={18}/>
            <div style={{ position: 'absolute', top: 8, right: 9, width: 7, height: 7, borderRadius: 999, background: T1.terracotta, border: `1.5px solid ${T1.paper}` }}/>
          </button>
        }
      />

      {/* Kasa kartı */}
      <div style={{ padding: '0 20px 16px' }}>
        <div className="grain" style={{
          background: T1.terracotta, borderRadius: 24,
          padding: '20px 22px 18px', color: '#fff',
          boxShadow: '0 12px 28px rgba(196,89,60,0.25)',
          position: 'relative', overflow: 'hidden',
        }}>
          {/* dekoratif daireler */}
          <div style={{ position: 'absolute', right: -40, top: -40, width: 140, height: 140, borderRadius: '50%', background: 'rgba(255,255,255,0.08)' }}/>
          <div style={{ position: 'absolute', right: 30, bottom: -30, width: 80, height: 80, borderRadius: '50%', background: 'rgba(255,255,255,0.06)' }}/>

          <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, opacity: 0.85, fontWeight: 500, marginBottom: 8 }}>
            <Icon name="house-heart" size={14} stroke={1.8}/>
            <span style={{ letterSpacing: 0.3 }}>EV KASASI · NİSAN</span>
          </div>
          <div className="ff-serif num" style={{ fontSize: 48, lineHeight: '52px', fontWeight: 400, marginBottom: 2 }}>
            {formatTL(balance)}<span style={{ fontSize: 22, marginLeft: 4, opacity: 0.85 }}>₺</span>
          </div>
          <div className="ff-sans" style={{ fontSize: 12, opacity: 0.85 }}>kalan bakiye</div>

          <div style={{ display: 'flex', gap: 14, marginTop: 18, position: 'relative', zIndex: 1 }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, opacity: 0.85, marginBottom: 2 }}>
                <Icon name="arrow-down" size={11} stroke={2}/> GELİR
              </div>
              <div className="num" style={{ fontSize: 18, fontWeight: 600 }}>+{formatTL(income)} ₺</div>
            </div>
            <div style={{ width: 1, background: 'rgba(255,255,255,0.25)' }}/>
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, opacity: 0.85, marginBottom: 2 }}>
                <Icon name="arrow-up" size={11} stroke={2}/> GİDER
              </div>
              <div className="num" style={{ fontSize: 18, fontWeight: 600 }}>−{formatTL(spent)} ₺</div>
            </div>
          </div>
        </div>
      </div>

      {/* Hızlı kayıt — dashboardun kalbi */}
      <div style={{ padding: '0 20px 16px' }}>
        <div className="ff-sans" style={{ fontSize: 12, color: T1.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 10, paddingLeft: 4 }}>
          Hızlı kayıt
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          {[
            { icon: 'mic', label: 'Sesli', bg: T1.terraTint, color: T1.terracotta },
            { icon: 'camera', label: 'Foto', bg: T1.forestTint, color: T1.forest },
            { icon: 'pen', label: 'Yaz', bg: T1.butterTint, color: '#9A7A2D' },
          ].map(b => (
            <button key={b.label} style={{
              border: `1px solid ${T1.line}`, background: T1.surface || '#fff', borderRadius: 16,
              padding: '14px 8px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
              cursor: 'pointer',
            }}>
              <div style={{
                width: 38, height: 38, borderRadius: 12, background: b.bg, color: b.color,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name={b.icon} size={20}/>
              </div>
              <div className="ff-sans" style={{ fontSize: 13, color: T1.inkSoft, fontWeight: 500 }}>{b.label}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Bütçe satırı */}
      <div style={{ padding: '0 20px 16px' }}>
        <div style={{
          background: T1.surface || '#fff', border: `1px solid ${T1.line}`, borderRadius: 18,
          padding: '14px 16px',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
            <div className="ff-sans" style={{ fontSize: 13, color: T1.inkSoft, fontWeight: 500 }}>Aylık bütçe</div>
            <div className="num ff-sans" style={{ fontSize: 12, color: T1.inkMute }}>
              <span style={{ color: T1.terracotta, fontWeight: 600 }}>{formatTL(spent)}</span> / {formatTL(budget)} ₺
            </div>
          </div>
          <div style={{ height: 8, background: T1.lineSoft, borderRadius: 999, overflow: 'hidden', position: 'relative' }}>
            <div style={{
              position: 'absolute', left: 0, top: 0, height: '100%',
              width: `${pct}%`, background: T1.terracotta, borderRadius: 999,
            }}/>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
            <div className="ff-sans" style={{ fontSize: 11, color: T1.inkMute }}>{Math.round(pct)}% kullanıldı</div>
            <div className="ff-sans" style={{ fontSize: 11, color: T1.forest, fontWeight: 600 }}>+ iyi gidiyor</div>
          </div>
        </div>
      </div>

      {/* Bu ay öne çıkanlar */}
      <div style={{ padding: '0 20px 16px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10, paddingLeft: 4 }}>
          <div className="ff-sans" style={{ fontSize: 12, color: T1.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>
            Son işlemler
          </div>
          <div className="ff-sans" style={{ fontSize: 12, color: T1.terracotta, fontWeight: 600 }}>Tümü →</div>
        </div>
        <div style={{ background: T1.surface || '#fff', borderRadius: 18, border: `1px solid ${T1.line}`, overflow: 'hidden' }}>
          {recent.map((tx, i) => {
            const cat = window.EVI_CAT_BY_ID[tx.cat];
            const who = window.EVI_FAMILY.find(f => f.id === tx.who);
            return (
              <div key={tx.id} style={{
                padding: '12px 14px', display: 'flex', gap: 12, alignItems: 'center',
                borderBottom: i < recent.length - 1 ? `1px solid ${T1.lineSoft}` : 'none',
              }}>
                <CatChip id={tx.cat} size={38}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="ff-sans" style={{ fontSize: 14, color: T1.ink, fontWeight: 500, marginBottom: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{tx.merchant}</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <Avatar name={who.name} size={14} color={who.color}/>
                    <div className="ff-sans" style={{ fontSize: 11, color: T1.inkMute }}>{who.name} · {tx.date}</div>
                  </div>
                </div>
                <div className="num ff-sans" style={{
                  fontSize: 14, fontWeight: 600,
                  color: tx.type === 'income' ? T1.forest : T1.ink,
                }}>
                  {tx.type === 'income' ? '+' : '−'}{formatTL(tx.amount, { decimals: tx.amount % 1 ? 2 : 0 })} ₺
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* AI öngörüsü */}
      <div style={{ padding: '0 20px 24px' }}>
        <div style={{
          background: T1.forestTint, borderRadius: 18,
          padding: '14px 16px', display: 'flex', gap: 12,
          border: `1px solid ${T1.forestSoft}`,
        }}>
          <div style={{ width: 32, height: 32, borderRadius: 10, background: T1.forest, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Icon name="sparkle" size={16} stroke={1.8}/>
          </div>
          <div style={{ flex: 1 }}>
            <div className="ff-sans" style={{ fontSize: 11, color: T1.forest, fontWeight: 600, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 2 }}>AI ipucu</div>
            <div className="ff-sans" style={{ fontSize: 13, color: T1.forestDeep, lineHeight: '18px' }}>
              Bu ay marketten <b>%18 daha az</b> harcıyorsunuz. Geçen ay aynı dönem 1.034 ₺ idi.
            </div>
          </div>
        </div>
      </div>
    </Screen>
  );
}

window.HomeScreen = HomeScreen;
