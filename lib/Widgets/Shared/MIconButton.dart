import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/MBoxShadow.dart';

class MIconButton extends StatelessWidget {
  final onPressedCallback;
  final icon;
  final width;
  final color;
  final String hint;

  MIconButton(
      {this.icon, this.onPressedCallback, this.width, this.color, this.hint});

  @override
  Widget build(BuildContext context) {
    return Material(
        shadowColor: Colors.transparent,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: width != null ? width : 50,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.9),
                      offset: Offset(0.0, 1.0),
                      blurRadius: 2,
                    ),
                  ],
                  color: color == null ? Theme.of(context).primaryColor : color,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: icon,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onPressed: () => onPressedCallback(),
                )),
            if (hint != null && hint.isNotEmpty)
              SizedBox(height: 4,),
            if (hint != null && hint.isNotEmpty)
              Text(hint, style: Theme.of(context).textTheme.headline5,)
          ],
        ));
  }
}
