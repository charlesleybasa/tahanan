import SwiftUI

/// Vertical scroller with the prototype's screen padding (56 top in a frame with a 54pt status bar).
struct ScreenScroll<Content: View>: View {
    var horizontal: CGFloat = Spacing.gutter
    var top: CGFloat = Spacing.belowStatusBar
    var bottom: CGFloat = 40
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0, content: content)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, horizontal)
                .padding(.top, top)
                .padding(.bottom, bottom)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

/// Back button + Outfit 20/600 title, as on Account, Security, About, New ticket.
struct ScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    var titleSize: CGFloat = 20
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BackButton(action: onBack)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(Typo.outfit(titleSize, .semibold)).foregroundStyle(Palette.text)
                if let subtitle {
                    Text(subtitle).font(Typo.manrope(12, .bold)).foregroundStyle(Palette.subtle)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

/// Bottom CTA bar with the prototype's fade: padding 16/20/30 over linear-gradient(transparent, #08142A 35%).
struct BottomCTABar<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0, content: content)
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(
                LinearGradient(stops: [
                    .init(color: Palette.night.opacity(0), location: 0),
                    .init(color: Palette.night, location: 0.35),
                ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
            )
    }
}

/// A fixed 390 × 844 design canvas scaled uniformly to the device, for absolutely positioned art.
struct DesignCanvas<Content: View>: View {
    static var size: CGSize { CGSize(width: 390, height: 844) }
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width / 390, geo.size.height / 844)
            ZStack(alignment: .topLeading, content: content)
                .frame(width: 390, height: 844, alignment: .topLeading)
                .scaleEffect(s, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Absolute placement inside a top-leading ZStack (CSS `left/top/width/height`).
    func place(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> some View {
        frame(width: w, height: h).offset(x: x, y: y)
    }
}
