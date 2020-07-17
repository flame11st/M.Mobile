import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Objects/MovieSearchDTO.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/MovieListItemExpanded.dart';
import 'Shared/BoxShadowNeomorph.dart';
import 'Shared/MIconRateButton.dart';
import 'Shared/MovieRateButtons.dart';

class MovieSearchItem extends StatelessWidget {
  final MovieSearchDTO movie;
  final imageBaseUrl =
      'https://moviediarystorage.blob.core.windows.net/movies';

  const MovieSearchItem({Key key, this.movie}) : super(key: key);
  final iconSize = 20.0;
  final width = 45.0;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 120.0,
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
          color: MColors.SecondaryColor,
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                imageBaseUrl + movie.posterPath,
                height: 120,
                fit: BoxFit.fill,
                width: 80,
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
                    RichText( text: TextSpan(
                      style: MTextStyles.BodyText,
                      children: <TextSpan>[
                        new TextSpan(text: movie.title, style: MTextStyles.Title),
                        new TextSpan(text: ' (${movie.year})'),
                      ],
                    )),
                    Text(movie.genres.join(', '),
                        style: MTextStyles.BodyText),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        MIconRateButton(
                          icon: Icon(
                              Icons.thumb_up,
                              color: movie.movieRate == MovieRate.liked
                                  ? Colors.greenAccent
                                  : MColors.FontsColor,
                              size: iconSize),
                          movieId: movie.id,
                          movieRate: MovieRate.liked,
                          width: width,
                        ),
                        MIconRateButton(
                          icon: Icon(
                              Icons.thumb_down,
                              color: movie.movieRate == MovieRate.notLiked
                                  ? Colors.redAccent
                                  : MColors.FontsColor,
                              size: iconSize,),
                          movieId: movie.id,
                          movieRate: MovieRate.notLiked,
                          width: width,
                        ),
                        MIconRateButton(
                          icon: Icon(
                              Icons.add_to_queue,
                              color: movie.movieRate == MovieRate.addedToWatchlist
                                  ? MColors.AdditionalColor
                                  : MColors.FontsColor,
                              size: iconSize),
                          movieId: movie.id,
                          movieRate: MovieRate.addedToWatchlist,
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
