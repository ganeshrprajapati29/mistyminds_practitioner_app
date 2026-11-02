import 'package:flutter/material.dart';

import '../../../data/models/enums.dart';

/// All answers gathered across the application steps.
///
/// Held by the flow screen for the life of the application, and turned into
/// the API payload by [toPayload] on submit.
class ApplicationForm {
  static const Set<ConsultMode> compulsoryModes = <ConsultMode>{
    ConsultMode.chat,
    ConsultMode.audio,
    ConsultMode.video,
  };

  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController city = TextEditingController();
  String? gender;

  String title = 'Clinical Psychologist';
  final TextEditingController degree = TextEditingController();
  final TextEditingController institution = TextEditingController();
  final TextEditingController graduationYear = TextEditingController();
  final TextEditingController workplace = TextEditingController();

  final Set<String> specializations = <String>{};
  final Set<String> languages = <String>{'English'};
  final Set<ConsultMode> modes = <ConsultMode>{...compulsoryModes};
  final TextEditingController bio = TextEditingController();

  String council = 'Rehabilitation Council of India (RCI)';
  final TextEditingController registrationNumber = TextEditingController();
  final TextEditingController validTill = TextEditingController();

  /// Ticked on the Registration step by an applicant who has no
  /// registration / licence yet: the number and the licence certificate are
  /// then not asked for, and the verification team follows up.
  bool registrationUnavailable = false;

  /// Document name → the uploaded file's reference on the server (submitted
  /// with the application; the file itself is never public).
  final Map<String, String> documents = <String, String>{};

  /// Document name → the file's original name, for display.
  final Map<String, String> documentNames = <String, String>{};

  final TextEditingController accountHolder = TextEditingController();
  final TextEditingController bankName = TextEditingController();
  final TextEditingController accountNumber = TextEditingController();
  final TextEditingController ifsc = TextEditingController();
  final TextEditingController upi = TextEditingController();
  final TextEditingController pan = TextEditingController();

  bool consent = false;

  static const List<String> titles = <String>[
    'Clinical Psychologist',
    'Counselling Psychologist',
    'Psychotherapist',
    'Counsellor',
  ];
  static const List<String> genders = <String>[
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];
  static const List<String> allSpecializations = <String>[
    'Anxiety',
    'Depression',
    'Stress & Burnout',
    'Relationships',
    'Grief & Loss',
    'Trauma',
    'Self-esteem',
    'OCD',
    'Marital Counselling',
    'Career',
    'LGBTQIA+ affirmative',
    'Adolescents',
  ];
  static const List<String> allLanguages = <String>[
    'English',
    'Bilingual',
    'Hindi',
    'Marathi',
    'Tamil',
    'Telugu',
    'Bengali',
    'Kannada',
    'Gujarati',
  ];
  static const List<String> councils = <String>[
    'Rehabilitation Council of India (RCI)',
    'State Medical Council',
    'Other recognised body',
  ];

  static const String licenceDocument = 'Registration / licence certificate';
  static const String photoDocument = 'Professional photo';

  /// Documents every applicant must upload; the rest are optional.
  static const List<(String, bool)> requiredDocuments = <(String, bool)>[
    ('Highest degree certificate', true),
    (licenceDocument, true),
    ('Government ID (Aadhaar / Passport)', true),
    (photoDocument, true),
    ('Additional certifications', false),
  ];

  /// Whether [name] must be uploaded. The licence certificate is only asked
  /// of applicants who have a registration; the photo is always compulsory.
  bool isRequired(String name, bool required) =>
      required && !(name == licenceDocument && registrationUnavailable);

  bool get hasPhoto => documents.containsKey(photoDocument);

  bool get documentsComplete => requiredDocuments
      .where(((String, bool) d) => isRequired(d.$1, d.$2))
      .every(((String, bool) d) => documents.containsKey(d.$1));

  Map<String, Object?> toPayload() => <String, Object?>{
    'personal': <String, Object?>{
      'name': name.text.trim(),
      'email': email.text.trim(),
      'phone': phone.text.trim(),
      'city': city.text.trim(),
      'gender': gender,
    },
    'professional': <String, Object?>{
      'title': title,
      'degree': degree.text.trim(),
      'institution': institution.text.trim(),
      'graduationYear': graduationYear.text.trim(),
      'experience': '0 years',
      'workplace': workplace.text.trim(),
    },
    'practice': <String, Object?>{
      'specializations': specializations.toList(),
      'languages': languages.toList(),
      'modes': compulsoryModes.map((ConsultMode m) => m.name).toList(),
      'bio': bio.text.trim(),
    },
    'registration': <String, Object?>{
      'council': council,
      'number': registrationUnavailable ? '' : registrationNumber.text.trim(),
      'validTill': registrationUnavailable ? '' : validTill.text.trim(),
    },
    'registrationUnavailable': registrationUnavailable,
    'documents': documents,
    'bank': <String, Object?>{
      'holder': accountHolder.text.trim(),
      'bank': bankName.text.trim(),
      'account': accountNumber.text.trim(),
      'ifsc': ifsc.text.trim(),
      'upi': upi.text.trim(),
      'pan': pan.text.trim(),
    },
  };

  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      name,
      email,
      phone,
      city,
      degree,
      institution,
      graduationYear,
      workplace,
      bio,
      registrationNumber,
      validTill,
      accountHolder,
      bankName,
      accountNumber,
      ifsc,
      upi,
      pan,
    ]) {
      c.dispose();
    }
  }
}
