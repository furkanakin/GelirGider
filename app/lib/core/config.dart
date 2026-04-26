import 'package:shared_preferences/shared_preferences.dart';

/// Runtime app configuration. Defaults come from `--dart-define` build flags,
/// but the user can override the API base URL from Settings → "Sunucu" so the
/// same APK works after the user deploys their backend to a custom domain.
class AppConfig {
  AppConfig._();

  static const _kApiBaseUrl = 'evimiz.api_base_url';

  /// The default URL baked into the binary at build time. Pass with:
  ///   flutter build apk --release --dart-define=API_BASE_URL=https://api.evimiz.app/api
  static const defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8001/api',
  );

  /// The actual URL we'll use this run. Loaded from prefs at startup, falls
  /// back to the build-time default. Update via [setApiBaseUrl].
  static String _apiBaseUrl = defaultApiBaseUrl;
  static String get apiBaseUrl => _apiBaseUrl;

  static Future<void> hydrate() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_kApiBaseUrl);
    if (saved != null && saved.trim().isNotEmpty) {
      _apiBaseUrl = saved.trim();
    }
  }

  /// Set + persist a new API base URL. Strips trailing slash.
  static Future<void> setApiBaseUrl(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleaned.isEmpty) return;
    _apiBaseUrl = cleaned;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kApiBaseUrl, cleaned);
  }

  static Future<void> resetApiBaseUrl() async {
    _apiBaseUrl = defaultApiBaseUrl;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kApiBaseUrl);
  }

  static const appName = 'Evimiz';
  static const supportEmail = 'destek@evimiz.app';

  /// LLM models the user can select from Settings.
  static const llmModels = <String, String>{
    'qwen3-coder-next': 'Qwen 3 Coder',
    'glm-5.1': 'GLM 5.1',
    'kimi-k2.6': 'Kimi K2.6',
    'minimax-m2.7': 'MiniMax M2.7',
  };
}
