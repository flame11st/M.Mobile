import 'package:flutter/material.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';

class Premium extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.settings,
              size: 25,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Premium',
              style: Theme.of(context).textTheme.headline5,
            )
          ],
        ),
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
//                margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              color: Theme.of(context).primaryColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
//                                      nameField,
//                                      if (!userState.isSignedInWithGoogle) emailField,
//                                      userMoviesCountField,
//                                      if (!userState.isSignedInWithGoogle) changePasswordField,
//                                      removeUserField
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
              text: 'Buy Premium',
              active: true,
            ),
          )),
    );
  }
}
