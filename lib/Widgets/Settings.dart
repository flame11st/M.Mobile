import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mmobile/Objects/User.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import 'package:mmobile/Widgets/Shared/MSnackBar.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';
import 'Providers/UserState.dart';
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
  final serviceAgent = new ServiceAgent();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  final _formNameKey = GlobalKey<FormState>();
  final _formEmailKey = GlobalKey<FormState>();
  final _formChangePasswordKey = GlobalKey<FormState>();

  String initialUserName;
  String initialUserEmail;

  bool nameButtonActive = false;
  bool emailButtonActive = false;
  bool changePasswordButtonActive = false;
  bool showRemoveUserButtons = false;

  int userMoviesCount = 0;

  setNameButtonActive() {
    var nameButtonActive = _formNameKey.currentState != null &&
        _formNameKey.currentState.validate() &&
        nameController.text != initialUserName;

    if (nameButtonActive == this.nameButtonActive) return;

    setState(() {
      this.nameButtonActive = nameButtonActive;
    });
  }

  setEmailButtonActive() {
    var emailButtonActive = _formEmailKey.currentState != null &&
        _formEmailKey.currentState.validate() &&
        emailController.text != initialUserEmail;

    if (emailButtonActive == this.emailButtonActive) return;

    setState(() {
      this.emailButtonActive = emailButtonActive;
    });
  }

  setChangePasswordButtonActive() {
    var changePasswordButtonActive =
        _formChangePasswordKey.currentState.validate() &&
            newPasswordController.text.length > 0 &&
            oldPasswordController.text.length > 0 &&
            confirmPasswordController.text.length > 0;

    if (this.changePasswordButtonActive != changePasswordButtonActive) {
      setState(() {
        this.changePasswordButtonActive = changePasswordButtonActive;
      });
    }
  }

  changeUserInfo(
      String userId, String name, String email, User user, String field) async {
    var changeUserInfoResponse =
        await serviceAgent.changeUserInfo(userId, name, email);

    if (changeUserInfoResponse.statusCode == 200) {
      MSnackBar.showSnackBar('$field successfully changed', true,
          MyGlobals.scaffoldSettingsKey.currentContext);

      initialUserName = name;
      initialUserEmail = email;

      user.name = name;
      user.email = email;

      setNameButtonActive();
      setEmailButtonActive();
    }
  }

  changePassword(String userId, String oldPassword, String newPassword) async {
    var changePasswordResponse =
        await serviceAgent.changeUserPassword(userId, oldPassword, newPassword);

    if (changePasswordResponse.statusCode == 200) {
      MSnackBar.showSnackBar('Password successfully changed', true,
          MyGlobals.scaffoldSettingsKey.currentContext);
    } else {
      MSnackBar.showSnackBar('Incorrect old password', false,
          MyGlobals.scaffoldSettingsKey.currentContext);
    }
  }

  clearUserMovies(String userId) async {
    var clearMoviesResponse = await serviceAgent.clearUserMovies(userId);

    if (clearMoviesResponse.statusCode == 200) {
      MSnackBar.showSnackBar('All movies removed', true,
          MyGlobals.scaffoldSettingsKey.currentContext);

      setState(() {
        userMoviesCount = 0;
      });
    }
  }

  removeUser(String userId) async {
    var removeUserResponse = await serviceAgent.deleteUser(userId);

    if (removeUserResponse.statusCode == 200) {
      //TODO: Add logout logic here
    }
  }

  String emailValidator(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);

    return !regex.hasMatch(value) ? 'E-mail must be valid' : null;
  }

  String passwordValidator(String value) {
    final result = value.length < 8
        ? 'Password length should be more then 8 characters'
        : null;

    return result;
  }

  String passwordsMatchValidator(String oldValue, String newValue) {
    if (oldValue.length < 8 || newValue.length < 8) return null;

    final result = oldValue != newValue ? 'Passwords does not match' : null;

    return result;
  }

  @override
  void initState() {
    super.initState();

    nameController.addListener(setNameButtonActive);
    emailController.addListener(setEmailButtonActive);
    oldPasswordController.addListener(setChangePasswordButtonActive);
    newPasswordController.addListener(setChangePasswordButtonActive);
    confirmPasswordController.addListener(setChangePasswordButtonActive);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MyGlobals.scaffoldSettingsKey == null)
      MyGlobals.scaffoldSettingsKey = new GlobalKey();

    final userState = Provider.of<UserState>(context);
    final moviesState = Provider.of<MoviesState>(context);

    userMoviesCount = moviesState.userMovies.length;

    if (serviceAgent.state == null) serviceAgent.state = userState;

    if (initialUserName == null)
      nameController.text = initialUserName = userState.user.name;

    if (initialUserEmail == null)
      emailController.text = initialUserEmail = userState.user.email;

    final nameField = MTextField(
      text: "Name",
      child: Form(
        key: _formNameKey,
        child: TextFormField(
          validator: (value) {
            return nameController.text.isEmpty ? 'Name can\'t be empty' : null;
          },
          controller: nameController,
        ),
      ),
      button: MButton(
        text: 'Apply',
        onPressedCallback: () => changeUserInfo(userState.userId,
            nameController.text, initialUserEmail, userState.user, 'Name'),
        active: nameButtonActive,
      ),
    );

    final emailField = MTextField(
      text: "Email",
      child: Form(
          key: _formEmailKey,
          child: TextFormField(
            validator: (value) {
              return emailController.text.isEmpty
                  ? 'Email can\'t be empty'
                  : emailValidator(emailController.text);
            },
            controller: emailController,
          )),
      button: MButton(
        text: 'Apply',
        onPressedCallback: () => changeUserInfo(userState.userId,
            initialUserName, emailController.text, userState.user, 'Email'),
        active: emailButtonActive,
      ),
    );

    final changePasswordField = MTextField(
        text: 'Change Password',
        button: MButton(
          text: 'Change',
          onPressedCallback: () => changePassword(userState.userId,
              oldPasswordController.text, newPasswordController.text),
          active: changePasswordButtonActive,
        ),
        child: Form(
          key: _formChangePasswordKey,
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 10,
              ),
              Text('Old Password'),
              TextFormField(
                validator: (value) => oldPasswordController.text.isNotEmpty
                    ? passwordValidator(oldPasswordController.text)
                    : null,
                controller: oldPasswordController,
                obscureText: true,
              ),
              SizedBox(
                height: 5,
              ),
              Text('New Password'),
              TextFormField(
                validator: (value) {
                  if (newPasswordController.text.isEmpty) return null;

                  var result = passwordValidator(newPasswordController.text);
                  if (result == null)
                    result = passwordsMatchValidator(newPasswordController.text,
                        confirmPasswordController.text);
                  return result;
                },
                controller: newPasswordController,
                obscureText: true,
              ),
              SizedBox(
                height: 5,
              ),
              Text('Confirm Password'),
              TextFormField(
                validator: (value) {
                  if (confirmPasswordController.text.isEmpty) return null;

                  var result =
                      passwordValidator(confirmPasswordController.text);
                  if (result == null)
                    result = passwordsMatchValidator(newPasswordController.text,
                        confirmPasswordController.text);
                  return result;
                },
                controller: confirmPasswordController,
                obscureText: true,
              )
            ],
          ),
        ));

    final userMoviesCountField = MTextField(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        RichText(
            text: TextSpan(
          style: MTextStyles.BodyText,
          children: <TextSpan>[
            new TextSpan(
                text: 'User movies count:   ', style: MTextStyles.Title),
            new TextSpan(text: userMoviesCount.toString())
          ],
        )),
        MButton(
          text: 'Clear all',
          onPressedCallback: () {clearUserMovies(userState.userId); moviesState.clear(); },
          active: true,
        )
      ],
    ));

    final removeUserField = MTextField(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          MButton(
            text: 'Remove user',
            active: true,
            onPressedCallback: () => {
              setState(() => showRemoveUserButtons = !showRemoveUserButtons)
            },
            height: 40,
          ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      MIconButton(
                        icon: Icon(
                          Icons.check,
                          color: Colors.redAccent,
                        ),
                        onPressedCallback: () => removeUser(userState.userId),
                      ),
                      MIconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.greenAccent,
                        ),
                        onPressedCallback: () => setState(() =>
                            showRemoveUserButtons = !showRemoveUserButtons),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
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
          icon: new Icon(
            Entypo.logout,
            size: 25,
          ),
          onPressed: () { userState.logout(); moviesState.clear(); Navigator.of(context).pop();},
        )
      ],
    );

    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          title: headingField,
        ),
        body: Container(
          key: MyGlobals.scaffoldSettingsKey,
          child: SingleChildScrollView(
            child: Container(
//                margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                color: Theme.of(context).primaryColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
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
