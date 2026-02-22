import UIKit
import AVFoundation

protocol QRScannerDelegate: AnyObject {
    func qrScanner(_ scanner: QRScannerViewController, didScanCode code: String)
    func qrScannerDidCancel(_ scanner: QRScannerViewController)
}

class QRScannerViewController: UIViewController {

    weak var delegate: QRScannerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasScanned = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video) else {
            showError("Camera not available")
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            showError("Cannot access camera")
            return
        }

        guard session.canAddInput(input) else {
            showError("Cannot configure camera")
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            showError("Cannot configure scanner")
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)

        self.captureSession = session
        self.previewLayer = preview
    }

    // MARK: - UI

    private func setupUI() {
        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        // Prompt label
        let promptLabel = UILabel()
        promptLabel.text = "Scan nsec or npub QR code"
        promptLabel.textColor = .white
        promptLabel.font = .systemFont(ofSize: 15, weight: .medium)
        promptLabel.textAlignment = .center
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(promptLabel)

        NSLayoutConstraint.activate([
            promptLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            promptLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // Scan frame overlay
        let frameView = UIView()
        frameView.layer.borderColor = UIColor(red: 0xa6/255, green: 0xe2/255, blue: 0x2e/255, alpha: 1).cgColor
        frameView.layer.borderWidth = 2
        frameView.layer.cornerRadius = 12
        frameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(frameView)

        NSLayoutConstraint.activate([
            frameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frameView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            frameView.widthAnchor.constraint(equalToConstant: 250),
            frameView.heightAnchor.constraint(equalToConstant: 250)
        ])
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.qrScannerDidCancel(self)
    }

    private func showError(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let code = object.stringValue else {
            return
        }

        hasScanned = true
        captureSession?.stopRunning()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        delegate?.qrScanner(self, didScanCode: code)
    }
}
