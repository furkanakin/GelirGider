// 06. İşlem listesi — gruplu, filtreli
const T6 = window.EVI_TOKENS;

function TransactionsScreen() {
  const groups = [
    { date: 'Bugün', items: window.EVI_TRANSACTIONS.filter(t => t.date === 'Bugün') },
    { date: 'Dün', items: window.EVI_TRANSACTIONS.filter(t => t.date === 'Dün') },
    { date: 'Bu hafta', items: window.EVI_TRANSACTIONS.filter(t => !['Bugün','Dün'].includes(t.date)) },
  ];

  const sourceIcon = { voice: 'mic', photo: 'camera', text: 'pen', auto: 'refresh' };

  return (
    <Screen label="06 İşlemler" activeTab="list" bg={T6.cream}>
      <ScreenHeader
        subtitle="NİSAN 2026"
        title="İşlemler"
        right={
          <button style={{
            width: 36, height: 36, borderRadius: 999, border: 'none',
            background: T6.paper, color: T6.inkSoft, display: 'flex',
            alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          }}>
            <Icon name="search" size={18}/>
          </button>
        }
      />

      {/* Filtre chip'leri */}
      <div className="scroll-hide" style={{ padding: '0 20px 12px', overflowX: 'auto', display: 'flex', gap: 6, whiteSpace: 'nowrap' }}>
        {[
          { l: 'Tümü', active: true },
          { l: 'Gider' },
          { l: 'Gelir' },
          { l: 'Ayşe' },
          { l: 'Mehmet' },
          { l: 'Bu ay' },
        ].map((c, i) => (
          <div key={i} className="ff-sans" style={{
            padding: '6px 12px', borderRadius: 999, fontSize: 12, fontWeight: 500,
            background: c.active ? T6.ink : '#fff',
            color: c.active ? '#fff' : T6.inkSoft,
            border: c.active ? 'none' : `1px solid ${T6.line}`,
            flexShrink: 0,
          }}>{c.l}</div>
        ))}
      </div>

      {/* Özet bar */}
      <div style={{ padding: '0 20px 16px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <div style={{ background: T6.surface || '#fff', border: `1px solid ${T6.line}`, borderRadius: 14, padding: '12px 14px' }}>
          <div className="ff-sans" style={{ fontSize: 11, color: T6.inkMute, marginBottom: 4 }}>↑ Gider</div>
          <div className="num ff-serif" style={{ fontSize: 22, color: T6.ink }}>{formatTL(7850)} ₺</div>
        </div>
        <div style={{ background: T6.surface || '#fff', border: `1px solid ${T6.line}`, borderRadius: 14, padding: '12px 14px' }}>
          <div className="ff-sans" style={{ fontSize: 11, color: T6.forest, marginBottom: 4 }}>↓ Gelir</div>
          <div className="num ff-serif" style={{ fontSize: 22, color: T6.forest }}>{formatTL(32700)} ₺</div>
        </div>
      </div>

      {/* Gruplar */}
      {groups.map(g => g.items.length > 0 && (
        <div key={g.date} style={{ padding: '0 20px 16px' }}>
          <div className="ff-sans" style={{ fontSize: 11, color: T6.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 8, paddingLeft: 4 }}>
            {g.date}
          </div>
          <div style={{ background: T6.surface || '#fff', border: `1px solid ${T6.line}`, borderRadius: 16, overflow: 'hidden' }}>
            {g.items.map((tx, i) => {
              const who = window.EVI_FAMILY.find(f => f.id === tx.who);
              return (
                <div key={tx.id} style={{
                  padding: '12px 14px', display: 'flex', gap: 12, alignItems: 'center',
                  borderBottom: i < g.items.length - 1 ? `1px solid ${T6.lineSoft}` : 'none',
                }}>
                  <CatChip id={tx.cat} size={36}/>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <div className="ff-sans" style={{ fontSize: 14, color: T6.ink, fontWeight: 500, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{tx.merchant}</div>
                      <Icon name={sourceIcon[tx.source]} size={11} color={T6.inkFaint}/>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 1 }}>
                      <Avatar name={who.name} size={12} color={who.color}/>
                      <div className="ff-sans" style={{ fontSize: 11, color: T6.inkMute, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{who.name} · {tx.time}</div>
                    </div>
                  </div>
                  <div className="num ff-sans" style={{
                    fontSize: 14, fontWeight: 600,
                    color: tx.type === 'income' ? T6.forest : T6.ink,
                  }}>
                    {tx.type === 'income' ? '+' : '−'}{formatTL(tx.amount, { decimals: tx.amount % 1 ? 2 : 0 })}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      ))}
    </Screen>
  );
}

window.TransactionsScreen = TransactionsScreen;
