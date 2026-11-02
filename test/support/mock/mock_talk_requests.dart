import 'package:mistyminds_practitioner/data/models/enums.dart';
import 'package:mistyminds_practitioner/data/models/talk_request.dart';

/// Incoming Talk Now requests, served in rotation so every consultation
/// mode can be demonstrated.
List<TalkRequest> mockTalkRequests() => <TalkRequest>[
  TalkRequest(
    id: 'tr_01',
    message: 'I’d like to talk to someone right now.',
    mode: ConsultMode.chat,
    expectedMinutes: 20,
    anonymous: true,
    clientName: 'Anonymous Client',
    requestedAt: DateTime.now(),
    concern: 'Feeling overwhelmed',
  ),
  TalkRequest(
    id: 'tr_02',
    message: 'Can we talk? I can’t sleep and my mind won’t stop.',
    mode: ConsultMode.audio,
    expectedMinutes: 30,
    anonymous: true,
    clientName: 'Anonymous Client',
    requestedAt: DateTime.now(),
    concern: 'Racing thoughts',
  ),
  TalkRequest(
    id: 'tr_03',
    message: 'I’d really like to see someone and talk it through.',
    mode: ConsultMode.video,
    expectedMinutes: 30,
    anonymous: false,
    clientName: 'Riya Sharma',
    requestedAt: DateTime.now(),
    concern: 'Work stress',
    details: const RequestDetails(
      age: 27,
      gender: 'female',
      city: 'Mumbai',
      language: 'English',
      mood: 'Anxious',
      intent: 'Just talk',
      concerns: <String>['Work stress', 'Sleep'],
      previousSessions: 2,
      fee: 1200,
      sessionMinutes: 50,
    ),
  ),
];

/// Replies the simulated client sends back in a chat consultation.
const List<String> mockClientReplies = <String>[
  'Thank you for being here. It’s been a really heavy week.',
  'I think it’s mostly work… I can’t switch off at night.',
  'Yes, that makes sense. I haven’t really told anyone this.',
  'That helps a little. Can I try that tonight?',
  'Thank you. I feel lighter already.',
];
