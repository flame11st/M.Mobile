import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Widgets/Shared/MBoxShadow.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:mmobile/Widgets/Shared/MTextField.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'MoviesBottomNavigationBarExpanded.dart';

class MovieListItemExpanded extends StatefulWidget {
  final Movie movie;
  final bool fromSearch;

  const MovieListItemExpanded(
      {Key key, this.movie, this.fromSearch = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MovieListItemExpandedState(movie, fromSearch);
  }
}

class MovieListItemExpandedState extends State<MovieListItemExpanded> {
  Movie movie;
  bool fromSearch;

  String imageBaseUrl =
      'https://moviediarystorage.blob.core.windows.net/movies';

  MovieListItemExpandedState(
      Movie movie, bool fromSearch) {
    this.movie = movie;
    this.fromSearch = fromSearch;
  }

  getProgressColor() {
    if (movie.rating < 30)
      return Colors.red;
    else if (movie.rating < 70)
      return Colors.amberAccent;
    else
      return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = new NumberFormat("#,###");

    final imageUrl =
        movie.posterPath != '' ? movie.posterPath : '/movie_placeholder.png';
    final topCard = MCard(
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Text(movie.title, style: Theme.of(context).textTheme.headline2),
          SizedBox(
            height: 5,
          ),
          Row(
            children: <Widget>[
              Text(
                  DateFormat(movie.seasonsCount > 0 ? 'yyyy' : 'yyyy-MM-dd')
                      .format(movie.releaseDate),
                  style: Theme.of(context).textTheme.headline5),
              SizedBox(
                width: 15,
              ),
              if (movie.duration > 0 || movie.averageTimeOfEpisode > 0)
                Text(
                    (movie.movieType == MovieType.movie
                            ? movie.duration.toString()
                            : movie.averageTimeOfEpisode.toString()) +
                        ' min',
                    style: Theme.of(context).textTheme.headline5),
              SizedBox(
                width: 15,
              ),
              if (movie.seasonsCount > 0)
                Text("Seasons: ${movie.seasonsCount}",
                    style: Theme.of(context).textTheme.headline5),
              SizedBox(
                width: 15,
              ),
              if (movie.seasonsCount > 0)
                Text("${movie.inProduction ? 'In production' : 'Finished'}",
                    style: Theme.of(context).textTheme.headline5)
            ],
          ),
          if (movie.genres.isNotEmpty)
            SizedBox(
              height: 5,
            ),
          if (movie.genres.isNotEmpty)
            Text(movie.genres.join(', '),
                style: Theme.of(context).textTheme.headline5)
        ],
      ),
    );

    final contentBody = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        MCard(
          padding: 1,
          marginTop: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: CachedNetworkImage(
              imageUrl: imageBaseUrl + imageUrl,
              height: 180,
              fit: BoxFit.fill,
              width: 120,
//              placeholder: (context, url) => CircularProgressIndicator(),
            ),
          ),
        ),
        Column(
          children: <Widget>[
            Container(
              height: 146,
              width: 146,
              decoration: new BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      offset: Offset(0.0, 0.1),
                      blurRadius: 0.5),
                ],
              ),
              child: CircularPercentIndicator(
                radius: 140.0,
                lineWidth: 6.0,
                percent: movie.allVotes > 0 && movie.rating == 0
                    ? 1
                    : movie.rating / 100,
                center: movie.allVotes > 0
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text("${movie.rating}%",
                              style: Theme.of(context).textTheme.headline5),
                          SizedBox(height: 5),
                          Text("Votes: ${formatter.format(movie.allVotes)}",
                              style: Theme.of(context).textTheme.headline5)
                        ],
                      )
                    : Text("Not rated",
                        style: Theme.of(context).textTheme.headline5),
                progressColor: getProgressColor(),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Imdb: ${movie.imdbVotes > 0 ? '${movie.imdbRate} (${formatter.format(movie.imdbVotes)})' : 'Not rated'}",
              style: Theme.of(context).textTheme.headline5,
            )
          ],
        )
      ],
    );

    final textFields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        if (movie.tagline != null && movie.tagline.isNotEmpty)
          MTextField(subtitleText: 'Tagline', bodyText: movie.tagline),
        if (movie.directors.isNotEmpty) SizedBox(height: 10),
        if (movie.directors.isNotEmpty)
          MTextField(
              subtitleText: 'Directed by',
              bodyText: movie.directors.map((director) => director).join(', ')),
        if (movie.actors.isNotEmpty) SizedBox(height: 10),
        if (movie.actors.isNotEmpty)
          MTextField(
              subtitleText: 'Starring',
              bodyText: movie.actors.map((actor) => actor).join(', ')),
        if (movie.countries.isNotEmpty) SizedBox(height: 10),
        if (movie.countries.isNotEmpty)
          MTextField(
              subtitleText: 'Countries',
              bodyText: movie.countries.replaceAll(',', ', ')),
        if (movie.overview.isNotEmpty)
          SizedBox(
            height: 10,
          ),
        if (movie.overview.isNotEmpty)
          MTextField(subtitleText: 'Overview', bodyText: movie.overview),
      ],
    );

    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            body: Hero(
              tag: 'movie-hero-animation' + movie.id,
              child: SingleChildScrollView(
                child: Container(
                    margin: EdgeInsets.fromLTRB(10, 20, 10, 20),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        color: Theme.of(context).primaryColor,
                        child: Column(
                          children: <Widget>[
                            topCard,
                            SizedBox(height: 20),
                            contentBody,
                            SizedBox(height: 20),
                            textFields,
                          ],
                        ),
                      ),
                    )),
              ),
            ),
            bottomNavigationBar: MoviesBottomNavigationBarExpanded(
              movie: movie,
              fromSearch: fromSearch,
            )));
  }
}
