import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Variables/validators.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:provider/provider.dart';
import 'Providers/loader_state.dart';
import 'Providers/user_state.dart';
import 'Shared/m_button.dart';
import 'Shared/m_card.dart';
import 'Shared/m_snack_bar.dart';

class SignUp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SignUpState();
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
      signUpButtonActive = false;
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
        nameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;

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
    GlobalKey globalKey = GlobalKey();

    if (ModalRoute.of(context)!.isCurrent) {
      MyGlobals.activeKey = globalKey;
    }

    final nameField = Theme(
        data: Theme.of(context)
            .copyWith(primaryColor: Theme.of(context).indicatorColor),
        child: TextField(
          controller: nameController,
          decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
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
              contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
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
            result ??= Validators.passwordsMatchValidator(
                  passwordController.text, confirmPasswordController.text);
            return result;
          },
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
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
            result ??= Validators.passwordsMatchValidator(
                  passwordController.text, confirmPasswordController.text);
            return result;
          },
          controller: confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              color: Theme.of(context).primaryColor,
              child: MCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      nameField,
                      const SizedBox(height: 25.0),
                      emailField,
                      const SizedBox(height: 25.0),
                      passwordField,
                      const SizedBox(height: 35.0),
                      confirmPasswordField,
                      const SizedBox(height: 35.0),
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

