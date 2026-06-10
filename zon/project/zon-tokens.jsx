// ZON Design Tokens — Direction D (Final)
// Accent: Warm Purple #8B6EC4 · Background: #F7F4EE

const T = {
  brand:      '#8B6EC4',
  brandDark:  '#6B50A4',
  brandLight: '#A98EDC',
  brandSoft:  'rgba(139,110,196,0.13)',
  brandSoft2: 'rgba(139,110,196,0.06)',

  checkin:     '#3B82F6',
  checkinSoft: 'rgba(59,130,246,0.12)',
  following:   '#F59E0B',
  story:       '#EC4899',
  note:        '#D97706',
  noteSoft:    'rgba(217,119,6,0.1)',
  auto:        '#9CA3AF',
  error:       '#EF4444',
  success:     '#10B981',

  surface0: '#F7F4EE',
  surface1: '#FFFFFF',
  surface2: '#F0EDE6',
  surface3: '#E8E4DC',

  text:      '#1A1714',
  textMuted: '#8A8278',
  textFaint: '#C0BAB2',

  outline:  '#E8E4DC',
  outline2: '#C8C2BA',

  mapBase:   '#E8E2D8',
  mapStreet: '#F5F0E8',
  mapBlock:  '#D8D2C8',
  mapWater:  '#BFCFE0',
  mapGreen:  '#C2D2BC',

  font: "'DM Sans', -apple-system, BlinkMacSystemFont, sans-serif",
};

const RouterCtx = React.createContext(null);
const useRouter = () => React.useContext(RouterCtx);

const MOCK = {
  me: { name: 'Taehyun Park', username: 'taehyun_p', stamps: 34, places: 12, friends: 8, followers: 156, following: 42 },

  stamps: [
    { id: 's1', place: 'Heukbyul Coffee', user: 'minjung_k', initials: 'M', time: '2h ago',
      caption: "The best latte I've had in months. Stayed for 3 hours just reading.",
      tags: ['cozy', 'quiet'], likes: 12, comments: 4, saved: false, liked: false, imgColor: '#C8B4DC' },
    { id: 's2', place: 'Han River Park', user: 'junho_s', initials: 'J', time: '5h ago',
      caption: 'Golden hour by the river. Nothing beats this view on a clear day.',
      tags: ['outdoor', 'golden-hour'], likes: 24, comments: 8, saved: true, liked: true, imgColor: '#B4C8A8' },
    { id: 's3', place: 'Pasta Bar Roma', user: 'yuna_m', initials: 'Y', time: 'Yesterday',
      caption: null, tags: ['dinner', 'italian'], likes: 6, comments: 1, saved: false, liked: false, imgColor: '#D4B4A0' },
    { id: 's4', place: 'Blue Note Records', user: 'junho_s', initials: 'J', time: '2 days ago',
      caption: 'Found a first press of Kind of Blue. Best ₩50,000 ever spent.',
      tags: ['music', 'vinyl'], likes: 31, comments: 12, saved: false, liked: false, imgColor: '#A4B4C8' },
  ],

  myStamps: [
    { id: 'm1', imgColor: '#C8B4DC' }, { id: 'm2', imgColor: '#B4C8A8' },
    { id: 'm3', imgColor: '#D4B4A0' }, { id: 'm4', imgColor: '#A4B4C8' },
    { id: 'm5', imgColor: '#C4C0A8' }, { id: 'm6', imgColor: '#D0B8C4' },
    { id: 'm7', imgColor: '#B8C4D0' }, { id: 'm8', imgColor: '#C8D0B8' },
    { id: 'm9', imgColor: '#D4C8B4' },
  ],

  stories: [
    { id: 'me', name: 'Me', initials: 'T', hasStory: true, isOwn: true },
    { id: 'm', name: 'minjung', initials: 'M', hasStory: true },
    { id: 'j', name: 'junho', initials: 'J', hasStory: true },
    { id: 'y', name: 'yuna', initials: 'Y', hasStory: false },
    { id: 's', name: 'sora', initials: 'S', hasStory: true },
    { id: 'h', name: 'heejin', initials: 'H', hasStory: false },
  ],

  timeline: [
    { id: 't1', kind: 'checkin', time: '09:45', place: 'Heukbyul Coffee', text: 'Morning coffee session ☀️', photos: 2, isAuto: false },
    { id: 't2', kind: 'note', time: '11:00', text: 'Light through the windows was so soft today. Stayed longer than planned.' },
    { id: 't3', kind: 'stamp', time: '13:20', place: 'Han River Park', text: 'Golden hour by the river', photos: 3 },
    { id: 't4', kind: 'checkin', time: '15:40', place: 'Itaewon-dong', isAuto: true },
    { id: 't5', kind: 'checkin', time: '18:50', place: 'Pasta Bar Roma', text: 'Dinner with friends', photos: 1 },
  ],

  nearby: [
    { id: 'p1', name: 'Heukbyul Coffee', emoji: '☕', category: 'Café',    dist: '42m',  stamps: 7,  visitors: 45 },
    { id: 'p2', name: 'Han River Park',  emoji: '🌿', category: 'Outdoor', dist: '340m', stamps: 3,  visitors: 128 },
    { id: 'p3', name: 'Grand Market',    emoji: '🏬', category: 'Retail',  dist: '520m', stamps: 12, visitors: 89 },
  ],

  places: {
    p1: { id: 'p1', name: 'Heukbyul Coffee', emoji: '☕', category: 'Café', dist: '42m',
      address: '12 Bukchon-ro, Jongno-gu, Seoul', hours: 'Mon–Fri 8am–8pm · Sat–Sun 9am–9pm',
      phone: '+82 2-123-4567', stamps: 7, visitors: 45, lastVisit: '2h ago',
      friendsHere: [{ initials: 'M' }, { initials: 'J' }], imgColor: '#C8B4DC' },
    p2: { id: 'p2', name: 'Han River Park', emoji: '🌿', category: 'Outdoor', dist: '340m',
      address: 'Yeouido-dong, Yeongdeungpo-gu, Seoul', hours: 'Always open',
      stamps: 3, visitors: 128, lastVisit: '5h ago',
      friendsHere: [{ initials: 'J' }], imgColor: '#B4C8A8' },
  },

  notifications: [
    { id: 'n0', type: 'friend_req', initials: 'S', user: 'sora_k',   text: 'sent you a friend request',                        time: '5m ago',   isRequest: true },
    { id: 'n1', type: 'like',       initials: 'M', user: 'minjung_k',text: 'liked your stamp at Heukbyul Coffee',               time: '2h ago' },
    { id: 'n2', type: 'comment',    initials: 'J', user: 'junho_s',  text: 'commented: "This place is amazing!"',              time: '3h ago' },
    { id: 'n3', type: 'follow',     initials: 'Y', user: 'yuna_m',   text: 'started following you',                            time: '6h ago' },
    { id: 'n4', type: 'tag',        initials: 'H', user: 'heejin_p', text: 'tagged you in a stamp at Blue Note Records',       time: 'Yesterday' },
  ],
};

Object.assign(window, { T, RouterCtx, useRouter, MOCK });
