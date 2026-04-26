import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            ScreenHeader(
              subtitle: 'YARDIM',
              title: Text('Parolanı mı unuttun?', style: TLText.display(28)),
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 12),
            if (!_submitted) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'E-posta adresine sıfırlama bağlantısı göndereceğiz. (E-posta entegrasyonu yöneticin tarafından kurulduğunda aktif olur.)',
                  style: TLText.body(color: T.inkMute, weight: FontWeight.w400, size: 14),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('E-POSTA', style: TLText.label()),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _ctrl,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'sen@evimiz.app'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => setState(() => _submitted = true),
                    style: FilledButton.styleFrom(
                      backgroundColor: T.terracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Bağlantı gönder', style: TLText.body(color: Colors.white, weight: FontWeight.w600, size: 15)),
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: T.forestTint, borderRadius: BorderRadius.circular(24)),
                      alignment: Alignment.center,
                      child: const EviIcon('check', size: 40, color: T.forest, stroke: 2.2),
                    ),
                    const SizedBox(height: 18),
                    Text('Bağlantı gönderildi', style: TLText.display(22)),
                    const SizedBox(height: 8),
                    Text(
                      _ctrl.text.isEmpty ? 'E-posta kutuna bak.' : 'Bağlantı ${_ctrl.text} adresine gönderildi.',
                      textAlign: TextAlign.center,
                      style: TLText.body(color: T.inkMute, weight: FontWeight.w400),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('Girişe dön', style: TLText.body(color: T.terracotta, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
