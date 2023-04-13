import 'dart:io';

import 'package:flutter/material.dart';

class RouteHelper {
  static Route createRoute(Function page) {
    if (Platform.isIOS) return MaterialPageRoute(builder: (context) => page());

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}