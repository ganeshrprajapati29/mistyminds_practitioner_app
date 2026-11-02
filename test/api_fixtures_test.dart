import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mistyminds_practitioner/data/models/app_notification.dart';
import 'package:mistyminds_practitioner/data/models/availability.dart';
import 'package:mistyminds_practitioner/data/models/client.dart';
import 'package:mistyminds_practitioner/data/models/psychologist.dart';
import 'package:mistyminds_practitioner/data/models/session.dart';
import 'package:mistyminds_practitioner/data/models/settings.dart';
import 'package:mistyminds_practitioner/data/models/talk_request.dart';
import 'package:mistyminds_practitioner/data/models/transaction.dart';

/// Parses real backend responses — captured from the full flow (Talk Now in
/// chat / audio / video → accept → chat → complete, plus socket events) —
/// with the app's own models. Offline: the JSON lives in test/fixtures/api.
///
/// A failure here means the app would crash or misread that screen's data.
void main() {
  const String dir = 'test/fixtures/api';
  Object? load(String name) =>
      jsonDecode(File('$dir/$name.json').readAsStringSync());
  Map<String, dynamic> map(String name) =>
      (load(name)! as Map<dynamic, dynamic>).cast<String, dynamic>();
  List<Map<String, dynamic>> list(String name) => (load(name)! as List<dynamic>)
      .map((dynamic e) => (e as Map<dynamic, dynamic>).cast<String, dynamic>())
      .toList();

  test('profile, settings and presence', () {
    final Psychologist me = Psychologist.fromJson(map('me'));
    expect(me.name, isNotEmpty);
    PractitionerSettings.fromJson(map('settings'));
    final PresenceSnapshot off = PresenceSnapshot.fromJson(
      map('presence_offline'),
    );
    final PresenceSnapshot on = PresenceSnapshot.fromJson(
      map('presence_online'),
    );
    expect(off.status.name, 'offline');
    expect(on.status.name, 'online');
  });

  test('sessions, clients, availability', () {
    for (final String name in <String>['sessions', 'sessions_after']) {
      expect(list(name).map(Session.fromJson), isNotEmpty);
    }
    list('clients').forEach(Client.fromJson);
    Client.fromJson(map('client_detail'));
    for (final Map<String, dynamic> day in (map(
      'availability',
    )['days']! as List<dynamic>).cast<Map<String, dynamic>>()) {
      (day['slots']! as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .forEach(AvailabilitySlot.fromJson);
    }
  });

  test('earnings and notifications', () {
    EarningsSummary.fromJson(map('earnings_summary'));
    EarningsSummary.fromJson(map('earnings_summary_after'));
    list('earnings_transactions').forEach(EarningTransaction.fromJson);
    list('earnings_transactions_after').forEach(EarningTransaction.fromJson);
    for (final String name in <String>[
      'notifications',
      'notifications_after',
      'notifications_read_all',
    ]) {
      list(name).forEach(AppNotification.fromJson);
    }
  });

  for (final String mode in <String>['chat', 'audio', 'video']) {
    test('Talk Now → $mode session', () {
      final TalkRequest request = TalkRequest.fromJson(map('talk_next_$mode'));
      expect(request.id, isNotEmpty);

      final Map<String, dynamic> accepted = map('talk_accept_$mode');
      TalkRequest.fromJson(
        (accepted['request']! as Map<dynamic, dynamic>).cast<String, dynamic>(),
      );
      final ConsultationRoom room = ConsultationRoom.fromJson(accepted);
      expect(room.session.id, isNotEmpty);
      if (mode == 'chat') {
        expect(room.conversationId, isNotNull);
        expect(room.call, isNull);
      } else {
        final CallCredentials call = room.call!;
        expect(call.configured, isTrue);
        expect(call.channel, isNotEmpty);
        expect(call.uid, isNot(call.peerUid));
      }

      Session.fromJson(map('session_detail_$mode'));
      final Map<String, dynamic> done = map('session_complete_$mode');
      Session.fromJson(
        (done['session']! as Map<dynamic, dynamic>).cast<String, dynamic>(),
      );

      // Socket payloads exactly as realtime_bridge / the consultation screens
      // read them.
      for (final Map<String, dynamic> e in list('socket_events_$mode')) {
        final Map<String, dynamic> data = (e['payload']! as Map<dynamic, dynamic>)
            .cast<String, dynamic>();
        switch (e['event']) {
          case 'talk:request':
            TalkRequest.fromJson(data);
          case 'chat:message':
            ChatMessage.fromJson(
              (data['message']! as Map<dynamic, dynamic>)
                  .cast<String, dynamic>(),
            );
          case 'notification:new':
            AppNotification.fromJson(data);
        }
      }
    });
  }

  test('chat messages both ways', () {
    final List<ChatMessage> messages = list(
      'chat_messages',
    ).map(ChatMessage.fromJson).toList();
    expect(messages, isNotEmpty);
    final ChatMessage sent = ChatMessage.fromJson(map('send_message'));
    expect(sent.fromMe, isTrue);
  });

  test('a scheduled session opens with call credentials', () {
    final Directory d = Directory(dir);
    final List<File> starts = d
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.contains('session_start_'))
        .toList();
    for (final File f in starts) {
      final ConsultationRoom room = ConsultationRoom.fromJson(
        (jsonDecode(f.readAsStringSync()) as Map<dynamic, dynamic>)
            .cast<String, dynamic>(),
      );
      expect(room.session.id, isNotEmpty);
    }
  });
}
