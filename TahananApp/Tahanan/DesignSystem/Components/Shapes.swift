import SwiftUI

/// The brand arch: a rounded rectangle whose top corners are full semicircles (`W/2 W/2 r r`).
struct ArchShape: Shape {
    var bottomRadius: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        let top = min(rect.width / 2, rect.height)
        let bottom = min(bottomRadius, (rect.height - top) , rect.width / 2)
        return UnevenRoundedRectangle(
            cornerRadii: .init(topLeading: top, bottomLeading: max(0, bottom), bottomTrailing: max(0, bottom), topTrailing: top),
            style: .circular
        ).path(in: rect)
    }
}

/// An open arch outline (border-top + sides, no bottom), used for the expanding rings.
struct ArchOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let r = rect.width / 2
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}

/// A CSS `border-radius: tl tr br bl` box.
struct CornerBox: Shape {
    var tl: CGFloat, tr: CGFloat, br: CGFloat, bl: CGFloat

    init(_ tl: CGFloat, _ tr: CGFloat, _ br: CGFloat, _ bl: CGFloat) {
        self.tl = tl; self.tr = tr; self.br = br; self.bl = bl
    }

    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(cornerRadii: .init(topLeading: tl, bottomLeading: bl, bottomTrailing: br, topTrailing: tr), style: .circular).path(in: rect)
    }
}

/// A photo filling its frame (object-fit: cover), optionally with Ken Burns.
struct Photo: View {
    let name: String
    var kenBurns = false
    var kbDuration: Double = 16

    var body: some View {
        GeometryReader { geo in
            Group {
                if kenBurns {
                    image(geo.size).kenBurns(kbDuration)
                } else {
                    image(geo.size)
                }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }

    private func image(_ size: CGSize) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
    }
}
