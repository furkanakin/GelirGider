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
import '../categories/category_form_sheet.dart';
import '../review/review_screen.dart';

/// Free-form text → AI classify → review.
///
/// Has two modes:
///   * AI       — natural-language entry (default), goes through the LLM
///                extractor and lands on the review screen.
///   * Manuel   — quick form (amount + category + kind + note) for when the
///                user already knows exactly what they want and doesn't
///                need AI in the loop. Goes straight to the database via
///                createTransaction; no review step.
class TextEntryScreen extends ConsumerStatefulWidget {
  final Category? prefilledCategory;
  const TextEntryScreen({super.key, this.prefilledCategory});

  @override
  ConsumerState<TextEntryScreen> createState() => _TextEntryScreenState();
}

const String _kNewCategorySentinel = '__new_category__';

class _TextEntryScreenState extends ConsumerState<TextEntryScreen> {
  // Default to 'manual' if a category was prefilled (the home / add picker
  // route a category tap straight here for speed) — otherwise default to AI.
  late String _mode = widget.prefilledCategory != null ? 'manual' : 'ai';

  // ---- AI mode -----------------------------------------------------------
  final _aiCtrl = TextEditingController();

  // ---- Manuel mode -------------------------------------------------------
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _kind = 'expense';
  String? _categoryId;
  DateTime _occurredAt = DateTime.now();

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final pre = widget.prefilledCategory;
    if (pre != null) {
      _aiCtrl.text = '${pre.label}: ';
      _aiCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _aiCtrl.text.length));
      _categoryId = pre.id;
      _kind = pre.kind;
    }
  }

  @override
  void dispose() {
    _aiCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _classifyAi() async {
    final text = _aiCtrl.text.trim();
    if (text.length < 3) return;
    setState(() { _busy = true; _error = null; });
    try {
      final api = ref.read(apiProvider);
      final me = await ref.read(meProvider.future);
      final receipt = await api.classifyText(text, model: me.preferredLlm);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReviewScreen(receipt: receipt, sourceLabel: 'METİN'),
      ));
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'AI çağrısı başarısız: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveManual() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Geçerli bir tutar gir.');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'Kategori seç.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final api = ref.read(apiProvider);
      final me = await ref.read(meProvider.future);
      final note = _noteCtrl.text.trim();
      await api.createTransaction({
        'kind': _kind,
        'amount': amount,
        'currency': 'TRY',
        'category_id': _categoryId,
        'actor_user_id': me.id,
        if (note.isNotEmpty) 'note': note,
        if (note.isNotEmpty) 'merchant': note,
        'occurred_at': _occurredAt.toUtc().toIso8601String(),
        'source': 'text',
      });
      ref.invalidate(transactionsProvider);
      ref.invalidate(reportProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Spacer(),
                  Text('Yaz', style: TLText.body(color: T.inkMute, size: 13, weight: FontWeight.w500)),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  _seg('Yapay zeka', _mode == 'ai', () => setState(() => _mode = 'ai')),
                  _seg('Manuel', _mode == 'manual', () => setState(() => _mode = 'manual')),
                ]),
              ),
            ),
            Expanded(child: _mode == 'ai' ? _buildAi() : _buildManual()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(_error!, style: TLText.body(color: T.alert, size: 12)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _busy ? null : (_mode == 'ai' ? _classifyAi : _saveManual),
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : EviIcon(_mode == 'ai' ? 'sparkle' : 'check', size: 18, color: Colors.white, stroke: 2),
                  label: Text(
                    _busy
                        ? (_mode == 'ai' ? 'AI çalışıyor…' : 'Kaydediliyor…')
                        : (_mode == 'ai' ? 'Yapay zeka ile çözümle' : 'Deftere işle'),
                    style: TLText.body(color: Colors.white, weight: FontWeight.w600, size: 15),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: T.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAi() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tek satır da olur', style: TLText.label()),
                const SizedBox(height: 4),
                Text('Bugün ne harcadın?', style: TLText.display(28)),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _aiCtrl,
              autofocus: true,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TLText.body(size: 17, weight: FontWeight.w400),
              decoration: const InputDecoration(
                hintText: "Bugün markete 320 lira verdim, akşam Espressolab'da 65 lira kahve içtim...",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManual() {
    final cats = ref.watch(categoriesProvider);
    final members = ref.watch(membersProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hızlı', style: TLText.label()),
          const SizedBox(height: 4),
          Text('Manuel kayıt', style: TLText.display(28)),
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
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TLText.display(28),
            decoration: const InputDecoration(suffixText: '₺'),
          ),
          const SizedBox(height: 12),

          // Kategori
          _label('Kategori'),
          cats.when(
            data: (cs) {
              final filtered = cs.where((c) => c.kind == _kind).toList();
              final hasMatch = filtered.any((c) => c.id == _categoryId);
              final value = hasMatch ? _categoryId : null;
              final items = <DropdownMenuItem<String?>>[
                ...filtered.map((c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.label, style: TLText.body(size: 14)),
                    )),
                DropdownMenuItem<String?>(
                  value: _kNewCategorySentinel,
                  child: Row(
                    children: [
                      const EviIcon('plus', size: 12, color: T.terracotta, stroke: 2),
                      const SizedBox(width: 6),
                      Text('Yeni kategori',
                          style: TLText.body(size: 14, color: T.terracotta, weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: T.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: T.line),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: value,
                    isExpanded: true,
                    hint: Text('Seç', style: TLText.body(color: T.inkMute, size: 14)),
                    items: items,
                    onChanged: (v) async {
                      if (v == _kNewCategorySentinel) {
                        final created = await showCategoryFormSheet(context, defaultKind: _kind);
                        if (created != null && mounted) {
                          setState(() => _categoryId = created.id);
                        }
                        return;
                      }
                      setState(() => _categoryId = v);
                    },
                  ),
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(color: T.terracotta)),
            ),
            error: (e, _) => Text('$e', style: TLText.body(color: T.alert, size: 12)),
          ),
          const SizedBox(height: 12),

          // Açıklama
          _label('Açıklama (opsiyonel)'),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(hintText: 'Migros, Espressolab...'),
          ),
          const SizedBox(height: 12),

          // Tarih
          _label('Tarih'),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _occurredAt,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (d != null) {
                setState(() => _occurredAt = DateTime(d.year, d.month, d.day, _occurredAt.hour, _occurredAt.minute));
              }
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: T.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: T.line),
              ),
              child: Row(children: [
                EviIcon('calendar', size: 16, color: T.inkSoft),
                const SizedBox(width: 10),
                Text(DateFormat('d MMMM y', 'tr_TR').format(_occurredAt), style: TLText.body(size: 14)),
              ]),
            ),
          ),
          // Touch members so the loading isn't a surprise; not used in form
          // body itself but ensures createTransaction has a fresh actor lookup.
          members.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
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
}
