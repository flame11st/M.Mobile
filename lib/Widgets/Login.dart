import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';
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
  final TargetPlatform? platformOverride;
  final bool loadMovieLists;

  const Login({
    super.key,
    this.platformOverride,
    this.loadMovieLists = true,
  });

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
  bool _obscurePassword = true;

  bool get _isIOS =>
      widget.platformOverride == TargetPlatform.iOS ||
      (widget.platformOverride == null && Platform.isIOS);

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
    var response = _isIOS
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

  Future<void> _openForgotPassword() async {
    final enteredEmail = emailController.text.trim();
    final resetEmailController = TextEditingController(
      text: Validators.emailValidator(enteredEmail) == null ? enteredEmail : '',
    );

    await showMd3BottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        var isSending = false;
        var wasSent = false;
        String? errorMessage;

        return Md3BottomSheetSurface(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final email = resetEmailController.text.trim();
              final isValid =
                  email.isNotEmpty && Validators.emailValidator(email) == null;

              Future<void> sendResetLink() async {
                if (!isValid || isSending || wasSent) {
                  return;
                }

                setSheetState(() {
                  isSending = true;
                  errorMessage = null;
                });

                try {
                  final response =
                      await serviceAgent.requestPasswordReset(email);
                  if (!sheetContext.mounted) {
                    return;
                  }

                  if (response.statusCode >= 200 && response.statusCode < 300) {
                    setSheetState(() {
                      isSending = false;
                      wasSent = true;
                    });
                    return;
                  }

                  setSheetState(() {
                    isSending = false;
                    errorMessage =
                        "We couldn't send a reset email. Try again later.";
                  });
                } on Object {
                  if (!sheetContext.mounted) {
                    return;
                  }
                  setSheetState(() {
                    isSending = false;
                    errorMessage =
                        "We couldn't send a reset email. Check your connection and try again.";
                  });
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reset your password',
                    style: TextStyle(
                      color: Md3Colors.text,
                      fontSize: 22,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wasSent
                        ? 'Check $email for a password reset link.'
                        : 'Enter the email for your MovieDiary account.',
                    style: const TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!wasSent)
                    TextFormField(
                      key: const Key('passwordResetEmailField'),
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter your email'
                              : Validators.emailValidator(value.trim()),
                      decoration: _inputDecoration(
                        'Email',
                        Icons.mail_outline_rounded,
                      ),
                      onChanged: (_) {
                        setSheetState(() {
                          errorMessage = null;
                        });
                      },
                      onFieldSubmitted: (_) => sendResetLink(),
                    ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        errorMessage!,
                        key: const Key('passwordResetError'),
                        style: const TextStyle(
                          color: Md3Colors.danger,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (wasSent)
                    Md3PrimaryButton(
                      key: const Key('passwordResetDoneButton'),
                      text: 'Done',
                      icon: Icons.check_rounded,
                      tonal: true,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    )
                  else
                    Md3PrimaryButton(
                      key: const Key('passwordResetSendButton'),
                      text:
                          isSending ? 'Sending reset link' : 'Send reset link',
                      icon: Icons.mark_email_read_outlined,
                      onPressed: isValid && !isSending ? sendResetLink : null,
                    ),
                ],
              );
            },
          ),
        );
      },
    );

    resetEmailController.dispose();
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

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      constraints: const BoxConstraints(minHeight: 52),
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final buttonHeight = textScale > 1.3 ? 64.0 : 52.0;

    return SizedBox(
      height: buttonHeight,
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
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.fade,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Md3Colors.border, thickness: 1)),
        Flexible(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
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
    if (widget.loadMovieLists && !isListsRequested) {
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
      key: const Key('loginEmailField'),
      validator: (value) => emailController.text.isNotEmpty
          ? Validators.emailValidator(emailController.text)
          : null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      decoration: _inputDecoration('Email', Icons.mail_outline_rounded),
    );

    final passwordField = TextFormField(
      key: const Key('loginPasswordField'),
      validator: (value) => passwordController.text.isNotEmpty
          ? Validators.passwordValidator(passwordController.text)
          : null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) {
        if (signInButtonActive) {
          login();
        }
      },
      decoration: _inputDecoration(
        'Password',
        Icons.lock_outline_rounded,
        suffixIcon: SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            key: const Key('toggleLoginPasswordVisibility'),
            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
      ),
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
      height: 52,
      onPressed: () => signInWithApple(),
    );

    final incognitoButton = SizedBox(
      height: 44,
      child: TextButton(
        key: const Key('continueWithoutAccountButton'),
        onPressed: () => proceedIncognitoMode(),
        style: TextButton.styleFrom(
          foregroundColor: Md3Colors.muted,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: const Text('Continue without account'),
      ),
    );

    final signUpButton = SizedBox(
      height: 44,
      child: TextButton(
        key: const Key('createAccountButton'),
        onPressed: () async {
          final navigator = Navigator.of(context);
          final authenticated = await navigator.push<bool>(
            MaterialPageRoute(builder: (ctx) => const SignUp()),
          );
          if (authenticated == true && mounted && navigator.canPop()) {
            navigator.pop(true);
          }
        },
        style: TextButton.styleFrom(
          foregroundColor: Md3Colors.primary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: const Text('Create account'),
      ),
    );

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardVisible = keyboardInset > 0;
    final canPop = Navigator.of(context).canPop();
    final scrollPadding = EdgeInsets.fromLTRB(
      24,
      isKeyboardVisible ? 8 : 16,
      24,
      24 + keyboardInset,
    );

    return Scaffold(
      backgroundColor: Md3Colors.background,
      body: SafeArea(
        child: AutofillGroup(
          child: SingleChildScrollView(
            key: globalKey,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: scrollPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: canPop
                          ? IconButton(
                              key: const Key('loginBackButton'),
                              tooltip: 'Back',
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Md3Colors.text,
                              ),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: const AssetImage(
                              "Assets/mdIcon_V_with_effect.png",
                            ),
                            width: isKeyboardVisible ? 40 : 48,
                            height: isKeyboardVisible ? 40 : 48,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'MovieDiary',
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: GoogleFonts.parisienne(
                                textStyle: TextStyle(
                                  fontSize: isKeyboardVisible ? 27 : 32,
                                  color: Md3Colors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 44, height: 44),
                  ],
                ),
                SizedBox(height: isKeyboardVisible ? 8 : 16),
                Text(
                  'Sign in to MovieDiary',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Md3Colors.text,
                    fontSize: isKeyboardVisible ? 25 : 30,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!isKeyboardVisible) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Sync your ratings, watchlist, and recommendations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Md3Colors.muted,
                      fontSize: 16,
                      height: 1.44,
                    ),
                  ),
                ],
                SizedBox(height: isKeyboardVisible ? 16 : 24),
                if (_isIOS) ...[
                  signInWithAppleButton,
                  const SizedBox(height: 12),
                ],
                googleLoginButton,
                const SizedBox(height: 16),
                _buildDivider('or sign in with email'),
                const SizedBox(height: 16),
                Md3Card(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        emailField,
                        const SizedBox(height: 12),
                        passwordField,
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 44,
                            child: TextButton(
                              key: const Key('forgotPasswordButton'),
                              onPressed: _openForgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: Md3Colors.primary,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        loginButton,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                signUpButton,
                const SizedBox(height: 4),
                incognitoButton,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
