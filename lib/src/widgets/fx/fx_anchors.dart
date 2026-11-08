import 'package:flutter/material.dart';

/// A helper widget that provides alignment anchors for other FX widgets.
/// Exposes GlobalKeys for the coin pill and bonus words pill for fly-to-target animations.
class FxAnchors extends StatelessWidget {
  const FxAnchors({
    super.key,
    required this.child,
    this.coinPillKey,
    this.bonusWordsKey,
  });

  final Widget child;
  final GlobalKey? coinPillKey;
  final GlobalKey? bonusWordsKey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Wrap child with key-aware positions if keys provided
        if (coinPillKey != null || bonusWordsKey != null)
          _KeyPositions(
            coinPillKey: coinPillKey,
            bonusWordsKey: bonusWordsKey,
            child: child,
          ),
        if (coinPillKey == null && bonusWordsKey == null) child,
      ],
    );
  }
}

class _KeyPositions extends StatelessWidget {
  const _KeyPositions({
    this.coinPillKey,
    this.bonusWordsKey,
    required this.child,
  });

  final GlobalKey? coinPillKey;
  final GlobalKey? bonusWordsKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}