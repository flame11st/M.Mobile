import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseState with ChangeNotifier {
  final storage = new FlutterSecureStorage();
  bool isPremium = false;

  PurchaseState() {
    initialSetPremium();
  }

  initialSetPremium() async {
    var storedPremiumValue;
    try{
      storedPremiumValue = await storage.read(key: 'isPremium');
    } catch(on, ex) {
      await clearStorage();
    }

    if (storedPremiumValue != null && storedPremiumValue.isNotEmpty) {
      var value = storedPremiumValue == 'true';

      setIsPremium(value);
    }

    if (!isPremium) await checkPurchase();
  }

  checkPurchase() async {
    final QueryPurchaseDetailsResponse response = await InAppPurchaseConnection.instance.queryPastPurchases();
    if (response.error != null) {
      return;
    }

    if (response.pastPurchases.isEmpty ||
        response.pastPurchases.first.productID != 'premium_purchase' ||
        response.pastPurchases.first.status != PurchaseStatus.purchased) return;

    if (isPremium != true) setIsPremium(true);
  }

  setIsPremium(bool value) async {
    if (value == isPremium) return;

    isPremium = value;

    notifyListeners();

    await storage.write(key: 'isPremium', value: isPremium.toString());
  }

  logout() async {
    await clearStorage();
    isPremium = false;
  }

  clearStorage() async {
    await storage.delete(key: 'isPremium');
  }
}