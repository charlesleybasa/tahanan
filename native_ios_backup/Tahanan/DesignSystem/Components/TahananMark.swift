import SwiftUI

/// The Tahanan logo built from shapes, on the design's 104 × 100 unit grid:
/// sun (50,0) 54², roof arch (0,18) 70×82 r35/5, door (22,62) 26×38 r13, bush (81,77) 19×23 r9.5/3.
struct TahananMark: View {
    var width: CGFloat
    var sunGlow: Color? = nil
    var sunGlowRadius: CGFloat = 0

    var k: CGFloat { width / 104 }
    var height: CGFloat { 100 * k }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle().fill(Palette.yellow)
                .frame(width: 54 * k, height: 54 * k)
                .shadow(color: sunGlow ?? .clear, radius: sunGlowRadius)
                .offset(x: 50 * k)
            CornerBox(35 * k, 35 * k, 5 * k, 5 * k).fill(Palette.roofGradient)
                .frame(width: 70 * k, height: 82 * k)
                .offset(y: 18 * k)
            CornerBox(13 * k, 13 * k, 0, 0).fill(Palette.orange)
                .frame(width: 26 * k, height: 38 * k)
                .offset(x: 22 * k, y: 62 * k)
            CornerBox(9.5 * k, 9.5 * k, 3 * k, 3 * k).fill(Palette.green)
                .frame(width: 19 * k, height: 23 * k)
                .offset(x: 81 * k, y: 77 * k)
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

/// Mark + "Tahanan" wordmark used in headers (30px mark, Outfit 700 20px, -0.02em).
struct TahananLockup: View {
    var markWidth: CGFloat = 30
    var fontSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 10) {
            TahananMark(width: markWidth)
            Text("Tahanan")
                .font(Typo.outfit(fontSize, .bold))
                .tracking(-0.02 * fontSize)
                .foregroundStyle(Palette.text)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tahanan")
    }
}

/// The support agent avatar: a 30pt yellow circle with a 16pt mark.
struct AgentAvatar: View {
    var body: some View {
        Circle().fill(Palette.yellow)
            .frame(width: 30, height: 30)
            .overlay(TahananMark(width: 16))
    }
}

#Preview {
    VStack(spacing: 30) {
        TahananMark(width: 150)
        TahananLockup()
        AgentAvatar()
    }
    .padding()
    .background(Palette.night)
}
