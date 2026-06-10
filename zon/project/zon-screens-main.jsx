// zon-screens-main.jsx — MapScreen + FeedScreen

const { useState: useS, useRef: useR, useEffect: useE } = React;

const SHEET_COLLAPSED = 196;
const SHEET_EXPANDED  = 390;

// ── MapScreen ─────────────────────────────────────────────────────────────
const MapScreen = ({ onNavigate, fabOpen, onFab, tab, onTab }) => {
  const [category, setCategory] = useS('All');
  const [showPlacePreview, setShowPlacePreview] = useS(false);
  const [previewPlace, setPreviewPlace] = useS(null);
  const [ghostMode, setGhostMode] = useS(false);
  const [filterTab, setFilterTab] = useS('Today');
  const [sheetH, setSheetH] = useS(SHEET_COLLAPSED);
  const dragging = useR(false);
  const dragStartY = useR(0);
  const dragStartH = useR(0);

  const cats = ['All', '☕ Café', '🍴 Food', '🌿 Nature', '🎨 Art', '🏬 Retail'];
  const filterTabs = ['Today', 'Week', 'Month', 'All time', 'Saved'];

  const onHandleDown = (e) => {
    dragging.current = true;
    dragStartY.current = e.touches ? e.touches[0].clientY : e.clientY;
    dragStartH.current = sheetH;
    e.preventDefault();
  };

  useE(() => {
    const onMove = (e) => {
      if (!dragging.current) return;
      const y = e.touches ? e.touches[0].clientY : e.clientY;
      const delta = dragStartY.current - y;
      setSheetH(Math.max(130, Math.min(SHEET_EXPANDED, dragStartH.current + delta)));
    };
    const onUp = () => {
      if (!dragging.current) return;
      dragging.current = false;
      setSheetH(s => s > (SHEET_COLLAPSED + SHEET_EXPANDED) / 2 ? SHEET_EXPANDED : SHEET_COLLAPSED);
    };
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
    window.addEventListener('touchmove', onMove, { passive: false });
    window.addEventListener('touchend', onUp);
    return () => {
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('mouseup', onUp);
      window.removeEventListener('touchmove', onMove);
      window.removeEventListener('touchend', onUp);
    };
  }, []);

  const handleCluster = () => { setPreviewPlace(MOCK.nearby[0]); setShowPlacePreview(true); };
  const headerH = 44 + 58 + 50; // StatusBar + searchbar + chips

  return (
    <div style={{ width:390, height:844, background:T.surface0, position:'relative', overflow:'hidden', fontFamily:T.font }}>

      {/* Header: search + chips (elevated, z:20) */}
      <div style={{ position:'relative', zIndex:20, background:T.surface1, boxShadow:'0 2px 8px rgba(0,0,0,0.06)' }}>
        <StatusBar/>
        <div style={{ padding:'6px 12px 10px' }}>
          <SearchBar placeholder="Search places…" style={{ marginBottom:8 }} onFocus={() => {}} />
          <div style={{ display:'flex', gap:7, overflowX:'auto', paddingBottom:2 }}>
            {cats.map(c => <Pill key={c} active={category===c} onClick={() => setCategory(c)} style={{ fontSize:12, padding:'5px 12px' }}>{c}</Pill>)}
          </div>
        </div>
      </div>

      {/* Full-bleed map fills remaining space */}
      <div style={{ position:'absolute', top:headerH, bottom:0, left:0, right:0 }}>
        <MapCanvas height={844 - headerH} showRoute showClusters onClusterTap={handleCluster} onPinTap={() => {}}/>

        {/* Ghost mode */}
        <button onClick={() => setGhostMode(v => !v)} style={{ position:'absolute', top:12, right:12, width:36, height:36, borderRadius:18, background: ghostMode ? T.text : 'rgba(247,244,238,0.92)', border:`1.5px solid ${ghostMode ? T.text : T.outline}`, display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer', boxShadow:'0 2px 8px rgba(0,0,0,0.12)', zIndex:10 }}>
          <span className="material-symbols-rounded" style={{ fontSize:18, color: ghostMode ? 'white' : T.textMuted }}>visibility_off</span>
        </button>

        {/* Map legend */}
        <div style={{ position:'absolute', bottom: sheetH - 83 + 16, left:12, background:'rgba(247,244,238,0.92)', borderRadius:10, padding:'5px 10px', boxShadow:'0 2px 8px rgba(0,0,0,0.1)', display:'flex', flexDirection:'column', gap:3, transition:'bottom 0.25s ease' }}>
          {[['#8B6EC4','My stamps'],['#3B82F6','Check-ins'],['#F59E0B','Following'],['#EC4899','Stories']].map(([color,label]) => (
            <div key={label} style={{ display:'flex', alignItems:'center', gap:5 }}>
              <div style={{ width:8, height:8, borderRadius:'50%', background:color }}/>
              <span style={{ fontFamily:T.font, fontSize:10, color:T.textMuted }}>{label}</span>
            </div>
          ))}
        </div>

        {/* Summary pill — floats just above the sheet */}
        <div style={{ position:'absolute', bottom: sheetH - 83 + 12, left:0, right:0, display:'flex', justifyContent:'center', transition:'bottom 0.25s ease', zIndex:5 }}>
          <div style={{ background:'rgba(247,244,238,0.96)', border:`1.5px solid ${T.outline}`, borderRadius:9999, padding:'7px 18px', display:'flex', gap:14, alignItems:'center', boxShadow:'0 2px 10px rgba(0,0,0,0.1)', fontSize:13, fontFamily:T.font }}>
            <span>📍 3 stamps</span><span style={{ color:T.outline2 }}>·</span><span>3.8 km today</span>
          </div>
        </div>
      </div>

      {/* ── Draggable bottom sheet ──────────────────────────────────────── */}
      <div style={{
        position:'absolute', bottom:83, left:0, right:0,
        height: sheetH,
        background: T.surface1,
        borderRadius:'24px 24px 0 0',
        boxShadow:'0 -4px 20px rgba(0,0,0,0.10)',
        display:'flex', flexDirection:'column',
        zIndex:30,
        transition: dragging.current ? 'none' : 'height 0.28s cubic-bezier(0.32,0.72,0,1)',
        overflow:'hidden',
      }}>
        {/* Drag handle */}
        <div
          onMouseDown={onHandleDown} onTouchStart={onHandleDown}
          onClick={() => setSheetH(h => h > SHEET_COLLAPSED + 40 ? SHEET_COLLAPSED : SHEET_EXPANDED)}
          style={{ padding:'10px 0 4px', display:'flex', justifyContent:'center', cursor:'ns-resize', flexShrink:0 }}>
          <div style={{ width:40, height:4, borderRadius:2, background:T.outline2 }}/>
        </div>

        {/* Filter chips */}
        <div style={{ display:'flex', gap:6, padding:'4px 14px 8px', overflowX:'auto', flexShrink:0 }}>
          {filterTabs.map(f => <Pill key={f} active={filterTab===f} onClick={() => setFilterTab(f)} style={{ fontSize:11, padding:'4px 10px' }}>{f}</Pill>)}
        </div>

        {/* Scrollable content */}
        <div style={{ flex:1, overflowY:'auto' }}>
          <SectionHeader title="Nearby" action="See all →" onAction={() => setSheetH(h => h > SHEET_COLLAPSED + 40 ? SHEET_COLLAPSED : SHEET_EXPANDED)}/>
          <div style={{ display:'flex', gap:10, padding:'0 12px 16px', overflowX:'auto' }}>
            {MOCK.nearby.map(p => <NearbyCard key={p.id} place={p} onTap={() => onNavigate('place-detail', { placeId: p.id })}/>)}
          </div>

          {sheetH > SHEET_COLLAPSED + 60 && (
            <div style={{ padding:'0 14px 20px' }}>
              <div style={{ fontFamily:T.font, fontSize:13, fontWeight:700, color:T.textMuted, marginBottom:10, textTransform:'uppercase', letterSpacing:'0.05em' }}>Trending nearby</div>
              {[
                { name:'Heukbyul Coffee', category:'Café',    stamps:7,  score:'🔥 Hot',   dist:'42m' },
                { name:'Grand Market',    category:'Retail',  stamps:12, score:'⬆ Rising', dist:'520m' },
                { name:'Pasta Bar Roma',  category:'Dining',  stamps:5,  score:'New',      dist:'780m' },
              ].map((p,i) => (
                <div key={i} style={{ display:'flex', alignItems:'center', padding:'11px 0', borderBottom:`1px solid ${T.outline}` }}>
                  <div style={{ flex:1 }}>
                    <div style={{ fontFamily:T.font, fontSize:14, fontWeight:700, color:T.text }}>{p.name}</div>
                    <div style={{ fontFamily:T.font, fontSize:12, color:T.textMuted, marginTop:2 }}>{p.category} · {p.dist} · {p.stamps} stamps</div>
                  </div>
                  <span style={{ fontFamily:T.font, fontSize:12, fontWeight:600, color:T.brand, background:T.brandSoft, borderRadius:9999, padding:'3px 10px' }}>{p.score}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Place preview card */}
      {showPlacePreview && previewPlace && (
        <>
          <div onClick={() => setShowPlacePreview(false)} style={{ position:'absolute', inset:0, zIndex:49 }}/>
          <div style={{ position:'absolute', bottom: sheetH + 83 + 8, left:14, right:14, zIndex:50, animation:'slideUp 0.22s ease-out' }}>
            <div style={{ background:T.surface1, borderRadius:20, padding:16, boxShadow:'0 8px 28px rgba(0,0,0,0.14)' }}>
              <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:10 }}>
                <div>
                  <h3 style={{ fontFamily:T.font, fontSize:17, fontWeight:700, color:T.text, margin:0, marginBottom:3 }}>{previewPlace.name}</h3>
                  <div style={{ display:'flex', gap:6 }}><span style={{ fontFamily:T.font, fontSize:13, color:T.textMuted }}>{previewPlace.category}</span><span style={{ color:T.outline2 }}>·</span><span style={{ fontFamily:T.font, fontSize:13, color:T.textMuted }}>{previewPlace.dist}</span></div>
                </div>
                <span style={{ fontSize:26 }}>{previewPlace.emoji}</span>
              </div>
              <div style={{ display:'flex', gap:8 }}>
                <button onClick={() => { setShowPlacePreview(false); onNavigate('place-detail', { placeId: previewPlace.id }); }} style={{ flex:1, height:42, borderRadius:12, border:`1.5px solid ${T.brand}`, background:'none', color:T.brand, fontFamily:T.font, fontSize:14, fontWeight:600, cursor:'pointer' }}>View place</button>
                <button onClick={() => { setShowPlacePreview(false); onNavigate('checkin'); }} style={{ flex:1, height:42, borderRadius:12, background:T.brand, border:'none', color:'white', fontFamily:T.font, fontSize:14, fontWeight:600, cursor:'pointer' }}>Check in</button>
              </div>
            </div>
          </div>
        </>
      )}

      <FabMenu open={fabOpen} onClose={onFab} onNavigate={onNavigate}/>
      <TabBar active={tab} onTab={onTab} fabOpen={fabOpen} onFab={onFab}/>
    </div>
  );
};

// ── FeedScreen ────────────────────────────────────────────────────────────
const FeedScreen = ({ onNavigate, fabOpen, onFab, tab, onTab }) => {
  const [feedTab, setFeedTab] = useS('Nearby');
  const feedTabs = ['Following', 'Nearby', 'Trending'];

  return (
    <div style={{ width: 390, height: 844, background: T.surface0, position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column', fontFamily: T.font }}>
      <div style={{ background: T.surface1, flexShrink: 0 }}>
        <StatusBar />
        {/* AppBar */}
        <div style={{ padding: '0 6px 0 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: 48 }}>
          <span style={{ fontSize: 24, fontWeight: 900, letterSpacing: 1.5, color: T.text }}>ZON</span>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <button onClick={() => onNavigate('user-search')} style={{ width: 44, height: 44, borderRadius: 22, background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 24, color: T.text }}>search</span>
            </button>
            <button onClick={() => onNavigate('activity')} style={{ width: 44, height: 44, borderRadius: 22, background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 24, color: T.text }}>notifications</span>
              <div style={{ position: 'absolute', top: 8, right: 8, width: 8, height: 8, borderRadius: 4, background: T.error, border: `1.5px solid ${T.surface1}` }}/>
            </button>
          </div>
        </div>

        {/* Filter tabs — Direction C */}
        <div style={{ display: 'flex', borderBottom: `1px solid ${T.outline}` }}>
          {feedTabs.map(t => (
            <button key={t} onClick={() => setFeedTab(t)} style={{ flex: 1, textAlign: 'center', padding: '10px 0', fontFamily: T.font, fontSize: 14, fontWeight: feedTab === t ? 700 : 400, color: feedTab === t ? T.brand : T.textMuted, background: 'none', border: 'none', cursor: 'pointer', borderBottom: feedTab === t ? `2.5px solid ${T.brand}` : '2.5px solid transparent', transition: 'all 0.15s' }}>{t}</button>
          ))}
        </div>
      </div>

      {/* Scrollable content */}
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 83 }}>
        <StoriesRail stories={MOCK.stories} onStoryTap={() => onNavigate('story-viewer')} />

        <div style={{ padding: '14px 14px 0' }}>
          {MOCK.stamps.map(s => (
            <StampCard key={s.id} stamp={s} onTap={() => onNavigate('stamp-detail', { stampId: s.id })} />
          ))}
        </div>
      </div>

      <FabMenu open={fabOpen} onClose={onFab} onNavigate={onNavigate} />
      <TabBar active={tab} onTab={onTab} fabOpen={fabOpen} onFab={onFab} />
    </div>
  );
};

Object.assign(window, { MapScreen, FeedScreen });
