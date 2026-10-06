import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/models.dart';

// Repository interfaces sit between the UI and data. The demo build ships mock implementations that read
// assets/data/*.json (the same files as the native app); swap in API-backed versions in `Repositories.live`.

abstract interface class ProjectRepository {
  Future<List<Brand>> brands();
}

abstract interface class BuyerRepository {
  Future<BuyerProfile> profile();
  Future<List<Transaction>> transactions();
  Future<List<ApplicationSection>> applicationSections();
  Future<void> linkAccount({required String homefulId, required String otp});
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

class Repositories {
  const Repositories({required this.projects, required this.buyer, required this.requirements, required this.tickets});

  final ProjectRepository projects;
  final BuyerRepository buyer;
  final RequirementsRepository requirements;
  final TicketRepository tickets;

  static const mock = Repositories(
    projects: _MockProjects(),
    buyer: _MockBuyer(),
    requirements: _MockRequirements(),
    tickets: _MockTickets(),
  );

  // TODO: API — return API-backed repositories when USE_MOCK_DATA is false.
  static const live = mock;
}

Future<Object?> _json(String name) async => jsonDecode(await rootBundle.loadString('assets/data/$name.json'));

Future<List<Json>> _jsonList(String name) async => ((await _json(name))! as List<Object?>).cast<Json>();

class _MockProjects implements ProjectRepository {
  const _MockProjects();

  // TODO: API — GET /api/v1/brands
  @override
  Future<List<Brand>> brands() async => (await _jsonList('brands')).map(Brand.fromJson).toList();
}

class _MockBuyer implements BuyerRepository {
  const _MockBuyer();

  // TODO: API — GET /api/v1/me
  @override
  Future<BuyerProfile> profile() async => BuyerProfile.fromJson((await _json('profile'))! as Json);

  // TODO: API — GET /api/v1/me/transactions
  @override
  Future<List<Transaction>> transactions() async =>
      (await _jsonList('transactions')).map(Transaction.fromJson).toList();

  // TODO: API — GET /api/v1/me/application
  @override
  Future<List<ApplicationSection>> applicationSections() async =>
      (await _jsonList('application')).map(ApplicationSection.fromJson).toList();

  // TODO: API — POST /api/v1/me/link-account then /verify
  @override
  Future<void> linkAccount({required String homefulId, required String otp}) async {}
}

class _MockRequirements implements RequirementsRepository {
  const _MockRequirements();

  // TODO: API — GET /api/v1/me/requirements
  @override
  Future<List<Requirement>> requirements() async =>
      (await _jsonList('requirements')).map(Requirement.fromJson).toList();

  // TODO: API — multipart POST /api/v1/me/requirements/{id}/files
  @override
  Future<void> upload({required String requirementId, required List<int>? bytes, required String filename}) async {}
}

class _MockTickets implements TicketRepository {
  const _MockTickets();

  // TODO: API — GET /api/v1/me/tickets and /api/v1/ticket-categories
  @override
  Future<TicketsFile> load() async => TicketsFile.fromJson((await _json('tickets'))! as Json);

  // TODO: API — POST /api/v1/me/tickets/{id}/messages
  @override
  Future<void> send(String text, {required String ticketId}) async {}

  // TODO: API — POST /api/v1/me/tickets
  @override
  Future<void> create({required String category, required String subject, required String message}) async {}
}
