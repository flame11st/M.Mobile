import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mmobile/Enums/MovieType.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/Shared/BoxShadowNeomorph.dart';
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
    return Scaffold(
        backgroundColor: MColors.PrimaryColor,
        body: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SizedBox.expand(
                child: Hero(
                    tag: 'movie-hero-animation' + movie.id,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
//                        padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
//                        decoration: BoxDecoration(
//                          boxShadow: BoxShadowNeomorph.shadow,
//                          borderRadius: BorderRadius.circular(20.0),
//
//                        ),
                        color: MColors.PrimaryColor,
                        margin: EdgeInsets.fromLTRB(12, 20, 12, 20),
//                                    color: MColors.SecondaryColor,
                        child: ListView(
//                              crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              height: 100,
                              padding: EdgeInsets.all(10),
                              margin: EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: MColors.SecondaryColor,
                                boxShadow: BoxShadowNeomorph.shadow,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: <Widget>[
                                  Text(movie.title,
                                      style: MTextStyles.ExpandedTitle),
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
                                  Text(movie.genres.join(' ,'),
                                      style: MTextStyles.BodyText)
                                ],
                              ),
                            ),
                            if (movie.tagline != null)
                              Center(
                                child: Text(movie.tagline,
                                    style: MTextStyles.BodyText),
                              ),
                            if (movie.tagline != "") SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                    boxShadow: BoxShadowNeomorph.shadow,
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: MColors.PrimaryColor
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
                                          color: MColors.PrimaryColor,
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
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
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
                                  height: 20,
                                ),
//                                Expanded(child: Text(movie.overview, style: MTextStyles.BodyText),),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: 150),
                                  child: Scrollbar(
                                    child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: SizedBox(
                                              child: RichText( text: TextSpan(
                                                style: MTextStyles.BodyText,
                                                children: <TextSpan>[
                                                  new TextSpan(text: 'Overview: ', style: MTextStyles.SubtitleText),
                                                  new TextSpan(text: movie.overview.replaceAll(',', ', ')),
                                                ],
                                              ))
                                            )
                                    ),
                                  ),
                                )
                              ],
                            ),

                          ],
                        ),
                      ),
                    ))),
          ),
        ),
    bottomNavigationBar: MoviesBottomNavigationBarExpanded(movieId: movie.id, movieRate: movie.movieRate,));
  }
}
