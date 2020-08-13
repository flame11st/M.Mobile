import 'package:flutter/material.dart';

class LoadingAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image(
                image: AssetImage("Assets/mdIcon_V_3.png"),
                width: 150,
              ),
              Text('𝓜𝓸𝓿𝓲𝓮𝓓𝓲𝓪𝓻𝔂', style: TextStyle(fontSize: 40, color: Theme.of(context).accentColor),)
            ],
          ),
        ));
  }
}
