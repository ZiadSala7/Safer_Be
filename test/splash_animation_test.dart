import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safer_be_project/core/constants/app_assets.dart';
import 'package:safer_be_project/features/splash/presentation/widgets/animated_wordmark.dart';
import 'package:safer_be_project/features/splash/presentation/widgets/splash_atmosphere.dart';

void main() {
  testWidgets('splash stages render safely in light and dark modes', (
    tester,
  ) async {
    for (final dark in [false, true]) {
      for (final progress in [0.0, .12, .3, .52, .7, .82, .96]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  SplashAtmosphere(progress: progress, isDark: dark),
                  Center(
                    child: AnimatedWordmark(
                      progress: progress,
                      asset: AppAssets.logoEn,
                      darkBackground: dark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
