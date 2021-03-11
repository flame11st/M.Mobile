import 'dart:io';

import 'package:firebase_admob/firebase_admob.dart';

class AdManager {
  static bool bannerVisible = false;
  static BannerAd _bannerAd;
  static double currentOffset = 0;

  static Future<void> hideBanner() async {
    try {
      await _bannerAd.dispose();
    } catch (on){}

    _bannerAd = null;
    bannerVisible = false;
  }

  static Future<void> showBanner(double offset) async {
    if (!bannerVisible) {
      bannerVisible = true;
      currentOffset = offset;

      bannerAd
        ..load()
        ..show(anchorOffset: offset);
    }
  }

  static BannerAd get bannerAd {
    if (_bannerAd == null ) {
      _bannerAd = BannerAd(
        adUnitId: AdManager.bannerAdUnitId,
        size: AdSize.banner,
      );
    }

    return _bannerAd;
  }

  static String get appId {
    if (Platform.isAndroid) {
      return "ca-app-pub-5540129750283532~2399817888";
    } else if (Platform.isIOS) {
      return "";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-5540129750283532/9763657807";
    } else if (Platform.isIOS) {
      return "<YOUR_IOS_BANNER_AD_UNIT_ID>";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-5540129750283532/2008742121";
    } else if (Platform.isIOS) {
      return "<YOUR_IOS_INTERSTITIAL_AD_UNIT_ID>";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }
}