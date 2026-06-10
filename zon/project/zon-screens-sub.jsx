// zon-screens-sub.jsx — ProfileScreen, ActivityScreen, SettingsScreen, UserSearchScreen

// ── ProfileScreen (Direction D/A: inline avatar row + 3 stats + text tabs) ──
const ProfileScreen = ({ onNavigate, fabOpen, onFab, tab, onTab, params = {} }) => {
  const [activeTab, setActiveTab] = React.useState('stamps');
  const isOwn = !params.userId;
  const me = MOCK.me;

  return (
    <div style={{ width:390, height:844, background:T.surface0, position:'relative', overflow:'hidden', display:'flex', flexDirection:'column', fontFamily:T.font }}>
      <div style={{ background:T.surface1, flexShrink:0 }}>
        <StatusBar/>

        {/* AppBar — username + menu */}
        <div style={{ padding:'2px 8px 2px 16px', display:'flex', alignItems:'center', minHeight:44 }}>
          {!isOwn && <BackButton onBack={() => onNavigate('back')}/>}
          <span style={{ flex:1, fontFamily:T.font, fontSize:15, fontWeight:700, color:T.text }}>@{me.username}</span>
          <button onClick={() => onNavigate('settings')} style={{ width:40, height:40, borderRadius:20, background:'none', border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center' }}>
            <span className="material-symbols-rounded" style={{ fontSize:22, color:T.text }}>{isOwn ? 'settings' : 'more_vert'}</span>
          </button>
        </div>

        <Divider/>

        {/* Identity row — small avatar inline with name + Edit */}
        <div style={{ padding:'16px 18px', display:'flex', alignItems:'center', gap:14, borderBottom:`1px solid ${T.outline}` }}>
          <Avatar size={58} initials="T" ring={false}/>
          <div style={{ flex:1 }}>
            <div style={{ fontFamily:T.font, fontSize:18, fontWeight:700, color:T.text, lineHeight:1.2 }}>{me.name}</div>
            <div style={{ fontFamily:T.font, fontSize:13, color:T.textMuted, marginTop:2 }}>Seoul, Korea</div>
          </div>
          {isOwn ? (
            <button style={{ border:`1.5px solid ${T.outline2}`, borderRadius:8, padding:'6px 16px', fontFamily:T.font, fontSize:13, fontWeight:600, color:T.text, background:'none', cursor:'pointer' }}>Edit</button>
          ) : (
            <div style={{ display:'flex', gap:7 }}>
              <button style={{ height:34, padding:'0 14px', borderRadius:9999, background:T.brand, border:'none', color:'white', fontFamily:T.font, fontSize:13, fontWeight:600, cursor:'pointer' }}>+ Friend</button>
              <button style={{ height:34, padding:'0 14px', borderRadius:9999, border:`1.5px solid ${T.outline2}`, background:'none', fontFamily:T.font, fontSize:13, fontWeight:600, color:T.text, cursor:'pointer' }}>Follow</button>
            </div>
          )}
        </div>

        {/* Stats — 3 only: Stamps · Places · Friends */}
        <div style={{ display:'flex', borderBottom:`1px solid ${T.outline}`, padding:'14px 0' }}>
          {[['34','Stamps'],['12','Places'],['8','Friends']].map(([n, l], i) => (
            <div key={l} style={{ flex:1, textAlign:'center', borderRight: i < 2 ? `1px solid ${T.outline}` : 'none' }}>
              <div style={{ fontFamily:T.font, fontSize:22, fontWeight:800, color:T.brand, lineHeight:1.15 }}>{n}</div>
              <div style={{ fontFamily:T.font, fontSize:12, color:T.textMuted, marginTop:2 }}>{l}</div>
            </div>
          ))}
        </div>

        {/* Tab switch — text only, Direction A style */}
        <div style={{ display:'flex', borderBottom:`1px solid ${T.outline}` }}>
          {['Stamps','Saved','Diaries'].map((label, i) => {
            const id = label.toLowerCase();
            return (
              <button key={id} onClick={() => setActiveTab(id)} style={{ flex:1, textAlign:'center', padding:'10px 0', fontFamily:T.font, fontSize:14, fontWeight: activeTab === id ? 700 : 400, color: activeTab === id ? T.brand : T.textMuted, background:'none', border:'none', cursor:'pointer', borderBottom: activeTab === id ? `2.5px solid ${T.brand}` : '2.5px solid transparent', transition:'all 0.15s' }}>{label}</button>
            );
          })}
        </div>
      </div>

      {/* Content area */}
      <div style={{ flex:1, overflowY:'auto', paddingBottom:83 }}>
        {activeTab !== 'diaries' ? (
          /* 3-col stamp grid */
          <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:2 }}>
            {MOCK.myStamps.map((s, i) => (
              <div key={s.id} onClick={() => onNavigate('stamp-detail', { stampId: s.id })} style={{ position:'relative', cursor:'pointer' }}>
                <ImgPlaceholder height={126} color={s.imgColor}/>
                {i < 2 && isOwn && (
                  <div style={{ position:'absolute', top:5, right:5, width:18, height:18, borderRadius:9, background:'rgba(0,0,0,0.45)', display:'flex', alignItems:'center', justifyContent:'center' }}>
                    <span className="material-symbols-rounded" style={{ fontSize:11, color:'white', fontVariationSettings:"'FILL' 1" }}>lock</span>
                  </div>
                )}
              </div>
            ))}
          </div>
        ) : (
          /* Diaries thread */
          <div style={{ padding:'8px 0' }}>
            {[
              { date:'Sat, Jun 7', text:'A slow Saturday in the city. The morning started with that familiar corner spot — light through frosted glass, the kind of warmth you want to bottle up. Then the river. Always the river. By evening, pasta and a good laugh.' },
              { date:'Fri, Jun 6', text:'Rushed day but a good one. Found a record I\'d been hunting for months at Blue Note. Walked home instead of taking the subway. Seoul is best on foot when you\'re not in a hurry.' },
              { date:'Thu, Jun 5', text:'Nothing much happened, and somehow that was exactly right. Coffee in the morning. Notes in the afternoon. A walk around the neighbourhood before dark.' },
              { date:'Tue, Jun 3', text:'Rainy all day. Stayed in the café until they started stacking chairs. Wrote more than I have in weeks. Sometimes bad weather is the best excuse.' },
              { date:'Mon, Jun 2', text:'First time at the new park. Smaller than I expected but the light hits differently near the water. Went back twice.' },
            ].map((entry, i) => (
              <div key={i} style={{ padding:'18px 20px', borderBottom:`1px solid ${T.outline}` }}>
                <div style={{ fontFamily:T.font, fontSize:11, fontWeight:700, color:T.brand, letterSpacing:'0.06em', textTransform:'uppercase', marginBottom:8 }}>{entry.date}</div>
                <p style={{ fontFamily:T.font, fontSize:14, color:T.text, lineHeight:1.72, margin:0, fontStyle:'italic' }}>{entry.text}</p>
              </div>
            ))}
          </div>
        )}
      </div>

      <FabMenu open={fabOpen} onClose={onFab} onNavigate={onNavigate}/>
      <TabBar active={tab} onTab={onTab} fabOpen={fabOpen} onFab={onFab}/>
    </div>
  );
};

// ── ActivityScreen ────────────────────────────────────────────────────────
const ActivityScreen = ({ onNavigate }) => {
  const requests = MOCK.notifications.filter(n => n.isRequest);
  const rest = MOCK.notifications.filter(n => !n.isRequest);

  return (
    <div style={{ width:390, height:844, background:T.surface0, position:'relative', overflow:'hidden', display:'flex', flexDirection:'column', fontFamily:T.font }}>
      <div style={{ background:T.surface1, flexShrink:0, borderBottom:`1px solid ${T.outline}` }}>
        <StatusBar/>
        <div style={{ padding:'4px 6px 12px', display:'flex', alignItems:'center', gap:4 }}>
          <BackButton onBack={() => onNavigate('back')}/>
          <span style={{ fontFamily:T.font, fontSize:18, fontWeight:700, color:T.text }}>Activity</span>
        </div>
      </div>
      <div style={{ flex:1, overflowY:'auto' }}>
        {requests.length > 0 && (
          <>
            <div style={{ padding:'14px 16px 6px' }}>
              <span style={{ fontFamily:T.font, fontSize:12, fontWeight:700, color:T.textMuted, letterSpacing:'0.06em', textTransform:'uppercase' }}>Friend Requests</span>
            </div>
            {requests.map(n => <NotificationRow key={n.id} notif={n} onAccept={() => {}} onDecline={() => {}}/>)}
            <Divider style={{ margin:'6px 0' }}/>
          </>
        )}
        <div style={{ padding:'14px 16px 6px' }}>
          <span style={{ fontFamily:T.font, fontSize:12, fontWeight:700, color:T.textMuted, letterSpacing:'0.06em', textTransform:'uppercase' }}>Today</span>
        </div>
        {rest.map(n => <NotificationRow key={n.id} notif={n}/>)}
      </div>
    </div>
  );
};

// ── SettingsScreen ────────────────────────────────────────────────────────
const SettingsScreen = ({ onNavigate }) => {
  const [ghost, setGhost] = React.useState(false);
  const [privateAcc, setPrivateAcc] = React.useState(false);

  const sections = [
    { title:'Profile', items:[
      { icon:'person', label:'Edit name & bio', arrow:true },
      { icon:'photo_camera', label:'Change avatar', arrow:true },
    ]},
    { title:'Privacy', items:[
      { icon:'lock', label:'Private account', toggle:true, value:privateAcc, onChange:setPrivateAcc },
      { icon:'visibility_off', label:'Ghost mode', sub:'Hide your live location', toggle:true, value:ghost, onChange:setGhost },
      { icon:'people', label:'Location visibility', sub:'Choose who can see you', arrow:true },
    ]},
    { title:'Notifications', items:[
      { icon:'favorite', label:'Likes', toggle:true, value:true, onChange:()=>{} },
      { icon:'chat_bubble', label:'Comments & mentions', toggle:true, value:true, onChange:()=>{} },
      { icon:'person_add', label:'Friend requests', toggle:true, value:true, onChange:()=>{} },
    ]},
    { title:'Account', items:[
      { icon:'logout', label:'Sign out', arrow:true, destructive:false },
      { icon:'delete', label:'Delete account', arrow:true, destructive:true },
    ]},
  ];

  return (
    <div style={{ width:390, height:844, background:T.surface0, position:'relative', overflow:'hidden', display:'flex', flexDirection:'column', fontFamily:T.font }}>
      <div style={{ background:T.surface1, flexShrink:0, borderBottom:`1px solid ${T.outline}` }}>
        <StatusBar/>
        <div style={{ padding:'4px 6px 12px', display:'flex', alignItems:'center', gap:4 }}>
          <BackButton onBack={() => onNavigate('back')}/>
          <span style={{ fontFamily:T.font, fontSize:18, fontWeight:700, color:T.text }}>Settings</span>
        </div>
      </div>
      <div style={{ flex:1, overflowY:'auto' }}>
        {sections.map(sec => (
          <div key={sec.title} style={{ marginBottom:8 }}>
            <div style={{ padding:'14px 16px 6px' }}>
              <span style={{ fontFamily:T.font, fontSize:12, fontWeight:700, color:T.textMuted, letterSpacing:'0.06em', textTransform:'uppercase' }}>{sec.title}</span>
            </div>
            <div style={{ background:T.surface1, borderTop:`1px solid ${T.outline}`, borderBottom:`1px solid ${T.outline}` }}>
              {sec.items.map((item, i) => (
                <div key={item.label}>
                  <div style={{ display:'flex', alignItems:'center', gap:12, padding:'13px 16px', cursor: item.arrow ? 'pointer' : 'default' }}>
                    <div style={{ width:34, height:34, borderRadius:10, background: item.destructive ? 'rgba(239,68,68,0.1)' : T.brandSoft, display:'flex', alignItems:'center', justifyContent:'center' }}>
                      <span className="material-symbols-rounded" style={{ fontSize:18, color: item.destructive ? T.error : T.brand, fontVariationSettings:"'FILL' 1" }}>{item.icon}</span>
                    </div>
                    <div style={{ flex:1 }}>
                      <div style={{ fontFamily:T.font, fontSize:15, fontWeight:500, color: item.destructive ? T.error : T.text }}>{item.label}</div>
                      {item.sub && <div style={{ fontFamily:T.font, fontSize:12, color:T.textMuted, marginTop:1 }}>{item.sub}</div>}
                    </div>
                    {item.toggle !== undefined && (
                      <div onClick={() => item.onChange?.(!item.value)} style={{ width:48, height:28, borderRadius:14, background: item.value ? T.brand : T.surface3, transition:'background 0.2s', cursor:'pointer', position:'relative', flexShrink:0 }}>
                        <div style={{ position:'absolute', top:3, left: item.value ? 23 : 3, width:22, height:22, borderRadius:11, background:'white', boxShadow:'0 1px 4px rgba(0,0,0,0.18)', transition:'left 0.2s' }}/>
                      </div>
                    )}
                    {item.arrow && <span className="material-symbols-rounded" style={{ fontSize:20, color:T.textFaint }}>chevron_right</span>}
                  </div>
                  {i < sec.items.length - 1 && <Divider mx={62}/>}
                </div>
              ))}
            </div>
          </div>
        ))}
        <div style={{ padding:'16px', textAlign:'center' }}>
          <span style={{ fontFamily:T.font, fontSize:12, color:T.textFaint }}>ZON v2.0 · Made in Seoul</span>
        </div>
      </div>
    </div>
  );
};

// ── UserSearchScreen ──────────────────────────────────────────────────────
const UserSearchScreen = ({ onNavigate }) => {
  const [query, setQuery] = React.useState('');
  const suggested = [
    { initials:'J', name:'Junho Shin', username:'junho_s', stamps:28 },
    { initials:'Y', name:'Yuna Moon', username:'yuna_m', stamps:15 },
    { initials:'H', name:'Heejin Park', username:'heejin_p', stamps:41 },
  ];
  return (
    <div style={{ width:390, height:844, background:T.surface0, position:'relative', overflow:'hidden', display:'flex', flexDirection:'column', fontFamily:T.font }}>
      <div style={{ background:T.surface1, flexShrink:0, borderBottom:`1px solid ${T.outline}` }}>
        <StatusBar/>
        <div style={{ padding:'4px 12px 12px', display:'flex', gap:8, alignItems:'center' }}>
          <BackButton onBack={() => onNavigate('back')}/>
          <SearchBar placeholder="Search people…" value={query} onFocus={() => {}} style={{ flex:1 }}/>
        </div>
      </div>
      <div style={{ flex:1, overflowY:'auto' }}>
        <SectionHeader title="Suggested"/>
        {suggested.map(u => (
          <div key={u.username} style={{ display:'flex', gap:12, alignItems:'center', padding:'10px 16px', borderBottom:`1px solid ${T.outline}` }}>
            <Avatar size={44} initials={u.initials}/>
            <div style={{ flex:1 }}>
              <div style={{ fontFamily:T.font, fontSize:14, fontWeight:700, color:T.text }}>{u.name}</div>
              <div style={{ fontFamily:T.font, fontSize:13, color:T.textMuted }}>@{u.username} · {u.stamps} stamps</div>
            </div>
            <button style={{ height:34, padding:'0 16px', borderRadius:9999, background:T.brand, border:'none', color:'white', fontFamily:T.font, fontSize:13, fontWeight:600, cursor:'pointer' }}>Follow</button>
          </div>
        ))}
      </div>
    </div>
  );
};

Object.assign(window, { ProfileScreen, ActivityScreen, SettingsScreen, UserSearchScreen });
