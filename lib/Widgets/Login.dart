import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Variables/Validators.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Providers/LoaderState.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:mmobile/Widgets/Shared/MSnackBar.dart';
import 'package:mmobile/Widgets/SignUp.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Services/ServiceAgent.dart';
import 'Providers/MoviesState.dart';
import 'Providers/UserState.dart';
import 'Shared/MButton.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
  bool isListsRequested = false;

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

  proceedIncognitoMode() async {
    final loaderState = Provider.of<LoaderState>(context, listen: false);
    loaderState.setIsLoaderVisible(true);

    var response =
        await serviceAgent.signInIncognito();

    if (response.statusCode == 200) {
      processLoginResponse(response.body, false);
    } else {
      loaderState.setIsLoaderVisible(false);

      MSnackBar.showSnackBar('Something went wrong', false);
    }
  }

  signInWithGoogle() async {
    final loaderState = Provider.of<LoaderState>(context, listen: false);
    loaderState.setIsLoaderVisible(true);

    final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount!.authentication;

    var response = Platform.isIOS
        ? await serviceAgent.googleLoginIOS(googleSignInAuthentication.idToken!)
        : await serviceAgent.googleLogin(googleSignInAuthentication.idToken!);

    if (response.statusCode == 200) {
      processLoginResponse(response.body, true);
    } else {
      loaderState.setIsLoaderVisible(false);
      MSnackBar.showSnackBar('Sign in with Google failed', false);
    }
  }

  Future<void> signInWithApple() async {
    final loaderState = Provider.of<LoaderState>(context, listen: false);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: WebAuthenticationOptions(
        clientId: 'com.flame.moviediary-service',
        redirectUri: Uri.parse(
          'https://moviediary.site/callbacks/sign_in_with_apple',
        ),
      ),
    );

    var name = '';
    var email = '';

    if (credential.givenName != null) {
      name += credential.givenName!;
    }

    if (credential.familyName != null) {
      name += ' ${credential.familyName}';
    }

    if (credential.email != null) {
      email = credential.email!;
    }

    loaderState.setIsLoaderVisible(true);

    var response =
        await serviceAgent.appleLogin(credential.userIdentifier!, email, name);

    if (response.statusCode == 200) {
      processLoginResponse(response.body, true);
    } else {
      loaderState.setIsLoaderVisible(false);
      MSnackBar.showSnackBar('Apple sign in failed', false);
    }
  }

  void signOutGoogle() async {}

  setSignInButtonActive() {
    var signInButtonActive = _formKey.currentState != null &&
        _formKey.currentState!.validate() &&
        emailController.text.length > 0 &&
        passwordController.text.length > 0;

    if (signInButtonActive == this.signInButtonActive) return;

    setState(() {
      this.signInButtonActive = signInButtonActive;
    });
  }

  login() async {
    final loaderState = Provider.of<LoaderState>(context, listen: false);
    loaderState.setIsLoaderVisible(true);

    var response =
        await serviceAgent.login(emailController.text, passwordController.text);

    if (response.statusCode == 200) {
      processLoginResponse(response.body, false);
    } else {
      loaderState.setIsLoaderVisible(false);

      MSnackBar.showSnackBar('Incorrect Email or Password', false);
    }
  }

  processLoginResponse(String response, bool isSignedInWithThirdPartyServices) {
    final userState = Provider.of<UserState>(context, listen: false);

    userState.processLoginResponse(response, isSignedInWithThirdPartyServices);
  }

  setMoviesLists() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);

    final moviesListsResponse = await serviceAgent.getMoviesLists("");

    Iterable iterableMoviesLists = json.decode(moviesListsResponse.body);

    if (iterableMoviesLists.length != 0) {
      List<MoviesList> moviesLists = iterableMoviesLists.map((model) {
        var list = json.decode(model);
        return MoviesList.fromJson(list);
      }).toList();

      moviesState.setInitialMoviesListsIncognito(moviesLists);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isListsRequested) {
      setMoviesLists();

      isListsRequested = true;
    }

    if (!isLoaderHided) {
      final loaderState = Provider.of<LoaderState>(context);
      loaderState.setIsLoaderVisible(false);
      isLoaderHided = true;
    }

    GlobalKey globalKey = new GlobalKey();

    if (ModalRoute.of(context)!.isCurrent) {
      MyGlobals.activeKey = globalKey;
    }

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
          validator: (value) => passwordController.text.isNotEmpty
              ? Validators.passwordValidator(passwordController.text)
              : null,
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
              hintText: "Password",
              hintStyle: Theme.of(context).textTheme.headlineSmall),
        ));

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

    final signInWithAppleButton = SignInWithAppleButton(
      borderRadius: BorderRadius.circular(25),
      height: 50,
      onPressed: () => signInWithApple(),
    );

    final incognitoButton = MButton(
      text: 'Skip Authorization',
      onPressedCallback: () => proceedIncognitoMode(),
      active: true,
      width: MediaQuery.of(context).size.width,
      height: 50,
      prependIcon: FontAwesome5.user_secret,
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
          key: globalKey,
          child: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                color: Theme.of(context).primaryColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Image(
                      image: AssetImage("Assets/mdIcon_V_with_effect.png"),
                      width: 130,
                    ),
                    Text(
                      'MovieDiary',
                      style: GoogleFonts.parisienne(
                          textStyle: TextStyle(
                              fontSize: 45,
                              color: Theme.of(context).indicatorColor)),
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
                      height: 30,
                    ),
                    if (Platform.isIOS) signInWithAppleButton,
                    if (Platform.isIOS)
                      SizedBox(
                        height: 20,
                      ),
                    googleLoginButton,
                    SizedBox(
                      height: 20,
                    ),
                    signUpButton,
                    // Text(email),
                    SizedBox(
                      height: 20,
                    ),
                    incognitoButton,
                  ],
                )),
          ),
        ));
  }
}
