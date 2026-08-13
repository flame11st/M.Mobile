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
import 'package:mmobile/Widgets/Shared/m_dialog.dart';
import 'package:mmobile/Widgets/Shared/m_snack_bar.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:provider/provider.dart';
import 'premium.dart';
import 'Providers/movies_state.dart';
import 'Providers/user_state.dart';
import 'package:fluttericon/entypo_icons.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

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
  final _scrollController = ScrollController();

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
    return Container(
      width: double.infinity,
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
    );
  }

  Widget _buildTonalButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    Key? key,
  }) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return SizedBox(
      key: key,
      height: textScale > 1.3 ? 56 : 44,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Md3Colors.primarySoft,
          foregroundColor: Md3Colors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.fade,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountEditorCard({
    required BuildContext context,
    required String title,
    required String actionLabel,
    required bool actionEnabled,
    required VoidCallback onAction,
    required Widget child,
    Key? key,
  }) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Md3Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackHeader = constraints.maxWidth < 360 || textScale > 1.3;
          final action = SizedBox(
            width: stackHeader ? double.infinity : 144,
            child: _buildTonalButton(
              context: context,
              text: actionLabel,
              onPressed: actionEnabled ? onAction : null,
            ),
          );
          final titleWidget = Text(
            title,
            style: const TextStyle(
              color: Md3Colors.text,
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stackHeader) ...[
                titleWidget,
                const SizedBox(height: 12),
                action,
              ] else
                Row(
                  children: [
                    Expanded(child: titleWidget),
                    const SizedBox(width: 12),
                    action,
                  ],
                ),
              const SizedBox(height: 16),
              child,
            ],
          );
        },
      ),
    );
  }

  InputDecoration _accountFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Md3Colors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Md3Colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Md3Colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Md3Colors.primary, width: 2),
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

  Widget _buildRestorePurchasesCard(BuildContext context) {
    final copy = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Md3Colors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.refresh_rounded,
            color: Md3Colors.primary,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restore purchases',
                style: TextStyle(
                  color: Md3Colors.text,
                  fontSize: 16,
                  height: 1.31,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Reconnect premium purchases on this device if they do not appear automatically.',
                style: TextStyle(
                  color: Md3Colors.muted,
                  fontSize: 14,
                  height: 1.43,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Md3Card(
      key: const Key('restorePurchasesCard'),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTrailingButton = constraints.maxWidth >= 568 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3;
          final restoreButton = SizedBox(
            width: useTrailingButton ? 96 : double.infinity,
            child: _buildTonalButton(
              context: context,
              text: 'Restore',
              onPressed: () => restorePurchases(),
            ),
          );

          if (useTrailingButton) {
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 16),
                restoreButton,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              const SizedBox(height: 12),
              restoreButton,
            ],
          );
        },
      ),
    );
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

  Future<void> clearUserMovies(String userId) async {
    var clearMoviesResponse = await serviceAgent.clearUserMovies(userId);

    if (clearMoviesResponse.statusCode != 200) {
      throw StateError('Clear library request failed.');
    }
  }

  Future<void> removeUser(String userId, String feedback) async {
    var removeUserResponse = await serviceAgent.deleteUser(userId, feedback);

    if (removeUserResponse.statusCode != 200) {
      throw StateError('Delete account request failed.');
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
    removeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> handleActiveTabTap() async {
    if (!_scrollController.hasClients) {
      return;
    }

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
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

    const headingField = Text(
      'Settings',
      style: TextStyle(
        color: Md3Colors.text,
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w900,
      ),
    );

    final accountStatusCard = Md3Card(
      key: const Key('settingsAccountStatusCard'),
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
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
                          ? 'Using MovieDiary without an account'
                          : 'Signed in${userState.user != null && userState.user!.name.isNotEmpty ? ' as ${userState.user!.name}' : ''}',
                      style: const TextStyle(
                        color: Md3Colors.text,
                        fontSize: 20,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userState.isIncognitoMode
                          ? 'Ratings, Watchlist, and Viewed stay with this guest profile on this device. Sign in to sync them with your account.'
                          : (userState.user?.email.isNotEmpty ?? false)
                              ? userState.user!.email
                              : 'Your MovieDiary account is active on this device.',
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 15,
                        height: 1.4,
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
              key: const Key('settingsSignInButton'),
              text: 'Sign in or create account',
              icon: Icons.login_rounded,
              onPressed: _openSignIn,
            ),
          ] else ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 44,
                child: TextButton.icon(
                  key: const Key('settingsSignOutButton'),
                  onPressed: () {
                    userState.logout();
                    moviesState.logout();
                    AdManager.hideBanner();
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Entypo.logout, size: 18),
                  label: const Text('Sign out'),
                  style: TextButton.styleFrom(
                    foregroundColor: Md3Colors.muted,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final nameField = _buildAccountEditorCard(
      context: context,
      key: const Key('settingsNameCard'),
      title: 'Name',
      actionLabel: 'Save name',
      actionEnabled: nameButtonActive,
      onAction: () => changeUserInfo(userState.userId!, nameController.text,
          initialUserEmail!, userState.user!, 'Name'),
      child: Form(
        key: _formNameKey,
        child: TextFormField(
          key: const Key('settingsNameField'),
          controller: nameController,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 16,
            height: 1.25,
          ),
          decoration: _accountFieldDecoration('Display name'),
          validator: (value) {
            return nameController.text.isEmpty ? 'Name can\'t be empty' : null;
          },
        ),
      ),
    );

    final emailField = _buildAccountEditorCard(
      context: context,
      key: const Key('settingsEmailCard'),
      title: 'Email',
      actionLabel: 'Save email',
      actionEnabled: emailButtonActive,
      onAction: () => changeUserInfo(userState.userId!, initialUserName!,
          emailController.text, userState.user!, 'Email'),
      child: Form(
        key: _formEmailKey,
        child: TextFormField(
          key: const Key('settingsEmailField'),
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            color: Md3Colors.text,
            fontSize: 16,
            height: 1.25,
          ),
          decoration: _accountFieldDecoration('Email address'),
          validator: (value) {
            return emailController.text.isEmpty
                ? 'Email can\'t be empty'
                : Validators.emailValidator(emailController.text);
          },
        ),
      ),
    );

    final premiumField = Md3Card(
      key: const Key('settingsPremiumCard'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTrailingButton = constraints.maxWidth >= 480 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3;
          final copy = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: userState.isPremium
                      ? Md3Colors.success
                      : Md3Colors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userState.isPremium ? 'Premium active' : 'Premium',
                      style: const TextStyle(
                        color: Md3Colors.text,
                        fontSize: 16,
                        height: 1.31,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userState.isPremium
                          ? 'Ads are removed for this MovieDiary profile.'
                          : 'Support MovieDiary and remove ads.',
                      style: const TextStyle(
                        color: Md3Colors.muted,
                        fontSize: 14,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final plansButton = SizedBox(
            key: const Key('settingsPremiumAction'),
            width: useTrailingButton ? 124 : double.infinity,
            child: _buildTonalButton(
              context: context,
              text: 'View plans',
              onPressed: () {
                Navigator.of(context)
                    .push(RouteHelper.createRoute(() => const Premium()));
              },
            ),
          );

          if (userState.isPremium) {
            return copy;
          }

          if (useTrailingButton) {
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 12),
                plansButton,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              const SizedBox(height: 12),
              plansButton,
            ],
          );
        },
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
          LayoutBuilder(
            builder: (context, constraints) {
              final stackMetrics = constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              final metrics = [
                _buildSummaryMetric(
                  'Watchlist',
                  '$watchlistCount',
                  Md3Colors.primary,
                  Icons.bookmark_rounded,
                ),
                _buildSummaryMetric(
                  'Viewed',
                  '$viewedCount',
                  Md3Colors.success,
                  Icons.visibility_rounded,
                ),
                _buildSummaryMetric(
                  'Liked',
                  '$likedCount',
                  Md3Colors.warning,
                  Icons.favorite,
                ),
              ];

              if (stackMetrics) {
                return Column(
                  children: [
                    metrics[0],
                    const SizedBox(height: 8),
                    metrics[1],
                    const SizedBox(height: 8),
                    metrics[2],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: metrics[0]),
                  const SizedBox(width: 10),
                  Expanded(child: metrics[1]),
                  const SizedBox(width: 10),
                  Expanded(child: metrics[2]),
                ],
              );
            },
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
                onPressed: () async {
                  final cleared = await showMd3ConfirmationDialog(
                    context: context,
                    title: 'Clear your library?',
                    body:
                        'This removes every rating and Watchlist item. This can’t be undone.',
                    confirmLabel: 'Clear library',
                    failureMessage:
                        'Couldn’t clear your library. Check your connection and try again.',
                    onConfirm: () async {
                      if (!userState.isIncognitoMode) {
                        await clearUserMovies(userState.userId!);
                      }
                    },
                  );

                  if (!cleared || !mounted) {
                    return;
                  }

                  setState(() {
                    userMoviesCount = 0;
                  });
                  await moviesState.clear();
                  MSnackBar.showSnackBar('Library cleared.', true);
                },
              ),
            ),
          ],
        ],
      ),
    );

    final changePasswordField = _buildAccountEditorCard(
      context: context,
      key: const Key('settingsPasswordCard'),
      title: 'Change password',
      actionLabel: 'Save password',
      actionEnabled: changePasswordButtonActive,
      onAction: () => changePassword(userState.userId!,
          oldPasswordController.text, newPasswordController.text),
      child: Form(
        key: _formChangePasswordKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              key: const Key('settingsOldPasswordField'),
              controller: oldPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: _accountFieldDecoration('Current password'),
              validator: (value) => oldPasswordController.text.isNotEmpty
                  ? Validators.passwordValidator(oldPasswordController.text)
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('settingsNewPasswordField'),
              controller: newPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: _accountFieldDecoration('New password'),
              validator: (value) {
                if (newPasswordController.text.isEmpty) return null;

                var result =
                    Validators.passwordValidator(newPasswordController.text);
                result ??= Validators.passwordsMatchValidator(
                    newPasswordController.text, confirmPasswordController.text);
                return result;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('settingsConfirmPasswordField'),
              controller: confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: _accountFieldDecoration('Confirm new password'),
              validator: (value) {
                if (confirmPasswordController.text.isEmpty) return null;

                var result = Validators.passwordValidator(
                    confirmPasswordController.text);
                result ??= Validators.passwordsMatchValidator(
                    newPasswordController.text, confirmPasswordController.text);
                return result;
              },
            ),
          ],
        ),
      ),
    );

    final removeUserField = Md3Card(
      key: const Key('settingsDeleteAccountCard'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Delete account',
            style: TextStyle(
              color: Md3Colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Permanently deactivate this account and remove its saved library.',
            style: TextStyle(
              color: Md3Colors.muted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 56 : 44,
            child: OutlinedButton.icon(
              key: const Key('settingsDeleteAccountButton'),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Md3Colors.danger,
                side: const BorderSide(color: Md3Colors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () async {
                final feedback = await showMd3TextInputDialog(
                  context: context,
                  title: 'Delete your account?',
                  body:
                      'This deactivates your MovieDiary account and removes its saved ratings and Watchlist items. This can’t be undone.',
                  fieldLabel: 'Reason (optional)',
                  initialValue: removeController.text,
                  confirmLabel: 'Delete account',
                  destructive: true,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  failureMessage:
                      'Couldn’t delete your account. Check your connection and try again.',
                  onConfirm: (value) async {
                    await removeUser(userState.userId!, value);
                  },
                );

                if (feedback == null || !mounted) {
                  return;
                }

                removeController.clear();
                await userState.logout();
                await moviesState.logout();
                if (!mounted) {
                  return;
                }
                Navigator.of(this.context).maybePop();
              },
            ),
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
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: headingField,
            ),
            body: Container(
              key: globalKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      Md3NavigationMetrics.contentBottomInset(context) + 24,
                    ),
                    color: Md3Colors.background,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        accountStatusCard,
                        if (!userState.isIncognitoMode &&
                            userState.user != null) ...[
                          _buildSectionTitle('Account'),
                          if (userState.user!.name.isNotEmpty) nameField,
                          if (userState.user!.email.isNotEmpty &&
                              !userState.user!.isIncognito)
                            emailField,
                          if (!userState.isSignedInWithGoogle &&
                              !userState.user!.isIncognito)
                            changePasswordField,
                          if (!userState.user!.isIncognito) removeUserField,
                        ],
                        _buildSectionTitle('Movie activity'),
                        userMoviesCountField,
                        _buildSectionTitle('Purchases'),
                        premiumField,
                        if (!userState.isPremium) ...[
                          const SizedBox(height: 12),
                          _buildRestorePurchasesCard(context),
                        ],
                      ],
                    )),
              ),
            )));
  }
}
