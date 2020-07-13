import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Widgets/MHome.dart';
import 'Widgets/Providers/MoviesState.dart';
import 'Widgets/Providers/UserState.dart';


void main() {
    runApp(
        ChangeNotifierProvider(
            builder: (context) => UserState(),
            child: ChangeNotifierProvider(
              create: (context) => MoviesState(),
              child: MaterialApp(
                title: 'MovieDiary',
                home: MHome(),
              ),
            ))
    );
}