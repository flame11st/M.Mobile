import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';

import 'MIconAddToListButton.dart';
import 'MIconRateButton.dart';

class MovieRateButtons extends StatelessWidget {
  final bool showTitle;
  final bool addMargin;
  final bool fromSearch;
  final Movie movie;
  final bool shouldRequestReview;
  final MoviesList moviesList;

  const MovieRateButtons(
      {Key key,
      this.showTitle,
      this.addMargin,
      this.fromSearch = false,
      this.movie,
      this.shouldRequestReview = false,
      this.moviesList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 50) / 4;
    final text = movie.movieRate == MovieRate.notRated
        ? "Add to your movies "
        : "Change score of ";

    return Container(
        height: showTitle != null && showTitle ? 200 : 105,
        margin: addMargin != null && !addMargin
            ? EdgeInsets.all(0)
            : EdgeInsets.fromLTRB(10, 5, 10, 10),
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.8),
                offset: Offset(0.0, 0.05),
                blurRadius: 0.5),
          ],
          color: showTitle != null && showTitle
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
              bottomLeft: Radius.circular(
                  addMargin == null || addMargin == true ? 15.0 : 0),
              bottomRight: Radius.circular(
                  addMargin == null || addMargin == true ? 15.0 : 0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            if (showTitle != null && showTitle)
              RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headline5,
                    children: <TextSpan>[
                      new TextSpan(text: text),
                      new TextSpan(
                          text:
                              '"${movie.title}"?',
                          style: Theme.of(context).textTheme.headline4),
                    ],
                  )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                MIconRateButton(
                  shouldRequestReview: shouldRequestReview,
                  hint: showTitle == null || !showTitle
                      ? ""
                      : "Like" +
                          (movie.movieRate == MovieRate.liked ? "d" : ""),
                  color: movie.movieRate == MovieRate.liked
                      ? Colors.green
                      : Theme.of(context).cardColor.withOpacity(0.95),
                  icon: Icon(Icons.favorite_border,
                      color: movie.movieRate == MovieRate.liked
                          ? Theme.of(context).cardColor
                          : Theme.of(context).hintColor),
                  movie: movie,
                  movieRate: movie.movieRate == MovieRate.liked
                      ? MovieRate.notRated
                      : MovieRate.liked,
                  width: width,
                  fromSearch: fromSearch,
                ),
                MIconRateButton(
                  shouldRequestReview: shouldRequestReview,
                  hint: showTitle == null || !showTitle
                      ? ""
                      : "Dislike" +
                          (movie.movieRate == MovieRate.notLiked ? "d" : ""),
                  color: movie.movieRate == MovieRate.notLiked
                      ? Colors.redAccent
                      : Theme.of(context).cardColor.withOpacity(0.95),
                  icon: Icon(FontAwesome5.ban,
                      color: movie.movieRate == MovieRate.notLiked
                          ? Theme.of(context).cardColor
                          : Theme.of(context).hintColor),
                  movie: movie,
                  movieRate: movie.movieRate == MovieRate.notLiked
                      ? MovieRate.notRated
                      : MovieRate.notLiked,
                  width: width,
                  fromSearch: fromSearch,
                ),
                MIconRateButton(
                  shouldRequestReview: shouldRequestReview,
                  hint: showTitle == null || !showTitle
                      ? ""
                      : (movie.movieRate == MovieRate.addedToWatchlist
                              ? "In"
                              : "To") +
                          " watchlist",
                  color: movie.movieRate == MovieRate.addedToWatchlist
                      ? Theme.of(context).accentColor
                      : Theme.of(context).cardColor.withOpacity(0.95),
                  icon: Icon(Icons.add_to_queue,
                      color: movie.movieRate == MovieRate.addedToWatchlist
                          ? Theme.of(context).cardColor
                          : Theme.of(context).hintColor),
                  movie: movie,
                  movieRate: movie.movieRate == MovieRate.addedToWatchlist
                      ? MovieRate.notRated
                      : MovieRate.addedToWatchlist,
                  width: width,
                  fromSearch: fromSearch,
                ),
              ],
            ),
            // if (showTitle != null && showTitle)
            MAddToListButton(
              movie: movie,
              moviesList: moviesList,
            ),
          ],
        ));
  }
}
