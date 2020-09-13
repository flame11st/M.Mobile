import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'BoxShadowNeomorph.dart';

class FilterIcon extends StatelessWidget {
  final IconData icon;
  final String text;
  final onPressedCallback;
  final bool isActive;
  final double textSize;
  final Color iconColor;

  FilterIcon({this.icon, this.text, this.onPressedCallback, this.isActive, this.textSize, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Theme.of(context).accentColor : Theme.of(context).hintColor;
    return GestureDetector(
        onTap: () => onPressedCallback(),
        child: Container(
            height: 50,
            width: 130,
            decoration: new BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.2),
                        offset: Offset(-2.0, -2.0),
                        blurRadius: 4,
                    ),
                    BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        offset: Offset(4.0, 4.0),
                        blurRadius: 6,
                    ),
                ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                if(icon != null) Icon(
                  icon,
                  size: 25,
                    color: iconColor == null ? color : iconColor,
                ),
                Text(text, style: TextStyle(color: color, fontSize: textSize != null ? textSize : 15),)
              ],
            )));
  }
}
