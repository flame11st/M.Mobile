import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Variables/validators.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/Providers/loader_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/sign_up.dart';
import 'package:provider/provider.dart';
import '../Services/service_agent.dart';
import 'Providers/movies_state.dart';
import 'Providers/user_state.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<StatefulWidget> createState() {
    return LoginState();
  }
}

class LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final serviceAgent = ServiceAgent();
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
    final userState = Provider.of<UserState>(context, listen: false);
    final wasAlreadyAnonymous = userState.isIncognitoMode;
    loaderState.setIsLoaderVisible(true);

    final created = await userState.ensureAnonymousProfile();

    if (created) {
      if (!wasAlreadyAnonymous) {
        await userState.setOnboardingSkipped(true);
      }
      loaderState.setIsLoaderVisible(false);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(false);
      }
    } else {
      loaderState.setIsLoaderVisible(false);

      MSnackBar.showSnackBar('Something went wrong', false);
    }
  }

  signInWithGoogle() async {
    final loaderState = Provider.of<LoaderState>(context, listen: false);
    loaderState.setIsLoaderVisible(true);

    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    if (googleSignInAccount == null) {
      loaderState.setIsLoaderVisible(false);
      return;
    }

    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final incognitoUserId = _currentIncognitoUserId();
    var response = Platform.isIOS
        ? await serviceAgent.googleLoginIOS(googleSignInAuthentication.idToken!,
            incognitoUserId: incognitoUserId)
        : await serviceAgent.googleLogin(googleSignInAuthentication.idToken!,
            incognitoUserId: incognitoUserId);

    if (response.statusCode == 200) {
      await processLoginResponse(response.body, true);
    } else {
      loaderState.setIsLoaderVisible(false);
      MSnackBar.showSnackBar('Sign in with Google failed', false);
    }
  }

  Future<void> signInWithApple() async {
    final loaderState = Provider.of<LoaderState>(context, listen: false);

    AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
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
    } on SignInWithAppleAuthorizationException catch (error) {
      loaderState.setIsLoaderVisible(false);
      if (error.code != AuthorizationErrorCode.canceled) {
        MSnackBar.showSnackBar('Apple sign in failed', false);
      }
      return;
    }

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

    var response = await serviceAgent.appleLogin(
        credential.userIdentifier!, email, name,
        incognitoUserId: _currentIncognitoUserId());

    if (response.statusCode == 200) {
      await processLoginResponse(response.body, true);
    } else {
      loaderState.setIsLoaderVisible(false);
      MSnackBar.showSnackBar('Apple sign in failed', false);
    }
  }

  setSignInButtonActive() {
    var signInButtonActive = _formKey.currentState != null &&
        _formKey.currentState!.validate() &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;

    if (signInButtonActive == this.signInButtonActive) return;

    setState(() {
      this.signInButtonActive = signInButtonActive;
    });
  }

  login() async {
    final loaderState = Provider.of<LoaderState>(context, listen: false);
    loaderState.setIsLoaderVisible(true);

    var response = await serviceAgent.login(
      emailController.text,
      passwordController.text,
      incognitoUserId: _currentIncognitoUserId(),
    );

    if (response.statusCode == 200) {
      await processLoginResponse(response.body, false);
    } else {
      loaderState.setIsLoaderVisible(false);

      MSnackBar.showSnackBar('Incorrect Email or Password', false);
    }
  }

  processLoginResponse(
      String response, bool isSignedInWithThirdPartyServices) async {
    final userState = Provider.of<UserState>(context, listen: false);
    final loaderState = Provider.of<LoaderState>(context, listen: false);

    await userState.processLoginResponse(
        response, isSignedInWithThirdPartyServices);
    await userState.setOnboardingCompleted(true);
    loaderState.setIsLoaderVisible(false);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  String? _currentIncognitoUserId() {
    final userState = Provider.of<UserState>(context, listen: false);

    if (!userState.isIncognitoMode ||
        userState.userId == null ||
        userState.userId!.isEmpty) {
      return null;
    }

    return userState.userId;
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Md3Colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Md3Colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Md3Colors.primary, width: 1.4),
      ),
    );
  }

  Widget _authButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    ImageProvider? image,
    bool primary = false,
  }) {
    final background = primary ? Md3Colors.primary : Colors.white;
    final foreground = primary ? Colors.white : Md3Colors.text;
    final isEnabled = onPressed != null;

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor:
              primary ? const Color(0xffeef2f7) : const Color(0xffeef0f4),
          disabledForegroundColor: Md3Colors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color:
                  primary && isEnabled ? Md3Colors.primary : Md3Colors.border,
            ),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              Image(image: image, height: 20)
            else if (icon != null)
              Icon(icon, size: 19),
            if (image != null || icon != null) const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Md3Colors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Md3Colors.border, thickness: 1)),
      ],
    );
  }

  setMoviesLists() async {
    final moviesState = Provider.of<MoviesState>(context, listen: false);

    final moviesListsResponse = await serviceAgent.getMoviesLists("");
    final body = moviesListsResponse.body.trim();

    if (moviesListsResponse.statusCode != 200 || body.isEmpty) {
      return;
    }

    dynamic decodedMoviesLists;
    try {
      decodedMoviesLists = json.decode(body);
    } on FormatException {
      return;
    }

    if (decodedMoviesLists is! Iterable) {
      return;
    }

    if (decodedMoviesLists.isNotEmpty) {
      final moviesLists = <MoviesList>[];
      for (final model in decodedMoviesLists) {
        try {
          final list = model is String ? json.decode(model) : model;
          moviesLists.add(MoviesList.fromJson(list));
        } on Object {
          continue;
        }
      }

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

    GlobalKey globalKey = GlobalKey();

    if (ModalRoute.of(context)!.isCurrent) {
      MyGlobals.activeKey = globalKey;
    }

    final emailField = TextFormField(
      validator: (value) => emailController.text.isNotEmpty
          ? Validators.emailValidator(emailController.text)
          : null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration('Email', Icons.mail_outline_rounded),
    );

    final passwordField = TextFormField(
      validator: (value) => passwordController.text.isNotEmpty
          ? Validators.passwordValidator(passwordController.text)
          : null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: passwordController,
      obscureText: true,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) {
        if (signInButtonActive) {
          login();
        }
      },
      decoration: _inputDecoration('Password', Icons.lock_outline_rounded),
    );

    final loginButton = _authButton(
      text: 'Sign in',
      onPressed: signInButtonActive ? () => login() : null,
      primary: true,
      icon: Entypo.login,
    );

    final googleLoginButton = _authButton(
      text: 'Sign in with Google',
      onPressed: () => signInWithGoogle(),
      image: const AssetImage("Assets/google_logo.png"),
    );

    final signInWithAppleButton = SignInWithAppleButton(
      borderRadius: BorderRadius.circular(14),
      height: 50,
      onPressed: () => signInWithApple(),
    );

    final incognitoButton = _authButton(
      text: 'Continue without account',
      onPressed: () => proceedIncognitoMode(),
      icon: Icons.person_outline_rounded,
    );

    final signUpButton = _authButton(
      text: 'Create account',
      onPressed: () async {
        final navigator = Navigator.of(context);
        final authenticated = await navigator.push<bool>(
          MaterialPageRoute(builder: (ctx) => const SignUp()),
        );
        if (authenticated == true && mounted && navigator.canPop()) {
          navigator.pop(true);
        }
      },
      icon: FontAwesome5.user_plus,
    );

    final hasTypedCredentials =
        emailController.text.isNotEmpty || passwordController.text.isNotEmpty;

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardVisible = keyboardInset > 0;
    final scrollPadding = EdgeInsets.fromLTRB(
      22,
      isKeyboardVisible ? 14 : 20,
      22,
      28 + keyboardInset,
    );

    return Scaffold(
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          key: globalKey,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: scrollPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: const AssetImage("Assets/mdIcon_V_with_effect.png"),
                    width: isKeyboardVisible ? 42 : 54,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MovieDiary',
                    style: GoogleFonts.parisienne(
                      textStyle: TextStyle(
                        fontSize: isKeyboardVisible ? 30 : 36,
                        color: Md3Colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isKeyboardVisible ? 10 : 16),
              Text(
                'Sign in or try first',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: isKeyboardVisible ? 22 : 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!isKeyboardVisible) ...[
                const SizedBox(height: 8),
                const Text(
                  "Keep your movie taste synced, or continue without an account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                incognitoButton,
              ],
              SizedBox(height: isKeyboardVisible ? 14 : 18),
              _buildSectionLabel('Email and password'),
              const SizedBox(height: 10),
              Md3Card(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      emailField,
                      const SizedBox(height: 14),
                      passwordField,
                      const SizedBox(height: 18),
                      loginButton,
                      if (!signInButtonActive) ...[
                        const SizedBox(height: 12),
                        Text(
                          hasTypedCredentials
                              ? 'Enter a valid email and password to continue.'
                              : 'Enter your email and password to continue.',
                          style: const TextStyle(
                            color: Md3Colors.muted,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildDivider('Or continue with'),
              const SizedBox(height: 18),
              if (Platform.isIOS) ...[
                signInWithAppleButton,
                const SizedBox(height: 12),
              ],
              googleLoginButton,
              const SizedBox(height: 12),
              signUpButton,
              if (isKeyboardVisible) ...[
                const SizedBox(height: 14),
                incognitoButton,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
