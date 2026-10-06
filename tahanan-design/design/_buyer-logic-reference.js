var IMG = {
  ph: '/_blob/9bf564b30af43ae11afb0b45624241e0',
  pp: '/_blob/845011af1a532ff1d886f641ed9fdf33',
  hts: '/_blob/fa5174b67a6555f48bd20f2c17470c87',
  pv: '/_blob/212188c28a8828030c7b166a39c0ab7d',
  row: '/_blob/73dab25e24708e2eb7d89f85c9b36e55',
  int: '/_blob/474fb931a1918b43a812114ef293aaf4'
};
var BRANDS = [
  { id: 'ph', name: 'Pasinaya Homes', img: IMG.ph, from: '₱750,000', gmi: '₱14,000', mo: '₱3,464', product: 'Full 2-Storey Townhouse',
    desc: 'An exclusive gated community of full 2-storey, 32 sqm townhomes — ideal for individuals or couples buying their first home. 0-equity, with no downpayment needed.',
    locs: [
      { name: 'Ternate, Cavite', brgy: 'Brgy. San Juan I', tcp: '₱800,000', fa: '32', la: '30', ma: '₱3,695.55', gmi: '₱14,000' },
      { name: 'Bay, Laguna', brgy: 'Brgy. Maitim', tcp: '₱800,000', fa: '32', la: '30', ma: '₱3,695.55', gmi: '₱14,000' },
      { name: 'San Miguel, Bulacan', brgy: 'Brgy. Balaong', tcp: '₱750,000', fa: '32', la: '30', ma: '₱3,463.65', gmi: '₱14,000' },
      { name: 'Magalang, Pampanga', brgy: 'Brgy. San Isidro', tcp: '₱800,000', fa: '32', la: '30', ma: '₱3,695.55', gmi: '₱14,000' },
      { name: 'Naic, Cavite', brgy: 'Brgy. Timalan Balsahan', tcp: '₱930,000', fa: '36', la: '32', ma: '₱4,294.92', gmi: '₱14,000' }
    ] },
  { id: 'pp', name: 'Pagsikat Place', img: IMG.pp, from: '₱1,250,000', gmi: '₱20,000', mo: '₱7,110', product: 'Full 2-Storey Townhouse',
    desc: 'An exclusive gated community of full 2-storey, 44 sqm townhomes with provisions for 2 bedrooms — for first-time buyers who want room to personalize.',
    locs: [ { name: 'Magalang, Pampanga', brgy: 'Brgy. Dolores', tcp: '₱1,300,000', fa: '44', la: '36', ma: '₱7,110.00', gmi: '₱20,000' } ] },
  { id: 'hts', name: 'Pasinaya Heights', img: IMG.hts, from: '₱1,588,000', gmi: '₱20,000', mo: '₱7,334', product: 'Studio Condominium',
    desc: 'Socialized condominiums with their own exclusive amenity area. Pasinaya Heights supports the government’s 4PH housing program.',
    locs: [ { name: 'Cabuyao, Laguna', brgy: 'Brgy. Baclaran', tcp: '₱1,588,000', fa: '28', la: '—', ma: '₱7,334.00', gmi: '₱20,000' } ] },
  { id: 'pv', name: 'Pagsibol Village', img: IMG.pv, from: '₱1,404,000', gmi: '₱14,212', mo: '₱8,855', product: 'Full 2-Storey Duplex',
    desc: 'An exclusive gated community of full 2-storey duplex homes with provisions for 2 bedrooms — space for families to shape their own layout.',
    locs: [ { name: 'Naic, Cavite', brgy: 'Brgy. Sabang', tcp: '₱1,350,000', fa: '36', la: '44', ma: '₱8,855.09', gmi: '₱24,400' } ] }
];
var REQS = [
  { id: 'r1', name: 'Valid government ID', who: 'Principal buyer', st: 'acc', date: 'Sep 15' },
  { id: 'r2', name: 'Latest payslips (3 months)', who: 'Principal buyer', st: 'rev', date: 'Sep 18' },
  { id: 'r3', name: 'Certificate of employment', who: 'Principal buyer', st: 'sub', date: 'Sep 20' },
  { id: 'r4', name: 'TIN ID or BIR Form 1902', who: 'Principal buyer', st: 'acc', date: 'Sep 15' },
  { id: 'r5', name: 'Marriage contract (PSA)', who: 'Principal buyer', st: 'todo' },
  { id: 'r6', name: 'Spouse valid government ID', who: 'Spouse', st: 'todo' },
  { id: 'r7', name: 'Spouse proof of income', who: 'Spouse', st: 'acc', date: 'Sep 16' },
  { id: 'r8', name: 'Proof of billing', who: 'Spouse', st: 'acc', date: 'Sep 16' }
];
var ST = {
  acc: { label: 'Accepted', cls: 'p-acc', n: 3 },
  rev: { label: 'Reviewed', cls: 'p-rev', n: 2 },
  sub: { label: 'Submitted', cls: 'p-sub', n: 1 },
  todo: { label: 'To upload', cls: 'p-todo', n: 0 }
};
var TICKETS = [
  { id: 'TK-1051', subj: 'Change of unit to Block 12 Lot 9', cat: 'Booking', st: 'open', time: '2h' },
  { id: 'TK-1042', subj: 'Payslip marked as reviewed only', cat: 'Documents', st: 'progress', time: 'Yesterday' },
  { id: 'TK-1038', subj: 'Consultation fee receipt', cat: 'Payments', st: 'resolved', time: 'Sep 14' }
];
var TST = { open: { label: 'Open', cls: 'p-sub' }, progress: { label: 'In progress', cls: 'p-rev' }, resolved: { label: 'Resolved', cls: 'p-acc' } };
var THREADS = {
  'TK-1051': [
    { k: 'sys', text: 'Ticket opened · Today' },
    { k: 'me', text: 'Hi! Can I move my booking from Lot 7 to Lot 9 in the same block? It’s closer to the park.', time: '8:41 AM' },
    { k: 'them', who: 'Homeful Support · Carla', text: 'Hi Maria! We’ve forwarded your request to the sales team to check Lot 9’s availability.', time: '9:02 AM' }
  ],
  'TK-1042': [
    { k: 'sys', text: 'Ticket opened · Sep 19' },
    { k: 'me', text: 'Hi! My payslips show “Reviewed” but not accepted yet. Is anything missing?', time: '9:12 AM' },
    { k: 'them', who: 'Homeful Support · Carla', text: 'Hi Maria! Your July and August payslips are clear. We just need September to complete the 3-month requirement.', time: '9:20 AM', att: true },
    { k: 'me', text: 'Got it — I’ll upload it tonight.', time: '9:24 AM' }
  ],
  'TK-1038': [
    { k: 'sys', text: 'Ticket opened · Sep 14' },
    { k: 'me', text: 'Where can I get the official receipt for my consultation fee?', time: '4:10 PM' },
    { k: 'them', who: 'Homeful Support · Carla', text: 'We’ve sent the receipt to maria.santos@email.com. It’s also in Transactions on your home.', time: '4:31 PM' },
    { k: 'sys', text: 'Marked resolved' }
  ]
};
var CATS = ['Payments', 'Documents', 'Booking', 'Account', 'Others'];
var SLIDE_KINDS = ['hero', 'video', 'map', 'home', 'invest'];

class Component extends DCLogic {
  constructor(props) {
    super(props);
    this.timers = {};
    this.state = this.initial(props.start || '__START__');
  }

  initial(start) {
    var p = String(start).split(':');
    var s = {
      screen: p[0], onb: 0, brand: 0, loc: 0, slide: 0, locView: 'story', fp: 0,
      sheet: null, sheetStep: 0, upId: null, ev: 0, bio: true, dataTab: 'info', openSec: 'personal',
      reqs: REQS.map(function (r) { return Object.assign({}, r); }),
      helpCat: 'All', tickets: TICKETS.map(function (t) { return Object.assign({}, t); }),
      threads: JSON.parse(JSON.stringify(THREADS)), ticketId: 'TK-1042', draft: '', typing: false,
      newCat: 'Documents', newSubj: '', newMsg: '', scan: null, pay: 'ew', paying: false, doc: 'privacy', toast: null, toastKey: 0
    };
    var x = p[1];
    if (s.screen === 'onb' && x) s.onb = Number(x) || 0;
    if (s.screen === 'forgot' && x) s.fp = Number(x) || 0;
    if (s.screen === 'loc' && x === 'gallery') s.locView = 'gallery';
    if (s.screen === 'loc' && x && x !== 'gallery') s.slide = Number(x) || 0;
    if (s.screen === 'data' && x === 'docs') s.dataTab = 'docs';
    if (s.screen === 'account' && x) s.ev = Number(x) || 0;
    if (s.screen === 'ticket' && x) s.ticketId = x;
    if (s.screen === 'home' && x === 'link') { s.sheet = 'link'; }
    if (s.screen === 'data' && x === 'upload') { s.dataTab = 'docs'; s.sheet = 'upload'; s.upId = 'r5'; }
    return s;
  }

  componentDidMount() { this.boot(); }
  componentWillUnmount() { this.clearAll(); }
  componentDidUpdate(prev) {
    if (prev.start !== this.props.start) {
      this.clearAll();
      this.setState(this.initial(this.props.start || '__START__'), () => this.boot());
    }
  }
  boot() {
    if (this.state.screen === 'splash') this.later('splash', () => this.go('onb'), 4400);
    if (this.state.screen === 'loc' && this.state.locView === 'story') this.armStory();
  }
  later(key, fn, ms) {
    if (this.timers[key]) clearTimeout(this.timers[key]);
    this.timers[key] = setTimeout(() => { this.timers[key] = null; fn(); }, ms);
  }
  clearAll() { Object.keys(this.timers).forEach((k) => { if (this.timers[k]) clearTimeout(this.timers[k]); }); this.timers = {}; }

  go(screen, extra) {
    if (this.timers.story) { clearTimeout(this.timers.story); this.timers.story = null; }
    var st = Object.assign({ screen: screen, sheet: null, scan: null, paying: false }, extra || {});
    this.setState(st, () => { if (screen === 'loc' && this.state.locView === 'story') this.armStory(); });
  }
  showToast(msg) {
    this.setState({ toast: msg, toastKey: this.state.toastKey + 1 });
    this.later('toast', () => this.setState({ toast: null }), 2500);
  }
  armStory() {
    this.later('story', () => {
      if (this.state.screen !== 'loc' || this.state.locView !== 'story') return;
      if (this.state.slide < SLIDE_KINDS.length - 1) { this.setState({ slide: this.state.slide + 1 }, () => this.armStory()); }
    }, 6000);
  }
  setSlide(i) {
    var n = Math.max(0, Math.min(SLIDE_KINDS.length - 1, i));
    this.setState({ slide: n }, () => this.armStory());
  }

  renderVals() {
    var s = this.state;
    var self = this;
    var sc = s.screen;
    var is = {};
    ['splash', 'onb', 'login', 'signup', 'welcome', 'forgot', 'home', 'brand', 'loc', 'scan', 'booking', 'payment', 'paid', 'data', 'profile', 'account', 'security', 'about', 'help', 'ticket', 'newticket']
      .forEach(function (k) { is[k] = sc === k; });

    var g = function (screen, extra) { return function (e) { if (e && e.preventDefault) e.preventDefault(); self.go(screen, extra); }; };
    var nav = {
      login: g('login'), signup: g('signup'), forgot: g('forgot', { fp: 0 }), home: g('home'), homeSubmit: g('home'),
      welcomeSubmit: g('welcome'), docs: g('data'), scan: g('scan'), help: g('help'), profile: g('profile'),
      account: g('account'), security: g('security'), privacy: g('about', { doc: 'privacy' }), terms: g('about', { doc: 'terms' }),
      booking: g('booking'), payment: g('payment'), newticket: g('newticket'), brandBack: g('brand')
    };

    // onboarding
    var onb = {
      s1: s.onb === 0, s2: s.onb === 1, s3: s.onb === 2, last: s.onb === 2, notLast: s.onb !== 2,
      next: function () { self.setState({ onb: Math.min(2, s.onb + 1) }); },
      dots: [0, 1, 2].map(function (i) { return { w: i === s.onb ? '30px' : '8px', bg: i === s.onb ? '#FFC42E' : 'rgba(255,255,255,.25)' }; })
    };
    // forgot password
    var fp = {
      s0: s.fp === 0, s1: s.fp === 1, s2: s.fp === 2, s3: s.fp === 3,
      next: function () { self.setState({ fp: Math.min(3, s.fp + 1) }); },
      back: function () { if (s.fp === 0 || s.fp === 3) self.go('login'); else self.setState({ fp: s.fp - 1 }); },
      dots: [0, 1, 2, 3].map(function (i) { return { w: i === s.fp ? '22px' : '6px', bg: i <= s.fp ? '#FFC42E' : 'rgba(255,255,255,.22)' }; })
    };

    // brands
    var brands = BRANDS.map(function (b, i) {
      return { name: b.name, img: b.img, from: b.from, locLabel: b.locs.length > 1 ? b.locs.length + ' locations' : b.locs[0].name,
        open: function () { self.go('brand', { brand: i, loc: 0, slide: 0 }); } };
    });
    var Bd = BRANDS[s.brand] || BRANDS[0];
    var B = Object.assign({}, Bd, {
      locLabel: Bd.locs.length > 1 ? Bd.locs.length + ' locations' : Bd.locs[0].brgy + ', ' + Bd.locs[0].name,
      locs: Bd.locs.map(function (l, i) { return Object.assign({}, l, { open: function () { self.go('loc', { loc: i, slide: 0, locView: 'story' }); } }); })
    });
    var L = Bd.locs[s.loc] || Bd.locs[0];
    var kind = SLIDE_KINDS[s.slide];
    var slideImg = kind === 'video' ? (Bd.id === 'ph' ? IMG.row : Bd.img) : (kind === 'home' ? IMG.int : Bd.img);
    var S = {
      story: s.locView === 'story', gallery: s.locView === 'gallery',
      k0: kind === 'hero', k1: kind === 'video', k2: kind === 'map', k3: kind === 'home', k4: kind === 'invest',
      hasImg: kind !== 'map', img: slideImg,
      prev: function () { self.setSlide(s.slide - 1); }, next: function () { if (s.slide < SLIDE_KINDS.length - 1) self.setSlide(s.slide + 1); },
      toGallery: function () { if (self.timers.story) clearTimeout(self.timers.story); self.setState({ locView: 'gallery' }); },
      toStory: function () { self.setState({ locView: 'story' }, function () { self.armStory(); }); },
      segs: SLIDE_KINDS.map(function (k, i) { return { done: i < s.slide, active: i === s.slide }; })
    };
    var G = [
      { img: Bd.img, label: 'Facade', span: 2, hasImg: true, ph: false },
      { img: IMG.int, label: 'Interior', span: 1, hasImg: true, ph: false },
      { img: '', label: 'Amenities', span: 1, hasImg: false, ph: true },
      { img: Bd.id === 'ph' ? IMG.row : Bd.img, label: 'Streetscape', span: 1, hasImg: true, ph: false },
      { img: '', label: 'Nearby destinations', span: 2, hasImg: false, ph: true },
      { img: '', label: 'Sales map', span: 1, hasImg: false, ph: true }
    ];

    // scan
    var scanBooking = function () { self.setState({ scan: 'booking' }); self.later('scan', function () { self.go('booking'); }, 1300); };
    var scanPayment = function () { self.setState({ scan: 'payment' }); self.later('scan', function () { self.go('payment'); }, 1300); };

    // payment
    var payList = [
      { id: 'ew', name: 'E-wallet', sub: 'Pay from your mobile wallet', isW: true },
      { id: 'cc', name: 'Debit or credit card', sub: 'Visa, Mastercard, JCB', isC: true },
      { id: 'ob', name: 'Online banking', sub: 'Transfer from your bank app', isB: true },
      { id: 'otc', name: 'Over the counter', sub: 'Pay at partner outlets', isO: true }
    ].map(function (m) {
      var on = s.pay === m.id;
      return Object.assign({ isW: false, isC: false, isB: false, isO: false }, m, { on: on, bd: on ? '#FFC42E' : 'rgba(255,255,255,.1)', bg: on ? 'rgba(255,196,46,.08)' : 'rgba(255,255,255,.04)', dot: on ? '#FFC42E' : 'rgba(255,255,255,.3)', pick: function () { self.setState({ pay: m.id }); } });
    });
    var doPay = function () { self.setState({ paying: true }); self.later('pay', function () { self.go('paid'); }, 1800); };

    // data tabs
    var dt = {
      isInfo: s.dataTab === 'info', isDocs: s.dataTab === 'docs',
      info: function () { self.setState({ dataTab: 'info' }); }, docs: function () { self.setState({ dataTab: 'docs' }); },
      infoBg: s.dataTab === 'info' ? '#FFC42E' : 'transparent', infoC: s.dataTab === 'info' ? '#0B1A33' : '#C9D4E8',
      docsBg: s.dataTab === 'docs' ? '#FFC42E' : 'transparent', docsC: s.dataTab === 'docs' ? '#0B1A33' : '#C9D4E8'
    };
    var secDefs = [
      { id: 'personal', title: 'Personal details', sub: 'Principal buyer · Complete', pct: 100, cta: 'Edit personal details',
        fields: [{ k: 'Full name', v: 'Maria L. Santos' }, { k: 'Civil status', v: 'Married' }, { k: 'Employer', v: '[Employer name]' }, { k: 'Gross monthly income', v: '[₱ amount]' }] },
      { id: 'spouse', title: 'Spouse information', sub: '3 fields left', pct: 60, cta: 'Complete spouse details',
        fields: [{ k: 'Full name', v: 'Jose R. Santos' }, { k: 'Employer', v: 'Not yet added' }, { k: 'Monthly income', v: 'Not yet added' }] },
      { id: 'cobo', title: 'Co-borrower (Cobo)', sub: 'Optional · adds to your GMI', pct: 0, cta: 'Add a co-borrower', fields: [] },
      { id: 'aif', title: 'Attorney-in-Fact (AIF)', sub: 'For buyers abroad', pct: 0, cta: 'Add an attorney-in-fact', fields: [] }
    ];
    var secs = secDefs.map(function (d) {
      var open = s.openSec === d.id;
      return { title: d.title, sub: d.sub, pct: d.pct + '%', done: d.pct === 100, notDone: d.pct !== 100, deg: Math.round(d.pct * 3.6) + 'deg',
        ringC: d.pct === 100 ? '#2FA96B' : (d.pct > 0 ? '#FFC42E' : '#5C6F93'), open: open, rot: open ? '180deg' : '0deg', cta: d.cta,
        fields: d.fields, hasFields: d.fields.length > 0, isSpouse: d.id === 'spouse', notSpouse: d.id !== 'spouse', toggle: function () { self.setState({ openSec: open ? null : d.id }); } };
    });
    var colorOf = { acc: '#2FA96B', rev: '#FFC42E', sub: '#2E6BE6', todo: '#F2622E' };
    var counts = { acc: 0, rev: 0, sub: 0, todo: 0 };
    s.reqs.forEach(function (r) { counts[r.st]++; });
    var order = ['acc', 'rev', 'sub', 'todo'];
    var bar = [];
    order.forEach(function (k) { for (var i = 0; i < counts[k]; i++) bar.push({ c: colorOf[k] }); });
    var mkItem = function (r) {
      var meta = ST[r.st];
      var n = meta.n;
      var dim = 'rgba(255,255,255,.14)';
      return { name: r.name, label: meta.label, cls: meta.cls, isTodo: r.st === 'todo', notTodo: r.st !== 'todo',
        sub: r.st === 'todo' ? 'Required' : (meta.label + (r.date ? ' · ' + r.date : '')),
        c1: n >= 1 ? '#2E6BE6' : dim, c2: n >= 2 ? '#FFC42E' : dim, c3: n >= 3 ? '#2FA96B' : dim,
        upload: function () { self.setState({ sheet: 'upload', sheetStep: 0, upId: r.id }); } };
    };
    var groups = ['Principal buyer', 'Spouse'].map(function (w) {
      return { title: w, items: s.reqs.filter(function (r) { return r.who === w; }).map(mkItem) };
    });
    var rq = { acc: counts.acc, total: s.reqs.length, todo: counts.todo, hasTodo: counts.todo > 0, bar: bar, groups: groups };

    // sheets
    var sheetNext = function () {
      var nx = s.sheetStep + 1;
      self.setState({ sheetStep: nx });
      if (s.sheet === 'upload' && nx === 1) {
        self.later('up', function () {
          var reqs = self.state.reqs.map(function (r) { return r.id === self.state.upId ? Object.assign({}, r, { st: 'sub', date: 'Today' }) : r; });
          self.setState({ sheetStep: 2, reqs: reqs });
        }, 1800);
      }
      if (s.sheet === 'email' && nx === 2) self.setState({ ev: 3 });
    };
    var closeSheet = function () { self.setState({ sheet: null, sheetStep: 0 }); };
    var openSheet = function (k) { return function () { self.setState({ sheet: k, sheetStep: 0 }); }; };
    var upReq = s.reqs.filter(function (r) { return r.id === s.upId; })[0];
    var sk = { link: s.sheet === 'link', email: s.sheet === 'email', mobile: s.sheet === 'mobile', upload: s.sheet === 'upload',
      st0: s.sheetStep === 0, st1: s.sheetStep === 1, st2: s.sheetStep === 2 };

    // email verification
    var verified = s.ev === 3;
    var ev = {
      s0: s.ev === 0, s1: s.ev === 1, s2: s.ev === 2, s3: s.ev === 3,
      bg: verified ? 'linear-gradient(135deg, rgba(47,169,107,.22), rgba(47,169,107,.08))' : 'linear-gradient(135deg, #1D3B6E, #16305B)',
      bd: verified ? 'rgba(47,169,107,.4)' : 'rgba(255,255,255,.1)',
      send: function () { self.setState({ ev: 1 }); },
      link: function () { self.setState({ ev: 2 }); self.later('ev', function () { self.setState({ ev: 3 }); }, 1800); },
      verify: function () { self.setState({ ev: 3 }); }
    };

    // help
    var hc = ['All'].concat(CATS).map(function (c) {
      var on = s.helpCat === c;
      return { name: c, bg: on ? '#F3F6FC' : 'rgba(255,255,255,.05)', col: on ? '#0B1A33' : '#E2E8F3', bd: on ? '#F3F6FC' : 'rgba(255,255,255,.14)', pick: function () { self.setState({ helpCat: c }); } };
    });
    var lastOf = function (id) {
      var th = s.threads[id] || [];
      for (var i = th.length - 1; i >= 0; i--) { if (th[i].k !== 'sys') return th[i].text; }
      return '';
    };
    var tks = s.tickets.filter(function (t) { return s.helpCat === 'All' || t.cat === s.helpCat; }).map(function (t) {
      return Object.assign({}, t, { stLabel: TST[t.st].label, cls: TST[t.st].cls, last: lastOf(t.id), open: function () { self.go('ticket', { ticketId: t.id, draft: '' }); } });
    });
    var Tt = s.tickets.filter(function (t) { return t.id === s.ticketId; })[0] || s.tickets[0];
    var T = Object.assign({}, Tt, { stLabel: TST[Tt.st].label, cls: TST[Tt.st].cls });
    var msgs = (s.threads[Tt.id] || []).map(function (m) {
      return { sys: m.k === 'sys', me: m.k === 'me', them: m.k === 'them', text: m.text, who: m.who || '', time: m.time || '', att: !!m.att };
    });
    var push = function (id, m) { var th = Object.assign({}, self.state.threads); th[id] = (th[id] || []).concat([m]); return th; };
    var sendMsg = function (e) {
      if (e && e.preventDefault) e.preventDefault();
      var text = (self.state.draft || '').trim();
      if (!text) return;
      var id = self.state.ticketId;
      self.setState({ threads: push(id, { k: 'me', text: text, time: 'Now' }), draft: '', typing: true });
      self.later('reply', function () {
        self.setState({ typing: false, threads: push(id, { k: 'them', who: 'Homeful Support · Carla', text: 'Thanks, Maria! I’ve noted that on your ticket. We’ll update you here as soon as it’s reviewed.', time: 'Now' }) });
      }, 1800);
    };
    var nc = CATS.map(function (c) {
      var on = s.newCat === c;
      return { name: c, bg: on ? '#FFC42E' : 'rgba(255,255,255,.05)', col: on ? '#0B1A33' : '#E2E8F3', bd: on ? '#FFC42E' : 'rgba(255,255,255,.14)', pick: function () { self.setState({ newCat: c }); } };
    });
    var submitTicket = function () {
      var id = 'TK-' + (1052 + s.tickets.length - 3);
      var subj = (s.newSubj || '').trim() || 'Question about my ' + s.newCat.toLowerCase();
      var msg = (s.newMsg || '').trim() || 'Hi! I need help with my ' + s.newCat.toLowerCase() + '.';
      var th = Object.assign({}, s.threads);
      th[id] = [{ k: 'sys', text: 'Ticket opened · Today' }, { k: 'me', text: msg, time: 'Now' }];
      var tickets = [{ id: id, subj: subj, cat: s.newCat, st: 'open', time: 'Now' }].concat(s.tickets);
      self.setState({ threads: th, tickets: tickets, newSubj: '', newMsg: '' });
      self.go('ticket', { ticketId: id, typing: true });
      self.later('reply', function () {
        self.setState({ typing: false, threads: push(id, { k: 'them', who: 'Homeful Support · Carla', text: 'Hi Maria! Thanks for reaching out — I’m looking into this now.', time: 'Now' }) });
      }, 2200);
    };

    var tabC = function (k) { return sc === k ? '#FFC42E' : '#8C9BB8'; };
    var DOCS = {
      privacy: { title: 'Privacy Policy', secs: [{ h: 'What we collect', p: 'Personal data collected at sign-up and during your application' }, { h: 'How we use it', p: 'Purposes of processing' }, { h: 'Your rights', p: 'Rights under the Data Privacy Act of 2012' }, { h: 'Contact our DPO', p: 'Data Protection Officer contact details' }] },
      terms: { title: 'Terms and Conditions', secs: [{ h: 'Using Tahanan', p: 'Account and eligibility terms' }, { h: 'Bookings and payments', p: 'Reservation, consultation fee and refund terms' }, { h: 'Limitations', p: 'Liability terms' }] }
    };
    var D = DOCS[s.doc] || DOCS.privacy;

    return {
      is: is, nav: nav, onb: onb, fp: fp, brands: brands, B: B, L: L, S: S, G: G,
      scanIdle: !s.scan, scanHit: !!s.scan, scanC: s.scan ? '#2FA96B' : '#FFC42E',
      scanLabel: s.scan === 'payment' ? 'Payment QR found · opening payment' : 'Booking QR found · opening booking',
      scanBooking: scanBooking, scanPayment: scanPayment,
      pay: payList, doPay: doPay, paying: s.paying,
      dt: dt, secs: secs, rq: rq,
      emailOk: verified, emailNo: !verified, ev: ev,
      bio: s.bio, bioBg: s.bio ? '#2FA96B' : 'rgba(255,255,255,.18)', bioJ: s.bio ? 'flex-end' : 'flex-start', bioLabel: s.bio ? 'Biometrics on' : 'Biometrics off',
      toggleBio: function () { self.setState({ bio: !s.bio }); self.showToast(s.bio ? 'Biometric login turned off' : 'Biometric login turned on'); },
      pwSaved: function () { self.showToast('Password updated'); },
      doc: { title: D.title, secs: D.secs, pBg: s.doc === 'privacy' ? '#FFC42E' : 'transparent', pC: s.doc === 'privacy' ? '#0B1A33' : '#C9D4E8', tBg: s.doc === 'terms' ? '#FFC42E' : 'transparent', tC: s.doc === 'terms' ? '#0B1A33' : '#C9D4E8' },
      hc: hc, tks: tks, tkCount: tks.length + (tks.length === 1 ? ' ticket' : ' tickets'), T: T, msgs: msgs, typing: s.typing,
      draft: s.draft, onDraft: function (e) { self.setState({ draft: e.target.value }); }, sendMsg: sendMsg,
      nc: nc, newSubj: s.newSubj, newMsg: s.newMsg,
      onSubj: function (e) { self.setState({ newSubj: e.target.value }); }, onMsg: function (e) { self.setState({ newMsg: e.target.value }); },
      submitTicket: submitTicket,
      showNav: sc === 'home' || sc === 'data' || sc === 'help' || sc === 'profile',
      tab: { home: tabC('home'), data: tabC('data'), help: tabC('help'), profile: tabC('profile') },
      sh: { link: openSheet('link'), email: openSheet('email'), mobile: openSheet('mobile') },
      sheetOn: !!s.sheet, sk: sk, sheetNext: sheetNext, closeSheet: closeSheet,
      sheetTitle: s.sheet === 'upload' ? 'Upload requirement' : (s.sheet === 'link' ? 'Link account' : 'Update contact details'),
      upName: upReq ? upReq.name : '',
      toastOn: !!s.toast, toast: s.toast || ''
    };
  }
}
