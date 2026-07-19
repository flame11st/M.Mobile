import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static bool bannerVisible = false;
  static final Map<String, BannerAd> _banners = {};
  static final Map<String, Completer<bool>> _bannerLoadCompleters = {};
  static final Set<String> _loadedBannerIds = {};
  static Future<InitializationStatus>? _mobileAdsInitialization;
  static InterstitialAd? _recommendationsInterstitialAd;
  static bool bannersReady = false;
  static bool recommendationsInterstitialAdLoaded = false;

  static Future<void> hideBanner() async {
    for (var ad in _banners.values) {
      await ad.dispose();
    }
    _banners.clear();
    _bannerLoadCompleters.clear();
    _loadedBannerIds.clear();
    await _recommendationsInterstitialAd?.dispose();
    _recommendationsInterstitialAd = null;

    bannerVisible = false;
    bannersReady = false;
    recommendationsInterstitialAdLoaded = false;
  }

  static Future<void> showBanner() async {
    if (!bannerVisible) {
      bannerVisible = true;
      await loadAds();
    }
  }

  static Future<void> loadAds() async {
    await _ensureMobileAdsInitialized();

    if (Platform.isIOS) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }

    final bannerResults = await Future.wait([
      loadBanner(bannerAdUnitId),
      loadBanner(bannerAdUnitId2),
      loadBanner(bannerAdUnitId3),
    ]);

    await loadInterstitialAd();
    bannersReady = bannerResults.any((loaded) => loaded);
  }

  static Future<void> _ensureMobileAdsInitialized() async {
    _mobileAdsInitialization ??= MobileAds.instance.initialize();
    await _mobileAdsInitialization;
  }

  static Future<bool> loadBanner(String adUnitId) {
    if (_loadedBannerIds.contains(adUnitId)) {
      return Future.value(true);
    }

    final existingCompleter = _bannerLoadCompleters[adUnitId];
    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    final completer = Completer<bool>();
    _bannerLoadCompleters[adUnitId] = completer;
    getBanner(adUnitId).load();

    return completer.future;
  }

  static BannerAd getBanner(String adUnitId) {
    return _banners.putIfAbsent(
      adUnitId,
      () => BannerAd(
        size: AdSize.banner,
        adUnitId: adUnitId,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _loadedBannerIds.add(adUnitId);
            final completer = _bannerLoadCompleters.remove(adUnitId);
            if (completer != null && !completer.isCompleted) {
              completer.complete(true);
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _banners.remove(adUnitId);
            _loadedBannerIds.remove(adUnitId);
            final completer = _bannerLoadCompleters.remove(adUnitId);
            if (completer != null && !completer.isCompleted) {
              completer.complete(false);
            }
            debugPrint('BannerAd failed to load: $error');
          },
        ),
        request: const AdRequest(),
      ),
    );
  }

  static Widget getBannerWidget(BannerAd bannerAd) {
    if (!_loadedBannerIds.contains(bannerAd.adUnitId)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: bannerAd),
    );
  }

  // Helper getters to maintain compatibility with existing code
  static BannerAd get bannerAd => getBanner(bannerAdUnitId);
  static BannerAd get itemExpandedBannerAd => getBanner(bannerAdUnitId2);
  static BannerAd get settingsBannerAd => getBanner(bannerAdUnitId3);
  static BannerAd get listsBannerAd => getBanner(bannerAdUnitId);
  static BannerAd get listBannerAd => getBanner(bannerAdUnitId);
  static BannerAd get premiumBannerAd => getBanner(bannerAdUnitId3);
  static BannerAd get recommendationsBannerAd => getBanner(bannerAdUnitId2);
  static BannerAd get recommendationsHistoryBannerAd =>
      getBanner(bannerAdUnitId3);
  static BannerAd get searchBannerAd => getBanner(bannerAdUnitId);
  static BannerAd get searchBanner2Ad => getBanner(bannerAdUnitId2);

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
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdFailedToShowFullScreenContent: (ad, err) => ad.dispose(),
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd();
            },
          );
          _recommendationsInterstitialAd = ad;
          recommendationsInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return "ca-app-pub-5540129750283532/9763657807";
    if (Platform.isIOS) return "ca-app-pub-5540129750283532/4970568843";
    throw UnsupportedError("Unsupported platform");
  }

  static String get bannerAdUnitId2 {
    if (Platform.isAndroid) return "ca-app-pub-5540129750283532/9763657807";
    if (Platform.isIOS) return "ca-app-pub-5540129750283532/7843835650";
    throw UnsupportedError("Unsupported platform");
  }

  static String get bannerAdUnitId3 {
    if (Platform.isAndroid) return "ca-app-pub-5540129750283532/9763657807";
    if (Platform.isIOS) return "ca-app-pub-5540129750283532/5286240481";
    throw UnsupportedError("Unsupported platform");
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return "ca-app-pub-5540129750283532/2008742121";
    if (Platform.isIOS) return "ca-app-pub-5540129750283532/4127478852";
    throw UnsupportedError("Unsupported platform");
  }
}
