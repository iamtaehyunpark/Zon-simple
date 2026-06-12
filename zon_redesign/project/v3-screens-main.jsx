// v3-screens-main.jsx — MapScreen + FeedScreen

const { useState: useS, useRef: useR, useEffect: useE } = React;

const SHEET_COLLAPSED = 196;
const SHEET_EXPANDED = 390;

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
      setSheetH((s) => s > (SHEET_COLLAPSED + SHEET_EXPANDED) / 2 ? SHEET_EXPANDED : SHEET_COLLAPSED);
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

  const headerH = 44 + 58 + 50;

  return (
    <div style={{ width: 390, height: 844, background: T.surface0, position: 'relative', overflow: 'hidden', fontFamily: T.font }}>

      {/* Header: search + chips */}
      <div style={{ position: 'relative', zIndex: 20, background: T.surface1, boxShadow: '0 1px 0 rgba(0,0,0,0.06)' }}>
        <StatusBar />
        <div style={{ padding: '6px 14px 10px' }}>
          <SearchBar placeholder="Search places, areas…" style={{ marginBottom: 8 }} onFocus={() => {}} />
          <div style={{ display: 'flex', gap: 7, overflowX: 'auto', paddingBottom: 2 }}>
            {cats.map((c) => <Pill key={c} active={category === c} onClick={() => setCategory(c)} style={{ fontSize: 11, padding: '4px 12px' }}>{c}</Pill>)}
          </div>
        </div>
      </div>

      {/* Map */}
      <div style={{ position: 'absolute', top: headerH, bottom: 0, left: 0, right: 0 }}>
        <MapCanvas height={844 - headerH} showRoute showClusters
        onClusterTap={() => {setPreviewPlace(MOCK.nearby[0]);setShowPlacePreview(true);}}
        onPinTap={() => {}} />

        {/* Ghost mode */}
        <button onClick={() => setGhostMode((v) => !v)} style={{ position: 'absolute', top: 12, right: 12, width: 38, height: 38, borderRadius: 19, background: ghostMode ? T.text : 'rgba(255,255,255,0.94)', border: `1px solid ${ghostMode ? T.text : T.outline2}`, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', boxShadow: '0 2px 8px rgba(0,0,0,0.10)', zIndex: 10 }}>
          <span className="material-symbols-rounded" style={{ fontSize: 18, color: ghostMode ? 'white' : T.textMuted }}>visibility_off</span>
        </button>

        {/* Map legend — minimal, bottom-left */}
        <div style={{ position: 'absolute', bottom: sheetH - 83 + 12, left: 12, background: 'rgba(255,255,255,0.94)', borderRadius: 10, padding: '6px 10px', boxShadow: '0 1px 6px rgba(0,0,0,0.08)', display: 'flex', flexDirection: 'column', gap: 3, transition: 'bottom 0.25s ease' }}>
          {[['#8B6EC4', 'My stamps'], ['#3B82F6', 'Check-ins'], ['#F59E0B', 'Following'], ['#EC4899', 'Stories']].map(([color, label]) =>
          <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
              <div style={{ width: 7, height: 7, borderRadius: '50%', background: color }} />
              <span style={{ fontFamily: T.font, fontSize: 10, color: T.textMuted }}>{label}</span>
            </div>
          )}
        </div>

        {/* Summary pill */}
        <div style={{ position: 'absolute', bottom: sheetH - 83 + 10, left: 0, right: 0, display: 'flex', justifyContent: 'center', transition: 'bottom 0.25s ease', zIndex: 5 }}>
          <div style={{ background: 'rgba(255,255,255,0.96)', border: `1px solid ${T.outline}`, borderRadius: 9999, padding: '7px 18px', display: 'flex', gap: 12, alignItems: 'center', boxShadow: '0 2px 10px rgba(0,0,0,0.08)', fontSize: 12, fontFamily: T.font, fontWeight: 500 }}>
            <span>📍 3 stamps</span>
            <span style={{ color: T.outline2 }}>·</span>
            <span style={{ color: T.textMuted }}>3.8 km today</span>
          </div>
        </div>
      </div>

      {/* Draggable bottom sheet */}
      <div style={{
        position: 'absolute', bottom: 83, left: 0, right: 0, height: sheetH,
        background: T.surface1, borderRadius: '20px 20px 0 0',
        boxShadow: '0 -2px 16px rgba(0,0,0,0.08)',
        display: 'flex', flexDirection: 'column', zIndex: 30,
        transition: dragging.current ? 'none' : 'height 0.28s cubic-bezier(0.32,0.72,0,1)',
        overflow: 'hidden'
      }}>
        <div onMouseDown={onHandleDown} onTouchStart={onHandleDown}
        onClick={() => setSheetH((h) => h > SHEET_COLLAPSED + 40 ? SHEET_COLLAPSED : SHEET_EXPANDED)}
        style={{ padding: '10px 0 4px', display: 'flex', justifyContent: 'center', cursor: 'ns-resize', flexShrink: 0 }}>
          <div style={{ width: 36, height: 4, borderRadius: 2, background: T.outline2 }} />
        </div>

        {/* Filter pills */}
        <div style={{ display: 'flex', gap: 6, padding: '4px 14px 8px', overflowX: 'auto', flexShrink: 0 }}>
          {filterTabs.map((f) => <Pill key={f} active={filterTab === f} onClick={() => setFilterTab(f)} style={{ fontSize: 11, padding: '4px 10px' }}>{f}</Pill>)}
        </div>

        {/* Scrollable content */}
        <div style={{ flex: 1, overflowY: 'auto' }}>
          <SectionHeader title="Nearby" action="See all" onAction={() => setSheetH(SHEET_EXPANDED)} />
          <div style={{ display: 'flex', gap: 10, padding: '0 14px 16px', overflowX: 'auto' }}>
            {MOCK.nearby.map((p) =>
            <NearbyCard key={p.id} place={p} onTap={() => onNavigate('place-detail', { placeId: p.id })} />
            )}
          </div>

          {sheetH > SHEET_COLLAPSED + 60 &&
          <div style={{ padding: '0 14px 20px' }}>
              {/* Section header — Naver-style with live indicator */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                <div style={{ fontFamily: T.font, fontSize: 14, fontWeight: 700, color: T.text }}>Trending in this Street</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                  <div style={{ width: 6, height: 6, borderRadius: 3, background: '#EF4444' }} />
                  <span style={{ fontFamily: T.font, fontSize: 10, color: T.textMuted, fontWeight: 500 }}>Live · 3 min ago</span>
                </div>
              </div>

              {/* 2-column photo grid — Naver Map style */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                {[
              { name: 'Heukbyul Coffee', category: 'Café', dist: '42m', score: '🔥 Hot', imgColor: '#D0C8CC' },
              { name: 'Grand Market', category: 'Retail', dist: '520m', score: '⬆ Rising', imgColor: '#C8C8C8' },
              { name: 'Pasta Bar Roma', category: 'Dining', dist: '780m', score: 'New', imgColor: '#CCC8C0' },
              { name: 'Blue Note Records', category: 'Music', dist: '1.1km', score: '⬆ Rising', imgColor: '#C0C4CC' }].
              map((p, i) =>
              <div key={i}
              onClick={() => onNavigate('place-detail', { placeId: 'p1' })}
              style={{ position: 'relative', borderRadius: 12, overflow: 'hidden', cursor: 'pointer' }}>
                    {/* Photo */}
                    <ImgPlaceholder height={152} color={p.imgColor} />
                    {/* Gradient scrim */}
                    <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to bottom, rgba(0,0,0,0.22) 0%, transparent 38%, rgba(0,0,0,0.68) 80%)' }} />
                    {/* Rank number */}
                    <div style={{ position: 'absolute', top: 7, left: 9, fontFamily: T.font, fontSize: 30, fontWeight: 800, color: 'white', lineHeight: 1 }}>{i + 1}</div>
                    {/* Score badge */}
                    <div style={{ position: 'absolute', top: 8, right: 8, background: 'rgba(0,0,0,0.38)', borderRadius: 9999, padding: '2px 7px' }}>
                      <span style={{ fontFamily: T.font, fontSize: 10, fontWeight: 600, color: 'white' }}>{p.score}</span>
                    </div>
                    {/* Place info */}
                    <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '0 9px 9px' }}>
                      <div style={{ fontFamily: T.font, fontSize: 12, fontWeight: 700, color: 'white', lineHeight: 1.3, marginBottom: 2 }}>{p.name}</div>
                      <div style={{ fontFamily: T.font, fontSize: 10, color: 'rgba(255,255,255,0.75)' }}>{p.category} · {p.dist}</div>
                    </div>
                  </div>
              )}
              </div>
            </div>
          }
        </div>
      </div>

      {/* Place preview card */}
      {showPlacePreview && previewPlace &&
      <>
          <div onClick={() => setShowPlacePreview(false)} style={{ position: 'absolute', inset: 0, zIndex: 49 }} />
          <div style={{ position: 'absolute', bottom: sheetH + 83 + 8, left: 14, right: 14, zIndex: 50, animation: 'slideUp 0.2s ease-out' }}>
            <div style={{ background: T.surface1, borderRadius: 18, padding: 16, boxShadow: '0 8px 28px rgba(0,0,0,0.12)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
                <div>
                  <h3 style={{ fontFamily: T.font, fontSize: 16, fontWeight: 700, color: T.text, margin: 0, marginBottom: 3 }}>{previewPlace.name}</h3>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <span style={{ fontFamily: T.font, fontSize: 12, color: T.textMuted }}>{previewPlace.category}</span>
                    <span style={{ color: T.outline2 }}>·</span>
                    <span style={{ fontFamily: T.font, fontSize: 12, color: T.textMuted }}>{previewPlace.dist}</span>
                  </div>
                </div>
                <span style={{ fontSize: 24 }}>{previewPlace.emoji}</span>
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                <button onClick={() => {setShowPlacePreview(false);onNavigate('place-detail', { placeId: previewPlace.id });}} style={{ flex: 1, height: 40, borderRadius: 10, border: `1px solid ${T.outline2}`, background: 'none', color: T.text, fontFamily: T.font, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>View place</button>
                <button onClick={() => {setShowPlacePreview(false);onNavigate('checkin');}} style={{ flex: 1, height: 40, borderRadius: 10, background: T.brand, border: 'none', color: 'white', fontFamily: T.font, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Check in</button>
              </div>
            </div>
          </div>
        </>
      }

      <FabMenu open={fabOpen} onClose={onFab} onNavigate={onNavigate} />
      <TabBar active={tab} onTab={onTab} fabOpen={fabOpen} onFab={onFab} />
    </div>);

};

// ── FeedScreen ────────────────────────────────────────────────────────────
const FeedScreen = ({ onNavigate, fabOpen, onFab, tab, onTab }) => {
  const [feedTab, setFeedTab] = useS('Following');
  const feedTabs = ['Following', 'Nearby', 'Trending'];

  return (
    <div style={{ width: 390, height: 844, background: T.surface0, position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column', fontFamily: T.font }}>
      <div style={{ background: T.surface1, flexShrink: 0 }}>
        <StatusBar />
        {/* AppBar — ZON wordmark in pure black */}
        <div style={{ padding: '0 6px 0 18px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: 48 }}>
          <span style={{ fontSize: 22, fontWeight: 900, letterSpacing: 2, color: T.text, fontFamily: T.font }}>ZON</span>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <button onClick={() => onNavigate('user-search')} style={{ width: 44, height: 44, borderRadius: 22, background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 22, color: T.text }}>search</span>
            </button>
            <button onClick={() => onNavigate('activity')} style={{ width: 44, height: 44, borderRadius: 22, background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 22, color: T.text }}>notifications</span>
              <div style={{ position: 'absolute', top: 9, right: 9, width: 7, height: 7, borderRadius: 4, background: '#EF4444', border: `1.5px solid ${T.surface1}` }} />
            </button>
          </div>
        </div>

        {/* Filter tabs */}
        <div style={{ display: 'flex', borderBottom: `0.5px solid ${T.outline}` }}>
          {feedTabs.map((t) =>
          <button key={t} onClick={() => setFeedTab(t)} style={{ flex: 1, textAlign: 'center', padding: '10px 0', fontFamily: T.font, fontSize: 13, fontWeight: feedTab === t ? 600 : 400, color: feedTab === t ? T.text : T.textMuted, background: 'none', border: 'none', cursor: 'pointer', borderBottom: feedTab === t ? `2px solid ${T.text}` : '2px solid transparent', transition: 'all 0.15s' }}>
              {t}
            </button>
          )}
        </div>
      </div>

      {/* Scrollable */}
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 83 }}>
        <StoriesRail stories={MOCK.stories} onStoryTap={() => onNavigate('story-viewer')} />
        <div style={{ padding: '10px 12px 0' }}>
          {MOCK.stamps.map((s) =>
          <StampCard key={s.id} stamp={s} onTap={() => onNavigate('stamp-detail', { stampId: s.id })} />
          )}
        </div>
      </div>

      <FabMenu open={fabOpen} onClose={onFab} onNavigate={onNavigate} />
      <TabBar active={tab} onTab={onTab} fabOpen={fabOpen} onFab={onFab} />
    </div>);

};

Object.assign(window, { MapScreen, FeedScreen });