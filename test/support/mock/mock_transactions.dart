import 'package:mistyminds_practitioner/data/models/enums.dart';
import 'package:mistyminds_practitioner/data/models/transaction.dart';

DateTime _daysAgo(int d, [int hour = 18]) {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day - d, hour);
}

final EarningsSummary mockEarningsSummary = EarningsSummary(
  total: 24600,
  today: 1800,
  thisMonth: 8400,
  pendingPayout: 3200,
  completedSessions: 18,
  nextPayoutDate: DateTime.now().add(const Duration(days: 4)),
);

final List<EarningTransaction> mockTransactions = <EarningTransaction>[
  EarningTransaction(
    id: 'tx_01',
    title: 'Talk Now session',
    subtitle: 'Anonymous Client · 22 min',
    amount: 450,
    type: TransactionType.sessionCredit,
    status: TransactionStatus.pending,
    date: _daysAgo(1, 20),
    mode: ConsultMode.chat,
  ),
  EarningTransaction(
    id: 'tx_02',
    title: 'Video session',
    subtitle: 'Riya · 50 min',
    amount: 1200,
    type: TransactionType.sessionCredit,
    status: TransactionStatus.pending,
    date: _daysAgo(3, 11),
    mode: ConsultMode.video,
  ),
  EarningTransaction(
    id: 'tx_03',
    title: 'Payout to HDFC ••4821',
    subtitle: 'Monthly settlement',
    amount: 5200,
    type: TransactionType.payout,
    status: TransactionStatus.completed,
    date: _daysAgo(4, 10),
  ),
  EarningTransaction(
    id: 'tx_04',
    title: 'Audio session',
    subtitle: 'Karan · 50 min',
    amount: 1200,
    type: TransactionType.sessionCredit,
    status: TransactionStatus.completed,
    date: _daysAgo(6, 18),
    mode: ConsultMode.audio,
  ),
  EarningTransaction(
    id: 'tx_05',
    title: 'Video session',
    subtitle: 'Meera · 50 min',
    amount: 1200,
    type: TransactionType.sessionCredit,
    status: TransactionStatus.completed,
    date: _daysAgo(10, 12),
    mode: ConsultMode.video,
  ),
  EarningTransaction(
    id: 'tx_06',
    title: 'Talk Now session',
    subtitle: 'Anonymous Client · 18 min',
    amount: 400,
    type: TransactionType.sessionCredit,
    status: TransactionStatus.completed,
    date: _daysAgo(12, 21),
    mode: ConsultMode.chat,
  ),
  EarningTransaction(
    id: 'tx_07',
    title: 'Payout to HDFC ••4821',
    subtitle: 'Monthly settlement',
    amount: 6800,
    type: TransactionType.payout,
    status: TransactionStatus.completed,
    date: _daysAgo(11, 10),
  ),
];
