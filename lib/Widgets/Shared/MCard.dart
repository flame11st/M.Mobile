import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';

class MCard extends StatelessWidget {
  final text;
  final child;
  final button;
  final double padding;

  MCard({this.text, this.child, this.button, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(padding != null ? padding : 20),
        margin: EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              offset: Offset(-4.0, -4.0),
              blurRadius: 3,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              offset: Offset(5.0, 5.0),
              blurRadius: 6,
            ),
          ],
          borderRadius: BorderRadius.circular(12.0),
          color: Theme.of(context).primaryColor,
        ),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                if (text != null) Text(
                  text,
                  style: MTextStyles.Title,
                ),
                if (button != null) button
              ],
            ),
            if(child != null) child
          ],
        ));
  }
}
