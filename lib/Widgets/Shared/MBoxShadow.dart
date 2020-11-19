import 'package:flutter/material.dart';

class MBoxShadow {
  static final shadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.8),
      offset: Offset(0.0, 0.5),
      blurRadius: 1,
    ),
  ];

  static final circleShadow = [
    BoxShadow(
        color: Colors.black.withOpacity(0.8),
        offset: Offset(0.0, 0.1),
        blurRadius: 0.25
    ),
  ];
}
