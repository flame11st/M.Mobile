import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:mmobile/Variables/Variables.dart';

class MSnackBar {
  static showSnackBar(String text, bool isSuccess, BuildContext context) {
    if (context == null)
      context = MyGlobals.scaffoldMoviesListsKey == null ||
              MyGlobals.scaffoldMoviesListsKey.currentContext == null
          ? MyGlobals.scaffoldKey.currentContext
          : MyGlobals.scaffoldMoviesListsKey.currentContext;

    show(context, text, isSuccess);
  }

  static void show(BuildContext context, String text, bool isSuccess) {
    Scaffold.of(context).hideCurrentSnackBar();
    Scaffold.of(context).showSnackBar(SnackBar(
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
          ? Theme.of(MyGlobals.scaffoldKey.currentContext).accentColor
          : Colors.redAccent,
    ));
  }
}
