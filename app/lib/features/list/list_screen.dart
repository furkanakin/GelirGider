import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';
import '../common/empty_state.dart';
import '../transactions/transaction_edit_sheet.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});
  @override
  ConsumerState<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends ConsumerState<TransactionsListScreen> {
  String? _kind;
  String? _actor;

  @override
  Widget build(BuildContext context) {
    final filter = TxQuery(kind: _kind, actorUserId: _actor, limit: 200);
    final txs = ref.watch(transactionsProvider(filter));
    final cats = ref.watch(categoriesProvider);
    final members = ref.watch(membersProvider);
    final report = ref.watch(reportProvider(const ReportQuery(scope: 'monthly')));
    final monthLabel = DateFormat('MMMM y', 'tr_TR').format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              subtitle: monthLabel,
              title: Text('İşlemler', style: TLText.display(28)),
              right: RoundIconBtn(icon: 'search', onTap: () => context.push('/search')),
            ),

            // Filter chips
            SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip('Tümü', _kind == null && _actor == null, () => setState(() { _kind = null; _actor = null; })),
                    const SizedBox(width: 6),
                    _chip('Gider', _kind == 'expense', () => setState(() => _kind = 'expense')),
                    const SizedBox(width: 6),
                    _chip('Gelir', _kind == 'income', () => setState(() => _kind = 'income')),
                    const SizedBox(width: 6),
                    members.when(
                      data: (ms) => Row(children: [
                        for (final m in ms) ...[
                          _chip(m.short, _actor == m.userId, () => setState(() => _actor = _actor == m.userId ? null : m.userId)),
                          const SizedBox(width: 6),
                        ],
                      ]),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Summary
            report.when(
              data: (r) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _SummaryCard(label: '↑ Gider', amount: r.totalExpense, color: T.ink)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(label: '↓ Gelir', amount: r.totalIncome, color: T.forest)),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: txs.when(
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: 'list',
                      title: 'Henüz işlem yok',
                      description: 'Ses, foto veya yazı ile ilk kaydını oluştur.',
                    );
                  }
                  final groups = _groupByDay(list);
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(transactionsProvider);
                      await ref.read(transactionsProvider(filter).future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: groups.length,
                      itemBuilder: (_, i) {
                        final g = groups[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
                                child: Text(g.label.toUpperCase(), style: TLText.label()),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: T.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: T.line),
                                ),
                                child: Column(
                                  children: [
                                    for (var k = 0; k < g.items.length; k++)
                                      cats.when(
                                        data: (cs) => members.when(
                                          data: (ms) => _SwipeableRow(
                                            key: ValueKey(g.items[k].id),
                                            tx: g.items[k],
                                            cats: cs,
                                            members: ms,
                                            isLast: k == g.items.length - 1,
                                          ),
                                          loading: () => const SizedBox.shrink(),
                                          error: (_, __) => const SizedBox.shrink(),
                                        ),
                                        loading: () => const SizedBox.shrink(),
                                        error: (_, __) => const SizedBox.shrink(),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: T.terracotta)),
                error: (e, _) => Center(child: Text('$e', style: TLText.body(color: T.alert))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? T.ink : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: T.line),
        ),
        child: Center(
          child: Text(
            label,
            style: TLText.body(color: active ? Colors.white : T.inkSoft, weight: FontWeight.w500, size: 12),
          ),
        ),
      ),
    );
  }

  List<_Group> _groupByDay(List<Transaction> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, _Group>{};
    String labelOf(DateTime d) {
      final day = DateTime(d.year, d.month, d.day);
      if (day == today) return 'Bugün';
      if (day == yesterday) return 'Dün';
      if (now.difference(day).inDays < 7) return 'Bu hafta';
      return DateFormat('MMMM y', 'tr_TR').format(day);
    }
    for (final tx in list) {
      final lbl = labelOf(tx.occurredAt);
      groups.putIfAbsent(lbl, () => _Group(label: lbl, items: [])).items.add(tx);
    }
    return groups.values.toList();
  }
}

class _Group {
  final String label;
  final List<Transaction> items;
  _Group({required this.label, required this.items});
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryCard({required this.label, required this.amount, required this.color});
  @override
  Widget build(BuildContext context) {
    return EviCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TLText.body(size: 11, color: color, weight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(formatTL(amount), style: TLText.display(22, color: color)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Transaction tx;
  final List<Category> cats;
  final List<HouseholdMember> members;
  final bool isLast;
  const _Row({required this.tx, required this.cats, required this.members, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cat = cats.cast<Category?>().firstWhere((c) => c?.id == tx.categoryId, orElse: () => null);
    final actor = members.cast<HouseholdMember?>().firstWhere((m) => m?.userId == tx.actorUserId, orElse: () => null);
    String sourceIcon = switch (tx.source) {
      'voice' => 'mic',
      'photo' => 'camera',
      'text' => 'pen',
      'auto' => 'refresh',
      _ => 'pen',
    };

    return InkWell(
      onTap: () => showTransactionSheet(context, tx),
      child: Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: T.lineSoft)),
      ),
      child: Row(
        children: [
          CatChip(category: cat, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tx.merchant ?? cat?.label ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TLText.body(weight: FontWeight.w500, size: 14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    EviIcon(sourceIcon, size: 11, color: T.inkFaint),
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    if (actor != null) Avatar(name: actor.short, size: 12, color: actor.avatarColor),
                    if (actor != null) const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${actor?.short ?? "—"} · ${DateFormat('HH:mm', 'tr_TR').format(tx.occurredAt)}',
                        style: TLText.body(color: T.inkMute, size: 11, weight: FontWeight.w400),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            (tx.kind == 'income' ? '+' : '−') + formatTL(tx.amount, decimals: tx.amount % 1 == 0 ? 0 : 2),
            style: TLText.num(size: 14, color: tx.kind == 'income' ? T.forest : T.ink, weight: FontWeight.w600),
          ),
        ],
      ),
    ),
    );
  }
}

/// Wraps _Row with a Dismissible so the user can swipe-left to reveal a
/// red 'Delete' background and confirm. Tapping the row still opens the
/// edit sheet via _Row's existing InkWell.
class _SwipeableRow extends ConsumerWidget {
  final Transaction tx;
  final List<Category> cats;
  final List<HouseholdMember> members;
  final bool isLast;
  const _SwipeableRow({
    super.key,
    required this.tx,
    required this.cats,
    required this.members,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('dismiss-${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: T.alert,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            EviIcon('trash', color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
      // We do BOTH confirm AND the API call inside `confirmDismiss` and always
      // return false. The list re-renders on `ref.invalidate` and Flutter
      // disposes the row naturally — far safer than `onDismissed` racing the
      // dismiss animation against an async network call.
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('İşlemi sil'),
            content: Text('${tx.merchant ?? "Bu işlem"} silinsin mi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: T.alert),
                child: const Text('Sil'),
              ),
            ],
          ),
        );
        if (ok != true) return false;
        try {
          await ref.read(apiProvider).deleteTransaction(tx.id);
          ref.invalidate(transactionsProvider);
          ref.invalidate(reportProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: T.ink,
              duration: const Duration(seconds: 2),
              content: Text('İşlem silindi', style: TLText.body(color: Colors.white)),
            ));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: T.alert,
              content: Text('Silinemedi: $e', style: const TextStyle(color: Colors.white)),
            ));
          }
        }
        return false;
      },
      child: _Row(tx: tx, cats: cats, members: members, isLast: isLast),
    );
  }
}
