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
  final bool showShortDescription;

  const MovieListItem(
      {Key key,
      this.movie,
      this.moviesList,
      this.shouldRequestReview = false,
      this.showShortDescription = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MovieListItemState(
        movie, moviesList, shouldRequestReview, showShortDescription);
  }
}

class MovieListItemState extends State<MovieListItem> {
  bool expanded = false;
  String imageBaseUrl =
      "https://moviediarystorage.blob.core.windows.net/movies";
  bool imageChecked = false;
  MoviesList moviesList;
  bool shouldRequestReview;
  bool showShortDescription;

  Movie movie;

  MovieListItemState(Movie movie, MoviesList moviesList,
      bool shouldRequestReview, bool showShortDescription) {
    this.movie = movie;
    this.moviesList = moviesList;
    this.shouldRequestReview = shouldRequestReview;
    this.showShortDescription = showShortDescription;
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
    final borderRadius = 25.0;
    final formatter = new NumberFormat("#,###");
    final imageWidth = showShortDescription ? 63.0 : 60.0;
    final imageHeight = showShortDescription ? 95.0 : 90.0;

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
                    marginLR: 11,
                    marginTop: 15,
                    padding: 0,
                    child: Column(children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            height: imageHeight,
                            child: SizedBox(
                                child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(borderRadius),
                                  bottomLeft: Radius.circular(
                                      showShortDescription ? 0 : borderRadius),
                                  bottomRight: Radius.circular(
                                      showShortDescription ? borderRadius : 0)),
                              child: imageBaseUrl != ""
                                  ? CachedNetworkImage(
                                      imageUrl: imageBaseUrl + imageUrl,
                                      height: imageHeight,
                                      fit: BoxFit.fill,
                                      width: imageWidth,
                                    )
                                  : SizedBox(
                                      height: imageHeight,
                                      width: imageWidth,
                                    ),
                            )),
                          ),
                          Expanded(
                            child: Container(
                              height: imageHeight,
                              padding: EdgeInsets.only(left: 7),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(movie.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline3),
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5),
                                ],
                              ),
                            ),
                          ),
                          Container(
                              height: imageHeight,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    width: 40,
                                    margin: EdgeInsets.only(right: 7),
                                    decoration: BoxDecoration(
                                      boxShadow: MBoxShadow.circleShadow,
                                      color: Theme.of(context)
                                          .cardColor
                                          .withOpacity(0.95),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        icon,
                                        color: movie.movieRate ==
                                                MovieRate.liked
                                            ? Colors.green
                                            : movie.movieRate ==
                                                    MovieRate.notLiked
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
                                  ),
                                ],
                              ))
                        ],
                      ),
                      if (showShortDescription)
                        Container(
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 0),
                            height: movie.overview.length > 200 ? 105 : 85,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    movie.overview,
                                    style:
                                        Theme.of(context).textTheme.headline5,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: movie.overview.length > 200 ? 5 : 4,
                                  )
                                ),
                              ],
                            )),
                      if (showShortDescription)
                        Container(
                          padding: EdgeInsets.fromLTRB(10,0,10,0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Imdb: ${movie.imdbVotes > 0 ? '${movie.imdbRate} (${formatter.format(movie.imdbVotes)})' : 'Not rated'}",
                                style: Theme.of(context).textTheme.headline4,
                              ),
                              Text(
                                "MovieDIary: ${movie.rating > 0 ? '${movie.rating}% (${formatter.format(movie.allVotes)})' : 'Not rated'}",
                                style: Theme.of(context).textTheme.headline4,
                              )
                            ],
                          ),
                        ),
                      if (showShortDescription)
                      SizedBox(
                        height: 30,
                        child: IconButton(
                          iconSize: 20,
                          icon: new Icon(Icons.keyboard_arrow_down),
                          onPressed: () => showFullMovie(context),
                          color: Theme.of(context).accentColor,
                        ),
                      )
                    ])),
              ))),
    );
  }

  showFullMovie(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => MovieListItemExpanded(
              movie: movie,
              imageUrl: imageBaseUrl,
              moviesList: moviesList,
              shouldRequestReview: shouldRequestReview,
            )));
  }
}
