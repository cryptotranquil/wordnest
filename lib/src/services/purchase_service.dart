import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wordnest/src/state/player_state.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late PlayerState _player;
  bool _isAvailable = false;

  // Product IDs
  static const String coins500 = 'coins_500';
  static const String coins1500 = 'coins_1500';
  static const String coins4000Hints5 = 'coins_4000_hints5';
  static const String removeAds = 'remove_ads';

  Future<void> initialize(PlayerState player) async {
    _player = player;
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      await _initializeProducts();
      _listenToPurchaseUpdates();
    }
  }

  Future<void> _initializeProducts() async {
    const Set<String> productIds = <String>{
      coins500,
      coins1500,
      coins4000Hints5,
      removeAds,
    };

    final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
    if (response.notFoundIDs.isNotEmpty) {
      // Handle the error.
    }
  }

  void _listenToPurchaseUpdates() {
    final purchaseStream = _iap.purchaseStream;
    purchaseStream.listen((purchaseDetailsList) {
      _handlePurchaseUpdate(purchaseDetailsList);
    }, onDone: () {
      _listenToPurchaseUpdates();
    }, onError: (error) {
      // Handle error
    });
  }

  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        await _deliverProduct(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        await _deliverProduct(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    switch (purchaseDetails.productID) {
      case coins500:
        _player.addCoins(500);
        break;
      case coins1500:
        _player.addCoins(1500);
        break;
      case coins4000Hints5:
        _player.addCoins(4000);
        _player.addHints(5);
        break;
      case removeAds:
        _player.setRemoveAds(true);
        _player.addCoins(500);
        break;
    }
  }

  Future<void> buyProduct(String productId) async {
    if (!_isAvailable) return;

    final ProductDetailsResponse response = await _iap.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty) {
      // Handle the error.
      return;
    }

    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _iap.restorePurchases();
  }

  bool isAvailable() => _isAvailable;
}