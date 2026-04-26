// Stub. Real implementations in `bytes_loader_io.dart` (mobile / desktop) and
// `bytes_loader_web.dart` (browser). Selected at compile-time via conditional
// import in the consumer (voice_screen.dart, photo_screen.dart).
import 'dart:typed_data';

Future<Uint8List> loadBytes(String pathOrUrl) async {
  throw UnsupportedError('loadBytes: no platform implementation linked');
}
