import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';
import 'category_form_sheet.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});
  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _kind = 'expense';

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final report = ref.watch(reportProvider(const ReportQuery(scope: 'monthly')));

    Map<String, double> totals = {};
    report.whenData((r) {
      for (final c in r.byCategory) {
        if (c.categorySlug != null) totals[c.categorySlug!] = c.total.toDouble();
      }
    });
    final monthLabel = DateFormat('MMMM y', 'tr_TR').format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: cats.when(
          data: (list) => ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            children: [
              ScreenHeader(
                subtitle: monthLabel,
                title: Text('Kategoriler', style: TLText.display(28)),
                right: RoundIconBtn(
                  icon: 'plus',
                  onTap: () => showCategoryFormSheet(context, defaultKind: _kind),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _segment('Gider', _kind == 'expense', () => setState(() => _kind = 'expense')),
                      _segment('Gelir', _kind == 'income', () => setState(() => _kind = 'income')),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    ...list.where((c) => c.kind == _kind).map((c) {
                      final amount = totals[c.slug] ?? 0;
                      return GestureDetector(
                        onTap: () => showCategoryFormSheet(context, existing: c, defaultKind: _kind),
                        child: _CategoryTile(category: c, amount: amount),
                      );
                    }),
                    GestureDetector(
                      onTap: () => showCategoryFormSheet(context, defaultKind: _kind),
                      child: _AddTile(kind: _kind),
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: T.terracotta)),
          error: (e, _) => Center(child: Text('$e', style: TLText.body(color: T.alert))),
        ),
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? T.shadowSm : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TLText.body(color: active ? T.ink : T.inkMute, weight: FontWeight.w600, size: 13),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final double amount;
  const _CategoryTile({required this.category, required this.amount});
  @override
  Widget build(BuildContext context) {
    return EviCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: category.tint, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: EviIcon(category.icon, size: 20, color: category.color, stroke: 1.7),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.label, style: TLText.body(weight: FontWeight.w500, size: 13)),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: amount > 0 ? formatTL(amount) : '—', style: TLText.display(18)),
                  if (amount > 0)
                    TextSpan(text: ' ₺', style: TLText.body(color: T.inkMute, size: 11)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final String kind;
  const _AddTile({required this.kind});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: T.line, style: BorderStyle.solid, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: T.paper, shape: BoxShape.circle),
            child: Center(child: EviIcon('plus', size: 18, color: T.inkMute)),
          ),
          const SizedBox(height: 6),
          Text('Yeni', style: TLText.body(color: T.inkMute, weight: FontWeight.w500, size: 12)),
        ],
      ),
    );
  }
}
