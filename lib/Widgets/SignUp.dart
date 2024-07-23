import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Validators.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'Providers/LoaderState.dart';
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
    setState(() {
      this.signUpButtonActive = false;
    });

    final userState = Provider.of<UserState>(context, listen: false);
    final loaderState = Provider.of<LoaderState>(context, listen: false);
    loaderState.setIsLoaderVisible(true);

    var response = await serviceAgent.signUp(
        nameController.text, emailController.text, passwordController.text);

    if (response.statusCode == 200) {
      userState.processLoginResponse(response.body, false);

      Navigator.of(context).pop();
    } else {
      MSnackBar.showSnackBar(response.body, false);
      loaderState.setIsLoaderVisible(false);
    }
  }

  setSignUpButtonActive() {
    var signUpButtonActive = _formKey.currentState != null &&
        _formKey.currentState!.validate() &&
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
    GlobalKey globalKey = new GlobalKey();

    if (ModalRoute.of(context)!.isCurrent) {
      MyGlobals.activeKey = globalKey;
    }

    final nameField = Theme(
        data: Theme.of(context)
            .copyWith(primaryColor: Theme.of(context).indicatorColor),
        child: TextField(
          controller: nameController,
          decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
              hintText: "Name",
              hintStyle: Theme.of(context).textTheme.headlineSmall),
        ));

    final emailField = Theme(
        data: Theme.of(context)
            .copyWith(primaryColor: Theme.of(context).indicatorColor),
        child: TextFormField(
          validator: (value) => emailController.text.isNotEmpty
              ? Validators.emailValidator(emailController.text)
              : null,
          controller: emailController,
          decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
              hintText: "Email",
              hintStyle: Theme.of(context).textTheme.headlineSmall),
        ));

    final passwordField = Theme(
        data: Theme.of(context)
            .copyWith(primaryColor: Theme.of(context).indicatorColor),
        child: TextFormField(
          validator: (value) {
            if (passwordController.text.isEmpty) return null;

            var result = Validators.passwordValidator(passwordController.text);
            if (result == null)
              result = Validators.passwordsMatchValidator(
                  passwordController.text, confirmPasswordController.text);
            return result;
          },
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
              hintText: "Password",
              hintStyle: Theme.of(context).textTheme.headlineSmall),
        ));

    final confirmPasswordField = Theme(
        data: Theme.of(context)
            .copyWith(primaryColor: Theme.of(context).indicatorColor),
        child: TextFormField(
          validator: (value) {
            if (confirmPasswordController.text.isEmpty) return null;

            var result =
                Validators.passwordValidator(confirmPasswordController.text);
            if (result == null)
              result = Validators.passwordsMatchValidator(
                  passwordController.text, confirmPasswordController.text);
            return result;
          },
          controller: confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
              hintText: "Confirm Password",
              hintStyle: Theme.of(context).textTheme.headlineSmall),
        ));

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
          title: Text('Create User', style: Theme.of(context).textTheme.displayMedium,),
        ),
        body: Container(
          key: globalKey,
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
              ),
            ),
          ),
        ));
  }
}
