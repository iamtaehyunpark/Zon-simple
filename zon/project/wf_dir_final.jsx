// wf_dir_final.jsx — Direction D: FINAL
// Map        = C clusters + search/filters + A's route + stamp pins + summary pill
// Feed       = Direction C (masonry + filter tabs + overall C tone)
// Check-in   = Direction A (bottom sheet, unchanged)
// Timeline   = Direction A (week strip → route map → list)
// Profile    = Direction A (stats row + tab switch + photo grid)

const ACCENT_D = '#8B6EC4';

const D_Concept = () => (
  <ConceptCard
    letter="D"
    name="ZON — Final"
    tagline="Collect places. Share moments. See your world grow."
    accent={ACCENT_D}
    bet="Map blends C's place discovery (clusters, search, filters) with A's living route (GPS trail + stamp pins) — you see both where you've been AND what's popular nearby. Feed and overall tone follows C: playful, place-centric, explorable. Check-in / Timeline / Profile take A's simple, warm, diary-like approach."
    tabs={[
      { icon: '◉', tab: 'Map (Home)',  desc: 'C clusters + search/filter + A route trail + stamp pins + nearby strip' },
      { icon: '≡', tab: 'Feed',        desc: 'C-style: filter tabs (Following / Nearby / Trending) + stamp cards with place pill, photo, caption' },
      { icon: '+', tab: 'Check-in',    desc: 'Direction A: bottom sheet over map, GPS + place search + nearby list' },
      { icon: '▦', tab: 'Timeline',    desc: 'Direction A: week strip → day route map → stamp list' },
      { icon: '◯', tab: 'Profile',     desc: 'Direction A: stats (Stamps / Places / Friends) + Stamps/Saved tabs + photo grid' },
    ]}
  />
);

// MAP — C's search/filter/clusters + A's route + stamp pins + summary pill
const D_Map = () => (
  <div style={{ width: 390, height: 844, background: WF.bg, fontFamily: 'Caveat, cursive', position: 'relative', overflow: 'hidden' }}>
    <StatusBar />

    {/* Search + filter — Direction C */}
    <div style={{ padding: '6px 12px 8px', background: WF.bg, position: 'relative', zIndex: 10 }}>
      <SearchBar placeholder="Search places…" style={{ marginBottom: 7 }} />
      <div style={{ display: 'flex', gap: 7, overflowX: 'auto' }}>
        {['All', '☕ Café', '🍴 Food', '🌿 Nature', '🎨 Art', '🏬 Retail'].map((t, i) => (
          <Pill key={i} bg={i === 0 ? ACCENT_D : WF.gray2} color={i === 0 ? 'white' : WF.text} style={{ flexShrink: 0, fontSize: 12 }}>{t}</Pill>
        ))}
      </div>
    </div>

    {/* Map — A's route + C's clusters together */}
    <div style={{ position: 'relative', height: 432 }}>
      <MapBg height={432} route={true} pins={[{ x: 120, y: 310 }, { x: 200, y: 215 }, { x: 288, y: 140 }]} accent={ACCENT_D} />

      {/* C's place clusters on top of map */}
      {[
        { x: 75,  y: 105, n: 3 },
        { x: 195, y: 75,  n: 7 },
        { x: 310, y: 55,  n: 2 },
        { x: 145, y: 270, n: 4 },
        { x: 330, y: 240, n: 1 },
      ].map((c, i) => (
        <div key={i} style={{
          position: 'absolute', left: c.x - 17, top: c.y - 17,
          width: 34, height: 34, borderRadius: 17,
          background: 'rgba(247,244,238,0.92)', border: `2px solid ${ACCENT_D}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: ACCENT_D, fontSize: 13, fontWeight: 700,
          boxShadow: '0 2px 7px rgba(0,0,0,0.18)',
          fontFamily: 'Caveat, cursive',
        }}>{c.n}</div>
      ))}

      {/* A's route summary pill — floating near bottom of map */}
      <div style={{ position: 'absolute', bottom: 14, left: 0, right: 0, display: 'flex', justifyContent: 'center' }}>
        <div style={{ background: 'rgba(247,244,238,0.95)', border: `1.5px solid ${WF.stroke}`, borderRadius: 24, padding: '6px 18px', display: 'flex', gap: 12, alignItems: 'center', fontSize: 13 }}>
          <span>📍 3 stamps</span>
          <span style={{ color: WF.muted }}>·</span>
          <span>3.8 km today</span>
        </div>
      </div>
    </div>

    {/* C's Nearby strip */}
    <div style={{ background: WF.bg, borderTop: `1px solid ${WF.gray1}` }}>
      <div style={{ padding: '9px 14px 7px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 14, fontWeight: 700 }}>Nearby</span>
        <span style={{ fontSize: 12, color: WF.muted }}>See all ›</span>
      </div>
      <div style={{ display: 'flex', gap: 10, padding: '0 12px 12px', overflowX: 'hidden' }}>
        {[
          { name: 'Heukbyul Coffee', type: '☕', count: 7  },
          { name: 'Han River Park',  type: '🌿', count: 3  },
          { name: 'Grand Market',    type: '🏬', count: 12 },
        ].map((p, i) => (
          <div key={i} style={{ border: `1.5px solid ${WF.stroke}`, borderRadius: 12, padding: '8px 10px', background: WF.bg, flexShrink: 0, minWidth: 112 }}>
            <div style={{ fontSize: 22, marginBottom: 4 }}>{p.type}</div>
            <div style={{ fontSize: 12, fontWeight: 700, lineHeight: 1.3, marginBottom: 2 }}>{p.name}</div>
            <div style={{ fontSize: 11, color: WF.muted }}>{p.count} stamps here</div>
          </div>
        ))}
      </div>
    </div>

    <TabBar active={0} accent={ACCENT_D} />
  </div>
);

// FEED — Direction C tone: filter tabs + stamp cards
const D_Feed = () => (
  <div style={{ width: 390, height: 844, background: WF.bg, fontFamily: 'Caveat, cursive', position: 'relative', overflow: 'hidden' }}>
    <StatusBar />

    <div style={{ padding: '8px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: `1px solid ${WF.gray1}` }}>
      <span style={{ fontSize: 24, fontWeight: 700, letterSpacing: 1 }}>ZON</span>
      <span style={{ fontSize: 20 }}>🔔</span>
    </div>

    {/* Filter tabs — Direction C */}
    <div style={{ display: 'flex', borderBottom: `1px solid ${WF.gray1}`, padding: '0 16px' }}>
      {['Following', 'Nearby', 'Trending'].map((t, i) => (
        <div key={i} style={{
          flex: 1, textAlign: 'center', padding: '9px 0', fontSize: 14,
          borderBottom: i === 1 ? `2.5px solid ${ACCENT_D}` : 'none',
          color: i === 1 ? ACCENT_D : WF.muted,
          fontWeight: i === 1 ? 700 : 400,
        }}>{t}</div>
      ))}
    </div>

    {/* Stamp card 1 — Direction C card style */}
    <div style={{ margin: '12px 14px 0', border: `1.5px solid ${WF.stroke}`, borderRadius: 14, overflow: 'hidden' }}>
      <ImgBox h={185} label="photo · Heukbyul Coffee" />
      <div style={{ padding: '10px 12px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
          <Pill style={{ fontSize: 12 }}>📍 Heukbyul Coffee</Pill>
          <span style={{ fontSize: 11, color: WF.muted, marginLeft: 'auto' }}>2h ago</span>
        </div>
        <div style={{ fontSize: 14, lineHeight: 1.55, marginBottom: 8, fontStyle: 'italic' }}>
          "The best latte I've had in months. Stayed for 3 hours just reading."
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 26, height: 26, borderRadius: 13, background: WF.gray1 }} />
          <span style={{ fontSize: 13, color: WF.muted }}>@minjung_k</span>
          <span style={{ marginLeft: 'auto', fontSize: 14 }}>♥ 12</span>
          <span style={{ fontSize: 14 }}>💬 4</span>
        </div>
      </div>
    </div>

    {/* Stamp card 2 — partial */}
    <div style={{ margin: '10px 14px 0', border: `1.5px solid ${WF.stroke}`, borderRadius: 14, overflow: 'hidden' }}>
      <ImgBox h={95} label="photo · Han River Park" />
      <div style={{ padding: '8px 12px' }}>
        <Pill style={{ fontSize: 12 }}>📍 Han River Park</Pill>
      </div>
    </div>

    <TabBar active={1} accent={ACCENT_D} />
  </div>
);

// CHECK-IN — Direction A, unchanged
const D_Checkin = () => (
  <div style={{ width: 390, height: 844, background: WF.bg, fontFamily: 'Caveat, cursive', position: 'relative', overflow: 'hidden' }}>
    <StatusBar />
    <div style={{ position: 'relative', height: 110 }}>
      <MapBg height={110} accent={ACCENT_D} />
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.38)' }} />
    </div>
    <div style={{
      background: WF.bg,
      borderRadius: '20px 20px 0 0',
      borderTop: `1.5px solid ${WF.stroke}`,
      borderLeft: `1.5px solid ${WF.stroke}`,
      borderRight: `1.5px solid ${WF.stroke}`,
      padding: '0 20px',
      height: 844 - 44 - 110,
    }}>
      <div style={{ display: 'flex', justifyContent: 'center', padding: '12px 0' }}>
        <div style={{ width: 38, height: 4, borderRadius: 2, background: WF.gray1 }} />
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <span style={{ fontSize: 20, fontWeight: 700 }}>Add a Stamp</span>
        <span style={{ fontSize: 20, color: WF.muted }}>✕</span>
      </div>
      <SearchBar placeholder="Where are you?" style={{ marginBottom: 14 }} />
      <div style={{ padding: '10px 12px', border: `1.5px dashed ${ACCENT_D}`, borderRadius: 10, marginBottom: 14, display: 'flex', alignItems: 'center', gap: 10, background: '#F2EEF9' }}>
        <span style={{ fontSize: 18, color: ACCENT_D }}>◉</span>
        <div>
          <div style={{ fontSize: 14, fontWeight: 700 }}>Use current location</div>
          <div style={{ fontSize: 12, color: WF.muted }}>Heukbyul Coffee · 42m away</div>
        </div>
      </div>
      {[
        { name: 'Heukbyul Coffee',   dist: '42m',   icon: '☕' },
        { name: 'Han River Park',    dist: '340m',  icon: '🌿' },
        { name: 'Grand Market',      dist: '520m',  icon: '🏬' },
        { name: 'Pasta Bar Roma',    dist: '780m',  icon: '🍝' },
        { name: 'Blue Note Records', dist: '1.1km', icon: '🎵' },
      ].map((p, i) => (
        <div key={i} style={{ padding: '11px 0', borderBottom: `1px solid ${WF.gray2}`, display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ fontSize: 18, width: 26, textAlign: 'center' }}>{p.icon}</span>
          <span style={{ fontSize: 15, flex: 1 }}>{p.name}</span>
          <span style={{ fontSize: 12, color: WF.muted }}>{p.dist}</span>
          <span style={{ fontSize: 14, color: WF.muted }}>›</span>
        </div>
      ))}
    </div>
  </div>
);

// TIMELINE — Direction A, unchanged
const D_Timeline = () => (
  <div style={{ width: 390, height: 844, background: WF.bg, fontFamily: 'Caveat, cursive', position: 'relative', overflow: 'hidden' }}>
    <StatusBar />
    <div style={{ padding: '10px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
      <span style={{ fontSize: 22, fontWeight: 700 }}>Timeline</span>
      <span style={{ fontSize: 18, color: WF.muted }}>📅</span>
    </div>
    <div style={{ padding: '0 10px 12px', display: 'flex', gap: 3 }}>
      {['S','M','T','W','T','F','S'].map((d, i) => (
        <div key={i} style={{
          flex: 1, textAlign: 'center', padding: '6px 2px', borderRadius: 10,
          background: i === 5 ? ACCENT_D : 'transparent',
          color: i === 5 ? 'white' : (i === 0 || i === 6 ? WF.gray1 : WF.text),
          border: i === 5 ? `1.5px solid ${WF.stroke}` : 'none',
        }}>
          <div style={{ fontSize: 10, marginBottom: 2 }}>{d}</div>
          <div style={{ fontSize: 14, fontWeight: i === 5 ? 700 : 400 }}>{[1,2,3,4,5,6,7][i]}</div>
        </div>
      ))}
    </div>
    <div style={{ margin: '0 14px 12px', border: `1.5px solid ${WF.stroke}`, borderRadius: 14, overflow: 'hidden' }}>
      <MapBg height={200} route pins={[{ x: 100, y: 140 }, { x: 190, y: 100 }, { x: 310, y: 55 }]} accent={ACCENT_D} />
      <div style={{ padding: '7px 12px', fontSize: 13, color: WF.muted, borderTop: `1px solid ${WF.gray1}` }}>
        Jun 6 · 3.8 km · 3 stamps
      </div>
    </div>
    {[
      { time: '09:45', place: 'Heukbyul Coffee', icon: '☕' },
      { time: '13:20', place: 'Han River Park',  icon: '🌿' },
      { time: '18:50', place: 'Pasta Bar Roma',  icon: '🍝' },
    ].map((s, i) => (
      <div key={i} style={{ padding: '9px 16px', display: 'flex', alignItems: 'center', gap: 12, borderBottom: `1px solid ${WF.gray2}` }}>
        <span style={{ fontSize: 12, color: WF.muted, width: 38, flexShrink: 0 }}>{s.time}</span>
        <span style={{ fontSize: 17 }}>{s.icon}</span>
        <span style={{ fontSize: 15, flex: 1 }}>{s.place}</span>
        <ImgBox w={44} h={44} label="" style={{ borderRadius: 8, flexShrink: 0 }} />
      </div>
    ))}
    <TabBar active={3} accent={ACCENT_D} />
  </div>
);

// PROFILE — Direction A, unchanged
const D_Profile = () => (
  <div style={{ width: 390, height: 844, background: WF.bg, fontFamily: 'Caveat, cursive', position: 'relative', overflow: 'hidden' }}>
    <StatusBar />

    <div style={{ padding: '14px 18px', display: 'flex', alignItems: 'center', gap: 14, borderBottom: `1px solid ${WF.gray1}` }}>
      <div style={{ width: 58, height: 58, borderRadius: 29, background: WF.gray1, border: `2px solid ${WF.stroke}`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22, fontWeight: 700 }}>T</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 18, fontWeight: 700 }}>Taehyun P.</div>
        <div style={{ fontSize: 13, color: WF.muted }}>Seoul, Korea</div>
      </div>
      <div style={{ border: `1.5px solid ${WF.stroke}`, borderRadius: 8, padding: '5px 14px', fontSize: 13 }}>Edit</div>
    </div>

    {/* Stats — Direction A */}
    <div style={{ display: 'flex', borderBottom: `1px solid ${WF.gray1}`, padding: '14px 0' }}>
      {[['34', 'Stamps'], ['12', 'Places'], ['8', 'Friends']].map(([n, l], i) => (
        <div key={i} style={{ flex: 1, textAlign: 'center', borderRight: i < 2 ? `1px solid ${WF.gray1}` : 'none' }}>
          <div style={{ fontSize: 22, fontWeight: 700, color: ACCENT_D }}>{n}</div>
          <div style={{ fontSize: 12, color: WF.muted }}>{l}</div>
        </div>
      ))}
    </div>

    {/* Tab switch — Direction A */}
    <div style={{ display: 'flex', borderBottom: `1px solid ${WF.gray1}` }}>
      {['Stamps', 'Saved'].map((t, i) => (
        <div key={i} style={{
          flex: 1, textAlign: 'center', padding: '10px 0', fontSize: 14,
          borderBottom: i === 0 ? `2.5px solid ${ACCENT_D}` : 'none',
          color: i === 0 ? ACCENT_D : WF.muted, fontWeight: i === 0 ? 700 : 400,
        }}>{t}</div>
      ))}
    </div>

    {/* 3-col photo grid — Direction A */}
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 2 }}>
      {[...Array(12)].map((_, i) => (
        <ImgBox key={i} h={118} label="" />
      ))}
    </div>

    <TabBar active={4} accent={ACCENT_D} />
  </div>
);

Object.assign(window, { ACCENT_D, D_Concept, D_Map, D_Feed, D_Checkin, D_Timeline, D_Profile });
