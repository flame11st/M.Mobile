import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Variables/Validators.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Providers/LoaderState.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:mmobile/Widgets/Shared/MSnackBar.dart';
import 'package:mmobile/Widgets/SignUp.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Services/ServiceAgent.dart';
import 'Providers/UserState.dart';
import 'Shared/MButton.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LoginState();
  }
}

class LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final serviceAgent = ServiceAgent();
  final storage = new FlutterSecureStorage();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final _formKey = GlobalKey<FormState>();

  bool isLoaderHided = false;
  bool signInButtonActive = false;

  @override
  void initState() {
    super.initState();

    emailController.addListener(setSignInButtonActive);
    passwordController.addListener(setSignInButtonActive);
  }

  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();

    super.dispose();
  }

  signInWithGoogle() async {
    final loaderState = Provider.of<LoaderState>(context);
    loaderState.setIsLoaderVisible(true);

    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();

    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    var response =
        await serviceAgent.googleLogin(googleSignInAuthentication.idToken);

    if (response.statusCode == 200) {
      processLoginResponse(response.body, true);
    } else {
      loaderState.setIsLoaderVisible(false);
      MSnackBar.showSnackBar('Sign in with Google failed', false,
          MyGlobals.scaffoldLoginKey.currentContext);
    }
  }

  void signOutGoogle() async {}

  setSignInButtonActive() {
    var signInButtonActive = _formKey.currentState != null &&
        _formKey.currentState.validate() &&
        emailController.text.length > 0 &&
        passwordController.text.length > 0;

    if (signInButtonActive == this.signInButtonActive) return;

    setState(() {
      this.signInButtonActive = signInButtonActive;
    });
  }

  login() async {
    final loaderState = Provider.of<LoaderState>(context);
    loaderState.setIsLoaderVisible(true);

    var response =
        await serviceAgent.login(emailController.text, passwordController.text);

    if (response.statusCode == 200) {
      processLoginResponse(response.body, false);
    } else {
      loaderState.setIsLoaderVisible(false);

      MSnackBar.showSnackBar('Incorrect Email or Password', false,
          MyGlobals.scaffoldLoginKey.currentContext);
    }
  }

  getText() {
    final userState = Provider.of<UserState>(context);
    var result = userState.androidVersion == 1 || userState.androidVersion > 7
        ? '𝓜𝓸𝓿𝓲𝓮𝓓𝓲𝓪𝓻𝔂'
        : userState.androidVersion == 0 ? '𝓜𝓸𝓿𝓲𝓮𝓓𝓲𝓪𝓻𝔂' : 'MovieDiary';
    return result;
  }

  processLoginResponse(String response, bool isSignedInWithGoogle) {
    final userState = Provider.of<UserState>(context);

    userState.processLoginResponse(response, isSignedInWithGoogle);
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaderHided) {
      final loaderState = Provider.of<LoaderState>(context);
      loaderState.setIsLoaderVisible(false);
      isLoaderHided = true;
    }

    if (MyGlobals.scaffoldLoginKey == null)
      MyGlobals.scaffoldLoginKey = new GlobalKey();

    final emailField = TextFormField(
      validator: (value) => emailController.text.isNotEmpty
          ? Validators.emailValidator(emailController.text)
          : null,
      controller: emailController,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Email",
          hintStyle: Theme.of(context).textTheme.headline5),
    );

    final passwordField = TextFormField(
      validator: (value) => passwordController.text.isNotEmpty
          ? Validators.passwordValidator(passwordController.text)
          : null,
      controller: passwordController,
      obscureText: true,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
          hintText: "Password",
          hintStyle: Theme.of(context).textTheme.headline5),
    );

    final loginButton = MButton(
      text: 'Sign in',
      onPressedCallback: () => login(),
      active: signInButtonActive,
      width: MediaQuery.of(context).size.width,
      height: 40,
      prependIcon: Entypo.login,
    );

    final googleLoginButton = MButton(
      text: 'Sign in with Google',
      onPressedCallback: () => signInWithGoogle(),
      active: true,
      width: MediaQuery.of(context).size.width,
      height: 50,
      prependImage: AssetImage("Assets/google_logo.png"),
    );

    final signUpButton = MButton(
      text: 'Sign up',
      onPressedCallback: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (ctx) => SignUp()));
      },
      active: true,
      width: MediaQuery.of(context).size.width,
      height: 50,
      prependIcon: FontAwesome5.user_plus,
    );

    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Container(
          margin: EdgeInsets.only(top: 40),
          key: MyGlobals.scaffoldLoginKey,
          child: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                color: Theme.of(context).primaryColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Image(image: AssetImage("Assets/mdIcon_V_with_effect.png"), width: 130,),
                    Text(
                      getText(),
                      style: TextStyle(fontSize: 40, color: Theme.of(context).accentColor),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    MCard(
                      child: Container(
                          child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            emailField,
                            SizedBox(height: 25.0),
                            passwordField,
                            SizedBox(height: 35.0),
                            loginButton,
                          ],
                        ),
                      )),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    googleLoginButton,
                    SizedBox(
                      height: 30,
                    ),
                    signUpButton,
                  ],
                )),
          ),
        ));
  }
}
