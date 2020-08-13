import 'package:flutter/material.dart';
import 'package:mmobile/Widgets/Providers/LoaderState.dart';
import 'package:mmobile/Widgets/Providers/ThemeState.dart';
import 'package:provider/provider.dart';
import 'Widgets/MHome.dart';
import 'Widgets/Providers/MoviesState.dart';
import 'Widgets/Providers/UserState.dart';

void main() {
  runApp(ChangeNotifierProvider(
      builder: (context) => UserState(),
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
          )),
      ));
}
