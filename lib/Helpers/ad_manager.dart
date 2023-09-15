import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static bool bannerVisible = false;
  static BannerAd? _bannerAd;
  static BannerAd? _settingsBannerAd;
  static BannerAd? _itemExpandedBannerAd;
  static BannerAd? _listsBannerAd;
  static BannerAd? _listBannerAd;
  static BannerAd? _premiumBannerAd;
  static BannerAd? _recommendationsBannerAd;
  static BannerAd? _recommendationsHistoryBannerAd;
  static BannerAd? _searchBannerAd;
  static BannerAd? _searchBanner2Ad;
  static InterstitialAd? _recommendationsInterstitialAd;
  static bool bannersReady = false;
  static bool recommendationsInterstitialAdLoaded = false;

  static Future<void> hideBanner() async {
    try {
      await _bannerAd?.dispose();
      await _recommendationsInterstitialAd?.dispose();
    } catch (on){}

    _bannerAd = null;
    _settingsBannerAd = null;
    _itemExpandedBannerAd = null;
    _listsBannerAd = null;
    _listBannerAd = null;
    _premiumBannerAd = null;
    _recommendationsBannerAd = null;
    _recommendationsHistoryBannerAd = null;
    _recommendationsInterstitialAd = null;
    _searchBannerAd = null;
    _searchBanner2Ad = null;

    bannerVisible = false;
    bannersReady = false;
    recommendationsInterstitialAdLoaded = false;
  }

  static Future<void> disposeInterstitialAd() async {
    await _recommendationsInterstitialAd?.dispose();
  }

  static Future<void> showBanner() async {
    if (!bannerVisible) {
      bannerVisible = true;

      await loadBanners();
    }
  }

  static Future<void> loadBanners() async {
    if (Platform.isIOS) await AppTrackingTransparency.requestTrackingAuthorization();

    await bannerAd?.load();
    await loadInterstitialAd();
    await settingsBannerAd?.load();
    await itemExpandedBannerAd?.load();
    await listsBannerAd?.load();
    await listBannerAd?.load();
    await premiumBannerAd?.load();
    await recommendationsBannerAd?.load();
    await recommendationsHistoryBannerAd?.load();
    await searchBannerAd?.load();
    await searchBanner2Ad?.load();

    bannersReady = true;
  }

  static Widget getBannerWidget(BannerAd bannerAd) {
    return StatefulBuilder(
      builder: (context, setState) => Container(
        child: AdWidget(ad: bannerAd),
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        alignment: Alignment.center,
      ),
    );
  }

  static BannerAd? get bannerAd {
    if (_bannerAd == null ) {
      _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _bannerAd;
  }

  static BannerAd? get itemExpandedBannerAd {
    if (_itemExpandedBannerAd == null ) {
      _itemExpandedBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _itemExpandedBannerAd;
  }

  static BannerAd? get settingsBannerAd {
    if (_settingsBannerAd == null ) {
      _settingsBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _settingsBannerAd;
  }

  static BannerAd? get listsBannerAd {
    if (_listsBannerAd == null ) {
      _listsBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _listsBannerAd;
  }

  static BannerAd? get listBannerAd {
    if (_listBannerAd == null ) {
      _listBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _listBannerAd;
  }

  static BannerAd? get premiumBannerAd {
    if (_premiumBannerAd == null ) {
      _premiumBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _premiumBannerAd;
  }

  static BannerAd? get recommendationsBannerAd {
    if (_recommendationsBannerAd == null ) {
      _recommendationsBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _recommendationsBannerAd;
  }
  static BannerAd? get recommendationsHistoryBannerAd {
    if (_recommendationsHistoryBannerAd == null ) {
      _recommendationsHistoryBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _recommendationsHistoryBannerAd;
  }

  static BannerAd? get searchBannerAd {
    if (_searchBannerAd == null ) {
      _searchBannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _searchBannerAd;
  }

  static BannerAd? get searchBanner2Ad {
    if (_searchBanner2Ad == null ) {
      _searchBanner2Ad = BannerAd(
        size: AdSize.banner,
        adUnitId: bannerAdUnitId,
        listener: AdManagerBannerAdListener(),
        request: AdRequest(),
      );
    }

    return _searchBanner2Ad;
  }

  static void showInterstitialAd() {
    if (recommendationsInterstitialAdLoaded) {
      _recommendationsInterstitialAd?.show();
    }
  }

  static Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              // Called when the ad showed the full screen content.
              //   onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                // onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  loadInterstitialAd();
                },
                // Called when a click is recorded for an ad.
                // onAdClicked: (ad) {}
            );
            recommendationsInterstitialAdLoaded = true;
            // Keep a reference to the ad so you can show it later.
            _recommendationsInterstitialAd = ad;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
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
      //return 'ca-app-pub-3940256099942544/6300978111'; //test
      return "ca-app-pub-5540129750283532/9763657807";//real
    } else if (Platform.isIOS) {
      return "ca-app-pub-5540129750283532/4970568843";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      //return "ca-app-pub-3940256099942544/1033173712"; //test
      return "ca-app-pub-5540129750283532/2008742121"; //real
    } else if (Platform.isIOS) {
      return "ca-app-pub-5540129750283532/4127478852";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }
}