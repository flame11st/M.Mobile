import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';

import 'Shared/BoxShadowNeomorph.dart';
import 'Shared/MTextField.dart';

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SettingsState();
  }
}

class SettingsState extends State<Settings> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final nameField = MTextField(controller: nameController, text: "Name",);
    final emailField = MTextField(controller: emailController, text: "Email",);

    return Material(
        child: Container(
            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
            padding: EdgeInsets.all(20),
            color: Theme.of(context).primaryColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Hero(
                        tag: 'settings',
                        child: Icon(
                          Icons.settings,
                          size: 30,
                        )),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Settings',
                      style: MTextStyles.BodyText,
                    )
                  ],
                ),
                nameField,
                Divider(
                  color: Theme.of(context).hintColor,
                  thickness: 1,
                  endIndent: 0,
                ),
                emailField,
                RaisedButton(
                  child: Text('Close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            )));
  }
}
