import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wordnest/src/services/purchase_service.dart';
import 'package:wordnest/src/state/player_state.dart';
import 'package:wordnest/src/theme/wordnest_theme.dart';
import 'package:wordnest/src/widgets/scenic_background.dart';
import 'package:wordnest/src/widgets/rewarded_offers.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.player});

  final PlayerState player;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  PurchaseService? _purchaseService;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      _purchaseService = PurchaseService();
      _initializePurchases();
    }
  }

  Future<void> _initializePurchases() async {
    try {
      await _purchaseService!.initialize(widget.player);
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Purchases are unavailable: $error');
    }
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
                      RewardedOffers(player: widget.player),
                      const SizedBox(height: 16),
                      _buildCoinPacksSection(),
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
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.cream),
            tooltip: 'Back',
          ),
          const Expanded(child: Text(
            'WordNest Shop',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          )),
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
                ListenableBuilder(
                  listenable: widget.player,
                  builder: (context, _) => Text(
                    '${widget.player.coins}',
                    style: AppText.label(12, weight: FontWeight.w700, color: AppColors.gold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchases are not available on this device.')),
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
          final purchases = _purchaseService;
          if (purchases?.isAvailable() ?? false) {
            await purchases!.buyProduct(productId);
            if (mounted) setState(() {});
          } else {
            _showPurchaseUnavailable();
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
                final purchases = _purchaseService;
                if (purchases?.isAvailable() ?? false) {
                  await purchases!.buyProduct(PurchaseService.removeAds);
                  if (mounted) setState(() {});
                } else {
                  _showPurchaseUnavailable();
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
                            'Remove Interruptive Ads',
                            style: AppText.quicksand(16, color: AppColors.cream),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Optional reward ads remain available',
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
            final purchases = _purchaseService;
            if (purchases?.isAvailable() ?? false) {
              await purchases!.restorePurchases();
              if (mounted) setState(() {});
            } else {
              _showPurchaseUnavailable();
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