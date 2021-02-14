import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mmobile/Objects/MColorTheme.dart';
import 'package:mmobile/Objects/MTextStyleTheme.dart';
import 'package:mmobile/Objects/MTheme.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/MoviesListPage.dart';
import 'package:mmobile/Widgets/Providers/LoaderState.dart';
import 'package:provider/provider.dart';
import 'LoadingAnimation.dart';
import 'Login.dart';
import 'MyMovies.dart';
import 'Providers/ThemeState.dart';
import 'Providers/UserState.dart';
import 'Shared/MSnackBar.dart';

class MHome extends StatefulWidget {
  @override
  MHomeState createState() {
    return MHomeState();
  }
}

class MHomeState extends State<MHome> {
  StreamSubscription<List<PurchaseDetails>> _subscription;
  final serviceAgent = ServiceAgent();

  _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    final userState = Provider.of<UserState>(context);

    if (purchases.isEmpty) return;

    if (purchases.first.status == PurchaseStatus.purchased) {
      InAppPurchaseConnection.instance.completePurchase(purchases.first);

      userState.setPremium(true);

      if (!userState.isIncognitoMode) {
        serviceAgent.state = userState;
        serviceAgent.setUserPremiumPurchased(userState.userId, true);
      }

      MSnackBar.showSnackBar("Premium features successfully unlocked", true);
    } else if(purchases.first.status == PurchaseStatus.error && purchases.first.error.details != "") {
      MSnackBar.showSnackBar(purchases.first.error.details , false);
    } else if (purchases.first.status == PurchaseStatus.pending) {
      MSnackBar.showSnackBar("Your request is being processed. It can take a while", true);
    } else {
      MSnackBar.showSnackBar("Not available now. Please try later", false);
    }
  }

  @override
  void initState() {
    final Stream purchaseUpdates =
        InAppPurchaseConnection.instance.purchaseUpdatedStream;
    _subscription = purchaseUpdates.listen((purchases) {
      _handlePurchaseUpdates(purchases);
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<ThemeState>(context);
    final userState = Provider.of<UserState>(context);
    final loaderState = Provider.of<LoaderState>(context);
    MTheme theme = themeState.selectedTheme;

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

    Widget widgetToReturn = userState.isAppLoaded
        ? userState.isUserAuthorizedOrInIncognitoMode ? MyMovies() : Login()
        : Text('');

    return MaterialApp(
        home: Stack(
          children: <Widget>[
            widgetToReturn,
            if (loaderState.isLoaderVisible) LoadingAnimation(),
          ],
        ),
        routes: {
          // When navigating to the "/second" route, build the SecondScreen widget.
          'moviesList': (context) => MoviesListPage(),
        },
        theme: ThemeData(
          // Define the default brightness and colors.
          brightness: theme.brightness,
          primaryColor: theme.colorTheme.primaryColor,
          accentColor: theme.colorTheme.additionalColor,
          hintColor: theme.colorTheme.fontsColor,
          cardColor: theme.colorTheme.secondaryColor,
          highlightColor: theme.colorTheme.fontsColor,
          splashColor: theme.colorTheme.primaryColor,

          textTheme: TextTheme(
//            headline1: themeState.selectedTheme.textStyleTheme.bodyText,
            headline2: theme.textStyleTheme.expandedTitle,
            headline3: theme.textStyleTheme.title,
            headline4: theme.textStyleTheme.subtitleText,
            headline5: theme.textStyleTheme.bodyText,
            headline6: theme.textStyleTheme.expandedTitle,
          ),
        ));
  }
}
