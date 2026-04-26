import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';

class MonthlyScreen extends ConsumerWidget {
  const MonthlyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportProvider(const ReportQuery(scope: 'monthly')));
    final monthLabel = DateFormat('MMMM y', 'tr_TR').format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          children: [
            ScreenHeader(
              subtitle: monthLabel,
              title: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Ay '),
                TextSpan(text: 'özeti', style: TLText.display(28, italic: FontStyle.italic)),
              ]), style: TLText.display(28)),
              right: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/weekly'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(999)),
                      child: Text('Hafta', style: TLText.body(size: 12, weight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => context.push('/yearly'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(999)),
                      child: Text('Yıl', style: TLText.body(size: 12, weight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),

            report.when(
              data: (r) => Column(children: _content(context, r)),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator(color: T.terracotta)),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Hata: $e', style: TLText.body(color: T.alert)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, Report r) {
    final segments = r.byCategory.where((c) => c.kind == 'expense').toList();
    final total = segments.fold<double>(0, (a, c) => a + c.total.toDouble());
    return [
      // Donut
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Center(
          child: SizedBox(
            width: 220, height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 60,
                    sectionsSpace: 1,
                    sections: segments.isEmpty
                        ? [
                            PieChartSectionData(
                              value: 1, color: T.lineSoft, radius: 28, showTitle: false,
                            ),
                          ]
                        : segments.map((s) => PieChartSectionData(
                              value: s.total.toDouble(),
                              color: s.color ?? T.terracotta,
                              radius: 28,
                              showTitle: false,
                            )).toList(),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Toplam', style: TLText.body(color: T.inkMute, size: 11)),
                    const SizedBox(height: 2),
                    Text(formatTL(total), style: TLText.display(28)),
                    Text('₺ harcandı', style: TLText.body(color: T.inkMute, size: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      // Comparison cards
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: EviCard(
                color: T.forestTint,
                border: const BorderSide(color: T.forestSoft),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NET KAZANÇ', style: TLText.label(color: T.forest)),
                    const SizedBox(height: 4),
                    Text('+${formatTL(r.balance)}', style: TLText.display(22, color: T.forestDeep)),
                    const SizedBox(height: 2),
                    Text('${formatTL(r.totalIncome)} − ${formatTL(r.totalExpense)}',
                        style: TLText.body(color: T.forest, size: 11, weight: FontWeight.w400)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: EviCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('İŞLEM', style: TLText.label()),
                    const SizedBox(height: 4),
                    Text(
                      r.byCategory.fold<int>(0, (a, c) => a + c.count).toString(),
                      style: TLText.display(22),
                    ),
                    const SizedBox(height: 2),
                    Text('toplam giriş', style: TLText.body(color: T.inkMute, size: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Category list
      const SectionHeader(label: 'Nereye gitti'),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: EviCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (var i = 0; i < segments.length; i++) _CategoryRow(
                segment: segments[i],
                total: total,
                isLast: i == segments.length - 1,
              ),
            ],
          ),
        ),
      ),

      // Daily wave (area-style fl_chart)
      if (r.daily.isNotEmpty) ...[
        const SectionHeader(label: 'Günlük dalga'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: EviCard(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < r.daily.length; i++)
                          FlSpot(i.toDouble(), r.daily[i].expense.toDouble()),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.4,
                      color: T.terracotta,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: T.terraTint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],

      // AI story
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: T.terracotta,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -20,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const EviIcon('sparkle', size: 14, color: Colors.white, stroke: 2),
                    const SizedBox(width: 8),
                    Text('AY HİKAYESİ', style: TLText.label(color: Colors.white)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    _buildSummary(r),
                    style: TLText.display(17, color: Colors.white).copyWith(height: 1.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  String _buildSummary(Report r) {
    if (r.byCategory.isEmpty) return 'Bu ay henüz kayıtlı işlem yok. Hızlı kayıt ile başlayalım.';
    final top = r.byCategory.firstWhere((c) => c.kind == 'expense', orElse: () => r.byCategory.first);
    final txCount = r.byCategory.fold<int>(0, (a, c) => a + c.count);
    return 'Bu ay $txCount işlem yapıldı. En çok ${top.categoryLabel ?? top.categorySlug} (${formatTL(top.total.toDouble())} ₺). Net: ${r.balance >= 0 ? "+" : "−"}${formatTL(r.balance.abs())} ₺.';
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryAggregate segment;
  final double total;
  final bool isLast;
  const _CategoryRow({required this.segment, required this.total, required this.isLast});
  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : ((segment.total / total) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: T.lineSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: segment.color ?? T.terracotta, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(segment.categoryLabel ?? segment.categorySlug ?? '—', style: TLText.body(weight: FontWeight.w500, size: 13))),
          SizedBox(
            width: 36,
            child: Text('%$pct', style: TLText.body(color: T.inkMute, size: 11), textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 84,
            child: Text(
              '${formatTL(segment.total.toDouble())} ₺',
              style: TLText.num(size: 13, weight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
