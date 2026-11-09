import 'package:flutter/material.dart';

import '../theme/wordnest_theme.dart';

/// Colours used by the "clean" tab screens (Chapters, Missions, Settings).
/// They sit on top of [AppColors] and match the Stitch/Kombai mockups.
abstract final class PanelColors {
  static const Color bgTop = Color(0xFF12292C);
  static const Color bgBottom = Color(0xFF071719);
  static const Color card = Color(0xFF14302F);
  static const Color cardLine = Color(0x14FFFFFF);
  static const Color tile = Color(0xFF1F403F);
  static const Color pill = Color(0xFF1C3A3A);
  static const Color track = Color(0xFF263F40);
  static const Color divider = Color(0x0FFFFFFF);
}

/// Flat dark teal gradient used behind the tab screens. No images, so it can
/// never 404 and it is cheap to paint.
class PanelBackdrop extends StatelessWidget {
  const PanelBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[PanelColors.bgTop, PanelColors.bgBottom],
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

/// Keeps phone-shaped screens readable when the app runs in a wide browser
/// window (Flutter web / desktop). On a real phone this is a no-op.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Rounded pill used in headers: "Resets in 4h 28m", "WordNest", "Ch. 2 · 24/60".
class HeaderPill extends StatelessWidget {
  const HeaderPill({
    super.key,
    required this.label,
    this.icon,
    this.iconColor = AppColors.teal,
    this.labelColor = AppColors.cream,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: PanelColors.pill,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: AppText.label(13, weight: 600, color: labelColor),
          ),
        ],
      ),
    );
    if (onTap == null) return body;
    return GestureDetector(onTap: onTap, child: body);
  }
}

/// Big screen title with an optional pill on the right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                style: AppText.quicksand(
                  30,
                  weight: 700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Rounded card surface.
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 24,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: PanelColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: PanelColors.cardLine),
      ),
      child: child,
    );
  }
}

/// Rounded-square icon tile used on every row.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 46,
    this.color = AppColors.teal,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PanelColors.tile,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Thin rounded progress bar. [value] is 0..1.
class SlimProgress extends StatelessWidget {
  const SlimProgress({
    super.key,
    required this.value,
    this.height = 6,
    this.gradient,
    this.color = AppColors.teal,
  });

  final double value;
  final double height;
  final Gradient? gradient;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double v = value.isNaN ? 0 : value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: ColoredBox(color: PanelColors.track)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: gradient == null ? color : null,
                  gradient: gradient,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
