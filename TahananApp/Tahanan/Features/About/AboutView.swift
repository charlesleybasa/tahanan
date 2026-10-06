import SwiftUI

/// About Homeful: Privacy Policy and Terms tabs (legal copy placeholders from the design).
struct AboutView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State var doc: AboutDoc

    private var content: (title: String, sections: [(String, String)]) {
        // TODO: API — legal copy from the CMS
        switch doc {
        case .privacy:
            return ("Privacy Policy", [
                ("What we collect", "Personal data collected at sign-up and during your application"),
                ("How we use it", "Purposes of processing"),
                ("Your rights", "Rights under the Data Privacy Act of 2012"),
                ("Contact our DPO", "Data Protection Officer contact details"),
            ])
        case .terms:
            return ("Terms and Conditions", [
                ("Using Tahanan", "Account and eligibility terms"),
                ("Bookings and payments", "Reservation, consultation fee and refund terms"),
                ("Limitations", "Liability terms"),
            ])
        }
    }

    var body: some View {
        ScreenScroll(bottom: 60) {
            ScreenHeader(title: "About Homeful") { router.go(.profile, state: state) }

            SegmentedPill(options: ["Privacy Policy", "Terms"], selection: Binding(get: { doc.rawValue }, set: { doc = AboutDoc(rawValue: $0) ?? .privacy }))
                .padding(.top, 20)
                .rise(1)

            VStack(alignment: .leading, spacing: 0) {
                Text(content.title).h1(32).padding(.top, 26).rise(2)
                Text("Last updated [DATE]").font(Typo.manrope(13)).foregroundStyle(Palette.subtle).padding(.top, 8).rise(2)
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(content.sections, id: \.0) { s in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(s.0).font(Typo.manrope(15, .extrabold)).foregroundStyle(Palette.text)
                            Text("[\(s.1) — content from Homeful legal]").font(Typo.manrope(15)).foregroundStyle(Palette.soft).lineSpacing(6)
                        }
                    }
                }
                .padding(.top, 20)
                .rise(3)
            }
            .id(doc)
        }
    }
}

#Preview {
    AboutView(doc: .privacy).environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
