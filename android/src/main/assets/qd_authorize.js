(function () {
  if (location.protocol !== 'https:' || location.hostname !== 'oauth.m.taobao.com' ||
      location.pathname !== '/authorize' || window.__alibcQdWatcher) return;
  window.__alibcQdWatcher = true;
  var submitted = false;
  var observer;
  var timeout;
  function visible(el) {
    return el.getClientRects().length > 0 && !el.disabled &&
      el.getAttribute('aria-disabled') !== 'true';
  }
  function finish() {
    submitted = true;
    if (observer) observer.disconnect();
    clearTimeout(timeout);
  }
  function authorize() {
    if (submitted || document.querySelector('input[type="password"]')) return;
    var buttons = document.querySelectorAll('button,input[type="submit"],input[type="button"],a,[role="button"]');
    for (var i = 0; i < buttons.length; i++) {
      var button = buttons[i];
      var text = (button.value || button.textContent || '').replace(/\s/g, '');
      if (visible(button) && /^(授权|同意授权|确认授权|同意并授权)$/.test(text)) {
        finish();
        button.click();
        return;
      }
    }
    // Only submit an OAuth form, never an arbitrary first form or login form.
    var forms = document.forms;
    for (var j = 0; j < forms.length; j++) {
      var form = forms[j];
      var action;
      try { action = new URL(form.action || location.href, location.href); } catch (e) { continue; }
      if (action.protocol === 'https:' && action.hostname === 'oauth.m.taobao.com' &&
          (action.pathname === '/authorize' || action.pathname === '/authorize.do') &&
          form.querySelector('[name="client_id"]') &&
          form.querySelector('[name="response_type"]') &&
          !form.querySelector('input[type="text"],input[type="tel"],input[type="password"]')) {
        finish();
        if (typeof form.requestSubmit === 'function') form.requestSubmit();
        else HTMLFormElement.prototype.submit.call(form);
        return;
      }
    }
  }
  observer = new MutationObserver(authorize);
  observer.observe(document.documentElement, {childList: true, subtree: true, attributes: true});
  timeout = setTimeout(function () { observer.disconnect(); }, 15000);
  authorize();
})();
