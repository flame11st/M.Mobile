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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserState()),
        ChangeNotifierProvider(create: (context) => MoviesState()),
        ChangeNotifierProvider(create: (context) => LoaderState()),
      ],
      child: MaterialApp(
        title: 'MovieDiary',
        home: MHome(),
      ),
    ),
  );
}
