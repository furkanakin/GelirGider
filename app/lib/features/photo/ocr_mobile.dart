import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String> recognizeText(String imagePath) async {
  final input = InputImage.fromFilePath(imagePath);
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(input);
    return result.text;
  } finally {
    await recognizer.close();
  }
}
