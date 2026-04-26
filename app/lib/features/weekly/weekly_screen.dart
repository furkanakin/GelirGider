import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_widgets.dart';

class WeeklyScreen extends ConsumerWidget {
  const WeeklyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider(const ReportQuery(scope: 'weekly')));

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final periodLabel = '${DateFormat('d', 'tr_TR').format(monday)} — ${DateFormat('d MMMM', 'tr_TR').format(sunday)}'.toUpperCase();

    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: report.when(
          data: (r) => _Body(report: r, periodLabel: periodLabel),
          loading: () => const Center(child: CircularProgressIndicator(color: T.terracotta)),
          error: (e, _) => Center(child: Text('Hata: $e', style: TLText.body(color: T.alert))),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Report report;
  final String periodLabel;
  const _Body({required this.report, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    final dailyByDay = <int, double>{};
    for (final p in report.daily) {
      dailyByDay[p.date.weekday] = p.expense.toDouble();
    }
    final maxAmount = dailyByDay.values.fold<double>(0, (a, b) => a > b ? a : b).clamp(1, double.infinity).toDouble();

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      children: [
        ScreenHeader(
          subtitle: periodLabel,
          title: Text.rich(TextSpan(children: [
            TextSpan(text: 'Bu', style: TLText.display(28, italic: FontStyle.italic)),
            const TextSpan(text: ' hafta'),
          ]), style: TLText.display(28)),
          right: const RoundIconBtn(icon: 'calendar'),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          child: Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Bu hafta '),
              TextSpan(text: '${formatTL(report.totalExpense)} ₺', style: TLText.display(22, color: T.terracotta, italic: FontStyle.italic)),
              const TextSpan(text: ' harcadınız.\nGelir: '),
              TextSpan(text: '${formatTL(report.totalIncome)} ₺', style: TLText.display(22, color: T.forest)),
            ]),
            style: TLText.display(22, color: T.inkSoft),
          ),
        ),

        // Bar chart
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: EviCard(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxAmount * 1.2,
                  barGroups: List.generate(7, (i) {
                    final day = i + 1;
                    final v = dailyByDay[day] ?? 0;
                    final isMax = v == maxAmount && v > 0;
                    return BarChartGroupData(
                      x: day,
                      barRods: [
                        BarChartRodData(
                          toY: v,
                          width: 18,
                          color: isMax ? T.terracotta : T.terraSoft,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.zero),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          const labels = {1: 'P', 2: 'S', 3: 'Ç', 4: 'P', 5: 'C', 6: 'C', 7: 'P'};
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labels[v.toInt()] ?? '', style: TLText.body(color: T.inkMute, size: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        ),

        // Top categories
        const SectionHeader(label: 'Hafta yıldızları'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: report.byCategory.where((c) => c.kind == 'expense').take(3).map((agg) {
              final pct = report.totalExpense == 0 ? 0.0 : agg.total / report.totalExpense.toDouble();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: EviCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: (agg.color ?? T.terracotta).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(agg.categoryLabel ?? agg.categorySlug ?? '—',
                                      style: TLText.body(weight: FontWeight.w500)),
                                ),
                                Text('${formatTL(agg.total.toDouble())} ₺', style: TLText.num(size: 14, weight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: pct.clamp(0, 1),
                                backgroundColor: T.lineSoft,
                                color: agg.color ?? T.terracotta,
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Family contribution
        if (report.byMember.isNotEmpty) ...[
          const SectionHeader(label: 'Kim ne kadar harcadı'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: EviCard(
              child: Column(
                children: () {
                  final totalSpent = report.byMember.fold<double>(0, (a, m) => a + m.expense.toDouble());
                  return report.byMember.map((m) {
                    final pct = totalSpent == 0 ? 0.0 : m.expense / totalSpent;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Avatar(name: m.nickname ?? '?', size: 28, color: m.avatarColor ?? T.terraSoft),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(m.nickname ?? '—', style: TLText.body(size: 13, weight: FontWeight.w500))),
                                  Text('${formatTL(m.expense.toDouble())} ₺', style: TLText.num(size: 12, color: T.inkMute, weight: FontWeight.w500)),
                                ]),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: pct.clamp(0, 1),
                                    backgroundColor: T.lineSoft,
                                    color: m.avatarColor ?? T.terracotta,
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                }(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
