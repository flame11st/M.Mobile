import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/MovieListItemExpanded.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class MovieListItem extends StatefulWidget {
  final Movie movie;

  const MovieListItem({Key key, this.movie}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MovieListItemState(movie);
  }
}

class MovieListItemState extends State<MovieListItem> {
  bool expanded = false;
  Movie movie;
  String imageBaseUrl =
      'https://moviediarystorage.blob.core.windows.net/movies';

  MovieListItemState(Movie movie) {
    this.movie = movie;
  }

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showFullMovie(context);
      },
      child: Center(
          child: Hero(
              tag: 'movie-hero-animation' + movie.id,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                    height: 120.0,
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
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
                                Text(movie.title, style: MTextStyles.Title),
                                Text(movie.year.toString(),
                                    style: MTextStyles.BodyText),
                                Text(movie.genres.join(', '),
                                    style: MTextStyles.BodyText),
                                Row(
                                  children: <Widget>[
                                    Text((movie.movieType == MovieType.movie
                                        ? movie.duration.toString()
                                        : movie.averageTimeOfEpisode.toString()) + ' min',
                                        style: MTextStyles.BodyText),
                                    SizedBox(width: 30,),
                                    if (movie.seasonsCount > 0)
                                      Text("Seasons: ${movie.seasonsCount}", style: MTextStyles.BodyText)
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    )),
              ))),
    );
  }

  showFullMovie(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => MovieListItemExpanded(movie: movie)));
  }
}
