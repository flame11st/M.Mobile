import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:mmobile/Variables/Variables.dart';

class MSnackBar {
  static showSnackBar(String text, bool isSuccess) {
    var context = MyGlobals.activeKey.currentContext;

    if (context != null)
      show(context, text, isSuccess);
  }

  static void show(BuildContext context, String text, bool isSuccess) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Container(
          margin: EdgeInsets.all(0),
          height: 40,
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontSize: 16),
              ))),
      duration: Duration(seconds: 2),
      backgroundColor: isSuccess
          ? Theme.of(MyGlobals.activeKey.currentContext).accentColor
          : Colors.redAccent,
    ));
  }
}
