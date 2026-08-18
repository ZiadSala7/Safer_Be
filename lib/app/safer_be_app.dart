import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import 'app_controller.dart';

class SaferBeApp extends StatefulWidget {
  const SaferBeApp({this.controller, super.key});

  final AppController? controller;

  @override
  State<SaferBeApp> createState() => _SaferBeAppState();
}

class _SaferBeAppState extends State<SaferBeApp> {
  late final AppController controller = widget.controller ?? AppController();
  late final bool ownsController = widget.controller == null;
  late final Future<void> initialization = controller.initialize();

  @override
  void dispose() {
    if (ownsController) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          final dark =
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
          return ColoredBox(
            color: dark ? const Color(0xFF071A33) : const Color(0xFFF3F7FB),
          );
        }
        return AppControllerScope(
          notifier: controller,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) => context.tr('appName'),
              theme: AppTheme.light(controller.locale),
              darkTheme: AppTheme.dark(controller.locale),
              themeMode: controller.themeMode,
              locale: controller.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const SplashPage(),
            ),
          ),
        );
      },
    );
  }
}
