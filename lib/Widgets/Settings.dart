import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mmobile/Objects/User.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Validators.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/ChangeThemes.dart';
import 'package:mmobile/Widgets/Providers/ThemeState.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import 'package:mmobile/Widgets/Shared/MSnackBar.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';
import 'Providers/UserState.dart';
import 'Shared/MIconButton.dart';
import 'Shared/MCard.dart';
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
  bool showClearMoviesButtons = false;

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

  removeUser(String userId, UserState userState, MoviesState moviesState,
      ThemeState themeState) async {
    var removeUserResponse = await serviceAgent.deleteUser(userId);

    if (removeUserResponse.statusCode == 200) {
      userState.logout();
      moviesState.logout();
      themeState.logout();
      Navigator.of(context).pop();
    } else {
      MSnackBar.showSnackBar('Something went wrong', false, context);
    }
  }

  changeTheme() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => ChangeThemes()));
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
    final themeState = Provider.of<ThemeState>(context);

    userMoviesCount = moviesState.userMovies.length;

    if (serviceAgent.state == null) serviceAgent.state = userState;

    if (initialUserName == null && userState.user != null)
      nameController.text = initialUserName = userState.user.name;

    if (initialUserEmail == null && userState.user != null)
      emailController.text = initialUserEmail = userState.user.email;

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
              'Settings',
              style: Theme.of(context).textTheme.headline5,
            )
          ],
        ),
        Row(
          children: <Widget>[
            MaterialButton(
              child: Row(
                children: <Widget>[
                  Text(
                    'Sign out',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  new Icon(
                    Entypo.logout,
                    size: 25,
                    color: Theme.of(context).hintColor,
                  )
                ],
              ),
              onPressed: () {
                userState.logout();
                moviesState.logout();
                themeState.logout();
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      ],
    );

    final nameField = MCard(
      text: "Name",
      child: Form(
        key: _formNameKey,
        child: TextFormField(
          style: Theme.of(context).textTheme.headline5,
          decoration: InputDecoration(
            fillColor: Colors.redAccent,
          ),
          validator: (value) {
            return nameController.text.isEmpty ? 'Name can\'t be empty' : null;
          },
          controller: nameController,
        ),
      ),
      button: MButton(
        text: 'Change name',
        onPressedCallback: () => changeUserInfo(userState.userId,
            nameController.text, initialUserEmail, userState.user, 'Name'),
        active: nameButtonActive,
      ),
    );

    final emailField = MCard(
      text: "Email",
      child: Form(
          key: _formEmailKey,
          child: TextFormField(
            style: Theme.of(context).textTheme.headline5,
            validator: (value) {
              return emailController.text.isEmpty
                  ? 'Email can\'t be empty'
                  : Validators.emailValidator(emailController.text);
            },
            controller: emailController,
          )),
      button: MButton(
        text: 'Change Email',
        onPressedCallback: () => changeUserInfo(userState.userId,
            initialUserName, emailController.text, userState.user, 'Email'),
        active: emailButtonActive,
      ),
    );

    final changeThemeField = MCard(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        RichText(
            text: TextSpan(
          style: Theme.of(context).textTheme.headline5,
          children: <TextSpan>[
            new TextSpan(
                text: 'Theme:  ',
                style: Theme.of(context).textTheme.headline3),
            new TextSpan(
                text: themeState.selectedTheme.name,
                style: Theme.of(context).textTheme.headline5)
          ],
        )),
        MButton(
          onPressedCallback: () => changeTheme(),
          text: 'Change',
          active: true,
        )
      ],
    ));

    final userMoviesCountField = MCard(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        RichText(
            text: TextSpan(
          style: Theme.of(context).textTheme.headline5,
          children: <TextSpan>[
            new TextSpan(
                text: 'User movies count:   ',
                style: Theme.of(context).textTheme.headline3),
            new TextSpan(text: userMoviesCount.toString())
          ],
        )),
        MButton(
          text: 'Clear all',
          onPressedCallback: () {
            showDialog<String>(
                context: context,
                builder: (BuildContext context1) => AlertDialog(
                  backgroundColor: Theme.of(context).primaryColor,
                      contentTextStyle: Theme.of(context).textTheme.headline5,
                      content:
                          Text('Are You really want to clear your movies?'),
                      actions: [
                        MButton(
                          active: true,
                          text: 'Yes, clear all',
                          parentContext: context,
                          onPressedCallback: () {
                            clearUserMovies(userState.userId);
                            moviesState.clear();

                            Navigator.of(context1).pop();
                          },
                        ),
                        SizedBox(width: 10,),
                        MButton(
                          active: true,
                          text: 'Cancel',
                          parentContext: context,
                          onPressedCallback: () => Navigator.of(context1).pop(),
                        )
                      ],
                    ));
          },
          active: true,
        )
      ],
    ));

    final changePasswordField = MCard(
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
              Text(
                'Old Password',
                style: Theme.of(context).textTheme.headline5,
              ),
              TextFormField(
                style: Theme.of(context).textTheme.headline5,
                validator: (value) => oldPasswordController.text.isNotEmpty
                    ? Validators.passwordValidator(oldPasswordController.text)
                    : null,
                controller: oldPasswordController,
                obscureText: true,
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                'New Password',
                style: Theme.of(context).textTheme.headline5,
              ),
              TextFormField(
                style: Theme.of(context).textTheme.headline5,
                validator: (value) {
                  if (newPasswordController.text.isEmpty) return null;

                  var result =
                      Validators.passwordValidator(newPasswordController.text);
                  if (result == null)
                    result = Validators.passwordsMatchValidator(
                        newPasswordController.text,
                        confirmPasswordController.text);
                  return result;
                },
                controller: newPasswordController,
                obscureText: true,
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                'Confirm Password',
                style: Theme.of(context).textTheme.headline5,
              ),
              TextFormField(
                style: Theme.of(context).textTheme.headline5,
                validator: (value) {
                  if (confirmPasswordController.text.isEmpty) return null;

                  var result = Validators.passwordValidator(
                      confirmPasswordController.text);
                  if (result == null)
                    result = Validators.passwordsMatchValidator(
                        newPasswordController.text,
                        confirmPasswordController.text);
                  return result;
                },
                controller: confirmPasswordController,
                obscureText: true,
              )
            ],
          ),
        ));

    final removeUserField = MCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          MButton(
            text: 'Remove user',
            active: true,
            onPressedCallback: () {
              showDialog<String>(
                  context: context,
                  builder: (BuildContext context1) =>
                      AlertDialog(
                        backgroundColor: Theme
                            .of(context)
                            .primaryColor,
                        contentTextStyle: Theme
                            .of(context)
                            .textTheme
                            .headline5,
                        content:
                        Text('Are You really want to remove your user?'),
                        actions: [
                          MButton(
                            active: true,
                            text: 'Yes, remove',
                            parentContext: context,
                            onPressedCallback: () {
                              removeUser(userState.userId, userState, moviesState,
                                  themeState);

                              Navigator.of(context1).pop();
                            },
                          ),
                          SizedBox(width: 10,),
                          MButton(
                            active: true,
                            text: 'Cancel',
                            parentContext: context,
                            onPressedCallback: () =>
                                Navigator.of(context1).pop(),
                          )
                        ],
                      ));
            },
            height: 40,
          ),
        ],
      ),
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
                    if (!userState.isSignedInWithGoogle) emailField,
                    changeThemeField,
                    userMoviesCountField,
                    if (!userState.isSignedInWithGoogle) changePasswordField,
                    removeUserField
                  ],
                )),
          ),
        ));
  }
}
