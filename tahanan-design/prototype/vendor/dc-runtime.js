/* Tahanan prototype runtime: renders the design's x-dc markup with React so the
   standalone files look and animate exactly like the canvas. */
(function () {
  var h = React.createElement;
  var MAP = { class: 'className', for: 'htmlFor', readonly: 'readOnly', autocomplete: 'autoComplete', inputmode: 'inputMode', tabindex: 'tabIndex',
    'stroke-width': 'strokeWidth', 'stroke-linecap': 'strokeLinecap', 'stroke-linejoin': 'strokeLinejoin', viewbox: 'viewBox', maxlength: 'maxLength' };
  var VOID = { img: 1, input: 1, br: 1, hr: 1, meta: 1, link: 1, source: 1, path: 1 };
  var WHOLE = /^\s*\{\{\s*([^}]+?)\s*\}\}\s*$/;
  function look(p, sc) {
    if (p === 'true') return true; if (p === 'false') return false;
    if (/^-?\d+(\.\d+)?$/.test(p)) return Number(p);
    return p.split('.').reduce(function (o, k) { return o == null ? undefined : o[k]; }, sc);
  }
  function interp(str, sc) {
    var m = str.match(WHOLE);
    if (m) return look(m[1], sc);
    return str.replace(/\{\{\s*([^}]+?)\s*\}\}/g, function (_, p) { var v = look(p, sc); return v == null ? '' : String(v); });
  }
  function styleObj(str) {
    var o = {};
    String(str).split(';').forEach(function (d) {
      var i = d.indexOf(':'); if (i < 0) return;
      var k = d.slice(0, i).trim(), v = d.slice(i + 1).trim(); if (!k) return;
      if (k.indexOf('--') !== 0) k = k.replace(/-([a-z])/g, function (_, c) { return c.toUpperCase(); });
      if (/^(ms|webkit)[A-Z]/.test(k) && k.indexOf('webkit') === 0) k = 'W' + k.slice(1);
      o[k] = v;
    });
    return o;
  }
  function kids(node, sc) {
    var out = [];
    node.childNodes.forEach(function (c, i) { var r = build(c, sc, i); if (r !== null && r !== undefined) out.push(r); });
    return out;
  }
  function build(node, sc, key) {
    if (node.nodeType === 3) {
      var t = node.textContent;
      if (!t.trim() && t.indexOf('\n') >= 0) return null;
      return interp(t, sc);
    }
    if (node.nodeType !== 1) return null;
    var tag = node.localName;
    if (tag === 'sc-if') return look(node.getAttribute('value').replace(/[{}\s]/g, ''), sc) ? h(React.Fragment, { key: key }, kids(node, sc)) : null;
    if (tag === 'sc-for') {
      var list = look(node.getAttribute('list').replace(/[{}\s]/g, ''), sc) || [];
      var as = node.getAttribute('as') || 'item';
      return h(React.Fragment, { key: key }, list.map(function (it, i) { var s2 = Object.create(sc); s2[as] = it; s2.$index = i; return h(React.Fragment, { key: i }, kids(node, s2)); }));
    }
    var props = { key: key };
    Array.prototype.forEach.call(node.attributes, function (a) {
      if (a.name.indexOf('hint-') === 0) return;
      var v = interp(a.value, sc), n = a.name;
      if (n === 'style') { props.style = styleObj(v); return; }
      if (/^on[a-z]+$/i.test(n)) { n = 'on' + n.charAt(2).toUpperCase() + n.slice(3).toLowerCase(); props[n] = v; return; }
      if (n === 'checked' && typeof v === 'boolean') { props.checked = v; return; }
      if (n === 'value') { props.value = v == null ? '' : v; return; }
      props[MAP[n] || n] = v === '' && (n === 'readonly' || n === 'checked') ? true : v;
    });
    if (props.value !== undefined && !props.onChange && (tag === 'input' || tag === 'textarea')) props.readOnly = true;
    if (tag === 'a' && typeof props.href === 'string') props.href = props.href.replace(/\.dc\.html$/, '.html');
    if (VOID[tag]) return h(tag, props);
    return h(tag, props, kids(node, sc));
  }
  window.DCLogic = class extends React.Component {
    render() {
      var tpl = document.getElementById('dc-template').content;
      var roots = []; tpl.childNodes.forEach(function (c) { if (c.nodeType === 1) roots.push(c); });
      var vals = this.renderVals();
      return h(React.Fragment, null, roots.map(function (r, i) { return build(r, vals, i); }));
    }
  };
  window.mountDC = function (props) { ReactDOM.createRoot(document.getElementById('dc-root')).render(h(window.Component, props || {})); };
})();
