import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';

class YearlyScreen extends ConsumerWidget {
  const YearlyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider(const ReportQuery(scope: 'yearly')));
    final yearLabel = DateFormat('y', 'tr_TR').format(DateTime.now());

    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: report.when(
          data: (r) {
            // Aggregate daily into 12 monthly buckets.
            final monthly = List<double>.filled(12, 0);
            final monthlyIncome = List<double>.filled(12, 0);
            for (final p in r.daily) {
              monthly[p.date.month - 1] += p.expense.toDouble();
              monthlyIncome[p.date.month - 1] += p.income.toDouble();
            }
            final maxAmount = (monthly + monthlyIncome).fold<double>(0, (a, b) => a > b ? a : b).clamp(1, double.infinity).toDouble();

            return ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 100),
              children: [
                ScreenHeader(
                  subtitle: yearLabel,
                  title: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Yıl '),
                    TextSpan(text: 'panoraması', style: TLText.display(28, italic: FontStyle.italic)),
                  ]), style: TLText.display(28)),
                  right: const RoundIconBtn(icon: 'calendar'),
                ),

                // Headline
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${formatTL(r.totalIncome)} ₺', style: TLText.display(22, color: T.forest)),
                      const TextSpan(text: ' kazandınız, '),
                      TextSpan(text: '${formatTL(r.totalExpense)} ₺', style: TLText.display(22, color: T.terracotta, italic: FontStyle.italic)),
                      const TextSpan(text: ' harcadınız.'),
                    ]),
                    style: TLText.display(22, color: T.inkSoft),
                  ),
                ),

                // Stat cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(child: _Stat(label: 'NET', value: '+${formatTL(r.balance)}', color: T.forest, bg: T.forestTint)),
                      const SizedBox(width: 8),
                      Expanded(child: _Stat(label: 'GİDER', value: formatTL(r.totalExpense), color: T.terracotta, bg: T.terraTint)),
                      const SizedBox(width: 8),
                      Expanded(child: _Stat(label: 'GELİR', value: formatTL(r.totalIncome), color: T.forest, bg: T.forestTint)),
                    ],
                  ),
                ),

                // 12-month bar chart
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: EviCard(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    child: SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxAmount * 1.15,
                          barGroups: List.generate(12, (i) => BarChartGroupData(
                            x: i + 1,
                            barRods: [
                              BarChartRodData(
                                toY: monthly[i],
                                width: 7,
                                color: T.terracotta,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3), bottom: Radius.zero),
                              ),
                              BarChartRodData(
                                toY: monthlyIncome[i],
                                width: 7,
                                color: T.forest,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3), bottom: Radius.zero),
                              ),
                            ],
                          )),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  const months = ['O', 'Ş', 'M', 'N', 'M', 'H', 'T', 'A', 'E', 'E', 'K', 'A'];
                                  final i = v.toInt() - 1;
                                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(months[i], style: TLText.body(color: T.inkMute, size: 10)),
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

                // Legend
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      _legend(T.terracotta, 'Gider'),
                      const SizedBox(width: 18),
                      _legend(T.forest, 'Gelir'),
                    ],
                  ),
                ),

                // Top categories of the year
                if (r.byCategory.isNotEmpty) ...[
                  const SectionHeader(label: 'Yıl yıldızları'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: EviCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          for (var i = 0; i < r.byCategory.length && i < 8; i++)
                            _topRow(r.byCategory[i], r.totalExpense.toDouble(), i == 7 || i == r.byCategory.length - 1),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: T.terracotta)),
          error: (e, _) => Center(child: Text('Hata: $e', style: TLText.body(color: T.alert))),
        ),
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(label, style: TLText.body(color: T.inkMute, size: 12, weight: FontWeight.w500)),
        ],
      );

  Widget _topRow(CategoryAggregate agg, double total, bool isLast) {
    final pct = total == 0 ? 0 : ((agg.total.toDouble() / total) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: T.lineSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: agg.color ?? T.terracotta, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(agg.categoryLabel ?? agg.categorySlug ?? '—', style: TLText.body(weight: FontWeight.w500, size: 13))),
          SizedBox(width: 36, child: Text('%$pct', style: TLText.body(color: T.inkMute, size: 11), textAlign: TextAlign.right)),
          SizedBox(width: 92, child: Text('${formatTL(agg.total.toDouble())} ₺', style: TLText.num(size: 13, weight: FontWeight.w600), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _Stat({required this.label, required this.value, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) {
    return EviCard(
      color: bg,
      border: BorderSide(color: color.withValues(alpha: 0.2)),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TLText.label(color: color)),
          const SizedBox(height: 4),
          Text(value, style: TLText.display(18, color: color)),
        ],
      ),
    );
  }
}
