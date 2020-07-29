import 'package:flutter/material.dart';
import 'BoxShadowNeomorph.dart';

class FilterIcon extends StatelessWidget {
  final IconData icon;
  final String text;
  final onPressedCallback;
  final bool isActive;

  FilterIcon({this.icon, this.text, this.onPressedCallback, this.isActive});

  @override
  Widget build(BuildContext context) {
      final color = isActive ? Theme.of(context).accentColor : Theme.of(context).hintColor;
    return GestureDetector(
        onTap: () => onPressedCallback(),
        child: Container(
            height: 70,
            width: 70,
            decoration: new BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                boxShadow: BoxShadowNeomorph.circleShadow),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 25,
                    color: color,
                ),
                Text(text, style: TextStyle(color: color),)
              ],
            )));
  }
}
