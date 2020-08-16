import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Objects/MovieSearchDTO.dart';
import 'package:provider/provider.dart';
import 'Shared/MIconRateButton.dart';

class MovieSearchItem extends StatelessWidget {
  final MovieSearchDTO movie;
  final imageBaseUrl = 'https://moviediarystorage.blob.core.windows.net/movies';

  const MovieSearchItem({Key key, this.movie}) : super(key: key);
  final iconSize = 20.0;
  final width = 45.0;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        movie.posterPath != '' ? movie.posterPath : '/movie_placeholder.png';
    return Container(
        height: 100.0,
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              offset: Offset(-4.0, -4.0),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: Offset(4.0, 4.0),
              blurRadius: 6,
            ),
          ],
          borderRadius: BorderRadius.circular(12.0),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                imageBaseUrl + imageUrl,
                height: 100,
                fit: BoxFit.fill,
                width: 66,
//                                        placeholder: (context, url) => CircularProgressIndicator(),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 5),
//                                            constraints: BoxConstraints.expand(height: 120, width: 300),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    RichText(
                        text: TextSpan(
                      style: Theme.of(context).textTheme.headline5,
                      children: <TextSpan>[
                        new TextSpan(
                            text: movie.title, style: Theme.of(context).textTheme.headline3),
                        new TextSpan(text: ' (${movie.year})'),
                      ],
                    )),

//                    Text(movie.genres.join(', '), style: Theme.of(context).textTheme.headline5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        MIconRateButton(
                          movieTitle: movie.title,
                          color: movie.movieRate == MovieRate.liked
                              ? Colors.greenAccent
                              : Theme.of(context).primaryColor,
                          icon: Icon(Icons.favorite_border, color: movie.movieRate == MovieRate.liked
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).hintColor),
                          movieId: movie.id,
                          movieRate: movie.movieRate == MovieRate.liked
                              ? MovieRate.notRated
                              : MovieRate.liked,
                          width: width,
                        ),
                        MIconRateButton(
                          movieTitle: movie.title,
                          color: movie.movieRate == MovieRate.notLiked
                              ? Colors.redAccent
                              : Theme.of(context).primaryColor,
                          icon: Icon(FontAwesome5.ban, color: movie.movieRate == MovieRate.notLiked
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).hintColor),
                          movieId: movie.id,
                          movieRate: movie.movieRate == MovieRate.notLiked
                              ? MovieRate.notRated
                              : MovieRate.notLiked,
                          width: width,
                        ),
                        MIconRateButton(
                          movieTitle: movie.title,
                          color: movie.movieRate == MovieRate.addedToWatchlist
                              ? Theme.of(context).accentColor
                              : Theme.of(context).primaryColor,
                          icon: Icon(Icons.add_to_queue,
                              color: movie.movieRate == MovieRate.addedToWatchlist
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).hintColor),
                          movieId: movie.id,
                          movieRate: movie.movieRate == MovieRate.addedToWatchlist
                              ? MovieRate.notRated
                              : MovieRate.addedToWatchlist,
                          width: width,
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
