import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static bool bannerVisible = false;
  static BannerAd _bannerAd;
  static BannerAd _settingsBannerAd;
  static BannerAd _itemExpandedBannerAd;
  static BannerAd _listsBannerAd;
  static BannerAd _listBannerAd;
  static BannerAd _searchBannerAd;
  static bool bannersReady = false;

  static Future<void> hideBanner() async {
    try {
      await _bannerAd.dispose();
    } catch (on){}

    _bannerAd = null;
    _settingsBannerAd = null;
    _itemExpandedBannerAd = null;
    bannerVisible = false;
    bannersReady = false;
  }

  static Future<void> showBanner() async {
    if (!bannerVisible) {
      bannerVisible = true;

      await bannerAd.load();
      await settingsBannerAd.load();
      await itemExpandedBannerAd.load();
      await listsBannerAd.load();
      await listBannerAd.load();
      await searchBannerAd.load();

      bannersReady = true;
    }
  }

  static BannerAd get bannerAd {
    if (_bannerAd == null ) {
      _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: BannerAd.testAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _bannerAd;
  }

  static BannerAd get itemExpandedBannerAd {
    if (_itemExpandedBannerAd == null ) {
      _itemExpandedBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: BannerAd.testAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _itemExpandedBannerAd;
  }

  static BannerAd get settingsBannerAd {
    if (_settingsBannerAd == null ) {
      _settingsBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: BannerAd.testAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _settingsBannerAd;
  }

  static BannerAd get listsBannerAd {
    if (_listsBannerAd == null ) {
      _listsBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: BannerAd.testAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _listsBannerAd;
  }

  static BannerAd get listBannerAd {
    if (_listBannerAd == null ) {
      _listBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: BannerAd.testAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _listBannerAd;
  }

  static BannerAd get searchBannerAd {
    if (_searchBannerAd == null ) {
      _searchBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: AdManager.bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _searchBannerAd;
  }

  static String get appId {
    if (Platform.isAndroid) {
      return "ca-app-pub-5540129750283532~2399817888";
    } else if (Platform.isIOS) {
      return "ca-app-pub-5540129750283532~9895592468";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-5540129750283532/9763657807";
    } else if (Platform.isIOS) {
      return "ca-app-pub-5540129750283532/4970568843";
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