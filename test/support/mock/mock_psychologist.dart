import 'package:mistyminds_practitioner/data/models/enums.dart';
import 'package:mistyminds_practitioner/data/models/psychologist.dart';

/// The demo psychologist shown on the dashboard reference.
const Psychologist mockPsychologist = Psychologist(
  id: 'psy_001',
  name: 'Dr. Ananya Mehta',
  title: 'Clinical Psychologist',
  email: 'ananya.mehta@mistyminds.in',
  phone: '+91 98200 41276',
  bio:
      'I work with adults navigating anxiety, burnout, relationships and '
      'grief. My approach blends CBT with mindfulness — practical, warm and '
      'always at your pace.',
  qualifications: <Qualification>[
    Qualification(
      degree: 'M.Phil. Clinical Psychology',
      institution: 'NIMHANS, Bengaluru',
      year: 2016,
    ),
    Qualification(
      degree: 'M.A. Psychology',
      institution: 'University of Delhi',
      year: 2014,
    ),
    Qualification(
      degree: 'Certified CBT Practitioner',
      institution: 'Beck Institute (online)',
      year: 2019,
    ),
  ],
  experienceYears: 8,
  experience: <ExperienceEntry>[
    ExperienceEntry(
      role: 'Consultant Clinical Psychologist',
      organisation: 'Private practice, Mumbai',
      period: '2020 – Present',
    ),
    ExperienceEntry(
      role: 'Clinical Psychologist',
      organisation: 'Fortis Healthcare, Mumbai',
      period: '2016 – 2020',
    ),
  ],
  specializations: <String>[
    'Anxiety',
    'Stress & Burnout',
    'Relationships',
    'Grief & Loss',
    'Self-esteem',
    'Sleep',
  ],
  languages: <String>['English', 'Hindi', 'Marathi'],
  modes: <ConsultMode>[ConsultMode.chat, ConsultMode.audio, ConsultMode.video],
  registration: Registration(
    council: 'Rehabilitation Council of India (RCI)',
    number: 'A43127',
    validTill: 'March 2029',
    verified: true,
  ),
  documents: <ProfessionalDocument>[
    ProfessionalDocument(
      name: 'RCI Registration Certificate',
      fileName: 'rci_certificate.pdf',
      status: DocumentStatus.verified,
    ),
    ProfessionalDocument(
      name: 'M.Phil. Degree Certificate',
      fileName: 'mphil_degree.pdf',
      status: DocumentStatus.verified,
    ),
    ProfessionalDocument(
      name: 'Government ID (Aadhaar / Passport)',
      fileName: 'passport.pdf',
      status: DocumentStatus.verified,
    ),
    ProfessionalDocument(
      name: 'CBT Certification',
      fileName: 'cbt_certificate.pdf',
      status: DocumentStatus.underReview,
    ),
    ProfessionalDocument(
      name: 'Professional Indemnity Insurance',
      fileName: null,
      status: DocumentStatus.missing,
    ),
  ],
  bank: BankDetails(
    holder: 'Ananya Mehta',
    bank: 'HDFC Bank',
    accountMasked: 'XXXX XXXX 4821',
    ifsc: 'HDFC0000240',
    upi: 'ananya.mehta@okhdfc',
    pan: 'BXXPM4821K',
  ),
  rating: 4.9,
  reviewCount: 214,
  sessionsCompleted: 1240,
  sessionFee: 1200,
);
