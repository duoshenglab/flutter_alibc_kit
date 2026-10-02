const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const script = fs.readFileSync(require('node:path').join(__dirname, '../src/main/assets/qd_authorize.js'), 'utf8');
function run(host, options = {}) {
  let clicks = 0, submits = 0, changed;
  const button = { textContent: options.label || '授权', disabled: false,
    getClientRects: () => [1], getAttribute: () => null, click: () => clicks++ };
  const form = { action: 'https://oauth.m.taobao.com/authorize.do',
    querySelector: selector => selector.includes('client_id') || selector.includes('response_type') ? {} : null,
    requestSubmit: () => submits++ };
  const context = { location: { protocol: 'https:', hostname: host, pathname: '/authorize', href: `https://${host}/authorize` },
    window: {}, URL, document: {documentElement: {}, forms: options.form ? [form] : [],
      querySelector: () => options.login ? {} : null,
      querySelectorAll: () => options.dynamic && !options.ready ? [] : [button]},
    MutationObserver: class { constructor(callback) { changed = callback; } observe() {} disconnect() {} },
    setTimeout: () => 1, clearTimeout: () => {} };
  vm.runInNewContext(script, context);
  if (options.dynamic) { options.ready = true; changed(); changed(); }
  vm.runInNewContext(script, context);
  return {clicks, submits};
}
assert.deepEqual(run('oauth.m.taobao.com'), {clicks: 1, submits: 0});
assert.deepEqual(run('example.com'), {clicks: 0, submits: 0});
assert.deepEqual(run('oauth.m.taobao.com', {login: true}), {clicks: 0, submits: 0});
assert.deepEqual(run('oauth.m.taobao.com', {label: '登录'}), {clicks: 0, submits: 0});
assert.deepEqual(run('oauth.m.taobao.com', {label: '登录', form: true}), {clicks: 0, submits: 1});
assert.deepEqual(run('oauth.m.taobao.com', {dynamic: true}), {clicks: 1, submits: 0});
console.log('6 authorization script scenarios passed');
