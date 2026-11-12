import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../state/player_state.dart';
import '../theme/wordnest_theme.dart';

/// Optional ads for two distinct rewards. Used in both the shop and the
/// insufficient-resources sheet, so neither requires spending coins first.
class RewardedOffers extends StatefulWidget {
  const RewardedOffers({super.key, required this.player, this.ads});

  final PlayerState player;
  final RewardedAdGateway? ads;

  @override
  State<RewardedOffers> createState() => _RewardedOffersState();
}

enum _RewardChoice { hint, coins }

class _RewardedOffersState extends State<RewardedOffers> {
  bool _busy = false;
  String? _message;
  RewardedAdGateway get _ads => widget.ads ?? AdService();

  Future<void> _watch(_RewardChoice choice) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final player = widget.player;
    var earned = false;
    RewardedAdResult result;
    try {
      result = await _ads.showRewardedAd(canShow: () => mounted, onReward: () {
        // Guard against duplicate SDK callbacks, even if this widget is gone.
        if (earned) return;
        earned = true;
        if (choice == _RewardChoice.hint) {
          player.addHints(1);
        } else {
          player.addCoins(100);
        }
      });
    } catch (_) {
      result = RewardedAdResult.failed;
    }
    if (!mounted) return;
    final message = earned
        ? choice == _RewardChoice.hint ? 'You earned 1 hint.' : 'You earned 100 coins.'
        : switch (result) {
            RewardedAdResult.dismissed => 'Ad closed before the reward was earned.',
            RewardedAdResult.unsupported => 'Rewarded ads are available on Android and iOS only.',
            RewardedAdResult.busy => 'An ad is already in progress.',
            _ => 'No rewarded ad is available right now. Please try again later.',
          };
    setState(() {
      _busy = false;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final supported = _ads.isSupported;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Earn free rewards', style: AppText.label(14, weight: 700, color: AppColors.teal)),
      const SizedBox(height: 8),
      Text(
        supported
            ? 'Choose a reward and finish one ad to earn it.'
            : 'Rewarded ads are available in the Android and iOS app, not in the browser.',
        style: AppText.label(12, color: AppColors.muted, weight: 500),
      ),
      const SizedBox(height: 10),
      _offer(
        icon: Icons.lightbulb_outline_rounded,
        title: '1 hint',
        subtitle: 'Watch one ad for 1 hint',
        onPressed: supported && !_busy ? () => _watch(_RewardChoice.hint) : null,
      ),
      const SizedBox(height: 8),
      _offer(
        icon: Icons.monetization_on_outlined,
        title: '100 coins',
        subtitle: 'Watch one ad for 100 coins',
        onPressed: supported && !_busy ? () => _watch(_RewardChoice.coins) : null,
      ),
      if (_busy || _message != null) ...[
        const SizedBox(height: 8),
        Semantics(liveRegion: true, child: Text(
          _busy ? 'Opening ad…' : _message!,
          style: AppText.label(11, color: AppColors.muted),
        )),
      ],
    ]);
  }

  Widget _offer({required IconData icon, required String title, required String subtitle, required VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF123130), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Icon(icon, color: AppColors.teal, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppText.quicksand(16, weight: 700)),
          const SizedBox(height: 3),
          Text(subtitle, style: AppText.label(11, color: AppColors.muted, weight: 500)),
        ])),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onPressed,
          clipBehavior: Clip.antiAlias,
          style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: Text('Watch ad', style: AppText.label(11, color: onPressed == null ? AppColors.muted : AppColors.ink)),
        ),
      ]),
    );
  }
}
