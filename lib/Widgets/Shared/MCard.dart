import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MCard extends StatelessWidget {
  final text;
  final child;
  final button;
  final double padding;
  final double marginTop;
  final double marginBottom;
  final double marginLR;
  final Color color;
  final Color shadowColor;
  final Color foregroundColor;

  MCard(
      {this.text,
      this.child,
      this.button,
      this.padding,
      this.marginTop,
      this.color,
      this.shadowColor,
      this.marginLR,
      this.marginBottom,
      this.foregroundColor});

  @override
  Widget build(BuildContext context) {
    final double marginLRValue = marginLR != null ? marginLR : 0;
    final borderRadius = 25.0;

    return Container(
        padding: EdgeInsets.all(padding != null ? padding : 20),
        margin: EdgeInsets.only(
            top: marginTop == null ? 20 : marginTop,
            left: marginLRValue,
            right: marginLRValue,
            bottom: marginBottom != null ? marginBottom : 0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 0.5
              // offset: Offset(0.0, 0.9),
            ),
          ],
          borderRadius: BorderRadius.circular(borderRadius),
          color: color != null ? color : Theme.of(context).cardColor,
        ),
        foregroundDecoration: BoxDecoration(
            color: foregroundColor != null ? foregroundColor : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                if (text != null)
                  Text(
                    text,
                    style: Theme.of(context).textTheme.headline3,
                  ),
                if (button != null) button
              ],
            ),
            if (child != null) child
          ],
        ));
  }
}
