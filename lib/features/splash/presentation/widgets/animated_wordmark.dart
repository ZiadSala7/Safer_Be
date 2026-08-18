import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

part 'animated_mark.dart';
part 'logo_layer.dart';

class AnimatedWordmark extends StatelessWidget {
  const AnimatedWordmark({
    required this.progress,
    required this.asset,
    required this.darkBackground,
    super.key,
  });

  final double progress;
  final String asset;
  final bool darkBackground;

  @override
  Widget build(BuildContext context) {
    final arabic = asset == AppAssets.logoAr;
    final markIn = _animate(0, .12, Curves.easeOutCubic);
    final markOut = _animate(.19, .30, Curves.easeInCubic);
    final first = _animate(.22, .47, Curves.easeOutCubic);
    final second = _animate(.46, .66, Curves.easeOutCubic);
    final tagline = _animate(.65, .78, Curves.easeOut);
    final fade = 1 - _animate(.92, 1, Curves.easeIn);
    final width = math.min(MediaQuery.sizeOf(context).width * .76, 300.0);

    return Semantics(
      label: 'Safer Be',
      image: true,
      child: Opacity(
        opacity: fade,
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: arabic ? 699 / 357 : 588 / 338,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: _AnimatedMark(
                    enter: markIn,
                    exit: markOut,
                    darkBackground: darkBackground,
                  ),
                ),
                _LogoLayer(
                  asset: asset,
                  clip: _firstWordClip(arabic, first),
                  opacity: first,
                  offset: Offset((1 - first) * (arabic ? 10 : -10), 0),
                ),
                _LogoLayer(
                  asset: asset,
                  clip: _secondWordClip(arabic, second),
                  opacity: second,
                  offset: Offset((1 - second) * (arabic ? -14 : 14), 0),
                ),
                _LogoLayer(
                  asset: asset,
                  clip: Rect.fromLTRB(0, arabic ? .71 : .68, 1, 1),
                  opacity: tagline,
                  offset: Offset(0, (1 - tagline) * 6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Rect _firstWordClip(bool arabic, double value) => arabic
      ? Rect.fromLTRB(1 - (.70 * value), 0, 1, .71)
      : Rect.fromLTRB(0, 0, .69 * value, .66);

  Rect _secondWordClip(bool arabic, double value) => arabic
      ? Rect.fromLTRB(0, 0, .42 * value, .71)
      : Rect.fromLTRB(.62, 0, .62 + (.38 * value), .66);

  double _animate(double begin, double end, Curve curve) =>
      curve.transform(((progress - begin) / (end - begin)).clamp(0.0, 1.0));
}
