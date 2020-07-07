import 'package:flutter/material.dart';

class BoxShadowNeomorph {
  static final shadow = [
    BoxShadow(
      color: Colors.white.withOpacity(0.2),
      offset: Offset(-4.0, -4.0),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      offset: Offset(6.0, 6.0),
      blurRadius: 12,
    ),
  ];

  static final circleShadow = [
    BoxShadow(
      color: Colors.white.withOpacity(0.2),
      offset: Offset(-4.0, -4.0),
      blurRadius: 10,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      offset: Offset(6.0, 6.0),
      blurRadius: 10,
    ),
  ];
}
