typedef Json = Map<String, Object?>;

List<Json> _list(Object? v) => (v as List<Object?>).cast<Json>();

// MARK: Project knowledge

class Location {
  const Location({
    required this.name,
    required this.barangay,
    required this.tcp,
    required this.floorArea,
    required this.lotArea,
    required this.monthlyAmortization,
    required this.gmi,
  });

  factory Location.fromJson(Json j) => Location(
    name: j['name']! as String,
    barangay: j['barangay']! as String,
    tcp: j['tcp']! as String,
    floorArea: j['floorArea']! as String,
    lotArea: j['lotArea']! as String,
    monthlyAmortization: j['monthlyAmortization']! as String,
    gmi: j['gmi']! as String,
  );

  final String name, barangay, tcp, floorArea, lotArea, monthlyAmortization, gmi;
}

class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.image,
    required this.from,
    required this.gmi,
    required this.monthly,
    required this.product,
    required this.description,
    required this.locations,
  });

  factory Brand.fromJson(Json j) => Brand(
    id: j['id']! as String,
    name: j['name']! as String,
    image: j['image']! as String,
    from: j['from']! as String,
    gmi: j['gmi']! as String,
    monthly: j['monthly']! as String,
    product: j['product']! as String,
    description: j['description']! as String,
    locations: _list(j['locations']).map(Location.fromJson).toList(),
  );

  final String id, name, image, from, gmi, monthly, product, description;
  final List<Location> locations;

  /// Home carousel pill: "5 locations" or the single location's name.
  String get carouselLocationLabel => locations.length > 1 ? '${locations.length} locations' : locations[0].name;

  /// Brand hero: "5 locations" or "Brgy. Dolores, Magalang, Pampanga".
  String get heroLocationLabel =>
      locations.length > 1 ? '${locations.length} locations' : '${locations[0].barangay}, ${locations[0].name}';

  /// Pasinaya Homes has its own row shot; the others reuse the facade.
  String get streetImage => id == 'ph' ? 'photoRow' : image;
}

// MARK: Requirements

enum RequirementStatus {
  accepted('acc', 'Accepted', 3),
  reviewed('rev', 'Reviewed', 2),
  submitted('sub', 'Submitted', 1),
  todo('todo', 'To upload', 0);

  const RequirementStatus(this.raw, this.label, this.step);

  final String raw, label;

  /// How many of the three status steps are lit.
  final int step;

  static RequirementStatus parse(String raw) => values.firstWhere((s) => s.raw == raw);
}

class Requirement {
  Requirement({required this.id, required this.name, required this.owner, required this.status, this.date});

  factory Requirement.fromJson(Json j) => Requirement(
    id: j['id']! as String,
    name: j['name']! as String,
    owner: j['owner']! as String,
    status: RequirementStatus.parse(j['status']! as String),
    date: j['date'] as String?,
  );

  final String id, name, owner;
  RequirementStatus status;
  String? date;
}

// MARK: Tickets

enum TicketStatus {
  open('Open'),
  progress('In progress'),
  resolved('Resolved');

  const TicketStatus(this.label);

  final String label;
}

enum MessageKind { sys, me, them }

class TicketMessage {
  TicketMessage({required this.kind, required this.text, this.who, this.time, this.attachment = false});

  factory TicketMessage.fromJson(Json j) => TicketMessage(
    kind: MessageKind.values.byName(j['kind']! as String),
    text: j['text']! as String,
    who: j['who'] as String?,
    time: j['time'] as String?,
    attachment: j['attachment'] as bool? ?? false,
  );

  final MessageKind kind;
  final String text;
  final String? who, time;
  final bool attachment;
}

class Ticket {
  Ticket({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.time,
    required this.messages,
  });

  factory Ticket.fromJson(Json j) => Ticket(
    id: j['id']! as String,
    subject: j['subject']! as String,
    category: j['category']! as String,
    status: TicketStatus.values.byName(j['status']! as String),
    time: j['time']! as String,
    messages: _list(j['messages']).map(TicketMessage.fromJson).toList(),
  );

  final String id;
  String subject, category, time;
  TicketStatus status;
  final List<TicketMessage> messages;

  String get lastMessage => messages.lastWhere((m) => m.kind != MessageKind.sys, orElse: () => messages.first).text;
}

class TicketsFile {
  const TicketsFile(this.categories, this.tickets);

  factory TicketsFile.fromJson(Json j) => TicketsFile(
    (j['categories']! as List<Object?>).cast<String>(),
    _list(j['tickets']).map(Ticket.fromJson).toList(),
  );

  final List<String> categories;
  final List<Ticket> tickets;
}

// MARK: Buyer

class Seller {
  const Seller(this.name, this.initials);

  factory Seller.fromJson(Json j) => Seller(j['name']! as String, j['initials']! as String);

  final String name, initials;
}

class Unit {
  const Unit({
    required this.code,
    required this.brandId,
    required this.brandName,
    required this.location,
    required this.barangay,
    required this.block,
    required this.product,
    required this.floorArea,
    required this.lotArea,
    required this.tcp,
    required this.monthly,
    required this.term,
    required this.consultationFee,
    required this.seller,
    required this.referenceNo,
  });

  factory Unit.fromJson(Json j) => Unit(
    code: j['code']! as String,
    brandId: j['brandId']! as String,
    brandName: j['brandName']! as String,
    location: j['location']! as String,
    barangay: j['barangay']! as String,
    block: j['block']! as String,
    product: j['product']! as String,
    floorArea: j['floorArea']! as String,
    lotArea: j['lotArea']! as String,
    tcp: j['tcp']! as String,
    monthly: j['monthly']! as String,
    term: j['term']! as String,
    consultationFee: j['consultationFee']! as String,
    seller: Seller.fromJson(j['seller']! as Json),
    referenceNo: j['referenceNo']! as String,
  );

  final String code, brandId, brandName, location, barangay, block, product;
  final String floorArea, lotArea, tcp, monthly, term, consultationFee, referenceNo;
  final Seller seller;
}

class BuyerProfile {
  const BuyerProfile({
    required this.firstName,
    required this.fullName,
    required this.initials,
    required this.homefulId,
    required this.email,
    required this.emailMasked,
    required this.mobileMasked,
    required this.emailVerified,
    required this.mobileVerified,
    required this.role,
    required this.unit,
    required this.address,
    required this.grossMonthlyIncome,
    required this.requiredIncome,
  });

  factory BuyerProfile.fromJson(Json j) => BuyerProfile(
    firstName: j['firstName']! as String,
    fullName: j['fullName']! as String,
    initials: j['initials']! as String,
    homefulId: j['homefulId']! as String,
    email: j['email']! as String,
    emailMasked: j['emailMasked']! as String,
    mobileMasked: j['mobileMasked']! as String,
    emailVerified: j['emailVerified']! as bool,
    mobileVerified: j['mobileVerified']! as bool,
    role: j['role']! as String,
    unit: Unit.fromJson(j['unit']! as Json),
    address: j['address']! as String,
    grossMonthlyIncome: j['grossMonthlyIncome']! as int,
    requiredIncome: j['requiredIncome']! as int,
  );

  final String firstName, fullName, initials, homefulId, email, emailMasked, mobileMasked, role, address;
  final bool emailVerified, mobileVerified;
  final Unit unit;
  final int grossMonthlyIncome, requiredIncome;
}

enum TxTone { acc, sub, mut }

enum TxKind { wallet, home, calendar }

class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.mono,
    required this.amount,
    required this.status,
    required this.tone,
    required this.icon,
  });

  factory Transaction.fromJson(Json j) => Transaction(
    id: j['id']! as String,
    title: j['title']! as String,
    subtitle: j['subtitle']! as String,
    mono: j['mono']! as bool,
    amount: j['amount'] as String?,
    status: j['status']! as String,
    tone: TxTone.values.byName(j['tone']! as String),
    icon: TxKind.values.byName(j['icon']! as String),
  );

  final String id, title, subtitle, status;
  final bool mono;
  final String? amount;
  final TxTone tone;
  final TxKind icon;
}

class SectionField {
  const SectionField(this.key, this.value);

  factory SectionField.fromJson(Json j) => SectionField(j['key']! as String, j['value']! as String);

  final String key, value;
}

class ApplicationSection {
  const ApplicationSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.percent,
    required this.cta,
    required this.fields,
  });

  factory ApplicationSection.fromJson(Json j) => ApplicationSection(
    id: j['id']! as String,
    title: j['title']! as String,
    subtitle: j['subtitle']! as String,
    percent: j['percent']! as int,
    cta: j['cta']! as String,
    fields: _list(j['fields']).map(SectionField.fromJson).toList(),
  );

  final String id, title, subtitle, cta;
  final int percent;
  final List<SectionField> fields;
}
