import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';

class Premium extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          'Premium',
          style: Theme.of(context).textTheme.headline5,
        )
      ],
    );

    final titleText = Text(
      'Thanks for your interest in MovieDiary!',
      textAlign: TextAlign.center,
      style: TextStyle(
          color: Theme.of(context).accentColor,
          fontSize: 20,
          fontWeight: FontWeight.bold),
    );

    final subTitleText = Text(
      'If you like MovieDiary you can support the project by unlocking the Premium features',
      textAlign: TextAlign.center,
      style: TextStyle(
          color: Theme.of(context).hintColor,
          fontSize: 18,
          fontWeight: FontWeight.bold),
    );

    final description = Text(
      'Unlock Premium features to: ',
      textAlign: TextAlign.center,
      style: TextStyle(
          color: Theme.of(context).hintColor,
          fontSize: 18,
          fontWeight: FontWeight.bold),
    );

    final themeFeature = Column(
      children: <Widget>[
        Icon(
          Icons.format_paint,
          color: Theme.of(context).accentColor,
          size: 50,
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          'Be able to change themes.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        )
      ],
    );

    final supportFeature = Column(
      children: <Widget>[
        Icon(
          FontAwesome5.hands_helping,
          color: Theme.of(context).accentColor,
          size: 50,
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          'Support MovieDiary team',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        )
      ],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: headingField,
      ),
      body: Container(
//                  key: MyGlobals.scaffoldSettingsKey,
        child: SingleChildScrollView(
          child: Container(
              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              color: Theme.of(context).primaryColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  titleText,
                  SizedBox(
                    height: 30,
                  ),
                  subTitleText,
                  SizedBox(
                    height: 30,
                  ),
                  description,
                  SizedBox(
                    height: 20,
                  ),
                  themeFeature,
                  SizedBox(
                    height: 40,
                  ),
                  supportFeature
                ],
              )),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).primaryColor,
          child: Container(
            margin: EdgeInsets.fromLTRB(10, 0, 10, 20),
            child: MButton(
              prependIconColor: Colors.greenAccent,
              prependIcon: Icons.monetization_on,
              height: 45,
              text: 'Unlock Premium Features',
              active: true,
            ),
          )),
    );
  }
}
