import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _isRegister = false;
  final _name = TextEditingController();
  final _household = TextEditingController(text: 'Evimiz');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _household.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      final api = ref.read(apiProvider);
      if (_isRegister) {
        await api.register(
          email: _email.text.trim(),
          password: _password.text,
          displayName: _name.text.trim(),
          householdName: _household.text.trim(),
        );
      } else {
        await api.login(email: _email.text.trim(), password: _password.text);
      }
      await api.household();
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = 'Giriş başarısız: ${e is Exception ? e.toString() : "tekrar deneyin"}'; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: T.terracotta, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: const EviIcon('house-heart', size: 32, color: Colors.white, stroke: 1.8),
              ),
              const SizedBox(height: 28),
              Text('Evimiz', style: TLText.display(40)),
              const SizedBox(height: 6),
              Text(
                _isRegister ? 'Aile defterine başla.' : 'Hoş geldin, defterine devam et.',
                style: TLText.body(color: T.inkMute, weight: FontWeight.w400),
              ),
              const SizedBox(height: 28),
              if (_isRegister) ...[
                _Field(label: 'Adın', controller: _name, hint: 'Ayşe'),
                const SizedBox(height: 12),
                _Field(label: 'Ev adı', controller: _household, hint: 'Demir Ailesi'),
                const SizedBox(height: 12),
              ],
              _Field(label: 'E-posta', controller: _email, hint: 'sen@evimiz.app', email: true),
              const SizedBox(height: 12),
              _Field(label: 'Parola', controller: _password, hint: '••••••••', obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: T.terraTint, borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: TLText.body(color: T.terraDeep, size: 12)),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: T.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isRegister ? 'Kayıt ol' : 'Giriş yap',
                          style: TLText.body(color: Colors.white, weight: FontWeight.w600, size: 15),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isRegister = !_isRegister),
                  child: Text(
                    _isRegister ? 'Zaten üyeyim, giriş yap' : 'Yeni aile defteri oluştur',
                    style: TLText.body(color: T.terracotta, weight: FontWeight.w600, size: 13),
                  ),
                ),
              ),
              if (!_isRegister)
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/forgot'),
                    child: Text(
                      'Parolamı unuttum',
                      style: TLText.body(color: T.inkMute, weight: FontWeight.w500, size: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final bool email;
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.email = false,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TLText.label()),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: !obscure,
          keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
