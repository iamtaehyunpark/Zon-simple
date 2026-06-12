// v3-primitives.jsx — StatusBar, TabBar, FAB, MapCanvas, SearchBar, Pill, Avatar, etc.

const { useState, useRef, useEffect } = React;

// ── StatusBar ──────────────────────────────────────────────────────────────
const StatusBar = ({ dark = false }) => {
  const c = dark ? 'rgba(255,255,255,0.9)' : T.text;
  return (
    <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 22px', fontFamily: T.font, fontSize: 13, fontWeight: 500, color: c, flexShrink: 0, zIndex: 10 }}>
      <span>9:41</span>
      <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
        <svg width="17" height="12" viewBox="0 0 17 12" fill={c}><rect x="0" y="4" width="3" height="8" rx="1" /><rect x="4.5" y="2.5" width="3" height="9.5" rx="1" /><rect x="9" y="0.5" width="3" height="11.5" rx="1" /><rect x="13.5" y="0.5" width="3" height="11.5" rx="1" opacity="0.3" /></svg>
        <svg width="16" height="12" viewBox="0 0 16 12" fill={c}><path d="M8 2.5C5.2 2.5 2.7 3.9 1.1 6.1L2.9 7.9C4.1 6.1 5.9 5 8 5s3.9 1.1 5.1 2.9l1.8-1.8C13.3 3.9 10.8 2.5 8 2.5z" /><path d="M8 6C6.4 6 5 6.9 4.1 8.2l1.8 1.8c.6-.9 1.4-1.5 2.1-1.5s1.5.6 2.1 1.5l1.8-1.8C10.9 6.9 9.5 6 8 6z" /><circle cx="8" cy="11" r="1.5" /></svg>
        <div style={{ width: 25, height: 12, borderRadius: 3, border: `1.5px solid ${c}`, display: 'flex', alignItems: 'center', padding: '1.5px', position: 'relative' }}>
          <div style={{ width: '72%', height: '100%', background: c, borderRadius: 1.5 }} />
          <div style={{ position: 'absolute', right: -4, top: '50%', transform: 'translateY(-50%)', width: 3, height: 6, borderRadius: '0 1.5px 1.5px 0', background: c, opacity: 0.5 }} />
        </div>
      </div>
    </div>);

};

// ── TabBar ─────────────────────────────────────────────────────────────────
const TABS = [
{ id: 'map', icon: 'map', label: 'Map' },
{ id: 'feed', icon: 'article', label: 'Feed' },
{ id: 'fab', icon: 'add', label: '', cta: true },
{ id: 'timeline', icon: 'timeline', label: 'Days' },
{ id: 'profile', icon: 'person', label: 'Me' }];


const TabBar = ({ active, onTab, fabOpen, onFab }) =>
<div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 83, background: T.surface1, borderTop: `0.5px solid ${T.outline}`, display: 'flex', alignItems: 'flex-start', paddingTop: 8, zIndex: 100 }}>
    {TABS.map((tab) =>
  <button key={tab.id} onClick={() => tab.cta ? onFab?.() : onTab?.(tab.id)}
  style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, background: 'none', border: 'none', cursor: 'pointer', padding: '2px 0 0' }}>
        {tab.cta ?
    <div style={{ width: 50, height: 50, borderRadius: 25, background: T.brand, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', marginTop: -18, boxShadow: `0 4px 16px rgba(139,110,196,0.38)`, transition: 'transform 0.2s ease', transform: fabOpen ? 'rotate(45deg) scale(1.05)' : 'none' }}>
            <span className="material-symbols-rounded" style={{ fontSize: 24, fontVariationSettings: "'FILL' 1" }}>add</span>
          </div> :

    <>
            <span className="material-symbols-rounded" style={{ fontSize: 24, color: active === tab.id ? T.brand : T.textFaint, fontVariationSettings: active === tab.id ? "'FILL' 1" : "'FILL' 0", transition: 'color 0.15s' }}>{tab.icon}</span>
            <span style={{ fontSize: 10, fontWeight: 500, fontFamily: T.font, color: active === tab.id ? T.brand : T.textFaint, transition: 'color 0.15s' }}>{tab.label}</span>
          </>
    }
      </button>
  )}
  </div>;


// ── FAB expand menu ────────────────────────────────────────────────────────
const FabMenu = ({ open, onClose, onNavigate }) => {
  if (!open) return null;
  const items = [
  { label: 'Check in', icon: 'location_on', route: 'checkin' },
  { label: 'Photo check-in', icon: 'photo_camera', route: 'photo-checkin' },
  { label: 'Create stamp', icon: 'workspace_premium', route: 'stamp-editor' }];

  return (
    <>
      <div onClick={onClose} style={{ position: 'absolute', inset: 0, zIndex: 98, background: 'rgba(0,0,0,0.10)' }} />
      <div style={{ position: 'absolute', bottom: 83 + 12, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, zIndex: 101, padding: '0 0 4px' }}>
        {items.map((item, i) =>
        <div key={item.route} onClick={() => {onNavigate(item.route);onClose();}}
        style={{ display: 'flex', alignItems: 'center', gap: 12, background: T.surface1, borderRadius: 9999, padding: '10px 20px 10px 14px', boxShadow: '0 4px 20px rgba(0,0,0,0.10)', cursor: 'pointer', animation: `fabIn 0.22s ease-out ${i * 0.06}s both`, minWidth: 180 }}>
            <div style={{ width: 34, height: 34, borderRadius: 17, background: T.surface2, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <span className="material-symbols-rounded" style={{ fontSize: 19, color: T.text, fontVariationSettings: "'FILL' 1" }}>{item.icon}</span>
            </div>
            <span style={{ fontFamily: T.font, fontSize: 14, fontWeight: 600, color: T.text }}>{item.label}</span>
          </div>
        )}
      </div>
    </>);

};

// ── MapCanvas ──────────────────────────────────────────────────────────────
const MapCanvas = ({ height = 432, showRoute = true, showClusters = true, mini = false, onClusterTap, onPinTap }) => {
  const W = 390,H = height;
  const route = `M 52,${H - 28} C 90,${H - 80} 122,${H - 130} 158,${H * 0.52} S 228,${H * 0.36} 272,${H * 0.265} S 320,${H * 0.115} 340,${H * 0.09}`;
  const autoDots = [{ x: 70, y: H - 55 }, { x: 88, y: H - 82 }, { x: 106, y: H - 110 }, { x: 128, y: H - 145 }, { x: 148, y: H * 0.58 }, { x: 198, y: H * 0.435 }, { x: 228, y: H * 0.36 }, { x: 255, y: H * 0.305 }];
  const myStamps = [{ x: 158, y: H * 0.52 }, { x: 272, y: H * 0.265 }];
  const curLoc = { x: 340, y: H * 0.09 };
  const followed = [{ x: 98, y: H * 0.42 }, { x: 318, y: H * 0.47 }];
  const storyPin = { x: 186, y: H * 0.285 };
  const clusters = [{ x: 80, y: 96, n: 3 }, { x: 196, y: 68, n: 7 }, { x: 316, y: 52, n: 2 }, { x: 140, y: H * 0.64, n: 4 }, { x: 336, y: H * 0.52, n: 1 }];

  return (
    <div style={{ width: W, height: H, position: 'relative', overflow: 'hidden', flexShrink: 0, background: T.mapBase }}>
      <svg width={W} height={H} viewBox={`0 0 ${W} ${H}`} style={{ display: 'block', position: 'absolute', inset: 0 }}>
        <rect width={W} height={H} fill={T.mapBase} />
        <path d={`M 0,${H * 0.74} C 90,${H * 0.7} 190,${H * 0.76} 285,${H * 0.71} S 375,${H * 0.67} ${W},${H * 0.69} L ${W},${H * 0.84} C 375,${H * 0.86} 190,${H * 0.82} 90,${H * 0.85} S 10,${H * 0.83} 0,${H * 0.82}Z`} fill={T.mapWater} />
        <ellipse cx="308" cy={H * 0.47} rx="52" ry="28" fill={T.mapGreen} />
        <ellipse cx="355" cy={H * 0.59} rx="32" ry="18" fill={T.mapGreen} opacity="0.75" />
        {[H * 0.2, H * 0.375, H * 0.535, H * 0.68].map((y, i) => <line key={`mh${i}`} x1="0" y1={y} x2={W} y2={y} stroke={T.mapStreet} strokeWidth="11" />)}
        {[H * 0.11, H * 0.29, H * 0.46, H * 0.61].map((y, i) => <line key={`sh${i}`} x1="0" y1={y} x2={W} y2={y} stroke={T.mapStreet} strokeWidth="6" />)}
        {[78, 155, 232, 308].map((x, i) => <line key={`mv${i}`} x1={x} y1="0" x2={x} y2={H} stroke={T.mapStreet} strokeWidth="11" />)}
        {[38, 116, 194, 270, 348].map((x, i) => <line key={`sv${i}`} x1={x} y1="0" x2={x} y2={H} stroke={T.mapStreet} strokeWidth="6" />)}
        <line x1="0" y1={H * 0.32} x2={W} y2={H * 0.1} stroke={T.mapStreet} strokeWidth="13" />
        {showRoute && <>
          <path d={route} stroke="rgba(0,0,0,0.04)" strokeWidth="10" fill="none" strokeLinecap="round" strokeLinejoin="round" />
          <path d={route} stroke={T.brand} strokeWidth="4" fill="none" strokeLinecap="round" strokeLinejoin="round" opacity="0.9" />
        </>}
        {autoDots.map((d, i) => <circle key={i} cx={d.x} cy={d.y} r="2.5" fill={T.auto} opacity="0.5" />)}
        {!mini && followed.map((f, i) =>
        <g key={i}>
            <circle cx={f.x} cy={f.y} r="11" fill="#F59E0B" stroke="white" strokeWidth="2.5" opacity="0.9" />
            <text x={f.x} y={f.y + 4} textAnchor="middle" fontSize="9" fontWeight="600" fill="white" fontFamily="Poppins,sans-serif">ZN</text>
          </g>
        )}
        {!mini && <>
          <circle cx={storyPin.x} cy={storyPin.y} r="13" fill="none" stroke="#EC4899" strokeWidth="2.5" opacity="0.85" />
          <circle cx={storyPin.x} cy={storyPin.y} r="5.5" fill="#EC4899" opacity="0.85" />
        </>}
        {myStamps.map((p, i) =>
        <g key={i} onClick={() => onPinTap?.(p)} style={{ cursor: onPinTap ? 'pointer' : 'default' }}>
            <circle cx={p.x} cy={p.y - 11} r="10" fill={T.brand} stroke="white" strokeWidth="2.5" />
            <polygon points={`${p.x - 5},${p.y - 4.5} ${p.x + 5},${p.y - 4.5} ${p.x},${p.y + 4}`} fill={T.brand} />
            <circle cx={p.x} cy={p.y - 11} r="3.8" fill="white" />
          </g>
        )}
        {showClusters && !mini && clusters.map((c, i) =>
        <g key={i} onClick={() => onClusterTap?.(c)} style={{ cursor: 'pointer' }}>
            <circle cx={c.x} cy={c.y} r="17" fill="rgba(255,255,255,0.96)" stroke={T.brand} strokeWidth="1.5" />
            <text x={c.x} y={c.y + 5} textAnchor="middle" fontSize="13" fontWeight="600" fill={T.brand} fontFamily="Poppins,sans-serif">{c.n}</text>
          </g>
        )}
        <circle cx={curLoc.x} cy={curLoc.y} r="20" fill={T.brand} opacity="0.12" />
        <circle cx={curLoc.x} cy={curLoc.y} r="9.5" fill={T.brand} stroke="white" strokeWidth="2.5" />
        <circle cx={curLoc.x} cy={curLoc.y} r="3.5" fill="white" />
      </svg>
    </div>);

};

// ── SearchBar ─────────────────────────────────────────────────────────────
const SearchBar = ({ placeholder = 'Search…', value, onChange, onFocus, style = {} }) =>
<div onClick={onFocus} style={{ height: 44, borderRadius: 9999, background: T.surface1, border: `1px solid ${T.outline2}`, display: 'flex', alignItems: 'center', gap: 10, padding: '0 16px', boxShadow: '0 1px 4px rgba(0,0,0,0.04)', cursor: 'text', ...style }}>
    <span className="material-symbols-rounded" style={{ fontSize: 19, color: T.textMuted }}>search</span>
    <span style={{ fontFamily: T.font, fontSize: 14, fontWeight: 400, color: T.textFaint, flex: 1 }}>{value || placeholder}</span>
    {value && <span className="material-symbols-rounded" style={{ fontSize: 18, color: T.textMuted }}>close</span>}
  </div>;


// ── Pill / chip ───────────────────────────────────────────────────────────
const Pill = ({ children, active, color, style = {}, onClick }) =>
<button onClick={onClick} style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: active ? color || T.brand : T.surface1, color: active ? 'white' : T.text, borderRadius: 9999, padding: '6px 14px', fontSize: 12, fontWeight: active ? 600 : 400, fontFamily: T.font, border: `1px solid ${active ? color || T.brand : T.outline2}`, cursor: 'pointer', flexShrink: 0, transition: 'all 0.15s', whiteSpace: 'nowrap', ...style }}>
    {children}
  </button>;


// ── Avatar ────────────────────────────────────────────────────────────────
const Avatar = ({ size = 40, initials = '?', ring = false, ringColors = [T.brand, T.story], style = {} }) =>
<div style={{ position: 'relative', width: size, height: size, flexShrink: 0, ...style }}>
    {ring && <div style={{ position: 'absolute', inset: -2.5, borderRadius: '50%', background: `linear-gradient(135deg, ${ringColors[0]}, ${ringColors[1]})` }} />}
    <div style={{ position: 'absolute', inset: ring ? 2.5 : 0, borderRadius: '50%', background: T.surface2, border: `1px solid ${T.outline}`, display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
      <span style={{ fontFamily: T.font, fontSize: size * 0.35, fontWeight: 600, color: T.textMuted }}>{initials}</span>
    </div>
  </div>;


// ── ImgPlaceholder ────────────────────────────────────────────────────────
const ImgPlaceholder = ({ width = '100%', height = 200, color = T.surface2, label, style = {} }) =>
<div style={{ width, height, background: color, position: 'relative', overflow: 'hidden', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', ...style }}>
    <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.12 }} preserveAspectRatio="none">
      <line x1="0" y1="0" x2="100%" y2="100%" stroke={T.textFaint} strokeWidth="1" />
      <line x1="100%" y1="0" x2="0" y2="100%" stroke={T.textFaint} strokeWidth="1" />
    </svg>
    {label && <span style={{ fontFamily: T.font, fontSize: 11, color: T.textMuted, background: 'rgba(255,255,255,0.7)', padding: '2px 7px', borderRadius: 4, position: 'relative', zIndex: 1 }}>{label}</span>}
  </div>;


// ── BackButton ────────────────────────────────────────────────────────────
const BackButton = ({ onBack, dark = false }) =>
<button onClick={onBack} style={{ width: 40, height: 40, borderRadius: 20, background: dark ? 'rgba(0,0,0,0.3)' : 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', color: dark ? 'white' : T.text, flexShrink: 0 }}>
    <span className="material-symbols-rounded" style={{ fontSize: 22 }}>arrow_back</span>
  </button>;


// ── BottomHandle ──────────────────────────────────────────────────────────
const BottomHandle = () =>
<div style={{ display: 'flex', justifyContent: 'center', padding: '10px 0 6px' }}>
    <div style={{ width: 36, height: 4, borderRadius: 2, background: T.outline2 }} />
  </div>;


// ── Divider ───────────────────────────────────────────────────────────────
const Divider = ({ mx = 0, style = {} }) =>
<div style={{ height: 0.5, background: T.outline, margin: `0 ${mx}px`, ...style }} />;


// ── SectionHeader ─────────────────────────────────────────────────────────
const SectionHeader = ({ title, action, onAction }) =>
<div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px 6px' }} data-comment-anchor="f11ccffb7e-div-195-3">
    <span style={{ fontFamily: T.font, fontSize: 13, fontWeight: 600, color: T.text }}>{title}</span>
    {action && <button onClick={onAction} style={{ fontFamily: T.font, fontSize: 12, color: T.textMuted, background: 'none', border: 'none', cursor: 'pointer', fontWeight: 400 }}>{action}</button>}
  </div>;


Object.assign(window, { StatusBar, TabBar, FabMenu, MapCanvas, SearchBar, Pill, Avatar, ImgPlaceholder, BackButton, BottomHandle, Divider, SectionHeader });