import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';

Future<void> _showMemberEdit(BuildContext context, WidgetRef ref, HouseholdMember member) async {
  final nicknameCtrl = TextEditingController(text: member.nickname ?? '');
  String selectedColor = member.avatarColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  selectedColor = '#$selectedColor';
  const palette = ['#E8B5A0', '#9BB3A4', '#F0D396', '#C9B8E0', '#C4593C', '#3D5A4A'];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: T.cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheetCtx) => StatefulBuilder(builder: (sheetCtx, setSheetState) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
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
            Text('ÜYEYİ DÜZENLE', style: TLText.label()),
            const SizedBox(height: 12),
            Text(member.displayName, style: TLText.display(22)),
            const SizedBox(height: 16),
            Text('TAKMA AD', style: TLText.label()),
            const SizedBox(height: 6),
            TextField(controller: nicknameCtrl, decoration: const InputDecoration(hintText: 'Anne, Baba, ...')),
            const SizedBox(height: 16),
            Text('AVATAR RENGİ', style: TLText.label()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: palette.map((c) {
                final selected = c == selectedColor;
                return GestureDetector(
                  onTap: () => setSheetState(() => selectedColor = c),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Color(int.parse('FF${c.substring(1)}', radix: 16)),
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? T.ink : T.line, width: selected ? 3 : 1),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: FilledButton(
                onPressed: () async {
                  try {
                    await ref.read(apiProvider).patchMember(member.userId, {
                      'nickname': nicknameCtrl.text.trim().isEmpty ? null : nicknameCtrl.text.trim(),
                      'avatar_color': selectedColor,
                    });
                    ref.invalidate(membersProvider);
                    if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                  } catch (e) {
                    if (sheetCtx.mounted) {
                      ScaffoldMessenger.of(sheetCtx).showSnackBar(SnackBar(
                        backgroundColor: T.alert,
                        content: Text('$e', style: const TextStyle(color: Colors.white)),
                      ));
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: T.terracotta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Kaydet', style: TLText.body(color: Colors.white, weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }),
  );
}

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hh = ref.watch(householdProvider);
    final members = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          children: [
            ScreenHeader(
              subtitle: 'EVİMİZ',
              title: Text('Aile', style: TLText.display(28)),
              right: RoundIconBtn(icon: 'settings', onTap: () => context.push('/settings')),
            ),

            // Hane kartı
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: hh.when(
                data: (h) => Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  decoration: BoxDecoration(color: T.forest, borderRadius: BorderRadius.circular(22)),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30, top: -30,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HANE', style: TLText.label(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(h.name, style: TLText.display(26, color: Colors.white)),
                          const SizedBox(height: 14),
                          members.when(
                            data: (ms) => Row(
                              children: [
                                ...ms.take(5).toList().asMap().entries.map((e) => Transform.translate(
                                      offset: Offset(e.key * -8.0, 0),
                                      child: Avatar(
                                        name: e.value.short, size: 32, color: e.value.avatarColor, ring: true,
                                      ),
                                    )),
                                const SizedBox(width: 10),
                                Text(
                                  '${ms.length} üye',
                                  style: TLText.body(color: Colors.white.withOpacity(0.85), size: 12),
                                ),
                              ],
                            ),
                            loading: () => const SizedBox(height: 32),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: T.terracotta))),
                error: (e, _) => Text('$e'),
              ),
            ),

            // Üyeler
            const SectionHeader(label: 'Bu ay'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: members.when(
                data: (ms) => EviCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < ms.length; i++)
                        InkWell(
                          onTap: () => _showMemberEdit(context, ref, ms[i]),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              border: i == ms.length - 1 ? null : Border(bottom: BorderSide(color: T.lineSoft)),
                            ),
                            child: Row(
                              children: [
                                Avatar(name: ms[i].short, size: 42, color: ms[i].avatarColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ms[i].displayName, style: TLText.body(weight: FontWeight.w600, size: 14)),
                                      const SizedBox(height: 2),
                                      Text('${ms[i].role}${ms[i].nickname != null ? " · ${ms[i].nickname}" : ""}',
                                          style: TLText.body(color: T.inkMute, size: 11)),
                                    ],
                                  ),
                                ),
                                EviIcon('chevron-right', size: 16, color: T.inkFaint),
                              ],
                            ),
                          ),
                        ),
                      _InviteRow(),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: T.terracotta)),
                error: (e, _) => Text('$e'),
              ),
            ),

            // Ayarlar
            const SectionHeader(label: 'Ayarlar'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: EviCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: 'wallet',
                      label: 'Hesaplar (Cüzdan)',
                      value: '',
                      onTap: () => context.push('/accounts'),
                    ),
                    _SettingsRow(
                      icon: 'tag',
                      label: 'Kategoriler',
                      value: '',
                      onTap: () => context.go('/categories'),
                    ),
                    _SettingsRow(
                      icon: 'refresh',
                      label: 'Tekrar eden kayıtlar',
                      value: '',
                      onTap: () => context.push('/recurring'),
                    ),
                    _SettingsRow(
                      icon: 'bell',
                      label: 'Bildirimler',
                      value: '',
                      onTap: () => context.push('/notifications'),
                    ),
                    _SettingsRow(
                      icon: 'settings',
                      label: 'Ayarlar',
                      value: '',
                      onTap: () => context.push('/settings'),
                    ),
                    _SettingsRow(
                      icon: 'arrow-right',
                      label: 'Çıkış yap',
                      value: '',
                      onTap: () async {
                        await ref.read(apiProvider).logout();
                        if (context.mounted) context.go('/login');
                      },
                      isLast: true,
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

class _InviteRow extends ConsumerStatefulWidget {
  @override
  ConsumerState<_InviteRow> createState() => _InviteRowState();
}

class _InviteRowState extends ConsumerState<_InviteRow> {
  bool _busy = false;

  Future<void> _invite() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(apiProvider).createInvite();
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: r['code'] as String));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: T.forest,
        content: Text('Davet kodu kopyalandı: ${r['code']}', style: const TextStyle(color: Colors.white)),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: T.alert,
          content: Text('Davet oluşturulamadı: $e', style: const TextStyle(color: Colors.white)),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _busy ? null : _invite,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: T.paper,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
          border: Border(top: BorderSide(color: T.lineSoft)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: T.surface,
                shape: BoxShape.circle,
                border: Border.all(color: T.line, width: 1.5),
              ),
              child: _busy
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: T.terracotta, strokeWidth: 2))
                  : const Center(child: EviIcon('plus', size: 18, color: T.terracotta)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aileye birini davet et',
                style: TLText.body(color: T.terracotta, weight: FontWeight.w600, size: 14),
              ),
            ),
            EviIcon('chevron-right', size: 18, color: T.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isLast;
  const _SettingsRow({required this.icon, required this.label, required this.value, this.onTap, this.isLast = false});

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
            if (value.isNotEmpty) Text(value, style: TLText.body(color: T.inkMute, size: 12)),
            if (value.isNotEmpty) const SizedBox(width: 8),
            EviIcon('chevron-right', size: 16, color: T.inkFaint),
          ],
        ),
      ),
    );
  }
}
