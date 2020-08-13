import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/BoxShadowNeomorph.dart';

class MIconButton extends StatelessWidget {
  final onPressedCallback;
  final icon;
  final width;
  final color;

  MIconButton({this.icon, this.onPressedCallback, this.width, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
        shadowColor: Colors.transparent,
        color: Colors.transparent,
        child: Container(
            width: width != null ? width : 50,
            decoration: BoxDecoration(
              boxShadow: BoxShadowNeomorph.circleShadow,
              color: color == null ? Theme.of(context).primaryColor : color,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: icon,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onPressed: () => onPressedCallback(),
            )));
  }
}
