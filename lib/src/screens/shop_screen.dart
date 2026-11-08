import 'package:flutter/material.dart';
import 'package:wordnest/src/services/ad_service.dart';
import 'package:wordnest/src/services/purchase_service.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';
import 'package:wordnest/src/widgets/scenic_background.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.player});

  final PlayerState player;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late PurchaseService _purchaseService;
  late AdService _adService;
  int _hintCharges = 3;
  DateTime? _lastHintRefill;

  @override
  void initState() {
    super.initState();
    _purchaseService = PurchaseService();
    _adService = AdService();
    _purchaseService.initialize(widget.player);
    _calculateHintCharges();
  }

  void _calculateHintCharges() {
    final now = DateTime.now();
    if (_lastHintRefill == null) {
      _lastHintRefill = now;
      _hintCharges = 3;
    } else {
      final difference = now.difference(_lastHintRefill!);
      final hoursPassed = difference.inHours;
      _hintCharges = (_hintCharges + (hoursPassed ~/ 2)).clamp(0, 3);
      if (hoursPassed >= 2) {
        _lastHintRefill = now;
      }
    }
  }

  Future<void> _showRewardedAd() async {
    await _adService.showRewardedAd(onReward: () {
      setState(() {
        widget.player.addHints(3);
        _hintCharges = 0;
        _lastHintRefill = DateTime.now();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ScenicBackground(scrim: SceneScrim.home),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCoinPacksSection(),
                      _buildHintBoostSection(),
                      _buildRemoveAdsSection(),
                      _buildRestorePurchasesSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'WordNest Shop',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.glassLine.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.spa_rounded,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.player.coins}',
                  style: AppText.label(12, weight: FontWeight.w700, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinPacksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Coin Packs',
            style: AppText.label(14, weight: FontWeight.w700, color: AppColors.teal),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassLine.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildCoinPackItem(
                title: '500 Coins',
                price: '5.99',
                productId: PurchaseService.coins500,
              ),
              _buildCoinPackItem(
                title: '1500 Coins',
                price: '12.99',
                productId: PurchaseService.coins1500,
              ),
              _buildCoinPackItem(
                title: '4000 Coins + 5 Hints',
                price: '24.99',
                productId: PurchaseService.coins4000Hints5,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoinPackItem({
    required String title,
    required String price,
    required String productId,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (_purchaseService.isAvailable()) {
            await _purchaseService.buyProduct(productId);
            setState(() {});
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monetization_on_rounded,
                  size: 24,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.quicksand(16, color: AppColors.cream),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: AppText.label(14, weight: FontWeight.w700, color: AppColors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintBoostSection() {
    _calculateHintCharges();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Zen Focus Clip',
            style: AppText.label(14, weight: FontWeight.w700, color: AppColors.teal),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassLine.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        size: 24,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Double with Zen Spark',
                            style: AppText.quicksand(18, color: AppColors.cream),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Watch an ad to get +3 hints (max 3 charges)',
                            style: AppText.label(12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(3, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            index < _hintCharges ? Icons.circle : Icons.circle_outlined,
                            size: 16,
                            color: index < _hintCharges ? AppColors.teal : AppColors.muted,
                          ),
                        );
                      }),
                    ),
                    ElevatedButton(
                      onPressed: _hintCharges < 3 ? _showRewardedAd : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Watch Ad',
                        style: AppText.label(12, weight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemoveAdsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'WordNest Perks',
            style: AppText.label(14, weight: FontWeight.w700, color: AppColors.teal),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassLine.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                if (_purchaseService.isAvailable()) {
                  await _purchaseService.buyProduct(PurchaseService.removeAds);
                  setState(() {});
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.remove_red_eye_rounded,
                        size: 24,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remove All Ads',
                            style: AppText.quicksand(16, color: AppColors.cream),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Includes 500 bonus coins',
                            style: AppText.label(12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '19.99',
                      style: AppText.label(14, weight: FontWeight.w700, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestorePurchasesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Center(
        child: TextButton(
          onPressed: () async {
            if (_purchaseService.isAvailable()) {
              await _purchaseService.restorePurchases();
              setState(() {});
            }
          },
          child: Text(
            'Restore Purchases',
            style: AppText.label(14, color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}