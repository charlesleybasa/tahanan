import 'package:flutter/foundation.dart';

/// How a field is entered.
enum FieldKind { text, select, date, phone, email, number, mono }

/// One input from the official Customer Information Form.
@immutable
class FieldSpec {
  const FieldSpec(
    this.id,
    this.label, {
    this.kind = FieldKind.text,
    this.required = false,
    this.options = const [],
    this.placeholder,
    this.mono = false,
  });

  final String id, label;
  final FieldKind kind;
  final bool required, mono;
  final List<String> options;
  final String? placeholder;

  String get hint =>
      placeholder ?? (kind == FieldKind.select ? 'Select from the options' : 'Enter ${label.toLowerCase()}');
}

/// A titled run of fields inside a step ("Present address", "Government IDs").
@immutable
class FieldGroup {
  const FieldGroup(this.title, this.fields, {this.sameAsKey});

  final String title;
  final List<FieldSpec> fields;

  /// When set, the group can mirror another group ("Same as present address").
  final String? sameAsKey;
}

/// One of the form's four data steps (step 5 is the document requirements).
@immutable
class FormStep {
  const FormStep(this.id, this.title, this.subtitle, this.groups);

  final String id, title, subtitle;
  final List<FieldGroup> groups;

  Iterable<FieldSpec> get fields => groups.expand((g) => g.fields);
}

// Option lists (the form's drop-downs).
const _suffix = ['None', 'Jr.', 'Sr.', 'II', 'III', 'IV'];
const _civil = ['Single', 'Married', 'Widowed', 'Separated', 'Divorced'];
const _gender = ['Male', 'Female'];
const _nationality = ['Filipino', 'Other'];
const _country = ['Philippines'];
const _ownership = ['Owned', 'Rented', 'Living with relatives', 'Mortgaged'];
const _relationship = ['Spouse', 'Parent', 'Child', 'Sibling', 'Relative', 'Other'];
const _employmentType = ['Locally employed', 'OFW', 'Self-employed', 'Business owner'];
const _employmentStatus = ['Regular', 'Contractual', 'Probationary', 'Part-time'];
const _tenure = ['Less than 1 year', '1–2 years', '3–5 years', '6–10 years', 'Over 10 years'];
const _industry = [
  'Banking & finance',
  'BPO / IT',
  'Construction',
  'Education',
  'Government',
  'Healthcare',
  'Manufacturing',
  'Retail & services',
  'Other',
];

// TODO: API — Region / Province / City / Barangay should cascade from the PSGC reference data.
List<FieldSpec> _address(String p) => [
  FieldSpec('$p.ownership', 'Ownership', kind: FieldKind.select, required: true, options: _ownership),
  FieldSpec('$p.country', 'Country', kind: FieldKind.select, required: true, options: _country),
  FieldSpec('$p.region', 'Region', required: true),
  FieldSpec('$p.province', 'Province', required: true),
  FieldSpec('$p.city', 'City', required: true),
  FieldSpec('$p.barangay', 'Barangay', required: true),
  FieldSpec('$p.street', 'Unit no., house/bldg/street name', required: true, placeholder: 'Enter address'),
  FieldSpec('$p.zip', 'Zip code', kind: FieldKind.number, required: true, placeholder: 'Enter zip code'),
  FieldSpec('$p.full', 'Full address', required: true, placeholder: 'Enter full address'),
];

List<FieldSpec> _person(String p, {bool relationship = false}) => [
  if (relationship)
    FieldSpec(
      '$p.relationship',
      'Relationship to buyer',
      kind: FieldKind.select,
      required: true,
      options: _relationship,
    ),
  FieldSpec('$p.first', 'First name', required: true),
  FieldSpec('$p.middle', 'Middle name'),
  FieldSpec('$p.last', 'Last name', required: true),
  FieldSpec('$p.suffix', 'Suffix', kind: FieldKind.select, options: _suffix),
  FieldSpec('$p.maiden', 'Mother’s maiden name', placeholder: 'Enter mother’s maiden name'),
  FieldSpec('$p.civil', 'Civil status', kind: FieldKind.select, options: _civil),
  FieldSpec('$p.gender', 'Gender', kind: FieldKind.select, options: _gender),
  FieldSpec('$p.nationality', 'Nationality', kind: FieldKind.select, options: _nationality),
  FieldSpec('$p.dob', 'Date of birth', kind: FieldKind.date),
];

List<FieldSpec> _contact(String p) => [
  FieldSpec('$p.email', 'Primary email address', kind: FieldKind.email, placeholder: 'Enter primary email address'),
  FieldSpec('$p.mobile', 'Mobile number', kind: FieldKind.phone, placeholder: '09XX XXX XXXX'),
  FieldSpec('$p.mobile2', 'Other mobile', kind: FieldKind.phone, placeholder: 'Enter other mobile'),
];

/// The Customer Information Form, in the order of the official PDF.
final List<FormStep> formSteps = [
  FormStep('personal', 'Personal', 'Name, contact and civil details', [
    FieldGroup('Personal details', _person('buyer')),
    FieldGroup('Contact', [
      ..._contact('buyer').map((f) => f.id == 'buyer.email' || f.id == 'buyer.mobile' ? _req(f) : f),
      const FieldSpec('buyer.landline', 'Landline', kind: FieldKind.phone, placeholder: 'Enter landline'),
      const FieldSpec('buyer.help', 'HELP certificate', placeholder: 'Certificate number, if any'),
    ]),
  ]),
  FormStep('address', 'Address', 'Present and permanent address', [
    FieldGroup('Present address', _address('present')),
    FieldGroup('Permanent address', _address('permanent'), sameAsKey: 'present'),
  ]),
  FormStep('employment', 'Employment', 'Primary employment and employer', [
    const FieldGroup('Primary employment', [
      FieldSpec('job.type', 'Employment type', kind: FieldKind.select, required: true, options: _employmentType),
      FieldSpec('job.status', 'Employment status', kind: FieldKind.select, required: true, options: _employmentStatus),
      FieldSpec('job.tenure', 'Tenure', kind: FieldKind.select, options: _tenure),
      FieldSpec('job.rank', 'Rank', placeholder: 'Enter rank'),
      FieldSpec('job.industry', 'Industry', kind: FieldKind.select, required: true, options: _industry),
      FieldSpec('job.income', 'Gross monthly income', kind: FieldKind.number, required: true, placeholder: '0'),
    ]),
    const FieldGroup('Government IDs', [
      FieldSpec('job.tin', 'TIN', kind: FieldKind.mono, placeholder: '000 000 000 000'),
      FieldSpec('job.pagibig', 'Pag-IBIG number', kind: FieldKind.mono, placeholder: '0000 0000 0000'),
      FieldSpec('job.sss', 'SSS / GSIS number', kind: FieldKind.mono, placeholder: '00 0000000 0'),
    ]),
    const FieldGroup('Employer / business', [
      FieldSpec('emp.name', 'Employer / business name', required: true, placeholder: 'Enter employer name'),
      FieldSpec('emp.email', 'Email', kind: FieldKind.email, required: true, placeholder: 'Enter employer email'),
      FieldSpec('emp.contact', 'Contact no.', kind: FieldKind.phone, required: true, placeholder: '09XX XXX XXXX'),
      FieldSpec('emp.year', 'Year established', kind: FieldKind.number, required: true, placeholder: 'YYYY'),
    ]),
    FieldGroup('Employer address', _address('emp')),
  ]),
  FormStep('coborrower', 'Co-borrower', 'Up to two co-borrowers', [
    FieldGroup('Co-borrower 1', [..._person('cob1', relationship: true), ..._contact('cob1')]),
    FieldGroup('Co-borrower 2', [..._person('cob2', relationship: true), ..._contact('cob2')]),
  ]),
];

FieldSpec _req(FieldSpec f) => FieldSpec(
  f.id,
  f.label,
  kind: f.kind,
  required: true,
  options: f.options,
  placeholder: f.placeholder,
  mono: f.mono,
);

/// The buyer's answers to the form. Seeded from the account, edited in the Edit application flow.
class ApplicationForm extends ChangeNotifier {
  ApplicationForm({Map<String, String>? seed}) : values = {..._defaults, ...?seed};

  static const _defaults = {
    'present.country': 'Philippines',
    'permanent.country': 'Philippines',
    'emp.country': 'Philippines',
    'buyer.nationality': 'Filipino',
  };

  final Map<String, String> values;

  /// "Same as present address" for the permanent address.
  bool samePermanent = false;

  /// Whether the second co-borrower has been started.
  bool secondCoBorrower = false;

  String get(String id) {
    if (samePermanent && id.startsWith('permanent.')) return values['present.${id.substring(10)}'] ?? '';
    return values[id] ?? '';
  }

  void set(String id, String value) {
    values[id] = value;
    notifyListeners();
  }

  void setSamePermanent(bool v) {
    samePermanent = v;
    notifyListeners();
  }

  void setSecondCoBorrower(bool v) {
    secondCoBorrower = v;
    notifyListeners();
  }

  bool _counts(FormStep s, FieldGroup g) => !(s.id == 'coborrower' && g.title == 'Co-borrower 2' && !secondCoBorrower);

  Iterable<FieldSpec> requiredFields(FormStep s) =>
      s.groups.where((g) => _counts(s, g)).expand((g) => g.fields).where((f) => f.required);

  int missing(FormStep s) => requiredFields(s).where((f) => get(f.id).trim().isEmpty).length;

  int total(FormStep s) => requiredFields(s).length;

  /// 0–100 for the progress ring.
  int percent(FormStep s) {
    final t = total(s);
    return t == 0 ? 100 : (((t - missing(s)) / t) * 100).round();
  }

  /// Overall completion across the four data steps.
  int get overallPercent {
    var all = 0, left = 0;
    for (final s in formSteps) {
      all += total(s);
      left += missing(s);
    }
    return all == 0 ? 100 : (((all - left) / all) * 100).round();
  }

  /// Index of the first step that still has required fields empty, or -1 when everything is filled.
  int get firstIncomplete => formSteps.indexWhere((s) => missing(s) > 0);

  /// "Jan 1, 1990" for a stored `YYYY-MM-DD`.
  static String prettyDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  /// What the review cards show for [f].
  String display(FieldSpec f) {
    final v = get(f.id).trim();
    if (v.isEmpty) return '';
    return switch (f.kind) {
      FieldKind.date => prettyDate(v),
      FieldKind.number when f.id == 'job.income' => '₱$v',
      _ => v,
    };
  }
}
