import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/BoxShadowNeomorph.dart';

class MIconButton extends StatelessWidget {
  final onPressedCallback;
  final icon;
  final width;

  MIconButton({this.icon, this.onPressedCallback, this.width});

  @override
  Widget build(BuildContext context) {
    return Material(
        shadowColor: Colors.transparent,
        color: Colors.transparent,
        child: Container(
            width: width != null ? width : 50,
            decoration: BoxDecoration(
              boxShadow: BoxShadowNeomorph.circleShadow,
              color: Theme.of(context).primaryColor,
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
