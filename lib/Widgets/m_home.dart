import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/loader_state.dart';
import 'package:provider/provider.dart';
import 'loading_animation.dart';
import 'my_movies.dart';
import 'Providers/user_state.dart';
import 'Shared/md3_ui.dart';
import 'Shared/m_snack_bar.dart';

class MHome extends StatefulWidget {
  @override
  MHomeState createState() {
    return MHomeState();
  }
}

class MHomeState extends State<MHome> with RestorationMixin {
  StreamSubscription<dynamic>? _subscription;
  final serviceAgent = ServiceAgent();
  final _selectedRootTab = RestorableInt(0);
  static const _anonymousBootstrapTimeout = Duration(seconds: 8);
  bool _anonymousBootstrapInFlight = false;
  String? _anonymousBootstrapError;

  @override
  String? get restorationId => 'movieDiaryHome';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedRootTab, 'selectedRootTab');
  }

  _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    final userState = Provider.of<UserState>(context, listen: false);

    if (purchases.isEmpty) return;

    final purchase = purchases.first;

    if (purchase.status == PurchaseStatus.purchased) {
      InAppPurchase.instance.completePurchase(purchases.first);

      userState.setPremium(true);

      if (!userState.isIncognitoMode) {
        serviceAgent.setUserPremiumPurchased(userState.userId!, true);
      }

      MSnackBar.showSnackBar("Premium features successfully unlocked", true);
    } else if (purchase.status == PurchaseStatus.error &&
        purchase.error!.details != "") {
      MSnackBar.showSnackBar(purchases.first.error!.details, false);
    } else if (purchase.status == PurchaseStatus.pending) {
      MSnackBar.showSnackBar(
          "Your request is being processed. It can take a while", true);
    } else if (purchase.status == PurchaseStatus.restored &&
        purchase.productID == 'premium_purchase') {
      userState.setPremium(true);

      if (!userState.isIncognitoMode) {
        serviceAgent.setUserPremiumPurchased(userState.userId!, true);
      }

      MSnackBar.showSnackBar("Premium features successfully restored", true);
    } else {
      MSnackBar.showSnackBar("Not available now. Please try later", false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _subscription != null) {
        return;
      }

      final Stream purchaseUpdates = InAppPurchase.instance.purchaseStream;
      _subscription = purchaseUpdates.listen((purchases) {
        _handlePurchaseUpdates(purchases);
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _selectedRootTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final loaderState = Provider.of<LoaderState>(context);

    Widget widgetToReturn = _buildStartupSurface(
      loadingLabel: 'Loading your MovieDiary',
      body: 'Setting up your taste profile, lists, and recommendations.',
    );
    if (userState.isAppLoaded) {
      if (userState.isUserAuthorizedOrInIncognitoMode) {
        widgetToReturn = MyMovies(
          initialNavigationIndex: _selectedRootTab.value,
          onNavigationIndexChanged: (index) {
            _selectedRootTab.value = index;
          },
        );
      } else {
        if (_anonymousBootstrapError == null) {
          _bootstrapAnonymousOnboarding(userState);
        }
        widgetToReturn = _buildStartupSurface(
          loadingLabel: _anonymousBootstrapInFlight
              ? 'Starting guest mode'
              : 'Preparing your first session',
          body: _anonymousBootstrapError ??
              'We are creating a private MovieDiary session so you can start rating movies right away.',
          showRetry: _anonymousBootstrapError != null,
        );
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Md3Colors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
          title: 'MovieDiary',
          restorationScopeId: 'movieDiaryApp',
          home: Stack(
            children: <Widget>[
              widgetToReturn,
              if (loaderState.isLoaderVisible) const LoadingAnimation(),
            ],
          ),
          theme: MovieDiaryTheme.light().copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          )),
    );
  }

  void _bootstrapAnonymousOnboarding(UserState userState) {
    if (_anonymousBootstrapInFlight) {
      return;
    }

    _anonymousBootstrapInFlight = true;
    _anonymousBootstrapError = null;
    Future.microtask(() async {
      try {
        final created = await userState
            .ensureAnonymousProfile()
            .timeout(_anonymousBootstrapTimeout);
        if (!created) {
          throw Exception('Guest mode request was rejected.');
        }

        await userState.setOnboardingStage(OnboardingStage.rating);
      } catch (error) {
        debugPrint('Anonymous bootstrap failed: $error');
        if (!mounted) {
          return;
        }

        setState(() {
          _anonymousBootstrapInFlight = false;
          _anonymousBootstrapError =
              'MovieDiary could not start a guest session. Check your connection, then try again.';
        });
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _anonymousBootstrapInFlight = false;
        _anonymousBootstrapError = null;
      });
    });
  }

  Widget _buildStartupSurface({
    required String loadingLabel,
    required String body,
    bool showRetry = false,
  }) {
    return Scaffold(
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Image(
                image: AssetImage('Assets/mdIcon_V_with_effect.png'),
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 24),
              const Text(
                'MovieDiary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Md3Colors.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                loadingLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: Md3Colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Md3Colors.muted,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: showRetry
                    ? Md3PrimaryButton(
                        key: const ValueKey('retryGuestMode'),
                        text: 'Try Again',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          setState(() {
                            _anonymousBootstrapInFlight = false;
                            _anonymousBootstrapError = null;
                          });
                        },
                      )
                    : const SizedBox(
                        key: ValueKey('startupSpinner'),
                        height: 48,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              color: Md3Colors.primary,
                            ),
                          ),
                        ),
                      ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
