import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';

/// Bottom sheet for inspecting / editing / deleting a single transaction.
///
/// We pass `useSafeArea: true` so that on devices with a gesture navigation
/// bar / physical chin, the bottom buttons are not hidden by the system UI.
/// `isScrollControlled` lets us take the full height when the keyboard opens.
Future<bool?> showTransactionSheet(BuildContext context, Transaction tx) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: T.cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.92,
    ),
    builder: (_) => TransactionEditSheet(initial: tx),
  );
}

class TransactionEditSheet extends ConsumerStatefulWidget {
  final Transaction initial;
  const TransactionEditSheet({super.key, required this.initial});
  @override
  ConsumerState<TransactionEditSheet> createState() => _TransactionEditSheetState();
}

class _TransactionEditSheetState extends ConsumerState<TransactionEditSheet> {
  late TextEditingController _amountCtrl;
  late TextEditingController _merchantCtrl;
  late TextEditingController _noteCtrl;
  late String _kind;
  String? _categoryId;
  String? _actorUserId;
  late DateTime _occurredAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.initial.amount.toStringAsFixed(2));
    _merchantCtrl = TextEditingController(text: widget.initial.merchant ?? '');
    _noteCtrl = TextEditingController(text: widget.initial.note ?? '');
    _kind = widget.initial.kind;
    _categoryId = widget.initial.categoryId;
    _actorUserId = widget.initial.actorUserId;
    _occurredAt = widget.initial.occurredAt;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).patchTransaction(widget.initial.id, {
        'amount': double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? widget.initial.amount,
        'merchant': _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim(),
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'category_id': _categoryId,
        'actor_user_id': _actorUserId,
        'occurred_at': _occurredAt.toUtc().toIso8601String(),
      });
      ref.invalidate(transactionsProvider);
      ref.invalidate(reportProvider);
      if (mounted) Navigator.of(context).pop(true);
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sil'),
        content: const Text('Bu işlem silinsin mi?'),
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
      await ref.read(apiProvider).deleteTransaction(widget.initial.id);
      ref.invalidate(transactionsProvider);
      ref.invalidate(reportProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: T.alert,
          content: Text('Silinemedi: $e', style: const TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final members = ref.watch(membersProvider);

    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom + mq.padding.bottom + 16;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: T.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('İŞLEMİ DÜZENLE', style: TLText.label()),
            const SizedBox(height: 8),
            Text(widget.initial.merchant ?? 'İşlem', style: TLText.display(22)),
            const SizedBox(height: 16),

            // Tür
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _seg('Gider', _kind == 'expense', () => setState(() => _kind = 'expense')),
                _seg('Gelir', _kind == 'income', () => setState(() => _kind = 'income')),
              ]),
            ),
            const SizedBox(height: 12),

            // Tutar
            _label('Tutar'),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TLText.display(28),
              decoration: const InputDecoration(suffixText: '₺'),
            ),
            const SizedBox(height: 12),

            // Merchant + Note
            _label('Yer / Açıklama'),
            TextField(controller: _merchantCtrl, decoration: const InputDecoration(hintText: 'Migros')),
            const SizedBox(height: 8),
            TextField(controller: _noteCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Not')),
            const SizedBox(height: 12),

            // Category + Actor
            Row(
              children: [
                Expanded(
                  child: cats.when(
                    data: (cs) {
                      final filtered = cs.where((c) => c.kind == _kind).toList();
                      final hasMatch = filtered.any((c) => c.id == _categoryId);
                      final value = hasMatch ? _categoryId : null;
                      return _wrap(
                        title: 'Kategori',
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: value,
                            isExpanded: true,
                            hint: Text('Seç', style: TLText.body(color: T.inkMute, size: 13)),
                            items: filtered.map((c) =>
                              DropdownMenuItem(value: c.id, child: Text(c.label, style: TLText.body(size: 13)))).toList(),
                            onChanged: (v) => setState(() => _categoryId = v),
                          ),
                        ),
                      );
                    },
                    loading: () => _wrap(title: 'Kategori', child: const SizedBox.shrink()),
                    error: (_, __) => _wrap(title: 'Kategori', child: const SizedBox.shrink()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: members.when(
                    data: (ms) => _wrap(
                      title: 'Kim',
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _actorUserId,
                          isExpanded: true,
                          hint: Text('Seç', style: TLText.body(color: T.inkMute, size: 13)),
                          items: ms.map((m) =>
                            DropdownMenuItem(value: m.userId, child: Text(m.short, style: TLText.body(size: 13)))).toList(),
                          onChanged: (v) => setState(() => _actorUserId = v),
                        ),
                      ),
                    ),
                    loading: () => _wrap(title: 'Kim', child: const SizedBox.shrink()),
                    error: (_, __) => _wrap(title: 'Kim', child: const SizedBox.shrink()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date
            _label('Tarih'),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _occurredAt,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (d != null) setState(() => _occurredAt = DateTime(d.year, d.month, d.day, _occurredAt.hour, _occurredAt.minute));
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(
                  color: T.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: T.line),
                ),
                child: Row(children: [
                  EviIcon('calendar', size: 16, color: T.inkSoft),
                  const SizedBox(width: 10),
                  Text(DateFormat('d MMMM y', 'tr_TR').format(_occurredAt), style: TLText.body(size: 13)),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                IconButton(
                  onPressed: _saving ? null : _delete,
                  icon: const EviIcon('trash', color: T.alert),
                  style: IconButton.styleFrom(
                    backgroundColor: T.surface,
                    side: BorderSide(color: T.line),
                    minimumSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(width: 12),
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
                          : Text('Kaydet', style: TLText.body(color: Colors.white, weight: FontWeight.w600)),
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

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s.toUpperCase(), style: TLText.label()),
      );

  Widget _seg(String label, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: active ? T.shadowSm : null,
            ),
            child: Center(
              child: Text(label, style: TLText.body(color: active ? T.ink : T.inkMute, weight: FontWeight.w600, size: 13)),
            ),
          ),
        ),
      );

  Widget _wrap({required String title, required Widget child}) => Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: T.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TLText.label().copyWith(fontSize: 10)),
            child,
          ],
        ),
      );
}
