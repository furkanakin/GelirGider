import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(meProvider);
    final hh = ref.watch(householdProvider);
    final cats = ref.watch(categoriesProvider);
    final members = ref.watch(membersProvider);
    final txs = ref.watch(transactionsProvider(const TxQuery(limit: 5)));
    final report = ref.watch(reportProvider(const ReportQuery(scope: 'monthly')));
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    final dateLabel = DateFormat('EEEE, d MMMM', 'tr_TR').format(DateTime.now());

    // Quick-action panel is pinned just above the tab bar (Stack + Positioned).
    // ListView keeps enough bottom padding so the AI tip card doesn't slide
    // under the panel as the page scrolls. Tab bar is rendered by AppShell
    // and sits at MediaQuery.padding.bottom + ~88 from the bottom.
    final double tabBarSpace = MediaQuery.paddingOf(context).bottom + 88;
    final double quickPanelHeight = 96;

    return Stack(
      children: [
        RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionsProvider);
        ref.invalidate(reportProvider);
        ref.invalidate(meProvider);
        await ref.read(transactionsProvider(const TxQuery(limit: 5)).future);
      },
      child: ListView(
        padding: EdgeInsets.only(top: 20, bottom: tabBarSpace + quickPanelHeight + 16),
        children: [
          // Header
          ScreenHeader(
            subtitle: dateLabel,
            title: user.when(
              data: (u) => Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Merhaba, '),
                  TextSpan(text: u.displayName.split(' ').first, style: const TextStyle(fontStyle: FontStyle.italic)),
                ]),
                style: TLText.display(28),
              ),
              loading: () => Text('Merhaba…', style: TLText.display(28)),
              error: (_, __) => Text('Merhaba', style: TLText.display(28)),
            ),
            right: RoundIconBtn(
              icon: 'bell',
              hasBadge: unread > 0,
              onTap: () => context.push('/notifications'),
            ),
          ),
          const SizedBox(height: 4),

          // Kasa kartı
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _BalanceCard(
              householdLabel: hh.maybeWhen(data: (h) => h.name.toUpperCase(), orElse: () => 'EVİMİZ'),
              monthLabel: DateFormat('MMMM', 'tr_TR').format(DateTime.now()).toUpperCase(),
              balance: report.maybeWhen(data: (r) => r.balance, orElse: () => 0),
              income: report.maybeWhen(data: (r) => r.totalIncome, orElse: () => 0),
              expense: report.maybeWhen(data: (r) => r.totalExpense, orElse: () => 0),
            ),
          ),

          // Aylık bütçe
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: hh.when(
              data: (h) => report.when(
                data: (r) => _BudgetRow(spent: r.totalExpense, budget: h.monthlyBudget ?? 18000),
                loading: () => const _BudgetRow(spent: 0, budget: 18000),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const _BudgetRow(spent: 0, budget: 18000),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Son işlemler
          SectionHeader(
            label: 'Son işlemler',
            trailing: GestureDetector(
              onTap: () => context.go('/list'),
              child: Text('Tümü →', style: TLText.body(color: T.terracotta, weight: FontWeight.w600, size: 12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: txs.when(
              data: (list) => list.isEmpty
                  ? EviCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
                        child: Column(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(color: T.terraTint, borderRadius: BorderRadius.circular(18)),
                              alignment: Alignment.center,
                              child: const EviIcon('sparkle', size: 28, color: T.terracotta, stroke: 1.5),
                            ),
                            const SizedBox(height: 12),
                            Text('Defter henüz boş', style: TLText.display(18)),
                            const SizedBox(height: 4),
                            Text(
                              'Sesli, foto veya yazı ile ilk kaydını yap.',
                              style: TLText.body(color: T.inkMute, size: 13),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => context.go('/add'),
                              style: FilledButton.styleFrom(
                                backgroundColor: T.terracotta,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Yeni kayıt', style: TLText.body(color: Colors.white, weight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : EviCard(
                      padding: EdgeInsets.zero,
                      child: cats.when(
                        data: (cs) => members.when(
                          data: (ms) => Column(
                            children: list
                                .take(5)
                                .map((tx) => _TxRow(
                                      tx: tx,
                                      categories: cs,
                                      members: ms,
                                      isLast: tx == list.last,
                                    ))
                                .toList(),
                          ),
                          loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
              loading: () => EviCard(child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: T.terracotta)))),
              error: (e, _) => EviCard(child: Text('Hata: $e', style: TLText.body(color: T.alert))),
            ),
          ),

          // AI ipucu (statik kart, ileride dinamikleşecek)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: T.forestTint,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: T.forestSoft),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: T.forest, borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: const EviIcon('sparkle', size: 16, color: Colors.white, stroke: 1.8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI İPUCU', style: TLText.label(color: T.forest)),
                        const SizedBox(height: 2),
                        Text(
                          'Sesli, foto veya metin ile kayıt ekle. AI seninle birlikte kategorize eder.',
                          style: TLText.body(color: T.forestDeep, size: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
        ),
        // Pinned quick-action panel — always reachable just above the tab bar.
        // A short cream gradient under it hides whatever ListView content is
        // scrolling past behind, so the panel always reads as "on top".
        Positioned(
          left: 0,
          right: 0,
          bottom: tabBarSpace,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [T.cream.withValues(alpha: 0), T.cream, T.cream],
                stops: const [0, 0.4, 1],
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _QuickAction(icon: 'pen', label: 'Yaz', bg: T.butterTint, color: const Color(0xFF9A7A2D), onTap: () => context.push('/text'))),
                const SizedBox(width: 8),
                Expanded(child: _QuickAction(icon: 'mic', label: 'Sesli', bg: T.terraTint, color: T.terracotta, onTap: () => context.push('/voice'))),
                const SizedBox(width: 8),
                Expanded(child: _QuickAction(icon: 'camera', label: 'Foto', bg: T.forestTint, color: T.forest, onTap: () => context.push('/photo'))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String householdLabel;
  final String monthLabel;
  final double balance;
  final double income;
  final double expense;
  const _BalanceCard({
    required this.householdLabel,
    required this.monthLabel,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: T.terracotta,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x40C4593C), blurRadius: 28, offset: Offset(0, 12))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40, top: -40,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 30, bottom: -30,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const EviIcon('house-heart', size: 14, color: Colors.white, stroke: 1.8),
                    const SizedBox(width: 8),
                    Text(
                      '$householdLabel · $monthLabel',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatTL(balance, decimals: 0),
                      style: TLText.display(48, color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text('₺', style: TLText.display(22, color: Colors.white.withOpacity(0.85))),
                    ),
                  ],
                ),
                Text('kalan bakiye', style: TLText.body(size: 12, color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            EviIcon('arrow-down', size: 11, color: Colors.white.withOpacity(0.85), stroke: 2),
                            const SizedBox(width: 4),
                            Text('GELİR', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                          ]),
                          const SizedBox(height: 2),
                          Text('+${formatTL(income)} ₺', style: TLText.num(size: 18, color: Colors.white)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.white.withOpacity(0.25)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            EviIcon('arrow-up', size: 11, color: Colors.white.withOpacity(0.85), stroke: 2),
                            const SizedBox(width: 4),
                            Text('GİDER', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                          ]),
                          const SizedBox(height: 2),
                          Text('−${formatTL(expense)} ₺', style: TLText.num(size: 18, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String icon;
  final String label;
  final Color bg;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.bg, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: T.line)),
          child: Column(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: EviIcon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Text(label, style: TLText.body(color: T.inkSoft, size: 13, weight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final double spent;
  final double budget;
  const _BudgetRow({required this.spent, required this.budget});

  @override
  Widget build(BuildContext context) {
    final pct = (budget == 0 ? 0 : (spent / budget) * 100).clamp(0, 100).toDouble();
    return EviCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Aylık bütçe', style: TLText.body(color: T.inkSoft, size: 13, weight: FontWeight.w500))),
              Text.rich(TextSpan(children: [
                TextSpan(text: formatTL(spent), style: TLText.num(size: 12, color: T.terracotta, weight: FontWeight.w600)),
                TextSpan(text: ' / ${formatTL(budget)} ₺', style: TLText.num(size: 12, color: T.inkMute, weight: FontWeight.w500)),
              ])),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: T.lineSoft,
              color: T.terracotta,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text('${pct.round()}% kullanıldı', style: TLText.body(color: T.inkMute, size: 11, weight: FontWeight.w500))),
              Text(
                pct < 90 ? '+ iyi gidiyor' : '⚠ dikkat',
                style: TLText.body(color: pct < 90 ? T.forest : T.alert, size: 11, weight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final Transaction tx;
  final List<Category> categories;
  final List<HouseholdMember> members;
  final bool isLast;
  const _TxRow({required this.tx, required this.categories, required this.members, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cat = categories.cast<Category?>().firstWhere(
          (c) => c?.id == tx.categoryId,
          orElse: () => null,
        );
    final actor = members.cast<HouseholdMember?>().firstWhere(
          (m) => m?.userId == tx.actorUserId,
          orElse: () => null,
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: T.lineSoft)),
      ),
      child: Row(
        children: [
          CatChip(category: cat, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchant ?? cat?.label ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TLText.body(weight: FontWeight.w500, size: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (actor != null) Avatar(name: actor.short, size: 14, color: actor.avatarColor),
                    if (actor != null) const SizedBox(width: 6),
                    Text(
                      '${actor?.short ?? "—"} · ${_relTime(tx.occurredAt)}',
                      style: TLText.body(color: T.inkMute, size: 11, weight: FontWeight.w400),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            (tx.kind == 'income' ? '+' : '−') + formatTL(tx.amount, decimals: tx.amount % 1 == 0 ? 0 : 2),
            style: TLText.num(
              size: 14,
              color: tx.kind == 'income' ? T.forest : T.ink,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _relTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Şimdi';
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) return 'Bugün';
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün';
    return DateFormat('d MMM', 'tr_TR').format(dt);
  }
}
