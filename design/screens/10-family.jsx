// 10. Aile / Ayarlar — üyeler, davet, ayarlar
const TA = window.EVI_TOKENS;

function FamilyScreen() {
  const fam = window.EVI_FAMILY;
  const contributions = { a: { spent: 1657, income: 4200 }, m: { spent: 1145, income: 28500 }, z: { spent: 65, income: 0 }, k: { spent: 250, income: 0 } };

  return (
    <Screen label="10 Aile" activeTab="people" bg={TA.cream}>
      <ScreenHeader
        subtitle="EVİMİZ"
        title="Aile"
        right={
          <button style={{
            width: 36, height: 36, borderRadius: 999, border: 'none',
            background: TA.paper, color: TA.inkSoft, display: 'flex',
            alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          }}>
            <Icon name="settings" size={18}/>
          </button>
        }
      />

      {/* Hane kartı */}
      <div style={{ padding: '0 20px 16px' }}>
        <div className="grain" style={{
          background: TA.forest, borderRadius: 22, padding: '18px 20px', color: '#fff',
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', right: -30, top: -30, width: 120, height: 120, borderRadius: '50%', background: 'rgba(255,255,255,0.06)' }}/>
          <div className="ff-sans" style={{ fontSize: 11, opacity: 0.8, fontWeight: 500, letterSpacing: 0.3, marginBottom: 4 }}>HANE</div>
          <div className="ff-serif" style={{ fontSize: 26, lineHeight: '30px', marginBottom: 8 }}>Demir Ailesi</div>
          <div style={{ display: 'flex', gap: -8, marginTop: 12 }}>
            {fam.map((f, i) => (
              <div key={f.id} style={{ marginLeft: i === 0 ? 0 : -8 }}>
                <Avatar name={f.name} size={32} color={f.color} ring={true}/>
              </div>
            ))}
            <div className="ff-sans" style={{ fontSize: 12, marginLeft: 12, alignSelf: 'center', opacity: 0.85 }}>
              4 üye · birlikte 32 ay
            </div>
          </div>
        </div>
      </div>

      {/* Üye listesi */}
      <div style={{ padding: '0 20px 16px' }}>
        <div className="ff-sans" style={{ fontSize: 11, color: TA.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 10, paddingLeft: 4 }}>
          Bu ay
        </div>
        <div style={{ background: TA.surface || '#fff', border: `1px solid ${TA.line}`, borderRadius: 16, overflow: 'hidden' }}>
          {fam.map((f, i) => {
            const c = contributions[f.id];
            return (
              <div key={f.id} style={{
                padding: '12px 14px', display: 'flex', gap: 12, alignItems: 'center',
                borderBottom: i < fam.length - 1 ? `1px solid ${TA.lineSoft}` : 'none',
              }}>
                <Avatar name={f.name} size={42} color={f.color}/>
                <div style={{ flex: 1 }}>
                  <div className="ff-sans" style={{ fontSize: 14, color: TA.ink, fontWeight: 600 }}>{f.name}</div>
                  <div className="ff-sans" style={{ fontSize: 11, color: TA.inkMute }}>{f.role}{i === 0 ? ' · siz' : ''}</div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div className="num ff-sans" style={{ fontSize: 13, color: TA.ink, fontWeight: 600 }}>−{formatTL(c.spent)}</div>
                  {c.income > 0 && <div className="num ff-sans" style={{ fontSize: 11, color: TA.forest }}>+{formatTL(c.income)}</div>}
                </div>
              </div>
            );
          })}

          {/* Davet et */}
          <div style={{
            padding: '14px', display: 'flex', gap: 12, alignItems: 'center',
            borderTop: `1px solid ${TA.lineSoft}`, background: TA.paper,
            cursor: 'pointer',
          }}>
            <div style={{ width: 42, height: 42, borderRadius: 999, background: TA.surface || '#fff', border: `1.5px dashed ${TA.line}`, color: TA.terracotta, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="plus" size={18}/>
            </div>
            <div className="ff-sans" style={{ fontSize: 14, color: TA.terracotta, fontWeight: 600 }}>Aileye birini davet et</div>
            <Icon name="chevron-right" size={18} color={TA.inkFaint} style={{ marginLeft: 'auto' }}/>
          </div>
        </div>
      </div>

      {/* Ayarlar */}
      <div style={{ padding: '0 20px 24px' }}>
        <div className="ff-sans" style={{ fontSize: 11, color: TA.inkMute, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 10, paddingLeft: 4 }}>
          Ayarlar
        </div>
        <div style={{ background: TA.surface || '#fff', border: `1px solid ${TA.line}`, borderRadius: 16, overflow: 'hidden' }}>
          {[
            { icon: 'wallet',   label: 'Aylık bütçe', value: '18.000 ₺' },
            { icon: 'bell',     label: 'Hatırlatmalar', value: 'Açık' },
            { icon: 'lock',     label: 'Gizlilik', value: 'Sadece aile' },
            { icon: 'globe',    label: 'Dil', value: 'Türkçe' },
            { icon: 'doc',      label: 'Veriyi dışa aktar', value: 'CSV / PDF' },
          ].map((it, i, arr) => (
            <div key={it.label} style={{
              padding: '12px 14px', display: 'flex', gap: 12, alignItems: 'center',
              borderBottom: i < arr.length - 1 ? `1px solid ${TA.lineSoft}` : 'none',
            }}>
              <div style={{ width: 32, height: 32, borderRadius: 10, background: TA.paper, color: TA.inkSoft, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon name={it.icon} size={16}/>
              </div>
              <div className="ff-sans" style={{ flex: 1, fontSize: 14, color: TA.ink, fontWeight: 500 }}>{it.label}</div>
              <div className="ff-sans" style={{ fontSize: 12, color: TA.inkMute }}>{it.value}</div>
              <Icon name="chevron-right" size={16} color={TA.inkFaint}/>
            </div>
          ))}
        </div>
      </div>
    </Screen>
  );
}

window.FamilyScreen = FamilyScreen;
