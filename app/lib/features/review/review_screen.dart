import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';
import '../categories/category_form_sheet.dart';

class _DraftLine {
  String? merchant;
  double amount;
  String currency;
  String kind;
  String? categoryId;
  String? actorUserId;
  String? note;
  double? confidence;
  _DraftLine({
    required this.amount,
    this.currency = 'TRY',
    this.kind = 'expense',
    this.merchant,
    this.categoryId,
    this.actorUserId,
    this.note,
    this.confidence,
  });
}

class ReviewScreen extends ConsumerStatefulWidget {
  final AIExtractedReceipt receipt;
  final String sourceLabel;
  const ReviewScreen({super.key, required this.receipt, required this.sourceLabel});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late List<_DraftLine> _drafts;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _drafts = widget.receipt.lines.map((l) => _DraftLine(
          amount: l.amount,
          currency: l.currency,
          kind: l.kind,
          merchant: l.merchant,
          note: l.note,
          confidence: l.confidence,
        )).toList();
  }

  Future<void> _ensureCategoriesAndMembersResolved() async {
    final cats = await ref.read(categoriesProvider.future);
    final members = await ref.read(membersProvider.future);
    final me = await ref.read(meProvider.future);
    for (var i = 0; i < _drafts.length && i < widget.receipt.lines.length; i++) {
      final l = widget.receipt.lines[i];
      if (l.categorySlug != null) {
        final c = cats.cast<Category?>().firstWhere(
              (c) => c?.slug == l.categorySlug,
              orElse: () => null,
            );
        if (c != null) _drafts[i].categoryId = c.id;
      }
      if (l.actorNickname != null) {
        final m = members.cast<HouseholdMember?>().firstWhere(
              (m) => m?.short.toLowerCase() == l.actorNickname!.toLowerCase(),
              orElse: () => null,
            );
        _drafts[i].actorUserId = m?.userId;
      }
      _drafts[i].actorUserId ??= me.id;
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_drafts.isEmpty) return;
    setState(() { _saving = true; _error = null; });
    try {
      final api = ref.read(apiProvider);
      final body = _drafts.map((d) => {
            'kind': d.kind,
            'amount': d.amount,
            'currency': d.currency,
            if (d.merchant != null) 'merchant': d.merchant,
            if (d.note != null) 'note': d.note,
            if (d.categoryId != null) 'category_id': d.categoryId,
            if (d.actorUserId != null) 'actor_user_id': d.actorUserId,
            'ai_job_id': widget.receipt.jobId,
            if (d.confidence != null) 'ai_confidence': d.confidence,
            'source': widget.sourceLabel.toLowerCase() == 'foto' ? 'photo' :
                     widget.sourceLabel.toLowerCase() == 'ses' ? 'voice' : 'text',
          }).toList();
      await api.createBulk(body);
      ref.invalidate(transactionsProvider);
      ref.invalidate(reportProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Kayıt başarısız: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _ensureCategoriesAndMembersResolved(),
      builder: (context, _) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final members = ref.watch(membersProvider);
    final total = _drafts.fold<double>(0, (a, b) => a + (b.kind == 'expense' ? b.amount : -b.amount));

    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              subtitle: 'AI ÖZET · ${widget.receipt.model}',
              title: Text.rich(TextSpan(children: [
                TextSpan(text: '${_drafts.length} işlem', style: TLText.display(28, italic: FontStyle.italic)),
                const TextSpan(text: ' hazır'),
              ]), style: TLText.display(28)),
              onBack: () => Navigator.of(context).pop(),
              right: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: T.forestTint,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: T.forestSoft),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EviIcon('sparkle', size: 12, color: T.forest, stroke: 2),
                    const SizedBox(width: 4),
                    Text('AI', style: TLText.body(color: T.forest, weight: FontWeight.w600, size: 12)),
                  ],
                ),
              ),
            ),
            if (widget.receipt.summary != null && widget.receipt.summary!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(widget.receipt.summary!, style: TLText.body(color: T.inkMute, size: 13)),
              ),

            Expanded(
              child: cats.when(
                data: (catList) => members.when(
                  data: (memberList) => ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    itemCount: _drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _DraftCard(
                      draft: _drafts[i],
                      categories: catList,
                      members: memberList,
                      onChange: () => setState(() {}),
                      onDelete: () => setState(() => _drafts.removeAt(i)),
                    ),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator(color: T.terracotta)),
                  error: (e, _) => Center(child: Text('$e')),
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: T.terracotta)),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_error!, style: TLText.body(color: T.alert, size: 12)),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(color: T.ink, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Toplam', style: TLText.body(color: Colors.white70, size: 13))),
                        Text(
                          (total < 0 ? '+' : '−') + formatTL(total.abs(), decimals: 2) + ' ₺',
                          style: TLText.display(28, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const EviIcon('check', size: 18, color: Colors.white, stroke: 2.2),
                        label: Text(_saving ? 'Kaydediliyor…' : 'Deftere işle',
                          style: TLText.body(color: Colors.white, weight: FontWeight.w600, size: 15)),
                        style: FilledButton.styleFrom(
                          backgroundColor: T.terracotta,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCard extends StatefulWidget {
  final _DraftLine draft;
  final List<Category> categories;
  final List<HouseholdMember> members;
  final VoidCallback onChange;
  final VoidCallback onDelete;
  const _DraftCard({
    required this.draft,
    required this.categories,
    required this.members,
    required this.onChange,
    required this.onDelete,
  });

  @override
  State<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<_DraftCard> {
  bool _expanded = false;

  Category? get _cat => widget.categories.cast<Category?>().firstWhere(
        (c) => c?.id == widget.draft.categoryId, orElse: () => null);

  HouseholdMember? get _actor => widget.members.cast<HouseholdMember?>().firstWhere(
        (m) => m?.userId == widget.draft.actorUserId, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _expanded ? T.terracotta : T.line,
              width: _expanded ? 1.5 : 1,
            ),
            boxShadow: _expanded ? [const BoxShadow(color: Color(0x1FC4593C), blurRadius: 16, offset: Offset(0, 4))] : null,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    CatChip(category: _cat, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.merchant ?? d.note ?? 'Tanımsız', style: TLText.body(weight: FontWeight.w500, size: 14)),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (_cat != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                                  decoration: BoxDecoration(color: _cat!.tint, borderRadius: BorderRadius.circular(999)),
                                  child: Text(_cat!.label, style: TextStyle(color: _cat!.color, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                              if (_actor != null) ...[
                                Text('·', style: TextStyle(color: T.inkMute, fontSize: 10)),
                                Avatar(name: _actor!.short, size: 14, color: _actor!.avatarColor),
                                Text(_actor!.short, style: TLText.body(color: T.inkMute, size: 10)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (d.kind == 'expense' ? '−' : '+') + formatTL(d.amount, decimals: 2),
                          style: TLText.display(20, color: T.ink),
                        ),
                        Text(
                          '₺' + (d.confidence == null ? '' : ' · %${(d.confidence! * 100).round()}'),
                          style: TLText.body(color: T.inkMute, size: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_expanded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(
                    color: T.paper,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
                    border: Border(top: BorderSide(color: T.lineSoft)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DÜZENLE', style: TLText.label()),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _categoryDropdown(d)),
                          const SizedBox(width: 8),
                          Expanded(child: _memberDropdown(d)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _amountField(d),
                      const SizedBox(height: 8),
                      _noteField(d),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _kindToggle(d)),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: widget.onDelete,
                            icon: const EviIcon('trash', color: T.alert, size: 18),
                            style: IconButton.styleFrom(backgroundColor: T.surface, side: BorderSide(color: T.line)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Sentinel value for the "Yeni kategori" item inside the dropdown. Picking
  // it opens the category form sheet inline so the user doesn't have to bail
  // out of the review flow to add a missing category — the AI extraction is
  // not always going to find a perfect match in the household's existing list.
  static const String _kNewCategorySentinel = '__new_category__';

  Widget _categoryDropdown(_DraftLine d) {
    final items = [
      ...widget.categories.where((c) => c.kind == d.kind).map(
            (c) => DropdownMenuItem<String?>(
              value: c.id,
              child: Text(c.label, style: TLText.body(size: 13)),
            ),
          ),
      DropdownMenuItem<String?>(
        value: _kNewCategorySentinel,
        child: Row(
          children: [
            const EviIcon('plus', size: 12, color: T.terracotta, stroke: 2),
            const SizedBox(width: 6),
            Text('Yeni kategori',
                style: TLText.body(size: 13, color: T.terracotta, weight: FontWeight.w600)),
          ],
        ),
      ),
    ];
    return _Field(
      label: 'Kategori',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: d.categoryId,
          isExpanded: true,
          items: items,
          onChanged: (v) async {
            if (v == _kNewCategorySentinel) {
              final created = await showCategoryFormSheet(context, defaultKind: d.kind);
              if (created != null) {
                d.categoryId = created.id;
              }
              widget.onChange();
              return;
            }
            d.categoryId = v;
            widget.onChange();
          },
        ),
      ),
    );
  }

  Widget _memberDropdown(_DraftLine d) {
    return _Field(
      label: 'Kim',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: d.actorUserId,
          isExpanded: true,
          items: widget.members.map((m) =>
            DropdownMenuItem(value: m.userId, child: Text(m.short, style: TLText.body(size: 13)))).toList(),
          onChanged: (v) {
            d.actorUserId = v;
            widget.onChange();
          },
        ),
      ),
    );
  }

  Widget _amountField(_DraftLine d) {
    return _Field(
      label: 'Tutar',
      child: TextFormField(
        initialValue: d.amount.toString(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        onChanged: (v) {
          d.amount = double.tryParse(v.replaceAll(',', '.')) ?? d.amount;
        },
      ),
    );
  }

  Widget _noteField(_DraftLine d) {
    return _Field(
      label: 'Not',
      child: TextFormField(
        initialValue: d.note ?? d.merchant ?? '',
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
        onChanged: (v) => d.note = v,
      ),
    );
  }

  Widget _kindToggle(_DraftLine d) {
    return _Field(
      label: 'Tür',
      child: ToggleButtons(
        constraints: const BoxConstraints(minHeight: 28, minWidth: 60),
        isSelected: [d.kind == 'expense', d.kind == 'income'],
        onPressed: (i) {
          d.kind = i == 0 ? 'expense' : 'income';
          widget.onChange();
        },
        borderRadius: BorderRadius.circular(8),
        selectedColor: Colors.white,
        fillColor: T.terracotta,
        children: const [Text('Gider', style: TextStyle(fontSize: 12)), Text('Gelir', style: TextStyle(fontSize: 12))],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: T.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TLText.label().copyWith(fontSize: 10)),
          child,
        ],
      ),
    );
  }
}
