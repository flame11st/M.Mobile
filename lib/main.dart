import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mmobile/Widgets/Providers/loader_state.dart';
import 'package:mmobile/Services/monetization_service.dart';
import 'package:mmobile/Services/product_analytics.dart';
import 'package:provider/provider.dart';

import 'Widgets/Providers/movies_state.dart';
import 'Widgets/Providers/user_state.dart';
import 'Widgets/m_home.dart';
import 'Widgets/Shared/md3_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  unawaited(ProductAnalytics.instance.initialize());

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Md3Colors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    RootRestorationScope(
      restorationId: 'movieDiaryRoot',
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) {
              final service = MonetizationService();
              unawaited(service.initializeConfiguration());
              return service;
            },
          ),
          ChangeNotifierProvider(
            create: (context) => UserState(
              monetizationService: context.read<MonetizationService>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => MoviesState(
              onRatedMoviesCountChanged: (count) {
                unawaited(
                  context.read<UserState>().setCachedRatedMoviesCount(count),
                );
              },
            ),
          ),
          ChangeNotifierProvider(create: (context) => LoaderState()),
        ],
        child: MHome(),
      ),
    ),
  );
}
