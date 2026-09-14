import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

@visibleForTesting
bool usesDevelopmentAdPrivacyBypass({
  required bool isReleaseMode,
  bool developmentBypassEnabled = const bool.fromEnvironment(
    'MOVIEDIARY_AD_PRIVACY_DEVELOPMENT_BYPASS',
    defaultValue: true,
  ),
}) => !isReleaseMode && developmentBypassEnabled;

enum AdPlatformConsentStatus { unknown, required, notRequired, obtained }

enum AdTrackingAuthorization {
  notApplicable,
  notDetermined,
  authorized,
  denied,
  restricted,
  unavailable,
}

enum AdTargetingMode { noAds, providerManaged, contextual }

enum AdPrivacyOptionsResult {
  presented,
  notRequired,
  unavailable,
  alreadyInProgress,
}

@immutable
class AdPrivacySnapshot {
  const AdPrivacySnapshot({
    required this.targetingMode,
    required this.platformConsentStatus,
    required this.trackingAuthorization,
    required this.privacyOptionsRequired,
    required this.eligibleThisSession,
    this.privacyOptionsStatusKnown = true,
    this.diagnosticCode,
  });

  const AdPrivacySnapshot.unresolved()
    : targetingMode = AdTargetingMode.noAds,
      platformConsentStatus = AdPlatformConsentStatus.unknown,
      trackingAuthorization = AdTrackingAuthorization.unavailable,
      privacyOptionsRequired = false,
      privacyOptionsStatusKnown = false,
      eligibleThisSession = false,
      diagnosticCode = 'not_initialized';

  final AdTargetingMode targetingMode;
  final AdPlatformConsentStatus platformConsentStatus;
  final AdTrackingAuthorization trackingAuthorization;
  final bool privacyOptionsRequired;
  final bool privacyOptionsStatusKnown;
  final bool eligibleThisSession;
  final String? diagnosticCode;

  bool get canRequestAds => targetingMode != AdTargetingMode.noAds;
  bool get usesContextualRequests =>
      targetingMode == AdTargetingMode.contextual;
}

class AdPrivacyAdRequestFactory {
  const AdPrivacyAdRequestFactory._();

  static AdRequest create(AdPrivacySnapshot snapshot) {
    final contextual = snapshot.usesContextualRequests;
    return AdRequest(
      nonPersonalizedAds: contextual,
      extras: contextual ? const {'rdp': '1'} : null,
    );
  }
}

abstract interface class AdPrivacyPlatformGateway {
  bool get isIos;

  Future<void> requestConsentInfoUpdate();

  Future<AdPlatformConsentStatus> consentStatus();

  Future<bool> canRequestAds();

  Future<bool> privacyOptionsRequired();

  Future<void> showRequiredConsentForm();

  Future<void> showPrivacyOptionsForm();

  Future<AdTrackingAuthorization> trackingAuthorization();

  Future<AdTrackingAuthorization> requestTrackingAuthorization();
}

abstract interface class AdPrivacyExperienceStore {
  Future<bool> hasPriorProductExperience();

  Future<void> markProductExperienceCompleted();
}

class SecureAdPrivacyExperienceStore implements AdPrivacyExperienceStore {
  SecureAdPrivacyExperienceStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const experienceKey = 'adPrivacyPriorProductExperienceV1';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> hasPriorProductExperience() async =>
      await _storage.read(key: experienceKey) == 'true';

  @override
  Future<void> markProductExperienceCompleted() =>
      _storage.write(key: experienceKey, value: 'true');
}

class GoogleAdPrivacyPlatformGateway implements AdPrivacyPlatformGateway {
  const GoogleAdPrivacyPlatformGateway();

  static const _debugGeography = String.fromEnvironment(
    'MOVIEDIARY_UMP_DEBUG_GEOGRAPHY',
  );
  static const _debugTestDeviceId = String.fromEnvironment(
    'MOVIEDIARY_UMP_TEST_DEVICE_ID',
  );

  @override
  bool get isIos => Platform.isIOS;

  @override
  Future<void> requestConsentInfoUpdate() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(
        consentDebugSettings: _developmentDebugSettings(),
      ),
      () => completer.complete(),
      (error) =>
          completer.completeError(StateError('ump_update_${error.errorCode}')),
    );
    return completer.future;
  }

  ConsentDebugSettings? _developmentDebugSettings() {
    if (kReleaseMode ||
        (_debugGeography.isEmpty && _debugTestDeviceId.isEmpty)) {
      return null;
    }
    final geography = switch (_debugGeography.toLowerCase()) {
      'eea' => DebugGeography.debugGeographyEea,
      'not_eea' => DebugGeography.debugGeographyNotEea,
      _ => DebugGeography.debugGeographyDisabled,
    };
    return ConsentDebugSettings(
      debugGeography: geography,
      testIdentifiers: _debugTestDeviceId.isEmpty ? null : [_debugTestDeviceId],
    );
  }

  @override
  Future<AdPlatformConsentStatus> consentStatus() async {
    final status = await ConsentInformation.instance.getConsentStatus();
    return switch (status) {
      ConsentStatus.required => AdPlatformConsentStatus.required,
      ConsentStatus.notRequired => AdPlatformConsentStatus.notRequired,
      ConsentStatus.obtained => AdPlatformConsentStatus.obtained,
      ConsentStatus.unknown => AdPlatformConsentStatus.unknown,
    };
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> privacyOptionsRequired() async {
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return switch (status) {
      PrivacyOptionsRequirementStatus.required => true,
      PrivacyOptionsRequirementStatus.notRequired => false,
      PrivacyOptionsRequirementStatus.unknown => throw StateError(
        'ump_privacy_options_unknown',
      ),
    };
  }

  @override
  Future<void> showRequiredConsentForm() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(StateError('ump_form_${error.errorCode}'));
      }
    });
    return completer.future;
  }

  @override
  Future<void> showPrivacyOptionsForm() {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(
          StateError('ump_privacy_options_${error.errorCode}'),
        );
      }
    });
    return completer.future;
  }

  @override
  Future<AdTrackingAuthorization> trackingAuthorization() async {
    if (!isIos) {
      return AdTrackingAuthorization.notApplicable;
    }
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    return _mapTrackingStatus(status);
  }

  @override
  Future<AdTrackingAuthorization> requestTrackingAuthorization() async {
    if (!isIos) {
      return AdTrackingAuthorization.notApplicable;
    }
    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    return _mapTrackingStatus(status);
  }

  AdTrackingAuthorization _mapTrackingStatus(TrackingStatus status) =>
      switch (status) {
        TrackingStatus.notSupported => AdTrackingAuthorization.unavailable,
        TrackingStatus.notDetermined => AdTrackingAuthorization.notDetermined,
        TrackingStatus.restricted => AdTrackingAuthorization.restricted,
        TrackingStatus.denied => AdTrackingAuthorization.denied,
        TrackingStatus.authorized => AdTrackingAuthorization.authorized,
      };
}

/// Coordinates provider consent, delayed iOS tracking permission, and the
/// conservative request mode used by every MovieDiary ad format.
///
/// Consent is refreshed at launch, but no provider form or ATT prompt is shown
/// during the first application session. A monetizable placement may present a
/// required form only in a later session, after the product shell has already
/// been experienced. Unresolved or failed consent always skips ads.
class AdPrivacyConsentController {
  AdPrivacyConsentController({
    AdPrivacyPlatformGateway? platform,
    AdPrivacyExperienceStore? experienceStore,
    this.operationTimeout = const Duration(seconds: 8),
    bool? isReleaseMode,
    bool? developmentBypassEnabled,
  }) : _platform = platform ?? const GoogleAdPrivacyPlatformGateway(),
       _experienceStore = experienceStore ?? SecureAdPrivacyExperienceStore(),
       _useDevelopmentBypass = usesDevelopmentAdPrivacyBypass(
         isReleaseMode: isReleaseMode ?? kReleaseMode,
         developmentBypassEnabled:
             developmentBypassEnabled ??
             const bool.fromEnvironment(
               'MOVIEDIARY_AD_PRIVACY_DEVELOPMENT_BYPASS',
               defaultValue: true,
             ),
       );

  final AdPrivacyPlatformGateway _platform;
  final AdPrivacyExperienceStore _experienceStore;
  final Duration operationTimeout;
  final bool _useDevelopmentBypass;

  AdPrivacySnapshot _snapshot = const AdPrivacySnapshot.unresolved();
  Future<AdPrivacySnapshot>? _initialization;
  Future<AdPrivacySnapshot>? _refreshInFlight;
  Future<AdPrivacyOptionsResult>? _privacyOptionsInFlight;
  Future<AdPrivacySnapshot>? _adRequestConsentInFlight;
  bool _eligibleThisSession = false;
  bool _refreshSucceeded = false;

  AdPrivacySnapshot get snapshot => _snapshot;

  Future<AdPrivacySnapshot> initializeForLaunch() =>
      _initialization ??= _initializeForLaunch();

  Future<AdPrivacySnapshot> _initializeForLaunch() async {
    if (_useDevelopmentBypass) {
      return _setDevelopmentBypass();
    }
    try {
      _eligibleThisSession = await _experienceStore.hasPriorProductExperience();
    } catch (_) {
      _eligibleThisSession = false;
    }
    await _refreshConsentInformation();
    return _evaluate(promptForTracking: false);
  }

  Future<void> markMeaningfulProductExperience() async {
    if (_useDevelopmentBypass) {
      return;
    }
    // Capture whether this was already a returning session before persisting
    // the marker. A fast first frame must never turn the current first session
    // into a prompt-eligible session through an initialization race.
    await initializeForLaunch();
    try {
      await _experienceStore.markProductExperienceCompleted();
    } catch (_) {
      // A failed marker write delays prompts and ads; core product flow stays
      // available and no privacy choice is weakened.
    }
  }

  Future<AdPrivacySnapshot> ensureConsentForAdRequest() =>
      _adRequestConsentInFlight ??= _ensureConsentForAdRequest().whenComplete(
        () => _adRequestConsentInFlight = null,
      );

  Future<AdPrivacySnapshot> _ensureConsentForAdRequest() async {
    if (_useDevelopmentBypass) {
      return _setDevelopmentBypass();
    }
    await initializeForLaunch();
    final privacyOptions = _privacyOptionsInFlight;
    if (privacyOptions != null) {
      await privacyOptions;
      return _snapshot;
    }
    if (!_eligibleThisSession) {
      return _setNoAds('first_session_deferred');
    }

    var status = await _safeConsentStatus();
    if (status == AdPlatformConsentStatus.required) {
      try {
        await _platform.showRequiredConsentForm();
      } catch (_) {
        return _setNoAds('required_form_unavailable');
      }
      status = await _safeConsentStatus();
    }

    if (!await _safeCanRequestAds()) {
      return _setNoAds(
        status == AdPlatformConsentStatus.required
            ? 'consent_declined_or_unresolved'
            : 'provider_cannot_request_ads',
      );
    }
    return _evaluate(promptForTracking: true);
  }

  Future<AdPrivacySnapshot> refreshAfterLifecycleOrIdentityChange() =>
      _refreshInFlight ??= _refreshAfterLifecycleOrIdentityChange()
          .whenComplete(() => _refreshInFlight = null);

  Future<AdPrivacySnapshot> _refreshAfterLifecycleOrIdentityChange() async {
    if (_useDevelopmentBypass) {
      return _setDevelopmentBypass();
    }
    await initializeForLaunch();
    await _refreshConsentInformation();
    return _evaluate(promptForTracking: false);
  }

  Future<AdPrivacyOptionsResult> showPrivacyOptions() {
    if (_adRequestConsentInFlight != null) {
      return Future.value(AdPrivacyOptionsResult.alreadyInProgress);
    }
    final inFlight = _privacyOptionsInFlight;
    if (inFlight != null) {
      return Future.value(AdPrivacyOptionsResult.alreadyInProgress);
    }
    final operation = _showPrivacyOptions();
    _privacyOptionsInFlight = operation;
    return operation.whenComplete(() => _privacyOptionsInFlight = null);
  }

  Future<AdPrivacyOptionsResult> _showPrivacyOptions() async {
    if (_useDevelopmentBypass) {
      return AdPrivacyOptionsResult.notRequired;
    }
    await initializeForLaunch();
    final freshRequirement = _refreshSucceeded
        ? await _readPrivacyOptionsRequired()
        : null;
    final required =
        freshRequirement ??
        (_snapshot.privacyOptionsStatusKnown &&
            _snapshot.privacyOptionsRequired);
    if (!required) {
      if (freshRequirement == null) {
        _setNoAds('privacy_options_status_unavailable');
        return AdPrivacyOptionsResult.unavailable;
      }
      _snapshot = AdPrivacySnapshot(
        targetingMode: _snapshot.targetingMode,
        platformConsentStatus: _snapshot.platformConsentStatus,
        trackingAuthorization: _snapshot.trackingAuthorization,
        privacyOptionsRequired: false,
        privacyOptionsStatusKnown: true,
        eligibleThisSession: _eligibleThisSession,
        diagnosticCode: 'privacy_options_not_required',
      );
      return AdPrivacyOptionsResult.notRequired;
    }

    try {
      // This future includes the user's time in the provider form. Keep the
      // single-flight guard until dismissal instead of timing out an open form.
      await _platform.showPrivacyOptionsForm();
    } catch (_) {
      _setNoAds('privacy_options_unavailable', privacyOptionsRequired: true);
      return AdPrivacyOptionsResult.unavailable;
    }
    await _refreshConsentInformation();
    await _evaluate(promptForTracking: false);
    return AdPrivacyOptionsResult.presented;
  }

  Future<void> _refreshConsentInformation() async {
    try {
      await _platform.requestConsentInfoUpdate().timeout(operationTimeout);
      _refreshSucceeded = true;
    } catch (_) {
      _refreshSucceeded = false;
    }
  }

  Future<AdPrivacySnapshot> _evaluate({required bool promptForTracking}) async {
    final status = await _safeConsentStatus();
    final requirement = await _resolvePrivacyOptionsRequirement();
    final privacyOptionsRequired = requirement.required;
    final canRequestAds = await _safeCanRequestAds();

    if (!_eligibleThisSession) {
      return _setNoAds(
        'first_session_deferred',
        status: status,
        privacyOptionsRequired: privacyOptionsRequired,
        privacyOptionsStatusKnown: requirement.known,
      );
    }
    if (status == AdPlatformConsentStatus.unknown ||
        status == AdPlatformConsentStatus.required ||
        !canRequestAds) {
      return _setNoAds(
        _refreshSucceeded ? 'consent_required' : 'consent_refresh_unavailable',
        status: status,
        privacyOptionsRequired: privacyOptionsRequired,
        privacyOptionsStatusKnown: requirement.known,
      );
    }

    var tracking = await _safeTrackingAuthorization();
    if (_platform.isIos &&
        promptForTracking &&
        status == AdPlatformConsentStatus.notRequired &&
        tracking == AdTrackingAuthorization.notDetermined) {
      try {
        tracking = await _platform.requestTrackingAuthorization().timeout(
          operationTimeout,
        );
      } catch (_) {
        tracking = AdTrackingAuthorization.unavailable;
      }
    }

    final contextual =
        !_refreshSucceeded ||
        tracking == AdTrackingAuthorization.denied ||
        tracking == AdTrackingAuthorization.restricted ||
        tracking == AdTrackingAuthorization.notDetermined ||
        tracking == AdTrackingAuthorization.unavailable;
    _snapshot = AdPrivacySnapshot(
      targetingMode: contextual
          ? AdTargetingMode.contextual
          : AdTargetingMode.providerManaged,
      platformConsentStatus: status,
      trackingAuthorization: tracking,
      privacyOptionsRequired: privacyOptionsRequired,
      privacyOptionsStatusKnown: requirement.known,
      eligibleThisSession: _eligibleThisSession,
      diagnosticCode: contextual ? 'contextual_only' : null,
    );
    return _snapshot;
  }

  Future<AdPlatformConsentStatus> _safeConsentStatus() async {
    try {
      return await _platform.consentStatus().timeout(operationTimeout);
    } catch (_) {
      return AdPlatformConsentStatus.unknown;
    }
  }

  Future<bool> _safeCanRequestAds() async {
    try {
      return await _platform.canRequestAds().timeout(operationTimeout);
    } catch (_) {
      return false;
    }
  }

  Future<bool?> _readPrivacyOptionsRequired() async {
    try {
      return await _platform.privacyOptionsRequired().timeout(operationTimeout);
    } catch (_) {
      return null;
    }
  }

  Future<({bool required, bool known})>
  _resolvePrivacyOptionsRequirement() async {
    if (!_refreshSucceeded) {
      return (
        required: _snapshot.privacyOptionsRequired,
        known: _snapshot.privacyOptionsStatusKnown,
      );
    }
    final fresh = await _readPrivacyOptionsRequired();
    if (fresh == null) {
      return (
        required: _snapshot.privacyOptionsRequired,
        known: _snapshot.privacyOptionsStatusKnown,
      );
    }
    return (required: fresh, known: true);
  }

  Future<AdTrackingAuthorization> _safeTrackingAuthorization() async {
    try {
      return await _platform.trackingAuthorization().timeout(operationTimeout);
    } catch (_) {
      return AdTrackingAuthorization.unavailable;
    }
  }

  AdPrivacySnapshot _setNoAds(
    String diagnosticCode, {
    AdPlatformConsentStatus? status,
    bool? privacyOptionsRequired,
    bool? privacyOptionsStatusKnown,
  }) {
    _snapshot = AdPrivacySnapshot(
      targetingMode: AdTargetingMode.noAds,
      platformConsentStatus: status ?? _snapshot.platformConsentStatus,
      trackingAuthorization: _snapshot.trackingAuthorization,
      privacyOptionsRequired:
          privacyOptionsRequired ?? _snapshot.privacyOptionsRequired,
      privacyOptionsStatusKnown:
          privacyOptionsStatusKnown ?? _snapshot.privacyOptionsStatusKnown,
      eligibleThisSession: _eligibleThisSession,
      diagnosticCode: diagnosticCode,
    );
    return _snapshot;
  }

  AdPrivacySnapshot _setDevelopmentBypass() {
    _eligibleThisSession = true;
    _refreshSucceeded = true;
    _snapshot = const AdPrivacySnapshot(
      targetingMode: AdTargetingMode.contextual,
      platformConsentStatus: AdPlatformConsentStatus.notRequired,
      trackingAuthorization: AdTrackingAuthorization.notApplicable,
      privacyOptionsRequired: false,
      privacyOptionsStatusKnown: true,
      eligibleThisSession: true,
      diagnosticCode: 'development_inventory',
    );
    return _snapshot;
  }
}
