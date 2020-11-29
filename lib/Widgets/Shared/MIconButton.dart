import 'package:flutter/material.dart';

class MIconButton extends StatelessWidget {
  final onPressedCallback;
  final icon;
  final width;
  final color;
  final String hint;
  final bool withBorder;
  final fontColor;

  MIconButton(
      {this.icon,
      this.onPressedCallback,
      this.width,
      this.color,
      this.hint,
      this.withBorder = true,
      this.fontColor});

  @override
  Widget build(BuildContext context) {
    var itemsColor = fontColor != null ? fontColor : Theme.of(context).hintColor;

    return Material(
        shadowColor: Colors.transparent,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (withBorder)
              Column(
                children: [
                  Container(
                      width: width != null ? width : 50,
                      decoration: BoxDecoration(
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.8),
                            offset: Offset(0.0, 0.5),
                            blurRadius: 1,
                          ),
                        ],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: icon,
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onPressed: () => onPressedCallback(),
                      )),
                  if (hint != null && hint.isNotEmpty)
                    SizedBox(
                      height: 4,
                    ),
                  if (hint != null && hint.isNotEmpty)
                    Text(
                      hint,
                      style: TextStyle(fontSize: 15, color: itemsColor),
                    )
                ],
              ),
            if (!withBorder)
              GestureDetector(
                  onTap: () => onPressedCallback(),
                  child: Container(
                    width: width != null ? width : 55,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    child: Column(
                      children: [
                        icon,
                        if (hint != null && hint.isNotEmpty)
                          SizedBox(
                            height: 4,
                          ),
                        if (hint != null && hint.isNotEmpty)
                          Text(
                            hint,
                            style: TextStyle(fontSize: 15, color: itemsColor),
                          )
                      ],
                    ),
                  )),
            // IconButton(
            //   icon: icon,
            //   highlightColor: Colors.transparent,
            //   splashColor: Colors.transparent,
            //   onPressed: () => onPressedCallback(),
            // ),
          ],
        ));
  }
}
