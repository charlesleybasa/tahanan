typedef Json = Map<String, Object?>;

List<Json> _list(Object? v) => (v as List<Object?>).cast<Json>();

// MARK: Catalog (Figma "02 · Home & Discover": brand → location → product)

/// "₱750,000" / "₱4,919.50": whole pesos drop the centavos, as in the source spreadsheet.
String peso(num n) {
  final whole = n.truncate();
  final cents = ((n - whole) * 100).round();
  final digits = whole.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return cents == 0 ? '₱$digits' : '₱$digits.${cents.toString().padLeft(2, '0')}';
}

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// A gallery photo or video uploaded in the CMS. [url] and [poster] are absolute URLs.
class MediaRef {
  const MediaRef({required this.category, required this.caption, required this.type, required this.url, this.poster});

  factory MediaRef.fromJson(Json j) => MediaRef(
    category: j['category']! as String,
    caption: (j['caption'] as String?) ?? '',
    type: j['type']! as String,
    url: j['url']! as String,
    poster: j['poster'] as String?,
  );

  /// "Project video", "Facade", "Floor plan", … (the Figma gallery categories).
  final String category, caption;

  /// `photo` or `video`.
  final String type;
  final String url;
  final String? poster;
}

List<MediaRef> _media(Object? v) => v == null ? const [] : _list(v).map(MediaRef.fromJson).toList();

class Financing {
  const Financing({
    required this.monthly,
    required this.note,
    required this.gmi,
    required this.program,
    required this.term,
  });

  factory Financing.fromJson(Json j) => Financing(
    monthly: j['monthly']! as num,
    note: j['note']! as String,
    gmi: j['gmi']! as num,
    program: j['program']! as String,
    term: j['term']! as String,
  );

  final num monthly, gmi;
  final String note, program, term;
}

/// "Consultation & PF" or "Consultation & down payment".
class FeeBlock {
  const FeeBlock({required this.title, required this.rows, required this.note, this.highlight});

  factory FeeBlock.fromJson(Json j) => FeeBlock(
    title: j['title']! as String,
    rows: [for (final r in (j['rows']! as List<Object?>).cast<List<Object?>>()) (r[0]! as String, r[1]! as String)],
    note: j['note']! as String,
    highlight: switch (j['highlight']) {
      final List<Object?> h => (h[0]! as String, h[1]! as String),
      _ => null,
    },
  );

  final String title, note;
  final List<(String, String)> rows;
  final (String, String)? highlight;
}

class Product {
  const Product({
    required this.name,
    required this.tcp,
    this.code,
    this.floor,
    this.lot,
    this.floors = 1,
    this.financing,
    this.fees,
    this.media = const [],
  });

  factory Product.fromJson(Json j) => Product(
    name: j['name']! as String,
    tcp: j['tcp']! as num,
    code: j['code'] as String?,
    floor: j['floor'] as String?,
    lot: j['lot'] as String?,
    floors: (j['floors'] as int?) ?? 1,
    financing: switch (j['financing']) {
      final Json f => Financing.fromJson(f),
      _ => null,
    },
    fees: switch (j['fees']) {
      final Json f => FeeBlock.fromJson(f),
      _ => null,
    },
    media: _media(j['media']),
  );

  final String name;
  final num tcp;

  /// Source spreadsheet product name ("1BR.i"); shown only when it differs from [name].
  final String? code;
  final String? floor, lot;

  /// Storeys, for the sample floor plan.
  final int floors;
  final Financing? financing;
  final FeeBlock? fees;

  /// Product gallery; empty until uploaded (the app then shows labelled samples).
  final List<MediaRef> media;

  String? get sourceCode => code != null && code != name ? code : null;
}

class Location {
  const Location({
    required this.name,
    required this.from,
    this.area,
    this.products,
    this.productCount,
    this.media = const [],
  });

  factory Location.fromJson(Json j) => Location(
    name: j['name']! as String,
    from: j['from']! as num,
    area: j['area'] as String?,
    products: j['products'] == null ? null : _list(j['products']).map(Product.fromJson).toList(),
    productCount: j['productCount'] as int?,
    media: _media(j['media']),
  );

  final String name;
  final num from;
  final String? area;

  /// Null when the spreadsheet lists the count but not the products.
  final List<Product>? products;
  final int? productCount;

  int get count => products?.length ?? productCount ?? 0;

  /// Project gallery; empty until uploaded (the app then shows labelled samples).
  final List<MediaRef> media;
}

enum HomeGroup { rowhouse, duplex, condo, cluster }

class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.type,
    required this.group,
    required this.from,
    required this.projects,
    required this.image,
    this.shots = const [],
    this.locations,
  });

  factory Brand.fromJson(Json j) => Brand(
    id: j['id']! as String,
    name: j['name']! as String,
    type: j['type']! as String,
    group: HomeGroup.values.byName((j['group']! as String).toLowerCase()),
    from: j['from']! as num,
    projects: j['projects']! as int,
    image: j['image']! as String,
    shots: ((j['shots'] as List<Object?>?) ?? const []).cast<String>(),
    locations: j['locations'] == null ? null : _list(j['locations']).map(Location.fromJson).toList(),
  );

  final String id, name, type;
  final HomeGroup group;
  final num from;
  final int projects;

  /// Website artwork (an artist's rendering).
  final String image;

  /// Extra exterior photos for the sample gallery.
  final List<String> shots;

  /// Null until the spreadsheet names this brand's locations.
  final List<Location>? locations;

  int get locationCount => locations?.length ?? projects;

  /// Home carousel pill: "4 locations".
  String get locationLabel => plural(locationCount, 'location');
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
