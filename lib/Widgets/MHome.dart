import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mmobile/Objects/MColorTheme.dart';
import 'package:mmobile/Objects/MTextStyleTheme.dart';
import 'package:mmobile/Objects/MTheme.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'Login.dart';
import 'MyMovies.dart';
import 'Providers/ThemeState.dart';
import 'Providers/UserState.dart';

class MHome extends StatefulWidget {
  @override
  MHomeState createState() {
    return MHomeState();
  }
}

class MHomeState extends State<MHome> {
  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<ThemeState>(context);
    final provider = Provider.of<UserState>(context);
    MTheme theme = themeState.selectedTheme;
    var style = SystemUiOverlayStyle(
        statusBarColor: theme.colorTheme.additionalColor,
    );
//    MTheme theme = new MTheme(
//            colorTheme: MColorTheme(
//                primaryColor: Color(0xff93b5e1),
//                secondaryColor: Color(0xff8dadd6),
//                additionalColor: Color(0xff0f4c75),
//                fontsColor: Color(0xff1b262c),
//            ),
//            textStyleTheme: MTextStyleTheme(
//                title: TextStyle(
//                        fontSize: 15,
//                        fontWeight: FontWeight.bold,
//                        color: Color(0xff0f4c75)),
//                subtitleText: TextStyle(
//                        fontSize: 15.0,
//                        color: Color(0xff0f4c75),
//                        fontWeight: FontWeight.bold),
//                bodyText: TextStyle(fontSize: 15.0, color: Color(0xff1b262c)),
//                expandedTitle: TextStyle(
//                        fontSize: 16,
//                        fontWeight: FontWeight.bold,
//                        color: Color(0xff0f4c75)),
//            ));

//      SystemChrome.restoreSystemUIOverlays();
//      SystemChrome.setSystemUIOverlayStyle(style);


    Widget widgetToReturn = provider.isAppLoaded
        ? provider.isUserAuthorized ? MyMovies() : Login()
        : Text("Not loaded");

    return MaterialApp(
        home: widgetToReturn,
        theme: ThemeData(
          // Define the default brightness and colors.
//          brightness: Brightness.light,
          primaryColor: theme.colorTheme.primaryColor,
          accentColor: theme.colorTheme.additionalColor,
          hintColor: theme.colorTheme.fontsColor,
          cardColor: theme.colorTheme.secondaryColor,
          highlightColor: theme.colorTheme.fontsColor,

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
