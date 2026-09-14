import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Services/ad_privacy_consent.dart';
import 'package:mmobile/Services/monetization_service.dart';
import 'package:mmobile/Widgets/Providers/loader_state.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/premium.dart';
import 'package:mmobile/Widgets/settings.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest Settings uses direct account copy and secondary restore', (
    tester,
  ) async {
    final states = await _states();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(
      _app(states, home: const Settings(), textScale: 1.3),
    );
    await tester.pump();

    expect(find.text('Using MovieDiary without an account'), findsOneWidget);
    expect(find.text('Trying MovieDiary first'), findsNothing);
    expect(
      find.text(
        'Ratings, Watchlist, and Viewed stay with this guest profile on this device. Sign in to sync them with your account.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('settingsPremiumCard')), findsOneWidget);
    expect(find.byKey(const Key('settingsPremiumAction')), findsOneWidget);
    expect(find.byKey(const Key('restorePurchasesCard')), findsOneWidget);
    expect(find.byKey(const Key('settingsAdPrivacyCard')), findsOneWidget);
    expect(find.byKey(const Key('settingsAdPrivacyAction')), findsOneWidget);
    expect(
      find.text(
        'Advertising choices are separate from your MovieDiary ratings and recommendations.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('owned Settings hides purchase and restore actions', (
    tester,
  ) async {
    final states = await _states(premium: true);
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 930));

    await tester.pumpWidget(_app(states, home: const Settings()));
    await tester.pump();

    expect(find.byKey(const Key('settingsPremiumCard')), findsOneWidget);
    expect(find.text('Premium active'), findsOneWidget);
    expect(find.byKey(const Key('settingsPremiumAction')), findsNothing);
    expect(find.byKey(const Key('restorePurchasesCard')), findsNothing);
    expect(find.text('View plans'), findsNothing);
    expect(find.byKey(const Key('settingsAdPrivacyCard')), findsOneWidget);
    expect(find.byKey(const Key('settingsAdPrivacyAction')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Premium uses real localized price and moves purchase into pending state',
    (tester) async {
      final states = await _states();
      final store = _FakePremiumStore(
        product: const PremiumStoreProduct(
          id: 'premium_purchase',
          localizedPrice: '123 456,78 Very Long Currency',
        ),
      );
      addTearDown(states.movies.dispose);
      addTearDown(store.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        _app(states, home: Premium(store: store), textScale: 1.3),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('premiumHeroCard')), findsOneWidget);
      expect(find.byKey(const Key('premiumBenefitsCard')), findsOneWidget);
      expect(find.byKey(const Key('premiumStoreCard')), findsOneWidget);
      expect(find.text('Remove ads'), findsOneWidget);
      expect(find.text('Support MovieDiary'), findsOneWidget);
      expect(
        find.textContaining('123 456,78 Very Long Currency'),
        findsWidgets,
      );
      expect(find.text('Unlock Premium Features'), findsNothing);
      expect(find.text('Support MovieDiary Team'), findsNothing);

      final primary = find.byKey(const Key('premiumPrimaryAction'));
      expect(primary, findsOneWidget);
      await tester.tap(primary);
      await tester.pumpAndSettle();

      expect(store.purchaseCalls, 1);
      expect(find.text('Purchase pending'), findsWidgets);
      final pendingButton = tester.widget<FilledButton>(primary);
      expect(pendingButton.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Premium exposes a truthful unavailable retry state', (
    tester,
  ) async {
    final states = await _states();
    final store = _FakePremiumStore(available: false);
    addTearDown(states.movies.dispose);
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 930));

    await tester.pumpWidget(_app(states, home: Premium(store: store)));
    await tester.pumpAndSettle();

    expect(find.text('Store unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining(r'$'), findsNothing);
    expect(find.byKey(const Key('premiumRestoreAction')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'owned Premium is a calm status surface with no purchase actions',
    (tester) async {
      final states = await _states(premium: true);
      final store = _FakePremiumStore(
        product: const PremiumStoreProduct(
          id: 'premium_purchase',
          localizedPrice: r'$4.99',
        ),
      );
      addTearDown(states.movies.dispose);
      addTearDown(store.dispose);

      await tester.pumpWidget(_app(states, home: Premium(store: store)));
      await tester.pumpAndSettle();

      expect(find.text('Premium is yours'), findsOneWidget);
      expect(find.text('Premium active'), findsOneWidget);
      expect(find.byKey(const Key('premiumPrimaryAction')), findsNothing);
      expect(find.byKey(const Key('premiumRestoreAction')), findsNothing);
      expect(find.textContaining(r'$4.99'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Premium purchase cancellation restores the real-price action', (
    tester,
  ) async {
    final states = await _states();
    final store = _FakePremiumStore(
      product: const PremiumStoreProduct(
        id: 'premium_purchase',
        localizedPrice: r'$4.99',
      ),
    );
    addTearDown(states.movies.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(_app(states, home: Premium(store: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('premiumPrimaryAction')));
    await tester.pumpAndSettle();

    store.emit(const PremiumPurchaseUpdate(PremiumPurchaseStatus.cancelled));
    await tester.pumpAndSettle();

    expect(find.text('Purchase not completed'), findsOneWidget);
    expect(find.text(r'Unlock Premium · $4.99'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('premiumPrimaryAction')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Premium purchase errors never expose technical store details', (
    tester,
  ) async {
    final states = await _states();
    final store = _FakePremiumStore(
      product: const PremiumStoreProduct(
        id: 'premium_purchase',
        localizedPrice: r'$4.99',
      ),
    );
    addTearDown(states.movies.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(_app(states, home: Premium(store: store)));
    await tester.pumpAndSettle();

    store.emit(
      const PremiumPurchaseUpdate(
        PremiumPurchaseStatus.error,
        message: 'PlatformException(store_error, request token=private)',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Purchase not completed'), findsOneWidget);
    expect(
      find.text(
        'Your app store did not complete the purchase. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('PlatformException'), findsNothing);
    expect(find.textContaining('token=private'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('verified purchase immediately activates lifetime Premium', (
    tester,
  ) async {
    final serviceAgent = _PremiumSyncServiceAgent();
    final states = await _states(serviceAgent: serviceAgent);
    final store = _FakePremiumStore(
      product: const PremiumStoreProduct(
        id: 'premium_purchase',
        localizedPrice: r'$4.99',
      ),
    );
    addTearDown(states.movies.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(_app(states, home: Premium(store: store)));
    await tester.pumpAndSettle();

    store.emit(const PremiumPurchaseUpdate(PremiumPurchaseStatus.purchased));
    await tester.pumpAndSettle();

    expect(states.user.isPremium, isTrue);
    expect(find.text('Premium is yours'), findsOneWidget);
    expect(find.byKey(const Key('premiumPrimaryAction')), findsNothing);
    expect(serviceAgent.syncUserIds, ['uxr31-guest']);
    expect(tester.takeException(), isNull);
  });
}

Future<_TestStates> _states({
  bool premium = false,
  ServiceAgent? serviceAgent,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'uxr31-guest-access',
    'refreshToken': 'uxr31-guest-refresh',
    'userId': 'uxr31-guest',
    'isIncognitoMode': 'true',
    'premiumPurchasedIncognito': premium.toString(),
  });
  const storage = FlutterSecureStorage();
  final user = UserState(
    storage: storage,
    serviceAgent: serviceAgent,
    monetizationService: _PrivacyMonetizationService(required: true),
  );
  await user.initialization;
  final movies = MoviesState(storage: storage);
  await movies.cacheInitialization;
  return _TestStates(user, movies, LoaderState());
}

class _PremiumSyncServiceAgent extends ServiceAgent {
  final List<String> syncUserIds = [];

  @override
  Future<http.Response> setUserPremiumPurchased(
    String userId,
    bool value,
  ) async {
    syncUserIds.add(userId);
    return http.Response('', 204);
  }
}

Widget _app(_TestStates states, {required Widget home, double textScale = 1}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserState>.value(value: states.user),
      ChangeNotifierProvider<MoviesState>.value(value: states.movies),
      ChangeNotifierProvider<LoaderState>.value(value: states.loader),
    ],
    child: MaterialApp(
      theme: MovieDiaryTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

class _TestStates {
  final UserState user;
  final MoviesState movies;
  final LoaderState loader;

  const _TestStates(this.user, this.movies, this.loader);
}

class _PrivacyMonetizationService extends MonetizationService {
  _PrivacyMonetizationService({required bool required}) : _required = required;

  final bool _required;
  bool _premium = false;

  @override
  bool get isPremium => _premium;

  @override
  bool get privacyOptionsRequired => _required;

  @override
  AdPrivacySnapshot get privacySnapshot => AdPrivacySnapshot(
    targetingMode: AdTargetingMode.noAds,
    platformConsentStatus: AdPlatformConsentStatus.obtained,
    trackingAuthorization: AdTrackingAuthorization.notApplicable,
    privacyOptionsRequired: _required,
    eligibleThisSession: true,
  );

  @override
  Future<void> synchronizeEntitlement({
    required bool isPremium,
    required bool isResolved,
  }) async {
    _premium = isPremium;
    notifyListeners();
  }

  @override
  Future<void> beginEntitlementRefresh() =>
      synchronizeEntitlement(isPremium: false, isResolved: false);

  @override
  Future<AdPrivacyOptionsResult> showPrivacyOptions() async =>
      AdPrivacyOptionsResult.presented;
}

class _FakePremiumStore implements PremiumStore {
  final bool available;
  final PremiumStoreProduct? product;
  final _updates = StreamController<PremiumPurchaseUpdate>.broadcast();
  int purchaseCalls = 0;

  _FakePremiumStore({this.available = true, this.product});

  @override
  Stream<PremiumPurchaseUpdate> get purchaseUpdates => _updates.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<PremiumStoreProduct?> loadPremiumProduct() async => product;

  @override
  Future<bool> purchase(PremiumStoreProduct product) async {
    purchaseCalls++;
    return true;
  }

  @override
  Future<void> restorePurchases() async {}

  void emit(PremiumPurchaseUpdate update) => _updates.add(update);

  Future<void> dispose() => _updates.close();
}
