import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Widgets/MovieListItemExpanded.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';
import 'Shared/MBoxShadow.dart';
import 'Shared/MCard.dart';
import 'Shared/MovieRateButtons.dart';
import 'package:http/http.dart' as http;

class MovieListItem extends StatefulWidget {
  final Movie movie;
  final MoviesList moviesList;
  final bool shouldRequestReview;

  const MovieListItem(
      {Key key, this.movie, this.moviesList, this.shouldRequestReview = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MovieListItemState(movie, moviesList, shouldRequestReview);
  }
}

class MovieListItemState extends State<MovieListItem> {
  bool expanded = false;
  String imageBaseUrl =
      "https://moviediarystorage.blob.core.windows.net/movies";
  bool imageChecked = false;
  MoviesList moviesList;
  bool shouldRequestReview;

  Movie movie;

  MovieListItemState(
      Movie movie, MoviesList moviesList, bool shouldRequestReview) {
    this.movie = movie;
    this.moviesList = moviesList;
    this.shouldRequestReview = shouldRequestReview;
  }

  checkImage(String imageUrl) async {
    final response = await http.head(Uri.parse(imageBaseUrl + imageUrl));

    if (response.statusCode == 404) {
      final serviceAgent = new ServiceAgent();

      await serviceAgent.reloadMoviePoster(movie.id);
    }

    imageChecked = true;
  }

  Widget build(BuildContext context) {
    //Don't remove this not used state declaration. It is needed for lists update.
    final moviesState = Provider.of<MoviesState>(context);
    final borderRadius = Platform.isIOS ? 10.0 : 4.0;
    final formatter = new NumberFormat("#,###");

    final imageUrl =
        movie.posterPath != '' ? movie.posterPath : '/movie_placeholder.png';
    IconData icon;

    if (imageChecked == false) {
      checkImage(imageUrl);
    }

    switch (movie.movieRate) {
      case MovieRate.addedToWatchlist:
        {
          icon = Icons.bookmark_border;
          break;
        }
      case MovieRate.liked:
        {
          icon = Icons.favorite_border;
          break;
        }
      case MovieRate.notLiked:
        {
          icon = FontAwesome5.ban;
          break;
        }
      case MovieRate.notRated:
        {
          icon = Icons.add;
          break;
        }
    }

    return GestureDetector(
      onTap: () {
        showFullMovie(context);
      },
      child: Center(
          child: Hero(
              tag: 'movie-hero-animation' + movie.id,
              child: Material(
                color: Theme.of(context).cardColor,
                type: MaterialType.transparency,
                child: MCard(
                    foregroundColor: movie.movieRate == MovieRate.liked
                        ? Colors.green.withOpacity(0.08)
                        : movie.movieRate == MovieRate.notLiked
                            ? Colors.red.withOpacity(0.08)
                            : Colors.transparent,
                    marginBottom: 5,
                    marginLR: 10,
                    marginTop: 15,
                    padding: 0,
                    child: Row(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(borderRadius),
                              bottomLeft: Radius.circular(borderRadius)),
                          child: imageBaseUrl != ""
                              ? CachedNetworkImage(
                                  imageUrl: imageBaseUrl + imageUrl,
                                  height: 90,
                                  fit: BoxFit.fill,
                                  width: 60,
                                )
                              : SizedBox(
                                  height: 90,
                                  width: 60,
                                ),
                        ),
                        Expanded(
                          child: Container(
                            height: 90,
                            padding: EdgeInsets.only(left: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(movie.title,
                                    style:
                                        Theme.of(context).textTheme.headline3),
                                Row(
                                  children: <Widget>[
                                    Text(
                                        DateFormat('yyyy')
                                            .format(movie.releaseDate),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5),
                                    SizedBox(
                                      width: 30,
                                    ),
                                    if (movie.duration > 0 ||
                                        movie.averageTimeOfEpisode > 0)
                                      Text(
                                          (movie.movieType == MovieType.movie
                                                  ? movie.duration.toString()
                                                  : movie.averageTimeOfEpisode
                                                      .toString()) +
                                              ' min',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5),
                                    SizedBox(
                                      width: 30,
                                    ),
                                    if (movie.seasonsCount > 0)
                                      Text("Seasons: ${movie.seasonsCount}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5),
                                  ],
                                ),
                                if (movie.genres.isNotEmpty)
                                  Text(movie.genres.join(', '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5),
                                if (movie.genres.isEmpty)
                                  Text(
                                      movie.imdbVotes > 0
                                          ? 'Imdb: ${movie.imdbRate} (${formatter.format(movie.imdbVotes)})'
                                          : 'Imdb: Not rated',
                                      style:
                                          Theme.of(context).textTheme.headline5)
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 40,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            boxShadow: MBoxShadow.circleShadow,
                            color:
                                Theme.of(context).cardColor.withOpacity(0.95),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              icon,
                              color: movie.movieRate == MovieRate.liked
                                  ? Colors.green
                                  : movie.movieRate == MovieRate.notLiked
                                      ? Colors.red
                                      : Theme.of(context).accentColor,
                            ),
                            onPressed: () async {
                              showModalBottomSheet<void>(
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  builder: (BuildContext context) =>
                                      MovieRateButtons(
                                        moviesList: moviesList,
                                        movie: movie,
                                        showTitle: true,
                                        addMargin: false,
                                      ));
                            },
                          ),
                        )
                      ],
                    )),
              ))),
    );
  }

  showFullMovie(BuildContext context) { Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => MovieListItemExpanded(
        movie: movie,
        imageUrl: imageBaseUrl,
        moviesList: moviesList,
        shouldRequestReview: shouldRequestReview,
      )));
  }
}
