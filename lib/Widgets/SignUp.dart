import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Validators.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';

import 'Providers/UserState.dart';
import 'Shared/MButton.dart';
import 'Shared/MCard.dart';
import 'Shared/MSnackBar.dart';

class SignUp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SignUpState();
  }
}

class SignUpState extends State<SignUp> {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final serviceAgent = ServiceAgent();

    bool signUpButtonActive = false;
    final _formKey = GlobalKey<FormState>();

    signUp() async {
        final userState = Provider.of<UserState>(context);

        var response = await serviceAgent.signUp(nameController.text, emailController.text, passwordController.text);

        if (response.statusCode == 200) {
            userState.processLoginResponse(response.body, false);
        } else {
            MSnackBar.showSnackBar(response.body, false,
                MyGlobals.scaffoldSignUpKey.currentContext);
        }

        Navigator.of(context).pop();
    }

    setSignUpButtonActive() {
        var signUpButtonActive = _formKey.currentState != null &&
                _formKey.currentState.validate() &&
                nameController.text.length > 0 &&
                emailController.text.length > 0 &&
                confirmPasswordController.text.length > 0 &&
                passwordController.text.length > 0;

        if (signUpButtonActive == this.signUpButtonActive) return;

        setState(() {
            this.signUpButtonActive = signUpButtonActive;
        });
    }

    @override
    void initState() {
        super.initState();

        nameController.addListener(setSignUpButtonActive);
        emailController.addListener(setSignUpButtonActive);
        confirmPasswordController.addListener(setSignUpButtonActive);
        passwordController.addListener(setSignUpButtonActive);
    }

    @override
    void dispose() {
        passwordController.dispose();
        confirmPasswordController.dispose();
        nameController.dispose();
        emailController.dispose();

        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        if (MyGlobals.scaffoldSignUpKey == null)
            MyGlobals.scaffoldSignUpKey = new GlobalKey();

        final nameField = TextField(
            controller: nameController,
            decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    hintText: "Name",
                    hintStyle: MTextStyles.BodyText),
        );

        final emailField = TextFormField(
            validator: (value) => emailController.text.isNotEmpty
                    ? Validators.emailValidator(emailController.text)
                    : null,
            controller: emailController,
            decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    hintText: "Email",
                    hintStyle: MTextStyles.BodyText),
        );

        final passwordField = TextFormField(
            validator: (value) {
                if (passwordController.text.isEmpty) return null;

                var result =
                Validators.passwordValidator(passwordController.text);
                if (result == null)
                    result = Validators.passwordsMatchValidator(
                            passwordController.text,
                            confirmPasswordController.text);
                return result;
            },
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    hintText: "Password",
                    hintStyle: MTextStyles.BodyText),
        );

        final confirmPasswordField = TextFormField(
            validator: (value) {
                if (confirmPasswordController.text.isEmpty) return null;

                var result = Validators.passwordValidator(
                        confirmPasswordController.text);
                if (result == null)
                    result = Validators.passwordsMatchValidator(
                            passwordController.text,
                            confirmPasswordController.text);
                return result;
            },
            controller: confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    hintText: "Confirm Password",
                    hintStyle: MTextStyles.BodyText),
        );

        final signUpButton = MButton(
            text: 'Sign up',
            onPressedCallback: () => signUp(),
            active: signUpButtonActive,
            width: MediaQuery.of(context).size.width,
            height: 40,
            prependIcon: FontAwesome5.user_plus,
        );


        return Scaffold(
                backgroundColor: Theme.of(context).primaryColor,
                appBar: AppBar(
                    title: Text('Create User'),
                ),
                body: Container(
                    key: MyGlobals.scaffoldSignUpKey,
                    child: SingleChildScrollView(
                        child: Container(
//                margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                                color: Theme.of(context).primaryColor,
                                child: MCard(
                                    child: Form(
                                        key: _formKey,
                                        child: Column(
                                            children: <Widget>[
                                                nameField,
                                                SizedBox(height: 25.0),
                                                emailField,
                                                SizedBox(height: 25.0),
                                                passwordField,
                                                SizedBox(height: 35.0),
                                                confirmPasswordField,
                                                SizedBox(height: 35.0),
                                                signUpButton
                                            ],
                                        ),
                                    ),
                                ),),
                    ),
                ));
    }
}
