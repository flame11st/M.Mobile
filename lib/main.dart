import 'package:flutter/material.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:mmobile/Widgets/Providers/LoaderState.dart';
import 'package:mmobile/Widgets/Providers/ThemeState.dart';
import 'package:provider/provider.dart';
import 'Widgets/MHome.dart';
import 'Widgets/Providers/MoviesState.dart';
import 'Widgets/Providers/UserState.dart';
// import 'package:flutter/services.dart';

void main() {
  InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
  // PlatformViewsService.synchronizeToNativeViewHierarchy(false);

  runApp(ChangeNotifierProvider(
    create: (context) => UserState(),
    child: ChangeNotifierProvider(
      create: (context) => MoviesState(),
      child: ChangeNotifierProvider(
        create: (context) => LoaderState(),
        child: ChangeNotifierProvider(
          create: (context) => ThemeState(),
          child: MaterialApp(
            title: 'MovieDiary',
            home: MHome(),
          ),
        ),
      ),
    ),
  ));
}
