import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/repositories.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../widgets/overlays.dart';

enum SheetKind { link, changeEmail, changeMobile, upload }

/// App-wide data and UI state shared across screens. Screen-local state lives in each screen.
class AppState extends ChangeNotifier {
  AppState._(this.repos);

  final Repositories repos;

  List<Brand> brands = const [];
  List<Requirement> requirements = const [];
  List<Ticket> tickets = const [];
  List<String> ticketCategories = const [];
  BuyerProfile? profile;
  List<Transaction> transactions = const [];
  List<ApplicationSection> sections = const [];

  SheetKind? sheet;
  String? uploadRequirementId;
  ToastData? toast;
  bool biometricsEnabled = true;

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
    notifyListeners();
  }

  int get todoCount => requirements.where((r) => r.status == RequirementStatus.todo).length;

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
}
