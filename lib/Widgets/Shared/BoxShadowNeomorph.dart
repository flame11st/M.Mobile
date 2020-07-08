import 'package:flutter/material.dart';

class BoxShadowNeomorph {
  static final shadow = [
    BoxShadow(
      color: Colors.white.withOpacity(0.3),
      offset: Offset(-4.0, -4.0),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      offset: Offset(6.0, 6.0),
      blurRadius: 8,
    ),
  ];

  static final circleShadow = [
    BoxShadow(
      color: Colors.white.withOpacity(0.4),
      offset: Offset(-2.0, -2.0),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.6),
      offset: Offset(4.0, 4.0),
      blurRadius: 6,
    ),
  ];
}
