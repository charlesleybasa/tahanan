import PhotosUI
import SwiftUI

/// QR scanner: live camera inside a dimmed surround, animated yellow corners and scan line.
/// Funnel/Seller codes route to Booking or Payment. The design's "try a code" buttons stay as debug shortcuts.
struct ScanView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router

    @State private var hit: QRRoute?
    @State private var cameraReady = false
    @State private var torch = false
    @State private var photo: PhotosPickerItem?

    private let frameTop: CGFloat = 200
    private let frameSize: CGFloat = 280

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let frameRect = CGRect(x: (geo.size.width - frameSize) / 2, y: frameTop - 54 + safeTop, width: frameSize, height: frameSize)

            ZStack(alignment: .topLeading) {
                Palette.scanGround

                if cameraReady {
                    QRCameraView(torchOn: torch) { code in found(QRRoute.parse(code)) }
                } else {
                    Photo(name: "photoRow")
                        .padding(-40)
                        .blur(radius: 22)
                        .brightness(-0.55)
                        .saturation(1.2)
                }

                // box-shadow: 0 0 0 999px rgba(2,6,14,.55) around the rounded viewfinder
                DimmedSurround(hole: frameRect, radius: 36)
                    .fill(Color(hex: 0x02060E, alpha: 0.55), style: FillStyle(eoFill: true))
                    .allowsHitTesting(false)

                viewfinder
                    .frame(width: frameSize, height: frameSize)
                    .offset(x: frameRect.minX, y: frameRect.minY)

                message
                    .frame(width: geo.size.width)
                    .offset(y: 506 - 54 + safeTop)
            }
            .ignoresSafeArea()
            .overlay(alignment: .top) { topBar }
            .overlay(alignment: .bottom) { tryPanel.padding(.horizontal, 12).padding(.bottom, 16 - 34 + 8) }
        }
        .background(Palette.scanGround.ignoresSafeArea())
        .task {
            if CameraAccess.isAvailable { cameraReady = await CameraAccess.request() }
        }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data),
                   let code = QRImageReader.decode(img) {
                    found(QRRoute.parse(code))
                } else {
                    state.showToast("No QR code found in that photo", icon: .info, tint: Palette.orange)
                }
            }
        }
    }

    private func found(_ route: QRRoute) {
        guard hit == nil else { return }
        withAnimation(.easeInOut(duration: 0.3)) { hit = route }
        Task {
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            router.go(route == .payment ? .payment : .booking, state: state)
        }
    }

    private var topBar: some View {
        HStack {
            IconButton(.close, label: "Close scanner", background: .white(0.12)) { router.go(.home, state: state) }
            Spacer()
            Text("Scan QR").font(Typo.outfit(18, .semibold)).foregroundStyle(Palette.text)
            Spacer()
            IconButton(.bolt, label: "Toggle flashlight", background: torch ? Palette.yellow.opacity(0.35) : .white(0.12)) { torch.toggle() }
        }
        .padding(.horizontal, 20)
    }

    private var viewfinder: some View {
        let color = hit == nil ? Palette.yellow : Palette.green
        return ZStack {
            if !cameraReady {
                DecorativeQR()
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                    .shadow(color: .black.opacity(0.5), radius: 25, y: 20)
                    .rotation3DEffect(.degrees(8), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                    .rotationEffect(.degrees(-3))
                    .padding(40)
                    .fadeIn()
            }
            ScanCorners(length: 52, lineWidth: 5, radius: 30, color: color)
                .modifier(BreathingModifier())
                .animation(.easeInOut(duration: 0.3), value: hit)
            if hit == nil {
                ScanLine(inset: 18, thickness: 3, glow: 22)
            } else {
                RoundedRectangle(cornerRadius: 36).fill(Palette.green.opacity(0.25))
                Circle().fill(Palette.green).frame(width: 86, height: 86)
                    .overlay(IconView(.check, size: 40).foregroundStyle(.white))
                    .background(Circle().fill(Palette.green.opacity(0.25)).padding(-12))
                    .pop()
            }
        }
    }

    @ViewBuilder
    private var message: some View {
        Group {
            if let hit {
                Text(hit == .payment ? "Payment QR found · opening payment" : "Booking QR found · opening booking")
                    .font(Typo.manrope(16, .extrabold)).foregroundStyle(Palette.acceptedText)
                    .fadeIn()
            } else {
                Text("Point your camera at the QR from your\nHomeful seller or the Funnel app.")
                    .font(Typo.manrope(15)).foregroundStyle(Palette.softer).lineSpacing(7)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 30)
    }

    private var tryPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Prototype · try a code").overline()
            HStack(spacing: 10) {
                tryButton(.home, "Booking QR") { found(.booking) }
                tryButton(.wallet, "Payment QR") { found(.payment) }
            }
            .padding(.top, 12)
            PhotosPicker(selection: $photo, matching: .images) {
                HStack(spacing: 10) {
                    IconView(.image, size: 18)
                    Text("Upload QR from photos").font(Typo.manrope(15, .bold))
                }
                .foregroundStyle(Palette.text)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(Capsule().fill(Color.white(0.06)))
                .overlay(Capsule().strokeBorder(Color.white(0.14), lineWidth: 1))
            }
            .padding(.top, 10)
        }
        .padding(18)
        .glass(30, fill: Color(hex: 0x0D1C38, alpha: 0.85), blur: true)
        .modifier(SheetUpModifier())
    }

    private func tryButton(_ icon: Icon, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                IconView(icon).foregroundStyle(Palette.yellow)
                Text(title).font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 76)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white(0.12), lineWidth: 1))
        }
        .pressable()
    }
}

/// `.sheet` entrance used by in-screen panels: slide up from below, .55s cubic-bezier(.2,.9,.2,1).
struct SheetUpModifier: ViewModifier {
    @State private var shown = false
    func body(content: Content) -> some View {
        content.offset(y: shown ? 0 : 400)
            .onAppear { withAnimation(Motion.sheet()) { shown = true } }
    }
}

/// Full-screen rectangle with a rounded hole, filled even-odd.
struct DimmedSurround: Shape {
    var hole: CGRect
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path(rect.insetBy(dx: -500, dy: -500))
        p.addRoundedRect(in: hole, cornerSize: CGSize(width: radius, height: radius), style: .continuous)
        return p
    }
}

#Preview {
    ScanView().environment(AppState.preview).environment(AppRouter())
}
