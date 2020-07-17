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
    return Container(
      width: width != null ? width : 50,
      decoration: BoxDecoration(
        boxShadow: BoxShadowNeomorph.circleShadow,
        color: MColors.PrimaryColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: icon,
        onPressed: () => onPressedCallback(),
      )
    );
  }
}
