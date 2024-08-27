import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:mmobile/Widgets/Shared/MTextField.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'MoviesBottomNavigationBarExpanded.dart';

class MovieListItemExpanded extends StatefulWidget {
  final Movie movie;
  final bool fromSearch;
  final String imageUrl;
  final MoviesList? moviesList;
  final bool shouldRequestReview;

  const MovieListItemExpanded(
      {super.key,
      required this.movie,
      this.fromSearch = false,
      required this.imageUrl,
      this.moviesList,
      this.shouldRequestReview = false});

  @override
  State<StatefulWidget> createState() {
    return MovieListItemExpandedState(
        movie, fromSearch, imageUrl, moviesList, shouldRequestReview);
  }
}

class MovieListItemExpandedState extends State<MovieListItemExpanded> {
  late Movie movie;
  bool? fromSearch;
  MoviesList? moviesList;
  bool? shouldRequestReview;

  String imageBaseUrl =
      'https://moviediarystorage.blob.core.windows.net/movies';

  MovieListItemExpandedState(Movie movie, bool fromSearch, String url,
      MoviesList? moviesList, bool shouldRequestReview) {
    this.movie = movie;
    this.fromSearch = fromSearch;
    this.moviesList = moviesList;
    this.shouldRequestReview = shouldRequestReview;
  }

  getProgressColor() {
    if (movie.rating < 30)
      return Colors.red;
    else if (movie.rating < 70)
      return Colors.amberAccent;
    else
      return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = new NumberFormat("#,###");
    final borderRadius = 15.0;

    final imageUrl =
        movie.posterPath != '' ? movie.posterPath : '/movie_placeholder.png';

    final genreChips = Align(alignment: Alignment.topLeft, child: Wrap(
      spacing: 8.0, // Space between chips
      runSpacing: 4.0, // Space between rows of chips
      children: movie.genres.map((genre) {
        return Chip(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                20), // More rounded corners
          ),
          padding: EdgeInsets.all(2),
          label: Text(
            genre,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        );
      }).toList(),
    ));

    final topCard = MCard(
      marginTop: 1,
      padding: 10,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: CachedNetworkImage(
                imageUrl: imageBaseUrl + imageUrl,
                height: 160,
                fit: BoxFit.fill,
                width: 110,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Container(
                height: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width - 160,
                      child: RichText(
                          text: TextSpan(
                        style: Theme.of(context).textTheme.displayMedium,
                        children: <TextSpan>[
                          new TextSpan(text: movie.title),
                          new TextSpan(
                              text: ' (' +
                                  DateFormat('yyyy').format(movie.releaseDate) +
                                  ')',
                              style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      )),
                    ),
                    Row(
                      children: <Widget>[
                        if (movie.seasonsCount > 0)
                          Text("Seasons: ${movie.seasonsCount}",
                              style: Theme.of(context).textTheme.headlineSmall),
                        SizedBox(
                          width: 25,
                        ),
                        if (movie.seasonsCount > 0)
                          Text(
                              "${movie.inProduction ? 'In production' : 'Finished'}",
                              style: Theme.of(context).textTheme.headlineSmall),
                      ],
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width - 160,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                height: 95,
                                width: 95,
                                decoration: new BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.8),
                                        offset: Offset(0.0, 0.1),
                                        blurRadius: 0.5),
                                  ],
                                ),
                                child: CircularPercentIndicator(
                                  radius: 45.0,
                                  lineWidth: 6.0,
                                  percent:
                                      movie.allVotes > 0 && movie.rating == 0
                                          ? 1
                                          : movie.rating / 100,
                                  center: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (movie.allVotes == 0)
                                          Text("Not rated",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall),
                                        if (movie.allVotes > 0)
                                          Text("${movie.rating}%",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall),
                                        if (movie.allVotes > 0)
                                          Text(
                                              "(${formatter.format(movie.allVotes)})",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall),
                                        Image(
                                          image: AssetImage(
                                              "Assets/mdIcon_V_with_effect.png"),
                                          width: 20,
                                        )
                                      ]),
                                  progressColor: getProgressColor(),
                                ),
                              ),
                              Container(
                                height: 95,
                                width: 95,
                                decoration: new BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.8),
                                        offset: Offset(0.0, 0.1),
                                        blurRadius: 0.5),
                                  ],
                                ),
                                child: CircularPercentIndicator(
                                  radius: 45.0,
                                  lineWidth: 6.0,
                                  percent:
                                      movie.imdbVotes > 0 && movie.imdbRate == 0
                                          ? 1
                                          : movie.imdbRate / 10,
                                  center: movie.imdbVotes > 0
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                              Text("${movie.imdbRate}",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall),
                                              Text(
                                                  "(${formatter.format(movie.imdbVotes)})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall),
                                              Image(
                                                image: AssetImage(
                                                    "Assets/imdb_logo.png"),
                                                width: 35,
                                              )
                                            ])
                                      : Text("Not rated",
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall),
                                  progressColor: getProgressColor(),
                                ),
                              )
                            ]))
                  ],
                ))
          ]),
    );

    final textFields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        if (movie.overview.isNotEmpty) SizedBox(height: 10),
        if (movie.overview.isNotEmpty)
          Text(movie.overview, style: Theme.of(context).textTheme.headlineSmall,),
        if (movie.overview.isNotEmpty) SizedBox(height: 10),
        if (movie.directors.isNotEmpty) SizedBox(height: 10),
        if (movie.directors.isNotEmpty)
          MTextField(
              subtitleText: 'Directed by',
              bodyText: movie.directors.map((director) => director).join(', ')),
        if (movie.actors.isNotEmpty) SizedBox(height: 10),
        if (movie.actors.isNotEmpty)
          MTextField(
              subtitleText: 'Starring',
              bodyText: movie.actors.map((actor) => actor).join(', ')),
        if (movie.countries.isNotEmpty) SizedBox(height: 10),
        if (movie.countries.isNotEmpty)
          MTextField(
              subtitleText: 'Countries',
              bodyText: movie.countries.replaceAll(',', ', ')),
        if (movie.overview.isNotEmpty)
          SizedBox(
            height: 200,
          ),
      ],
    );

    return Scaffold(
        appBar: AdManager.bannerVisible && AdManager.bannersReady
            ? AppBar(
                title: Center(
                  child: AdManager.getBannerWidget(
                      AdManager.itemExpandedBannerAd!),
                ),
                automaticallyImplyLeading: false,
                elevation: 0.7,
              )
            : PreferredSize(preferredSize: Size(0, 0), child: Container()),
        body: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: SingleChildScrollView(
                child: Container(
              padding: EdgeInsets.fromLTRB(10, 5, 10, 20),
              child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    color: Theme.of(context).primaryColor,
                    child: Column(
                      children: <Widget>[
                        if (movie.tagline != null && movie.tagline!.isNotEmpty)
                        Text(movie.tagline!, style: Theme.of(context)
                            .textTheme.titleMedium,),
                        topCard,
                        SizedBox(height: 5),
                        genreChips,
                        textFields,
                      ],
                    ),
                  )),
            ))),
        bottomNavigationBar: MoviesBottomNavigationBarExpanded(
          movie: movie,
          fromSearch: fromSearch!,
          shouldRequestReview: shouldRequestReview!,
          moviesList: moviesList,
        ));
  }
}
