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

  /// LLM models the user can select from Settings, grouped by speed/cost.
  /// The model id (key) is sent to the backend as `preferred_llm` and forwarded
  /// to llmgateway.io as the `model` parameter. Add or rearrange freely — the
  /// backend just treats the value as a string and falls through fallbacks if
  /// the chosen one isn't reachable.
  static const llmModels = <String, String>{
    // Hızlı ve ucuz — gündelik kullanım için ideal.
    'gpt-4o-mini': 'GPT-4o mini · hızlı',
    'gpt-4.1-mini': 'GPT-4.1 mini · hızlı',
    'claude-3-5-haiku-20241022': 'Claude Haiku 3.5 · hızlı',
    'claude-haiku-4-5-20251001': 'Claude Haiku 4.5 · hızlı',
    'gemini-1.5-flash': 'Gemini 1.5 Flash · hızlı',
    'gemini-2.0-flash': 'Gemini 2.0 Flash · hızlı',
    'llama-3.3-70b-versatile': 'Llama 3.3 70B (Groq) · çok hızlı',
    // Orta seviye — daha kaliteli, biraz daha yavaş.
    'qwen3-coder-next': 'Qwen 3 Coder',
    'qwen2.5-72b-instruct': 'Qwen 2.5 72B',
    'mistral-large-latest': 'Mistral Large',
    'glm-5.1': 'GLM 5.1',
    'kimi-k2.6': 'Kimi K2.6',
    'minimax-m2.7': 'MiniMax M2.7',
    // Yüksek kalite — yavaş ama isabetli.
    'gpt-4o': 'GPT-4o',
    'gpt-4.1': 'GPT-4.1',
    'claude-sonnet-4-6': 'Claude Sonnet 4.6',
    'gemini-1.5-pro': 'Gemini 1.5 Pro',
  };

  /// User-visible labels for the categories used to order the dropdown.
  static const llmGroupLabels = <String, String>{
    'fast': 'Hızlı',
    'mid': 'Orta',
    'pro': 'Kaliteli',
  };

  /// slug → group key, used by the Settings UI to render section headers.
  static const llmGroupOf = <String, String>{
    'gpt-4o-mini': 'fast',
    'gpt-4.1-mini': 'fast',
    'claude-3-5-haiku-20241022': 'fast',
    'claude-haiku-4-5-20251001': 'fast',
    'gemini-1.5-flash': 'fast',
    'gemini-2.0-flash': 'fast',
    'llama-3.3-70b-versatile': 'fast',
    'qwen3-coder-next': 'mid',
    'qwen2.5-72b-instruct': 'mid',
    'mistral-large-latest': 'mid',
    'glm-5.1': 'mid',
    'kimi-k2.6': 'mid',
    'minimax-m2.7': 'mid',
    'gpt-4o': 'pro',
    'gpt-4.1': 'pro',
    'claude-sonnet-4-6': 'pro',
    'gemini-1.5-pro': 'pro',
  };
}
