import 'dart:typed_data';

import 'package:dio/dio.dart';

/// On web the `record` package returns a `blob:` (or `data:`) URL after
/// stopping. Browsers serve those same-origin so a plain GET works.
Future<Uint8List> loadBytes(String url) async {
  final r = await Dio().get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );
  return Uint8List.fromList(r.data!);
}
