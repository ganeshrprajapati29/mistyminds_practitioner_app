import 'package:mistyminds_practitioner/data/models/client.dart';
import 'package:mistyminds_practitioner/data/models/enums.dart';

DateTime _daysAgo(int d) => DateTime.now().subtract(Duration(days: d));

final List<Client> mockClients = <Client>[
  Client(
    id: 'cl_01',
    name: 'Riya',
    anonymous: false,
    sessionCount: 6,
    lastSession: _daysAgo(3),
    firstSession: _daysAgo(62),
    preferredMode: ConsultMode.video,
    concerns: <String>['Anxiety', 'Work stress'],
    ageRange: '25–30',
    privateNote:
        'Responding well to grounding exercises. Revisit sleep routine next '
        'session.',
  ),
  Client(
    id: 'cl_02',
    name: 'Anonymous Client',
    anonymous: true,
    sessionCount: 2,
    lastSession: _daysAgo(1),
    firstSession: _daysAgo(9),
    preferredMode: ConsultMode.chat,
    concerns: <String>['Loneliness'],
  ),
  Client(
    id: 'cl_03',
    name: 'Karan',
    anonymous: false,
    sessionCount: 11,
    lastSession: _daysAgo(6),
    firstSession: _daysAgo(140),
    preferredMode: ConsultMode.audio,
    concerns: <String>['Relationships', 'Anger'],
    ageRange: '30–35',
    privateNote: 'Couples work paused; continuing individual sessions.',
  ),
  Client(
    id: 'cl_04',
    name: 'Meera',
    anonymous: false,
    sessionCount: 4,
    lastSession: _daysAgo(10),
    firstSession: _daysAgo(45),
    preferredMode: ConsultMode.video,
    concerns: <String>['Grief & Loss'],
    ageRange: '40–45',
  ),
  Client(
    id: 'cl_05',
    name: 'Anonymous Client',
    anonymous: true,
    sessionCount: 1,
    lastSession: _daysAgo(14),
    firstSession: _daysAgo(14),
    preferredMode: ConsultMode.chat,
    concerns: <String>['Exam stress'],
  ),
  Client(
    id: 'cl_06',
    name: 'Arjun',
    anonymous: false,
    sessionCount: 8,
    lastSession: _daysAgo(20),
    firstSession: _daysAgo(110),
    preferredMode: ConsultMode.audio,
    concerns: <String>['Burnout', 'Sleep'],
    ageRange: '28–32',
  ),
];
