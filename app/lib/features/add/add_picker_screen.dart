import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';

class AddPickerScreen extends ConsumerWidget {
  const AddPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  RoundIconBtn(icon: 'x', onTap: () => context.pop()),
                  const Spacer(),
                  Text('Yeni kayıt', style: TLText.body(color: T.inkMute, size: 13, weight: FontWeight.w500)),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Nasıl '),
                      TextSpan(text: 'ekleyelim?', style: TLText.display(32, italic: FontStyle.italic)),
                    ]),
                    style: TLText.display(32),
                  ),
                  const SizedBox(height: 6),
                  Text('AI seninle birlikte, satır satır kaydeder.', style: TLText.body(color: T.inkMute, weight: FontWeight.w400)),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                children: [
                  _MethodTile(
                    icon: 'mic',
                    label: 'Sesli anlat',
                    description: '"Bugün markete 320 lira verdim..."',
                    bg: T.terracotta,
                    color: Colors.white,
                    onTap: () => context.push('/voice'),
                  ),
                  const SizedBox(height: 12),
                  _MethodTile(
                    icon: 'camera',
                    label: 'Fiş çek',
                    description: 'Fişi çek, AI satır satır okusun',
                    bg: T.forest,
                    color: Colors.white,
                    onTap: () => context.push('/photo'),
                  ),
                  const SizedBox(height: 12),
                  _MethodTile(
                    icon: 'pen',
                    label: 'Yaz',
                    description: 'Klasik usul, tek satır da olur',
                    bg: T.ink,
                    color: Colors.white,
                    onTap: () => context.push('/text'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const SectionHeader(label: 'Sık kullanılan'),
            cats.when(
              data: (list) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 4.4,
                  children: list.where((c) => c.kind == 'expense').take(6).map((c) {
                    return Material(
                      color: T.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.push('/text', extra: c),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: T.line),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              CatChip(category: c, size: 32),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  c.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TLText.body(weight: FontWeight.w500, size: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: T.terracotta)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String icon;
  final String label;
  final String description;
  final Color bg;
  final Color color;
  final VoidCallback onTap;
  const _MethodTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.bg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(border: Border.all(color: T.line), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: EviIcon(icon, size: 24, color: color, stroke: 1.8),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TLText.body(weight: FontWeight.w600, size: 16)),
                    const SizedBox(height: 2),
                    Text(description, style: TLText.body(color: T.inkMute, size: 12, weight: FontWeight.w400)),
                  ],
                ),
              ),
              EviIcon('chevron-right', size: 20, color: T.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
