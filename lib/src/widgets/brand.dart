import 'package:flutter/material.dart';

import '../theme/wordnest_theme.dart';

/// The cream "W" letter tile with its gold sparkle.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34, this.sparkle = true});

  final double size;
  final bool sparkle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.3),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[AppColors.creamTop, Color(0xFFF4E6C8)],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.bevel,
                  offset: Offset(0, size * 0.09),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  offset: Offset(0, 6),
                  blurRadius: 12,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'W',
              style: AppText.quicksand(size * 0.58, color: const Color(0xFF12504B)),
            ),
          ),
          if (sparkle)
            Positioned(
              top: -size * 0.09,
              right: -size * 0.09,
              child: Container(
                width: size * 0.24,
                height: size * 0.24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: AppColors.gold, blurRadius: 9),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mark + "Wordnest." lockup.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.markSize = 34, this.textSize = 18});

  final double markSize;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BrandMark(size: markSize),
        SizedBox(width: markSize * 0.26),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: 'Wordnest',
                style: AppText.quicksand(
                  textSize,
                  color: AppColors.cream,
                  letterSpacing: -0.2,
                ),
              ),
              TextSpan(
                text: '.',
                style: AppText.quicksand(textSize, color: AppColors.gold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
