// v3-app.jsx — App shell with theme listener + ReactDOM mount

const { useState, useCallback, useEffect } = React;

function App() {
  const [tab,      setTab]      = useState('map');
  const [stack,    setStack]    = useState([]);
  const [modal,    setModal]    = useState(null);
  const [fabOpen,  setFabOpen]  = useState(false);
  const [, forceUpdate]         = useState(0); // re-render on theme change

  // Listen for theme changes from tweak bar
  useEffect(() => {
    const handler = () => forceUpdate(n => n + 1);
    window.addEventListener('zon-theme-change', handler);
    return () => window.removeEventListener('zon-theme-change', handler);
  }, []);

  const currentEntry  = stack.length > 0 ? stack[stack.length - 1] : null;
  const currentScreen = currentEntry ? currentEntry.screen : tab;
  const currentParams = currentEntry ? currentEntry.params : {};

  const navigate = useCallback((screen, params = {}) => {
    setFabOpen(false);
    if (screen === 'back')         { setStack(s => s.slice(0, -1)); return; }
    if (screen === 'checkin')      { setModal('checkin');      return; }
    if (screen === 'story-viewer') { setModal('story-viewer'); return; }
    if (screen === 'photo-checkin'){ setModal('checkin');      return; }
    if (['map','feed','timeline','profile'].includes(screen)) {
      setTab(screen); setStack([]); return;
    }
    setStack(s => [...s, { screen, params }]);
  }, []);

  const switchTab  = useCallback((t) => { setTab(t); setStack([]); setFabOpen(false); }, []);
  const closeModal = useCallback(() => setModal(null), []);
  const toggleFab  = useCallback(() => setFabOpen(v => !v), []);

  const sharedProps = { onNavigate: navigate, fabOpen, onFab: toggleFab, tab, onTab: switchTab };

  const renderScreen = () => {
    switch (currentScreen) {
      case 'map':          return <MapScreen      {...sharedProps}/>;
      case 'feed':         return <FeedScreen     {...sharedProps}/>;
      case 'timeline':     return <TimelineScreen {...sharedProps}/>;
      case 'profile':      return <ProfileScreen  {...sharedProps} params={currentParams}/>;
      case 'activity':     return <ActivityScreen   onNavigate={navigate}/>;
      case 'settings':     return <SettingsScreen   onNavigate={navigate}/>;
      case 'user-search':  return <UserSearchScreen onNavigate={navigate}/>;
      case 'stamp-detail': return <StampDetailScreen onNavigate={navigate} params={currentParams}/>;
      case 'place-detail': return <PlaceDetailScreen onNavigate={navigate} params={currentParams}/>;
      case 'stamp-editor': return <StampEditorFallback onNavigate={navigate}/>;
      default:             return <MapScreen {...sharedProps}/>;
    }
  };

  return (
    <RouterCtx.Provider value={{ navigate, switchTab, closeModal }}>
      <div style={{ position:'relative', width:390, height:844, overflow:'hidden', background:T.surface0 }}>
        <div key={currentScreen + (stack.length > 0 ? '-push' : '-tab')}
          style={{ position:'absolute', inset:0, animation: stack.length > 0 ? 'slideIn 0.26s ease-out' : 'fadeIn 0.14s ease' }}>
          {renderScreen()}
        </div>

        {modal === 'checkin' && (
          <CheckInSheet onNavigate={navigate} onClose={closeModal}/>
        )}
        {modal === 'story-viewer' && (
          <StoryViewer onClose={closeModal}/>
        )}

        {fabOpen && !modal && (
          <div onClick={() => setFabOpen(false)} style={{ position:'absolute', inset:0, zIndex:97 }}/>
        )}
      </div>
    </RouterCtx.Provider>
  );
}

const _root = ReactDOM.createRoot(document.getElementById('root'));
_root.render(<App/>);
