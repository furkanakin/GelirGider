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

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(recurringProvider);
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              subtitle: 'TEKRAR EDEN',
              title: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Sabit '),
                  TextSpan(text: 'kayıtlar', style: TLText.display(28, italic: FontStyle.italic)),
                ]),
                style: TLText.display(28),
              ),
              onBack: () => context.pop(),
              right: RoundIconBtn(icon: 'plus', onTap: () => _showForm(context, ref, null)),
            ),

            Expanded(
              child: templates.when(
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: 'refresh',
                      title: 'Tekrar eden kayıt yok',
                      description: 'Kira, maaş, abonelik gibi düzenli işlemleri ekle. Otomatik defterine işlenir.',
                      actionLabel: 'Yeni',
                      onAction: () => _showForm(context, ref, null),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(recurringProvider);
                      await ref.read(recurringProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _RecurringTile(
                        template: list[i],
                        onTap: () => _showForm(context, ref, list[i]),
                        onRunNow: () async {
                          try {
                            await ref.read(apiProvider).runRecurring(list[i].id);
                            ref.invalidate(transactionsProvider);
                            ref.invalidate(reportProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                backgroundColor: T.forest,
                                content: const Text('İşlem oluşturuldu', style: TextStyle(color: Colors.white)),
                              ));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                backgroundColor: T.alert,
                                content: Text('$e', style: const TextStyle(color: Colors.white)),
                              ));
                            }
                          }
                        },
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

  Future<void> _showForm(BuildContext context, WidgetRef ref, RecurringTemplate? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: T.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _RecurringFormSheet(existing: existing),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringTemplate template;
  final VoidCallback onTap;
  final VoidCallback onRunNow;
  const _RecurringTile({required this.template, required this.onTap, required this.onRunNow});
  @override
  Widget build(BuildContext context) {
    final cadenceLabel = switch (template.cadence) {
      'daily' => 'Her gün',
      'weekly' => 'Her hafta',
      'monthly' => 'Aylık' + (template.dayOfPeriod != null ? ' · ${template.dayOfPeriod}.' : ''),
      'yearly' => 'Yıllık',
      _ => template.cadence,
    };
    return Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: T.line),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: template.kind == 'income' ? T.forestTint : T.terraTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: EviIcon(
                    'refresh',
                    size: 20,
                    color: template.kind == 'income' ? T.forest : T.terracotta,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.label, style: TLText.body(weight: FontWeight.w600, size: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '$cadenceLabel${template.isPaused ? ' · DURDU' : ''}',
                      style: TLText.body(color: T.inkMute, size: 11, weight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (template.kind == 'income' ? '+' : '−') + formatTL(template.amount),
                    style: TLText.num(
                      size: 14,
                      color: template.kind == 'income' ? T.forest : T.ink,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onRunNow,
                    child: Text('Şimdi işle →', style: TLText.body(color: T.terracotta, size: 11, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringFormSheet extends ConsumerStatefulWidget {
  final RecurringTemplate? existing;
  const _RecurringFormSheet({required this.existing});
  @override
  ConsumerState<_RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  late TextEditingController _label;
  late TextEditingController _amount;
  late TextEditingController _day;
  late String _kind;
  late String _cadence;
  String? _categoryId;
  bool _saving = false;
  late bool _paused;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _amount = TextEditingController(text: e == null ? '' : e.amount.toStringAsFixed(0));
    _day = TextEditingController(text: e?.dayOfPeriod?.toString() ?? '1');
    _kind = e?.kind ?? 'expense';
    _cadence = e?.cadence ?? 'monthly';
    _categoryId = e?.categoryId;
    _paused = e?.isPaused ?? false;
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiProvider);
      final body = {
        'label': _label.text.trim(),
        'kind': _kind,
        'amount': double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0,
        'cadence': _cadence,
        if (_cadence == 'monthly') 'day_of_period': int.tryParse(_day.text) ?? 1,
        if (_categoryId != null) 'category_id': _categoryId,
        if (_isEdit) 'is_paused': _paused,
      };
      if (_isEdit) {
        await api.patchRecurring(widget.existing!.id, body);
      } else {
        await api.createRecurring(body);
      }
      ref.invalidate(recurringProvider);
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
        title: const Text('Tekrar eden kaydı sil'),
        content: const Text('Geçmiş işlemler etkilenmez.'),
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
    await ref.read(apiProvider).deleteRecurring(widget.existing!.id);
    ref.invalidate(recurringProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
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
            Text(_isEdit ? 'TEKRAR EDEN KAYDI DÜZENLE' : 'YENİ TEKRAR EDEN', style: TLText.label()),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _seg('Gider', _kind == 'expense', () => setState(() => _kind = 'expense')),
                _seg('Gelir', _kind == 'income', () => setState(() => _kind = 'income')),
              ]),
            ),
            const SizedBox(height: 12),
            _label_('Ad'),
            TextField(controller: _label, autofocus: true, decoration: const InputDecoration(hintText: 'Kira')),
            const SizedBox(height: 12),
            _label_('Tutar'),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(suffixText: '₺'),
            ),
            const SizedBox(height: 12),
            _label_('Sıklık'),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _seg('Günlük', _cadence == 'daily', () => setState(() => _cadence = 'daily')),
                _seg('Haftalık', _cadence == 'weekly', () => setState(() => _cadence = 'weekly')),
                _seg('Aylık', _cadence == 'monthly', () => setState(() => _cadence = 'monthly')),
                _seg('Yıllık', _cadence == 'yearly', () => setState(() => _cadence = 'yearly')),
              ]),
            ),
            if (_cadence == 'monthly') ...[
              const SizedBox(height: 12),
              _label_('Ayın günü (1-31)'),
              TextField(
                controller: _day,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '1'),
              ),
            ],
            const SizedBox(height: 12),
            cats.when(
              data: (cs) {
                final filtered = cs.where((c) => c.kind == _kind).toList();
                final value = filtered.any((c) => c.id == _categoryId) ? _categoryId : null;
                return Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  decoration: BoxDecoration(color: T.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: T.line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KATEGORİ', style: TLText.label().copyWith(fontSize: 10)),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: value,
                          isExpanded: true,
                          hint: Text('Seç', style: TLText.body(color: T.inkMute, size: 13)),
                          items: filtered.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.label, style: TLText.body(size: 13)))).toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _paused,
                onChanged: (v) => setState(() => _paused = v),
                title: Text('Duraklat', style: TLText.body(weight: FontWeight.w500)),
                subtitle: Text('Otomatik işleme almaz', style: TLText.body(color: T.inkMute, size: 12, weight: FontWeight.w400)),
                activeColor: T.terracotta,
              ),
            ],
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

  Widget _label_(String s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s.toUpperCase(), style: TLText.label()));
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
            child: Center(child: Text(label, style: TLText.body(color: active ? T.ink : T.inkMute, weight: FontWeight.w600, size: 11))),
          ),
        ),
      );
}
