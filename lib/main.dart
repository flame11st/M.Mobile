import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mmobile/Widgets/Providers/loader_state.dart';
import 'package:provider/provider.dart';

import 'Widgets/Providers/movies_state.dart';
import 'Widgets/Providers/user_state.dart';
import 'Widgets/m_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xfff7f8fa),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    RootRestorationScope(
      restorationId: 'movieDiaryRoot',
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => UserState()),
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
