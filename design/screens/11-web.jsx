// 11. Web responsive — desktop dashboard görünümü
const TB = window.EVI_TOKENS;

function WebDashboard() {
  return (
    <div style={{
      width: '100%', height: '100%', background: TB.cream,
      display: 'flex', overflow: 'hidden',
      fontFamily: "'DM Sans', sans-serif", color: TB.ink,
    }} data-screen-label="11 Web">
      {/* Sidebar */}
      <div style={{ width: 220, padding: '24px 16px', borderRight: `1px solid ${TB.line}`, background: TB.paper, display: 'flex', flexDirection: 'column', gap: 4 }}>
        <div style={{ padding: '0 8px 24px', display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: TB.terracotta, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="house-heart" size={20} stroke={1.8}/>
          </div>
          <div>
            <div className="ff-serif" style={{ fontSize: 18, color: TB.ink, lineHeight: '20px' }}>Evimiz</div>
            <div className="ff-sans" style={{ fontSize: 10, color: TB.inkMute }}>Demir Ailesi</div>
          </div>
        </div>

        {[
          { icon: 'house-heart', label: 'Genel', active: true },
          { icon: 'list', label: 'İşlemler' },
          { icon: 'pie', label: 'Raporlar' },
          { icon: 'tag', label: 'Kategoriler' },
          { icon: 'people', label: 'Aile' },
          { icon: 'settings', label: 'Ayarlar' },
        ].map(it => (
          <div key={it.label} className="ff-sans" style={{
            padding: '10px 12px', borderRadius: 10, display: 'flex', gap: 10, alignItems: 'center',
            background: it.active ? '#fff' : 'transparent',
            color: it.active ? TB.ink : TB.inkMute,
            fontSize: 13, fontWeight: it.active ? 600 : 500,
            boxShadow: it.active ? TB.shadowSm : 'none',
          }}>
            <Icon name={it.icon} size={16}/>
            {it.label}
          </div>
        ))}

        <div style={{ flex: 1 }}/>

        <div style={{ padding: '12px', background: TB.surface || '#fff', border: `1px solid ${TB.line}`, borderRadius: 12, display: 'flex', alignItems: 'center', gap: 10 }}>
          <Avatar name="Ayşe Demir" size={32} color={TB.terraSoft}/>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="ff-sans" style={{ fontSize: 12, fontWeight: 600 }}>Ayşe</div>
            <div className="ff-sans" style={{ fontSize: 10, color: TB.inkMute }}>Anne</div>
          </div>
          <Icon name="menu-dots" size={16} color={TB.inkMute}/>
        </div>
      </div>

      {/* Main */}
      <div className="scroll-hide" style={{ flex: 1, overflowY: 'auto', padding: '28px 32px' }}>
        {/* Top */}
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 24 }}>
          <div>
            <div className="ff-sans" style={{ fontSize: 11, color: TB.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 4 }}>Salı, 23 Nisan</div>
            <div className="ff-serif" style={{ fontSize: 36, lineHeight: '40px' }}>Merhaba, <span style={{ fontStyle: 'italic' }}>Ayşe</span></div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button style={{
              padding: '10px 14px', border: `1px solid ${TB.line}`, background: TB.surface || '#fff',
              borderRadius: 12, fontSize: 13, fontWeight: 500, color: TB.inkSoft,
              fontFamily: "'DM Sans', sans-serif", display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer',
            }}>
              <Icon name="calendar" size={14}/> Nisan 2026
            </button>
            <button style={{
              padding: '10px 16px', border: 'none', background: TB.terracotta, color: '#fff',
              borderRadius: 12, fontSize: 13, fontWeight: 600,
              fontFamily: "'DM Sans', sans-serif", display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer',
            }}>
              <Icon name="plus" size={14} stroke={2.2}/> Yeni kayıt
            </button>
          </div>
        </div>

        {/* Stat row */}
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr', gap: 12, marginBottom: 20 }}>
          <div className="grain" style={{ background: TB.terracotta, color: '#fff', borderRadius: 18, padding: '18px 22px', position: 'relative', overflow: 'hidden' }}>
            <div style={{ position: 'absolute', right: -30, top: -30, width: 140, height: 140, borderRadius: '50%', background: 'rgba(255,255,255,0.08)' }}/>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, opacity: 0.85, marginBottom: 6 }}>
              <Icon name="house-heart" size={12} stroke={1.8}/> EV KASASI
            </div>
            <div className="num ff-serif" style={{ fontSize: 40, lineHeight: '44px' }}>{formatTL(24850)} <span style={{ fontSize: 18, opacity: 0.85 }}>₺</span></div>
            <div className="ff-sans" style={{ fontSize: 11, opacity: 0.85, marginTop: 4 }}>kalan bakiye</div>
          </div>
          <div style={{ background: TB.surface || '#fff', border: `1px solid ${TB.line}`, borderRadius: 18, padding: '18px 20px' }}>
            <div className="ff-sans" style={{ fontSize: 11, color: TB.forest, fontWeight: 600, marginBottom: 6, letterSpacing: 0.3 }}>↓ GELİR</div>
            <div className="num ff-serif" style={{ fontSize: 26, color: TB.forest }}>+{formatTL(32700)}</div>
            <div className="ff-sans" style={{ fontSize: 11, color: TB.inkMute, marginTop: 2 }}>2 işlem</div>
          </div>
          <div style={{ background: TB.surface || '#fff', border: `1px solid ${TB.line}`, borderRadius: 18, padding: '18px 20px' }}>
            <div className="ff-sans" style={{ fontSize: 11, color: TB.terracotta, fontWeight: 600, marginBottom: 6, letterSpacing: 0.3 }}>↑ GİDER</div>
            <div className="num ff-serif" style={{ fontSize: 26, color: TB.ink }}>−{formatTL(7850)}</div>
            <div className="ff-sans" style={{ fontSize: 11, color: TB.inkMute, marginTop: 2 }}>14 işlem</div>
          </div>
        </div>

        {/* Two columns */}
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 12 }}>
          {/* Recent transactions */}
          <div style={{ background: TB.surface || '#fff', border: `1px solid ${TB.line}`, borderRadius: 18, padding: '18px 20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
              <div className="ff-serif" style={{ fontSize: 18 }}>Son işlemler</div>
              <div className="ff-sans" style={{ fontSize: 12, color: TB.terracotta, fontWeight: 600 }}>Tümü →</div>
            </div>
            {window.EVI_TRANSACTIONS.slice(0, 5).map((tx, i, arr) => {
              const who = window.EVI_FAMILY.find(f => f.id === tx.who);
              const sourceIcon = { voice: 'mic', photo: 'camera', text: 'pen', auto: 'refresh' };
              return (
                <div key={tx.id} style={{
                  padding: '10px 0', display: 'flex', gap: 12, alignItems: 'center',
                  borderBottom: i < arr.length - 1 ? `1px solid ${TB.lineSoft}` : 'none',
                }}>
                  <CatChip id={tx.cat} size={34}/>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <div className="ff-sans" style={{ fontSize: 13, fontWeight: 500 }}>{tx.merchant}</div>
                      <Icon name={sourceIcon[tx.source]} size={11} color={TB.inkFaint}/>
                    </div>
                    <div className="ff-sans" style={{ fontSize: 11, color: TB.inkMute }}>{tx.note}</div>
                  </div>
                  <Avatar name={who.name} size={20} color={who.color}/>
                  <div className="ff-sans" style={{ fontSize: 11, color: TB.inkMute, width: 50 }}>{tx.date}</div>
                  <div className="num ff-sans" style={{ fontSize: 13, fontWeight: 600, width: 90, textAlign: 'right',
                    color: tx.type === 'income' ? TB.forest : TB.ink }}>
                    {tx.type === 'income' ? '+' : '−'}{formatTL(tx.amount, { decimals: tx.amount % 1 ? 2 : 0 })} ₺
                  </div>
                </div>
              );
            })}
          </div>

          {/* AI panel + family */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div style={{
              background: TB.forestTint, border: `1px solid ${TB.forestSoft}`,
              borderRadius: 18, padding: '16px 18px',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                <div style={{ width: 28, height: 28, borderRadius: 8, background: TB.forest, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Icon name="sparkle" size={14} stroke={2}/>
                </div>
                <div className="ff-sans" style={{ fontSize: 11, color: TB.forest, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase' }}>AI ÖZET</div>
              </div>
              <div className="ff-serif" style={{ fontSize: 15, lineHeight: '22px', color: TB.forestDeep }}>
                Bu ay <i>düzenli</i> bir aysınız. Market <b>%18 düştü</b>, kira ve faturalar zamanında.
              </div>
            </div>

            <div style={{ background: TB.surface || '#fff', border: `1px solid ${TB.line}`, borderRadius: 18, padding: '16px 18px' }}>
              <div className="ff-sans" style={{ fontSize: 11, color: TB.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 10 }}>Aile katkısı</div>
              {window.EVI_FAMILY.slice(0, 3).map(f => {
                const c = { a: 1657, m: 1145, k: 250 }[f.id] || 0;
                const pct = (c / 3052) * 100;
                return (
                  <div key={f.id} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                    <Avatar name={f.name} size={22} color={f.color}/>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
                        <div className="ff-sans" style={{ fontSize: 12, fontWeight: 500 }}>{f.name}</div>
                        <div className="num ff-sans" style={{ fontSize: 11, color: TB.inkMute }}>{formatTL(c)} ₺</div>
                      </div>
                      <div style={{ height: 3, background: TB.lineSoft, borderRadius: 999 }}>
                        <div style={{ width: `${pct}%`, height: '100%', background: f.color, borderRadius: 999 }}/>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

window.WebDashboard = WebDashboard;
