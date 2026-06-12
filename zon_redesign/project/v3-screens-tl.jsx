// v3-screens-tl.jsx — TimelineScreen

const TimelineScreen = ({ onNavigate, fabOpen, onFab, tab, onTab }) => {
  const DAYS  = ['S','M','T','W','T','F','S'];
  const DATES = [1,2,3,4,5,6,7];
  const TODAY_IDX = 5;

  const [selectedDay,    setSelectedDay]    = React.useState(TODAY_IDX);
  const [expandedId,     setExpandedId]     = React.useState(null);
  const [diaryGenerated, setDiaryGenerated] = React.useState(false);
  const [diaryText,      setDiaryText]      = React.useState('');
  const [generating,     setGenerating]     = React.useState(false);
  const [addingNote,     setAddingNote]     = React.useState(false);
  const [noteText,       setNoteText]       = React.useState('');

  const isToday = selectedDay === TODAY_IDX;

  const handleGenerate = () => {
    if (diaryGenerated) return;
    setGenerating(true);
    setTimeout(() => {
      setDiaryText("A slow Saturday in the city. The morning started with that familiar corner spot — light through frosted glass, the kind of warmth you want to bottle up. Then the river. Always the river. By evening, pasta and a good laugh. Days like this are why I keep a trace.");
      setDiaryGenerated(true);
      setGenerating(false);
    }, 1800);
  };

  return (
    <div style={{ width:390, height:844, background:T.surface0, position:'relative', overflow:'hidden', display:'flex', flexDirection:'column', fontFamily:T.font }}>
      <div style={{ background:T.surface1, flexShrink:0 }}>
        <StatusBar/>

        {/* Date nav */}
        <div style={{ padding:'4px 16px 8px', display:'flex', justifyContent:'space-between', alignItems:'center' }}>
          <button style={{ width:36, height:36, borderRadius:18, background:'none', border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', color:T.textMuted }}>
            <span className="material-symbols-rounded" style={{ fontSize:20 }}>chevron_left</span>
          </button>
          <button style={{ fontFamily:T.font, fontSize:16, fontWeight:600, color:T.text, background:'none', border:'none', cursor:'pointer', display:'flex', alignItems:'center', gap:4 }}>
            {isToday ? 'Today' : `Jun ${DATES[selectedDay]}`}
            <span className="material-symbols-rounded" style={{ fontSize:16, color:T.textMuted }}>expand_more</span>
          </button>
          <button style={{ width:36, height:36, borderRadius:18, background:'none', border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', color:T.textMuted }}>
            <span className="material-symbols-rounded" style={{ fontSize:20 }}>calendar_month</span>
          </button>
        </div>

        {/* Week strip */}
        <div style={{ display:'flex', gap:2, padding:'0 12px 12px' }}>
          {DAYS.map((d, i) => {
            const isSelected  = i === selectedDay;
            const isWeekend   = i === 0 || i === 6;
            const hasActivity = [1,3,4,5].includes(i);
            return (
              <button key={i} onClick={() => setSelectedDay(i)} style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', gap:3, padding:'7px 2px 6px', borderRadius:10, background: isSelected ? T.brand : 'none', border:'none', cursor:'pointer', transition:'background 0.15s', position:'relative' }}>
                <span style={{ fontFamily:T.font, fontSize:10, fontWeight:500, color: isSelected ? 'rgba(255,255,255,0.78)' : isWeekend ? T.textFaint : T.textMuted }}>{d}</span>
                <span style={{ fontFamily:T.font, fontSize:14, fontWeight: isSelected ? 600 : 400, color: isSelected ? 'white' : isWeekend ? T.textFaint : T.text }}>{DATES[i]}</span>
                {hasActivity && !isSelected && <div style={{ width:4, height:4, borderRadius:2, background:T.brand, opacity:0.6 }}/>}
                {!hasActivity && !isSelected && <div style={{ width:4, height:4 }}/>}
              </button>
            );
          })}
        </div>
      </div>

      {/* Scrollable body */}
      <div style={{ flex:1, overflowY:'auto', paddingBottom:83 }}>

        {/* Mini route map */}
        <div style={{ margin:'12px 14px', borderRadius:14, overflow:'hidden', boxShadow:'0 1px 6px rgba(0,0,0,0.06)', border:`0.5px solid ${T.outline}` }}>
          <MapCanvas height={180} showRoute showClusters={false} mini/>
          <div style={{ padding:'9px 13px', background:T.surface1, borderTop:`0.5px solid ${T.outline}`, display:'flex', justifyContent:'space-between', alignItems:'center' }}>
            <span style={{ fontFamily:T.font, fontSize:12, color:T.textMuted, fontWeight:400 }}>Jun {DATES[selectedDay]} · 3.8 km</span>
            <span style={{ fontFamily:T.font, fontSize:12, fontWeight:600, color:T.brand }}>3 stamps</span>
          </div>
        </div>

        {/* Timeline nodes */}
        <div style={{ padding:'4px 0 0' }}>
          {MOCK.timeline.map((item, i) => (
            <TimelineNode
              key={item.id} item={item}
              isLast={i === MOCK.timeline.length - 1}
              expanded={expandedId === item.id}
              onExpand={id => setExpandedId(prev => prev === id ? null : id)}
            />
          ))}
        </div>

        {/* Add note */}
        <div style={{ padding:'4px 16px 8px 52px' }}>
          {!addingNote ? (
            <button onClick={() => setAddingNote(true)} style={{ display:'flex', alignItems:'center', gap:8, background:'none', border:`1px dashed ${T.outline2}`, borderRadius:10, padding:'9px 14px', cursor:'pointer', width:'100%', fontFamily:T.font, fontSize:13, color:T.textMuted }}>
              <span className="material-symbols-rounded" style={{ fontSize:17, color:T.textMuted }}>add</span>
              Add a note…
            </button>
          ) : (
            <div style={{ background:T.surface1, border:`1.5px solid ${T.brand}`, borderRadius:12, padding:'10px 12px' }}>
              <textarea autoFocus value={noteText} onChange={e => setNoteText(e.target.value)} placeholder="What's on your mind?" style={{ width:'100%', minHeight:68, border:'none', background:'transparent', fontFamily:T.font, fontSize:13, color:T.text, resize:'none', outline:'none', lineHeight:1.55 }}/>
              <div style={{ display:'flex', justifyContent:'flex-end', gap:8, marginTop:6 }}>
                <button onClick={() => { setAddingNote(false); setNoteText(''); }} style={{ height:30, padding:'0 12px', borderRadius:9999, border:`1px solid ${T.outline2}`, background:'none', fontFamily:T.font, fontSize:12, color:T.textMuted, cursor:'pointer' }}>Cancel</button>
                <button onClick={() => { setAddingNote(false); setNoteText(''); }} style={{ height:30, padding:'0 12px', borderRadius:9999, background:T.brand, border:'none', color:'white', fontFamily:T.font, fontSize:12, fontWeight:600, cursor:'pointer' }}>Save</button>
              </div>
            </div>
          )}
        </div>

        <Divider mx={16} style={{ margin:'8px 16px' }}/>

        {/* Diary */}
        <div style={{ margin:'0 14px 24px', background:T.surface1, borderRadius:14, border:`0.5px solid ${T.outline}`, overflow:'hidden', boxShadow:'0 1px 4px rgba(0,0,0,0.04)' }}>
          <div style={{ padding:'13px 16px 11px', borderBottom:`0.5px solid ${T.outline}`, display:'flex', alignItems:'center', justifyContent:'space-between' }}>
            <div style={{ display:'flex', alignItems:'center', gap:8 }}>
              <span className="material-symbols-rounded" style={{ fontSize:18, color:T.brand, fontVariationSettings:"'FILL' 1" }}>menu_book</span>
              <span style={{ fontFamily:T.font, fontSize:14, fontWeight:600, color:T.text }}>Diary</span>
            </div>
            <div style={{ display:'flex', gap:7 }}>
              {diaryGenerated && (
                <button style={{ height:28, padding:'0 11px', borderRadius:9999, border:`1px solid ${T.outline2}`, background:'none', fontFamily:T.font, fontSize:11, fontWeight:600, color:T.textMuted, cursor:'pointer' }}>Edit</button>
              )}
              <button onClick={handleGenerate} disabled={diaryGenerated || generating} style={{ height:28, padding:'0 11px', borderRadius:9999, background: diaryGenerated ? T.surface2 : T.brand, border:'none', color: diaryGenerated ? T.textMuted : 'white', fontFamily:T.font, fontSize:11, fontWeight:600, cursor: diaryGenerated ? 'default' : 'pointer', display:'flex', alignItems:'center', gap:4, opacity: generating ? 0.7 : 1 }}>
                <span className="material-symbols-rounded" style={{ fontSize:13, fontVariationSettings:"'FILL' 1" }}>auto_awesome</span>
                {generating ? 'Writing…' : diaryGenerated ? 'Generated' : 'Generate'}
              </button>
            </div>
          </div>
          <div style={{ padding:'13px 16px 16px', minHeight:72 }}>
            {generating && (
              <div style={{ display:'flex', flexDirection:'column', gap:7 }}>
                {[100,88,72,55].map((w,i) => (
                  <div key={i} style={{ height:12, width:`${w}%`, borderRadius:6, background:`linear-gradient(90deg, ${T.surface2} 25%, ${T.surface3} 50%, ${T.surface2} 75%)`, backgroundSize:'200% 100%', animation:'shimmer 1.5s infinite' }}/>
                ))}
              </div>
            )}
            {!generating && diaryText && (
              <p style={{ fontFamily:T.font, fontSize:13, color:T.text, lineHeight:1.75, margin:0, fontStyle:'italic', fontWeight:400 }}>{diaryText}</p>
            )}
            {!generating && !diaryText && (
              <p style={{ fontFamily:T.font, fontSize:13, color:T.textFaint, lineHeight:1.65, margin:0, fontStyle:'italic' }}>How was your day? Tap Generate to write your diary with AI.</p>
            )}
          </div>
        </div>
      </div>

      <FabMenu open={fabOpen} onClose={onFab} onNavigate={onNavigate}/>
      <TabBar active={tab} onTab={onTab} fabOpen={fabOpen} onFab={onFab}/>
    </div>
  );
};

Object.assign(window, { TimelineScreen });
