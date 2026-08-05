import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmobile/Objects/user.dart';
import 'package:mmobile/Widgets/Providers/loader_state.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:mmobile/Widgets/Shared/md3_ui.dart';
import 'package:mmobile/Widgets/login.dart';
import 'package:mmobile/Widgets/settings.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android Login keeps sign-in first and remains scroll-safe at text scale 2',
    (tester) async {
      final states = await _guestStates();
      addTearDown(states.movies.dispose);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 568));

      await tester.pumpWidget(
        _app(
          states,
          textScale: 2,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const Login(
                        platformOverride: TargetPlatform.android,
                        loadMovieLists: false,
                      ),
                    ),
                  ),
                  child: const Text('Open Login'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Login'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loginBackButton')), findsOneWidget);
      expect(find.text('Sign in to MovieDiary'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsNothing);
      expect(find.byKey(const Key('forgotPasswordButton')), findsOneWidget);
      expect(find.byKey(const Key('createAccountButton')), findsOneWidget);
      expect(
        find.byKey(const Key('continueWithoutAccountButton')),
        findsOneWidget,
      );

      expect(
        tester.getTopLeft(find.text('Sign in with Google')).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('loginEmailField'))).dy,
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('createAccountButton'))).dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const Key('continueWithoutAccountButton')),
              )
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byKey(const Key('loginBackButton')));
      await tester.tap(find.byKey(const Key('loginBackButton')));
      await tester.pumpAndSettle();
      expect(find.text('Open Login'), findsOneWidget);
    },
  );

  testWidgets('iOS Login shows Apple before Google', (tester) async {
    final states = await _guestStates();
    addTearDown(states.movies.dispose);

    await tester.pumpWidget(
      _app(
        states,
        home: const Login(
          platformOverride: TargetPlatform.iOS,
          loadMovieLists: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sign in with Apple'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Sign in with Apple')).dy,
      lessThan(tester.getTopLeft(find.text('Sign in with Google')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Forgot password opens with a valid entered email prefilled',
      (tester) async {
    final states = await _guestStates();
    addTearDown(states.movies.dispose);

    await tester.pumpWidget(
      _app(
        states,
        home: const Login(
          platformOverride: TargetPlatform.android,
          loadMovieLists: false,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('loginEmailField')),
      'movie.fan@example.test',
    );
    await tester.ensureVisible(find.byKey(const Key('forgotPasswordButton')));
    await tester.tap(find.byKey(const Key('forgotPasswordButton')));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
    final resetField = tester.widget<TextFormField>(
      find.byKey(const Key('passwordResetEmailField')),
    );
    expect(resetField.controller?.text, 'movie.fan@example.test');
    expect(find.byKey(const Key('passwordResetSendButton')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest Settings uses compact sections and responsive purchases',
      (tester) async {
    final states = await _guestStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));

    await tester.pumpWidget(
      _app(
        states,
        textScale: 2,
        home: const Settings(),
      ),
    );
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byKey(const Key('settingsAccountStatusCard')), findsOneWidget);
    expect(find.text('Movie activity'), findsOneWidget);
    expect(find.text('Purchases'), findsOneWidget);
    expect(
      find.text(
        'Keep these tools lightweight so Discover and My Movies stay central.',
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('restorePurchasesCard')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('restorePurchasesCard')));
    await tester.pumpAndSettle();
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'signed-in Settings account editors stay polished at text scale 2',
      (tester) async {
    final states = await _signedInStates();
    addTearDown(states.movies.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 568));

    await tester.pumpWidget(
      _app(
        states,
        textScale: 2,
        home: const Settings(),
      ),
    );
    await tester.pump();

    expect(find.text('Signed in as R3 Acceptance Target'), findsOneWidget);
    expect(find.byKey(const Key('settingsNameCard')), findsOneWidget);
    expect(find.byKey(const Key('settingsEmailCard')), findsOneWidget);
    expect(find.byKey(const Key('settingsPasswordCard')), findsOneWidget);
    expect(find.byKey(const Key('settingsDeleteAccountCard')), findsOneWidget);

    final nameField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('settingsNameField')),
        matching: find.byType(TextField),
      ),
    );
    expect(nameField.decoration?.fillColor, Md3Colors.background);

    for (final key in [
      const Key('settingsEmailField'),
      const Key('settingsOldPasswordField'),
      const Key('settingsDeleteAccountButton'),
    ]) {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

Future<_TestStates> _guestStates() async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'guest-access',
    'refreshToken': 'guest-refresh',
    'userId': 'guest-settings-login-test',
    'isIncognitoMode': 'true',
  });
  const storage = FlutterSecureStorage();
  final user = UserState(storage: storage);
  await user.initialization;
  final movies = MoviesState(storage: storage);
  await movies.cacheInitialization;

  return _TestStates(
    user: user,
    movies: movies,
    loader: LoaderState(),
  );
}

Future<_TestStates> _signedInStates() async {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'signed-in-access',
    'refreshToken': 'signed-in-refresh',
    'userId': 'signed-in-settings-test',
    'isIncognitoMode': 'false',
  });
  const storage = FlutterSecureStorage();
  final user = UserState(storage: storage);
  await user.initialization;
  await user.setUser(
    User(
      id: 'signed-in-settings-test',
      name: 'R3 Acceptance Target',
      email: 'r3-acceptance@example.test',
      role: 'StandardRole',
      premiumPurchased: false,
      isIncognito: false,
    ),
  );
  final movies = MoviesState(storage: storage);
  await movies.cacheInitialization;

  return _TestStates(
    user: user,
    movies: movies,
    loader: LoaderState(),
  );
}

Widget _app(
  _TestStates states, {
  required Widget home,
  double textScale = 1,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserState>.value(value: states.user),
      ChangeNotifierProvider<MoviesState>.value(value: states.movies),
      ChangeNotifierProvider<LoaderState>.value(value: states.loader),
    ],
    child: MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: home,
    ),
  );
}

class _TestStates {
  final UserState user;
  final MoviesState movies;
  final LoaderState loader;

  const _TestStates({
    required this.user,
    required this.movies,
    required this.loader,
  });
}
