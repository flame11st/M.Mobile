import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Variables/validators.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:provider/provider.dart';
import 'Providers/loader_state.dart';
import 'Providers/user_state.dart';
import 'Shared/m_snack_bar.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

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

    final incognitoUserId = userState.isIncognitoMode &&
            userState.userId != null &&
            userState.userId!.isNotEmpty
        ? userState.userId
        : null;
    var response = await serviceAgent.signUp(
      nameController.text,
      emailController.text,
      passwordController.text,
      incognitoUserId: incognitoUserId,
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      await userState.processLoginResponse(response.body, false);
      await userState.setOnboardingCompleted(true);

      if (!mounted) return;

      loaderState.setIsLoaderVisible(false);
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    GlobalKey globalKey = GlobalKey();

    if (ModalRoute.of(context)!.isCurrent) {
      MyGlobals.activeKey = globalKey;
    }

    final nameField = TextField(
      controller: nameController,
      textCapitalization: TextCapitalization.words,
      decoration: _inputDecoration('Name', Icons.person_outline_rounded),
    );

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
      validator: (value) {
        if (passwordController.text.isEmpty) return null;

        var result = Validators.passwordValidator(passwordController.text);
        result ??= Validators.passwordsMatchValidator(
            passwordController.text, confirmPasswordController.text);
        return result;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: passwordController,
      obscureText: true,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration('Password', Icons.lock_outline_rounded),
    );

    final confirmPasswordField = TextFormField(
      validator: (value) {
        if (confirmPasswordController.text.isEmpty) return null;

        var result =
            Validators.passwordValidator(confirmPasswordController.text);
        result ??= Validators.passwordsMatchValidator(
            passwordController.text, confirmPasswordController.text);
        return result;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: confirmPasswordController,
      obscureText: true,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) {
        if (signUpButtonActive) {
          signUp();
        }
      },
      decoration:
          _inputDecoration('Confirm password', Icons.verified_user_outlined),
    );

    final signUpButton = Md3PrimaryButton(
      text: 'Create account',
      icon: FontAwesome5.user_plus,
      onPressed: signUpButtonActive ? () => signUp() : null,
    );

    final hasStartedProfile = nameController.text.isNotEmpty ||
        emailController.text.isNotEmpty ||
        passwordController.text.isNotEmpty ||
        confirmPasswordController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Md3Colors.background,
      appBar: AppBar(
        title: const Text('Create account'),
        centerTitle: false,
        backgroundColor: Md3Colors.background,
        foregroundColor: Md3Colors.text,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: globalKey,
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start your movie diary',
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Create an account to sync ratings, your Watchlist, and recommendations.",
                style: TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              Md3Card(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      nameField,
                      const SizedBox(height: 14),
                      emailField,
                      const SizedBox(height: 14),
                      passwordField,
                      const SizedBox(height: 14),
                      confirmPasswordField,
                      const SizedBox(height: 18),
                      signUpButton,
                      if (!signUpButtonActive) ...[
                        const SizedBox(height: 12),
                        Text(
                          hasStartedProfile
                              ? 'Finish all fields with a valid email and matching passwords to continue.'
                              : 'Add your details to create and sync your MovieDiary account.',
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
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
