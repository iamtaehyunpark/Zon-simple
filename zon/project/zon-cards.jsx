// zon-cards.jsx — StampCard, StoriesRail, TimelineNode, NearbyCard, NotificationRow, KindChip

const KIND = {
  checkin: { label:'Check-in', color:'#3B82F6', soft:'rgba(59,130,246,0.12)', icon:'location_on' },
  stamp:   { label:'Stamp',    color:T.brand,   soft:T.brandSoft,             icon:'workspace_premium' },
  note:    { label:'Note',     color:'#D97706', soft:'rgba(217,119,6,0.1)',   icon:'edit_note' },
  auto:    { label:'Auto',     color:T.auto,    soft:'rgba(156,163,175,0.12)',icon:'radio_button_unchecked' },
};

// ── KindChip ──────────────────────────────────────────────────────────────
const KindChip = ({ kind }) => {
  const m = KIND[kind] || KIND.checkin;
  return (
    <span style={{ display:'inline-flex', alignItems:'center', gap:4, background:m.soft, color:m.color, borderRadius:9999, padding:'2px 9px', fontSize:11, fontWeight:700, fontFamily:T.font, letterSpacing:'0.03em', textTransform:'uppercase' }}>
      <span className="material-symbols-rounded" style={{ fontSize:12, fontVariationSettings:"'FILL' 1" }}>{m.icon}</span>
      {m.label}
    </span>
  );
};

// ── StampCard (photo-first, Direction C feed style) ───────────────────────
const StampCard = ({ stamp, onTap }) => {
  const [liked, setLiked] = React.useState(stamp.liked);
  const [saved, setSaved] = React.useState(stamp.saved);

  return (
    <div onClick={onTap} style={{ background:T.surface1, borderRadius:16, overflow:'hidden', marginBottom:12, border:`1px solid ${T.outline}`, cursor:'pointer', boxShadow:'0 1px 4px rgba(0,0,0,0.04)' }}>
      {/* Photo with overlay */}
      <div style={{ position:'relative' }}>
        <ImgPlaceholder height={222} color={stamp.imgColor} />
        {/* Scrim */}
        <div style={{ position:'absolute', bottom:0, left:0, right:0, height:88, background:'linear-gradient(transparent, rgba(20,16,12,0.62))' }}/>
        {/* Place + user overlay */}
        <div style={{ position:'absolute', bottom:10, left:13, right:13, display:'flex', justifyContent:'space-between', alignItems:'flex-end' }}>
          <div>
            <div style={{ display:'flex', alignItems:'center', gap:5, marginBottom:2 }}>
              <span className="material-symbols-rounded" style={{ fontSize:14, color:'white', fontVariationSettings:"'FILL' 1" }}>location_on</span>
              <span style={{ fontFamily:T.font, fontSize:14, fontWeight:700, color:'white' }}>{stamp.place}</span>
            </div>
            <span style={{ fontFamily:T.font, fontSize:12, color:'rgba(255,255,255,0.78)' }}>@{stamp.user}</span>
          </div>
          <span style={{ fontFamily:T.font, fontSize:11, color:'rgba(255,255,255,0.65)' }}>{stamp.time}</span>
        </div>
      </div>

      {/* Card body */}
      <div style={{ padding:'12px 14px 14px' }}>
        {stamp.caption && (
          <p style={{ fontFamily:T.font, fontSize:14, color:T.text, lineHeight:1.58, marginBottom:10, fontStyle:'italic' }}>
            "{stamp.caption}"
          </p>
        )}
        {stamp.tags?.length > 0 && (
          <div style={{ display:'flex', gap:6, flexWrap:'wrap', marginBottom:11 }}>
            {stamp.tags.map(tag => (
              <span key={tag} style={{ fontFamily:T.font, fontSize:11, fontWeight:600, color:T.brand, background:T.brandSoft, borderRadius:9999, padding:'2px 10px' }}>#{tag}</span>
            ))}
          </div>
        )}
        <div style={{ display:'flex', alignItems:'center', gap:16 }}>
          <button onClick={e => { e.stopPropagation(); setLiked(v => !v); }} style={{ display:'flex', alignItems:'center', gap:5, background:'none', border:'none', cursor:'pointer', padding:0 }}>
            <span className="material-symbols-rounded" style={{ fontSize:21, color: liked ? '#EF4444' : T.textMuted, fontVariationSettings: liked ? "'FILL' 1" : "'FILL' 0", transition:'color 0.15s' }}>favorite</span>
            <span style={{ fontFamily:T.font, fontSize:13, color:T.textMuted }}>{stamp.likes + (liked && !stamp.liked ? 1 : !liked && stamp.liked ? -1 : 0)}</span>
          </button>
          <button style={{ display:'flex', alignItems:'center', gap:5, background:'none', border:'none', cursor:'pointer', padding:0 }}>
            <span className="material-symbols-rounded" style={{ fontSize:21, color:T.textMuted }}>chat_bubble_outline</span>
            <span style={{ fontFamily:T.font, fontSize:13, color:T.textMuted }}>{stamp.comments}</span>
          </button>
          <div style={{ marginLeft:'auto' }}>
            <button onClick={e => { e.stopPropagation(); setSaved(v => !v); }} style={{ background:'none', border:'none', cursor:'pointer', padding:4, display:'flex' }}>
              <span className="material-symbols-rounded" style={{ fontSize:21, color: saved ? T.brand : T.textMuted, fontVariationSettings: saved ? "'FILL' 1" : "'FILL' 0", transition:'color 0.15s' }}>bookmark</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

// ── StoriesRail ────────────────────────────────────────────────────────────
const StoriesRail = ({ stories, onStoryTap }) => (
  <div style={{ borderBottom:`1px solid ${T.outline}`, flexShrink:0 }}>
    <div style={{ display:'flex', gap:0, padding:'10px 4px 12px', overflowX:'auto' }}>
      {stories.map(s => (
        <button key={s.id} onClick={() => onStoryTap?.(s)} style={{ width:76, display:'flex', flexDirection:'column', alignItems:'center', gap:5, background:'none', border:'none', cursor:'pointer', padding:'0 4px', flexShrink:0 }}>
          <div style={{ position:'relative' }}>
            <Avatar size={54} initials={s.initials} ring={s.hasStory} ringColors={[T.brand, T.story]}/>
            {s.isOwn && !s.hasStory && (
              <div style={{ position:'absolute', bottom:0, right:0, width:18, height:18, borderRadius:9, background:T.brand, border:`2px solid ${T.surface1}`, display:'flex', alignItems:'center', justifyContent:'center' }}>
                <span className="material-symbols-rounded" style={{ fontSize:11, color:'white', fontVariationSettings:"'FILL' 1" }}>add</span>
              </div>
            )}
          </div>
          <span style={{ fontFamily:T.font, fontSize:11, color:T.text, maxWidth:68, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>{s.name}</span>
        </button>
      ))}
    </div>
  </div>
);

// ── TimelineNode ──────────────────────────────────────────────────────────
const TimelineNode = ({ item, isLast, onExpand, expanded }) => {
  const m = KIND[item.isAuto ? 'auto' : item.kind] || KIND.checkin;
  const isNote = item.kind === 'note';

  return (
    <div style={{ display:'flex', gap:0 }}>
      {/* Left rail */}
      <div style={{ width:52, display:'flex', flexDirection:'column', alignItems:'center', flexShrink:0 }}>
        <div style={{ width:28, height:28, borderRadius:14, background:m.soft, border:`2px solid ${m.color}`, display:'flex', alignItems:'center', justifyContent:'center', marginTop:14, flexShrink:0 }}>
          <span className="material-symbols-rounded" style={{ fontSize:14, color:m.color, fontVariationSettings:"'FILL' 1" }}>{m.icon}</span>
        </div>
        {!isLast && <div style={{ width:2, flex:1, background:T.outline, minHeight:20, marginTop:4 }}/>}
      </div>

      {/* Content */}
      <div onClick={() => onExpand?.(item.id)} style={{ flex:1, paddingTop:12, paddingRight:16, paddingBottom:16, cursor:'pointer' }}>
        <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:4 }}>
          <span style={{ fontFamily:T.font, fontSize:12, color:T.textMuted, fontWeight:500 }}>{item.time}</span>
          <KindChip kind={item.isAuto ? 'auto' : item.kind}/>
        </div>
        {!isNote && item.place && (
          <div style={{ fontFamily:T.font, fontSize:15, fontWeight:700, color:T.text, marginBottom: item.text ? 4 : 0 }}>{item.place}</div>
        )}
        {item.text && (
          <p style={{ fontFamily:T.font, fontSize:14, color: isNote ? T.note : T.textMuted, lineHeight:1.55, margin:0, fontStyle: isNote ? 'italic' : 'normal' }}>{item.text}</p>
        )}
        {/* Photo thumbs */}
        {item.photos > 0 && (
          <div style={{ display:'flex', gap:6, marginTop:8 }}>
            {Array.from({ length: Math.min(item.photos, 3) }).map((_, i) => (
              <ImgPlaceholder key={i} width={60} height={60} color={T.surface2} style={{ borderRadius:8 }}/>
            ))}
          </div>
        )}
        {/* Promote to stamp CTA (only on checkin, not auto) */}
        {item.kind === 'checkin' && !item.isAuto && !item.stampId && (
          <button onClick={e => { e.stopPropagation(); }} style={{ marginTop:8, fontFamily:T.font, fontSize:12, fontWeight:600, color:T.brand, background:T.brandSoft, border:'none', borderRadius:9999, padding:'4px 12px', cursor:'pointer' }}>
            Promote to stamp →
          </button>
        )}
      </div>
    </div>
  );
};

// ── NearbyCard ────────────────────────────────────────────────────────────
const NearbyCard = ({ place, onTap }) => (
  <div onClick={onTap} style={{ border:`1.5px solid ${T.outline}`, borderRadius:14, padding:'10px 12px', background:T.surface1, flexShrink:0, minWidth:128, cursor:'pointer' }}>
    <div style={{ fontSize:24, marginBottom:5 }}>{place.emoji}</div>
    <div style={{ fontFamily:T.font, fontSize:13, fontWeight:700, color:T.text, lineHeight:1.35, marginBottom:2 }}>{place.name}</div>
    <div style={{ fontFamily:T.font, fontSize:11, color:T.textMuted }}>{place.stamps} stamps · {place.dist}</div>
  </div>
);

// ── NotificationRow ───────────────────────────────────────────────────────
const NotificationRow = ({ notif, onAccept, onDecline }) => (
  <div style={{ display:'flex', gap:12, alignItems:'flex-start', padding:'12px 16px', borderBottom:`1px solid ${T.outline}` }}>
    <Avatar size={40} initials={notif.initials} ring={false}/>
    <div style={{ flex:1 }}>
      <div style={{ fontFamily:T.font, fontSize:14, color:T.text, lineHeight:1.5, marginBottom:3 }}>
        <span style={{ fontWeight:700 }}>@{notif.user}</span> {notif.text}
      </div>
      <div style={{ fontFamily:T.font, fontSize:12, color:T.textMuted }}>{notif.time}</div>
      {notif.isRequest && (
        <div style={{ display:'flex', gap:8, marginTop:8 }}>
          <button onClick={onAccept} style={{ flex:1, height:34, borderRadius:9999, background:T.brand, border:'none', color:'white', fontFamily:T.font, fontSize:13, fontWeight:600, cursor:'pointer' }}>Accept</button>
          <button onClick={onDecline} style={{ flex:1, height:34, borderRadius:9999, background:'none', border:`1.5px solid ${T.outline2}`, color:T.textMuted, fontFamily:T.font, fontSize:13, fontWeight:600, cursor:'pointer' }}>Decline</button>
        </div>
      )}
    </div>
    {!notif.isRequest && notif.type !== 'follow' && (
      <ImgPlaceholder width={44} height={44} color={T.surface2} style={{ borderRadius:8, flexShrink:0 }}/>
    )}
  </div>
);

Object.assign(window, { KIND, KindChip, StampCard, StoriesRail, TimelineNode, NearbyCard, NotificationRow });
