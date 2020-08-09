import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';

class MButton extends StatelessWidget {
  final String text;
  final onPressedCallback;
  final bool active;
  final double height;

  MButton({
    this.text,
    this.onPressedCallback,
    this.active,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = active
        ? TextStyle(color: Colors.white)
        : TextStyle(color: Colors.grey.withOpacity(0.5));

    return InkWell(
        onTap: () => active ? onPressedCallback() : {},
        child: Container(
          width: 100,
          alignment: Alignment.center,
          height: height != null ? height : 25,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(active ? 0.25 : 0.1),
                offset: Offset(-3.0, -3.0),
                blurRadius: 3,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                offset: Offset(4.0, 4.0),
                blurRadius: 3,
              ),
            ],
            borderRadius: BorderRadius.circular(8.0),
            color: Theme.of(context).primaryColor,
          ),
          child: Text(text, style: textStyle),
        ));
  }
}
