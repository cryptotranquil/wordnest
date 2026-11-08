import 'package:flutter/material.dart';

import '../theme/wordnest_theme.dart';
import 'scenic_background.dart';

/// Round glass booster (Hint, Target) with its coin price underneath.
/// Shows owned token count badge when player has tokens, hiding the coin price.
class BoosterButton extends StatelessWidget {
  const BoosterButton({
    super.key,
    required this.icon,
    required this.cost,
    required this.onTap,
    this.label,
    this.enabled = true,
    this.tokenCount = 0,
  });

  final IconData icon;
  final int cost;
  final VoidCallback onTap;
  final String? label;
  final bool enabled;
  final int tokenCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${label ?? 'Booster'}${tokenCount > 0 ? ', $tokenCount tokens available' : ', costs $cost coins'}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              _Pressable(
                onTap: onTap,
                child: Glass(
                  width: AppMetrics.boosterSize,
                  height: AppMetrics.boosterSize,
                  radius: AppMetrics.boosterSize / 2,
                  color: AppColors.glass,
                  shadows: const <BoxShadow>[
                    BoxShadow(color: Color(0x61000000), offset: Offset(0, 6), blurRadius: 18),
                  ],
                  child: Center(
                    child: Icon(
                      icon,
                      size: 22,
                      color: enabled ? AppColors.cream : AppColors.muted,
                    ),
                  ),
                ),
              ),
              if (tokenCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        '$tokenCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (tokenCount <= 0)
            Text(
              '$cost',
              style: AppText.label(10.5, weight: 700, color: const Color(0xFFFFD790)),
            ),
        ],
      ),
    );
  }
}

/// Teal gradient call to action.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.height = 52,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.tealBright, Color(0xFF0C6B63)],
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x57066860), offset: Offset(0, 12), blurRadius: 26),
            BoxShadow(
              color: Color(0x38FFFFFF),
              offset: Offset(0, -1),
              blurRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              style: AppText.label(14.5, weight: 700, color: const Color(0xFFF2FFFD)),
            ),
            if (icon != null) ...<Widget>[
              const SizedBox(width: 9),
              Icon(icon, size: 18, color: const Color(0xFFF2FFFD)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Quiet companion to [PrimaryButton].
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.restart_alt_rounded,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 16, color: AppColors.text),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppText.label(13, weight: 600)),
          ],
        ),
      ),
    );
  }
}

/// Speed / Mastery / Lexicon medal.
class StarBadge extends StatelessWidget {
  const StarBadge({
    super.key,
    required this.label,
    required this.earned,
  });

  final String label;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: earned ? null : Colors.white.withValues(alpha: 0.06),
            gradient: earned
                ? const RadialGradient(
                    center: Alignment(-0.24, -0.44),
                    colors: <Color>[Color(0xFFFFE1A1), AppColors.gold, AppColors.goldDeep],
                    stops: <double>[0, 0.62, 1],
                  )
                : null,
            border: earned ? null : Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: earned
                ? const <BoxShadow>[
                    BoxShadow(color: Color(0x57F5B83D), offset: Offset(0, 6), blurRadius: 16),
                  ]
                : null,
          ),
          child: Icon(
            Icons.star_rounded,
            size: 26,
            color: earned ? const Color(0xFF7A4D00) : Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppText.label(
            11,
            weight: earned ? 700 : 600,
            color: earned ? AppColors.cream : AppColors.muted,
          ),
        ),
      ],
    );
  }
}

/// Small press-feedback wrapper; keeps hover/press behaviour consistent.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}
