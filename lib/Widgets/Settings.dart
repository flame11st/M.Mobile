import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';

import 'package:flutter_neumorphic/flutter_neumorphic.dart';
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
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool showPasswordChanging = false;

  @override
  Widget build(BuildContext context) {
    final nameField = MTextField(controller: nameController, text: "Name",);
    final emailField = MTextField(controller: emailController, text: "Email",);
    final oldPasswordField = MTextField(controller: oldPasswordController, text: "Old Password",);
    final newPasswordField = MTextField(controller: newPasswordController, text: "New Password",);
    final confirmPasswordField = MTextField(controller: confirmPasswordController, text: "Confirm Password",);

    final divider = Divider(
      color: Theme.of(context).hintColor,
      thickness: 1,
      endIndent: 0,
    );

    return Material(
        child: Container(
            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
            padding: EdgeInsets.all(20),
            color: Theme.of(context).primaryColor,
            child: ListView(
//              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                divider,
                emailField,
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    RichText( text: TextSpan(
                      style: MTextStyles.BodyText,
                      children: <TextSpan>[
                        new TextSpan(text: 'User movies count:   ', style: MTextStyles.Title),
                        new TextSpan(text: '54')
                      ],
                    )),
                    MButton(
                      text: 'Clear all',
                      onPressedCallback: () => {},
                    )
                  ],
                ),
                divider,
                  Text('Change password', style: MTextStyles.Title,),
                oldPasswordField,
                newPasswordField,
                confirmPasswordField,

                MButton(
                  text: 'Close',
                  onPressedCallback: () => Navigator.of(context).pop(),
                ),
              ],
            )));
  }
}
