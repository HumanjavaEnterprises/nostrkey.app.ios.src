import UIKit
import WebKit

class MainViewController: UIViewController {

    private var backgroundWebView: WKWebView!
    private var uiWebView: WKWebView!
    private var bgBridge: IOSBridge!
    private var uiBridge: IOSBridge!

    private let monokaiBg = UIColor(red: 0x27/255.0, green: 0x28/255.0, blue: 0x22/255.0, alpha: 1)
    private let monokaiBar = UIColor(red: 0x3e/255.0, green: 0x3d/255.0, blue: 0x32/255.0, alpha: 1)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = monokaiBg

        setupWebViews()
        setupBridges()
        loadContent()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup

    private func setupWebViews() {
        // Background WebView (invisible, runs background.js)
        let bgConfig = createWebViewConfig(name: "background")
        backgroundWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: bgConfig)
        backgroundWebView.isHidden = true
        backgroundWebView.navigationDelegate = self
        #if DEBUG
        if #available(iOS 16.4, *) {
            backgroundWebView.isInspectable = true
        }
        #endif
        view.addSubview(backgroundWebView)

        // UI WebView (visible, runs sidepanel)
        let uiConfig = createWebViewConfig(name: "ui")
        uiWebView = WKWebView(frame: .zero, configuration: uiConfig)
        uiWebView.isOpaque = false
        uiWebView.backgroundColor = monokaiBg
        uiWebView.scrollView.backgroundColor = monokaiBg
        // Prevent WKWebView from adding its own safe area insets —
        // we handle them in CSS via env(safe-area-inset-*)
        uiWebView.scrollView.contentInsetAdjustmentBehavior = .never
        uiWebView.navigationDelegate = self
        uiWebView.uiDelegate = self
        #if DEBUG
        if #available(iOS 16.4, *) {
            uiWebView.isInspectable = true
        }
        #endif
        view.addSubview(uiWebView)

        uiWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            uiWebView.topAnchor.constraint(equalTo: view.topAnchor),
            uiWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            uiWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            uiWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func createWebViewConfig(name: String) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        let contentController = WKUserContentController()

        // Inject __nostrkey_baseURL at document start
        if let webURL = Bundle.main.url(forResource: "background", withExtension: "html", subdirectory: "Web") {
            let baseURL = webURL.deletingLastPathComponent().absoluteString
            let script = WKUserScript(
                source: "window.__nostrkey_baseURL = '\(baseURL)';",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            contentController.addUserScript(script)
        }

        config.userContentController = contentController
        return config
    }

    private func setupBridges() {
        bgBridge = IOSBridge(
            webView: backgroundWebView,
            onNavigate: { [weak self] url in self?.navigateUI(url) }
        )
        bgBridge.setPeer(uiWebView)

        uiBridge = IOSBridge(
            webView: uiWebView,
            onNavigate: { [weak self] url in self?.navigateUI(url) },
            onScanQR: { [weak self] in self?.launchQRScanner() }
        )
        uiBridge.setPeer(backgroundWebView)

        // Register message handlers
        backgroundWebView.configuration.userContentController.add(bgBridge, name: "nostrkey")
        uiWebView.configuration.userContentController.add(uiBridge, name: "nostrkey")
    }

    private func loadContent() {
        guard let bgURL = Bundle.main.url(forResource: "background", withExtension: "html", subdirectory: "Web") else {
            print("[NostrKey] ERROR: background.html not found in bundle")
            return
        }
        let webDir = bgURL.deletingLastPathComponent()
        backgroundWebView.loadFileURL(bgURL, allowingReadAccessTo: webDir)
    }

    // MARK: - Insets
    // Safe area insets are handled natively by CSS env(safe-area-inset-*)
    // via viewport-fit=cover in the HTML meta tags. No JS injection needed.

    // MARK: - Navigation

    func navigateUI(_ url: String) {
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            // External link — open in Safari
            if let externalURL = URL(string: url) {
                UIApplication.shared.open(externalURL)
            }
            return
        }

        // "Back" to sidepanel: pop the navigation stack so WKWebView's
        // page cache restores the sidepanel with the correct tab active.
        if url == "sidepanel.html" && uiWebView.canGoBack {
            uiWebView.goBack()
            return
        }

        guard let webDir = Bundle.main.url(forResource: "background", withExtension: "html", subdirectory: "Web")?.deletingLastPathComponent() else { return }

        let resolved: URL
        if url.hasPrefix("file://") {
            guard let fileURL = URL(string: url) else { return }
            resolved = fileURL
        } else if url.hasPrefix("/") {
            resolved = webDir.appendingPathComponent(String(url.dropFirst()))
        } else {
            resolved = webDir.appendingPathComponent(url)
        }

        uiWebView.loadFileURL(resolved, allowingReadAccessTo: webDir)
    }

    // MARK: - QR Scanner

    private func launchQRScanner() {
        let scanner = QRScannerViewController()
        scanner.delegate = self
        scanner.modalPresentationStyle = .fullScreen
        present(scanner, animated: true)
    }

    // MARK: - Cleanup

    deinit {
        // Remove message handlers to break retain cycle
        backgroundWebView.configuration.userContentController.removeScriptMessageHandler(forName: "nostrkey")
        uiWebView.configuration.userContentController.removeScriptMessageHandler(forName: "nostrkey")
    }
}

// MARK: - WKNavigationDelegate

extension MainViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView === backgroundWebView {
            // Background is ready — load UI after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                guard let uiURL = Bundle.main.url(forResource: "sidepanel", withExtension: "html", subdirectory: "Web") else {
                    print("[NostrKey] ERROR: sidepanel.html not found in bundle")
                    return
                }
                let webDir = uiURL.deletingLastPathComponent()
                self.uiWebView.loadFileURL(uiURL, allowingReadAccessTo: webDir)
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard webView === uiWebView else {
            decisionHandler(.allow)
            return
        }

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Allow file:// URLs (internal pages)
        if url.isFileURL {
            decisionHandler(.allow)
            return
        }

        // External URLs — open in Safari
        if url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate

extension MainViewController: WKUIDelegate {

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Handle target="_blank" links — load in same WebView
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            if url.isFileURL {
                webView.load(navigationAction.request)
            } else {
                UIApplication.shared.open(url)
            }
        }
        return nil
    }
}

// MARK: - QRScannerDelegate

extension MainViewController: QRScannerDelegate {

    func qrScanner(_ scanner: QRScannerViewController, didScanCode code: String) {
        scanner.dismiss(animated: true)
        uiBridge.deliverScanResult(code)
    }

    func qrScannerDidCancel(_ scanner: QRScannerViewController) {
        scanner.dismiss(animated: true)
        uiBridge.deliverScanError("Scan cancelled")
    }
}
