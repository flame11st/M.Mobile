import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mmobile/Helpers/route_helper.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/movie.dart';
import 'package:mmobile/Objects/movies_list.dart';
import 'package:mmobile/Objects/user.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Variables/validators.dart';
import 'package:mmobile/Variables/variables.dart';
import 'package:mmobile/Widgets/Login.dart';
import 'package:mmobile/Widgets/Shared/m_button.dart';
import 'package:mmobile/Widgets/Shared/m_dialog.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:provider/provider.dart';
import 'premium.dart';
import 'Providers/movies_state.dart';
import 'Providers/user_state.dart';
import 'Shared/m_card.dart';
import 'package:fluttericon/entypo_icons.dart';

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SettingsState();
  }
}

class SettingsState extends State<Settings> {
  final serviceAgent = ServiceAgent();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final removeController = TextEditingController();

  final _formNameKey = GlobalKey<FormState>();
  final _formEmailKey = GlobalKey<FormState>();
  final _formChangePasswordKey = GlobalKey<FormState>();

  String? initialUserName;
  String? initialUserEmail;

  bool nameButtonActive = false;
  bool emailButtonActive = false;
  bool changePasswordButtonActive = false;
  bool showRemoveUserButtons = false;
  bool showClearMoviesButtons = false;

  int userMoviesCount = 0;

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(
      String label, String value, Color accent, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Md3Colors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Md3Colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Md3Colors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Md3Colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  setNameButtonActive() {
    var nameButtonActive = _formNameKey.currentState != null &&
        _formNameKey.currentState!.validate() &&
        nameController.text != initialUserName;

    if (nameButtonActive == this.nameButtonActive) return;

    setState(() {
      this.nameButtonActive = nameButtonActive;
    });
  }

  setEmailButtonActive() {
    var emailButtonActive = _formEmailKey.currentState != null &&
        _formEmailKey.currentState!.validate() &&
        emailController.text != initialUserEmail;

    if (emailButtonActive == this.emailButtonActive) return;

    setState(() {
      this.emailButtonActive = emailButtonActive;
    });
  }

  setChangePasswordButtonActive() {
    var changePasswordButtonActive =
        _formChangePasswordKey.currentState!.validate() &&
            newPasswordController.text.isNotEmpty &&
            oldPasswordController.text.isNotEmpty &&
            confirmPasswordController.text.isNotEmpty;

    if (this.changePasswordButtonActive != changePasswordButtonActive) {
      setState(() {
        this.changePasswordButtonActive = changePasswordButtonActive;
      });
    }
  }

  restorePurchases() async {
    final bool available = await InAppPurchase.instance.isAvailable();

    if (!available) {
      MSnackBar.showSnackBar("Not available now. Please try later", false);

      return;
    }

    await InAppPurchase.instance.restorePurchases();
  }

  changeUserInfo(
      String userId, String name, String email, User user, String field) async {
    var changeUserInfoResponse =
        await serviceAgent.changeUserInfo(userId, name, email);

    if (changeUserInfoResponse.statusCode == 200) {
      MSnackBar.showSnackBar('$field successfully changed', true);

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
      MSnackBar.showSnackBar('Password successfully changed', true);
    } else {
      MSnackBar.showSnackBar('Incorrect old password', false);
    }
  }

  clearUserMovies(String userId) async {
    var clearMoviesResponse = await serviceAgent.clearUserMovies(userId);

    if (clearMoviesResponse.statusCode == 200) {
      MSnackBar.showSnackBar('All movies removed', true);
    }
  }

  removeUser(
      String userId, UserState userState, MoviesState moviesState) async {
    var text = removeController.text;
    var removeUserResponse = await serviceAgent.deleteUser(userId, text);

    if (removeUserResponse.statusCode == 200) {
      if (!mounted) return;
      userState.logout();
      moviesState.logout();
      Navigator.of(context).pop();
    } else {
      MSnackBar.showSnackBar('Something went wrong', false);
    }
  }

  Future<void> _openSignIn() async {
    final authenticated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const Login()),
    );

    if (!mounted || authenticated != true) {
      return;
    }

    final userState = Provider.of<UserState>(context, listen: false);
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    var libraryRefreshed = true;

    try {
      await _reloadMergedLibrary(userState, moviesState);

      final userId = userState.userId;
      if (userId != null && userId.isNotEmpty && userState.user == null) {
        final response = await serviceAgent.getUserInfo(userId);
        if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
          await userState.setUser(User.fromJson(json.decode(response.body)));
        }
      }
    } catch (error) {
      libraryRefreshed = false;
      debugPrint('Post-sign-in library refresh failed: $error');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      initialUserName = null;
      initialUserEmail = null;
    });
    MSnackBar.showSnackBar(
      libraryRefreshed
          ? 'Account connected. Your movies are synced.'
          : 'Account connected. Your library will refresh shortly.',
      true,
    );
  }

  Future<void> _reloadMergedLibrary(
    UserState userState,
    MoviesState moviesState,
  ) async {
    final userId = userState.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final moviesResponse = await serviceAgent.getUserMovies(userId);
    if (moviesResponse.statusCode == 200 &&
        moviesResponse.body.trim().isNotEmpty) {
      final decodedMovies = json.decode(moviesResponse.body);
      if (decodedMovies is Iterable) {
        await moviesState.setUserMovies(
          decodedMovies.map((model) => Movie.fromJson(model)).toList(),
        );
      }
    }

    final listsResponse = await serviceAgent.getMoviesLists(userId);
    if (listsResponse.statusCode == 200 &&
        listsResponse.body.trim().isNotEmpty) {
      final decodedLists = json.decode(listsResponse.body);
      if (decodedLists is Iterable) {
        final lists = <MoviesList>[];
        for (final model in decodedLists) {
          final listModel = model is String ? json.decode(model) : model;
          if (listModel is Map<String, dynamic>) {
            lists.add(MoviesList.fromJson(listModel));
          }
        }
        await moviesState.setInitialMoviesLists(lists);
      }
    }
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
    GlobalKey globalKey = GlobalKey();

    if (ModalRoute.of(context)!.isCurrent) {
      MyGlobals.activeKey = globalKey;
    }

    final userState = Provider.of<UserState>(context);
    final moviesState = Provider.of<MoviesState>(context);
    userMoviesCount = moviesState.userMovies.length;
    final watchlistCount = moviesState.userMovies
        .where((movie) => movie.movieRate == MovieRate.addedToWatchlist)
        .length;
    final viewedCount = moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .length;
    final likedCount = moviesState.userMovies
        .where((movie) => movie.movieRate == MovieRate.liked)
        .length;

    if (initialUserName == null && userState.user != null) {
      nameController.text = initialUserName = userState.user!.name;
    }

    if (initialUserEmail == null && userState.user != null) {
      emailController.text = initialUserEmail = userState.user!.email;
    }

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(Icons.settings, size: 25, color: Md3Colors.primary),
            SizedBox(
              width: 10,
            ),
            Text(
              'Settings',
              style: TextStyle(
                color: Md3Colors.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            )
          ],
        ),
        Row(
          children: <Widget>[
            if (!userState.isIncognitoMode)
              MaterialButton(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Sign out',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Icon(
                      Entypo.logout,
                      size: 25,
                      color: Theme.of(context).hintColor,
                    )
                  ],
                ),
                onPressed: () {
                  userState.logout();
                  moviesState.logout();

                  AdManager.hideBanner();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ],
    );

    final accountStatusCard = Md3Card(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: userState.isIncognitoMode
                      ? const Color(0xffe8f0fb)
                      : const Color(0xffe9f7ef),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  userState.isIncognitoMode
                      ? Icons.person_outline_rounded
                      : Icons.verified_rounded,
                  color: userState.isIncognitoMode
                      ? Md3Colors.primary
                      : Md3Colors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userState.isIncognitoMode
                          ? 'Trying MovieDiary first'
                          : 'Signed in${userState.user != null && userState.user!.name.isNotEmpty ? ' as ${userState.user!.name}' : ''}',
                      style: const TextStyle(
                        color: Md3Colors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userState.isIncognitoMode
                          ? 'You can keep rating movies without an account. Sign in when you want your Watchlist and Viewed history synced.'
                          : (userState.user?.email.isNotEmpty ?? false)
                              ? userState.user!.email
                              : 'Your MovieDiary account is active on this device.',
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (userState.isIncognitoMode) ...[
            const SizedBox(height: 16),
            Md3PrimaryButton(
              text: 'Sign in or create account',
              icon: Icons.login_rounded,
              onPressed: _openSignIn,
            ),
          ],
        ],
      ),
    );

    final nameField = MCard(
      color: Md3Colors.surface,
      text: "Name",
      button: MButton(
        text: 'Change name',
        onPressedCallback: () => changeUserInfo(userState.userId!,
            nameController.text, initialUserEmail!, userState.user!, 'Name'),
        active: nameButtonActive,
      ),
      child: Form(
        key: _formNameKey,
        child: Theme(
            data: Theme.of(context)
                .copyWith(primaryColor: Theme.of(context).indicatorColor),
            child: TextFormField(
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: const InputDecoration(
                fillColor: Colors.redAccent,
              ),
              validator: (value) {
                return nameController.text.isEmpty
                    ? 'Name can\'t be empty'
                    : null;
              },
              controller: nameController,
            )),
      ),
    );

    final emailField = MCard(
      color: Md3Colors.surface,
      text: "Email",
      button: MButton(
        text: 'Change Email',
        onPressedCallback: () => changeUserInfo(userState.userId!,
            initialUserName!, emailController.text, userState.user!, 'Email'),
        active: emailButtonActive,
      ),
      child: Form(
          key: _formEmailKey,
          child: Theme(
              data: Theme.of(context)
                  .copyWith(primaryColor: Theme.of(context).indicatorColor),
              child: TextFormField(
                style: Theme.of(context).textTheme.headlineSmall,
                validator: (value) {
                  return emailController.text.isEmpty
                      ? 'Email can\'t be empty'
                      : Validators.emailValidator(emailController.text);
                },
                controller: emailController,
              ))),
    );

    final premiumField = Md3Card(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: userState.isPremium
                  ? const Color(0xffe9f7ef)
                  : const Color(0xfffff4dc),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              userState.isPremium
                  ? Icons.check_circle_rounded
                  : Icons.workspace_premium_rounded,
              color:
                  userState.isPremium ? Md3Colors.success : Md3Colors.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Premium',
                  style: TextStyle(
                    color: Md3Colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userState.isPremium
                      ? 'Premium is active on this device.'
                      : 'Support MovieDiary and remove ads.',
                  style: const TextStyle(
                    color: Md3Colors.muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 124,
            child: MButton(
              text: userState.isPremium ? 'Included' : 'View plans',
              onPressedCallback: () {
                Navigator.of(context)
                    .push(RouteHelper.createRoute(() => Premium()));
              },
              active: true,
              backgroundColor: Theme.of(context).cardColor,
            ),
          ),
        ],
      ),
    );

    final userMoviesCountField = Md3Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your library',
            style: TextStyle(
              color: Md3Colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userMoviesCount == 0
                ? 'Start building your MovieDiary by saving titles to Watchlist or rating movies you have seen.'
                : 'A quick snapshot of your MovieDiary progress.',
            style: const TextStyle(
              color: Md3Colors.muted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryMetric('Watchlist', '$watchlistCount',
                  Md3Colors.primary, Icons.bookmark_rounded),
              const SizedBox(width: 10),
              _buildSummaryMetric('Viewed', '$viewedCount', Md3Colors.success,
                  Icons.visibility_rounded),
              const SizedBox(width: 10),
              _buildSummaryMetric(
                  'Liked', '$likedCount', Md3Colors.warning, Icons.favorite),
            ],
          ),
          if (userMoviesCount > 0) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Clear library'),
                style: TextButton.styleFrom(
                  foregroundColor: Md3Colors.danger,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {
                  var mDialog = MDialog(
                      context: context,
                      content: const Text(
                          'Clear every rating and Watchlist item from this device? This cannot be undone.'),
                      firstButtonText: 'Yes, clear library',
                      firstButtonCallback: () {
                        if (!userState.isIncognitoMode) {
                          clearUserMovies(userState.userId!);
                        }

                        setState(() {
                          userMoviesCount = 0;
                        });

                        moviesState.clear();
                      },
                      secondButtonText: 'Cancel',
                      secondButtonCallback: () {});

                  mDialog.openDialog();
                },
              ),
            ),
          ],
        ],
      ),
    );

    final changePasswordField = MCard(
        color: Md3Colors.surface,
        text: 'Change Password',
        button: MButton(
          text: 'Change',
          onPressedCallback: () => changePassword(userState.userId!,
              oldPasswordController.text, newPasswordController.text),
          active: changePasswordButtonActive,
        ),
        child: Form(
          key: _formChangePasswordKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(
                height: 10,
              ),
              Text(
                'Old Password',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Theme(
                  data: Theme.of(context)
                      .copyWith(primaryColor: Theme.of(context).indicatorColor),
                  child: TextFormField(
                    style: Theme.of(context).textTheme.headlineSmall,
                    validator: (value) => oldPasswordController.text.isNotEmpty
                        ? Validators.passwordValidator(
                            oldPasswordController.text)
                        : null,
                    controller: oldPasswordController,
                    obscureText: true,
                  )),
              const SizedBox(
                height: 5,
              ),
              Text(
                'New Password',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Theme(
                  data: Theme.of(context)
                      .copyWith(primaryColor: Theme.of(context).indicatorColor),
                  child: TextFormField(
                    style: Theme.of(context).textTheme.headlineSmall,
                    validator: (value) {
                      if (newPasswordController.text.isEmpty) return null;

                      var result = Validators.passwordValidator(
                          newPasswordController.text);
                      result ??= Validators.passwordsMatchValidator(
                          newPasswordController.text,
                          confirmPasswordController.text);
                      return result;
                    },
                    controller: newPasswordController,
                    obscureText: true,
                  )),
              const SizedBox(
                height: 5,
              ),
              Text(
                'Confirm Password',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Theme(
                  data: Theme.of(context)
                      .copyWith(primaryColor: Theme.of(context).indicatorColor),
                  child: TextFormField(
                    style: Theme.of(context).textTheme.headlineSmall,
                    validator: (value) {
                      if (confirmPasswordController.text.isEmpty) return null;

                      var result = Validators.passwordValidator(
                          confirmPasswordController.text);
                      result ??= Validators.passwordsMatchValidator(
                          newPasswordController.text,
                          confirmPasswordController.text);
                      return result;
                    },
                    controller: confirmPasswordController,
                    obscureText: true,
                  ))
            ],
          ),
        ));

    final removeUserField = MCard(
      color: Md3Colors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          MButton(
            text: 'Remove user',
            active: true,
            onPressedCallback: () {
              var mDialog = MDialog(
                  context: context,
                  content: SizedBox(
                    height: 143,
                    child: Column(
                      children: [
                        const Text(
                            'Are you sure you want to remove your user?'),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: removeController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              hintText:
                                  'Please tell us why are you going to remove your user.\n',
                              border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                  firstButtonText: 'Remove',
                  firstButtonCallback: () {
                    removeUser(userState.userId!, userState, moviesState);
                  },
                  secondButtonText: 'Cancel',
                  secondButtonCallback: () {});

              mDialog.openDialog();
            },
            height: 40,
          ),
        ],
      ),
    );

    return Scaffold(
        backgroundColor: Md3Colors.background,
        appBar: AdManager.bannerVisible && AdManager.bannersReady
            ? AppBar(
                title: Center(
                  child: AdManager.getBannerWidget(AdManager.settingsBannerAd),
                ),
                automaticallyImplyLeading: false,
                elevation: 0.7,
              )
            : PreferredSize(
                preferredSize: const Size(0, 0), child: Container()),
        body: Scaffold(
            backgroundColor: Md3Colors.background,
            appBar: AppBar(
              backgroundColor: Md3Colors.background,
              foregroundColor: Md3Colors.text,
              elevation: 0,
              title: headingField,
            ),
            body: Container(
              key: globalKey,
              child: SingleChildScrollView(
                child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 104),
                    color: Md3Colors.background,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        accountStatusCard,
                        if (!userState.isIncognitoMode &&
                            userState.user != null &&
                            userState.user!.name.isNotEmpty)
                          nameField,
                        if (!userState.isIncognitoMode &&
                            userState.user != null &&
                            userState.user!.email.isNotEmpty &&
                            !userState.user!.isIncognito)
                          emailField,
                        if (!userState.isIncognitoMode &&
                            userState.user != null) ...[
                          _buildSectionTitle('Account'),
                          if (!userState.isSignedInWithGoogle &&
                              !userState.user!.isIncognito)
                            changePasswordField,
                          if (!userState.user!.isIncognito) removeUserField,
                        ],
                        _buildSectionTitle(
                          'Preferences',
                          subtitle:
                              'Keep these tools lightweight so Discover and My Movies stay central.',
                        ),
                        premiumField,
                        _buildSectionTitle(
                          'Movie activity',
                          subtitle:
                              'Watchlist, Viewed, and Liked stay visible here without taking over the app.',
                        ),
                        userMoviesCountField,
                        const SizedBox(
                          height: 20,
                        ),
                        Md3Card(
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xffe8f0fb),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  color: Md3Colors.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Restore purchases',
                                      style: TextStyle(
                                        color: Md3Colors.text,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Reconnect premium purchases on this device if they do not appear automatically.',
                                      style: TextStyle(
                                        color: Md3Colors.muted,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 104,
                                child: MButton(
                                  text: 'Restore',
                                  onPressedCallback: () => restorePurchases(),
                                  active: true,
                                  height: 40,
                                  backgroundColor: Theme.of(context).cardColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
              ),
            )));
  }
}
