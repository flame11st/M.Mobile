import 'package:flutter/material.dart';

class MButton extends StatelessWidget {
  final text;
  final onPressedCallback;

  MButton({
    this.text,
    this.onPressedCallback,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => onPressedCallback(),
        child: Container(
          width: 100,
          alignment: Alignment.center,
          height: 40,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.25),
                offset: Offset(-4.0, -4.0),
                blurRadius: 6,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                offset: Offset(6.0, 6.0),
                blurRadius: 8,
              ),
            ],
            borderRadius: BorderRadius.circular(12.0),
            color: Theme.of(context).primaryColor,
          ),
          child: Text(text),
        ));
  }
}
