import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:mmobile/Enums/movie_rate.dart';
import 'package:mmobile/Objects/user_taste_profile.dart';
import 'package:mmobile/Services/service_agent.dart';
import 'package:mmobile/Widgets/Providers/movies_state.dart';
import 'package:mmobile/Widgets/Providers/user_state.dart';
import 'package:provider/provider.dart';

import '../Helpers/route_helper.dart';
import 'movies_lists_page.dart';
import 'onboarding_wizard_page.dart';
import 'recommendations_page.dart';
import 'Shared/m_button.dart';
import 'Shared/m_card.dart';

class EmptyMoviesCard extends StatelessWidget {
  final String tabName;
  final serviceAgent = ServiceAgent();

  EmptyMoviesCard({super.key, required this.tabName});

  Route _createRoute(Function page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);
    final ratedCount = moviesState.userMovies
        .where((movie) => MovieRate.isViewed(movie.movieRate))
        .length;
    final progress = (ratedCount / 10).clamp(0.0, 1.0);
    final isViewedTab = tabName.toLowerCase().contains('viewed');
    final introCopy = isViewedTab
        ? 'Rate movies, build your taste profile, and keep your Viewed history in one place.'
        : 'Build your taste profile, keep a strong Watchlist, and start Discovery when you are ready.';
    final primaryActionText = isViewedTab ? 'Rate Movies' : 'Start Discovery';

    return MCard(
      marginLR: 20,
      marginTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MovieDiary',
            style: TextStyle(
                color: Theme.of(context).indicatorColor,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            introCopy,
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
          ),
          const SizedBox(height: 18),
          buildTasteProfileCard(context, userState, ratedCount, progress),
          const SizedBox(height: 18),
          MButton(
            height: 42,
            width: MediaQuery.of(context).size.width - 40,
            backgroundColor: Theme.of(context).indicatorColor,
            borderRadius: 22,
            prependIcon:
                isViewedTab ? Icons.swipe_rounded : Icons.electric_bolt,
            prependIconColor: Theme.of(context).cardColor,
            text: primaryActionText,
            onPressedCallback: () {
              Navigator.of(context)
                  .push(RouteHelper.createRoute(() => isViewedTab
                      ? OnboardingWizardPage(
                          onFinished: () {
                            Navigator.of(context).pop();
                          },
                        )
                      : const RecommendationsPage()));
            },
            active: true,
            textColor: Theme.of(context).cardColor,
          ),
          const SizedBox(height: 14),
          MButton(
            height: 42,
            borderRadius: 30,
            active: true,
            text: 'Open Lists',
            prependIcon: Entypo.menu,
            width: MediaQuery.of(context).size.width - 40,
            onPressedCallback: () => Navigator.of(context).push(
              _createRoute(() => const MoviesListsPage(initialPageIndex: 0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTasteProfileCard(BuildContext context, UserState userState,
      int ratedCount, double progress) {
    if (userState.isIncognitoMode ||
        userState.userId == null ||
        userState.userId!.isEmpty) {
      return buildTasteProfileSummary(
        context,
        UserTasteProfile(
          isReady: ratedCount >= 10,
          isGenerated: false,
          ratingsCount: ratedCount,
        ),
        progress,
      );
    }

    return FutureBuilder<UserTasteProfile>(
      future: serviceAgent.getUserTasteProfile(userState.userId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildTasteProfileSummary(
            context,
            UserTasteProfile(
              isReady: ratedCount >= 10,
              isGenerated: false,
              ratingsCount: ratedCount,
            ),
            progress,
            hasProfileError: true,
          );
        }

        final profile = snapshot.data ??
            UserTasteProfile(
              isReady: ratedCount >= 10,
              isGenerated: false,
              ratingsCount: ratedCount,
            );

        return buildTasteProfileSummary(context, profile, progress);
      },
    );
  }

  Widget buildTasteProfileSummary(
    BuildContext context,
    UserTasteProfile profile,
    double progress, {
    bool hasProfileError = false,
  }) {
    final genres = profile.favoriteGenres
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty)
        .take(2)
        .toList();
    final title = hasProfileError
        ? 'Taste profile unavailable'
        : profile.isReady
            ? 'Your taste profile'
            : 'Build your taste profile';
    final body = hasProfileError
        ? 'MovieDiary could not load your taste profile from the API. Your ratings are still saved.'
        : profile.isReady
            ? genres.isNotEmpty
                ? 'Based on ${profile.ratingsCount} ratings, you often rate ${genres.join(' and ')} highly.'
                : 'Based on ${profile.ratingsCount} ratings. Rate more to keep sharpening your recommendations.'
            : '${profile.ratingsCount}/10 ratings toward better recommendations.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).indicatorColor),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded,
                  color: Theme.of(context).indicatorColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ],
          ),
          if (!profile.isReady) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
          ],
          const SizedBox(height: 10),
          Text(body, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
