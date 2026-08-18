part of 'animated_wordmark.dart';

class _LogoLayer extends StatelessWidget {
  const _LogoLayer({
    required this.asset,
    required this.clip,
    required this.opacity,
    required this.offset,
  });

  final String asset;
  final Rect clip;
  final double opacity;
  final Offset offset;

  @override
  Widget build(BuildContext context) => ClipRect(
    clipper: _FractionalRectClipper(clip),
    child: Opacity(
      opacity: opacity.clamp(0, 1),
      child: Transform.translate(
        offset: offset,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    ),
  );
}

class _FractionalRectClipper extends CustomClipper<Rect> {
  const _FractionalRectClipper(this.rect);

  final Rect rect;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    rect.left * size.width,
    rect.top * size.height,
    rect.right * size.width,
    rect.bottom * size.height,
  );

  @override
  bool shouldReclip(covariant _FractionalRectClipper oldClipper) =>
      oldClipper.rect != rect;
}
