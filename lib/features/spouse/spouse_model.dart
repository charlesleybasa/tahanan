import 'package:flutter/foundation.dart';

enum SpouseScreen { intro, idScan, step, done, invite }

enum ScanState { idle, reading, ok }

typedef IdType = ({String id, String label, String placeholder});
typedef Employment = ({String id, String label, String sub});

/// State and validation for "Complete spouse details" (design/buyer/S00–S08).
class SpouseFlowModel extends ChangeNotifier {
  SpouseFlowModel({this.mine = 22000, this.required = 14000});

  static const steps = ['Personal', 'Address & ID', 'Work & income', 'Review'];
  static const List<IdType> idTypes = [
    (id: 'philsys', label: 'PhilSys ID', placeholder: '0000-0000-0000-0000'),
    (id: 'umid', label: 'UMID', placeholder: '0000-0000000-0'),
    (id: 'passport', label: 'Passport', placeholder: 'P0000000A'),
    (id: 'dl', label: 'Driver’s license', placeholder: 'N00-00-000000'),
    (id: 'prc', label: 'PRC ID', placeholder: '0000000'),
  ];
  static const List<Employment> employment = [
    (id: 'emp', label: 'Employed', sub: 'Private or government'),
    (id: 'self', label: 'Self-employed', sub: 'Business or freelance'),
    (id: 'ofw', label: 'OFW', sub: 'Working abroad'),
    (id: 'none', label: 'Not working', sub: 'No regular income'),
  ];

  /// Buyer's own income and the location's required GMI.
  final int mine, required;

  SpouseScreen screen = SpouseScreen.intro;
  int step = 0;
  ScanState scan = ScanState.idle;
  bool fromId = false;
  bool touched = false;

  // Personal
  String first = '', middle = '', suffix = '', last = '';
  bool noMiddleName = false;
  DateTime? birthdate;
  String sex = 'Male';
  String citizenship = 'Filipino';
  String mobile = '';
  String email = '';

  // Address & ID
  bool sameAddress = true;
  String street = '', barangay = '', city = '', province = '', zip = '';
  String idType = 'philsys';
  String idNumber = '';
  String tin = '';

  // Work & income
  String employmentType = 'emp';
  String employer = '', position = '';
  int years = 4;
  String incomeDigits = '';

  // Review
  bool consent = true;

  // Invite
  String inviteName = '', inviteMobile = '';
  bool inviteSent = false;

  void set(VoidCallback change) {
    change();
    notifyListeners();
  }

  String get mobileDigits => mobile.replaceAll(RegExp(r'\D'), '');

  /// "Enter 10 digits, starting with 9" once the user has typed.
  bool get mobileError => touched && mobileDigits.isNotEmpty && !(mobileDigits.length == 10 && mobileDigits[0] == '9');

  bool isValid(int step) => switch (step) {
    0 => first.isNotEmpty && last.isNotEmpty && birthdate != null && !mobileError && mobileDigits.length == 10,
    1 => idNumber.isNotEmpty,
    2 => employmentType == 'none' || (employer.isNotEmpty && incomeDigits.isNotEmpty),
    _ => consent,
  };

  int get spouseIncome => employmentType == 'none' ? 0 : int.tryParse(incomeDigits) ?? 0;
  int get total => mine + spouseIncome;
  double get scale => [total, (required * 1.2).toInt(), 40000].reduce((a, b) => a > b ? a : b).toDouble();

  IdType get idTypeInfo => idTypes.firstWhere((t) => t.id == idType, orElse: () => idTypes[0]);

  String get employerLabel => switch (employmentType) {
    'self' => 'Business name',
    'ofw' => 'Employer abroad',
    'none' => '',
    _ => 'Employer',
  };

  String get fullName => [first, middle, last, suffix].where((s) => s.isNotEmpty).join(' ');

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String get birthdateText {
    final d = birthdate;
    if (d == null) return '—';
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String grouped(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  static String peso(int n) => '₱${grouped(n)}';

  String get incomeDisplay {
    final n = int.tryParse(incomeDigits);
    return n == null ? '' : grouped(n);
  }

  String get gmiMessage => spouseIncome > 0
      ? 'Combined, you’re at ${(total / required).toStringAsFixed(1)}× the required income — a stronger loan application.'
      : 'Your income already meets the required ${peso(required)}.';

  /// Prototype autofill after reading the ID (name, birthdate and ID number).
  void applyScannedID([String? scanned]) {
    first = 'Jose';
    middle = 'Reyes';
    last = 'Santos';
    birthdate = DateTime(1990, 3, 14);
    idNumber = scanned ?? '1234-5678-9012-2048';
    fromId = true;
  }

  void resetManual() {
    first = middle = suffix = last = mobile = email = idNumber = '';
    birthdate = null;
    fromId = false;
    touched = false;
  }
}
