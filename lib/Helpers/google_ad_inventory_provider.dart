import 'dart:async';
import 'dart:io';
import 'package:mmobile/Widgets/Shared/md3_colors.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mmobile/Helpers/ad_inventory.dart';

/// Production AdMob inventory owned by the MovieDiary applications.
///
/// Ad unit IDs are public application identifiers rather than credentials.
/// Keeping the platform/format mapping beside the provider prevents a native
/// unit from being used for a rewarded request (or vice versa). Builds may
/// still override these defaults through the existing dart-define hooks.
abstract final class MovieDiaryAdMobUnits {
  static const androidNative = 'ca-app-pub-5540129750283532/8561091229';
  static const androidRewarded = 'ca-app-pub-5540129750283532/3128072193';
  static const iosNative = 'ca-app-pub-5540129750283532/9794281840';
  static const iosRewarded = 'ca-app-pub-5540129750283532/4665244096';
}

/// The only native/rewarded adapter that imports Google Mobile Ads.
///
/// Product screens and monetization policy code deal exclusively in the
/// provider-neutral resources from `ad_inventory.dart`.
class GoogleMobileAdsInventoryProvider implements AdInventoryProvider {
  GoogleMobileAdsInventoryProvider({
    required this.nativeAdUnitId,
    required this.rewardedAdUnitId,
    AdRequest Function()? requestFactory,
  }) : requestFactory = requestFactory ?? _defaultRequest;

  factory GoogleMobileAdsInventoryProvider.testInventory({
    AdRequest Function()? requestFactory,
  }) {
    if (Platform.isAndroid) {
      return GoogleMobileAdsInventoryProvider(
        nativeAdUnitId: 'ca-app-pub-3940256099942544/2247696110',
        rewardedAdUnitId: 'ca-app-pub-3940256099942544/5224354917',
        requestFactory: requestFactory,
      );
    }
    if (Platform.isIOS) {
      return GoogleMobileAdsInventoryProvider(
        nativeAdUnitId: 'ca-app-pub-3940256099942544/3986624511',
        rewardedAdUnitId: 'ca-app-pub-3940256099942544/1712485313',
        requestFactory: requestFactory,
      );
    }
    throw const AdInventoryException('unsupported_ad_platform');
  }

  final String nativeAdUnitId;
  final String rewardedAdUnitId;
  final AdRequest Function() requestFactory;
  Future<InitializationStatus>? _initialization;

  static AdRequest _defaultRequest() => const AdRequest();

  Future<void> _initialize() async {
    _initialization ??= MobileAds.instance.initialize();
    await _initialization;
  }

  @override
  Future<NativeAdResource> loadNative(
    NativeAdProviderCallbacks callbacks,
  ) async {
    await _initialize();
    final completer = Completer<NativeAdResource>();
    late NativeAd ad;
    var settled = false;

    ad = NativeAd(
      adUnitId: nativeAdUnitId,
      request: requestFactory(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Md3Colors.surfaceMuted,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Md3Colors.surface,
          backgroundColor: Md3Colors.primary,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Md3Colors.text,
          backgroundColor: Md3Colors.surfaceMuted,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Md3Colors.muted,
          backgroundColor: Md3Colors.surfaceMuted,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Md3Colors.muted,
          backgroundColor: Md3Colors.surfaceMuted,
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          if (settled) {
            unawaited(loadedAd.dispose());
            return;
          }
          settled = true;
          completer.complete(_GoogleNativeAdResource(ad));
        },
        onAdFailedToLoad: (failedAd, error) {
          unawaited(failedAd.dispose());
          if (settled) {
            return;
          }
          settled = true;
          completer.completeError(
            AdInventoryException('native_load_${error.code}'),
          );
        },
        onAdImpression: (_) => callbacks.onImpression(),
        onAdClicked: (_) => callbacks.onClicked(),
        onAdClosed: (_) => callbacks.onClosed(),
      ),
    );

    try {
      await ad.load();
    } catch (_) {
      if (!settled) {
        settled = true;
        await ad.dispose();
        completer.completeError(
          const AdInventoryException('native_load_exception'),
        );
      }
    }
    return completer.future;
  }

  @override
  Future<RewardedAdResource> loadRewarded() async {
    await _initialize();
    final completer = Completer<RewardedAdResource>();
    var settled = false;

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: requestFactory(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (settled) {
              unawaited(ad.dispose());
              return;
            }
            settled = true;
            completer.complete(_GoogleRewardedAdResource(ad));
          },
          onAdFailedToLoad: (error) {
            if (settled) {
              return;
            }
            settled = true;
            completer.completeError(
              AdInventoryException('rewarded_load_${error.code}'),
            );
          },
        ),
      );
    } catch (_) {
      if (!settled) {
        settled = true;
        completer.completeError(
          const AdInventoryException('rewarded_load_exception'),
        );
      }
    }
    return completer.future;
  }

  @override
  Future<void> dispose() async {}
}

class _GoogleNativeAdResource implements NativeAdResource {
  _GoogleNativeAdResource(this._ad);

  NativeAd? _ad;

  @override
  AdWidget buildView() {
    final ad = _ad;
    if (ad == null) {
      throw const AdInventoryException('native_resource_disposed');
    }
    return AdWidget(ad: ad);
  }

  @override
  Future<void> dispose() async {
    final ad = _ad;
    _ad = null;
    if (ad != null) {
      await ad.dispose();
    }
  }
}

class _GoogleRewardedAdResource implements RewardedAdResource {
  _GoogleRewardedAdResource(this._ad);

  RewardedAd? _ad;

  @override
  Future<void> show(RewardedAdProviderCallbacks callbacks) async {
    final ad = _ad;
    if (ad == null) {
      throw const AdInventoryException('rewarded_resource_disposed');
    }
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) => callbacks.onShown(),
      onAdImpression: (_) => callbacks.onImpression(),
      onAdClicked: (_) => callbacks.onClicked(),
      onAdDismissedFullScreenContent: (_) => callbacks.onDismissed(),
      onAdFailedToShowFullScreenContent: (_, error) =>
          callbacks.onFailure('rewarded_show_${error.code}'),
    );
    await ad.show(
      onUserEarnedReward: (_, reward) =>
          callbacks.onReward(reward.amount, reward.type),
    );
  }

  @override
  Future<void> dispose() async {
    final ad = _ad;
    _ad = null;
    if (ad != null) {
      await ad.dispose();
    }
  }
}
