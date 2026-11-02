import '../../core/config/app_config.dart';
import 'enums.dart';
import 'json.dart';

/// The signed-in psychologist's profile.
class Psychologist {
  const Psychologist({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.phone,
    required this.bio,
    required this.qualifications,
    required this.experienceYears,
    this.experienceLabel = '',
    required this.experience,
    required this.specializations,
    required this.languages,
    required this.modes,
    required this.registration,
    required this.documents,
    required this.bank,
    required this.rating,
    required this.reviewCount,
    required this.sessionsCompleted,
    required this.sessionFee,
    this.photoUrl,
    this.sessionMinutes = 0,
    this.ratePerMinute = 0,
    this.modeRates = const <ConsultMode, double>{},
  });

  /// `GET /practitioner/me`
  factory Psychologist.fromJson(Json j) => Psychologist(
    id: j['id'] as String,
    name: j['name'] as String,
    title: j['title'] as String? ?? '',
    email: j['email'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    bio: j['bio'] as String? ?? '',
    photoUrl: AppConfig.resolveMedia(j['photoUrl'] as String?),
    qualifications: jsonList(
      j['qualifications'],
    ).map(Qualification.fromJson).toList(),
    experienceYears: asInt(j['experienceYears']),
    experienceLabel: j['experienceLabel'] as String? ?? '',
    experience: jsonList(
      j['experience'],
    ).map(ExperienceEntry.fromJson).toList(),
    specializations: stringList(j['specializations']),
    languages: stringList(j['languages']),
    modes: stringList(j['modes'])
        .map((String m) => enumByName(ConsultMode.values, m, ConsultMode.chat))
        .toList(),
    registration: Registration.fromJson(jsonMap(j['registration'])),
    documents: jsonList(
      j['documents'],
    ).map(ProfessionalDocument.fromJson).toList(),
    bank: BankDetails.fromJson(jsonMap(j['bank'])),
    rating: (j['rating'] as num? ?? 0).toDouble(),
    reviewCount: asInt(j['reviewCount']),
    sessionsCompleted: asInt(j['sessionsCompleted']),
    sessionFee: asInt(j['sessionFee']),
    sessionMinutes: asInt(j['sessionMinutes']),
    ratePerMinute: asDouble(j['ratePerMinute']),
    modeRates: <ConsultMode, double>{
      if (j['ratesPerMinute'] is Map)
        for (final ConsultMode m in ConsultMode.values)
          if ((j['ratesPerMinute'] as Map<dynamic, dynamic>)[m.name] is num &&
              stringList(j['modes']).contains(m.name))
            m: asDouble((j['ratesPerMinute'] as Map<dynamic, dynamic>)[m.name]),
    },
  );

  final String id;
  final String name;
  final String title;
  final String email;
  final String phone;
  final String bio;
  final String? photoUrl;
  final List<Qualification> qualifications;
  final int experienceYears;
  final String experienceLabel;
  final List<ExperienceEntry> experience;
  final List<String> specializations;
  final List<String> languages;
  final List<ConsultMode> modes;
  final Registration registration;
  final List<ProfessionalDocument> documents;
  final BankDetails bank;
  final double rating;
  final int reviewCount;
  final int sessionsCompleted;

  /// Fee for a standard 50-minute session.
  final int sessionFee;

  /// Length of a standard session, in minutes.
  final int sessionMinutes;

  /// What a minute of session time is billed at, by experience band.
  final double ratePerMinute;

  /// Per-minute rate for each mode the psychologist offers (set by Misty
  /// Minds; defaults to the experience band's rate).
  final Map<ConsultMode, double> modeRates;

  /// The fields `PATCH /practitioner/me` accepts.
  Json toUpdateJson() => <String, dynamic>{
    'name': name,
    'title': title,
    'email': email,
    'phone': phone,
    'bio': bio,
    'specializations': specializations,
    'languages': languages,
  };

  Psychologist copyWith({
    String? name,
    String? title,
    String? email,
    String? phone,
    String? bio,
    List<String>? specializations,
    List<String>? languages,
  }) => Psychologist(
    id: id,
    name: name ?? this.name,
    title: title ?? this.title,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    bio: bio ?? this.bio,
    photoUrl: photoUrl,
    qualifications: qualifications,
    experienceYears: experienceYears,
    experienceLabel: experienceLabel,
    experience: experience,
    specializations: specializations ?? this.specializations,
    languages: languages ?? this.languages,
    modes: modes,
    registration: registration,
    documents: documents,
    bank: bank,
    rating: rating,
    reviewCount: reviewCount,
    sessionsCompleted: sessionsCompleted,
    sessionFee: sessionFee,
    sessionMinutes: sessionMinutes,
    ratePerMinute: ratePerMinute,
    modeRates: modeRates,
  );
}

class Qualification {
  const Qualification({
    required this.degree,
    required this.institution,
    required this.year,
  });

  factory Qualification.fromJson(Json j) => Qualification(
    degree: j['degree'] as String? ?? '',
    institution: j['institution'] as String? ?? '',
    year: asInt(j['year']),
  );

  final String degree;
  final String institution;
  final int year;
}

class ExperienceEntry {
  const ExperienceEntry({
    required this.role,
    required this.organisation,
    required this.period,
  });

  factory ExperienceEntry.fromJson(Json j) => ExperienceEntry(
    role: j['role'] as String? ?? '',
    organisation: j['organisation'] as String? ?? '',
    period: j['period'] as String? ?? '',
  );

  final String role;
  final String organisation;
  final String period;
}

class Registration {
  const Registration({
    required this.council,
    required this.number,
    required this.validTill,
    required this.verified,
  });

  factory Registration.fromJson(Json j) => Registration(
    council: j['council'] as String? ?? '',
    number: j['number'] as String? ?? '',
    validTill: j['validTill'] as String? ?? '',
    verified: j['verified'] as bool? ?? false,
  );

  final String council;
  final String number;
  final String validTill;
  final bool verified;
}

class ProfessionalDocument {
  const ProfessionalDocument({
    required this.name,
    required this.fileName,
    required this.status,
  });

  factory ProfessionalDocument.fromJson(Json j) => ProfessionalDocument(
    name: j['name'] as String? ?? '',
    fileName: j['fileName'] as String?,
    status: enumByName(
      DocumentStatus.values,
      j['status'],
      DocumentStatus.missing,
    ),
  );

  final String name;
  final String? fileName;
  final DocumentStatus status;
}

class BankDetails {
  const BankDetails({
    required this.holder,
    required this.bank,
    required this.accountMasked,
    required this.ifsc,
    required this.upi,
    required this.pan,
  });

  factory BankDetails.fromJson(Json j) => BankDetails(
    holder: j['holder'] as String? ?? '',
    bank: j['bank'] as String? ?? '',
    accountMasked: j['accountMasked'] as String? ?? '',
    ifsc: j['ifsc'] as String? ?? '',
    upi: j['upi'] as String? ?? '',
    pan: j['pan'] as String? ?? '',
  );

  final String holder;
  final String bank;
  final String accountMasked;
  final String ifsc;
  final String upi;
  final String pan;
}
