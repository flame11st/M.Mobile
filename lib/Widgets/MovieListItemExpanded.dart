import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/BoxShadowNeomorph.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'BottomNavigationBarExpanded.dart';

class MovieListItemExpanded extends StatefulWidget {
  final Movie movie;

  const MovieListItemExpanded({Key key, this.movie}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MovieListItemExpandedState(movie);
  }
}

class MovieListItemExpandedState extends State<MovieListItemExpanded> {
  Movie movie;
  String imageBaseUrl =
      'https://moviediarystorage.blob.core.windows.net/movies';

  MovieListItemExpandedState(Movie movie) {
    this.movie = movie;
  }

  getProgressColor() {
    if (movie.rating < 30)
      return Colors.red;
    else if (movie.rating < 70)
      return Colors.amberAccent;
    else
      return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = movie.posterPath != '' ? movie.posterPath : '/movie_placeholder.png';
    final topCard = MCard(
      padding: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
        MainAxisAlignment.spaceAround,
        children: <Widget>[
          Text(movie.title,
                  style: MTextStyles.ExpandedTitle),
          SizedBox(
            height: 10,
          ),
          Row(
            children: <Widget>[
              Text(movie.year.toString(),
                      style: MTextStyles.BodyText),
              SizedBox(
                width: 15,
              ),
              Text(
                      (movie.movieType == MovieType.movie
                              ? movie.duration.toString()
                              : movie.averageTimeOfEpisode.toString())+
                              ' min',
                      style: MTextStyles.BodyText),
              SizedBox(
                width: 15,
              ),
              if (movie.seasonsCount > 0)
                Text("Seasons: ${movie.seasonsCount}", style: MTextStyles.BodyText)
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Text(movie.genres.join(' ,'),
                  style: MTextStyles.BodyText)
        ],
      ),
    );

    final contentBody = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
                  boxShadow: BoxShadowNeomorph.shadow,
                  borderRadius: BorderRadius.circular(10.0),
                  color: Theme.of(context).primaryColor
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: imageBaseUrl + imageUrl,
              height: 150,
              fit: BoxFit.fill,
              width: 100,
//                                        placeholder: (context, url) => CircularProgressIndicator(),
            ),
          ),
        ),
        Column(
          children: <Widget>[
            Container(
              height: 116,
              width: 116,
              decoration: new BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow:
                      BoxShadowNeomorph.circleShadow),
              child: CircularPercentIndicator(
                radius: 110.0,
                lineWidth: 6.0,
                percent: movie.allVotes > 0 &&
                        movie.rating == 0
                        ? 1
                        : movie.rating / 100,
                center: movie.allVotes > 0
                        ? Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: <Widget>[
                    Text("${movie.rating}%",
                            style:
                            MTextStyles.BodyText),
                    SizedBox(height: 5),
                    Text("Votes: ${movie.allVotes}",
                            style:
                            MTextStyles.BodyText)
                  ],
                )
                        : Text("Not rated",
                        style: MTextStyles.BodyText),
                progressColor: getProgressColor(),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Imdb: ${movie.imdbRate} (${movie.imdbVotes})",
              style: MTextStyles.BodyText,
            )
          ],
        )
      ],
    );

    final textFields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        if (movie.tagline != null)
          RichText( text: TextSpan(
            style: MTextStyles.BodyText,
            children: <TextSpan>[
              new TextSpan(text: 'Tagline: ', style: MTextStyles.SubtitleText),
              new TextSpan(text: movie.tagline),
            ],
          )),
        SizedBox(height: 10),
        RichText( text: TextSpan(
          style: MTextStyles.BodyText,
          children: <TextSpan>[
            new TextSpan(text: 'Directed by: ', style: MTextStyles.SubtitleText),
            new TextSpan(text: movie.directors
                    .map((actor) => actor.name)
                    .join(', ')),
          ],
        )),
        SizedBox(height: 10),
        RichText( text: TextSpan(
          style: MTextStyles.BodyText,
          children: <TextSpan>[
            new TextSpan(text: 'Starring: ', style: MTextStyles.SubtitleText),
            new TextSpan(text: movie.actors
                    .map((actor) => actor.name)
                    .join(', ')),
          ],
        )),
        SizedBox(height: 10),
        RichText( text: TextSpan(
          style: MTextStyles.BodyText,
          children: <TextSpan>[
            new TextSpan(text: 'Countries: ', style: MTextStyles.SubtitleText),
            new TextSpan(text: movie.countries.replaceAll(',', ', ')),
          ],
        )),
        SizedBox(
          height: 15,
        ),
        RichText( text: TextSpan(
          style: MTextStyles.BodyText,
          children: <TextSpan>[
            new TextSpan(text: 'Overview: ', style: MTextStyles.SubtitleText),
            new TextSpan(text: movie.overview.replaceAll(',', ', ')),
          ],
        ))
      ],
    );

    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Container(
          child: Hero(
            tag: 'movie-hero-animation' + movie.id,
            child: SingleChildScrollView (child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                      margin: EdgeInsets.fromLTRB(12, 20, 12, 20),
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
          )),
    bottomNavigationBar: MoviesBottomNavigationBarExpanded(movieId: movie.id, movieRate: movie.movieRate,));
  }
}
