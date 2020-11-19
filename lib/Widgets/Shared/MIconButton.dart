import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/MBoxShadow.dart';

class MIconButton extends StatelessWidget {
  final onPressedCallback;
  final icon;
  final width;
  final color;
  final String hint;
  final bool withBorder;

  MIconButton(
      {this.icon,
      this.onPressedCallback,
      this.width,
      this.color,
      this.hint,
      this.withBorder = true});

  @override
  Widget build(BuildContext context) {
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.8),
                            offset: Offset(0.0, 0.5),
                            blurRadius: 1,
                          ),
                        ],
                        color: color == null
                            ? Theme.of(context).primaryColor
                            : color,
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
                      style: Theme.of(context).textTheme.headline5,
                    )
                ],
              ),
            if (!withBorder)
              GestureDetector(
                  onTap: () => onPressedCallback(),
                  child: Container(
                    width: width != null ? width : 58,
                    color: Colors.transparent,
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
                            style: Theme.of(context).textTheme.headline5,
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
