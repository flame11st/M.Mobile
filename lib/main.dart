import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mmobile/Widgets/Providers/loader_state.dart';
import 'package:mmobile/Widgets/Providers/theme_state.dart';
import 'package:provider/provider.dart';
import 'Widgets/m_home.dart';
import 'Widgets/Providers/movies_state.dart';
import 'Widgets/Providers/user_state.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserState()),
        ChangeNotifierProvider(create: (context) => MoviesState()),
        ChangeNotifierProvider(create: (context) => LoaderState()),
        ChangeNotifierProvider(create: (context) => ThemeState()),
      ],
      child: MaterialApp(
        title: 'MovieDiary',
        home: MHome(),
      ),
    ),
  );
}
