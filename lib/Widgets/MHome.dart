import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'Login.dart';
import 'MyMovies.dart';
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
        final provider = Provider.of<UserState>(context);

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: MColors.PrimaryColor,
        ));

        Widget widgetToReturn = provider.isAppLoaded
            ? provider.isUserAuthorized ? MyMovies() : Login()
            : Text("Not loaded");

        return MaterialApp(
            home: widgetToReturn,
            theme: ThemeData(
              // Define the default brightness and colors.
              brightness: Brightness.dark,
              primaryColor: MColors.PrimaryColor,
              accentColor: MColors.AdditionalColor,
              hintColor: MColors.FontsColor,

              // Define the default font family.
//              fontFamily: 'Roboto',

              // Define the default TextTheme. Use this to specify the default
              // text styling for headlines, titles, bodies of text, and more.
              textTheme: TextTheme(
                headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
                headline6: MTextStyles.BodyText,
              ),
            )
        );
    }
}