import 'enums.dart';
import 'json.dart';

class EarningTransaction {
  const EarningTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
    this.mode,
    this.grossAmount,
    this.platformShare,
    this.doctorGross,
    this.gstRate,
    this.gstAmount,
    this.tdsRate,
    this.tdsAmount,
    this.ratePerMinute,
    this.durationMinutes,
    this.sessionCount,
    this.adjustment,
    this.adjustmentNote,
  });

  /// `GET /practitioner/earnings/transactions`
  factory EarningTransaction.fromJson(Json j) => EarningTransaction(
    id: j['id'] as String,
    title: j['title'] as String,
    subtitle: j['subtitle'] as String? ?? '',
    amount: asDouble(j['amount']),
    type: enumByName(
      TransactionType.values,
      j['type'],
      TransactionType.sessionCredit,
    ),
    status: enumByName(
      TransactionStatus.values,
      j['status'],
      TransactionStatus.pending,
    ),
    date: asDate(j['date']),
    mode: j['mode'] == null
        ? null
        : enumByName(ConsultMode.values, j['mode'], ConsultMode.chat),
    grossAmount: j['grossAmount'] == null ? null : asDouble(j['grossAmount']),
    platformShare: j['platformShare'] == null
      ? null
      : asDouble(j['platformShare']),
    doctorGross: j['doctorGross'] == null ? null : asDouble(j['doctorGross']),
    gstRate: j['gstRate'] == null ? null : asDouble(j['gstRate']),
    gstAmount: j['gstAmount'] == null ? null : asDouble(j['gstAmount']),
    tdsRate: j['tdsRate'] == null ? null : asDouble(j['tdsRate']),
    tdsAmount: j['tdsAmount'] == null ? null : asDouble(j['tdsAmount']),
    ratePerMinute: j['ratePerMinute'] == null
      ? null
      : asDouble(j['ratePerMinute']),
    durationMinutes: (j['durationMinutes'] as num?)?.round(),
    sessionCount: (j['sessionCount'] as num?)?.round(),
    adjustment: j['adjustment'] == null ? null : asDouble(j['adjustment']),
    adjustmentNote: j['adjustmentNote'] as String?,
  );

  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime date;
  final ConsultMode? mode;
  final double? grossAmount;
  final double? platformShare;
  final double? doctorGross;
  final double? gstRate;
  final double? gstAmount;
  final double? tdsRate;
  final double? tdsAmount;
  final double? ratePerMinute;
  final int? durationMinutes;

  /// Payouts: how many sessions it settles, and any bonus (+) / deduction (−).
  final int? sessionCount;
  final double? adjustment;
  final String? adjustmentNote;

  bool get isCredit => type == TransactionType.sessionCredit;
}

/// Headline earnings numbers.
class EarningsSummary {
  const EarningsSummary({
    required this.total,
    required this.today,
    required this.thisMonth,
    required this.pendingPayout,
    required this.completedSessions,
    required this.nextPayoutDate,
    this.payoutDue = false,
    this.experienceYears = 0,
    this.ratePerMinute = 0,
    this.rateBands = const <RateBand>[],
    this.modeRates = const <ConsultMode, double>{},
    this.platformSharePercent = 50,
    this.doctorSharePercent = 50,
    this.gstPercent = 0,
    this.tdsPercent = 0,
    this.thisMonthBreakdown,
    this.lifetimeBreakdown,
  });

  /// `GET /practitioner/earnings/summary`
  factory EarningsSummary.fromJson(Json j) => EarningsSummary(
    total: asDouble(j['total']),
    today: asDouble(j['today']),
    thisMonth: asDouble(j['thisMonth']),
    pendingPayout: asDouble(j['pendingPayout']),
    completedSessions: asInt(j['completedSessions']),
    nextPayoutDate: asDate(j['nextPayoutDate']),
    payoutDue: j['payoutDue'] as bool? ?? false,
    experienceYears: asInt(j['experienceYears']),
    ratePerMinute: asDouble(j['ratePerMinute']),
    rateBands: j['rateBands'] is List
        ? (j['rateBands'] as List<dynamic>)
              .whereType<Map<dynamic, dynamic>>()
              .map((Map<dynamic, dynamic> b) => RateBand.fromJson(jsonMap(b)))
              .toList()
        : const <RateBand>[],
    modeRates: <ConsultMode, double>{
      if (j['ratesPerMinute'] is Map)
        for (final ConsultMode m in ConsultMode.values)
          if ((j['ratesPerMinute'] as Map<dynamic, dynamic>)[m.name] is num &&
              (j['offeredModes'] is! List ||
                  (j['offeredModes'] as List<dynamic>).contains(m.name)))
            m: asDouble((j['ratesPerMinute'] as Map<dynamic, dynamic>)[m.name]),
    },
    platformSharePercent: j['platformSharePercent'] == null
        ? 50
        : asDouble(j['platformSharePercent']),
    doctorSharePercent: j['doctorSharePercent'] == null
        ? 50
        : asDouble(j['doctorSharePercent']),
    gstPercent: asDouble(j['gstPercent']),
    tdsPercent: asDouble(j['tdsPercent']),
    thisMonthBreakdown: j['thisMonthBreakdown'] is Map
        ? EarningsBreakdown.fromJson(jsonMap(j['thisMonthBreakdown']))
        : null,
    lifetimeBreakdown: j['lifetimeBreakdown'] is Map
        ? EarningsBreakdown.fromJson(jsonMap(j['lifetimeBreakdown']))
        : null,
  );

  final double total;
  final double today;
  final double thisMonth;
  final double pendingPayout;
  final int completedSessions;
  final DateTime nextPayoutDate;
  final bool payoutDue;

  /// The psychologist's rate card and how each session is split.
  final int experienceYears;
  final double ratePerMinute;
  final List<RateBand> rateBands;

  /// Per-minute rate for each mode the psychologist offers (set by Misty
  /// Minds; defaults to the experience band's rate).
  final Map<ConsultMode, double> modeRates;
  final double platformSharePercent;
  final double doctorSharePercent;
  final double gstPercent;
  final double tdsPercent;
  final EarningsBreakdown? thisMonthBreakdown;
  final EarningsBreakdown? lifetimeBreakdown;
}

/// One experience band's per-minute rate ("2–5 years · ₹24/min").
class RateBand {
  const RateBand({
    required this.label,
    required this.minYears,
    required this.ratePerMinute,
    this.maxYears,
  });

  factory RateBand.fromJson(Json j) => RateBand(
    label: j['label'] as String? ?? '',
    minYears: asInt(j['minYears']),
    maxYears: (j['maxYears'] as num?)?.round(),
    ratePerMinute: asDouble(j['ratePerMinute']),
  );

  final String label;
  final int minYears;
  final int? maxYears;
  final double ratePerMinute;

  bool covers(int years) =>
      years >= minYears && (maxYears == null || years < maxYears!);
}

/// Totals of each part of the split across a set of sessions.
class EarningsBreakdown {
  const EarningsBreakdown({
    required this.sessions,
    required this.minutes,
    required this.grossAmount,
    required this.platformShare,
    required this.doctorGross,
    required this.gstAmount,
    required this.tdsAmount,
    required this.netAmount,
  });

  factory EarningsBreakdown.fromJson(Json j) => EarningsBreakdown(
    sessions: asInt(j['sessions']),
    minutes: asInt(j['minutes']),
    grossAmount: asDouble(j['grossAmount']),
    platformShare: asDouble(j['platformShare']),
    doctorGross: asDouble(j['doctorGross']),
    gstAmount: asDouble(j['gstAmount']),
    tdsAmount: asDouble(j['tdsAmount']),
    netAmount: asDouble(j['netAmount']),
  );

  final int sessions;
  final int minutes;
  final double grossAmount;
  final double platformShare;
  final double doctorGross;
  final double gstAmount;
  final double tdsAmount;
  final double netAmount;
}
