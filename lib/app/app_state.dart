import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../data/repositories.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/overlays.dart';

enum SheetKind { link, changeEmail, changeMobile, upload }

enum ApplicationTab { info, requirements }

/// Email verification card states on Account details (prototype `ev` 0–3).
enum EmailVerification { idle, enterCode, openingLink, verified }

/// App-wide data and UI state shared across screens. Screen-local state lives in each screen.
class AppState extends ChangeNotifier {
  AppState._(this.repos);

  final Repositories repos;

  List<Brand> brands = const [];
  List<Requirement> requirements = const [];
  List<Ticket> tickets = [];
  List<String> ticketCategories = const [];
  BuyerProfile? profile;
  List<Transaction> transactions = const [];
  List<ApplicationSection> sections = [];

  SheetKind? sheet;
  String? uploadRequirementId;
  ToastData? toast;
  ApplicationTab applicationTab = ApplicationTab.info;
  bool biometricsEnabled = true;
  EmailVerification emailVerification = EmailVerification.idle;

  /// Set by the tahanan://auth/reset deep link so Forgot password opens on the new-password step.
  int forgotStartStep = 0;
  Uint8List? avatar;

  /// "Typing…" indicator for the support agent, per ticket.
  final Set<String> agentTyping = {};

  /// Loads the bundled data before the first frame, so screens never render empty (as on iOS).
  static Future<AppState> load({Repositories repos = Repositories.live}) async {
    final s = AppState._(repos);
    await s.refresh();
    return s;
  }

  Future<void> refresh() async {
    final r = await Future.wait<Object>([
      repos.projects.brands(),
      repos.requirements.requirements(),
      repos.tickets.load(),
      repos.buyer.profile(),
      repos.buyer.transactions(),
      repos.buyer.applicationSections(),
    ]);
    brands = r[0] as List<Brand>;
    requirements = r[1] as List<Requirement>;
    final t = r[2] as TicketsFile;
    tickets = t.tickets;
    ticketCategories = t.categories;
    profile = r[3] as BuyerProfile;
    transactions = r[4] as List<Transaction>;
    sections = r[5] as List<ApplicationSection>;
    emailVerification = profile!.emailVerified ? EmailVerification.verified : EmailVerification.idle;
    notifyListeners();
  }

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  // Sheets and toast

  void showSheet(SheetKind kind, {String? requirementId}) {
    sheet = kind;
    uploadRequirementId = requirementId;
    notifyListeners();
  }

  void closeSheet() {
    if (sheet == null) return;
    sheet = null;
    notifyListeners();
  }

  void showToast(String message, {TIcon icon = TIcon.check, Color tint = Palette.green}) {
    toast = ToastData(message, icon: icon, tint: tint);
    notifyListeners();
  }

  void clearToast() {
    toast = null;
    notifyListeners();
  }

  // Requirements

  int get todoCount => requirements.where((r) => r.status == RequirementStatus.todo).length;

  Requirement? requirement(String? id) => requirements.where((r) => r.id == id).firstOrNull;

  void markSubmitted(String id) {
    final r = requirement(id);
    if (r == null) return;
    r
      ..status = RequirementStatus.submitted
      ..date = 'Today';
    requirements = [...requirements];
    notifyListeners();
  }

  // Tickets

  static const _agent = 'Homeful Support · Carla';

  Ticket? ticket(String? id) => tickets.where((t) => t.id == id).firstOrNull;

  void send(String text, {required String to}) {
    final t = ticket(to);
    if (t == null) return;
    t.messages.add(TicketMessage(kind: MessageKind.me, text: text, time: 'Now'));
    agentTyping.add(to);
    notifyListeners();
    unawaited(repos.tickets.send(text, ticketId: to));
    // Demo: the agent replies after 1.8 s, as in the prototype.
    Timer(const Duration(milliseconds: 1800), () {
      agentTyping.remove(to);
      ticket(to)?.messages.add(
        TicketMessage(
          kind: MessageKind.them,
          text: 'Thanks, Maria! I’ve noted that on your ticket. We’ll update you here as soon as it’s reviewed.',
          who: _agent,
          time: 'Now',
        ),
      );
      notifyListeners();
    });
  }

  /// Creates a ticket and returns its id (TK-1052, TK-1053, …).
  String createTicket({required String category, required String subject, required String message}) {
    final id = 'TK-${1052 + tickets.length - 3}';
    final subj = subject.trim().isEmpty ? 'Question about my ${category.toLowerCase()}' : subject.trim();
    final msg = message.trim().isEmpty ? 'Hi! I need help with my ${category.toLowerCase()}.' : message.trim();
    tickets.insert(
      0,
      Ticket(
        id: id,
        subject: subj,
        category: category,
        status: TicketStatus.open,
        time: 'Now',
        messages: [
          TicketMessage(kind: MessageKind.sys, text: 'Ticket opened · Today'),
          TicketMessage(kind: MessageKind.me, text: msg, time: 'Now'),
        ],
      ),
    );
    agentTyping.add(id);
    notifyListeners();
    unawaited(repos.tickets.create(category: category, subject: subj, message: msg));
    Timer(const Duration(milliseconds: 2200), () {
      agentTyping.remove(id);
      ticket(id)?.messages.add(
        TicketMessage(
          kind: MessageKind.them,
          text: 'Hi Maria! Thanks for reaching out — I’m looking into this now.',
          who: _agent,
          time: 'Now',
        ),
      );
      notifyListeners();
    });
    return id;
  }

  // Auth (demo: any email and password are accepted, as in the native mock)

  // TODO: API — Supabase sign-in, session refresh every 3 h and on foreground, Keychain/Keystore storage.
  Future<void> signIn({required String email, required String password}) async {}

  Future<void> signOut() async {}
}
