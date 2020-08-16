import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:mmobile/Variables/Variables.dart';

class MSnackBar {
  static showSnackBar(String text, bool isSuccess, BuildContext context) {
    if (context == null) context = MyGlobals.scaffoldKey.currentContext;

    Scaffold.of(context).showSnackBar(SnackBar(
      content: Container(
          margin: EdgeInsets.all(0),
          height: 40,
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: TextStyle(
                    color: Theme
                        .of(context)
                        .primaryColor,
                    fontSize: 16),
              ))),
      duration: Duration(seconds: 1),
      backgroundColor: isSuccess ? Theme
          .of(MyGlobals.scaffoldKey.currentContext)
          .accentColor : Colors.redAccent,
    ));
  }
}
