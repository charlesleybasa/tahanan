import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../data/api/api_client.dart';
import '../data/repositories.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/overlays.dart';

enum SheetKind { link, changeEmail, changeMobile, upload, location }

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

  /// The brand whose locations the location sheet lists, and where it was opened from.
  int sheetBrand = 0;
  String sheetOrigin = 'catalog';
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
  static Future<AppState> load({Repositories? repos}) async {
    final s = AppState._(repos ?? Repositories.fromEnvironment());
    await s.refresh();
    return s;
  }

  /// Loads the public catalog and, when signed in, the buyer's data. Never throws: an unreachable server or a
  /// signed-out user leaves the affected lists empty (the screens render their empty states).
  Future<void> refresh() async {
    try {
      brands = await repos.projects.brands();
    } on ApiException catch (e) {
      debugPrint('Catalog not loaded: $e');
    }
    try {
      final r = await Future.wait<Object>([
        repos.requirements.requirements(),
        repos.tickets.load(),
        repos.buyer.profile(),
        repos.buyer.transactions(),
        repos.buyer.applicationSections(),
      ]);
      requirements = r[0] as List<Requirement>;
      final t = r[1] as TicketsFile;
      tickets = t.tickets;
      ticketCategories = t.categories;
      profile = r[2] as BuyerProfile;
      transactions = r[3] as List<Transaction>;
      sections = r[4] as List<ApplicationSection>;
      emailVerification = profile!.emailVerified ? EmailVerification.verified : EmailVerification.idle;
    } on ApiException catch (e) {
      debugPrint('Buyer data not loaded: $e');
    }
    notifyListeners();
  }

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  // Sheets and toast

  void showSheet(SheetKind kind, {String? requirementId, int brand = 0, String origin = 'catalog'}) {
    sheet = kind;
    uploadRequirementId = requirementId;
    sheetBrand = brand;
    sheetOrigin = origin;
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
    unawaited(run((r) => r.tickets.send(text, ticketId: to)));
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
    unawaited(run((r) => r.tickets.create(category: category, subject: subj, message: msg)));
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

  // Backend calls from screens

  /// Runs a repository call fired from the UI. The screens update optimistically (as the design's demo flows do);
  /// a failure surfaces as a toast. Returns whether the call succeeded.
  Future<bool> run(Future<Object?> Function(Repositories r) call) async {
    try {
      await call(repos);
      return true;
    } on ApiException catch (e) {
      showToast(e.message, icon: TIcon.info, tint: Palette.orange);
      return false;
    }
  }

  // Auth (mock repositories accept any email and password)

  /// Signs in and reloads the buyer's data. Throws [ApiException] on bad credentials so the form can show it.
  // TODO: API — refresh the session every 3 h and on foreground (see AuthRepository.refresh).
  Future<void> signIn({required String email, required String password}) async {
    await repos.auth.signIn(email: email, password: password);
    await refresh();
  }

  /// New users are saved as Leads.
  Future<void> signUp({required String name, required String email, required String mobile}) async {
    await repos.auth.signUp(name: name, email: email, mobile: mobile);
    await refresh();
  }

  Future<void> signOut() async {
    await run((r) => r.auth.signOut());
    profile = null;
    requirements = const [];
    tickets = [];
    transactions = const [];
    sections = [];
    notifyListeners();
  }
}
