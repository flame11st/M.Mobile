import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'MovieListItemExpanded.dart';
import 'Shared/MCard.dart';
import 'Shared/MIconRateButton.dart';
import 'package:http/http.dart' as http;

class MovieSearchItem extends StatelessWidget {
  final Movie movie;
  final imageBaseUrl = 'https://moviediarystorage.blob.core.windows.net/movies';

  // const MovieSearchItem({Key key, this.movie, this.imageBaseUrl}) : super(key: key);
  const MovieSearchItem({Key key, this.movie}) : super(key: key);
  final iconSize = 20.0;
  final width = 45.0;

  showFullMovie(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => MovieListItemExpanded(
              movie: movie,
              fromSearch: true,
              // imageUrl: imageBaseUrl,
            )));
  }

  checkImage(String imageUrl) async {
    final response = await http.head(imageBaseUrl + imageUrl);

    if (response.statusCode == 404) {
      final serviceAgent = new ServiceAgent();

      await serviceAgent.reloadMoviePoster(movie.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        movie.posterPath != '' ? movie.posterPath : '/movie_placeholder.png';

    checkImage(imageUrl);

    return GestureDetector(
        onTap: () {
          showFullMovie(context);
        },
        child: MCard(
            marginBottom: 5,
            marginLR: 10,
            marginTop: 15,
            padding: 0,
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4)),
                  child: Image.network(
                    imageBaseUrl + imageUrl,
                    height: 90,
                    fit: BoxFit.fill,
                    width: 60,
//                                        placeholder: (context, url) => CircularProgressIndicator(),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 90,
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
                                text: movie.title,
                                style: Theme.of(context).textTheme.headline3),
                            new TextSpan(
                                text:
                                    ' (${DateFormat('yyyy').format(movie.releaseDate)})'),
                          ],
                        )),

//                    Text(movie.genres.join(', '), style: Theme.of(context).textTheme.headline5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            MIconRateButton(
                              color: movie.movieRate == MovieRate.liked
                                  ? Colors.green
                                  : Theme.of(context).primaryColor,
                              icon: Icon(Icons.favorite_border,
                                  color: movie.movieRate == MovieRate.liked
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).hintColor),
                              movie: movie,
                              movieRate: movie.movieRate == MovieRate.liked
                                  ? MovieRate.notRated
                                  : MovieRate.liked,
                              width: width,
                            ),
                            MIconRateButton(
                              color: movie.movieRate == MovieRate.notLiked
                                  ? Colors.redAccent
                                  : Theme.of(context).primaryColor,
                              icon: Icon(FontAwesome5.ban,
                                  color: movie.movieRate == MovieRate.notLiked
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).hintColor),
                              movie: movie,
                              movieRate: movie.movieRate == MovieRate.notLiked
                                  ? MovieRate.notRated
                                  : MovieRate.notLiked,
                              width: width,
                            ),
                            MIconRateButton(
                              color:
                                  movie.movieRate == MovieRate.addedToWatchlist
                                      ? Theme.of(context).accentColor
                                      : Theme.of(context).primaryColor,
                              icon: Icon(Icons.add_to_queue,
                                  color: movie.movieRate ==
                                          MovieRate.addedToWatchlist
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).hintColor),
                              movie: movie,
                              movieRate:
                                  movie.movieRate == MovieRate.addedToWatchlist
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
            )));
  }
}
