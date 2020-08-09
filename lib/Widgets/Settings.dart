import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import 'Shared/MIconButton.dart';
import 'Shared/MTextField.dart';
import 'package:fluttericon/entypo_icons.dart';

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
  bool showRemoveUserButtons = false;

  //          decoration: InputDecoration(
//            contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
//          ),

  @override
  Widget build(BuildContext context) {
    final nameField = MTextField(
        text: "Name",
        child: TextField(
          controller: nameController,
        ));
    final emailField = MTextField(
        text: "Email",
        child: TextField(
          controller: emailController,
        ));

    final changePasswordField = MTextField(
      text: 'Change Password',
      button: MButton(
        text: 'Change',
        onPressedCallback: () => {},
      ),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 10,),
          Text('Old Password'),
          TextField(
            controller: oldPasswordController,
          ),
          SizedBox(height: 5,),
          Text('New Password'),
          TextField(
            controller: newPasswordController,
          ),
          SizedBox(height: 5,),
          Text('Confirm Password'),
          TextField(
            controller: confirmPasswordController,
          )
        ],
      ),
    );

    final userMoviesCountField = MTextField(child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        RichText(
            text: TextSpan(
              style: MTextStyles.BodyText,
              children: <TextSpan>[
                new TextSpan(
                    text: 'User movies count:   ',
                    style: MTextStyles.Title),
                new TextSpan(text: '54')
              ],
            )),
        MButton(
          text: 'Clear all',
          onPressedCallback: () => {},
        )
      ],
    ));

    final removeUserField = MTextField(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          SizedBox(width: 10),
          Expanded(
            child: Opacity(
              opacity: showRemoveUserButtons ? 1 : 0,
              child: Column(
                children: <Widget>[
                  Text(
                    'Are you want to remove user?',
                    style: MTextStyles.BodyText,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      MIconButton(
                        icon: Icon(
                          Icons.check,
                          color: Colors.redAccent,
                        ),
                      ),
                      MIconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          MButton(
            text: 'Remove user',
            onPressedCallback: () => {
              setState(() =>
              showRemoveUserButtons = !showRemoveUserButtons)
            },
          )
        ],
      ),
    );

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              icon: new Icon(Icons.arrow_back, size: 25,),
              onPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(
              width: 10,
            ),
            Hero(
                tag: 'settings',
                child: Icon(
                  Icons.settings,
                  size: 25,
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
        IconButton(
          icon: new Icon(Entypo.logout, size: 25,),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    );

    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Container(
          child: SingleChildScrollView(
            child: Container(
                margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                padding: EdgeInsets.all(20),
                color: Theme.of(context).primaryColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    headingField,
                    nameField,
                    emailField,
                    userMoviesCountField,
                    changePasswordField,
                    removeUserField
                  ],
                )),
          ),
        ));
  }
}
