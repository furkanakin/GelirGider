import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';

const _kOnboardedFlag = 'evimiz.onboarded';

Future<bool> hasOnboarded() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(_kOnboardedFlag) ?? false;
}

Future<void> markOnboarded() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(_kOnboardedFlag, true);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _index = 0;

  // Resolved at build time; tints are mode-dependent so cannot be const.
  List<(String, Color, Color, String, String)> get _pages => [
        (
          'sparkle',
          T.terracotta,
          T.terraTint,
          'AI ile saniyede',
          'Bugün ne harcadığını söyle, yaz veya fotoğrafla. Yapay zeka senin için kategorize eder.',
        ),
        (
          'people',
          T.forest,
          T.forestTint,
          'Aileyle birlikte',
          'Eşin, çocuğun, kardeşin kayıt ekleyebilir; herkes ne kattığını net görür.',
        ),
        (
          'pie',
          const Color(0xFF9A7A2D),
          T.butterTint,
          'Hikaye gibi rapor',
          'Haftalık, aylık, yıllık dalgalar; bütçe uyarıları, kategori dağılımı — tek bakışta.',
        ),
      ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      await markOnboarded();
                      if (context.mounted) context.go('/login');
                    },
                    child: Text('Atla', style: TLText.body(color: T.inkMute, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            color: p.$3,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          alignment: Alignment.center,
                          child: EviIcon(p.$1, size: 64, color: p.$2, stroke: 1.5),
                        ),
                        const SizedBox(height: 36),
                        Text(p.$4, style: TLText.display(36), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(
                          p.$5,
                          textAlign: TextAlign.center,
                          style: TLText.body(color: T.inkMute, weight: FontWeight.w400, size: 15),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _index ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index ? T.terracotta : T.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    if (_index < _pages.length - 1) {
                      _ctrl.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
                    } else {
                      await markOnboarded();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: T.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _index < _pages.length - 1 ? 'Devam et' : 'Başlayalım',
                    style: TLText.body(color: Colors.white, weight: FontWeight.w600, size: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
