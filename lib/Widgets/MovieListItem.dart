import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mmobile/Enums/MovieRate.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Widgets/MovieListItemExpanded.dart';
import 'package:provider/provider.dart';
import 'Shared/BoxShadowNeomorph.dart';
import 'Shared/MovieRateButtons.dart';

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
    final imageUrl =
        movie.posterPath != '' ? movie.posterPath : '/movie_placeholder.png';

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
                child: Container(
                    height: 102.0,
                    margin: EdgeInsets.fromLTRB(10, 10, 10, 5),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          offset: Offset(-3.0, -3.0),
                          blurRadius: 3,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          offset: Offset(4.0, 4.0),
                          blurRadius: 3,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12.0),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 1,
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12)),
                          child: CachedNetworkImage(
                            imageUrl: imageBaseUrl + imageUrl,
                            height: 100,
                            fit: BoxFit.fill,
                            width: 66,
//                            placeholder: (context, url) => CircularProgressIndicator(),
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
                                //TODO: move color to variable
                                Text(movie.title,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            movie.movieRate == MovieRate.liked
                                                ? Theme.of(context)
                                                .accentColor
                                                : movie.movieRate ==
                                                        MovieRate.notLiked
                                                    ? Colors.red
                                                    : Theme.of(context)
                                                        .accentColor)),
                                Row(
                                  children: <Widget>[
                                    Text(movie.year.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5),
                                    SizedBox(
                                      width: 30,
                                    ),
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
                                              .headline5)
                                  ],
                                ),
                                Text(movie.genres.join(', '),
                                    style:
                                        Theme.of(context).textTheme.headline5),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 40,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            boxShadow: BoxShadowNeomorph.circleShadow,
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Theme.of(context).hintColor,
                            ),
                            onPressed: () async {
                              showModalBottomSheet<void>(
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  builder: (BuildContext context) =>
                                      MovieRateButtons(
                                          movieRate: movie.movieRate,
                                          movieId: movie.id,
                                          movieTitle: movie.title,
                                          showTitle: true,
                                          addMargin: false));
                            },
                          ),
                        )
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
