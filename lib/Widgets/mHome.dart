import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'bottomNavigationBar.dart';

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
    return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(text),
          ),
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