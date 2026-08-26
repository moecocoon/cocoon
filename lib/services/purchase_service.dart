import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  static const String starNightProductId =
      'cocoon_background_star_night';

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? starNightProduct;

  bool storeAvailable = false;
  bool starNightPurchased = false;

  Future<void> initialize() async {
    await _loadSavedPurchases();

    // WebではApple/Googleのアプリ内課金を使わない
    if (kIsWeb) {
      return;
    }

    storeAvailable = await _iap.isAvailable();

    if (!storeAvailable) {
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('purchaseStream error: $error');
      },
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails({
      starNightProductId,
    });

    if (response.error != null) {
      debugPrint(
        'queryProductDetails error: ${response.error}',
      );
      return;
    }

    if (response.productDetails.isNotEmpty) {
      starNightProduct = response.productDetails.first;
    }
  }

  Future<void> buyStarNight() async {
    final product = starNightProduct;

    if (product == null) {
      throw Exception('商品情報を取得できませんでした。');
    }

    final purchaseParam = PurchaseParam(
      productDetails: product,
    );

    await _iap.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  Future<void> restorePurchases() async {
    if (kIsWeb || !storeAvailable) return;

    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      if (purchase.productID != starNightProductId) {
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _unlockStarNight();
      }

      if (purchase.status == PurchaseStatus.error) {
        debugPrint(
          'purchase error: ${purchase.error}',
        );
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _unlockStarNight() async {
    starNightPurchased = true;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'purchased_star_night',
      true,
    );
  }

  Future<void> _loadSavedPurchases() async {
    final prefs = await SharedPreferences.getInstance();

    starNightPurchased =
        prefs.getBool('purchased_star_night') ?? false;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}