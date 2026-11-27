import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/audio/request_sounds.dart';
import 'providers.dart';

/// Texts, links and policy pages the admin console can change without an app
/// update (GET /content/practitioner). Every screen passes its own built-in text as
/// the fallback, so the app looks exactly as shipped until the admin edits
/// something — and keeps working offline from the last copy it saw.

class ContentLink {
  const ContentLink({required this.title, required this.subtitle, required this.url});
  final String title;
  final String subtitle;
  final String url;
}

class ContentSection {
  const ContentSection({
    required this.heading,
    required this.body,
    this.linkLabel = '',
    this.linkUrl = '',
  });

  factory ContentSection.fromJson(Map<String, dynamic> j) => ContentSection(
    heading: (j['heading'] as String?) ?? '',
    body: (j['body'] as String?) ?? '',
    linkLabel: (j['linkLabel'] as String?) ?? '',
    linkUrl: (j['linkUrl'] as String?) ?? '',
  );

  final String heading;
  final String body;
  final String linkLabel;
  final String linkUrl;

  bool get hasLink => isWebLink(linkUrl);
}

class ContentDocument {
  const ContentDocument({
    required this.title,
    required this.subtitle,
    required this.heading,
    required this.intro,
    required this.footer,
    required this.sections,
  });

  factory ContentDocument.fromJson(Map<String, dynamic> j) => ContentDocument(
    title: (j['title'] as String?) ?? '',
    subtitle: (j['subtitle'] as String?) ?? '',
    heading: (j['heading'] as String?) ?? '',
    intro: (j['intro'] as String?) ?? '',
    footer: (j['footer'] as String?) ?? '',
    sections: ((j['sections'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ContentSection.fromJson)
        .toList(),
  );

  final String title;
  final String subtitle;
  final String heading;
  final String intro;
  final String footer;
  final List<ContentSection> sections;
}

bool isWebLink(String? url) =>
    url != null && RegExp(r'^https?://\S+$', caseSensitive: false).hasMatch(url.trim());

/// Opens [url] in the browser / YouTube app. Returns false if it couldn't.
Future<bool> openContentLink(String url) async {
  final Uri? uri = Uri.tryParse(url.trim());
  if (uri == null || !isWebLink(url)) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

class AppContent {
  const AppContent(this._pages);
  static const AppContent empty = AppContent(<String, dynamic>{});

  final Map<String, dynamic> _pages;

  Map<String, dynamic>? _fields(String page) {
    final dynamic p = _pages[page];
    if (p is Map<String, dynamic> && p['fields'] is Map<String, dynamic>) {
      return p['fields'] as Map<String, dynamic>;
    }
    return null;
  }

  /// The admin's text for [key], or [fallback] if unset or blank.
  String text(String page, String key, String fallback) {
    final dynamic v = _fields(page)?[key];
    return v is String && v.trim().isNotEmpty ? v : fallback;
  }

  /// Like [text], but a blank value from the admin means "hide this" ('').
  String optional(String page, String key, String fallback) {
    final Map<String, dynamic>? f = _fields(page);
    if (f == null || !f.containsKey(key)) return fallback;
    final dynamic v = f[key];
    return v is String ? v.trim() : fallback;
  }

  /// A link the admin attached to [key], if any (else null → normal action).
  String? link(String page, String key, {String? fallback}) {
    final Map<String, dynamic>? f = _fields(page);
    if (f == null) return isWebLink(fallback) ? fallback : null;
    final dynamic v = f[key];
    if (v is String && isWebLink(v)) return v.trim();
    if (f.containsKey(key)) return null;
    return isWebLink(fallback) ? fallback : null;
  }

  List<ContentLink> links(String page) {
    final dynamic p = _pages[page];
    if (p is! Map<String, dynamic> || p['links'] is! List<dynamic>) {
      return const <ContentLink>[];
    }
    return (p['links'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((Map<String, dynamic> l) => isWebLink(l['url'] as String?))
        .map(
          (Map<String, dynamic> l) => ContentLink(
            title: (l['title'] as String?) ?? '',
            subtitle: (l['subtitle'] as String?) ?? '',
            url: (l['url'] as String).trim(),
          ),
        )
        .toList();
  }

  /// The admin's version of a policy/FAQ page, or null to use the built-in one.
  ContentDocument? document(String page) {
    final dynamic p = _pages[page];
    if (p is Map<String, dynamic> && p['document'] is Map<String, dynamic>) {
      final ContentDocument doc = ContentDocument.fromJson(
        p['document'] as Map<String, dynamic>,
      );
      return doc.sections.isEmpty && doc.intro.isEmpty ? null : doc;
    }
    return null;
  }
}

class AppContentController extends Notifier<AppContent> {
  static const String _app = 'practitioner';
  static const String _cacheKey = 'app_content_v1_$_app';

  @override
  AppContent build() {
    unawaited(_load());
    return AppContent.empty;
  }

  Future<void> _load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cached = prefs.getString(_cacheKey);
      if (cached != null && state == AppContent.empty) {
        final dynamic decoded = jsonDecode(cached);
        if (decoded is Map<String, dynamic>) {
          state = AppContent(decoded);
          _applyRingtones();
        }
      }
    } catch (_) {
      // A bad cache just means we wait for the network.
    }
    await refresh();
  }

  /// Hands the admin's ringtones (App content → Ringtones) to the ringer.
  void _applyRingtones() {
    RequestSounds.customRingtones = <String, String>{
      for (final String mode in <String>['audio', 'video', 'chat'])
        if (state.link('ringtones', 'ring.$mode') != null)
          mode: state.link('ringtones', 'ring.$mode')!,
    };
  }

  /// Fetches the latest content (called on start and on pull-to-refresh).
  Future<void> refresh() async {
    try {
      final Map<String, dynamic> data = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/content/$_app');
      final dynamic pages = data['pages'];
      if (pages is Map<String, dynamic>) {
        state = AppContent(pages);
        _applyRingtones();
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(pages));
      }
    } catch (_) {
      // Offline or older server — keep what we have.
    }
  }
}

final NotifierProvider<AppContentController, AppContent> appContentProvider =
    NotifierProvider<AppContentController, AppContent>(
      AppContentController.new,
    );
