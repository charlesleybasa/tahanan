import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/models.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';

// Repository interfaces sit between the UI and data. Two implementations ship:
//  • mock — reads the bundled assets/data/*.json (the demo build; also the API contract's sample payloads)
//  • http — calls the versioned REST API (`API_BASE_URL`), see docs/BACKEND_INTEGRATION.md
// `Repositories.fromEnvironment()` picks one from `USE_MOCK_DATA`.

abstract interface class ProjectRepository {
  /// Catalog: brands → locations → products (+ optional gallery media).
  Future<List<Brand>> brands();
}

abstract interface class BuyerRepository {
  Future<BuyerProfile> profile();
  Future<List<Transaction>> transactions();
  Future<List<ApplicationSection>> applicationSections();
  Future<void> linkAccount({required String homefulId, required String otp});
  Future<void> saveSpouse(Map<String, String> fields);
  Future<void> inviteSpouse({required String name, required String mobile});
}

abstract interface class RequirementsRepository {
  Future<List<Requirement>> requirements();
  Future<void> upload({required String requirementId, required List<int>? bytes, required String filename});
}

abstract interface class TicketRepository {
  Future<TicketsFile> load();
  Future<void> send(String text, {required String ticketId});
  Future<void> create({required String category, required String subject, required String message});
}

abstract interface class AuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String name, required String email, required String mobile});

  /// Exchanges the stored refresh token for a new session; false when the user must sign in again.
  Future<bool> refresh();
  Future<void> signOut();
  Future<void> requestPasswordReset(String email);
  Future<void> changePassword({required String current, required String next});
  Future<void> requestEmailChange(String email);
  Future<void> sendEmailVerificationLink();
  Future<void> requestMobileChange(String mobile);
  Future<void> uploadAvatar(List<int> bytes, {required String filename});
}

abstract interface class PaymentRepository {
  /// Creates a payment for the consultation fee and returns the provider checkout URL (or null when the
  /// provider is handled natively).
  Future<String?> createConsultationPayment({required String unitCode, required String method});
}

class Repositories {
  const Repositories({
    required this.projects,
    required this.buyer,
    required this.requirements,
    required this.tickets,
    required this.auth,
    required this.payments,
  });

  factory Repositories.http(ApiClient api) {
    final auth = _HttpAuth(api);
    api.onRefresh = auth.refresh;
    return Repositories(
      projects: _HttpProjects(api),
      buyer: _HttpBuyer(api),
      requirements: _HttpRequirements(api),
      tickets: _HttpTickets(api),
      auth: auth,
      payments: _HttpPayments(api),
    );
  }

  factory Repositories.fromEnvironment() {
    final config = ApiConfig.fromEnvironment();
    return config.useMockData ? mock : Repositories.http(ApiClient(config));
  }

  final ProjectRepository projects;
  final BuyerRepository buyer;
  final RequirementsRepository requirements;
  final TicketRepository tickets;
  final AuthRepository auth;
  final PaymentRepository payments;

  static const mock = Repositories(
    projects: _MockProjects(),
    buyer: _MockBuyer(),
    requirements: _MockRequirements(),
    tickets: _MockTickets(),
    auth: _MockAuth(),
    payments: _MockPayments(),
  );
}

// MARK: Mock (bundled JSON)

Future<Object?> _json(String name) async => jsonDecode(await rootBundle.loadString('assets/data/$name.json'));

Future<List<Json>> _jsonList(String name) async => ((await _json(name))! as List<Object?>).cast<Json>();

class _MockProjects implements ProjectRepository {
  const _MockProjects();

  @override
  Future<List<Brand>> brands() async => (await _jsonList('brands')).map(Brand.fromJson).toList();
}

class _MockBuyer implements BuyerRepository {
  const _MockBuyer();

  @override
  Future<BuyerProfile> profile() async => BuyerProfile.fromJson((await _json('profile'))! as Json);

  @override
  Future<List<Transaction>> transactions() async =>
      (await _jsonList('transactions')).map(Transaction.fromJson).toList();

  @override
  Future<List<ApplicationSection>> applicationSections() async =>
      (await _jsonList('application')).map(ApplicationSection.fromJson).toList();

  @override
  Future<void> linkAccount({required String homefulId, required String otp}) async {}

  @override
  Future<void> saveSpouse(Map<String, String> fields) async {}

  @override
  Future<void> inviteSpouse({required String name, required String mobile}) async {}
}

class _MockRequirements implements RequirementsRepository {
  const _MockRequirements();

  @override
  Future<List<Requirement>> requirements() async =>
      (await _jsonList('requirements')).map(Requirement.fromJson).toList();

  @override
  Future<void> upload({required String requirementId, required List<int>? bytes, required String filename}) async {}
}

class _MockTickets implements TicketRepository {
  const _MockTickets();

  @override
  Future<TicketsFile> load() async => TicketsFile.fromJson((await _json('tickets'))! as Json);

  @override
  Future<void> send(String text, {required String ticketId}) async {}

  @override
  Future<void> create({required String category, required String subject, required String message}) async {}
}

/// Demo auth: any email and password are accepted.
class _MockAuth implements AuthRepository {
  const _MockAuth();

  @override
  Future<void> signIn({required String email, required String password}) async {}
  @override
  Future<void> signUp({required String name, required String email, required String mobile}) async {}
  @override
  Future<bool> refresh() async => true;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> requestPasswordReset(String email) async {}
  @override
  Future<void> changePassword({required String current, required String next}) async {}
  @override
  Future<void> requestEmailChange(String email) async {}
  @override
  Future<void> sendEmailVerificationLink() async {}
  @override
  Future<void> requestMobileChange(String mobile) async {}
  @override
  Future<void> uploadAvatar(List<int> bytes, {required String filename}) async {}
}

class _MockPayments implements PaymentRepository {
  const _MockPayments();

  @override
  Future<String?> createConsultationPayment({required String unitCode, required String method}) async => null;
}

// MARK: HTTP (REST API v1 — contract in docs/BACKEND_INTEGRATION.md)

List<Json> _asList(Object? body) => (body! as List<Object?>).cast<Json>();

class _HttpProjects implements ProjectRepository {
  const _HttpProjects(this.api);

  final ApiClient api;

  @override
  Future<List<Brand>> brands() async => _asList(await api.get('/brands')).map(Brand.fromJson).toList();
}

class _HttpBuyer implements BuyerRepository {
  const _HttpBuyer(this.api);

  final ApiClient api;

  @override
  Future<BuyerProfile> profile() async => BuyerProfile.fromJson((await api.get('/me'))! as Json);

  @override
  Future<List<Transaction>> transactions() async =>
      _asList(await api.get('/me/transactions')).map(Transaction.fromJson).toList();

  @override
  Future<List<ApplicationSection>> applicationSections() async =>
      _asList(await api.get('/me/application')).map(ApplicationSection.fromJson).toList();

  @override
  Future<void> linkAccount({required String homefulId, required String otp}) async {
    await api.post('/me/link-account', body: {'homefulId': homefulId});
    await api.post('/me/link-account/verify', body: {'homefulId': homefulId, 'otp': otp});
  }

  @override
  Future<void> saveSpouse(Map<String, String> fields) => api.put('/me/application/spouse', body: fields);

  @override
  Future<void> inviteSpouse({required String name, required String mobile}) =>
      api.post('/me/application/spouse/invite', body: {'name': name, 'mobile': mobile});
}

class _HttpRequirements implements RequirementsRepository {
  const _HttpRequirements(this.api);

  final ApiClient api;

  @override
  Future<List<Requirement>> requirements() async =>
      _asList(await api.get('/me/requirements')).map(Requirement.fromJson).toList();

  @override
  Future<void> upload({required String requirementId, required List<int>? bytes, required String filename}) async {
    if (bytes == null) return;
    await api.upload('/me/requirements/$requirementId/files', field: 'file', bytes: bytes, filename: filename);
  }
}

class _HttpTickets implements TicketRepository {
  const _HttpTickets(this.api);

  final ApiClient api;

  @override
  Future<TicketsFile> load() async {
    final r = await Future.wait([api.get('/me/tickets'), api.get('/ticket-categories')]);
    return TicketsFile.fromJson({'tickets': r[0], 'categories': r[1]});
  }

  @override
  Future<void> send(String text, {required String ticketId}) =>
      api.post('/me/tickets/$ticketId/messages', body: {'text': text});

  @override
  Future<void> create({required String category, required String subject, required String message}) =>
      api.post('/me/tickets', body: {'category': category, 'subject': subject, 'message': message});
}

class _HttpAuth implements AuthRepository {
  const _HttpAuth(this.api);

  final ApiClient api;

  Future<void> _session(Object? body) async {
    final j = body! as Json;
    await api.tokens.save(accessToken: j['accessToken']! as String, refreshToken: j['refreshToken'] as String?);
  }

  @override
  Future<void> signIn({required String email, required String password}) async =>
      _session(await api.post('/auth/sign-in', body: {'email': email, 'password': password}));

  @override
  Future<void> signUp({required String name, required String email, required String mobile}) async =>
      _session(await api.post('/auth/sign-up', body: {'name': name, 'email': email, 'mobile': mobile}));

  @override
  Future<bool> refresh() async {
    final token = api.tokens.refreshToken;
    if (token == null) return false;
    try {
      await _session(await api.post('/auth/refresh', body: {'refreshToken': token}));
      return true;
    } on ApiException catch (e) {
      if (e.unauthorized) await api.tokens.clear();
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await api.post('/auth/sign-out');
    } finally {
      await api.tokens.clear();
    }
  }

  @override
  Future<void> requestPasswordReset(String email) => api.post('/auth/password-reset', body: {'email': email});

  @override
  Future<void> changePassword({required String current, required String next}) =>
      api.post('/me/password', body: {'currentPassword': current, 'newPassword': next});

  @override
  Future<void> requestEmailChange(String email) => api.post('/me/email', body: {'email': email});

  @override
  Future<void> sendEmailVerificationLink() => api.post('/me/email/verification-link');

  @override
  Future<void> requestMobileChange(String mobile) => api.post('/me/mobile', body: {'mobile': mobile});

  @override
  Future<void> uploadAvatar(List<int> bytes, {required String filename}) async {
    await api.upload('/me/avatar', field: 'file', bytes: bytes, filename: filename);
  }
}

class _HttpPayments implements PaymentRepository {
  const _HttpPayments(this.api);

  final ApiClient api;

  @override
  Future<String?> createConsultationPayment({required String unitCode, required String method}) async {
    final j = (await api.post('/me/payments/consultation', body: {'unitCode': unitCode, 'method': method}))! as Json;
    return j['checkoutUrl'] as String?;
  }
}
