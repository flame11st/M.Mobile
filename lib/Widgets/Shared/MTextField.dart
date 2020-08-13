import 'package:flutter/material.dart';

class MTextField extends StatelessWidget {
  final subtitleText;
  final bodyText;

  const MTextField({Key key, this.subtitleText, this.bodyText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText( text: TextSpan(
          style: Theme.of(context).textTheme.headline5,
          children: <TextSpan>[
            new TextSpan(text: subtitleText + ': ', style: Theme.of(context).textTheme.headline4),
            new TextSpan(text: bodyText),
          ],
        ));
  }
}
