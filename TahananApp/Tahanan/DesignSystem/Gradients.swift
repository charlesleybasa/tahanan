import SwiftUI

/// A CSS `radial-gradient(RX RY at CX CY, stops…)` with independent x/y radii, drawn to fill its frame.
/// `rx`/`ry` and `cx`/`cy` are fractions of the frame size, like CSS percentages.
struct CSSRadialGradient: View {
    var rx: CGFloat
    var ry: CGFloat
    var cx: CGFloat
    var cy: CGFloat
    var stops: [Gradient.Stop]

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: cx * size.width, y: cy * size.height)
            let radiusX = max(rx * size.width, 0.001)
            let radiusY = max(ry * size.height, 0.001)
            ctx.translateBy(x: center.x, y: center.y)
            ctx.scaleBy(x: 1, y: radiusY / radiusX)
            let reach = max(size.width, size.height) * 4
            ctx.fill(
                Path(CGRect(x: -reach, y: -reach, width: reach * 2, height: reach * 2)),
                with: .radialGradient(Gradient(stops: stops), center: .zero, startRadius: 0, endRadius: radiusX)
            )
        }
        .allowsHitTesting(false)
    }
}

/// `radial-gradient(closest-side, color, transparent)` on a circle or ellipse element.
struct ClosestSideGlow: View {
    var stops: [Gradient.Stop]

    init(_ color: Color, _ alpha: Double) {
        stops = [.init(color: color.opacity(alpha), location: 0), .init(color: color.opacity(0), location: 1)]
    }

    init(stops: [Gradient.Stop]) { self.stops = stops }

    var body: some View {
        GeometryReader { geo in
            CSSRadialGradient(rx: 0.5, ry: 0.5, cx: 0.5, cy: 0.5, stops: stops)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }
}

/// The app ground behind every screen:
/// radial-gradient(110% 55% at 85% -8%, rgba(46,107,230,.34), transparent 62%),
/// radial-gradient(70% 40% at -10% 105%, rgba(255,196,46,.09), transparent 60%), #08142A.
struct AppBackground: View {
    var body: some View {
        ZStack {
            Palette.night
            CSSRadialGradient(rx: 0.7, ry: 0.4, cx: -0.1, cy: 1.05, stops: [
                .init(color: Palette.yellow.opacity(0.09), location: 0),
                .init(color: Palette.yellow.opacity(0), location: 0.6),
            ])
            CSSRadialGradient(rx: 1.1, ry: 0.55, cx: 0.85, cy: -0.08, stops: [
                .init(color: Palette.blue.opacity(0.34), location: 0),
                .init(color: Palette.blue.opacity(0), location: 0.62),
            ])
        }
        .ignoresSafeArea()
    }
}

/// Diagonal navy stripes used on progress tracks: repeating-linear-gradient(-45deg, …95 0 6px, …72 6px 12px).
struct StripesFill: View {
    var dark: Double = 0.95
    var light: Double = 0.72

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Palette.ink.opacity(light)))
            // stripes run perpendicular to -45deg, period 12px measured along the gradient line
            let period: CGFloat = 12 * sqrt(2)
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                var p = Path()
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                p.addLine(to: CGPoint(x: x + size.height + period / 2, y: 0))
                p.addLine(to: CGPoint(x: x + period / 2, y: size.height))
                p.closeSubpath()
                ctx.fill(p, with: .color(Palette.ink.opacity(dark)))
                x += period
            }
        }
    }
}
