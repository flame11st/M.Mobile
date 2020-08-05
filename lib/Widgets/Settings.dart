import 'package:flutter/material.dart';

class Settings extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
          color: Colors.green,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Hero(
                tag: 'settings',
                child: Icon(Icons.settings, size: 20,),
              ),
              RaisedButton(
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          )
      ),
    );
  }
}