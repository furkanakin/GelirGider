import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';
import '../common/empty_state.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              subtitle: 'CÜZDAN & HESAPLAR',
              title: Text('Hesaplar', style: TLText.display(28)),
              onBack: () => context.pop(),
              right: RoundIconBtn(
                icon: 'plus',
                onTap: () => _showAccountForm(context, ref, null),
              ),
            ),

            Expanded(
              child: accounts.when(
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: 'wallet',
                      title: 'Hesap yok',
                      description: 'Cüzdan, banka hesabı veya kredi kartı ekleyerek başla.',
                      actionLabel: 'Yeni hesap',
                      onAction: () => _showAccountForm(context, ref, null),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(accountsProvider);
                      await ref.read(accountsProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _AccountTile(
                        account: list[i],
                        onTap: () => _showAccountForm(context, ref, list[i]),
                      ),
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

  Future<void> _showAccountForm(BuildContext context, WidgetRef ref, Account? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: T.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _AccountFormSheet(existing: existing),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  const _AccountTile({required this.account, required this.onTap});
  @override
  Widget build(BuildContext context) {
    String iconOf(String t) => switch (t) {
          'bank' => 'wallet',
          'credit_card' => 'wallet',
          'savings' => 'wallet',
          _ => 'wallet',
        };
    String labelOf(String t) => switch (t) {
          'bank' => 'Banka',
          'credit_card' => 'Kredi kartı',
          'savings' => 'Birikim',
          _ => 'Nakit',
        };
    return Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: T.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(14)),
                child: Center(child: EviIcon(iconOf(account.type), size: 22, color: T.inkSoft)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: TLText.body(weight: FontWeight.w600, size: 15)),
                    const SizedBox(height: 2),
                    Text('${labelOf(account.type)} · ${account.currency}',
                        style: TLText.body(color: T.inkMute, size: 12, weight: FontWeight.w400)),
                  ],
                ),
              ),
              Text(formatTL(account.startingBalance, decimals: 2),
                  style: TLText.num(size: 16, weight: FontWeight.w600)),
              const SizedBox(width: 8),
              EviIcon('chevron-right', size: 16, color: T.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountFormSheet extends ConsumerStatefulWidget {
  final Account? existing;
  const _AccountFormSheet({required this.existing});
  @override
  ConsumerState<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<_AccountFormSheet> {
  late TextEditingController _name;
  late TextEditingController _balance;
  late String _type;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _balance = TextEditingController(text: e == null ? '0' : e.startingBalance.toStringAsFixed(0));
    _type = e?.type ?? 'cash';
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiProvider);
      final body = {
        'name': _name.text.trim(),
        'type': _type,
        'starting_balance': double.tryParse(_balance.text.replaceAll(',', '.')) ?? 0,
      };
      if (_isEdit) {
        await api.patchAccount(widget.existing!.id, body);
      } else {
        await api.createAccount(body);
      }
      ref.invalidate(accountsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: T.alert,
          content: Text('Kaydedilemedi: $e', style: const TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!_isEdit) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hesabı sil'),
        content: const Text('Bu hesap arşivlenecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: T.alert),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).archiveAccount(widget.existing!.id);
      ref.invalidate(accountsProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: T.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(_isEdit ? 'HESABI DÜZENLE' : 'YENİ HESAP', style: TLText.label()),
            const SizedBox(height: 12),
            _label('Ad'),
            TextField(controller: _name, autofocus: true, decoration: const InputDecoration(hintText: 'İş Bankası')),
            const SizedBox(height: 12),
            _label('Tür'),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _seg('Nakit', _type == 'cash', () => setState(() => _type = 'cash')),
                _seg('Banka', _type == 'bank', () => setState(() => _type = 'bank')),
                _seg('Kart', _type == 'credit_card', () => setState(() => _type = 'credit_card')),
                _seg('Birikim', _type == 'savings', () => setState(() => _type = 'savings')),
              ]),
            ),
            const SizedBox(height: 12),
            _label('Açılış bakiyesi'),
            TextField(
              controller: _balance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(suffixText: '₺'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_isEdit)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: IconButton(
                      onPressed: _saving ? null : _delete,
                      icon: const EviIcon('trash', color: T.alert),
                      style: IconButton.styleFrom(
                        backgroundColor: T.surface,
                        side: BorderSide(color: T.line),
                        minimumSize: const Size(50, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: T.terracotta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_isEdit ? 'Kaydet' : 'Oluştur', style: TLText.body(color: Colors.white, weight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s.toUpperCase(), style: TLText.label()));
  Widget _seg(String label, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: active ? T.shadowSm : null,
            ),
            child: Center(child: Text(label, style: TLText.body(color: active ? T.ink : T.inkMute, weight: FontWeight.w600, size: 12))),
          ),
        ),
      );
}
