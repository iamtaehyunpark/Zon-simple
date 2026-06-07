// wf_shared.jsx — shared wireframe primitives for ZON wireframes
// Exports to window: WF, StatusBar, TabBar, MapBg, ImgBox, Pill, SearchBar, ConceptCard

const WF = {
  bg:     '#F7F4EE',
  stroke: '#2A2624',
  gray1:  '#C4BDB4',
  gray2:  '#E2DDD6',
  text:   '#2A2624',
  muted:  '#8A8278',
  mapBg:  '#DEDAD2',
};

const StatusBar = ({ dark = false }) => (
  <div style={{
    height: 44, display: 'flex', alignItems: 'center',
    justifyContent: 'space-between',
    padding: '0 20px 0 24px',
    fontFamily: 'monospace', fontSize: 13,
    color: dark ? 'rgba(255,255,255,0.9)' : WF.text,
    flexShrink: 0,
  }}>
    <span>9:41</span>
    <div style={{ display: 'flex', gap: 5, alignItems: 'center', fontSize: 11 }}>
      <span>●●●</span><span>WiFi</span><span>■■■</span>
    </div>
  </div>
);

const TabBar = ({ active = 0, accent = '#888' }) => {
  const tabs = [
    { sym: '◉', label: 'Map' },
    { sym: '≡', label: 'Feed' },
    { sym: '+', label: '', cta: true },
    { sym: '▦', label: 'Time' },
    { sym: '◯', label: 'Me' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      height: 83,
      background: WF.bg,
      borderTop: `1.5px solid ${WF.stroke}`,
      display: 'flex', alignItems: 'flex-start', paddingTop: 10,
    }}>
      {tabs.map((t, i) => (
        <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3 }}>
          {t.cta ? (
            <div style={{
              width: 46, height: 46, borderRadius: 23,
              background: accent,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: 'white', fontSize: 26, fontWeight: 'bold',
              marginTop: -20,
              border: `2px solid ${WF.stroke}`,
              fontFamily: 'Caveat, cursive',
              lineHeight: 1,
            }}>+</div>
          ) : (
            <>
              <div style={{ fontSize: 18, color: active === i ? accent : WF.muted }}>{t.sym}</div>
              <div style={{ fontSize: 10, fontFamily: 'monospace', color: active === i ? accent : WF.muted }}>{t.label}</div>
            </>
          )}
        </div>
      ))}
    </div>
  );
};

const MapBg = ({ height = 400, route = true, pins = [], accent = '#888' }) => {
  const cols = Math.ceil(390 / 55);
  const rows = Math.ceil(height / 55);
  return (
    <div style={{ width: '100%', height, background: WF.mapBg, position: 'relative', overflow: 'hidden', flexShrink: 0 }}>
      <svg width="390" height={height} viewBox={`0 0 390 ${height}`} style={{ position: 'absolute', top: 0, left: 0 }}>
        {[...Array(cols)].map((_, i) => (
          <line key={`v${i}`} x1={i * 55} y1="0" x2={i * 55} y2={height} stroke="#CBC5BC" strokeWidth="0.5" />
        ))}
        {[...Array(rows)].map((_, i) => (
          <line key={`h${i}`} x1="0" y1={i * 55} x2="390" y2={i * 55} stroke="#CBC5BC" strokeWidth="0.5" />
        ))}
        {route && (
          <path
            d={`M 30,${height - 60} Q 90,${height - 120} 150,${height * 0.45} T 260,${height * 0.25} T 370,${height * 0.1}`}
            stroke={accent} strokeWidth="2.5" strokeDasharray="7,4" fill="none" opacity="0.65"
          />
        )}
        {pins.map((p, i) => (
          <g key={i}>
            <circle cx={p.x} cy={p.y} r="9" fill={accent} stroke="white" strokeWidth="2" opacity="0.9" />
            <circle cx={p.x} cy={p.y} r="3" fill="white" />
          </g>
        ))}
        <circle cx="220" cy={height * 0.38} r="7" fill={accent} stroke="white" strokeWidth="2.5" />
        <circle cx="220" cy={height * 0.38} r="16" fill={accent} opacity="0.18" />
      </svg>
    </div>
  );
};

const ImgBox = ({ w = '100%', h = 200, label = 'photo', style = {} }) => (
  <div style={{
    width: w, height: h, background: WF.gray1,
    position: 'relative', overflow: 'hidden',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    backgroundImage: [
      'linear-gradient(to bottom right, transparent calc(50% - 0.5px), #B0AAA0 calc(50% - 0.5px), #B0AAA0 calc(50% + 0.5px), transparent calc(50% + 0.5px))',
      'linear-gradient(to bottom left, transparent calc(50% - 0.5px), #B0AAA0 calc(50% - 0.5px), #B0AAA0 calc(50% + 0.5px), transparent calc(50% + 0.5px))',
    ].join(', '),
    ...style,
  }}>
    {label && (
      <span style={{
        fontSize: 10, color: '#777', fontFamily: 'monospace', zIndex: 1,
        background: 'rgba(196,189,180,0.7)', padding: '1px 5px', borderRadius: 2,
      }}>{label}</span>
    )}
  </div>
);

const Pill = ({ children, bg = WF.gray2, color = WF.text, style = {} }) => (
  <span style={{
    display: 'inline-flex', alignItems: 'center',
    background: bg, color, borderRadius: 20,
    padding: '3px 11px', fontSize: 12,
    border: `1px solid ${WF.stroke}`,
    fontFamily: 'Caveat, cursive',
    lineHeight: 1.4,
    ...style,
  }}>{children}</span>
);

const SearchBar = ({ placeholder = 'Search...', style = {} }) => (
  <div style={{
    height: 40, border: `1.5px solid ${WF.stroke}`,
    borderRadius: 20, display: 'flex', alignItems: 'center',
    padding: '0 14px', gap: 8,
    background: 'white', ...style,
  }}>
    <span style={{ fontSize: 13 }}>⌕</span>
    <span style={{ color: WF.muted, fontSize: 14, fontFamily: 'Caveat, cursive' }}>{placeholder}</span>
  </div>
);

const ConceptCard = ({ letter, name, tagline, bet, tabs, accent }) => (
  <div style={{
    width: 260, height: 844, background: WF.bg,
    fontFamily: 'Caveat, cursive',
    display: 'flex', flexDirection: 'column',
    borderLeft: `5px solid ${accent}`,
    padding: '32px 24px',
  }}>
    <div style={{ fontSize: 56, fontWeight: 700, color: accent, lineHeight: 1, marginBottom: 4 }}>{letter}</div>
    <div style={{ fontSize: 26, fontWeight: 700, color: WF.text, marginBottom: 6, lineHeight: 1.2 }}>{name}</div>
    <div style={{ fontSize: 15, color: WF.muted, fontStyle: 'italic', marginBottom: 24, lineHeight: 1.4 }}>"{tagline}"</div>

    <div style={{ fontSize: 13, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, color: WF.muted, marginBottom: 10 }}>Core Bet</div>
    <div style={{ fontSize: 14, lineHeight: 1.65, color: WF.text, marginBottom: 32 }}>{bet}</div>

    <div style={{ fontSize: 13, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, color: WF.muted, marginBottom: 12 }}>Tab Structure</div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {tabs.map((t, i) => (
        <div key={i} style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
          <div style={{
            width: 26, height: 26, borderRadius: 6, background: i === 2 ? accent : WF.gray2,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 13, flexShrink: 0, border: `1px solid ${WF.stroke}`,
            color: i === 2 ? 'white' : WF.text,
          }}>{t.icon}</div>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700 }}>{t.tab}</div>
            <div style={{ fontSize: 12, color: WF.muted, lineHeight: 1.4 }}>{t.desc}</div>
          </div>
        </div>
      ))}
    </div>

    <div style={{ marginTop: 'auto', paddingTop: 24 }}>
      <div style={{ height: 1, background: WF.gray1, marginBottom: 16 }} />
      <div style={{ fontSize: 11, color: WF.muted, fontFamily: 'monospace' }}>ZON · Wireframes v1 · {new Date().toLocaleDateString()}</div>
    </div>
  </div>
);

Object.assign(window, { WF, StatusBar, TabBar, MapBg, ImgBox, Pill, SearchBar, ConceptCard });
