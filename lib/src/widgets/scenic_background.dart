import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/wordnest_theme.dart';

/// Colour recipe for one chapter's painted landscape.
class ScenePalette {
  const ScenePalette({
    required this.sky,
    required this.skyStops,
    required this.ridgeFar,
    required this.ridgeMid,
    required this.waterTop,
    required this.waterBottom,
    required this.glow,
    required this.horizon,
    required this.pine,
    required this.mist,
    this.glowCenter = const Offset(0.5, 0.51),
    this.glowRadius = 0.55,
    this.horizonY = 0.536,
  });

  final List<Color> sky;
  final List<double> skyStops;
  final Color ridgeFar;
  final Color ridgeMid;
  final Color waterTop;
  final Color waterBottom;
  final Color glow;
  final Color horizon;
  final Color pine;
  final Color mist;
  final Offset glowCenter;
  final double glowRadius;
  final double horizonY;

  /// Chapter 2 — the canvas default: moonlit ridge over still water.
  static const mistyLake = ScenePalette(
    sky: <Color>[
      Color(0xFF04141A),
      Color(0xFF0A2B31),
      Color(0xFF124044),
      Color(0xFF0B2B31),
      Color(0xFF061A20),
      Color(0xFF03101A),
    ],
    skyStops: <double>[0, 0.34, 0.52, 0.62, 0.72, 1],
    ridgeFar: Color(0xFF0E343B),
    ridgeMid: Color(0xFF0A282F),
    waterTop: Color(0xFF0A2B30),
    waterBottom: Color(0xFF03121A),
    glow: Color(0x8CFFEEC2),
    horizon: Color(0xFFC9F2EA),
    pine: Color(0xFF04161C),
    mist: Color(0xFFBFF0E7),
  );

  /// Splash — a little cooler and softer than gameplay.
  static const dawn = ScenePalette(
    sky: <Color>[
      Color(0xFF04141A),
      Color(0xFF0B2D34),
      Color(0xFF1A4B4C),
      Color(0xFF123437),
      Color(0xFF071C22),
      Color(0xFF03101A),
    ],
    skyStops: <double>[0, 0.30, 0.46, 0.56, 0.72, 1],
    ridgeFar: Color(0xFF12383C),
    ridgeMid: Color(0xFF08232A),
    waterTop: Color(0xFF0B2C31),
    waterBottom: Color(0xFF02101A),
    glow: Color(0x4D9FF3E8),
    horizon: Color(0xFF9FF3E8),
    pine: Color(0xFF031319),
    mist: Color(0xFFC9F2EA),
    glowCenter: Offset(0.5, 0.39),
    glowRadius: 0.62,
    horizonY: 0.512,
  );

  /// Direction B / C alternate grade, kept for the variant screens.
  static const dusk = ScenePalette(
    sky: <Color>[
      Color(0xFF04121C),
      Color(0xFF0A2436),
      Color(0xFF153B4C),
      Color(0xFF2C5560),
      Color(0xFF0D2733),
      Color(0xFF03101A),
    ],
    skyStops: <double>[0, 0.28, 0.44, 0.52, 0.60, 1],
    ridgeFar: Color(0xFF1D4A56),
    ridgeMid: Color(0xFF0A2330),
    waterTop: Color(0xFF12303C),
    waterBottom: Color(0xFF020E17),
    glow: Color(0x8CFFD9A0),
    horizon: Color(0xFFFFCF94),
    pine: Color(0xFF03121A),
    mist: Color(0xFF9FD8E6),
    glowCenter: Offset(0.61, 0.48),
    glowRadius: 0.42,
    horizonY: 0.51,
  );

  static const night = ScenePalette(
    sky: <Color>[
      Color(0xFF030914),
      Color(0xFF0A1426),
      Color(0xFF17253B),
      Color(0xFF111C31),
      Color(0xFF091321),
      Color(0xFF020812),
    ],
    skyStops: <double>[0, 0.28, 0.44, 0.56, 0.72, 1],
    ridgeFar: Color(0xFF17243A),
    ridgeMid: Color(0xFF0B1425),
    waterTop: Color(0xFF101A2D),
    waterBottom: Color(0xFF020812),
    glow: Color(0x6B9BB9FF),
    horizon: Color(0xFFA8BFEA),
    pine: Color(0xFF020812),
    mist: Color(0xFF9FB5D9),
    glowCenter: Offset(0.65, 0.43),
    glowRadius: 0.44,
    horizonY: 0.51,
  );
}

/// Where the dark veil sits over the landscape.
enum SceneScrim { gameplay, home, splash, sheet }

/// Full-bleed painted scenery: sky, moon glow, layered ridges, pines and the
/// lake. Painted rather than shipped as a photo so it stays crisp at any size.
class ScenicBackground extends StatelessWidget {
  const ScenicBackground({
    super.key,
    this.palette = ScenePalette.mistyLake,
    this.scrim = SceneScrim.gameplay,
  });

  final ScenePalette palette;
  final SceneScrim scrim;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(painter: _ScenePainter(palette)),
          DecoratedBox(decoration: BoxDecoration(gradient: _scrimGradient())),
        ],
      ),
    );
  }

  LinearGradient _scrimGradient() {
    switch (scrim) {
      case SceneScrim.gameplay:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xDB041116),
            Color(0x57051A1B),
            Color(0x6B05161A),
            Color(0xDB040F14),
            Color(0xF5030C11),
          ],
          stops: <double>[0, 0.16, 0.52, 0.88, 1],
        );
      case SceneScrim.home:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xD1041116),
            Color(0x4D06181D),
            Color(0x6B05161A),
            Color(0xEB040F14),
          ],
          stops: <double>[0, 0.22, 0.55, 0.9],
        );
      case SceneScrim.splash:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0x2E061A1E),
            Color(0xB804101B),
            Color(0xEB030B10),
          ],
          stops: <double>[0, 0.62, 1],
        );
      case SceneScrim.sheet:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0x75041116),
            Color(0x1F05161A),
            Color(0x47040F14),
          ],
          stops: <double>[0, 0.34, 1],
        );
    }
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.palette);

  final ScenePalette palette;

  // Ridge crests in unit space (x, y) sampled from the canvas artwork.
  static const List<Offset> _farCrest = <Offset>[
    Offset(0, 0.381), Offset(0.113, 0.346), Offset(0.221, 0.377),
    Offset(0.328, 0.336), Offset(0.451, 0.374), Offset(0.549, 0.344),
    Offset(0.672, 0.379), Offset(0.785, 0.351), Offset(0.897, 0.381),
    Offset(1, 0.358),
  ];

  static const List<Offset> _midCrest = <Offset>[
    Offset(0, 0.433), Offset(0.097, 0.405), Offset(0.210, 0.431),
    Offset(0.318, 0.398), Offset(0.431, 0.433), Offset(0.528, 0.408),
    Offset(0.646, 0.438), Offset(0.759, 0.412), Offset(0.877, 0.441),
    Offset(1, 0.415),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky.
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, h),
          palette.sky,
          palette.skyStops,
        ),
    );

    // Chapter light pool behind the board.
    final glowCenter = Offset(
      palette.glowCenter.dx * w,
      palette.glowCenter.dy * h,
    );
    canvas.drawCircle(
      glowCenter,
      palette.glowRadius * w,
      Paint()
        ..shader = ui.Gradient.radial(glowCenter, palette.glowRadius * w, <Color>[
          palette.glow,
          palette.glow.withValues(alpha: 0.08),
          palette.glow.withValues(alpha: 0),
        ], <double>[0, 0.45, 1]),
    );

    // Ridges.
    canvas.drawPath(
      _ridge(size, _farCrest, palette.horizonY + 0.06),
      Paint()..color = palette.ridgeFar.withValues(alpha: 0.9),
    );
    canvas.drawPath(
      _ridge(size, _midCrest, palette.horizonY + 0.075),
      Paint()..color = palette.ridgeMid,
    );

    // Haze across the shoreline.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * (palette.horizonY - 0.06)),
        width: w * 1.2,
        height: h * 0.07,
      ),
      Paint()
        ..color = palette.mist.withValues(alpha: 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // Water.
    final horizonY = h * palette.horizonY;
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, w, h - horizonY),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, horizonY),
          Offset(0, h),
          <Color>[palette.waterTop, palette.waterBottom],
        ),
    );

    // Reflection of the chapter light on the water.
    final reflectX = glowCenter.dx;
    canvas.drawRect(
      Rect.fromLTWH(reflectX - w * 0.07, horizonY, w * 0.14, h * 0.36),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, horizonY),
          Offset(0, horizonY + h * 0.36),
          <Color>[
            palette.horizon.withValues(alpha: 0.26),
            palette.horizon.withValues(alpha: 0),
          ],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(reflectX, horizonY + h * 0.045),
        width: w * 0.2,
        height: h * 0.014,
      ),
      Paint()
        ..color = palette.horizon.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Water haze bands.
    for (final y in <double>[0.05, 0.12, 0.2]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, horizonY + h * y),
          width: w * 1.1,
          height: h * 0.03,
        ),
        Paint()
          ..color = palette.mist.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    // Pine groves framing the left and right edges.
    const groves = <List<double>>[
      <double>[0.00, 0.435, 0.085, 0.100],
      <double>[0.061, 0.452, 0.072, 0.083],
      <double>[0.120, 0.464, 0.061, 0.071],
      <double>[0.169, 0.482, 0.046, 0.053],
      <double>[0.795, 0.470, 0.056, 0.065],
      <double>[0.846, 0.452, 0.072, 0.083],
      <double>[0.908, 0.464, 0.061, 0.071],
      <double>[0.957, 0.476, 0.051, 0.059],
    ];
    for (final grove in groves) {
      _pine(canvas, w, h, grove[0], grove[1], grove[2], grove[3]);
    }
  }

  Path _ridge(Size size, List<Offset> crest, double bottom) {
    final path = Path()
      ..moveTo(0, crest.first.dy * size.height);
    for (final point in crest.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    path
      ..lineTo(size.width, bottom * size.height)
      ..lineTo(0, bottom * size.height)
      ..close();
    return path;
  }

  void _pine(Canvas canvas, double w, double h, double x, double baseY,
      double width, double height) {
    final left = x * w;
    final base = baseY * h;
    final pw = width * w;
    final ph = height * h;
    final path = Path()
      ..moveTo(left + pw / 2, base - ph)
      ..lineTo(left + pw * 0.82, base - ph * 0.72)
      ..lineTo(left + pw * 0.64, base - ph * 0.72)
      ..lineTo(left + pw * 0.94, base - ph * 0.42)
      ..lineTo(left + pw * 0.70, base - ph * 0.42)
      ..lineTo(left + pw, base - ph * 0.06)
      ..lineTo(left, base - ph * 0.06)
      ..lineTo(left + pw * 0.30, base - ph * 0.42)
      ..lineTo(left + pw * 0.06, base - ph * 0.42)
      ..lineTo(left + pw * 0.36, base - ph * 0.72)
      ..lineTo(left + pw * 0.18, base - ph * 0.72)
      ..close();
    canvas.drawPath(path, Paint()..color = palette.pine);
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// Frosted glass surface used by every capsule, panel and sheet.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 18,
    this.color = AppColors.glass,
    this.borderColor = AppColors.glassLine,
    this.blur = 16,
    this.padding = EdgeInsets.zero,
    this.height,
    this.width,
    this.borderRadius,
    this.shadows,
  });

  final Widget child;
  final double radius;
  final Color color;
  final Color borderColor;
  final double blur;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final effective = borderRadius ?? BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: effective,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: effective,
            border: Border.all(color: borderColor),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}
