import AVFoundation
import SwiftUI
import UIKit
import VisionKit

// MARK: - QR routing

/// Where a Funnel / Seller app QR should take the buyer.
enum QRRoute: Equatable {
    case booking, payment

    /// TODO: API — the real payload format comes from the Funnel/Seller app (e.g. a signed URL
    /// `https://homeful.ph/q/booking/<id>`). For the demo, any code mentioning "pay" opens Payment,
    /// everything else opens Booking.
    static func parse(_ payload: String) -> QRRoute {
        payload.lowercased().contains("pay") ? .payment : .booking
    }
}

enum CameraAccess {
    static var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return AVCaptureDevice.default(for: .video) != nil
        #endif
    }

    static func request() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }
}

// MARK: - QR camera

/// Live camera preview that reports the first QR code it sees.
struct QRCameraView: UIViewRepresentable {
    var torchOn: Bool
    var onCode: (String) -> Void

    func makeUIView(context: Context) -> QRPreviewView {
        let v = QRPreviewView()
        v.onCode = onCode
        v.start()
        return v
    }

    func updateUIView(_ uiView: QRPreviewView, context: Context) {
        uiView.onCode = onCode
        uiView.setTorch(torchOn)
    }

    static func dismantleUIView(_ uiView: QRPreviewView, coordinator: ()) { uiView.stop() }
}

final class QRPreviewView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    private let session = AVCaptureSession()
    private var delivered = false
    private let queue = DispatchQueue(label: "tahanan.qr")

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    func start() {
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        queue.async { [weak self] in
            guard let self, let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(input) else { return }
            self.session.beginConfiguration()
            self.session.addInput(input)
            let output = AVCaptureMetadataOutput()
            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: .main)
                output.metadataObjectTypes = [.qr]
            }
            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func stop() {
        queue.async { [session] in if session.isRunning { session.stopRunning() } }
    }

    func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !delivered, let code = (objects.first as? AVMetadataMachineReadableCodeObject)?.stringValue else { return }
        delivered = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onCode?(code)
    }
}

/// Reads a QR code from a still image (Upload QR from photos).
enum QRImageReader {
    static func decode(_ image: UIImage) -> String? {
        guard let ci = CIImage(image: image),
              let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else { return nil }
        return (detector.features(in: ci).first as? CIQRCodeFeature)?.messageString
    }
}

// MARK: - ID scanner

/// VisionKit live text scanner for the spouse's ID, with a plain camera preview fallback.
struct IDScannerView: View {
    /// Latest recognized text lines; parsed on Capture.
    @Binding var recognized: [String]

    var body: some View {
        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
            DataScannerRepresentable(recognized: $recognized)
        } else if CameraAccess.isAvailable {
            CameraPreview()
        } else {
            Color.clear
        }
    }

    static var hasCamera: Bool { CameraAccess.isAvailable }
}

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var recognized: [String]

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: false
        )
        vc.delegate = context.coordinator
        try? vc.startScanning()
        return vc
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ vc: DataScannerViewController, coordinator: Coordinator) { vc.stopScanning() }

    func makeCoordinator() -> Coordinator { Coordinator(recognized: $recognized) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var recognized: Binding<[String]>
        init(recognized: Binding<[String]>) { self.recognized = recognized }

        func dataScanner(_ s: DataScannerViewController, didUpdate updated: [RecognizedItem], allItems: [RecognizedItem]) {
            recognized.wrappedValue = allItems.compactMap {
                if case let .text(t) = $0 { return t.transcript }
                return nil
            }
        }
    }
}

/// AVFoundation preview without recognition (fallback for devices without VisionKit scanning).
struct CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> PlainPreviewView {
        let v = PlainPreviewView()
        v.start()
        return v
    }

    func updateUIView(_ uiView: PlainPreviewView, context: Context) {}
    static func dismantleUIView(_ uiView: PlainPreviewView, coordinator: ()) { uiView.stop() }
}

final class PlainPreviewView: UIView {
    private let session = AVCaptureSession()
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    func start() {
        let layer = self.layer as! AVCaptureVideoPreviewLayer
        layer.session = session
        layer.videoGravity = .resizeAspectFill
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            guard let device = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }
            session.addInput(input)
            session.startRunning()
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [session] in session.stopRunning() }
    }
}

/// Pulls an ID number out of recognized text: the longest run of digits/dashes with at least 7 digits.
enum IDTextParser {
    static func idNumber(from lines: [String]) -> String? {
        let candidates = lines.flatMap { $0.components(separatedBy: .whitespaces) }
            .filter { token in token.filter(\.isNumber).count >= 7 && token.allSatisfy { $0.isNumber || $0 == "-" } }
        return candidates.max(by: { $0.count < $1.count })
    }
}

// MARK: - Camera capture (requirements, selfie)

struct CameraCapture: UIViewControllerRepresentable {
    var front = false
    var onImage: (UIImage?) -> Void

    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        if front, UIImagePickerController.isCameraDeviceAvailable(.front) { p.cameraDevice = .front }
        p.delegate = context.coordinator
        return p
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage?) -> Void
        init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onImage(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onImage(nil) }
    }
}
