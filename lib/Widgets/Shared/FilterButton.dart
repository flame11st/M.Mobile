import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'MBoxShadow.dart';

class FilterIcon extends StatelessWidget {
  final IconData icon;
  final String text;
  final onPressedCallback;
  final bool isActive;
  final double textSize;
  final Color iconColor;

  FilterIcon(
      {this.icon,
      this.text,
      this.onPressedCallback,
      this.isActive,
      this.textSize,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Theme.of(context).accentColor
        : Theme.of(context).cardColor;
    final fontColor =
        isActive ? Theme.of(context).primaryColor : Theme.of(context).hintColor;
    return GestureDetector(
        onTap: () => onPressedCallback(),
        child: Container(
            height: 50,
            width: 160,
            decoration: new BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  offset: Offset(0.0, 0.1),
                  blurRadius: 0.25
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                if (icon != null)
                  Icon(
                    icon,
                    size: 25,
                    color: iconColor == null ? fontColor : iconColor,
                  ),
                Text(
                  text,
                  style: TextStyle(
                      color: fontColor, fontSize: textSize != null ? textSize : 15),
                )
              ],
            )));
  }
}
