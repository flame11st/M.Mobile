import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'Login.dart';
import 'MState.dart';
import 'MyMovies.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Services/ServiceAgent.dart';
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
        );
    }
}