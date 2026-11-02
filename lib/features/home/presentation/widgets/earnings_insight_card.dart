import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../data/models/session.dart';
import '../../../../data/models/transaction.dart';

/// What the dashboard chart plots for each of the last seven days.
enum _ChartMetric { earnings, hours }

class EarningsInsightCard extends StatefulWidget {
  const EarningsInsightCard({
    super.key,
    required this.summary,
    required this.transactions,
    required this.todaysSessions,
    required this.loading,
    required this.onTap,
  });

  final EarningsSummary? summary;
  final List<EarningTransaction> transactions;
  final List<Session> todaysSessions;
  final bool loading;
  final VoidCallback onTap;

  @override
  State<EarningsInsightCard> createState() => _EarningsInsightCardState();
}

class _EarningsInsightCardState extends State<EarningsInsightCard> {
  _ChartMetric _metric = _ChartMetric.earnings;

  /// "1h 20m", "45m", "0m".
  static String _hours(int minutes) {
    if (minutes <= 0) return '0m';
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  /// Short label drawn above a bar: "₹1.2k" / "1.5h" / "40m".
  static String _barLabel(_DayEarning p, _ChartMetric metric) {
    if (metric == _ChartMetric.hours) {
      if (p.minutes <= 0) return '';
      if (p.minutes < 60) return '${p.minutes}m';
      final double h = p.minutes / 60;
      return '${h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1)}h';
    }
    if (p.amount <= 0) return '';
    if (p.amount >= 1000) {
      final double k = p.amount / 1000;
      return '₹${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
    }
    return '₹${p.amount.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final EarningsSummary? s = widget.summary;
    final bool loading = widget.loading;
    final VoidCallback onTap = widget.onTap;
    final List<_DayEarning> points = _lastSevenDays(s, widget.transactions);
    final _DayEarning today = points.last;
    final double weekTotal = points.fold<double>(
      0,
      (double total, _DayEarning point) => total + point.amount,
    );
    final int weekMinutes = points.fold<int>(
      0,
      (int total, _DayEarning point) => total + point.minutes,
    );
    final bool showHours = _metric == _ChartMetric.hours;
    final bool empty = showHours ? weekMinutes == 0 : weekTotal == 0;

    return MistyCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.lg,
        AppSizes.lg,
        AppSizes.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Earnings Overview',
                      style: AppTypography.body(17, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loading
                          ? 'Syncing live dashboard'
                          : 'Daily earnings & hours · last 7 days',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              _PillButton(label: 'Details', onTap: onTap),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: <Widget>[
              _MetricTile(
                label: 'Today’s Earning',
                value: s == null ? '-' : Fmt.money(s.today),
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.sm),
              _MetricTile(
                label: 'Today’s Hours',
                value: loading ? '-' : _hours(today.minutes),
                color: AppColors.mintInk,
              ),
              const SizedBox(width: AppSizes.sm),
              _MetricTile(
                label: 'Current Earnings',
                value: s == null ? '-' : Fmt.money(s.thisMonth),
                color: AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: <Widget>[
              _MetricChip(
                label: 'Daily earning',
                selected: !showHours,
                onTap: () => setState(() => _metric = _ChartMetric.earnings),
              ),
              const SizedBox(width: AppSizes.sm),
              _MetricChip(
                label: 'Daily hours',
                selected: showHours,
                onTap: () => setState(() => _metric = _ChartMetric.hours),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: _EarningsChart(
                    points: points,
                    values: <double>[
                      for (final _DayEarning p in points)
                        showHours ? p.minutes.toDouble() : p.amount,
                    ],
                    labels: <String>[
                      for (final _DayEarning p in points)
                        _barLabel(p, _metric),
                    ],
                    color: showHours ? AppColors.mintInk : AppColors.primary,
                  ),
                ),
                if (loading)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (empty)
                  Center(
                    child: Text(
                      showHours
                          ? 'No session hours logged this week yet'
                          : 'No earnings logged this week yet',
                      style: AppTypography.body(
                        13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: _FooterStat(
                  label: '7-day earnings',
                  value: loading ? '-' : Fmt.money(weekTotal),
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              Expanded(
                child: _FooterStat(
                  label: '7-day hours',
                  value: loading ? '-' : _hours(weekMinutes),
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              Expanded(
                child: _FooterStat(
                  label: 'Sessions today',
                  value: '${widget.todaysSessions.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_DayEarning> _lastSevenDays(
    EarningsSummary? summary,
    List<EarningTransaction> txs,
  ) {
    final DateTime today = Fmt.dateOnly(DateTime.now());
    final List<DateTime> days = <DateTime>[
      for (int i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final Map<DateTime, double> totals = <DateTime, double>{
      for (final DateTime day in days) day: 0,
    };
    final Map<DateTime, int> minutes = <DateTime, int>{
      for (final DateTime day in days) day: 0,
    };

    for (final EarningTransaction tx in txs) {
      if (!tx.isCredit) continue;
      final DateTime date = Fmt.dateOnly(tx.date);
      if (!totals.containsKey(date)) continue;
      totals[date] = totals[date]! + tx.amount;
      minutes[date] = minutes[date]! + (tx.durationMinutes ?? 0);
    }
    if (summary != null && totals[today] == 0 && summary.today > 0) {
      totals[today] = summary.today;
    }

    return <_DayEarning>[
      for (final DateTime day in days)
        _DayEarning(day, totals[day] ?? 0, minutes[day] ?? 0),
    ];
  }
}

/// The "Daily earning / Daily hours" switch above the chart.
class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.lavender,
      borderRadius: AppSizes.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm - 1,
          ),
          child: Text(
            label,
            style: AppTypography.body(
              12.5,
              weight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.primaryStrong,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.sm + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: AppSizes.brMd,
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: AppTypography.body(
                  15.5,
                  weight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  const _FooterStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: AppTypography.body(16, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body(11.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lavender,
      borderRadius: AppSizes.brPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: AppTypography.body(
                  13,
                  weight: FontWeight.w700,
                  color: AppColors.primaryStrong,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.primaryStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningsChart extends StatelessWidget {
  const _EarningsChart({
    required this.points,
    required this.values,
    required this.labels,
    required this.color,
  });

  final List<_DayEarning> points;

  /// One value per day (rupees or minutes) and its short label.
  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: CustomPaint(
            painter: _EarningsChartPainter(values, labels, color),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: <Widget>[
            for (final _DayEarning point in points)
              Expanded(
                child: Text(
                  _weekday(point.day),
                  textAlign: TextAlign.center,
                  style: AppTypography.body(10.5, color: AppColors.textTertiary),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _weekday(DateTime day) {
    const List<String> labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[day.weekday - 1];
  }
}

/// One rounded bar per day, each with its value written above it.
class _EarningsChartPainter extends CustomPainter {
  const _EarningsChartPainter(this.values, this.labels, this.color);

  final List<double> values;
  final List<String> labels;
  final Color color;

  static const double _labelSpace = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final double y = _labelSpace + (size.height - _labelSpace) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      grid,
    );
    if (values.isEmpty) return;

    final double maxValue = values.fold<double>(
      0,
      (double max, double v) => v > max ? v : max,
    );
    final double scaleMax = maxValue <= 0 ? 1 : maxValue;
    final double slot = size.width / values.length;
    final double barWidth = (slot * 0.56).clamp(14.0, 34.0).toDouble();
    final double usable = size.height - _labelSpace;

    for (int i = 0; i < values.length; i++) {
      final double center = slot * i + slot / 2;
      final bool last = i == values.length - 1;
      final bool none = values[i] <= 0;
      final double height = none
          ? 3
          : (values[i] / scaleMax * usable).clamp(6.0, usable).toDouble();
      final Rect rect = Rect.fromLTWH(
        center - barWidth / 2,
        size.height - height,
        barWidth,
        height,
      );
      final Paint bar = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: none ? 0.18 : (last ? 1 : 0.7)),
            color.withValues(alpha: none ? 0.12 : (last ? 0.75 : 0.35)),
          ],
        ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
        ),
        bar,
      );

      if (labels[i].isEmpty) continue;
      final TextPainter text = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: AppTypography.body(
            10,
            weight: FontWeight.w700,
            color: last ? color : AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: slot + 8);
      text.paint(
        canvas,
        Offset(center - text.width / 2, rect.top - text.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EarningsChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.labels != labels ||
      oldDelegate.color != color;
}

class _DayEarning {
  const _DayEarning(this.day, [this.amount = 0, this.minutes = 0]);

  final DateTime day;
  final double amount;

  /// Session minutes worked that day.
  final int minutes;
}
