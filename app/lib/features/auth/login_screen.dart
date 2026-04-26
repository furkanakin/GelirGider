import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';

enum _RegisterMode { create, join }

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
  _RegisterMode _registerMode = _RegisterMode.create;
  final _name = TextEditingController();
  final _household = TextEditingController(text: 'Evimiz');
  final _invite = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _household.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      if (_isRegister) {
        if (_registerMode == _RegisterMode.join &&
            _invite.text.trim().isEmpty) {
          throw Exception('Davet kodunu yapıştır.');
        }
        await api.register(
          email: _email.text.trim(),
          password: _password.text,
          displayName: _name.text.trim(),
          householdName: _registerMode == _RegisterMode.create
              ? (_household.text.trim().isEmpty ? 'Evimiz' : _household.text.trim())
              : null,
          inviteCode: _registerMode == _RegisterMode.join
              ? _invite.text.trim()
              : null,
        );
      } else {
        await api.login(email: _email.text.trim(), password: _password.text);
      }
      await api.household();
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _error = _humanizeError(e);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _humanizeError(Object e) {
    final s = e.toString();
    if (s.contains('email already registered')) return 'Bu e-posta zaten kayıtlı. Giriş yapmayı dene.';
    if (s.contains('invalid invite code')) return 'Davet kodu geçersiz.';
    if (s.contains('invite expired')) return 'Davet kodu kullanılmış veya süresi dolmuş.';
    if (s.contains('invalid credentials')) return 'E-posta veya parola yanlış.';
    if (s.contains('Pick one:')) return 'Yeni hane VEYA davet kodu — biri seçilmeli.';
    if (s.contains('SocketException') || s.contains('Failed host lookup')) return 'Sunucuya ulaşılamıyor. API adresini kontrol et.';
    return _isRegister ? 'Kayıt başarısız: ${s.replaceAll("Exception: ", "")}' : 'Giriş başarısız: ${s.replaceAll("Exception: ", "")}';
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
                _isRegister
                    ? (_registerMode == _RegisterMode.join
                        ? 'Aile defterine davetli olarak katıl.'
                        : 'Aile defterine başla.')
                    : 'Hoş geldin, defterine devam et.',
                style: TLText.body(color: T.inkMute, weight: FontWeight.w400),
              ),
              const SizedBox(height: 28),

              if (_isRegister) ...[
                _ModeToggle(
                  mode: _registerMode,
                  onChanged: (m) => setState(() {
                    _registerMode = m;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
                _Field(label: 'Adın', controller: _name, hint: 'Ayşe'),
                const SizedBox(height: 12),
                if (_registerMode == _RegisterMode.create)
                  _Field(label: 'Ev adı', controller: _household, hint: 'Demir Ailesi')
                else
                  _Field(
                    label: 'Davet kodu',
                    controller: _invite,
                    hint: 'davetçinin gönderdiği kod',
                  ),
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
                          _isRegister
                              ? (_registerMode == _RegisterMode.join ? 'Davet kodumla katıl' : 'Kayıt ol')
                              : 'Giriş yap',
                          style: TLText.body(color: Colors.white, weight: FontWeight.w600, size: 15),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _isRegister = !_isRegister;
                    _error = null;
                  }),
                  child: Text(
                    _isRegister ? 'Zaten üyeyim, giriş yap' : 'Yeni hesap aç',
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

class _ModeToggle extends StatelessWidget {
  final _RegisterMode mode;
  final ValueChanged<_RegisterMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(_RegisterMode m, String label) {
      final selected = mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? T.terracotta : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TLText.body(
                color: selected ? Colors.white : T.inkSoft,
                weight: FontWeight.w600,
                size: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.line),
      ),
      child: Row(
        children: [
          seg(_RegisterMode.create, 'Yeni hane'),
          seg(_RegisterMode.join, 'Davet kodu'),
        ],
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
