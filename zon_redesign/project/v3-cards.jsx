// v3-cards.jsx — StampCard, StoriesRail, TimelineNode, NearbyCard, NotificationRow

const KIND = {
  checkin: { label:'Check-in', color:'#3B82F6', soft:'rgba(59,130,246,0.10)', icon:'location_on' },
  stamp:   { label:'Stamp',    color:T.brand,   soft:T.brandSoft,             icon:'workspace_premium' },
  note:    { label:'Note',     color:'#D97706', soft:'rgba(217,119,6,0.08)',  icon:'edit_note' },
  auto:    { label:'Auto',     color:T.auto,    soft:T.autoSoft,              icon:'radio_button_unchecked' },
};

// ── KindChip ──────────────────────────────────────────────────────────────
const KindChip = ({ kind }) => {
  const m = KIND[kind] || KIND.checkin;
  return (
    <span style={{ display:'inline-flex', alignItems:'center', gap:4, background:m.soft, color:m.color, borderRadius:9999, padding:'2px 8px', fontSize:10, fontWeight:600, fontFamily:T.font, letterSpacing:'0.04em', textTransform:'uppercase' }}>
      <span className="material-symbols-rounded" style={{ fontSize:11, fontVariationSettings:"'FILL' 1" }}>{m.icon}</span>
      {m.label}
    </span>
  );
};

// ── StampCard — v3: shadow, neutral tags, restrained color ────────────────
const StampCard = ({ stamp, onTap }) => {
  const [liked, setLiked] = React.useState(stamp.liked);
  const [saved, setSaved] = React.useState(stamp.saved);
  const dir = () => (window.THEME || {}).direction || 'A';

  return (
    <div onClick={onTap} style={{ background:T.surface1, borderRadius:16, overflow:'hidden', marginBottom:8, boxShadow:'0 1px 8px rgba(0,0,0,0.06), 0 0 0 0.5px rgba(0,0,0,0.04)', cursor:'pointer' }}>
      {/* Photo + overlay */}
      <div style={{ position:'relative' }}>
        <ImgPlaceholder height={222} color={stamp.imgColor}/>
        <div style={{ position:'absolute', bottom:0, left:0, right:0, height:100, background:'linear-gradient(transparent, rgba(0,0,0,0.6))' }}/>
        <div style={{ position:'absolute', bottom:10, left:13, right:13, display:'flex', justifyContent:'space-between', alignItems:'flex-end' }}>
          <div>
            <div style={{ display:'flex', alignItems:'center', gap:5, marginBottom:2 }}>
              <span className="material-symbols-rounded" style={{ fontSize:13, color:'white', fontVariationSettings:"'FILL' 1" }}>location_on</span>
              <span style={{ fontFamily:T.font, fontSize:13, fontWeight:600, color:'white' }}>{stamp.place}</span>
            </div>
            <span style={{ fontFamily:T.font, fontSize:11, color:'rgba(255,255,255,0.72)' }}>@{stamp.user}</span>
          </div>
          <span style={{ fontFamily:T.font, fontSize:11, color:'rgba(255,255,255,0.58)' }}>{stamp.time}</span>
        </div>
      </div>

      {/* Body */}
      <div style={{ padding:'12px 14px 14px' }}>
        {stamp.caption && (
          <p style={{ fontFamily:T.font, fontSize:13, color:T.text, lineHeight:1.65, marginBottom:10, fontStyle:'italic', fontWeight:400 }}>
            "{stamp.caption}"
          </p>
        )}
        {stamp.tags?.length > 0 && (
          <div style={{ display:'flex', gap:6, flexWrap:'wrap', marginBottom:11 }}>
            {stamp.tags.map(tag => (
              <span key={tag} style={{ fontFamily:T.font, fontSize:11, fontWeight:500, color: dir()==='B' ? T.brand : T.text, background: dir()==='B' ? T.brandSoft : T.surface2, borderRadius:9999, padding:'2px 10px' }}>
                #{tag}
              </span>
            ))}
          </div>
        )}
        <div style={{ display:'flex', alignItems:'center', gap:16 }}>
          <button onClick={e => { e.stopPropagation(); setLiked(v => !v); }} style={{ display:'flex', alignItems:'center', gap:5, background:'none', border:'none', cursor:'pointer', padding:0 }}>
            <span className="material-symbols-rounded" style={{ fontSize:20, color: liked ? '#EF4444' : T.textFaint, fontVariationSettings: liked ? "'FILL' 1" : "'FILL' 0", transition:'color 0.15s' }}>favorite</span>
            <span style={{ fontFamily:T.font, fontSize:12, color:T.textMuted }}>{stamp.likes + (liked && !stamp.liked ? 1 : !liked && stamp.liked ? -1 : 0)}</span>
          </button>
          <button style={{ display:'flex', alignItems:'center', gap:5, background:'none', border:'none', cursor:'pointer', padding:0 }}>
            <span className="material-symbols-rounded" style={{ fontSize:20, color:T.textFaint }}>chat_bubble_outline</span>
            <span style={{ fontFamily:T.font, fontSize:12, color:T.textMuted }}>{stamp.comments}</span>
          </button>
          <div style={{ marginLeft:'auto' }}>
            <button onClick={e => { e.stopPropagation(); setSaved(v => !v); }} style={{ background:'none', border:'none', cursor:'pointer', padding:4, display:'flex' }}>
              <span className="material-symbols-rounded" style={{ fontSize:20, color: saved ? (dir()==='B' ? T.brand : T.text) : T.textFaint, fontVariationSettings: saved ? "'FILL' 1" : "'FILL' 0", transition:'color 0.15s' }}>bookmark</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

// ── StoriesRail ────────────────────────────────────────────────────────────
const StoriesRail = ({ stories, onStoryTap }) => (
  <div style={{ borderBottom:`0.5px solid ${T.outline}`, flexShrink:0 }}>
    <div style={{ display:'flex', gap:0, padding:'12px 4px 14px', overflowX:'auto' }}>
      {stories.map(s => (
        <button key={s.id} onClick={() => onStoryTap?.(s)} style={{ width:72, display:'flex', flexDirection:'column', alignItems:'center', gap:5, background:'none', border:'none', cursor:'pointer', padding:'0 4px', flexShrink:0 }}>
          <div style={{ position:'relative' }}>
            <Avatar size={52} initials={s.initials} ring={s.hasStory} ringColors={[T.brand, T.story]}/>
            {s.isOwn && !s.hasStory && (
              <div style={{ position:'absolute', bottom:0, right:0, width:18, height:18, borderRadius:9, background:T.brand, border:`2px solid ${T.surface1}`, display:'flex', alignItems:'center', justifyContent:'center' }}>
                <span className="material-symbols-rounded" style={{ fontSize:11, color:'white', fontVariationSettings:"'FILL' 1" }}>add</span>
              </div>
            )}
          </div>
          <span style={{ fontFamily:T.font, fontSize:10, fontWeight:500, color:T.textMuted, maxWidth:64, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>{s.name}</span>
        </button>
      ))}
    </div>
  </div>
);

// ── TimelineNode ──────────────────────────────────────────────────────────
const TimelineNode = ({ item, isLast, onExpand }) => {
  const m = KIND[item.isAuto ? 'auto' : item.kind] || KIND.checkin;
  const isNote = item.kind === 'note';
  return (
    <div style={{ display:'flex', gap:0 }}>
      <div style={{ width:52, display:'flex', flexDirection:'column', alignItems:'center', flexShrink:0 }}>
        <div style={{ width:28, height:28, borderRadius:14, background:m.soft, border:`1.5px solid ${m.color}`, display:'flex', alignItems:'center', justifyContent:'center', marginTop:14, flexShrink:0 }}>
          <span className="material-symbols-rounded" style={{ fontSize:13, color:m.color, fontVariationSettings:"'FILL' 1" }}>{m.icon}</span>
        </div>
        {!isLast && <div style={{ width:1, flex:1, background:T.outline2, minHeight:20, marginTop:4 }}/>}
      </div>
      <div onClick={() => onExpand?.(item.id)} style={{ flex:1, paddingTop:12, paddingRight:16, paddingBottom:16, cursor:'pointer' }}>
        <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:4 }}>
          <span style={{ fontFamily:T.font, fontSize:11, color:T.textMuted, fontWeight:500 }}>{item.time}</span>
          <KindChip kind={item.isAuto ? 'auto' : item.kind}/>
        </div>
        {!isNote && item.place && (
          <div style={{ fontFamily:T.font, fontSize:14, fontWeight:600, color:T.text, marginBottom: item.text ? 4 : 0 }}>{item.place}</div>
        )}
        {item.text && (
          <p style={{ fontFamily:T.font, fontSize:13, color: isNote ? '#D97706' : T.textMuted, lineHeight:1.6, margin:0, fontStyle: isNote ? 'italic' : 'normal' }}>{item.text}</p>
        )}
        {item.photos > 0 && (
          <div style={{ display:'flex', gap:5, marginTop:8 }}>
            {Array.from({ length: Math.min(item.photos, 3) }).map((_,i) => (
              <ImgPlaceholder key={i} width={56} height={56} color={T.surface2} style={{ borderRadius:8 }}/>
            ))}
          </div>
        )}
        {item.kind === 'checkin' && !item.isAuto && (
          <button onClick={e => e.stopPropagation()} style={{ marginTop:8, fontFamily:T.font, fontSize:11, fontWeight:600, color:T.brand, background:T.brandSoft, border:'none', borderRadius:9999, padding:'3px 10px', cursor:'pointer' }}>
            Promote to stamp →
          </button>
        )}
      </div>
    </div>
  );
};

// ── NearbyCard — v3: photo thumbnail, Naver-map style ─────────────────────
const NearbyCard = ({ place, onTap }) => (
  <div onClick={onTap} style={{ background:T.surface1, borderRadius:14, overflow:'hidden', flexShrink:0, width:148, cursor:'pointer', boxShadow:'0 1px 6px rgba(0,0,0,0.06)', border:`0.5px solid ${T.outline}` }}>
    <ImgPlaceholder height={88} color={place.imgColor || T.surface2}/>
    <div style={{ padding:'8px 10px 10px' }}>
      <div style={{ fontFamily:T.font, fontSize:12, fontWeight:600, color:T.text, lineHeight:1.35, marginBottom:3 }}>{place.name}</div>
      <div style={{ fontFamily:T.font, fontSize:11, color:T.textMuted, marginBottom:5 }}>{place.category} · {place.dist}</div>
      <div style={{ display:'inline-flex', alignItems:'center', gap:3, background:T.brandSoft, borderRadius:9999, padding:'2px 7px' }}>
        <span style={{ fontFamily:T.font, fontSize:10, fontWeight:600, color:T.brand }}>{place.stamps} stamps</span>
      </div>
    </div>
  </div>
);

// ── NotificationRow ───────────────────────────────────────────────────────
const NotificationRow = ({ notif, onAccept, onDecline }) => (
  <div style={{ display:'flex', gap:12, alignItems:'flex-start', padding:'12px 16px', borderBottom:`0.5px solid ${T.outline}` }}>
    <Avatar size={40} initials={notif.initials}/>
    <div style={{ flex:1 }}>
      <div style={{ fontFamily:T.font, fontSize:13, color:T.text, lineHeight:1.55, marginBottom:3 }}>
        <span style={{ fontWeight:600 }}>@{notif.user}</span>{' '}{notif.text}
      </div>
      <div style={{ fontFamily:T.font, fontSize:11, color:T.textMuted }}>{notif.time}</div>
      {notif.isRequest && (
        <div style={{ display:'flex', gap:8, marginTop:8 }}>
          <button onClick={onAccept} style={{ flex:1, height:32, borderRadius:9999, background:T.text, border:'none', color:'white', fontFamily:T.font, fontSize:12, fontWeight:600, cursor:'pointer' }}>Accept</button>
          <button onClick={onDecline} style={{ flex:1, height:32, borderRadius:9999, background:'none', border:`1px solid ${T.outline2}`, color:T.textMuted, fontFamily:T.font, fontSize:12, fontWeight:500, cursor:'pointer' }}>Decline</button>
        </div>
      )}
    </div>
    {!notif.isRequest && notif.type !== 'follow' && (
      <ImgPlaceholder width={44} height={44} color={T.surface2} style={{ borderRadius:8, flexShrink:0 }}/>
    )}
  </div>
);

Object.assign(window, { KIND, KindChip, StampCard, StoriesRail, TimelineNode, NearbyCard, NotificationRow });
