import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'bottomNavigationBar.dart';
import 'MovieList.dart';

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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.blue, //or set color with: Color(0xFF0000FF)
    ));

    return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black26,
          ),
          body: MovieList(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              print('Floating action button pressed');
            },
            child: const Icon(Icons.add),
            backgroundColor: Colors.black,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: MoviesBottomNavigationBar(),
        ));
  }
}