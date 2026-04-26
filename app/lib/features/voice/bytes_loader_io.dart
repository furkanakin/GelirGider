import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> loadBytes(String path) => File(path).readAsBytes();
