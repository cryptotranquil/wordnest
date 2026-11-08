import 'package:flutter/material.dart';

import '../theme/wordnest_theme.dart';
import 'scenic_background.dart';

/// One row inside the Today panel: icon, title, supporting field, action.
class TodayRow extends StatelessWidget {
  const TodayRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
    this.iconTint,
    this.detailHighlight,
    this.solidAction = false,
    this.actionEnabled = true,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? detailHighlight;
  final String actionLabel;
  final VoidCallback onAction;
  final Color? iconTint;
  final bool solidAction;
  final bool actionEnabled;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07)))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: (iconTint ?? AppColors.tealLift).withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 18, color: iconTint ?? AppColors.tealLift),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppText.label(13, weight: 700)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      if (detailHighlight != null)
                        TextSpan(
                          text: detailHighlight,
                          style: AppText.label(11, weight: 600, color: const Color(0xFFBFE9E3)),
                        ),
                      TextSpan(
                        text: detail,
                        style: AppText.label(11, weight: 500, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActionChip(
            label: actionLabel,
            solid: solidAction,
            enabled: actionEnabled,
            onTap: onAction,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.solid,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool solid;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: solid
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[AppColors.goldLight, AppColors.gold],
                  )
                : null,
            color: solid ? null : Colors.white.withValues(alpha: 0.06),
            border: solid
                ? null
                : Border.all(color: Colors.white.withValues(alpha: enabled ? 0.16 : 0.08)),
            boxShadow: solid
                ? const <BoxShadow>[
                    BoxShadow(color: Color(0x4DF5B83D), offset: Offset(0, 3), blurRadius: 10),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppText.label(
              11.5,
              weight: 700,
              color: solid
                  ? AppColors.goldInk
                  : (enabled ? AppColors.text : AppColors.muted),
            ),
          ),
        ),
      ),
    );
  }
}

/// The single "Today" panel from the home screen.
class TodayPanel extends StatelessWidget {
  const TodayPanel({
    super.key,
    required this.rows,
    this.footer,
  });

  final List<Widget> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: AppMetrics.panelRadius,
      color: const Color(0x9E0A1C20),
      blur: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Today', style: AppText.quicksand(15, color: AppColors.cream)),
                Text(
                  'Resets in 6h',
                  style: AppText.label(10.5, weight: 600, color: AppColors.muted),
                ),
              ],
            ),
          ),
          ...rows,
          ?footer,
        ],
      ),
    );
  }
}
