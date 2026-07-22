import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Variables/themes.dart';
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

class MHomeState extends State<MHome> {
  StreamSubscription<dynamic>? _subscription;
  final serviceAgent = ServiceAgent();
  static const _anonymousBootstrapTimeout = Duration(seconds: 10);
  bool _anonymousBootstrapInFlight = false;
  String? _anonymousBootstrapError;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final loaderState = Provider.of<LoaderState>(context);
    final theme = Themes.family;
    //  final primaryColor = Color(0xff206a5d);
    //  final secondaryColor = Color(0xff307a6d);
    //  final additionalColor = Color(0xfff1f1e8);
    //  final fontsColor = Color(0xffbfdcae);
    // MTheme theme = new MTheme(
    //   brightness: Brightness.light,
    //     colorTheme: MColorTheme(
    //       primaryColor: primaryColor,
    //       secondaryColor: secondaryColor,
    //       additionalColor: additionalColor,
    //       fontsColor: fontsColor,
    //     ),
    //     textStyleTheme: MTextStyleTheme(
    //       title: TextStyle(
    //           fontSize: 15,
    //           fontWeight: FontWeight.bold,
    //           color: additionalColor),
    //       subtitleText: TextStyle(
    //           fontSize: 15.0,
    //           color: additionalColor,
    //           fontWeight: FontWeight.bold),
    //       bodyText: TextStyle(fontSize: 15.0, color: fontsColor),
    //       expandedTitle: TextStyle(
    //           fontSize: 16,
    //           fontWeight: FontWeight.bold,
    //           color: additionalColor),
    //     ));

    Widget widgetToReturn = _buildStartupSurface(
      loadingLabel: 'Loading your MovieDiary',
      body: 'Setting up your taste profile, lists, and recommendations.',
    );
    if (userState.isAppLoaded) {
      if (userState.isUserAuthorizedOrInIncognitoMode) {
        widgetToReturn = MyMovies();
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

    return MaterialApp(
        home: Stack(
          children: <Widget>[
            widgetToReturn,
            if (loaderState.isLoaderVisible) const LoadingAnimation(),
          ],
        ),
        // routes: {
        //   'moviesList': (context) => MoviesListPage(),
        // },
        theme: ThemeData(
            // Define the default brightness and colors.
            brightness: theme.brightness,
            splashFactory: InkRipple.splashFactory,
            primaryColor: theme.colorTheme.primaryColor,
            indicatorColor: theme.colorTheme.additionalColor,
            hintColor: theme.colorTheme.fontsColor,
            cardColor: theme.colorTheme.secondaryColor,
            highlightColor: theme.colorTheme.fontsColor,
            splashColor: theme.colorTheme.primaryColor,
            iconTheme: IconThemeData(color: theme.colorTheme.fontsColor),
            appBarTheme: AppBarTheme(
                backgroundColor: theme.colorTheme.primaryColor,
                iconTheme: IconThemeData(color: theme.colorTheme.fontsColor)),
            textTheme: TextTheme(
              displayMedium: theme.textStyleTheme.expandedTitle,
              displaySmall: theme.textStyleTheme.title,
              headlineMedium: theme.textStyleTheme.subtitleText,
              headlineSmall: theme.textStyleTheme.bodyText,
              titleLarge: theme.textStyleTheme.expandedTitle,
            ),
            pageTransitionsTheme: const PageTransitionsTheme(builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder()
            })));
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: const Center(
                  child: Image(
                    image: AssetImage('Assets/mdIcon_V_with_effect.png'),
                    width: 54,
                  ),
                ),
              ),
              const Text(
                'MovieDiary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Md3Colors.text,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loadingLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Md3Colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
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
