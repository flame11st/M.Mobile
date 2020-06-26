import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'Login.dart';
import 'MState.dart';
import 'MyMovies.dart';

class MHome extends StatefulWidget {
  @override
  MHomeState createState() {
    return MHomeState();
  }
}

class MHomeState extends State<MHome> {
    var text = "";

    Future<void> setText() async {
        var response  = await http.get("https://mwebapi1.azurewebsites.net/api/movies/get");
        text = response.body;
    }


    @override
        void initState() {
        super.initState();
        setText();
    }

    @override
    Widget build(BuildContext context) {
        final provider = Provider.of<MState>(context);

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.blue, //or set color with: Color(0xFF0000FF)
        ));

        Widget widgetToReturn = provider.isUserAuthorized
            ? MyMovies()
            : Login();

        return MaterialApp(
            home: widgetToReturn,
        );
    }
}