// zon-screens-modal.jsx — CheckInSheet, StampEditorScreen, PlaceDetailScreen, StampDetailScreen, StoryViewer

// ── CheckInSheet (Direction A: bottom sheet over map) ─────────────────────
const CheckInSheet = ({ onNavigate, onClose }) => {
  const [step, setStep] = React.useState('search'); // 'search' | 'editor' | 'confirm'
  const [selectedPlace, setSelectedPlace] = React.useState(null);
  const [note, setNote] = React.useState('');
  const [shareStory, setShareStory] = React.useState(false);

  const nearby = [
    { id:'p1', name:'Heukbyul Coffee', emoji:'☕', dist:'42m' },
    { id:'p2', name:'Han River Park',  emoji:'🌿', dist:'340m' },
    { id:'p3', name:'Grand Market',    emoji:'🏬', dist:'520m' },
    { id:'p4', name:'Pasta Bar Roma',  emoji:'🍝', dist:'780m' },
    { id:'p5', name:'Blue Note Records',emoji:'🎵', dist:'1.1km' },
  ];

  const handleSave = () => setStep('confirm');

  return (
    <div style={{ position:'absolute', inset:0, zIndex:200, display:'flex', flexDirection:'column', justifyContent:'flex-end', fontFamily:T.font }}>
      {/* Map peek */}
      <div onClick={onClose} style={{ flex:1, position:'relative' }}>
        <MapCanvas height={180} showRoute showClusters={false}/>
        <div style={{ position:'absolute', inset:0, background:'rgba(26,23,20,0.25)' }}/>
      </div>

      {/* Sheet */}
      <div style={{ background:T.surface1, borderRadius:'24px 24px 0 0', boxShadow:'0 -8px 32px rgba(0,0,0,0.14)', maxHeight:'72vh', display:'flex', flexDirection:'column' }}>
        <BottomHandle/>

        {step === 'search' && <>
          <div style={{ padding:'0 20px 12px', display:'flex', justifyContent:'space-between', alignItems:'center' }}>
            <span style={{ fontFamily:T.font, fontSize:20, fontWeight:700, color:T.text }}>Add a Check-in</span>
            <button onClick={onClose} style={{ width:32, height:32, borderRadius:16, background:T.surface2, border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center' }}>
              <span className="material-symbols-rounded" style={{ fontSize:18, color:T.textMuted }}>close</span>
            </button>
          </div>
          <div style={{ padding:'0 16px 10px' }}>
            <SearchBar placeholder="Where are you?" style={{ marginBottom:12 }}/>
            {/* Use current location CTA */}
            <div style={{ padding:'11px 14px', border:`2px dashed ${T.brand}`, borderRadius:12, marginBottom:12, display:'flex', alignItems:'center', gap:12, background:T.brandSoft2, cursor:'pointer' }} onClick={() => { setSelectedPlace({ name:'Heukbyul Coffee', emoji:'☕' }); setStep('editor'); }}>
              <div style={{ width:36, height:36, borderRadius:18, background:T.brand, display:'flex', alignItems:'center', justifyContent:'center' }}>
                <span className="material-symbols-rounded" style={{ fontSize:20, color:'white', fontVariationSettings:"'FILL' 1" }}>my_location</span>
              </div>
              <div>
                <div style={{ fontFamily:T.font, fontSize:14, fontWeight:700, color:T.text }}>Use current location</div>
                <div style={{ fontFamily:T.font, fontSize:12, color:T.textMuted }}>Heukbyul Coffee · 42m away</div>
              </div>
            </div>
          </div>
          {/* Nearby list */}
          <div style={{ overflowY:'auto', flex:1, paddingBottom:20 }}>
            {nearby.map((p, i) => (
              <div key={p.id} onClick={() => { setSelectedPlace(p); setStep('editor'); }} style={{ padding:'12px 16px', display:'flex', alignItems:'center', gap:12, borderBottom:`1px solid ${T.outline}`, cursor:'pointer' }}>
                <span style={{ fontSize:20, width:28, textAlign:'center' }}>{p.emoji}</span>
                <span style={{ fontFamily:T.font, fontSize:15, flex:1, color:T.text }}>{p.name}</span>
                <span style={{ fontFamily:T.font, fontSize:13, color:T.textMuted }}>{p.dist}</span>
                <span className="material-symbols-rounded" style={{ fontSize:18, color:T.textFaint }}>chevron_right</span>
              </div>
            ))}
          </div>
        </>}

        {step === 'editor' && selectedPlace && <>
          <div style={{ padding:'0 20px 14px', display:'flex', alignItems:'center', gap:10 }}>
            <BackButton onBack={() => setStep('search')}/>
            <div style={{ flex:1 }}>
              <div style={{ fontFamily:T.font, fontSize:18, fontWeight:700, color:T.text }}>{selectedPlace.emoji} {selectedPlace.name}</div>
            </div>
          </div>
          <div style={{ overflowY:'auto', flex:1, padding:'0 16px 16px' }}>
            <textarea value={note} onChange={e => setNote(e.target.value)} placeholder="Add a note (optional)…" style={{ width:'100%', minHeight:80, border:`1.5px solid ${T.outline}`, borderRadius:12, padding:'12px 14px', fontFamily:T.font, fontSize:14, color:T.text, background:T.surface0, resize:'none', outline:'none', lineHeight:1.55, boxSizing:'border-box', marginBottom:14 }}/>
            {/* Photo strip placeholder */}
            <div style={{ marginBottom:14 }}>
              <div style={{ fontFamily:T.font, fontSize:14, fontWeight:600, color:T.text, marginBottom:8 }}>Photos</div>
              <div style={{ display:'flex', gap:8 }}>
                <div style={{ width:72, height:72, borderRadius:12, background:T.surface2, border:`1.5px dashed ${T.outline2}`, display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer' }}>
                  <span className="material-symbols-rounded" style={{ fontSize:24, color:T.textFaint }}>add_photo_alternate</span>
                </div>
              </div>
            </div>
            {/* Share toggle */}
            <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', padding:'12px 0', borderTop:`1px solid ${T.outline}`, marginBottom:16 }}>
              <div>
                <div style={{ fontFamily:T.font, fontSize:14, fontWeight:600, color:T.text }}>Share as story</div>
                <div style={{ fontFamily:T.font, fontSize:12, color:T.textMuted }}>Visible to friends for 24h</div>
              </div>
              <div onClick={() => setShareStory(v => !v)} style={{ width:48, height:28, borderRadius:14, background: shareStory ? T.brand : T.surface3, cursor:'pointer', position:'relative', transition:'background 0.2s' }}>
                <div style={{ position:'absolute', top:3, left: shareStory ? 23 : 3, width:22, height:22, borderRadius:11, background:'white', boxShadow:'0 1px 4px rgba(0,0,0,0.18)', transition:'left 0.2s' }}/>
              </div>
            </div>
            <button onClick={handleSave} style={{ width:'100%', height:50, borderRadius:16, background:T.brand, border:'none', color:'white', fontFamily:T.font, fontSize:16, fontWeight:700, cursor:'pointer', boxShadow:`0 4px 16px rgba(139,110,196,0.38)` }}>Save Check-in</button>
          </div>
        </>}

        {step === 'confirm' && <>
          <div style={{ padding:'20px 24px 28px', textAlign:'center' }}>
            <div style={{ width:64, height:64, borderRadius:32, background:T.brandSoft, display:'flex', alignItems:'center', justifyContent:'center', margin:'0 auto 14px' }}>
              <span className="material-symbols-rounded" style={{ fontSize:34, color:T.brand, fontVariationSettings:"'FILL' 1" }}>check_circle</span>
            </div>
            <div style={{ fontFamily:T.font, fontSize:20, fontWeight:700, color:T.text, marginBottom:6 }}>Checked in!</div>
            <div style={{ fontFamily:T.font, fontSize:14, color:T.textMuted, marginBottom:24 }}>{selectedPlace?.emoji} {selectedPlace?.name}</div>
            <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
              <button onClick={() => { onNavigate('stamp-editor'); onClose(); }} style={{ height:48, borderRadius:14, background:T.brand, border:'none', color:'white', fontFamily:T.font, fontSize:15, fontWeight:700, cursor:'pointer' }}>Make it a stamp →</button>
              <button onClick={() => { onNavigate('timeline'); onClose(); }} style={{ height:48, borderRadius:14, background:'none', border:`1.5px solid ${T.outline2}`, color:T.text, fontFamily:T.font, fontSize:15, fontWeight:500, cursor:'pointer' }}>View in Timeline</button>
              <button onClick={onClose} style={{ height:40, background:'none', border:'none', color:T.textMuted, fontFamily:T.font, fontSize:14, cursor:'pointer' }}>Done</button>
            </div>
          </div>
        </>}
      </div>
    </div>
  );
};

// ── PlaceDetailScreen (Phase D placeholder — fully scaffolded) ─────────────
const PlaceDetailScreen = ({ onNavigate, params = {} }) => {
  const place = MOCK.places[params.placeId] || MOCK.places.p1;
  return (
    <div style={{ width:390, height:844, background:T.surface0, position:'relative', overflow:'hidden', display:'flex', flexDirection:'column', fontFamily:T.font }}>
      {/* Hero */}
      <div style={{ position:'relative', flexShrink:0 }}>
        <ImgPlaceholder height={220} color={place.imgColor}/>
        <div style={{ position:'absolute', inset:0, background:'linear-gradient(transparent 40%, rgba(20,16,12,0.6))' }}/>
        <div style={{ position:'absolute', top:0, left:0, right:0 }}>
          <StatusBar dark/>
          <div style={{ padding:'0 8px', display:'flex', justifyContent:'space-between', alignItems:'center' }}>
            <BackButton onBack={() => onNavigate('back')} dark/>
            <button onClick={() => onNavigate('checkin')} style={{ height:36, padding:'0 18px', borderRadius:9999, background:T.brand, border:'none', color:'white', fontFamily:T.font, fontSize:14, fontWeight:600, cursor:'pointer' }}>Check in</button>
          </div>
        </div>
        <div style={{ position:'absolute', bottom:14, left:16 }}>
          <h1 style={{ fontFamily:T.font, fontSize:26, fontWeight:800, color:'white', margin:0, marginBottom:4 }}>{place.name}</h1>
          <div style={{ display:'flex', gap:10, alignItems:'center' }}>
            <span style={{ fontFamily:T.font, fontSize:13, color:'rgba(255,255,255,0.82)' }}>{place.category}</span>
            <span style={{ color:'rgba(255,255,255,0.5)' }}>·</span>
            <span style={{ fontFamily:T.font, fontSize:13, color:'rgba(255,255,255,0.82)' }}>{place.dist}</span>
          </div>
        </div>
      </div>

      <div style={{ flex:1, overflowY:'auto' }}>
        {/* Place info */}
        <div style={{ background:T.surface1, padding:'16px', borderBottom:`1px solid ${T.outline}` }}>
          {[['location_on', place.address], ['schedule', place.hours], ...(place.phone ? [['call', place.phone]] : [])].map(([icon, val]) => (
            <div key={icon} style={{ display:'flex', gap:10, alignItems:'flex-start', marginBottom:8 }}>
              <span className="material-symbols-rounded" style={{ fontSize:18, color:T.textMuted, marginTop:1 }}>{icon}</span>
              <span style={{ fontFamily:T.font, fontSize:14, color:T.text, lineHeight:1.5 }}>{val}</span>
            </div>
          ))}
        </div>

        {/* ZON activity */}
        <div style={{ background:T.surface1, margin:'8px 0', padding:'16px', borderTop:`1px solid ${T.outline}`, borderBottom:`1px solid ${T.outline}` }}>
          <div style={{ fontFamily:T.font, fontSize:15, fontWeight:700, color:T.text, marginBottom:12 }}>ZON Activity</div>
          <div style={{ display:'flex', gap:24, marginBottom:12 }}>
            <div style={{ textAlign:'center' }}>
              <div style={{ fontFamily:T.font, fontSize:22, fontWeight:800, color:T.brand }}>{place.stamps}</div>
              <div style={{ fontFamily:T.font, fontSize:11, color:T.textMuted }}>Stamps</div>
            </div>
            <div style={{ textAlign:'center' }}>
              <div style={{ fontFamily:T.font, fontSize:22, fontWeight:800, color:T.text }}>{place.visitors}</div>
              <div style={{ fontFamily:T.font, fontSize:11, color:T.textMuted }}>Visitors</div>
            </div>
            <div style={{ textAlign:'center' }}>
              <div style={{ fontFamily:T.font, fontSize:22, fontWeight:800, color:T.text }}>{place.lastVisit}</div>
              <div style={{ fontFamily:T.font, fontSize:11, color:T.textMuted }}>Last visit</div>
            </div>
          </div>
          {place.friendsHere?.length > 0 && (
            <div style={{ display:'flex', alignItems:'center', gap:8 }}>
              <div style={{ display:'flex', gap:-4 }}>
                {place.friendsHere.map((f, i) => <Avatar key={i} size={28} initials={f.initials} style={{ marginLeft: i > 0 ? -8 : 0, zIndex: place.friendsHere.length - i }}/>)}
              </div>
              <span style={{ fontFamily:T.font, fontSize:13, color:T.textMuted }}>{place.friendsHere.length} friend{place.friendsHere.length > 1 ? 's' : ''} been here</span>
            </div>
          )}
        </div>

        {/* Photo grid */}
        <SectionHeader title="Photos"/>
        <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:2, padding:'0 2px 2px' }}>
          {[T.surface2,'#C8B4DC','#B4C8A8','#D4B4A0','#A4B4C8','#C4C0A8'].map((c, i) => (
            <ImgPlaceholder key={i} height={118} color={c}/>
          ))}
        </div>

        {/* Stamps from this place */}
        <SectionHeader title="Stamps" action="See all" />
        <div style={{ padding:'0 14px 24px' }}>
          {MOCK.stamps.slice(0, 2).map(s => (
            <StampCard key={s.id} stamp={s} onTap={() => onNavigate('stamp-detail', { stampId: s.id })}/>
          ))}
        </div>
      </div>
    </div>
  );
};

// ── StampDetailScreen ─────────────────────────────────────────────────────
const StampDetailScreen = ({ onNavigate, params = {} }) => {
  const stamp = MOCK.stamps.find(s => s.id === params.stampId) || MOCK.stamps[0];
  const [liked, setLiked] = React.useState(stamp.liked);
  const [saved, setSaved] = React.useState(stamp.saved);

  return (
    <div style={{ width:390, height:844, background:T.surface0, position:'relative', overflow:'hidden', display:'flex', flexDirection:'column', fontFamily:T.font }}>
      <div style={{ position:'relative', flexShrink:0 }}>
        <ImgPlaceholder height={340} color={stamp.imgColor}/>
        <div style={{ position:'absolute', inset:0, background:'linear-gradient(transparent 50%, rgba(20,16,12,0.7))' }}/>
        <div style={{ position:'absolute', top:0, left:0, right:0 }}>
          <StatusBar dark/>
          <div style={{ padding:'0 8px', display:'flex', justifyContent:'space-between' }}>
            <BackButton onBack={() => onNavigate('back')} dark/>
            <button style={{ width:40, height:40, borderRadius:20, background:'rgba(0,0,0,0.3)', border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center' }}>
              <span className="material-symbols-rounded" style={{ fontSize:22, color:'white' }}>more_vert</span>
            </button>
          </div>
        </div>
        <div style={{ position:'absolute', bottom:14, left:16, right:16 }}>
          <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:5 }}>
            <Avatar size={30} initials={stamp.initials}/>
            <span style={{ fontFamily:T.font, fontSize:13, color:'rgba(255,255,255,0.85)', fontWeight:600 }}>@{stamp.user}</span>
            <span style={{ fontFamily:T.font, fontSize:12, color:'rgba(255,255,255,0.6)', marginLeft:'auto' }}>{stamp.time}</span>
          </div>
          <div style={{ display:'flex', alignItems:'center', gap:6 }}>
            <span className="material-symbols-rounded" style={{ fontSize:16, color:'white', fontVariationSettings:"'FILL' 1" }}>location_on</span>
            <span style={{ fontFamily:T.font, fontSize:18, fontWeight:700, color:'white' }}>{stamp.place}</span>
          </div>
        </div>
      </div>

      <div style={{ flex:1, overflowY:'auto' }}>
        <div style={{ background:T.surface1, padding:'16px', borderBottom:`1px solid ${T.outline}` }}>
          {stamp.caption && <p style={{ fontFamily:T.font, fontSize:15, color:T.text, lineHeight:1.65, margin:'0 0 12px', fontStyle:'italic' }}>"{stamp.caption}"</p>}
          {stamp.tags?.length > 0 && (
            <div style={{ display:'flex', gap:6, flexWrap:'wrap', marginBottom:14 }}>
              {stamp.tags.map(tag => <span key={tag} style={{ fontFamily:T.font, fontSize:12, fontWeight:600, color:T.brand, background:T.brandSoft, borderRadius:9999, padding:'3px 12px' }}>#{tag}</span>)}
            </div>
          )}
          <div style={{ display:'flex', alignItems:'center', gap:20 }}>
            <button onClick={() => setLiked(v => !v)} style={{ display:'flex', alignItems:'center', gap:6, background:'none', border:'none', cursor:'pointer', padding:0 }}>
              <span className="material-symbols-rounded" style={{ fontSize:24, color: liked ? '#EF4444' : T.textMuted, fontVariationSettings: liked ? "'FILL' 1" : "'FILL' 0" }}>favorite</span>
              <span style={{ fontFamily:T.font, fontSize:14, color:T.textMuted }}>{stamp.likes}</span>
            </button>
            <button style={{ display:'flex', alignItems:'center', gap:6, background:'none', border:'none', cursor:'pointer', padding:0 }}>
              <span className="material-symbols-rounded" style={{ fontSize:24, color:T.textMuted }}>chat_bubble_outline</span>
              <span style={{ fontFamily:T.font, fontSize:14, color:T.textMuted }}>{stamp.comments}</span>
            </button>
            <button onClick={() => setSaved(v => !v)} style={{ marginLeft:'auto', display:'flex', alignItems:'center', background:'none', border:'none', cursor:'pointer', padding:4 }}>
              <span className="material-symbols-rounded" style={{ fontSize:24, color: saved ? T.brand : T.textMuted, fontVariationSettings: saved ? "'FILL' 1" : "'FILL' 0" }}>bookmark</span>
            </button>
          </div>
        </div>

        {/* Comments section */}
        <SectionHeader title="Comments"/>
        <div style={{ padding:'0 16px 24px' }}>
          {[{ initials:'J', user:'junho_s', text:'This place is amazing! Went last week too.' },
            { initials:'Y', user:'yuna_m', text:'Adding this to my list 🌿' }].map((c, i) => (
            <div key={i} style={{ display:'flex', gap:10, marginBottom:14, alignItems:'flex-start' }}>
              <Avatar size={34} initials={c.initials}/>
              <div style={{ flex:1, background:T.surface1, borderRadius:12, padding:'9px 12px', border:`1px solid ${T.outline}` }}>
                <span style={{ fontFamily:T.font, fontSize:13, fontWeight:700, color:T.text }}>@{c.user} </span>
                <span style={{ fontFamily:T.font, fontSize:13, color:T.text }}>{c.text}</span>
              </div>
            </div>
          ))}
          {/* Comment input */}
          <div style={{ display:'flex', gap:8, alignItems:'center' }}>
            <Avatar size={34} initials="T"/>
            <div style={{ flex:1, height:40, borderRadius:20, background:T.surface1, border:`1.5px solid ${T.outline}`, display:'flex', alignItems:'center', padding:'0 14px' }}>
              <span style={{ fontFamily:T.font, fontSize:13, color:T.textFaint }}>Add a comment…</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// ── StoryViewer ───────────────────────────────────────────────────────────
const StoryViewer = ({ onClose }) => {
  const [idx, setIdx] = React.useState(0);
  const total = 3;
  const story = MOCK.stories[1];
  const colors = ['#C8B4DC', '#B4C8A8', '#D4B4A0'];

  return (
    <div style={{ position:'absolute', inset:0, zIndex:300, background:'#000', fontFamily:T.font }}
      onClick={e => { const mid = 195; if (e.clientX > mid) { if (idx < total-1) setIdx(i => i+1); else onClose(); } else { if (idx > 0) setIdx(i => i-1); else onClose(); } }}>
      <ImgPlaceholder width="100%" height={844} color={colors[idx]}/>
      <div style={{ position:'absolute', inset:0 }}>
        {/* Progress bars */}
        <div style={{ position:'absolute', top: 48, left:10, right:10, display:'flex', gap:4 }}>
          {Array.from({ length: total }).map((_, i) => (
            <div key={i} style={{ flex:1, height:3, borderRadius:2, background: i <= idx ? 'white' : 'rgba(255,255,255,0.35)' }}/>
          ))}
        </div>
        {/* User row */}
        <div style={{ position:'absolute', top:60, left:12, right:12, display:'flex', alignItems:'center', gap:10 }}>
          <Avatar size={34} initials={story.initials} ring ringColors={[T.brand, T.story]}/>
          <span style={{ fontFamily:T.font, fontSize:14, fontWeight:600, color:'white' }}>@{story.name}</span>
          <span style={{ fontFamily:T.font, fontSize:12, color:'rgba(255,255,255,0.65)', marginLeft:'auto' }}>2h ago</span>
          <button onClick={e => { e.stopPropagation(); onClose(); }} style={{ background:'none', border:'none', cursor:'pointer' }}>
            <span className="material-symbols-rounded" style={{ fontSize:22, color:'white' }}>close</span>
          </button>
        </div>
        {/* Place + note */}
        <div style={{ position:'absolute', bottom:40, left:16, right:16 }}>
          <div style={{ display:'flex', alignItems:'center', gap:6, marginBottom:4 }}>
            <span className="material-symbols-rounded" style={{ fontSize:16, color:'white', fontVariationSettings:"'FILL' 1" }}>location_on</span>
            <span style={{ fontFamily:T.font, fontSize:18, fontWeight:700, color:'white' }}>Heukbyul Coffee</span>
          </div>
          <span style={{ fontFamily:T.font, fontSize:13, color:'rgba(255,255,255,0.75)' }}>Jun 7 · 9:45 AM</span>
        </div>
      </div>
    </div>
  );
};

Object.assign(window, { CheckInSheet, PlaceDetailScreen, StampDetailScreen, StoryViewer });
