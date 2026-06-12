// v3-screens-modal.jsx — CheckInSheet, PlaceDetailScreen, StampDetailScreen, StoryViewer

// ── CheckInSheet ──────────────────────────────────────────────────────────
const CheckInSheet = ({ onNavigate, onClose }) => {
  const [step, setStep] = React.useState('search');
  const [selectedPlace, setSelectedPlace] = React.useState(null);
  const [note, setNote] = React.useState('');
  const [shareStory, setShareStory] = React.useState(false);

  const nearby = [
  { id: 'p1', name: 'Heukbyul Coffee', emoji: '☕', dist: '42m' },
  { id: 'p2', name: 'Han River Park', emoji: '🌿', dist: '340m' },
  { id: 'p3', name: 'Grand Market', emoji: '🏬', dist: '520m' },
  { id: 'p4', name: 'Pasta Bar Roma', emoji: '🍝', dist: '780m' },
  { id: 'p5', name: 'Blue Note Records', emoji: '🎵', dist: '1.1km' }];

  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 200, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', fontFamily: T.font }}>
      <div onClick={onClose} style={{ flex: 1, position: 'relative' }}>
        <MapCanvas height={180} showRoute showClusters={false} />
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.22)' }} />
      </div>
      <div style={{ background: T.surface1, borderRadius: '20px 20px 0 0', boxShadow: '0 -4px 24px rgba(0,0,0,0.10)', maxHeight: '72vh', display: 'flex', flexDirection: 'column' }}>
        <BottomHandle />
        {step === 'search' && <>
          <div style={{ padding: '0 20px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontFamily: T.font, fontSize: 18, fontWeight: 700, color: T.text }}>Check in</span>
            <button onClick={onClose} style={{ width: 30, height: 30, borderRadius: 15, background: T.surface2, border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 17, color: T.textMuted }}>close</span>
            </button>
          </div>
          <div style={{ padding: '0 16px 10px' }}>
            <SearchBar placeholder="Where are you?" style={{ marginBottom: 10 }} />
            <div onClick={() => { setSelectedPlace({ name: 'Heukbyul Coffee', emoji: '☕' }); setStep('editor'); }}
              style={{ padding: '11px 14px', border: `1.5px dashed ${T.brand}`, borderRadius: 12, marginBottom: 10, display: 'flex', alignItems: 'center', gap: 12, background: T.brandSoft2, cursor: 'pointer' }}>
              <div style={{ width: 36, height: 36, borderRadius: 18, background: T.brand, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <span className="material-symbols-rounded" style={{ fontSize: 20, color: 'white', fontVariationSettings: "'FILL' 1" }}>my_location</span>
              </div>
              <div>
                <div style={{ fontFamily: T.font, fontSize: 14, fontWeight: 600, color: T.text }}>Use current location</div>
                <div style={{ fontFamily: T.font, fontSize: 12, color: T.textMuted }}>Heukbyul Coffee · 42m away</div>
              </div>
            </div>
          </div>
          <div style={{ overflowY: 'auto', flex: 1, paddingBottom: 20 }}>
            {nearby.map((p) =>
              <div key={p.id} onClick={() => { setSelectedPlace(p); setStep('editor'); }}
                style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12, borderBottom: `0.5px solid ${T.outline}`, cursor: 'pointer' }}>
                <span style={{ fontSize: 20, width: 28, textAlign: 'center' }}>{p.emoji}</span>
                <span style={{ fontFamily: T.font, fontSize: 14, flex: 1, color: T.text, fontWeight: 500 }}>{p.name}</span>
                <span style={{ fontFamily: T.font, fontSize: 12, color: T.textMuted }}>{p.dist}</span>
                <span className="material-symbols-rounded" style={{ fontSize: 17, color: T.textFaint }}>chevron_right</span>
              </div>
            )}
          </div>
        </>}
        {step === 'editor' && selectedPlace && <>
          <div style={{ padding: '0 20px 12px', display: 'flex', alignItems: 'center', gap: 8 }}>
            <BackButton onBack={() => setStep('search')} />
            <div style={{ fontFamily: T.font, fontSize: 16, fontWeight: 700, color: T.text }}>{selectedPlace.emoji} {selectedPlace.name}</div>
          </div>
          <div style={{ overflowY: 'auto', flex: 1, padding: '0 16px 16px' }}>
            <textarea value={note} onChange={(e) => setNote(e.target.value)} placeholder="Add a note (optional)…"
              style={{ width: '100%', minHeight: 80, border: `1px solid ${T.outline2}`, borderRadius: 12, padding: '12px 14px', fontFamily: T.font, fontSize: 13, color: T.text, background: T.surface2, resize: 'none', outline: 'none', lineHeight: 1.55, boxSizing: 'border-box', marginBottom: 14 }} />
            <div style={{ marginBottom: 14 }}>
              <div style={{ fontFamily: T.font, fontSize: 13, fontWeight: 600, color: T.text, marginBottom: 8 }}>Photos</div>
              <div style={{ display: 'flex', gap: 8 }}>
                <div style={{ width: 72, height: 72, borderRadius: 10, background: T.surface2, border: `1px dashed ${T.outline2}`, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
                  <span className="material-symbols-rounded" style={{ fontSize: 22, color: T.textFaint }}>add_photo_alternate</span>
                </div>
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 0', borderTop: `0.5px solid ${T.outline}`, marginBottom: 16 }}>
              <div>
                <div style={{ fontFamily: T.font, fontSize: 14, fontWeight: 600, color: T.text }}>Share as story</div>
                <div style={{ fontFamily: T.font, fontSize: 11, color: T.textMuted }}>Visible to friends for 24h</div>
              </div>
              <div onClick={() => setShareStory((v) => !v)}
                style={{ width: 46, height: 26, borderRadius: 13, background: shareStory ? T.brand : T.surface3, cursor: 'pointer', position: 'relative', transition: 'background 0.2s', flexShrink: 0 }}>
                <div style={{ position: 'absolute', top: 3, left: shareStory ? 23 : 3, width: 20, height: 20, borderRadius: 10, background: 'white', boxShadow: '0 1px 3px rgba(0,0,0,0.18)', transition: 'left 0.2s' }} />
              </div>
            </div>
            <button onClick={() => setStep('confirm')}
              style={{ width: '100%', height: 50, borderRadius: 14, background: T.brand, border: 'none', color: 'white', fontFamily: T.font, fontSize: 15, fontWeight: 700, cursor: 'pointer', boxShadow: `0 4px 14px rgba(139,110,196,0.32)` }}>
              Save Check-in
            </button>
          </div>
        </>}
        {step === 'confirm' && <>
          <div style={{ padding: '24px 24px 28px', textAlign: 'center' }}>
            <div style={{ width: 64, height: 64, borderRadius: 32, background: T.brandSoft, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 14px' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 34, color: T.brand, fontVariationSettings: "'FILL' 1" }}>check_circle</span>
            </div>
            <div style={{ fontFamily: T.font, fontSize: 20, fontWeight: 700, color: T.text, marginBottom: 5 }}>Checked in!</div>
            <div style={{ fontFamily: T.font, fontSize: 13, color: T.textMuted, marginBottom: 24 }}>{selectedPlace?.emoji} {selectedPlace?.name}</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <button onClick={() => { onNavigate('stamp-editor'); onClose(); }} style={{ height: 48, borderRadius: 14, background: T.brand, border: 'none', color: 'white', fontFamily: T.font, fontSize: 14, fontWeight: 700, cursor: 'pointer' }}>Make it a stamp →</button>
              <button onClick={() => { onNavigate('timeline'); onClose(); }} style={{ height: 48, borderRadius: 14, background: 'none', border: `1px solid ${T.outline2}`, color: T.text, fontFamily: T.font, fontSize: 14, fontWeight: 500, cursor: 'pointer' }}>View in Timeline</button>
              <button onClick={onClose} style={{ height: 38, background: 'none', border: 'none', color: T.textMuted, fontFamily: T.font, fontSize: 13, cursor: 'pointer' }}>Done</button>
            </div>
          </div>
        </>}
      </div>
    </div>
  );
};

// ── PlaceDetailScreen — v3.1 (Naver Map-style collapsible) ─────────────────
// 3 snap states:
//   COLLAPSED (~110px) — map is main, tiny name strip
//   DEFAULT   (~330px) — map peeking above, name + actions visible
//   FULL      (~780px) — full place page, map behind
// Back btn on map (non-full) / chevron-down inside sheet (full)
// Photos moved below ZON Activity per design feedback
const PLACE_COLLAPSED = 110;
const PLACE_DEFAULT   = 330;
const PLACE_FULL      = 778;

const PlaceDetailScreen = ({ onNavigate, params = {} }) => {
  const place = MOCK.places[params.placeId] || MOCK.places.p1;
  const [sheetH,    setSheetH]    = React.useState(PLACE_DEFAULT);
  const [activeTab, setActiveTab] = React.useState('overview');
  const isDragging = React.useRef(false);
  const dragY0     = React.useRef(0);
  const dragH0     = React.useRef(0);

  React.useEffect(() => {
    const onMove = (e) => {
      if (!isDragging.current) return;
      const y = e.touches ? e.touches[0].clientY : e.clientY;
      setSheetH(Math.max(80, Math.min(PLACE_FULL, dragH0.current + (dragY0.current - y))));
    };
    const onUp = () => {
      if (!isDragging.current) return;
      isDragging.current = false;
      setSheetH((h) => {
        const snaps = [PLACE_COLLAPSED, PLACE_DEFAULT, PLACE_FULL];
        return snaps.reduce((a, b) => Math.abs(b - h) < Math.abs(a - h) ? b : a);
      });
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

  const onHandleDown = (e) => {
    isDragging.current = true;
    dragY0.current = e.touches ? e.touches[0].clientY : e.clientY;
    dragH0.current = sheetH;
    e.preventDefault();
  };
  const cycleSheet = () => {
    if (sheetH <= PLACE_COLLAPSED + 60) setSheetH(PLACE_DEFAULT);
    else if (sheetH <= PLACE_DEFAULT + 60) setSheetH(PLACE_FULL);
    else setSheetH(PLACE_DEFAULT);
  };

  const isCollapsed = sheetH < PLACE_COLLAPSED + 60;
  const isFull      = sheetH > PLACE_FULL - 60;
  const transition  = isDragging.current ? 'none' : 'height 0.3s cubic-bezier(0.32,0.72,0,1)';

  return (
    <div style={{ width: 390, height: 844, position: 'relative', overflow: 'hidden', fontFamily: T.font }}>

      {/* ── Full-bleed map background ── */}
      <MapCanvas height={844} showRoute={false} showClusters={false} mini={false} />

      {/* Map overlay: back + save + close — hidden when full */}
      {!isFull && (
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 10 }}>
          <StatusBar />
          <div style={{ padding: '2px 12px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <button onClick={() => onNavigate('back')}
              style={{ width: 40, height: 40, borderRadius: 20, background: 'rgba(255,255,255,0.96)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 2px 8px rgba(0,0,0,0.14)' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 22, color: T.text }}>arrow_back</span>
            </button>
            <div style={{ display: 'flex', gap: 8 }}>
              <button style={{ width: 40, height: 40, borderRadius: 20, background: 'rgba(255,255,255,0.96)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 2px 8px rgba(0,0,0,0.14)' }}>
                <span className="material-symbols-rounded" style={{ fontSize: 20, color: T.text }}>bookmark_border</span>
              </button>
              <button onClick={() => onNavigate('back')}
                style={{ width: 40, height: 40, borderRadius: 20, background: 'rgba(255,255,255,0.96)', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 2px 8px rgba(0,0,0,0.14)' }}>
                <span className="material-symbols-rounded" style={{ fontSize: 20, color: T.text }}>close</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Place pin on map — floats above sheet */}
      <div style={{ position: 'absolute', bottom: sheetH + 10, left: '50%', transform: 'translateX(-50%)', display: 'flex', flexDirection: 'column', alignItems: 'center', transition: `bottom ${transition}`, pointerEvents: 'none', zIndex: 5 }}>
        <div style={{ width: 42, height: 42, borderRadius: '50% 50% 50% 0', transform: 'rotate(-45deg)', background: T.brand, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: `0 4px 14px rgba(139,110,196,0.45)` }}>
          <span className="material-symbols-rounded" style={{ fontSize: 20, color: 'white', transform: 'rotate(45deg)', fontVariationSettings: "'FILL' 1" }}>storefront</span>
        </div>
        <div style={{ width: 6, height: 6, borderRadius: 3, background: T.brand, opacity: 0.35, marginTop: 2 }} />
      </div>

      {/* ── Collapsible bottom sheet ── */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        height: sheetH, background: T.surface1,
        borderRadius: isFull ? 0 : '20px 20px 0 0',
        boxShadow: '0 -4px 24px rgba(0,0,0,0.10)',
        display: 'flex', flexDirection: 'column',
        transition, overflow: 'hidden', zIndex: 40,
      }}>

        {/* Drag handle */}
        <div onMouseDown={onHandleDown} onTouchStart={onHandleDown} onClick={cycleSheet}
          style={{ padding: '10px 0 6px', display: 'flex', justifyContent: 'center', cursor: 'ns-resize', flexShrink: 0 }}>
          <div style={{ width: 36, height: 4, borderRadius: 2, background: T.outline2 }} />
        </div>

        {/* Fixed header — always visible */}
        <div style={{ padding: '2px 16px 14px', flexShrink: 0 }}>

          {/* Full-state top bar: chevron-down + save + close */}
          {isFull && (
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: 10, marginLeft: -8 }}>
              <button onClick={() => setSheetH(PLACE_DEFAULT)}
                style={{ width: 36, height: 36, borderRadius: 18, background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <span className="material-symbols-rounded" style={{ fontSize: 24, color: T.text }}>keyboard_arrow_down</span>
              </button>
              <div style={{ flex: 1 }} />
              <button style={{ width: 36, height: 36, borderRadius: 18, background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <span className="material-symbols-rounded" style={{ fontSize: 22, color: T.text }}>bookmark_border</span>
              </button>
              <button onClick={() => onNavigate('back')}
                style={{ width: 36, height: 36, borderRadius: 18, background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <span className="material-symbols-rounded" style={{ fontSize: 22, color: T.text }}>close</span>
              </button>
            </div>
          )}

          {/* Place identity */}
          <div style={{ fontFamily: T.font, fontSize: 21, fontWeight: 700, color: T.text, lineHeight: 1.2, marginBottom: 4 }}>{place.name}</div>
          {!isCollapsed && (
            <div style={{ fontFamily: T.font, fontSize: 13, color: T.textMuted, marginBottom: 14 }}>
              {place.category} · {place.dist} · <span style={{ color: T.brand, fontWeight: 600 }}>{place.stamps} stamps</span>
            </div>
          )}

          {/* Action buttons — hidden when collapsed */}
          {!isCollapsed && (
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              <button style={{ height: 38, padding: '0 16px', borderRadius: 9999, border: `1px solid ${T.outline2}`, background: 'none', fontFamily: T.font, fontSize: 13, fontWeight: 500, color: T.text, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 5 }}>
                <span className="material-symbols-rounded" style={{ fontSize: 14, color: T.textMuted }}>near_me</span>Go
              </button>
              <button onClick={() => onNavigate('checkin')}
                style={{ height: 38, padding: '0 18px', borderRadius: 9999, background: T.brand, border: 'none', fontFamily: T.font, fontSize: 13, fontWeight: 600, color: 'white', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 5 }}>
                <span className="material-symbols-rounded" style={{ fontSize: 14, fontVariationSettings: "'FILL' 1" }}>location_on</span>Check in
              </button>
              <button style={{ width: 38, height: 38, borderRadius: 9999, border: `1px solid ${T.outline2}`, background: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
                <span className="material-symbols-rounded" style={{ fontSize: 18, color: T.textMuted }}>ios_share</span>
              </button>
            </div>
          )}
        </div>

        {/* Scrollable content — visible when near default or full */}
        {sheetH > PLACE_DEFAULT - 30 && (
          <div style={{ flex: 1, overflowY: 'auto', borderTop: `0.5px solid ${T.outline}` }}>

            {/* Tab bar */}
            <div style={{ display: 'flex', borderBottom: `0.5px solid ${T.outline}`, background: T.surface1, position: 'sticky', top: 0, zIndex: 2 }}>
              {['overview', 'stamps', 'photos'].map((t) =>
                <button key={t} onClick={() => setActiveTab(t)}
                  style={{ flex: 1, textAlign: 'center', padding: '10px 0', fontFamily: T.font, fontSize: 12, fontWeight: activeTab === t ? 600 : 400, color: activeTab === t ? T.text : T.textMuted, background: 'none', border: 'none', cursor: 'pointer', borderBottom: activeTab === t ? `2px solid ${T.text}` : '2px solid transparent', textTransform: 'capitalize', transition: 'all 0.15s' }}>
                  {t.charAt(0).toUpperCase() + t.slice(1)}
                </button>
              )}
            </div>

            {activeTab === 'overview' && <>
              {/* Place info */}
              <div style={{ padding: '14px 16px', borderBottom: `0.5px solid ${T.outline}` }}>
                {[['location_on', place.address], ['schedule', place.hours], ...(place.phone ? [['call', place.phone]] : [])].map(([icon, val]) =>
                  <div key={icon} style={{ display: 'flex', gap: 10, alignItems: 'flex-start', marginBottom: 10 }}>
                    <span className="material-symbols-rounded" style={{ fontSize: 17, color: T.textMuted, marginTop: 1 }}>{icon}</span>
                    <span style={{ fontFamily: T.font, fontSize: 13, color: T.text, lineHeight: 1.5 }}>{val}</span>
                  </div>
                )}
              </div>

              {/* ZON Activity */}
              <div style={{ padding: '14px 16px', borderBottom: `0.5px solid ${T.outline}` }}>
                <div style={{ fontFamily: T.font, fontSize: 14, fontWeight: 600, color: T.text, marginBottom: 14 }}>ZON Activity</div>
                <div style={{ display: 'flex', marginBottom: 14 }}>
                  {[['stamps', place.stamps], ['visitors', place.visitors], ['last visit', place.lastVisit]].map(([l, v], i) =>
                    <div key={l} style={{ flex: 1, textAlign: 'center', borderRight: i < 2 ? `0.5px solid ${T.outline}` : 'none' }}>
                      <div style={{ fontFamily: T.font, fontSize: 20, fontWeight: 700, color: T.text }}>{v}</div>
                      <div style={{ fontFamily: T.font, fontSize: 10, color: T.textMuted, marginTop: 2, textTransform: 'capitalize' }}>{l}</div>
                    </div>
                  )}
                </div>
                {place.friendsHere?.length > 0 &&
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <div style={{ display: 'flex' }}>
                      {place.friendsHere.map((f, i) => <Avatar key={i} size={26} initials={f.initials} style={{ marginLeft: i > 0 ? -8 : 0, zIndex: place.friendsHere.length - i }} />)}
                    </div>
                    <span style={{ fontFamily: T.font, fontSize: 12, color: T.textMuted }}>{place.friendsHere.length} friend{place.friendsHere.length > 1 ? 's' : ''} been here</span>
                  </div>
                }
              </div>

              {/* Photos — moved below ZON Activity */}
              <SectionHeader title="Photos" />
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 1, marginBottom: 8 }}>
                {MOCK.myStamps.slice(0, 6).map((s, i) => <ImgPlaceholder key={i} height={118} color={s.imgColor} />)}
              </div>

              {/* Recent Stamps */}
              <SectionHeader title="Recent Stamps" action="See all" />
              <div style={{ padding: '0 14px 24px' }}>
                {MOCK.stamps.slice(0, 2).map((s) =>
                  <StampCard key={s.id} stamp={s} onTap={() => onNavigate('stamp-detail', { stampId: s.id })} />
                )}
              </div>
            </>}

            {activeTab === 'stamps' &&
              <div style={{ padding: '12px 14px' }}>
                {MOCK.stamps.map((s) => <StampCard key={s.id} stamp={s} onTap={() => onNavigate('stamp-detail', { stampId: s.id })} />)}
              </div>
            }

            {activeTab === 'photos' &&
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 1, padding: '1px' }}>
                {MOCK.myStamps.map((s, i) => <ImgPlaceholder key={i} height={118} color={s.imgColor} />)}
              </div>
            }
          </div>
        )}
      </div>
    </div>
  );
};

// ── StampDetailScreen — v3.3 ──────────────────────────────────────────────
// · Gallery lives inside scroll — slides away like any other section
// · Place header fixed at top · Map slide leftmost · Photo slides swipeable
// · No user row · Flat threaded comments · Feed-style "More from" section
const StampDetailScreen = ({ onNavigate, params = {} }) => {
  const stamp    = MOCK.stamps.find((s) => s.id === params.stampId) || MOCK.stamps[0];
  const [liked,    setLiked]    = React.useState(stamp.liked);
  const [saved,    setSaved]    = React.useState(stamp.saved);
  const [slideIdx, setSlideIdx] = React.useState(1); // 0 = map, 1+ = photos
  const dragRef = React.useRef(null);

  const photoColors = [stamp.imgColor, MOCK.myStamps[2].imgColor, MOCK.myStamps[4].imgColor];
  const totalSlides = 1 + photoColors.length;
  const likeCount   = stamp.likes + (liked && !stamp.liked ? 1 : 0);

  const onDragStart = (e) => { dragRef.current = e.touches ? e.touches[0].clientX : e.clientX; };
  const onDragEnd   = (e) => {
    if (dragRef.current === null) return;
    const endX = e.changedTouches ? e.changedTouches[0].clientX : e.clientX;
    const delta = endX - dragRef.current;
    if (delta < -40 && slideIdx < totalSlides - 1) setSlideIdx((i) => i + 1);
    if (delta >  40 && slideIdx > 0)               setSlideIdx((i) => i - 1);
    dragRef.current = null;
  };

  return (
    <div style={{ width: 390, height: 844, background: T.surface0, display: 'flex', flexDirection: 'column', fontFamily: T.font, overflow: 'hidden' }}>

      {/* ── Place header — fixed at top ── */}
      <div style={{ background: T.surface1, flexShrink: 0, borderBottom: `0.5px solid ${T.outline}` }}
        data-comment-anchor="63f30dee5c-div-275-9">
        <StatusBar />
        <div style={{ padding: '2px 8px 10px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <BackButton onBack={() => onNavigate('back')} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: T.font, fontSize: 16, fontWeight: 700, color: T.text, lineHeight: 1.2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{stamp.place}</div>
            <div style={{ fontFamily: T.font, fontSize: 12, color: T.textMuted, marginTop: 1 }}>Café · 42m away · 7 stamps</div>
          </div>
          <button onClick={() => onNavigate('place-detail', { placeId: 'p1' })}
            style={{ height: 32, padding: '0 12px', borderRadius: 9999, border: `1px solid ${T.outline2}`, background: 'none', fontFamily: T.font, fontSize: 12, fontWeight: 600, color: T.text, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4, flexShrink: 0 }}>
            <span className="material-symbols-rounded" style={{ fontSize: 13, color: T.brand }}>near_me</span>
            Go
          </button>
        </div>
      </div>

      {/* ── All content scrolls: gallery → actions → comments → more ── */}
      <div style={{ flex: 1, overflowY: 'auto' }}>

        {/* Gallery — just another section, scrolls away naturally */}
        <div style={{ position: 'relative', userSelect: 'none' }}
          onMouseDown={slideIdx > 0 ? onDragStart : undefined}
          onMouseUp={slideIdx > 0 ? onDragEnd : undefined}
          onTouchStart={slideIdx > 0 ? onDragStart : undefined}
          onTouchEnd={slideIdx > 0 ? onDragEnd : undefined}>

          {slideIdx === 0
            ? <div style={{ position: 'relative' }}>
                <MapCanvas height={348} showRoute={false} showClusters={false} mini={false} />
                <div style={{ position: 'absolute', bottom: 28, left: 16, background: 'rgba(255,255,255,0.94)', borderRadius: 9999, padding: '4px 10px', display: 'flex', alignItems: 'center', gap: 5 }}>
                  <span className="material-symbols-rounded" style={{ fontSize: 13, color: T.brand, fontVariationSettings: "'FILL' 1" }}>location_on</span>
                  <span style={{ fontFamily: T.font, fontSize: 11, fontWeight: 600, color: T.text }}>{stamp.place}</span>
                </div>
              </div>
            : <ImgPlaceholder height={348} color={photoColors[slideIdx - 1]} />
          }

          {/* Indicators */}
          <div style={{ position: 'absolute', bottom: 10, left: 0, right: 0, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 6, pointerEvents: 'none' }}>
            <svg width="9" height="11" viewBox="0 0 9 11" opacity={slideIdx === 0 ? 1 : 0.38} style={{ flexShrink: 0, transition: 'opacity 0.2s' }}>
              <circle cx="4.5" cy="4" r="3.5" fill="white" />
              <polygon points="4.5,11 1.8,7 7.2,7" fill="white" />
            </svg>
            {photoColors.map((_, i) =>
              <div key={i} style={{ width: slideIdx === i + 1 ? 18 : 6, height: 5, borderRadius: 3, background: slideIdx === i + 1 ? 'white' : 'rgba(255,255,255,0.4)', transition: 'all 0.22s ease', flexShrink: 0 }} />
            )}
          </div>
        </div>

        {/* Actions + caption */}
        <div style={{ background: T.surface1, padding: '10px 16px 14px', borderBottom: `0.5px solid ${T.outline}` }}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: 8 }}>
            <button onClick={() => setLiked((v) => !v)} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '2px 10px 2px 0', display: 'flex' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 26, color: liked ? '#EF4444' : T.text, fontVariationSettings: liked ? "'FILL' 1" : "'FILL' 0", transition: 'all 0.15s' }}>favorite</span>
            </button>
            <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '2px 10px', display: 'flex' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 26, color: T.text }}>chat_bubble_outline</span>
            </button>
            <button style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '2px 10px', display: 'flex' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 24, color: T.text }}>send</span>
            </button>
            <button onClick={() => setSaved((v) => !v)} style={{ marginLeft: 'auto', background: 'none', border: 'none', cursor: 'pointer', padding: '2px 0', display: 'flex' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 26, color: saved ? T.brand : T.text, fontVariationSettings: saved ? "'FILL' 1" : "'FILL' 0", transition: 'color 0.15s' }}>bookmark</span>
            </button>
          </div>
          <div style={{ fontFamily: T.font, fontSize: 13, fontWeight: 600, color: T.text, marginBottom: 6 }}>{likeCount} likes</div>
          {stamp.caption &&
            <div style={{ fontFamily: T.font, fontSize: 13, color: T.text, lineHeight: 1.65, marginBottom: 6 }}>
              <span style={{ fontWeight: 600 }}>@{stamp.user}</span>{' '}{stamp.caption}
            </div>
          }
          {stamp.tags?.length > 0 &&
            <div style={{ fontFamily: T.font, fontSize: 13 }}>
              {stamp.tags.map((tag) => <span key={tag} style={{ color: T.brand, fontWeight: 500, marginRight: 8 }}>#{tag}</span>)}
            </div>
          }
        </div>

        {/* Comments */}
        <div style={{ background: T.surface1, padding: '12px 16px 14px' }}
          data-comment-anchor="c397e2eb80-div-345-9">
          <div style={{ marginBottom: 12 }}>
            <div style={{ display: 'flex', gap: 9, alignItems: 'flex-start' }}>
              <Avatar size={26} initials="J" />
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: T.font, fontSize: 13, color: T.text, lineHeight: 1.55 }}>
                  <span style={{ fontWeight: 600 }}>@junho_s</span>{' '}This place is amazing! Went last week too.
                </div>
                <div style={{ display: 'flex', gap: 14, marginTop: 4 }}>
                  <span style={{ fontFamily: T.font, fontSize: 11, color: T.textMuted }}>3h ago</span>
                  <button style={{ fontFamily: T.font, fontSize: 11, fontWeight: 500, color: T.textMuted, background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}>Reply</button>
                </div>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 9, alignItems: 'flex-start', marginLeft: 34, marginTop: 8 }}>
              <Avatar size={22} initials="T" />
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: T.font, fontSize: 12, color: T.text, lineHeight: 1.55 }}>
                  <span style={{ fontWeight: 600 }}>@taehyun_p</span>{' '}Same! Always go on Saturdays 🙌
                </div>
                <span style={{ fontFamily: T.font, fontSize: 11, color: T.textMuted }}>2h ago</span>
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 9, alignItems: 'flex-start', marginBottom: 14 }}>
            <Avatar size={26} initials="Y" />
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: T.font, fontSize: 13, color: T.text, lineHeight: 1.55 }}>
                <span style={{ fontWeight: 600 }}>@yuna_m</span>{' '}Adding this to my list 🌿
              </div>
              <div style={{ display: 'flex', gap: 14, marginTop: 4 }}>
                <span style={{ fontFamily: T.font, fontSize: 11, color: T.textMuted }}>5h ago</span>
                <button style={{ fontFamily: T.font, fontSize: 11, fontWeight: 500, color: T.textMuted, background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}>Reply</button>
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 9, alignItems: 'center', paddingTop: 10, borderTop: `0.5px solid ${T.outline}` }}>
            <Avatar size={26} initials="T" />
            <span style={{ fontFamily: T.font, fontSize: 13, color: T.textFaint, flex: 1 }}>Add a comment…</span>
          </div>
        </div>

        {/* More from this place — feed-style StampCards */}
        <div style={{ marginTop: 8, paddingBottom: 24 }}>
          <SectionHeader title={`More from ${stamp.place}`} action="See all" />
          <div style={{ padding: '4px 12px 0' }}>
            {MOCK.stamps.slice(0, 3).map((s) =>
              <StampCard key={s.id} stamp={s} onTap={() => {}} />
            )}
          </div>
        </div>

      </div>
    </div>
  );
};

// ── StoryViewer ───────────────────────────────────────────────────────────
const StoryViewer = ({ onClose }) => {
  const [idx, setIdx] = React.useState(0);
  const total  = 3;
  const story  = MOCK.stories[1];
  const colors = ['#D0C8CC', '#C4CCC0', '#CCC8C0'];

  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 300, background: '#000', fontFamily: T.font }}
      onClick={(e) => { const mid = 195; if (e.clientX > mid) { idx < total - 1 ? setIdx((i) => i + 1) : onClose(); } else { idx > 0 ? setIdx((i) => i - 1) : onClose(); } }}>
      <ImgPlaceholder width="100%" height={844} color={colors[idx]} />
      <div style={{ position: 'absolute', inset: 0 }}>
        <div style={{ position: 'absolute', top: 48, left: 10, right: 10, display: 'flex', gap: 3 }}>
          {Array.from({ length: total }).map((_, i) =>
            <div key={i} style={{ flex: 1, height: 2.5, borderRadius: 2, background: i <= idx ? 'white' : 'rgba(255,255,255,0.3)' }} />
          )}
        </div>
        <div style={{ position: 'absolute', top: 58, left: 12, right: 12, display: 'flex', alignItems: 'center', gap: 10 }}>
          <Avatar size={32} initials={story.initials} ring ringColors={[T.brand, T.story]} />
          <span style={{ fontFamily: T.font, fontSize: 13, fontWeight: 600, color: 'white' }}>@{story.name}</span>
          <span style={{ fontFamily: T.font, fontSize: 11, color: 'rgba(255,255,255,0.6)', marginLeft: 'auto' }}>2h ago</span>
          <button onClick={(e) => { e.stopPropagation(); onClose(); }} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
            <span className="material-symbols-rounded" style={{ fontSize: 20, color: 'white' }}>close</span>
          </button>
        </div>
        <div style={{ position: 'absolute', bottom: 40, left: 16, right: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
            <span className="material-symbols-rounded" style={{ fontSize: 15, color: 'white', fontVariationSettings: "'FILL' 1" }}>location_on</span>
            <span style={{ fontFamily: T.font, fontSize: 17, fontWeight: 700, color: 'white' }}>Heukbyul Coffee</span>
          </div>
          <span style={{ fontFamily: T.font, fontSize: 12, color: 'rgba(255,255,255,0.7)' }}>Jun 7 · 9:45 AM</span>
        </div>
      </div>
    </div>
  );
};

// ── StampEditorFallback ───────────────────────────────────────────────────
const StampEditorFallback = ({ onNavigate }) =>
  <div style={{ width: 390, height: 844, background: T.surface0, display: 'flex', flexDirection: 'column', fontFamily: T.font }}>
    <div style={{ background: T.surface1, borderBottom: `0.5px solid ${T.outline}` }}>
      <StatusBar />
      <div style={{ padding: '4px 8px 12px', display: 'flex', alignItems: 'center', gap: 4 }}>
        <BackButton onBack={() => onNavigate('back')} />
        <span style={{ fontFamily: T.font, fontSize: 16, fontWeight: 700, color: T.text }}>Create Stamp</span>
        <button style={{ marginLeft: 'auto', height: 34, padding: '0 16px', borderRadius: 9999, background: T.brand, border: 'none', color: 'white', fontFamily: T.font, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>Post</button>
      </div>
    </div>
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ borderRadius: 14, overflow: 'hidden', border: `1.5px dashed ${T.outline2}`, minHeight: 200, display: 'flex', alignItems: 'center', justifyContent: 'center', background: T.surface2, cursor: 'pointer', flexDirection: 'column', gap: 10, marginBottom: 16 }}>
        <span className="material-symbols-rounded" style={{ fontSize: 36, color: T.textFaint }}>add_photo_alternate</span>
        <span style={{ fontFamily: T.font, fontSize: 13, color: T.textMuted }}>Add photos</span>
      </div>
      <div style={{ marginBottom: 14 }}>
        <div style={{ fontFamily: T.font, fontSize: 11, fontWeight: 600, color: T.textMuted, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Place</div>
        <SearchBar placeholder="Search for a place…" />
      </div>
      <div style={{ marginBottom: 14 }}>
        <div style={{ fontFamily: T.font, fontSize: 11, fontWeight: 600, color: T.textMuted, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Caption</div>
        <textarea placeholder="Write something…" style={{ width: '100%', minHeight: 88, border: `1px solid ${T.outline2}`, borderRadius: 12, padding: '12px 14px', fontFamily: T.font, fontSize: 13, color: T.text, background: T.surface1, resize: 'none', outline: 'none', lineHeight: 1.55, boxSizing: 'border-box' }} />
      </div>
      <div style={{ marginBottom: 20 }}>
        <div style={{ fontFamily: T.font, fontSize: 11, fontWeight: 600, color: T.textMuted, marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Vibe tags</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 7 }}>
          {['cozy', 'quiet', 'lively', 'outdoor', 'artsy', 'scenic', 'local', 'trendy'].map((tag) =>
            <Pill key={tag} style={{ fontSize: 11, padding: '4px 11px' }}>#{tag}</Pill>
          )}
        </div>
      </div>
    </div>
  </div>;

Object.assign(window, { CheckInSheet, PlaceDetailScreen, StampDetailScreen, StoryViewer, StampEditorFallback });
