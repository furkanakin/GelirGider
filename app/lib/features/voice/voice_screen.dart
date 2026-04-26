import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';
import '../review/review_screen.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});
  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  final _stt = stt.SpeechToText();
  bool _listening = false;
  bool _initialized = false;
  String _transcript = '';
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _error;
  bool _processing = false;
  double _amp = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Explicitly ask for microphone permission first — speech_to_text doesn't
    // always trigger the OS dialog on its own, and silently fails if denied.
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() {
        _error = mic.isPermanentlyDenied
            ? 'Mikrofon izni reddedildi. Telefon ayarlarından izin ver.'
            : 'Mikrofon izni gerekli.';
      });
      return;
    }

    final ok = await _stt.initialize(
      onError: (e) {
        if (!mounted) return;
        setState(() => _error = 'Konuşma tanıma hatası: ${e.errorMsg}');
      },
      onStatus: (s) {
        // 'listening' | 'notListening' | 'done'
        if (s == 'done' && mounted && _listening) {
          setState(() => _listening = false);
        }
      },
    );
    if (!mounted) return;
    setState(() => _initialized = ok);
    if (!ok) {
      setState(() {
        _error = 'Konuşma tanıma motoru başlatılamadı. '
            'Cihazda Türkçe konuşma motoru (Google) yüklü olmalı: '
            'Ayarlar → Diller ve giriş → Konuşma → Konuşma tanıma motoru.';
      });
      return;
    }

    // Verify Turkish locale is actually available; if not, fall back gracefully.
    final locales = await _stt.locales();
    final hasTr = locales.any((l) => l.localeId.toLowerCase().startsWith('tr'));
    if (!hasTr) {
      setState(() {
        _error = 'Türkçe konuşma tanıma yüklü değil. '
            'Google uygulamasında Türkçe dil paketini indir, sonra tekrar dene.';
      });
      return;
    }

    await _start();
  }

  Future<void> _start() async {
    if (!_initialized) return;
    _transcript = '';
    _elapsed = Duration.zero;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    await _stt.listen(
      onResult: (r) => setState(() => _transcript = r.recognizedWords),
      localeId: 'tr_TR',
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      ),
      onSoundLevelChange: (level) {
        setState(() => _amp = level.clamp(-2, 10));
      },
    );
    setState(() => _listening = true);
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await _stt.stop();
    setState(() => _listening = false);
  }

  Future<void> _confirm() async {
    if (_transcript.trim().length < 3) return;
    await _stop();
    setState(() => _processing = true);
    try {
      final api = ref.read(apiProvider);
      final me = await ref.read(meProvider.future);
      final receipt = await api.transcribeVoice(_transcript, model: me.preferredLlm);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReviewScreen(receipt: receipt, sourceLabel: 'SES'),
      ));
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'AI çağrısı başarısız: $e';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stt.stop();
    super.dispose();
  }

  String get _time {
    final m = _elapsed.inMinutes.toString().padLeft(1, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  RoundIconBtn(icon: 'x', onTap: () => context.pop()),
                  const Spacer(),
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _listening ? T.terracotta : T.inkFaint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_time, style: TLText.num(size: 13, color: T.inkSoft, weight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // Status / transcript
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _initialized ? (_listening ? 'DİNLİYORUM…' : 'BEKLEMEDE') : 'YÜKLENİYOR',
                    style: TLText.label(color: _listening ? T.terracotta : T.inkMute),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _transcript.isEmpty
                        ? '"Bugün markete 320 lira verdim..."'
                        : '"$_transcript${_listening ? "|" : ""}"',
                    style: TLText.display(
                      22,
                      color: _transcript.isEmpty ? T.inkFaint : T.ink,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            // Wave animation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 100,
                child: _Wave(active: _listening, amp: _amp),
              ),
            ),

            const Spacer(),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(_error!, style: TLText.body(color: T.alert, size: 12)),
              ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CtrlBtn(
                    icon: 'trash',
                    onTap: () {
                      _stop();
                      setState(() { _transcript = ''; _elapsed = Duration.zero; });
                    },
                    color: T.inkMute,
                    background: T.surface,
                    border: T.line,
                    size: 56,
                  ),
                  const SizedBox(width: 36),
                  GestureDetector(
                    onTap: _processing ? null : (_listening ? _stop : _start),
                    child: Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: T.terracotta,
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Color(0x66C4593C), blurRadius: 24, offset: Offset(0, 8))],
                      ),
                      alignment: Alignment.center,
                      child: _processing
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          : EviIcon(_listening ? 'pause' : 'mic', size: 32, color: Colors.white, stroke: 2),
                    ),
                  ),
                  const SizedBox(width: 36),
                  _CtrlBtn(
                    icon: 'check',
                    onTap: _processing ? null : _confirm,
                    color: Colors.white,
                    background: T.forest,
                    border: T.forest,
                    size: 56,
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

class _CtrlBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final Color color;
  final Color background;
  final Color border;
  final double size;
  const _CtrlBtn({required this.icon, required this.color, required this.background, required this.border, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1.5),
        ),
        child: Center(child: EviIcon(icon, size: size * 0.36, color: color, stroke: 2)),
      ),
    );
  }
}

class _Wave extends StatefulWidget {
  final bool active;
  final double amp;
  const _Wave({required this.active, required this.amp});
  @override
  State<_Wave> createState() => _WaveState();
}

class _WaveState extends State<_Wave> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return CustomPaint(
          size: Size.infinite,
          painter: _WavePainter(t: _c.value, active: widget.active, amp: widget.amp),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  final bool active;
  final double amp;
  _WavePainter({required this.t, required this.active, required this.amp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = active ? T.terracotta : T.lineSoft;
    final activeBars = (32 * 0.7).round();
    const barCount = 32;
    final w = (size.width - barCount * 4) / (barCount - 1);
    for (int i = 0; i < barCount; i++) {
      final phase = t * 2 * pi + i * 0.7;
      final amplitude = active ? (1 + amp * 0.05) : 0.3;
      final h = 8.0 + (sin(phase).abs() * 70 * amplitude).clamp(0.0, size.height - 8.0);
      final isActive = i < activeBars;
      final p = Paint()
        ..color = isActive ? (active ? T.terracotta : T.terraSoft) : T.lineSoft;
      final left = i * (4 + w);
      final top = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, top, 4, h.toDouble()), const Radius.circular(2)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.t != t || old.active != active || old.amp != amp;
}
