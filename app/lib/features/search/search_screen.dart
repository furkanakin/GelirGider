import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';
import '../common/empty_state.dart';
import '../transactions/transaction_edit_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _busy = false;
  List<Transaction> _results = [];

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(v));
  }

  Future<void> _runSearch(String q) async {
    setState(() { _query = q; _busy = q.length >= 2; });
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    try {
      final list = await ref.read(apiProvider).searchTransactions(q);
      if (!mounted) return;
      setState(() { _results = list; _busy = false; });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final members = ref.watch(membersProvider);
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  RoundIconBtn(icon: 'arrow-left', onTap: () => context.pop()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: _onChanged,
                      decoration: InputDecoration(
                        hintText: 'Ara — Migros, Espressolab, kira...',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: EviIcon('search', size: 18, color: T.inkMute),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _query.length < 2
                  ? const EmptyState(
                      icon: 'search',
                      title: 'En az 2 karakter yaz',
                      description: 'İşlem adı, mağaza veya not içinde arama yap.',
                    )
                  : _busy
                      ? const Center(child: CircularProgressIndicator(color: T.terracotta))
                      : _results.isEmpty
                          ? EmptyState(
                              icon: 'search',
                              title: 'Sonuç yok',
                              description: '"$_query" için kayıt bulunamadı.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: _results.length,
                              itemBuilder: (_, i) {
                                final tx = _results[i];
                                return cats.when(
                                  data: (cs) => members.when(
                                    data: (ms) => _ResultRow(tx: tx, cats: cs, members: ms, query: _query),
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Transaction tx;
  final List<Category> cats;
  final List<HouseholdMember> members;
  final String query;
  const _ResultRow({required this.tx, required this.cats, required this.members, required this.query});
  @override
  Widget build(BuildContext context) {
    final cat = cats.cast<Category?>().firstWhere((c) => c?.id == tx.categoryId, orElse: () => null);
    final actor = members.cast<HouseholdMember?>().firstWhere((m) => m?.userId == tx.actorUserId, orElse: () => null);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: T.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final updated = await showTransactionSheet(context, tx);
            // No need to refresh — the providers are invalidated inside the sheet
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: T.line),
            ),
            child: Row(
              children: [
                CatChip(category: cat, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.merchant ?? cat?.label ?? '—',
                        style: TLText.body(weight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${actor?.short ?? "—"} · ${DateFormat('d MMM y', 'tr_TR').format(tx.occurredAt)}',
                        style: TLText.body(color: T.inkMute, size: 11, weight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                Text(
                  (tx.kind == 'income' ? '+' : '−') + formatTL(tx.amount),
                  style: TLText.num(size: 14, color: tx.kind == 'income' ? T.forest : T.ink, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
