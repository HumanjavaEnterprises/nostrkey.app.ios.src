import SwiftUI
import VisionKit
import AVFoundation

// MARK: - Scanner View (Main Entry Point)

/// Full-screen camera view for scanning QR codes.
/// Uses Apple's DataScannerViewController (iOS 16+) which manages its own
/// AVCaptureSession internally — no manual session queues, preview layers,
/// or lifecycle hacks needed. Handles TabView correctly via app lifecycle
/// notifications (didBecomeActive / willResignActive).
struct ScannerView: View {
    @EnvironmentObject var appState: AppState
    @State private var scannedCode: String?
    @State private var showingResult = false
    @State private var scanResult: ScanResult?
    @State private var importError: String?
    @State private var scannerError: String?
    @State private var isScanning = false

    /// Whether the device supports DataScanner (has a camera)
    private var isScannerAvailable: Bool {
        DataScannerViewController.isSupported
    }

    var body: some View {
        ZStack {
            if isScannerAvailable {
                // DataScanner handles its own permission prompting
                DataScannerRepresentable(
                    scannedCode: $scannedCode,
                    isScanning: $isScanning,
                    scannerError: $scannerError
                )
                .ignoresSafeArea(.container, edges: .top)

                // Viewfinder overlay
                scannerOverlay

            } else {
                // Device doesn't support scanning (e.g., simulator)
                noScannerView
            }

            // Error overlay
            if let error = scannerError {
                scannerErrorOverlay(error)
            }
        }
        // — Lifecycle: start/stop scanning based on tab visibility —
        .onChange(of: appState.selectedTab) { _, tab in
            isScanning = (tab == .scanner)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // App returned to foreground — restart if on scanner tab
            if appState.selectedTab == .scanner {
                isScanning = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // App going to background — stop camera
            isScanning = false
        }
        .onAppear {
            isScanning = (appState.selectedTab == .scanner)
        }
        // — Handle scanned codes —
        .onChange(of: scannedCode) { _, code in
            if let code = code {
                processScannedCode(code)
            }
        }
        .sheet(isPresented: $showingResult) {
            // Reset scannedCode when sheet is dismissed so scanner can scan again
            scannedCode = nil
        } content: {
            if let result = scanResult {
                ScanResultSheet(result: result, importError: $importError)
            }
        }
        .alert("Import Failed", isPresented: .init(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK") { importError = nil }
        } message: {
            Text(importError ?? "An unknown error occurred.")
        }
    }

    // MARK: - Overlays

    private var scannerOverlay: some View {
        VStack {
            Spacer()

            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.6), lineWidth: 2)
                .frame(width: 260, height: 260)
                .background(.clear)

            Spacer()

            // Controls bar
            HStack(spacing: 40) {
                // Placeholder for symmetry
                Color.clear
                    .frame(width: 44, height: 44)

                Text("Scan a QR code")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                // Placeholder for symmetry
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.bottom, 16)
        }
    }

    private var noScannerView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(NostrKeepSignerTheme.accent)

            Text("Scanner Not Available")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(NostrKeepSignerTheme.text)

            Text("This device does not support camera scanning.")
                .font(.subheadline)
                .foregroundStyle(NostrKeepSignerTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NostrKeepSignerTheme.bg)
    }

    private func scannerErrorOverlay(_ error: String) -> some View {
        VStack {
            Spacer()
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Process Scanned Code

    private func processScannedCode(_ code: String) {
        if code.hasPrefix("bunker://") || code.hasPrefix("nostrconnect://") {
            // NIP-46 connection request — show confirmation sheet
            if let url = URL(string: code),
               let pubkey = url.host,
               let relay = url.queryParameters["relay"] {
                scanResult = .nip46Connect(pubkey: pubkey, relay: relay)
                showingResult = true
            } else {
                if let url = URL(string: code) {
                    DeepLinkHandler.handle(url: url, appState: appState)
                }
                scannedCode = nil
            }
        } else if code.hasPrefix("nostrkeepsigner://") {
            // Parse nostrkeepsigner:// deep links — route add-relay to confirmation sheet
            if let url = URL(string: code) {
                let params = url.queryParameters
                if url.host?.lowercased() == "add-relay", let relayURL = params["url"] {
                    let name = params["name"]
                    let paid = params["paid"] == "true"
                    scanResult = .addRelay(url: relayURL, name: name, paid: paid)
                    showingResult = true
                } else {
                    // Other deep links (connect, import-keys, wallet-pass)
                    DeepLinkHandler.handle(url: url, appState: appState)
                    scannedCode = nil
                }
            } else {
                scannedCode = nil
            }
        } else if code.hasPrefix("nsec1") {
            scanResult = .importKey(nsec: code)
            showingResult = true
        } else if code.hasPrefix("npub1") {
            scanResult = .viewProfile(npub: code)
            showingResult = true
        } else if code.hasPrefix("wss://") || code.hasPrefix("ws://") {
            scanResult = .addRelay(url: code, name: nil, paid: false)
            showingResult = true
        } else {
            scanResult = .unknown(content: code)
            showingResult = true
        }
    }
}

// MARK: - DataScanner Representable

/// Wraps Apple's DataScannerViewController for use in SwiftUI.
/// DataScannerViewController manages its own AVCaptureSession — no manual
/// session queues, preview layers, or threading needed. Start/stop scanning
/// are simple, idempotent method calls.
struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool
    @Binding var scannerError: String?

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        // This is the entire lifecycle management. No session queues. No race conditions.
        // startScanning() and stopScanning() are idempotent — safe to call repeatedly.
        if isScanning {
            if !scanner.isScanning {
                do {
                    try scanner.startScanning()
                } catch {
                    DispatchQueue.main.async {
                        scannerError = "Camera error: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            if scanner.isScanning {
                scanner.stopScanning()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var scannedCode: String?
        private var lastScannedTime: Date = .distantPast
        private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

        init(scannedCode: Binding<String?>) {
            _scannedCode = scannedCode
            super.init()
            feedbackGenerator.prepare()
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Process the first recognized barcode
            guard let item = addedItems.first else { return }

            switch item {
            case .barcode(let barcode):
                guard let payload = barcode.payloadStringValue else { return }

                // Debounce: don't process the same code within 2 seconds
                let now = Date()
                guard now.timeIntervalSince(lastScannedTime) > 2.0 else { return }
                lastScannedTime = now

                // Haptic feedback
                feedbackGenerator.impactOccurred()
                feedbackGenerator.prepare()

                DispatchQueue.main.async {
                    self.scannedCode = payload
                }
            default:
                break
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // Also handle tap on recognized item
            switch item {
            case .barcode(let barcode):
                guard let payload = barcode.payloadStringValue else { return }

                let now = Date()
                guard now.timeIntervalSince(lastScannedTime) > 2.0 else { return }
                lastScannedTime = now

                feedbackGenerator.impactOccurred()
                feedbackGenerator.prepare()

                DispatchQueue.main.async {
                    self.scannedCode = payload
                }
            default:
                break
            }
        }
    }
}

// MARK: - Scan Result

enum ScanResult {
    case importKey(nsec: String)
    case viewProfile(npub: String)
    case addRelay(url: String, name: String?, paid: Bool)
    case nip46Connect(pubkey: String, relay: String)
    case unknown(content: String)
}

// MARK: - Scan Result Sheet

struct ScanResultSheet: View {
    let result: ScanResult
    @Binding var importError: String?
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch result {
                case .addRelay(let url, let name, let paid):
                    let isDuplicate = appState.relays.contains(where: { $0.url == url })
                    let displayHost = URL(string: url)?.host ?? url

                    Image(systemName: "network")
                        .font(.system(size: 48))
                        .foregroundStyle(NostrKeepSignerTheme.accent)

                    Text("Add Relay?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(NostrKeepSignerTheme.text)

                    // Relay details card
                    VStack(spacing: 12) {
                        // Host name
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundStyle(NostrKeepSignerTheme.accent)
                            Text(displayHost)
                                .font(.headline)
                                .foregroundStyle(NostrKeepSignerTheme.text)
                            Spacer()
                            if paid {
                                Text("Paid")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(NostrKeepSignerTheme.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(NostrKeepSignerTheme.orange.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }

                        // URL
                        HStack {
                            Text(url)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(NostrKeepSignerTheme.textMuted)
                                .lineLimit(1)
                            Spacer()
                        }

                        // Name (if different from URL)
                        if let name = name, name != url {
                            HStack {
                                Text("Name:")
                                    .font(.caption)
                                    .foregroundStyle(NostrKeepSignerTheme.textMuted)
                                Text(name)
                                    .font(.caption)
                                    .foregroundStyle(NostrKeepSignerTheme.text)
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .background(NostrKeepSignerTheme.bgLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 4)

                    if isDuplicate {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(NostrKeepSignerTheme.accent)
                            Text("This relay is already in your list.")
                                .font(.subheadline)
                                .foregroundStyle(NostrKeepSignerTheme.textMuted)
                        }
                    }

                    Button(isDuplicate ? "View Relays" : "Add Relay") {
                        if !isDuplicate {
                            appState.addRelay(url: url, name: name, paid: paid)
                        }
                        dismiss()
                        // Navigate to Relays tab after a brief delay to let sheet dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            appState.selectedTab = .relays
                        }
                    }
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(NostrKeepSignerTheme.accent)
                    .foregroundStyle(NostrKeepSignerTheme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                case .importKey(let nsec):
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(NostrKeepSignerTheme.orange)

                    Text("Import Key?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(NostrKeepSignerTheme.text)

                    Text("This will store the private key in the Secure Enclave on this device.")
                        .font(.subheadline)
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                        .multilineTextAlignment(.center)

                    Button("Import Key") {
                        do {
                            try appState.importKeys(nsec: nsec)
                            dismiss()
                        } catch {
                            importError = error.localizedDescription
                            dismiss()
                        }
                    }
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(NostrKeepSignerTheme.orange)
                    .foregroundStyle(NostrKeepSignerTheme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                case .viewProfile(let npub):
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(NostrKeepSignerTheme.cyan)

                    Text("Nostr Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(NostrKeepSignerTheme.text)

                    Text(npub)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                case .nip46Connect(let pubkey, let relay):
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(NostrKeepSignerTheme.accent)

                    Text("Connect to App?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(NostrKeepSignerTheme.text)

                    VStack(spacing: 8) {
                        Text("App pubkey:")
                            .font(.caption)
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                        Text(String(pubkey.prefix(16)) + "..." + String(pubkey.suffix(8)))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)

                        Text("Relay:")
                            .font(.caption)
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                        Text(relay)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    }

                    Button("Connect") {
                        // TODO: Initiate NIP-46 session
                        dismiss()
                    }
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(NostrKeepSignerTheme.accent)
                    .foregroundStyle(NostrKeepSignerTheme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                case .unknown(let content):
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)

                    Text("Unknown QR Code")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(NostrKeepSignerTheme.text)

                    Text(String(content.prefix(200)))
                        .font(.caption)
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                        .lineLimit(5)
                }

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
