// herdr mod host for JavaScriptCore (iOS app and the macOS headless test).
//
// Loaded first into every mod copy's context. It provides the three modules the
// bundled mods import (gpui-kit, gpui-base, herdr), the browser-ish globals they
// may touch (timers, console, localStorage, fetch, TextEncoder, atob/btoa), and
// the __host object Swift drives: boot, render, dispatch, settle, fire, setState.
//
// Native side: a single global function __native(name, json) installed by Swift.
//   sync calls return a JSON string (or nothing);
//   async calls carry a `pid` and are answered later with __host.settle(pid, ok, json).
//
// Element trees are recorded into plain JSON nodes:
//   {t:"div"|"svg"|"text"|"input"|"md"|"vlist"|"none", s:{style}, c:[children],
//    v:text, src:svg path, h:{click|rclick|hover|scroll|size: handlerKey},
//    hv:{pressed style}, tip:"tooltip", id:"element id"}
(function (global) {
  "use strict";

  const native = global.__native;
  const call = (name, args) => {
    const out = native(name, args === undefined ? "null" : JSON.stringify(args));
    return typeof out === "string" && out.length ? JSON.parse(out) : null;
  };

  // ---------------------------------------------------------------- async bridge
  let nextPid = 1;
  const pending = new Map();
  function callAsync(name, args) {
    return new Promise((resolve, reject) => {
      const pid = nextPid++;
      pending.set(pid, { resolve, reject });
      try {
        native(name, JSON.stringify(Object.assign({}, args, { pid })));
      } catch (e) {
        pending.delete(pid);
        reject(e);
      }
    });
  }

  // ---------------------------------------------------------------- console
  const fmtArg = (a) => {
    if (typeof a === "string") return a;
    if (a instanceof Error) return `${a.name}: ${a.message}${a.stack ? `\n${a.stack}` : ""}`;
    try { return JSON.stringify(a); } catch { return String(a); }
  };
  const log = (level) => (...args) => native("log", JSON.stringify({ level, msg: args.map(fmtArg).join(" ") }));
  global.console = { log: log("log"), info: log("info"), warn: log("warn"), error: log("error"), debug: log("debug") };
  const reportError = (where, e) => native("error", JSON.stringify({ where, msg: fmtArg(e) }));

  // ---------------------------------------------------------------- timers
  // One native one-shot per JS timer; repeating timers re-arm in JS.
  let nextTimer = 1;
  const timers = new Map(); // id -> { fn, ms, repeat, every }
  function arm(id, ms) { native("timer", JSON.stringify({ id, ms: Math.max(0, Number(ms) || 0) })); }
  function addTimer(fn, ms, repeat, every) {
    const id = nextTimer++;
    timers.set(id, { fn, ms, repeat, every });
    arm(id, ms);
    return id;
  }
  function clearTimer(id) {
    if (timers.delete(id)) native("clearTimer", JSON.stringify({ id }));
  }
  global.setTimeout = (fn, ms, ...args) => addTimer(() => fn(...args), ms, false, false);
  global.setInterval = (fn, ms, ...args) => addTimer(() => fn(...args), ms, true, false);
  global.clearTimeout = clearTimer;
  global.clearInterval = clearTimer;
  if (typeof global.queueMicrotask !== "function") global.queueMicrotask = (fn) => { Promise.resolve().then(fn); };

  function runTimer(id) {
    const t = timers.get(id);
    if (!t) return;
    if (!t.repeat) timers.delete(id);
    let result;
    try {
      result = t.fn();
    } catch (e) {
      reportError("timer", e);
    }
    if (!t.repeat) return;
    // timer.every: the next run is scheduled after the callback (and its promise) finishes.
    if (t.every && result && typeof result.then === "function") {
      t.running = true;
      Promise.resolve(result).catch((e) => reportError("timer", e)).then(() => {
        t.running = false;
        if (timers.has(id)) arm(id, t.ms);
      });
    } else if (timers.has(id)) {
      arm(id, t.ms);
    }
  }

  // ---------------------------------------------------------------- state from Swift
  const S = {
    spaces: [], focused: null, machines: [], layout: null, theme: {}, shared: {},
    home: "~", settings: { font_family: "JetBrains Mono" }, props: null, mod: "",
  };
  let LS = {};

  // ---------------------------------------------------------------- utilities
  const clone = (v) => (v === undefined ? null : JSON.parse(JSON.stringify(v)));
  const uuid = () => "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    return (c === "x" ? r : (r & 0x3) | 0x8).toString(16);
  });

  // ---------------------------------------------------------------- render bookkeeping
  let renderRequested = false;
  let rendering = false;
  function requestRender() {
    if (renderRequested) return;
    renderRequested = true;
    native("render", "null");
  }

  let handlers = new Map(); // key -> { kind, fn }
  let handlerSeq = 0;
  function registerHandler(el, kind, fn) {
    let key = el.i != null ? `${el.i}:${kind}` : `#${++handlerSeq}:${kind}`;
    if (handlers.has(key)) key = `${key}#${++handlerSeq}`;
    handlers.set(key, { kind, fn });
    return key;
  }

  // ---------------------------------------------------------------- cx
  let stopped = false;
  function makeTask(promise) {
    let done = false;
    let cancelled = false;
    promise.then(() => { done = true; }, () => { done = true; });
    return { cancel() { cancelled = true; }, is_done() { return done; }, get cancelled() { return cancelled; } };
  }
  const cx = {
    notify() { requestRender(); },
    refresh() { requestRender(); },
    spawn(fn) {
      const p = Promise.resolve().then(() => fn(cx)).catch((e) => reportError("spawn", e));
      return makeTask(p);
    },
    sleep(ms) { return new Promise((r) => global.setTimeout(r, ms)); },
    stop_propagation() { stopped = true; },
    prevent_default() {},
    timer: {
      every(ms, fn) {
        const id = addTimer(() => fn(cx), ms, true, true);
        return { cancel() { clearTimer(id); }, is_done() { return !timers.has(id); } };
      },
      after(ms, fn) {
        const id = addTimer(() => fn(cx), ms, false, false);
        return { cancel() { clearTimer(id); }, is_done() { return !timers.has(id); } };
      },
    },
    new(View, props) {
      const v = new View();
      if (typeof v.init === "function") v.init(props ?? null, cx);
      return v;
    },
  };

  // ---------------------------------------------------------------- elements
  // Builders mutate in place and return `this` (mods chain after helpers and call
  // .child() in loops without reassigning).
  class El {
    constructor(t) {
      this.t = t;
      this.s = {};
      this.c = [];
      this.hs = null; // kind -> fn
      this.hv = null;
      this.tip = null;
      this.i = null;
      this.x = null; // extra per-type payload
    }
    _h(kind, fn) {
      if (typeof fn === "function") (this.hs ??= {})[kind] = fn;
      return this;
    }
    _set(k, v) { this.s[k] = v; return this; }

    // tree
    child(x) { pushChild(this.c, x); return this; }
    children(it) {
      if (it == null) return this;
      for (const x of it) pushChild(this.c, x);
      return this;
    }
    when(cond, fn) { if (cond) { const r = fn(this); return r instanceof El ? r : this; } return this; }
    when_some(v, fn) { if (v != null) { const r = fn(this, v); return r instanceof El ? r : this; } return this; }
    when_none(v, fn) { return v == null ? this.when(true, fn) : this; }
    map(fn) { const r = fn(this); return r instanceof El ? r : this; }
    id(v) { this.i = String(v); return this; }
    key(v) { return this.id(v); }
    group() { return this; }

    // display & flex
    flex() { if (!this.s.dir) this.s.dir = "row"; return this; }
    flex_row() { return this._set("dir", "row"); }
    flex_col() { return this._set("dir", "col"); }
    block() { delete this.s.dir; return this; }
    flex_1() { this.s.grow = 1; this.s.shrink = 1; this.s.basis0 = true; return this; }
    flex_auto() { this.s.grow = 1; this.s.shrink = 1; return this; }
    flex_initial() { this.s.grow = 0; this.s.shrink = 1; return this; }
    flex_grow() { return this._set("grow", 1); }
    flex_shrink() { return this._set("shrink", 1); }
    flex_shrink_0() { return this._set("shrink", 0); }
    flex_none() { this.s.grow = 0; this.s.shrink = 0; return this; }
    flex_wrap() { return this._set("wrap", true); }
    flex_nowrap() { delete this.s.wrap; return this; }
    items_center() { return this._set("items", "center"); }
    items_start() { return this._set("items", "start"); }
    items_end() { return this._set("items", "end"); }
    items_baseline() { return this._set("items", "center"); }
    items_stretch() { return this._set("items", "stretch"); }
    self_center() { return this._set("self", "center"); }
    self_start() { return this._set("self", "start"); }
    self_end() { return this._set("self", "end"); }
    justify_between() { return this._set("justify", "between"); }
    justify_around() { return this._set("justify", "around"); }
    justify_evenly() { return this._set("justify", "around"); }
    justify_center() { return this._set("justify", "center"); }
    justify_end() { return this._set("justify", "end"); }
    justify_start() { return this._set("justify", "start"); }
    content_center() { return this; }
    gap(n) { this.s.gap = num(n); return this; }
    gap_x(n) { return this._set("gapX", num(n)); }
    gap_y(n) { return this._set("gapY", num(n)); }

    // size
    w(n) { return this._set("w", len(n)); }
    h(n) { return this._set("h", len(n)); }
    size(n) { this.s.w = len(n); this.s.h = len(n); return this; }
    w_full() { return this._set("w", "full"); }
    h_full() { return this._set("h", "full"); }
    size_full() { this.s.w = "full"; this.s.h = "full"; return this; }
    w_auto() { delete this.s.w; return this; }
    h_auto() { delete this.s.h; return this; }
    min_w(n) { return this._set("minW", num(n)); }
    min_h(n) { return this._set("minH", num(n)); }
    max_w(n) { return this._set("maxW", num(n)); }
    max_h(n) { return this._set("maxH", num(n)); }
    min_w_0() { return this._set("minW", 0); }
    min_h_0() { return this._set("minH", 0); }

    // padding & margin
    p(n) { const v = num(n); Object.assign(this.s, { pt: v, pr: v, pb: v, pl: v }); return this; }
    px(n) { const v = num(n); this.s.pl = v; this.s.pr = v; return this; }
    py(n) { const v = num(n); this.s.pt = v; this.s.pb = v; return this; }
    pt(n) { return this._set("pt", num(n)); }
    pb(n) { return this._set("pb", num(n)); }
    pl(n) { return this._set("pl", num(n)); }
    pr(n) { return this._set("pr", num(n)); }
    m(n) { const v = num(n); Object.assign(this.s, { mt: v, mr: v, mb: v, ml: v }); return this; }
    mx(n) { const v = num(n); this.s.ml = v; this.s.mr = v; return this; }
    my(n) { const v = num(n); this.s.mt = v; this.s.mb = v; return this; }
    mt(n) { return this._set("mt", num(n)); }
    mb(n) { return this._set("mb", num(n)); }
    ml(n) { return this._set("ml", num(n)); }
    mr(n) { return this._set("mr", num(n)); }

    // position
    relative() { return this._set("pos", "rel"); }
    absolute() { return this._set("pos", "abs"); }
    inset_0() { Object.assign(this.s, { top: 0, left: 0, right: 0, bottom: 0 }); return this; }
    inset(n) { const v = num(n); Object.assign(this.s, { top: v, left: v, right: v, bottom: v }); return this; }
    top(n) { return this._set("top", num(n)); }
    left(n) { return this._set("left", num(n)); }
    right(n) { return this._set("right", num(n)); }
    bottom(n) { return this._set("bottom", num(n)); }
    top_0() { return this._set("top", 0); }
    left_0() { return this._set("left", 0); }
    right_0() { return this._set("right", 0); }
    bottom_0() { return this._set("bottom", 0); }

    // paint
    bg(c) { return c == null ? this : this._set("bg", String(c)); }
    rounded(n) { return this._set("r", n === undefined ? 4 : num(n)); }
    rounded_full() { return this._set("r", 9999); }
    rounded_none() { return this._set("r", 0); }
    rounded_sm() { return this._set("r", 2); }
    rounded_md() { return this._set("r", 6); }
    rounded_lg() { return this._set("r", 8); }
    opacity(x) { return this._set("op", Number(x)); }
    border(n) { const v = n === undefined ? 1 : num(n); Object.assign(this.s, { bt: v, br: v, bb: v, bl: v }); return this; }
    border_1() { return this.border(1); }
    border_t(n) { return this._set("bt", n === undefined ? 1 : num(n)); }
    border_b(n) { return this._set("bb", n === undefined ? 1 : num(n)); }
    border_l(n) { return this._set("bl", n === undefined ? 1 : num(n)); }
    border_r(n) { return this._set("br", n === undefined ? 1 : num(n)); }
    border_color(c) { return c == null ? this : this._set("bc", String(c)); }
    shadow() { return this; }
    shadow_sm() { return this; }
    shadow_md() { return this; }
    shadow_lg() { return this; }
    overflow_hidden() { return this._set("clip", true); }
    overflow_x_hidden() { return this._set("clip", true); }
    overflow_y_hidden() { return this._set("clip", true); }
    visible() { return this; }
    invisible() { return this._set("op", 0); }

    // text
    text_size(n) { return this._set("ts", num(n)); }
    text_xs() { return this._set("ts", 12); }
    text_sm() { return this._set("ts", 14); }
    text_base() { return this._set("ts", 16); }
    text_lg() { return this._set("ts", 18); }
    text_xl() { return this._set("ts", 20); }
    text_color(c) { return c == null ? this : this._set("tc", String(c)); }
    font_normal() { return this._set("fw", 400); }
    font_medium() { return this._set("fw", 500); }
    font_semibold() { return this._set("fw", 600); }
    font_bold() { return this._set("fw", 700); }
    font_weight(w) { return this._set("fw", Number(w) || 400); }
    font_family(f) { return f == null ? this : this._set("ff", String(f)); }
    italic() { return this._set("it", true); }
    underline() { return this._set("ul", true); }
    line_through() { return this._set("strike", true); }
    truncate() { return this._set("trunc", true); }
    text_ellipsis() { return this._set("trunc", true); }
    whitespace_nowrap() { return this._set("nowrap", true); }
    line_clamp(n) { return this._set("lines", num(n)); }
    text_left() { return this._set("ta", "left"); }
    text_center() { return this._set("ta", "center"); }
    text_right() { return this._set("ta", "right"); }
    line_height(n) { return this._set("lh", num(n)); }
    selectable() { return this._set("sel", true); }

    // scroll
    overflow_y_scrollbar() { return this._set("scrollY", true); }
    overflow_y_scroll() { return this._set("scrollY", true); }
    overflow_scroll() { return this._set("scrollY", true); }
    overflow_x_scrollbar() { return this._set("scrollX", true); }
    overflow_x_scroll() { return this._set("scrollX", true); }
    track_scroll(handle) { if (handle && handle.__id) this.x = Object.assign(this.x ?? {}, { scrollHandle: handle }); return this; }
    viewport_from_layout() { return this; }

    // interaction (pointer-only bits are no-ops on touch)
    cursor_pointer() { return this; }
    cursor_text() { return this; }
    cursor_default() { return this; }
    cursor_grab() { return this; }
    cursor_move() { return this; }
    hover(fn) {
      if (typeof fn !== "function") return this;
      const probe = new El("div");
      try { fn(probe); } catch (e) { reportError("hover", e); }
      this.hv = Object.assign(this.hv ?? {}, probe.s);
      return this;
    }
    active(fn) { return this.hover(fn); }
    focus() { return this; }
    tooltip(text) { if (text != null) this.tip = String(text); return this; }
    on_click(fn) { return this._h("click", fn); }
    on_hover(fn) { return this._h("hover", fn); }
    on_mouse_down(button, fn) {
      if (typeof button === "function") return this; // left-button press: nothing to do on touch
      if (button === "right") return this._h("rclick", fn);
      return this; // "left" presses only stop float drags on desktop
    }
    on_mouse_up() { return this; }
    on_mouse_move() { return this; }
    on_scroll_wheel(fn) { return this._h("scroll", fn); }
    on_size_change(fn) { return this._h("size", fn); }
    on_key_down() { return this; }
    on_drag() { return this; }
    on_drop() { return this; }

    // animation
    spin(ms) { return this._set("spin", num(ms) || 1000); }
    loop(prop, opts) {
      if (prop !== "opacity" || !opts) return this;
      return this._set("loop", { from: Number(opts.from ?? 0), to: Number(opts.to ?? 1), period: Number(opts.period ?? 1000) });
    }
    with_animation() { return this; }

    toJSON() { return serialize(this); }
  }

  // Unknown builder methods record nothing and keep the chain alive, so a mod
  // using a method this shim lacks still renders (and the gap is logged once).
  const warned = new Set();
  Object.setPrototypeOf(El.prototype, new Proxy({}, {
    get(_t, prop) {
      if (typeof prop !== "string" || prop === "then" || prop === "constructor" || prop.startsWith("__")) return undefined;
      return function () {
        if (!warned.has(prop)) { warned.add(prop); native("log", JSON.stringify({ level: "warn", msg: `gpui-kit: .${prop}() is not supported on iOS; ignored` })); }
        return this;
      };
    },
  }));

  function num(n) { const v = Number(n); return Number.isFinite(v) ? v : 0; }
  function len(n) {
    if (typeof n === "string") {
      if (n === "full" || n === "100%") return "full";
      const v = parseFloat(n);
      return Number.isFinite(v) ? v : 0;
    }
    return num(n);
  }
  function pushChild(list, x) {
    if (x == null || x === false || x === true) return;
    if (x instanceof El) list.push(x);
    else if (typeof x === "string" || typeof x === "number") list.push(text(String(x)));
    else if (Array.isArray(x)) for (const y of x) pushChild(list, y);
    else if (typeof x === "object" && typeof x.render === "function") list.push(text("")); // nested views are not hosted
    else list.push(text(String(x)));
  }
  function text(v) { const e = new El("text"); e.x = { v }; return e; }

  function serialize(el) {
    const n = { t: el.t };
    if (el.i != null) n.id = el.i;
    let hasStyle = false;
    for (const _k in el.s) { hasStyle = true; break; }
    if (hasStyle) n.s = el.s;
    if (el.hv) n.hv = el.hv;
    if (el.tip != null) n.tip = el.tip;
    if (el.x) {
      if (el.x.v != null) n.v = el.x.v;
      if (el.x.src != null) n.src = el.x.src;
      if (el.x.md != null) n.md = el.x.md;
      if (el.x.input) {
        const st = el.x.input;
        n.input = { id: st.__id, ph: st.placeholder ?? "", val: st._v };
      }
      if (el.x.scrollHandle) n.scroll = { id: el.x.scrollHandle.__id, bottom: el.x.scrollHandle.__bottom };
      if (el.x.rowH != null) n.rowH = el.x.rowH;
    }
    if (el.hs) {
      n.h = {};
      for (const kind in el.hs) n.h[kind] = registerHandler(el, kind, el.hs[kind]);
    }
    if (el.c.length) n.c = el.c.map(serialize);
    return n;
  }

  // ---------------------------------------------------------------- gpui-kit
  class View {
    init(_props, _cx) {}
    render(_cx) { return new El("div"); }
  }
  const div = () => new El("div");
  const svg = (path) => { const e = new El("svg"); e.x = { src: String(path ?? "") }; return e; };
  const img = (path) => { const e = new El("svg"); e.x = { src: String(path ?? "") }; return e; };
  const gpuiKit = { View, div, svg, img, image: img, Element: El };

  // ---------------------------------------------------------------- gpui-base
  const h_flex = () => { const e = new El("div"); e.s.dir = "row"; e.s.items = "center"; return e; };
  const v_flex = () => { const e = new El("div"); e.s.dir = "col"; return e; };

  let nextObj = 1;
  const inputs = new Map();
  class InputState {
    static new(opts) {
      const st = new InputState();
      st.__id = `in${nextObj++}`;
      st.placeholder = opts?.placeholder ?? "";
      st._v = String(opts?.value ?? opts?.default_value ?? "");
      st._on = { change: [], enter: [], focus: [], blur: [] };
      inputs.set(st.__id, st);
      return st;
    }
    value() { return this._v; }
    text() { return this._v; }
    set_value(v) { this._v = String(v ?? ""); requestRender(); return this; }
    set_placeholder(p) { this.placeholder = String(p ?? ""); requestRender(); return this; }
    on(event, fn) { (this._on[event] ??= []).push(fn); return this; }
    focus() { return this; }
  }
  const Input = {
    new(state) { const e = new El("input"); e.x = { input: state }; return e; },
  };

  class VirtualListScrollHandle {
    static new() {
      const h = new VirtualListScrollHandle();
      h.__id = `sh${nextObj++}`;
      h.__bottom = 0;
      return h;
    }
    scroll_to_bottom() { this.__bottom++; requestRender(); }
    scroll_to_item() {}
    scroll_to_top() {}
  }

  // At most a few hundred rows: render them all, lazily stacked natively.
  function v_virtual_list(_id, count, rowPx, _key, rangeFn) {
    const e = new El("vlist");
    e.s.dir = "col";
    e.s.scrollY = true;
    e.x = { rowH: num(rowPx) };
    const n = Math.max(0, Number(count) || 0);
    let rows = [];
    try { rows = rangeFn({ start: 0, end: n }) ?? []; } catch (err) { reportError("v_virtual_list", err); }
    for (const r of rows) pushChild(e.c, r);
    return e;
  }
  const Scrollbar = {
    vertical() { return new El("none"); },
    horizontal() { return new El("none"); },
    both() { return new El("none"); },
  };
  const TextView = {
    markdown(_id, md) { const e = new El("md"); e.x = { md: String(md ?? "") }; return e; },
    plain(_id, t) { const e = new El("md"); e.x = { md: String(t ?? "") }; e.s.plain = true; return e; },
  };
  const Label = { new(t) { const e = new El("div"); e.c.push(text(String(t ?? ""))); return e; } };
  const gpuiBase = { h_flex, v_flex, InputState, Input, VirtualListScrollHandle, v_virtual_list, Scrollbar, TextView, Label };

  // ---------------------------------------------------------------- web-ish globals
  const storage = {
    getItem(k) { k = String(k); return Object.prototype.hasOwnProperty.call(LS, k) ? LS[k] : null; },
    setItem(k, v) { k = String(k); v = String(v); LS[k] = v; native("ls.set", JSON.stringify({ k, v })); },
    removeItem(k) { k = String(k); delete LS[k]; native("ls.set", JSON.stringify({ k, v: null })); },
    clear() { LS = {}; native("ls.clear", "null"); },
    key(i) { return Object.keys(LS)[i] ?? null; },
    get length() { return Object.keys(LS).length; },
  };
  global.localStorage = storage;

  global.fetch = async function (url, opts) {
    opts = opts ?? {};
    let body = opts.body;
    if (body != null && typeof body !== "string") body = JSON.stringify(body);
    const r = await callAsync("fetch", { url: String(url), method: opts.method ?? "GET", headers: opts.headers ?? {}, body: body ?? null });
    return {
      status: r.status,
      ok: r.status >= 200 && r.status < 300,
      url: r.url ?? String(url),
      text: async () => r.body ?? "",
      json: async () => JSON.parse(r.body ?? "null"),
    };
  };

  if (typeof global.TextEncoder !== "function") {
    global.TextEncoder = class {
      encode(s) {
        const u = unescape(encodeURIComponent(String(s ?? "")));
        const out = new Uint8Array(u.length);
        for (let i = 0; i < u.length; i++) out[i] = u.charCodeAt(i);
        return out;
      }
    };
  }
  if (typeof global.TextDecoder !== "function") {
    global.TextDecoder = class {
      decode(bytes) {
        let s = "";
        for (const b of bytes ?? []) s += String.fromCharCode(b);
        try { return decodeURIComponent(escape(s)); } catch { return s; }
      }
    };
  }
  const B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  if (typeof global.btoa !== "function") {
    global.btoa = (s) => {
      s = String(s);
      let out = "";
      for (let i = 0; i < s.length; i += 3) {
        const a = s.charCodeAt(i), b = s.charCodeAt(i + 1), c = s.charCodeAt(i + 2);
        const n = (a << 16) | ((b || 0) << 8) | (c || 0);
        out += B64[(n >> 18) & 63] + B64[(n >> 12) & 63] + (isNaN(b) ? "=" : B64[(n >> 6) & 63]) + (isNaN(c) ? "=" : B64[n & 63]);
      }
      return out;
    };
  }
  if (typeof global.atob !== "function") {
    global.atob = (s) => {
      s = String(s).replace(/[^A-Za-z0-9+/]/g, "");
      let out = "";
      for (let i = 0; i < s.length; i += 4) {
        const n = (B64.indexOf(s[i]) << 18) | (B64.indexOf(s[i + 1]) << 12) | ((B64.indexOf(s[i + 2]) & 63) << 6) | (B64.indexOf(s[i + 3]) & 63);
        out += String.fromCharCode((n >> 16) & 255);
        if (s[i + 2] !== undefined) out += String.fromCharCode((n >> 8) & 255);
        if (s[i + 3] !== undefined) out += String.fromCharCode(n & 255);
      }
      return out;
    };
  }

  // ---------------------------------------------------------------- herdr
  // Local quirks (Config/host-local.js, bundled as _local.js after this file)
  // can rewrite a mod's exec before it leaves the phone:
  //   herdrIOS.onExec((cmd, args, on) => ({ cmd, args }))
  const execHooks = [];
  globalThis.herdrIOS = { onExec(fn) { execHooks.push(fn); } };
  function rewriteExec(cmd, args, on) {
    let r = { cmd, args };
    for (const hook of execHooks) {
      try { r = hook(r.cmd, r.args.slice(), on) ?? r; } catch (e) { console.error("exec hook: " + e); }
    }
    return r;
  }

  const herdr = {
    exec(command, args, options) {
      const r = rewriteExec(String(command), (args ?? []).map(String), options?.on ?? null);
      return callAsync("exec", { cmd: r.cmd, args: r.args, cwd: options?.cwd ?? null, on: options?.on ?? null });
    },
    hc() { return Promise.reject(new Error("hc is not available on iOS")); },
    home() { return S.home; },
    appHome() { return "/herdr-app"; },
    readTextFile(path, options) { return callAsync("readTextFile", { path: String(path), on: options?.on ?? null }); },
    writeTextFile() { return Promise.reject(new Error("writeTextFile is not available on iOS")); },
    knownAgents() { return Promise.resolve([]); },
    pickFolder() { return Promise.resolve(null); },
    playSound(sound) { native("playSound", JSON.stringify({ sound: String(sound ?? "") })); return null; },
    run(name, args) { native("run", JSON.stringify({ name: String(name), args: args ?? null })); return null; },
    machines() { return clone(S.machines); },
    spaces() { return clone(S.spaces); },
    agents() { return []; },
    panes() { return []; },
    setAgentOrder() { return null; },
    terminals() { return []; },
    focused() { return clone(S.focused); },
    layout() { return clone(S.layout); },
    layouts() { return []; },
    commands() { return []; },
    window() { return { width: 0, height: 0, fullscreen: false, maximized: false }; },
    placement() { return null; },
    theme() { return Object.assign({}, S.theme); },
    themes() { return []; },
    fonts() { return ["JetBrains Mono", "Geist"]; },
    updates() { return null; },
    presentUpdateNotes() { return null; },
    telemetry() { return { enabled: false }; },
    settings() { return Object.assign({}, S.settings); },
    keys() { return []; },
    openOverlay() { return uuid(); },
    closeOverlay() { return null; },
    notify(n) {
      const id = uuid();
      n = n ?? {};
      native("notify", JSON.stringify({ id, title: String(n.title ?? ""), body: n.body == null ? null : String(n.body), level: n.level ?? "info", timeout: n.timeout ?? null }));
      return id;
    },
    props() { return clone(S.props); },
    shared(key) { const v = S.shared[String(key)]; return v === undefined ? null : clone(v); },
    setShared(key, value) {
      key = String(key);
      const before = JSON.stringify(S.shared[key] ?? null);
      const after = JSON.stringify(value ?? null);
      if (before === after) return null;
      if (value == null) delete S.shared[key]; else S.shared[key] = JSON.parse(after);
      native("setShared", JSON.stringify({ k: key, v: value ?? null }));
      requestRender();
      return null;
    },
    nextCommand() { return new Promise(() => {}); },
    watchFolder() { return new Promise(() => {}); },
  };
  const herdrModule = new Proxy(herdr, {
    get(t, prop) {
      if (prop in t) return t[prop];
      if (typeof prop !== "string") return undefined;
      return function () {
        if (!warned.has(`herdr.${prop}`)) { warned.add(`herdr.${prop}`); native("log", JSON.stringify({ level: "warn", msg: `herdr.${prop}() is not available on iOS` })); }
        return null;
      };
    },
  });

  const modules = { "gpui-kit": gpuiKit, "gpui-base": gpuiBase, herdr: herdrModule };
  function require(name) {
    const m = modules[name];
    if (!m) throw new Error(`module not found: ${name}`);
    return m;
  }

  // ---------------------------------------------------------------- the host API
  let view = null;
  const fail = (msg) => ({ t: "div", s: { dir: "col", pt: 12, pl: 12, pr: 12, pb: 12, gap: 4 }, c: [
    { t: "text", v: "This mod hit an error", s: { fw: 600 } },
    { t: "text", v: msg, s: { ts: 11, tc: S.theme.blocked ?? "#f0705f" } },
  ] });

  global.__host = {
    // boot(factory, bootJSON): factory is the evaluated bundle function.
    boot(factory, bootJSON) {
      const b = JSON.parse(bootJSON);
      S.mod = b.mod ?? "";
      S.props = b.props ?? null;
      LS = b.localStorage ?? {};
      if (b.state) Object.assign(S, b.state);
      const exports = {};
      factory(require, exports);
      const Default = exports.default;
      if (typeof Default !== "function") throw new Error("the mod has no default export");
      view = new Default();
      if (typeof view.init === "function") view.init(clone(S.props), cx);
      requestRender();
      return true;
    },

    setState(json) {
      Object.assign(S, JSON.parse(json));
      requestRender();
    },

    // Returns the JSON tree of one render.
    render() {
      renderRequested = false;
      handlers = new Map();
      handlerSeq = 0;
      if (!view) return JSON.stringify(fail("not booted"));
      rendering = true;
      try {
        let out = view.render(cx);
        if (typeof out === "string" || typeof out === "number") out = text(String(out));
        if (!(out instanceof El)) out = new El("none");
        return JSON.stringify(serialize(out));
      } catch (e) {
        reportError("render", e);
        return JSON.stringify(fail(String(e?.message ?? e)));
      } finally {
        rendering = false;
      }
    },

    // Calls a handler from the last render. Returns true when it stopped propagation.
    dispatch(key, argJSON) {
      const h = handlers.get(key);
      if (!h) return false;
      const arg = argJSON ? JSON.parse(argJSON) : null;
      stopped = false;
      try {
        if (h.kind === "hover") h.fn(Boolean(arg), cx);
        else if (h.kind === "size") h.fn({ width: arg?.width ?? 0, height: arg?.height ?? 0 }, cx);
        else h.fn(Object.assign({ button: h.kind === "rclick" ? "right" : "left", click_count: 1, position: { x: 0, y: 0 } }, arg ?? {}), cx);
      } catch (e) {
        reportError(`on_${h.kind}`, e);
      }
      return stopped;
    },

    input(id, value) {
      const st = inputs.get(id);
      if (!st || st._v === value) return;
      st._v = String(value ?? "");
      for (const fn of st._on.change ?? []) {
        try { fn({ value: st._v }, cx); } catch (e) { reportError("input.change", e); }
      }
      requestRender();
    },

    settle(pid, ok, json) {
      const p = pending.get(pid);
      if (!p) return;
      pending.delete(pid);
      let value = null;
      try { value = json ? JSON.parse(json) : null; } catch { value = json; }
      if (ok) p.resolve(value);
      else p.reject(new Error(typeof value === "string" ? value : value?.message ?? "failed"));
    },

    fire(id) { runTimer(id); },

    // scenePhase became active: run every repeating timer callback once now.
    fireRepeating() {
      for (const [id, t] of timers) {
        if (!t.repeat || t.running) continue;
        native("clearTimer", JSON.stringify({ id }));
        runTimer(id);
      }
    },

    pendingCount() { return pending.size; },
    timerCount() { return timers.size; },
  };
})(globalThis);
