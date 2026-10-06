import SwiftUI

/// Six `.otp` boxes (46 × 58, radius 14, JetBrains Mono 24) with a blinking caret in the active box.
/// Typing goes to a hidden field; `code` starts with the digits shown in the prototype.
struct OTPField: View {
    @Binding var code: String
    var length = 6
    var boxWidth: CGFloat = 46
    var spacing: CGFloat = 8

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            TextField("", text: Binding(
                get: { code },
                set: { code = String($0.filter(\.isNumber).prefix(length)) }
            ))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($focused)
            .opacity(0.01)
            .frame(width: 1, height: 1)
            .accessibilityLabel("Verification code")

            HStack(spacing: spacing) {
                ForEach(0..<length, id: \.self) { i in
                    box(i)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { focused = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verification code, \(code.count) of \(length) digits")
    }

    private func box(_ i: Int) -> some View {
        let chars = Array(code)
        let active = i == min(chars.count, length - 1) && chars.count < length
        return ZStack {
            if i < chars.count {
                Text(String(chars[i])).font(Typo.fixedMono(24)).fontWeight(.semibold).foregroundStyle(Palette.text)
            } else if active {
                BlinkingCaret()
            }
        }
        .frame(width: boxWidth, height: 58)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(active ? Palette.yellow : .white(0.13), lineWidth: 1))
        .background(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Palette.yellow.opacity(active ? 0.14 : 0), lineWidth: 4)
                .padding(-4)
        )
    }
}

#Preview {
    @Previewable @State var code = "4829"
    OTPField(code: $code).padding().background(Palette.night)
}
