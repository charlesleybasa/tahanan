import SwiftUI

@main
struct TahananApp: App {
    @State private var state = AppState()
    @State private var router = AppRouter(start: Self.startScreen)

    /// Debug builds accept `-start <screen>` (e.g. `-start home`) to open a screen directly for design review.
    private static var startScreen: Screen {
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "start") {
        case "onboarding": return .onboarding
        case "login": return .login
        case "signup": return .signup
        case "welcome": return .welcome
        case "forgot": return .forgotPassword
        case "home": return .home
        case "brand": return .brand(0)
        case "loc": return .location(brand: 0, location: 0)
        case "scan": return .scan
        case "booking": return .booking
        case "payment": return .payment
        case "paid": return .paid
        case "application": return .application
        case "spouse": return .spouse
        case "profile": return .profile
        case "account": return .account
        case "security": return .security
        case "about": return .about(.privacy)
        case "help": return .help
        case "ticket": return .ticket("TK-1042")
        case "newticket": return .newTicket
        case "gallery": return .componentGallery
        default: return .splash
        }
        #else
        return .splash
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(state)
                .environment(router)
                .preferredColorScheme(.dark)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .onOpenURL { router.handle($0, state: state) }
                .task {
                    state.session.onExpired = { [router, state] in router.go(.login, state: state) }
                    await state.refresh()
                }
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            AppBackground()

            screenView(router.screen)
                .id(router.visit)
                .transition(router.tabSwitch ? .fadeIn : router.screen.entersPlain ? .identity : .screen)
                .environment(\.skipEntrance, router.tabSwitch)
                .zIndex(1)

            if let tab = router.screen.tab {
                VStack {
                    Spacer()
                    FloatingTabBar(selected: tab, onSelect: select, onScan: { router.go(.scan, state: state) })
                        .padding(.bottom, 20)
                }
                .ignoresSafeArea(edges: .bottom)
                .zIndex(40)
            }

            if let sheet = state.sheet {
                sheetView(sheet)
                    .zIndex(70)
            }

            if let toast = state.toast {
                VStack {
                    ToastView(toast: toast).id(toast.id).padding(.top, 2)
                    Spacer()
                }
                .zIndex(90)
                .allowsHitTesting(false)
            }
        }
    }

    private func select(_ tab: MainTab) {
        switch tab {
        case .home: router.go(.home, state: state)
        case .application: router.go(.application, state: state)
        case .help: router.go(.help, state: state)
        case .profile: router.go(.profile, state: state)
        }
    }

    @ViewBuilder
    private func screenView(_ screen: Screen) -> some View {
        switch screen {
        case .splash: SplashView()
        case .onboarding: OnboardingView()
        case .login: LoginView()
        case .signup: SignupView()
        case .welcome: WelcomeView()
        case .forgotPassword: ForgotPasswordView()
        case .home: HomeView()
        case let .brand(i): BrandView(brandIndex: i)
        case let .location(b, l): LocationStoryView(brandIndex: b, locationIndex: l)
        case .scan: ScanView()
        case .booking: BookingView()
        case .payment: PaymentView()
        case .paid: PaidView()
        case .application: ApplicationView()
        case .spouse: SpouseFlowView()
        case .profile: ProfileView()
        case .account: AccountView()
        case .security: SecurityView()
        case let .about(doc): AboutView(doc: doc)
        case .help: HelpView()
        case let .ticket(id): TicketChatView(ticketId: id)
        case .newTicket: NewTicketView()
        case .componentGallery: ComponentGallery()
        }
    }

    @ViewBuilder
    private func sheetView(_ sheet: SheetKind) -> some View {
        let close = { state.sheet = nil }
        BottomSheet(onDismiss: close) {
            switch sheet {
            case .link: LinkAccountSheet(onClose: close)
            case .changeEmail: ChangeEmailSheet(onClose: close)
            case .changeMobile: ChangeMobileSheet(onClose: close)
            case let .upload(id): UploadSheet(requirementId: id, onClose: close)
            }
        }
    }
}
