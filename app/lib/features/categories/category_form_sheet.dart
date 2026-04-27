import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';

const kCategoryIcons = [
  'cart', 'bolt', 'fuel', 'cup', 'baby', 'leaf', 'gift', 'house-heart',
  'wallet', 'spark2', 'food', 'doc', 'globe', 'star', 'tag', 'sparkle',
];

const kCategoryColors = [
  ('#C4593C', '#F6E4D8'),
  ('#3D5A4A', '#DCE7DF'),
  ('#7A6F65', '#EFE8DA'),
  ('#A4452C', '#F0D9CC'),
  ('#C9933A', '#F6E9C0'),
  ('#8B5A8B', '#EBDBEB'),
  ('#1A1A1A', '#E8E0D0'),
  ('#2A4234', '#DCE7DF'),
];

/// Opens the category form. On a successful CREATE, returns the freshly
/// created [Category] so callers (e.g. the AI review screen) can auto-select
/// it in their dropdown without forcing the user to re-pick. Returns null on
/// cancel, archive, or edit.
Future<Category?> showCategoryFormSheet(BuildContext context, {Category? existing, required String defaultKind}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: T.cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _CategoryFormSheet(existing: existing, defaultKind: defaultKind),
  );
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final Category? existing;
  final String defaultKind;
  const _CategoryFormSheet({required this.existing, required this.defaultKind});
  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late TextEditingController _label;
  late TextEditingController _slug;
  late TextEditingController _budget;
  late String _kind;
  late String _icon;
  late String _color;
  late String _tint;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _slug = TextEditingController(text: e?.slug ?? '');
    _budget = TextEditingController(text: e?.monthlyBudget == null ? '' : e!.monthlyBudget!.toStringAsFixed(0));
    _kind = e?.kind ?? widget.defaultKind;
    _icon = e?.icon ?? 'tag';
    _color = e == null ? kCategoryColors.first.$1 : '#${e.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    _tint = e == null ? kCategoryColors.first.$2 : '#${e.tint.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiProvider);
      Category? created;
      if (_isEdit) {
        await api.patchCategory(widget.existing!.id, {
          'label': _label.text.trim(),
          'icon': _icon,
          'color': _color,
          'tint': _tint,
          if (_budget.text.trim().isNotEmpty) 'monthly_budget': double.tryParse(_budget.text.replaceAll(',', '.')) ?? 0,
        });
      } else {
        final slug = _slug.text.trim().isEmpty
            ? _label.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '')
            : _slug.text.trim();
        created = await api.createCategory({
          'slug': slug.isEmpty ? 'kat_${DateTime.now().millisecondsSinceEpoch}' : slug,
          'label': _label.text.trim(),
          'kind': _kind,
          'icon': _icon,
          'color': _color,
          'tint': _tint,
          if (_budget.text.trim().isNotEmpty) 'monthly_budget': double.tryParse(_budget.text.replaceAll(',', '.')) ?? 0,
        });
      }
      ref.invalidate(categoriesProvider);
      // On create, hand the new Category back so the caller (e.g. review
      // screen) can auto-select it. On edit, just pop.
      if (mounted) Navigator.of(context).pop(created);
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
    // Use the dialog's own context (`dialogCtx`) when popping — the outer
    // sheet sits on the local navigator while the dialog is on the root
    // navigator, so popping with the outer context closes the *sheet*.
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Kategoriyi sil'),
        content: const Text('Bu kategori arşivlenecek. Geçmiş işlemler etkilenmez.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: T.alert),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).archiveCategory(widget.existing!.id);
      ref.invalidate(categoriesProvider);
      // Sheet's pop type is Category? — pop with null on archive (no
      // category to hand back).
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
            Text(_isEdit ? 'KATEGORİYİ DÜZENLE' : 'YENİ KATEGORİ', style: TLText.label()),
            const SizedBox(height: 12),

            // Preview chip
            Center(
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: _hexColor(_tint), borderRadius: BorderRadius.circular(20)),
                alignment: Alignment.center,
                child: EviIcon(_icon, size: 32, color: _hexColor(_color), stroke: 1.7),
              ),
            ),
            const SizedBox(height: 16),

            // Kind toggle (only when creating)
            if (!_isEdit)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  _seg('Gider', _kind == 'expense', () => setState(() => _kind = 'expense')),
                  _seg('Gelir', _kind == 'income', () => setState(() => _kind = 'income')),
                ]),
              ),
            if (!_isEdit) const SizedBox(height: 12),

            _label_('Adı'),
            TextField(controller: _label, autofocus: true, decoration: const InputDecoration(hintText: 'Spor Salonu')),
            const SizedBox(height: 12),

            if (!_isEdit) ...[
              _label_('Slug (otomatik)'),
              TextField(controller: _slug, decoration: const InputDecoration(hintText: 'spor_salonu')),
              const SizedBox(height: 12),
            ],

            _label_('Aylık bütçe (opsiyonel)'),
            TextField(
              controller: _budget,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(suffixText: '₺'),
            ),
            const SizedBox(height: 16),

            _label_('İkon'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategoryIcons.map((ic) {
                final selected = ic == _icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = ic),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: selected ? _hexColor(_tint) : T.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? _hexColor(_color) : T.line, width: selected ? 2 : 1),
                    ),
                    child: Center(child: EviIcon(ic, size: 20, color: selected ? _hexColor(_color) : T.inkSoft)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _label_('Renk'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategoryColors.map((cp) {
                final selected = cp.$1 == _color;
                return GestureDetector(
                  onTap: () => setState(() { _color = cp.$1; _tint = cp.$2; }),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _hexColor(cp.$2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? T.ink : T.line, width: selected ? 2 : 1),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: _hexColor(cp.$1), shape: BoxShape.circle),
                    ),
                  ),
                );
              }).toList(),
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

  Widget _label_(String s) => Padding(
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

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
