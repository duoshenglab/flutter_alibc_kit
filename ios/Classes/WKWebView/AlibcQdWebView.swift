import UIKit
import WebKit

/// Retains an authenticated SDK WebView until the matching OAuth callback arrives.
final class AlibcQdWebView: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private let oauth: QdOAuthRequest
    private let authorizeURL: String
    private let completion: (String, String, [String: String]?) -> Void
    private var completed = false
    private var deadline: DispatchWorkItem?
    private var webView: WKWebView!

    init(url: String, completion: @escaping (String, String, [String: String]?) -> Void) throws {
        oauth = try QdOAuthRequest(url)
        authorizeURL = url
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        // Match AlibcWkWebView: WindVane bridges SDK login cookies and POST bodies.
        // Enable it before creating the WebView to avoid repeated login redirects.
        WVURLProtocolService.setSupportWKURLProtocol(true)
        let container = UIView()
        container.isUserInteractionEnabled = false
        container.backgroundColor = .clear
        // Keep native visibility/layout intact. Only the document is transparent.
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(WKUserScript(
            source: Self.transparentScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.add(QdWeakScriptHandler(self), name: "alibcQdStatus")
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        container.addSubview(webView)
        view = container
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }

    func start(parent: UIViewController, backURL: String) {
        parent.addChild(self)
        view.frame = parent.view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parent.view.addSubview(view)
        didMove(toParent: parent)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let timer = DispatchWorkItem { [weak self] in self?.finish("TIMEOUT", "渠道授权超时，请使用可见授权流程重试", nil) }
        deadline = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: timer)
        let params = AlibcTradeShowParams()
        params.openType = .auto
        params.linkKey = "taobao"
        params.backUrl = backURL
        params.isNeedPush = true
        let status = AlibcTradeSDK.sharedInstance().tradeService().open(
            byUrl: authorizeURL, identity: "trade", webView: webView,
            parentController: self, showParams: params, taoKeParams: nil, trackParam: nil,
            tradeProcessSuccessCallback: { _ in },
            tradeProcessFailedCallback: { [weak self] error in
                self?.finish(String((error as NSError?)?.code ?? -1), "百川无法打开渠道授权页面", nil)
            })
        NSLog("[AlibcQd] SDK open status=%ld", status)
        if status != 1 { finish("OPEN_FAILED", "渠道授权需要在应用内 H5 页面打开", nil) }
    }

    private func consume(_ url: URL?) -> Bool {
        if completed { return true }
        guard let url = url else { return false }
        do {
            guard let data = try oauth.readCallback(url) else { return false }
            if data["error"] != nil { finish("AUTH_DENIED", "淘宝渠道授权失败或被拒绝", nil) }
            else { finish("0", "成功", data) }
        } catch { finish("INVALID_CALLBACK", "授权回调校验失败", nil) }
        return true
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let consumed = navigationAction.targetFrame?.isMainFrame == true && consume(navigationAction.request.url)
        decisionHandler(consumed ? .cancel : .allow)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("[AlibcQd] navigation finished; checking OAuth result and authorization button")
        if !consume(webView.url) { webView.evaluateJavaScript(Self.authorizeScript, completionHandler: { [weak self] _, error in
            if error != nil { self?.finish("SCRIPT_FAILED", "无法执行渠道授权脚本", nil) }
        }) }
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        NSLog("[AlibcQd] navigation started")
    }
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        _ = consume(webView.url)
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard !completed, message.frameInfo.isMainFrame,
              let status = message.body as? String,
              ["watching", "button_clicked", "form_submitted", "button_not_found", "login_required", "not_authorization_page"].contains(status) else { return }
        // Log stages only; never include URL queries, OAuth codes, or account data.
        NSLog("[AlibcQd] script stage=%@", status)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { navigationFailed(error) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { navigationFailed(error) }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { finish("LOAD_FAILED", "渠道授权页面进程已退出", nil) }
    private func navigationFailed(_ error: Error) {
        // The SDK may intercept a redirect before forwarding navigation policy.
        // Recover only a callback that passes the same origin/path/state checks.
        if consume(QdOAuthRequest.failingURL(error as NSError)) || consume(webView?.url) { return }
        if (error as NSError).code != NSURLErrorCancelled { finish("LOAD_FAILED", "渠道授权页面加载失败", nil) }
    }
    func cancel() { finish("CANCELLED", "渠道授权已取消", nil) }
    private func finish(_ code: String, _ message: String, _ data: [String: String]?) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in self?.finish(code, message, data) }
            return
        }
        guard !completed else { return }
        completed = true
        NSLog("[AlibcQd] completed code=%@", code)
        deadline?.cancel()
        deadline = nil
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "alibcQdStatus")
        willMove(toParent: nil)
        viewIfLoaded?.removeFromSuperview()
        removeFromParent()
        completion(code, message, data)
    }
    private static let transparentScript = #"""
(function () {
  function apply() {
    if (!document.documentElement) return false;
    var style = document.createElement('style');
    style.textContent = 'html { opacity: 0 !important; background: transparent !important; }';
    document.documentElement.appendChild(style);
    return true;
  }
  if (!apply()) {
    var observer = new MutationObserver(function () {
      if (apply()) observer.disconnect();
    });
    observer.observe(document, {childList: true, subtree: true});
  }
})();
"""#
    private static let authorizeScript = #"""
(function () {
  function report(status) {
    window.webkit.messageHandlers.alibcQdStatus.postMessage(status);
  }
  if (location.protocol !== 'https:' || location.hostname !== 'oauth.m.taobao.com' ||
      location.pathname !== '/authorize') { report('not_authorization_page'); return; }
  if (window.__alibcQdWatcher) return;
  window.__alibcQdWatcher = true;
  report('watching');
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
        report('button_clicked');
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
        report('form_submitted');
        if (typeof form.requestSubmit === 'function') form.requestSubmit();
        else HTMLFormElement.prototype.submit.call(form);
        return;
      }
    }
  }
  observer = new MutationObserver(authorize);
  observer.observe(document.documentElement, {childList: true, subtree: true, attributes: true});
  timeout = setTimeout(function () {
    observer.disconnect();
    report(document.querySelector('input[type="password"]') ? 'login_required' : 'button_not_found');
  }, 15000);
  authorize();
})();
"""#
}

private final class QdWeakScriptHandler: NSObject, WKScriptMessageHandler {
    private weak var target: AlibcQdWebView?
    init(_ target: AlibcQdWebView) { self.target = target }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
