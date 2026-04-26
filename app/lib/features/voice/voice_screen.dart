import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';
import '../review/review_screen.dart';

import 'bytes_loader.dart'
    if (dart.library.io) 'bytes_loader_io.dart'
    if (dart.library.html) 'bytes_loader_web.dart' as bytes_loader;

/// Voice capture screen.
///
/// Records audio with the `record` package — no platform STT, so no Google
/// Turkish language pack download prompt on Android Chrome — uploads the
/// audio blob to the backend, and the backend pipes it through Whisper +
/// LLM extractor. Works on Android, iOS, and web. The encoder differs by
/// platform (Opus/webm on web, AAC/M4A on mobile); both are accepted by
/// Whisper.
class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});
  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSub;

  bool _recording = false;
  bool _processing = false;
  String? _clipPath; // last finished clip's path (mobile) or blob URL (web)
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _error;
  double _amp = 0;

  @override
  void initState() {
    super.initState();
    _start(); // Auto-start so user just talks; can stop / retry / confirm.
  }

  Future<bool> _ensurePermission() async {
    if (kIsWeb) return true; // Browser prompts during start().
    final mic = await Permission.microphone.request();
    if (mic.isGranted) return true;
    setState(() {
      _error = mic.isPermanentlyDenied
          ? 'Mikrofon izni reddedildi. Telefon ayarları → Uygulamalar → Evimiz → İzinler.'
          : 'Mikrofon izni gerekli.';
    });
    return false;
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _elapsed = Duration.zero;
      _clipPath = null;
    });
    if (!await _ensurePermission()) return;

    try {
      // Browsers natively encode webm/Opus; mobile gets AAC for max compat.
      final config = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000,
        numChannels: 1,
      );
      // Mobile: pass a real writable path or the package's underlying file
      // handle won't open and start() throws / crashes. Web ignores the path
      // and uses an in-memory blob instead.
      final path = await _resolveOutputPath();
      await _recorder.start(config, path: path);

      _ampSub?.cancel();
      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 200))
          .listen((amp) {
        if (!mounted) return;
        // amp.current is roughly -45..0 dB; normalize to 0..10 for the wave.
        final normalized = ((amp.current + 45) / 4.5).clamp(0.0, 10.0);
        setState(() => _amp = normalized);
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });

      setState(() => _recording = true);
    } catch (e) {
      setState(() => _error = 'Kayıt başlatılamadı: $e');
    }
  }

  Future<String> _resolveOutputPath() async {
    if (kIsWeb) return ''; // ignored by record_web
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/evimiz_voice_$ts.m4a';
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await _ampSub?.cancel();
    _ampSub = null;
    String? out;
    try {
      out = await _recorder.stop();
    } catch (_) {
      out = null;
    }
    if (mounted) {
      setState(() {
        _recording = false;
        _clipPath = out;
      });
    }
  }

  Future<void> _restart() async {
    if (_recording) await _stop();
    setState(() {
      _clipPath = null;
      _elapsed = Duration.zero;
    });
    await _start();
  }

  Future<void> _confirm() async {
    if (_processing) return;
    if (_recording) await _stop();
    final pathOrUrl = _clipPath;
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      setState(() => _error = 'Kayıt bulunamadı, tekrar dene.');
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final bytes = await bytes_loader.loadBytes(pathOrUrl);
      if (bytes.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'Kayıt boş, tekrar dene.';
        });
        return;
      }
      final mime = kIsWeb ? 'audio/webm' : 'audio/m4a';
      final filename = kIsWeb ? 'voice.webm' : 'voice.m4a';

      final api = ref.read(apiProvider);
      final me = await ref.read(meProvider.future);
      final AIExtractedReceipt receipt = await api.transcribeAudio(
        bytes,
        filename: filename,
        contentType: mime,
        model: me.preferredLlm,
      );
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
    _ampSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String get _time {
    final m = _elapsed.inMinutes.toString().padLeft(1, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hasClip = _clipPath != null && _clipPath!.isNotEmpty;
    return Scaffold(
      backgroundColor: T.cream,
      body: SafeArea(
        child: Column(
          children: [
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
                          color: _recording ? T.terracotta : T.inkFaint,
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

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _processing
                        ? 'AI ÇALIŞIYOR…'
                        : (_recording ? 'KAYIT EDİYORUM…' : (hasClip ? 'HAZIR' : 'BEKLEMEDE')),
                    style: TLText.label(color: _recording ? T.terracotta : T.inkMute),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _processing
                        ? 'Yapay zeka kaydı çözümlüyor, bekle.'
                        : (_recording
                            ? '"Bugün markete 320 lira verdim..." der gibi konuş.'
                            : (hasClip ? 'Onayla → AI işlesin.' : 'Konuşmaya başla.')),
                    style: TLText.display(20, color: T.ink),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 100,
                child: _Wave(active: _recording, amp: _amp),
              ),
            ),

            const Spacer(),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(_error!, style: TLText.body(color: T.alert, size: 12)),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CtrlBtn(
                    icon: 'trash',
                    onTap: _processing ? null : _restart,
                    color: T.inkMute,
                    background: T.surface,
                    border: T.line,
                    size: 56,
                  ),
                  const SizedBox(width: 36),
                  GestureDetector(
                    onTap: _processing ? null : (_recording ? _stop : _start),
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
                          : EviIcon(_recording ? 'pause' : 'mic', size: 32, color: Colors.white, stroke: 2),
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
