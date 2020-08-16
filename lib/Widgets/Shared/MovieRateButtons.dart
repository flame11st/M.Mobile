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

  const MovieRateButtons(
      {Key key,
      this.movieId,
      this.movieRate,
      this.width,
      this.movieTitle,
      this.showTitle,
      this.addMargin})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: showTitle != null && showTitle ? 110 : 60,
        margin: addMargin != null && !addMargin
            ? EdgeInsets.all(0)
            : EdgeInsets.fromLTRB(10, 5, 10, 10),
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              offset: Offset(-4.0, -4.0),
              blurRadius: 4,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: Offset(4.0, 4.0),
              blurRadius: 6,
            ),
          ],
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
              bottomLeft: Radius.circular(
                  addMargin == null || addMargin == true ? 30.0 : 0),
              bottomRight: Radius.circular(
                  addMargin == null || addMargin == true ? 30.0 : 0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            if (showTitle != null && showTitle)
              Text(
                movieTitle,
                style: Theme.of(context).textTheme.headline2,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                MIconRateButton(
                  movieTitle: movieTitle,
                  color: movieRate == MovieRate.liked
                      ? Colors.greenAccent
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
                ),
                MIconRateButton(
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
                ),
                MIconRateButton(
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
                )
              ],
            )
          ],
        ));
  }
}
