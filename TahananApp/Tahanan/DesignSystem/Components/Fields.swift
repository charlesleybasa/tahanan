import SwiftUI

/// `.field`: 56pt, radius 16, white 6% fill, 13% border; focus turns the border yellow with a 4pt yellow ring.
struct FieldChrome: ViewModifier {
    var focused: Bool
    var height: CGFloat? = 56
    var borderOverride: Color? = nil
    var radius: CGFloat = Radii.input

    func body(content: Content) -> some View {
        content
            .frame(height: height)
            .background(RoundedRectangle(cornerRadius: radius).fill(focused ? Palette.yellow.opacity(0.05) : .white(0.06)))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(focused ? Palette.yellow : (borderOverride ?? .white(0.13)), lineWidth: 1))
            // box-shadow: 0 0 0 4px rgba(255,196,46,.12) — an outer ring only
            .background(
                RoundedRectangle(cornerRadius: radius + 4)
                    .strokeBorder(Palette.yellow.opacity(focused ? 0.12 : 0), lineWidth: 4)
                    .padding(-4)
            )
            .animation(.easeInOut(duration: 0.2), value: focused)
    }
}

/// A labeled text input matching the prototype's `.lbl` + `.field` pair.
struct TahananTextField: View {
    var label: String?
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var secure = false
    var mono = false
    var borderOverride: Color? = nil
    var capitalization: TextInputAutocapitalization = .sentences
    var labelSuffix: String? = nil
    var leadingIcon: Icon? = nil

    @FocusState private var focused: Bool
    @State private var reveal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label {
                HStack(spacing: 4) {
                    Text(label).fieldLabel()
                    if let labelSuffix { Text(labelSuffix).font(Typo.manrope(13, .semibold)).foregroundStyle(Palette.placeholder) }
                }
            }
            HStack(spacing: 0) {
                if let leadingIcon {
                    IconView(leadingIcon).foregroundStyle(Palette.subtle).padding(.leading, 16)
                }
                Group {
                    if secure && !reveal {
                        SecureField("", text: $text, prompt: prompt)
                    } else {
                        TextField("", text: $text, prompt: prompt)
                    }
                }
                .font(mono ? Typo.mono(16) : Typo.manrope(16))
                .foregroundStyle(Palette.text)
                .tint(Palette.yellow)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : capitalization)
                .autocorrectionDisabled(keyboard == .emailAddress || secure || mono)
                .focused($focused)
                .padding(.leading, leadingIcon == nil ? 16 : 12)
                .padding(.trailing, secure ? 0 : 16)

                if secure {
                    Button { reveal.toggle() } label: {
                        IconView(.eye, size: 20).foregroundStyle(Palette.muted).frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 6)
                    .accessibilityLabel(reveal ? "Hide password" : "Show password")
                }
            }
            .modifier(FieldChrome(focused: focused, borderOverride: borderOverride))
            .contentShape(Rectangle())
            .onTapGesture { focused = true }
        }
    }

    private var prompt: Text { Text(placeholder).foregroundStyle(Palette.placeholder) }
}

/// "+63" prefix box + mobile input.
struct PhoneField: View {
    var label: String?
    @Binding var text: String
    var placeholder = "917 123 4567"
    var borderOverride: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label { Text(label).fieldLabel() }
            HStack(spacing: 8) {
                Text("+63")
                    .font(Typo.mono(15, .semibold))
                    .foregroundStyle(Palette.text)
                    .padding(.horizontal, 14)
                    .frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white(0.13), lineWidth: 1))
                TahananTextField(label: nil, placeholder: placeholder, text: $text, keyboard: .phonePad, contentType: .telephoneNumber, borderOverride: borderOverride)
            }
        }
    }
}

/// A 22pt checkbox with the browser's accent-color yellow.
struct Checkbox: View {
    @Binding var isOn: Bool
    var size: CGFloat = 22

    var body: some View {
        Button { isOn.toggle() } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(isOn ? Palette.yellow : Color.white(0.95))
                .frame(width: size, height: size)
                .overlay {
                    if isOn { IconView(.check, size: size - 4).foregroundStyle(Palette.ink) }
                }
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(isOn ? Palette.yellow : Color(hex: 0x767676), lineWidth: 1))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

/// Checkbox + wrapping text, like the prototype's `<label>` rows.
struct CheckboxRow<Content: View>: View {
    @Binding var isOn: Bool
    var size: CGFloat = 22
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Checkbox(isOn: $isOn, size: size)
                .frame(width: size, height: size)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { isOn.toggle() }
        }
    }
}

/// `.toggle`: 52 × 32 switch, green when on.
struct TahananToggle: View {
    @Binding var isOn: Bool
    var label: String

    var body: some View {
        Button { isOn.toggle() } label: {
            Capsule()
                .fill(isOn ? Palette.green : Color.white(0.18))
                .frame(width: 52, height: 32)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle().fill(.white)
                        .frame(width: 26, height: 26)
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                        .padding(3)
                }
                .animation(.easeInOut(duration: 0.25), value: isOn)
                .frame(minWidth: 52, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}
