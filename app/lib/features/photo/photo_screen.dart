import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/evi_icon.dart';
import '../../widgets/evi_widgets.dart';
import '../review/review_screen.dart';

// On mobile we run on-device OCR (Google ML Kit). On web, the import resolves
// to a stub that returns an empty string — user can still pick from gallery
// and we send the raw image text-extraction request to the backend in future.
import 'ocr_stub.dart' if (dart.library.io) 'ocr_mobile.dart' as ocr;

/// In-app camera for capturing receipts/invoices.
/// Lifecycle:
///   1. Request CAMERA permission
///   2. Open CameraController on the back lens
///   3. Show live preview inside the terracotta corner-frame
///   4. User taps the in-app shutter → takePicture() → freeze + ML Kit OCR
///   5. Tap retry to retake, or proceed → backend AI extract → review screen
class PhotoScreen extends ConsumerStatefulWidget {
  const PhotoScreen({super.key});
  @override
  ConsumerState<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends ConsumerState<PhotoScreen> with WidgetsBindingObserver {
  CameraController? _camera;
  Future<void>? _initFuture;
  String? _capturedPath;
  String? _ocrText;
  bool _busy = false;
  String? _error;
  String _tab = 'fis';
  FlashMode _flash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _camera;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      // No live preview on web — fall back to gallery picker.
      setState(() {});
      return;
    }
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _error = status.isPermanentlyDenied
              ? 'Kamera izni reddedildi. Ayarlar → Uygulamalar → Evimiz → İzinler.'
              : 'Kamera izni gerekli.';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Kullanılabilir kamera bulunamadı.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _initFuture = ctrl.initialize();
      await _initFuture;
      await ctrl.setFlashMode(_flash);
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _camera = ctrl;
        _error = null;
      });
    } on CameraException catch (e) {
      setState(() => _error = 'Kamera hatası: ${e.code} ${e.description ?? ""}');
    } catch (e) {
      setState(() => _error = 'Kamera açılamadı: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final c = _camera;
    if (c == null || !c.value.isInitialized) return;
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
    };
    try {
      await c.setFlashMode(next);
      setState(() => _flash = next);
    } on CameraException {
      // Some lenses don't support all modes — just cycle past.
      setState(() => _flash = FlashMode.off);
    }
  }

  Future<void> _shoot() async {
    final c = _camera;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    setState(() { _busy = true; _error = null; });
    try {
      final file = await c.takePicture();
      setState(() => _capturedPath = file.path);
      final txt = await ocr.recognizeText(file.path);
      if (!mounted) return;
      setState(() => _ocrText = txt);
    } catch (e) {
      setState(() => _error = 'Çekim/OCR başarısız: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() { _busy = true; _error = null; });
    try {
      final picker = ImagePicker();
      final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 1800);
      if (f == null) {
        setState(() => _busy = false);
        return;
      }
      setState(() => _capturedPath = f.path);
      final txt = await ocr.recognizeText(f.path);
      if (!mounted) return;
      setState(() => _ocrText = txt);
    } catch (e) {
      setState(() => _error = 'Seçim/OCR başarısız: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _retry() {
    setState(() { _capturedPath = null; _ocrText = null; });
  }

  Future<void> _process() async {
    if (_ocrText == null || _ocrText!.trim().length < 5) {
      setState(() => _error = 'Yazı okunamadı, daha yakından tekrar dene.');
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      final me = await ref.read(meProvider.future);
      final receipt = await api.extractReceipt(
        _ocrText!,
        model: me.preferredLlm,
        hint: _tab == 'fatura' ? 'fatura' : (_tab == 'tek' ? 'tek satır' : 'fiş'),
      );
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReviewScreen(receipt: receipt, sourceLabel: 'FOTO'),
      ));
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'AI çağrısı başarısız: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCapture = _capturedPath != null;
    final cameraReady = _camera != null && _camera!.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  RoundIconBtn(
                    icon: 'x',
                    onTap: () => context.pop(),
                    background: Colors.white12,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  Text(
                    hasCapture ? 'Önizleme' : 'Fişi çerçevele',
                    style: TLText.body(color: Colors.white, weight: FontWeight.w500, size: 13),
                  ),
                  const Spacer(),
                  if (cameraReady && !hasCapture)
                    RoundIconBtn(
                      icon: 'flash',
                      background: _flash == FlashMode.off ? Colors.white12 : T.terracotta,
                      color: Colors.white,
                      onTap: _toggleFlash,
                    )
                  else
                    const SizedBox(width: 36),
                ],
              ),
            ),

            // Camera preview / captured frame
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: _CameraFrame(
                  child: _buildViewfinder(hasCapture, cameraReady),
                ),
              ),
            ),

            // OCR detected line count
            if (_ocrText != null && _ocrText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: T.terracotta,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const EviIcon('sparkle', size: 12, color: Colors.white, stroke: 2),
                      const SizedBox(width: 6),
                      Text(
                        'AI tarafından okundu — ${_ocrText!.split('\n').where((l) => l.trim().isNotEmpty).length} satır',
                        style: TLText.body(color: Colors.white, size: 12, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TLText.body(color: T.terraSoft, size: 12),
                ),
              ),

            // Tabs (only before capture)
            if (!hasCapture)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final t in const [('tek', 'Tek satır'), ('fis', 'Fiş'), ('fatura', 'Fatura')])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = t.$1),
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _tab == t.$1 ? T.terracotta : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              t.$2,
                              style: TextStyle(
                                color: _tab == t.$1 ? Colors.white : Colors.white54,
                                fontWeight: _tab == t.$1 ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Bottom controls — different per state
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: hasCapture ? _buildCapturedControls() : _buildShootControls(cameraReady),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinder(bool hasCapture, bool cameraReady) {
    if (hasCapture) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_capturedPath!), fit: BoxFit.cover),
          if (_busy)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  SizedBox(height: 12),
                  Text('Okunuyor…', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
        ],
      );
    }
    if (kIsWeb) {
      return Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Web sürümünde galeri kullanılır.\nAlttaki galeri butonundan fiş seç.',
            textAlign: TextAlign.center,
            style: TLText.body(color: Colors.white70, size: 13, weight: FontWeight.w400),
          ),
        ),
      );
    }
    if (!cameraReady) {
      return Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: _error == null
            ? const CircularProgressIndicator(color: T.terracotta)
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TLText.body(color: Colors.white70, size: 13, weight: FontWeight.w400),
                ),
              ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _camera!.value.previewSize?.height ?? 1,
          height: _camera!.value.previewSize?.width ?? 1,
          child: CameraPreview(_camera!),
        ),
      ),
    );
  }

  Widget _buildShootControls(bool cameraReady) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SquareBtn(icon: 'image', onTap: _busy ? null : _pickFromGallery),
        // Big shutter
        GestureDetector(
          onTap: (_busy || !cameraReady) ? null : _shoot,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: cameraReady ? Colors.white : Colors.white60,
                  shape: BoxShape.circle,
                ),
                child: _busy
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: T.terracotta, strokeWidth: 2.5))
                    : null,
              ),
            ),
          ),
        ),
        _SquareBtn(icon: 'rotate', onTap: cameraReady ? () => _initCamera() : null),
      ],
    );
  }

  Widget _buildCapturedControls() {
    return Row(
      children: [
        _SquareBtn(icon: 'rotate', onTap: _busy ? null : _retry, label: 'Tekrar'),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _busy ? null : _process,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const EviIcon('sparkle', size: 18, color: Colors.white, stroke: 2),
              label: Text(
                _busy ? 'AI çalışıyor…' : 'AI ile yorumla',
                style: TLText.body(color: Colors.white, weight: FontWeight.w600, size: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: T.terracotta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SquareBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final String? label;
  const _SquareBtn({required this.icon, this.onTap, this.label});
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: disabled ? Colors.white10 : Colors.white24,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: EviIcon(icon, size: 22, color: Colors.white)),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label!, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

/// Terracotta-cornered rounded frame around the live preview / captured photo.
class _CameraFrame extends StatelessWidget {
  final Widget child;
  const _CameraFrame({required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: child,
          ),
        ),
        // Corner brackets — terracotta L-shapes
        Positioned.fill(child: CustomPaint(painter: _CornersPainter())),
      ],
    );
  }
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = T.terracotta
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    const inset = 6.0;
    final r = Rect.fromLTWH(inset, inset, size.width - 2 * inset, size.height - 2 * inset);
    // top-left
    canvas.drawPath(Path()
      ..moveTo(r.left, r.top + len)
      ..lineTo(r.left, r.top)
      ..lineTo(r.left + len, r.top), paint);
    // top-right
    canvas.drawPath(Path()
      ..moveTo(r.right - len, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + len), paint);
    // bottom-left
    canvas.drawPath(Path()
      ..moveTo(r.left, r.bottom - len)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left + len, r.bottom), paint);
    // bottom-right
    canvas.drawPath(Path()
      ..moveTo(r.right - len, r.bottom)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.right, r.bottom - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
