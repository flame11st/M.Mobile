import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';

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

  MCard(
      {this.text,
      this.child,
      this.button,
      this.padding,
      this.marginTop,
      this.color,
      this.shadowColor,
      this.marginLR,
      this.marginBottom});

  @override
  Widget build(BuildContext context) {
    final double marginLRValue = marginLR != null ? marginLR : 0;

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
              offset: Offset(0.0, 0.05),
            ),
          ],
          borderRadius: BorderRadius.circular(4.0),
          color: color != null ? color : Theme.of(context).cardColor,
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
