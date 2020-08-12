import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Variables/Variables.dart';

import 'MIconRateButton.dart';

class MovieRateButtons extends StatelessWidget {
  final String movieId;
  final int movieRate;
  final String additionalText;
  final width;

  const MovieRateButtons(
      {Key key, this.movieId, this.movieRate, this.additionalText, this.width})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: additionalText == null ? 60 : 110,
        margin: EdgeInsets.fromLTRB(10, 5, 10, 10),
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
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            if (additionalText != null)
              Text(
                additionalText,
                style: MTextStyles.BodyText,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                MIconRateButton(
                  icon: Icon(Icons.favorite_border,
                      color: movieRate == MovieRate.liked
                          ? Colors.greenAccent
                          : Theme.of(context).hintColor),
                  movieId: movieId,
                  movieRate: movieRate == MovieRate.liked
                      ? MovieRate.notRated
                      : MovieRate.liked,
                  width: width,
                ),
                MIconRateButton(
                  icon: Icon(FontAwesome5.ban,
                      color: movieRate == MovieRate.notLiked
                          ? Colors.redAccent
                          : Theme.of(context).hintColor),
                  movieId: movieId,
                  movieRate: movieRate == MovieRate.notLiked
                      ? MovieRate.notRated
                      : MovieRate.notLiked,
                  width: width,
                ),
                MIconRateButton(
                  icon: Icon(Icons.add_to_queue,
                      color: movieRate == MovieRate.addedToWatchlist
                          ? Theme.of(context).accentColor
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
