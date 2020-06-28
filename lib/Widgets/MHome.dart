import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'Login.dart';
import 'MState.dart';
import 'MyMovies.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Services/ServiceAgent.dart';

class MHome extends StatefulWidget {
  @override
  MHomeState createState() {
    return MHomeState();
  }
}

class MHomeState extends State<MHome> {
//    final storage = new FlutterSecureStorage();
//    final serviceAgent = new ServiceAgent();
//
//    String token;
//    String refreshToken;
//    String userId;
//    bool isInitialized = false;
//    bool isAuthorized = false;

//    @override
//    void initState() {
//        setToken();
//        super.initState();
//    }

//    Future<void> setToken() async {
//        var storedToken = await storage.read(key: 'token');
//        var storedRefreshToken = await storage.read(key: 'refreshToken');
//        var storedUserId = await storage.read(key: 'userId');
//        var storedUserName = await storage.read(key: 'userName');
//
//        if (storedToken == null) return;
//
//        serviceAgent.token = storedToken;
//        serviceAgent.refreshToken = storedRefreshToken;
//        var isUserAuthorized = await serviceAgent.checkAuthorization();
//
//        setState(() {
//            if (isUserAuthorized) {
//                token = storedToken;
//                refreshToken = storedRefreshToken;
//            }
//
//            isAuthorized = isUserAuthorized;
//            isInitialized = true;
//        });
//    }

    @override
    Widget build(BuildContext context) {
        final provider = Provider.of<MState>(context);

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Color(0xff222831),
        ));

        Widget widgetToReturn = provider.isAppLoaded
            ? provider.isUserAuthorized ? MyMovies() : Login()
            : Text("Not loaded");

        return MaterialApp(
            home: widgetToReturn,
        );
    }
}