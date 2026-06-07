// zon-app.jsx — App shell, navigation, ReactDOM mount

const { useState, useCallback } = React;

// ── Navigation logic ───────────────────────────────────────────────────────
// stack items: { screen, params }
// tab:  persists across push/pop
// modal: 'checkin' | 'story-viewer' | null

function App() {
  const [tab, setTab] = useState('map');
  const [stack, setStack] = useState([]);   // pushed screens
  const [modal, setModal] = useState(null);
  const [fabOpen, setFabOpen] = useState(false);

  const currentEntry = stack.length > 0 ? stack[stack.length - 1] : null;
  const currentScreen = currentEntry ? currentEntry.screen : tab;
  const currentParams = currentEntry ? currentEntry.params : {};

  const navigate = useCallback((screen, params = {}) => {
    setFabOpen(false);
    if (screen === 'back') {
      setStack(s => s.slice(0, -1));
      return;
    }
    if (screen === 'checkin') { setModal('checkin'); return; }
    if (screen === 'story-viewer') { setModal('story-viewer'); return; }
    if (screen === 'photo-checkin') { setModal('checkin'); return; }
    // Tab shortcuts
    if (['map','feed','timeline','profile'].includes(screen)) {
      setTab(screen); setStack([]); return;
    }
    setStack(s => [...s, { screen, params }]);
  }, []);

  const switchTab = useCallback((t) => {
    setTab(t); setStack([]); setFabOpen(false);
  }, []);

  const closeModal = useCallback(() => setModal(null), []);
  const toggleFab = useCallback(() => setFabOpen(v => !v), []);

  const sharedProps = { onNavigate: navigate, fabOpen, onFab: toggleFab, tab, onTab: switchTab };

  // ── Screen renderer ──────────────────────────────────────────────────────
  const renderScreen = () => {
    switch (currentScreen) {
      case 'map':          return <MapScreen      {...sharedProps} />;
      case 'feed':         return <FeedScreen     {...sharedProps} />;
      case 'timeline':     return <TimelineScreen {...sharedProps} />;
      case 'profile':      return <ProfileScreen  {...sharedProps} params={currentParams} />;
      case 'activity':     return <ActivityScreen   onNavigate={navigate} />;
      case 'settings':     return <SettingsScreen   onNavigate={navigate} />;
      case 'user-search':  return <UserSearchScreen onNavigate={navigate} />;
      case 'stamp-detail': return <StampDetailScreen onNavigate={navigate} params={currentParams} />;
      case 'place-detail': return <PlaceDetailScreen onNavigate={navigate} params={currentParams} />;
      case 'stamp-editor': return <StampEditorFallback onNavigate={navigate} />;
      default:             return <MapScreen {...sharedProps} />;
    }
  };

  return (
    <RouterCtx.Provider value={{ navigate, switchTab, closeModal }}>
      <div style={{ position: 'relative', width: 390, height: 844, overflow: 'hidden', background: T.surface0 }}>
        {/* Animated screen area */}
        <div key={currentScreen} style={{ position: 'absolute', inset: 0, animation: stack.length > 0 ? 'slideIn 0.28s ease-out' : 'fadeIn 0.15s ease' }}>
          {renderScreen()}
        </div>

        {/* Modal overlays */}
        {modal === 'checkin' && (
          <CheckInSheet onNavigate={navigate} onClose={closeModal} />
        )}
        {modal === 'story-viewer' && (
          <StoryViewer onClose={closeModal} />
        )}

        {/* FAB backdrop (close on outside tap) */}
        {fabOpen && !modal && (
          <div onClick={() => setFabOpen(false)} style={{ position: 'absolute', inset: 0, zIndex: 97 }}/>
        )}
      </div>
    </RouterCtx.Provider>
  );
}

// Minimal fallback for stamp editor (not yet fully built)
const StampEditorFallback = ({ onNavigate }) => (
  <div style={{ width:390, height:844, background:T.surface0, display:'flex', flexDirection:'column', fontFamily:T.font }}>
    <div style={{ background:T.surface1, borderBottom:`1px solid ${T.outline}` }}>
      <StatusBar/>
      <div style={{ padding:'4px 8px 12px', display:'flex', alignItems:'center', gap:4 }}>
        <BackButton onBack={() => onNavigate('back')}/>
        <span style={{ fontFamily:T.font, fontSize:18, fontWeight:700, color:T.text }}>Create Stamp</span>
        <button style={{ marginLeft:'auto', height:36, padding:'0 18px', borderRadius:9999, background:T.brand, border:'none', color:'white', fontFamily:T.font, fontSize:14, fontWeight:600, cursor:'pointer' }}>Post</button>
      </div>
    </div>
    <div style={{ flex:1, overflowY:'auto', padding:16 }}>
      {/* Photo section */}
      <div style={{ marginBottom:16 }}>
        <div style={{ borderRadius:16, overflow:'hidden', border:`2px dashed ${T.outline2}`, minHeight:200, display:'flex', alignItems:'center', justifyContent:'center', background:T.surface2, cursor:'pointer', flexDirection:'column', gap:10 }}>
          <span className="material-symbols-rounded" style={{ fontSize:40, color:T.textFaint }}>add_photo_alternate</span>
          <span style={{ fontFamily:T.font, fontSize:14, color:T.textMuted }}>Add photos</span>
        </div>
      </div>
      {/* Place */}
      <div style={{ marginBottom:14 }}>
        <div style={{ fontFamily:T.font, fontSize:13, fontWeight:700, color:T.textMuted, marginBottom:6, textTransform:'uppercase', letterSpacing:'0.05em' }}>Place</div>
        <SearchBar placeholder="Search for a place…"/>
      </div>
      {/* Caption */}
      <div style={{ marginBottom:14 }}>
        <div style={{ fontFamily:T.font, fontSize:13, fontWeight:700, color:T.textMuted, marginBottom:6, textTransform:'uppercase', letterSpacing:'0.05em' }}>Caption</div>
        <textarea placeholder="Write something…" style={{ width:'100%', minHeight:96, border:`1.5px solid ${T.outline}`, borderRadius:12, padding:'12px 14px', fontFamily:T.font, fontSize:14, color:T.text, background:T.surface1, resize:'none', outline:'none', lineHeight:1.55, boxSizing:'border-box' }}/>
      </div>
      {/* Vibe tags */}
      <div style={{ marginBottom:20 }}>
        <div style={{ fontFamily:T.font, fontSize:13, fontWeight:700, color:T.textMuted, marginBottom:8, textTransform:'uppercase', letterSpacing:'0.05em' }}>Vibe tags <span style={{ color:T.textFaint, textTransform:'none', letterSpacing:0 }}>(pick up to 3)</span></div>
        <div style={{ display:'flex', flexWrap:'wrap', gap:8 }}>
          {['cozy','quiet','lively','outdoor','historic','artsy','scenic','local','trendy','hidden-gem'].map(tag => (
            <Pill key={tag} style={{ fontSize:12, padding:'5px 12px' }}>#{tag}</Pill>
          ))}
        </div>
      </div>
      {/* Visibility */}
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', padding:'13px 14px', background:T.surface1, borderRadius:14, border:`1px solid ${T.outline}` }}>
        <div style={{ display:'flex', alignItems:'center', gap:10 }}>
          <span className="material-symbols-rounded" style={{ fontSize:20, color:T.brand }}>public</span>
          <div>
            <div style={{ fontFamily:T.font, fontSize:14, fontWeight:600, color:T.text }}>Public stamp</div>
            <div style={{ fontFamily:T.font, fontSize:12, color:T.textMuted }}>Visible to your followers</div>
          </div>
        </div>
        <div style={{ width:48, height:28, borderRadius:14, background:T.brand, cursor:'pointer', position:'relative' }}>
          <div style={{ position:'absolute', top:3, left:23, width:22, height:22, borderRadius:11, background:'white', boxShadow:'0 1px 4px rgba(0,0,0,0.18)' }}/>
        </div>
      </div>
    </div>
  </div>
);

// ── Mount ─────────────────────────────────────────────────────────────────
const _root = ReactDOM.createRoot(document.getElementById('root'));
_root.render(<App/>);
