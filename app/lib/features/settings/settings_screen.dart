import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(meProvider);
    final hh = ref.watch(householdProvider);
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          children: [
            ScreenHeader(
              subtitle: 'AYARLAR',
              title: Text('Tercihler', style: TLText.display(28)),
              onBack: () => context.pop(),
            ),

            const SectionHeader(label: 'Sunucu'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: EviCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: 'web',
                      label: 'API adresi',
                      value: _shortenUrl(AppConfig.apiBaseUrl),
                      onTap: () => _editApiUrl(context, ref),
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SectionHeader(label: 'Profil'),
            user.when(
              data: (u) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: EviCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: 'pen',
                        label: 'İsim',
                        value: u.displayName,
                        onTap: () => _editName(context, ref, u.displayName),
                      ),
                      _SettingsRow(
                        icon: 'tag',
                        label: 'Renk',
                        value: u.avatarColor ?? '—',
                        trailingWidget: u.avatarColor == null
                            ? null
                            : Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: _hexColor(u.avatarColor!),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: T.line),
                                ),
                              ),
                        onTap: () => _editAvatarColor(context, ref, u.avatarColor),
                      ),
                      _SettingsRow(
                        icon: 'globe',
                        label: 'Dil',
                        value: u.locale,
                        onTap: () {},
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: T.terracotta))),
              error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Text('$e', style: TLText.body(color: T.alert))),
            ),

            const SectionHeader(label: 'Yapay zeka'),
            user.when(
              data: (u) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: EviCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < AppConfig.llmModels.length; i++)
                        _LlmRow(
                          slug: AppConfig.llmModels.keys.elementAt(i),
                          label: AppConfig.llmModels.values.elementAt(i),
                          selected: u.preferredLlm == AppConfig.llmModels.keys.elementAt(i),
                          isLast: i == AppConfig.llmModels.length - 1,
                          onSelect: () async {
                            final slug = AppConfig.llmModels.keys.elementAt(i);
                            await ref.read(apiProvider).patchMe({'preferred_llm': slug});
                            ref.invalidate(meProvider);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SectionHeader(label: 'Hane'),
            hh.when(
              data: (h) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: EviCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: 'house-heart',
                        label: 'Hane adı',
                        value: h.name,
                        onTap: () => _editHouseholdName(context, ref, h.name),
                      ),
                      _SettingsRow(
                        icon: 'wallet',
                        label: 'Aylık bütçe',
                        value: '${formatTL(h.monthlyBudget ?? 0)} ₺',
                        onTap: () => _editBudget(context, ref, h.monthlyBudget),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SectionHeader(label: 'Veri'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: EviCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: 'doc',
                      label: 'CSV olarak dışa aktar',
                      value: '',
                      onTap: () async {
                        try {
                          final csv = await ref.read(apiProvider).exportCsvText();
                          await Clipboard.setData(ClipboardData(text: csv));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: T.forest,
                              content: Text(
                                'CSV panoya kopyalandı (${csv.split('\n').length - 1} satır).',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: T.alert,
                              content: Text('Dışa aktarılamadı: $e', style: const TextStyle(color: Colors.white)),
                            ));
                          }
                        }
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(apiProvider).logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const EviIcon('arrow-right', color: T.alert, size: 18),
                  label: Text('Çıkış yap', style: TLText.body(color: T.alert, weight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: T.line),
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

  Future<void> _editApiUrl(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: AppConfig.apiBaseUrl);
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: T.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 24, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + MediaQuery.of(sheetCtx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API ADRESİ', style: TLText.label()),
            const SizedBox(height: 8),
            Text(
              'Backend sunucunun adresi. /api ile bitmeli.',
              style: TLText.body(color: T.inkMute, size: 12, weight: FontWeight.w400),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(hintText: 'https://api.evimiz.app/api'),
            ),
            const SizedBox(height: 8),
            Text(
              'Varsayılan: ${AppConfig.defaultApiBaseUrl}',
              style: TLText.body(color: T.inkFaint, size: 11, weight: FontWeight.w400),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetCtx).pop('__reset__'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: T.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Varsayılana dön', style: TLText.body(color: T.inkSoft, weight: FontWeight.w600, size: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(ctrl.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: T.terracotta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Kaydet', style: TLText.body(color: Colors.white, weight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    if (result == '__reset__') {
      await AppConfig.resetApiBaseUrl();
    } else if (result.trim().isNotEmpty) {
      await AppConfig.setApiBaseUrl(result);
    }
    // Drop any stale auth so the user re-logs in against the new server.
    await ref.read(apiProvider).clear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: T.forest,
        content: Text(
          'Sunucu güncellendi — yeniden giriş yap.',
          style: TLText.body(color: Colors.white),
        ),
      ));
      // Force redirect through the router redirect rule.
      // ignore: use_build_context_synchronously
      Future.delayed(const Duration(milliseconds: 600), () {
        if (context.mounted) context.go('/login');
      });
    }
  }

  String _shortenUrl(String url) {
    // Show host only, since the value column is narrow.
    final u = Uri.tryParse(url);
    if (u == null || u.host.isEmpty) return url;
    return u.host;
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: T.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _SimpleEditSheet(controller: ctrl, title: 'İsim', hint: 'Ayşe Demir'),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(apiProvider).patchMe({'display_name': result});
      ref.invalidate(meProvider);
    }
  }

  Future<void> _editAvatarColor(BuildContext context, WidgetRef ref, String? current) async {
    const colors = ['#E8B5A0', '#9BB3A4', '#F0D396', '#C9B8E0', '#C4593C', '#3D5A4A'];
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: T.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AVATAR RENGİ', style: TLText.label()),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((c) {
                final selected = c == current;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(c),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: _hexColor(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? T.ink : T.line, width: selected ? 3 : 1),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await ref.read(apiProvider).patchMe({'avatar_color': result});
      ref.invalidate(meProvider);
    }
  }

  Future<void> _editHouseholdName(BuildContext context, WidgetRef ref, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: T.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _SimpleEditSheet(controller: ctrl, title: 'Hane adı', hint: 'Demir Ailesi'),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(apiProvider).patchHousehold({'name': result});
      ref.invalidate(householdProvider);
    }
  }

  Future<void> _editBudget(BuildContext context, WidgetRef ref, double? current) async {
    final ctrl = TextEditingController(text: (current ?? 0).toStringAsFixed(0));
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: T.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AYLIK BÜTÇE', style: TLText.label()),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(suffixText: '₺'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  final v = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
                  Navigator.of(sheetCtx).pop(v);
                },
                style: FilledButton.styleFrom(backgroundColor: T.terracotta, foregroundColor: Colors.white),
                child: Text('Kaydet', style: TLText.body(color: Colors.white, weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await ref.read(apiProvider).patchHousehold({'monthly_budget': result});
      ref.invalidate(householdProvider);
    }
  }
}

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

class _SimpleEditSheet extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final String hint;
  const _SimpleEditSheet({required this.controller, required this.title, required this.hint});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TLText.label()),
          const SizedBox(height: 8),
          TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: hint)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: T.terracotta, foregroundColor: Colors.white),
              child: Text('Kaydet', style: TLText.body(color: Colors.white, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final bool isLast;
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailingWidget,
    this.onTap,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: T.lineSoft)),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: T.paper, borderRadius: BorderRadius.circular(10)),
              child: Center(child: EviIcon(icon, size: 16, color: T.inkSoft)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TLText.body(weight: FontWeight.w500, size: 14))),
            if (trailingWidget != null) trailingWidget!,
            if (trailingWidget == null && value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(value, style: TLText.body(color: T.inkMute, size: 12)),
              ),
            if (onTap != null) EviIcon('chevron-right', size: 16, color: T.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _LlmRow extends StatelessWidget {
  final String slug;
  final String label;
  final bool selected;
  final bool isLast;
  final VoidCallback onSelect;
  const _LlmRow({
    required this.slug,
    required this.label,
    required this.selected,
    required this.isLast,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: T.lineSoft)),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: selected ? T.terraTint : T.paper,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: EviIcon(
                  selected ? 'sparkle' : 'tag',
                  size: 16,
                  color: selected ? T.terracotta : T.inkSoft,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TLText.body(weight: FontWeight.w500, size: 14)),
                  Text(slug, style: TLText.body(color: T.inkMute, size: 11)),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(color: T.terracotta, shape: BoxShape.circle),
                child: const Center(child: EviIcon('check', size: 14, color: Colors.white, stroke: 2.5)),
              ),
          ],
        ),
      ),
    );
  }
}

