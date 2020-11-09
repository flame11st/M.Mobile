import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Enums/MovieRate.dart';

import 'MIconRateButton.dart';

class MovieRateButtons extends StatelessWidget {
  final String movieId;
  final String movieTitle;
  final int movieRate;
  final width;
  final bool showTitle;
  final bool addMargin;
  final bool fromSearch;

  const MovieRateButtons(
      {Key key,
      this.movieId,
      this.movieRate,
      this.width,
      this.movieTitle,
      this.showTitle,
      this.addMargin,
      this.fromSearch = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: showTitle != null && showTitle ? 130 : 55,
        margin: addMargin != null && !addMargin
            ? EdgeInsets.all(0)
            : EdgeInsets.fromLTRB(10, 5, 10, 10),
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.9),
              offset: Offset(0.0, 1.0),
              blurRadius: 2,
            ),
          ],
          color: Theme.of(context).primaryColor,
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
                  text: TextSpan(
                style: Theme.of(context).textTheme.headline5,
                children: <TextSpan>[
                  new TextSpan(text: movieRate == MovieRate.addedToWatchlist ? "Did you like " : "Change score of "),
                  new TextSpan(
                      text: '"$movieTitle"${movieRate == MovieRate.addedToWatchlist ? '?' : ''}',
                      style: Theme.of(context).textTheme.headline4),
                ],
              )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                if ((showTitle == null || !showTitle) || movieRate != MovieRate.liked)
                MIconRateButton(
                  hint: showTitle == null || !showTitle ? "" : "Like",
                  movieTitle: movieTitle,
                  color: movieRate == MovieRate.liked
                      ? Colors.green
                      : Theme.of(context).primaryColor,
                  icon: Icon(Icons.favorite_border,
                      color: movieRate == MovieRate.liked
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).hintColor),
                  movieId: movieId,
                  movieRate: movieRate == MovieRate.liked
                      ? MovieRate.notRated
                      : MovieRate.liked,
                  width: width,
                  fromSearch: fromSearch,
                ),
                if ((showTitle == null || !showTitle) || movieRate != MovieRate.notLiked)
                MIconRateButton(
                  hint: showTitle == null || !showTitle ? "" : "Not like",
                  movieTitle: movieTitle,
                  color: movieRate == MovieRate.notLiked
                      ? Colors.redAccent
                      : Theme.of(context).primaryColor,
                  icon: Icon(FontAwesome5.ban,
                      color: movieRate == MovieRate.notLiked
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).hintColor),
                  movieId: movieId,
                  movieRate: movieRate == MovieRate.notLiked
                      ? MovieRate.notRated
                      : MovieRate.notLiked,
                  width: width,
                  fromSearch: fromSearch,
                ),
                if ((showTitle == null || !showTitle) || movieRate != MovieRate.addedToWatchlist)
                  MIconRateButton(
                    hint: showTitle == null || !showTitle ? "" : "To watchlist",
                    movieTitle: movieTitle,
                    color: movieRate == MovieRate.addedToWatchlist
                        ? Theme.of(context).accentColor
                        : Theme.of(context).primaryColor,
                    icon: Icon(Icons.add_to_queue,
                        color: movieRate == MovieRate.addedToWatchlist
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).hintColor),
                    movieId: movieId,
                    movieRate: movieRate == MovieRate.addedToWatchlist
                        ? MovieRate.notRated
                        : MovieRate.addedToWatchlist,
                    width: width,
                    fromSearch: fromSearch,
                  )
              ],
            )
          ],
        ));
  }
}
