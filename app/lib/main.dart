import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config.dart';
import 'core/router.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  // Load user-overridden API base URL (Settings → Sunucu) so the same APK
  // works against any backend deployment without rebuilding.
  await AppConfig.hydrate();
  // Hydrate stored auth tokens so the router can decide whether to show /login.
  // We do NOT eagerly call /auth/refresh here — that would log the user out
  // if the network is briefly unavailable on cold start. The dio interceptor
  // refreshes lazily on the first 401 from any real request.
  await ApiClient.instance.hydrate();
  final onboarded = await hasOnboarded();
  runApp(ProviderScope(child: EvimizApp(showOnboarding: !onboarded)));
}

class EvimizApp extends ConsumerWidget {
  final bool showOnboarding;
  const EvimizApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always run in light mode — keeps T.cream / T.ink consistent with all
    // hand-rolled widgets that read T directly.
    T.applyLight();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    final router = buildRouter(ref, showOnboarding: showOnboarding);
    return MaterialApp.router(
      title: 'Evimiz',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
