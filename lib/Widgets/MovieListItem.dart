import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mmobile/Objects/Movie.dart';
import 'package:mmobile/Variables/Variables.dart';
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
                          color: Colors.white.withOpacity(0.1),
                          offset: Offset(-3.0, -3.0),
                          blurRadius: 6,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          offset: Offset(3.0, 3.0),
                          blurRadius: 4,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12.0),
                      color: MColors.PrimaryColor,
                    ),
                    child: Row(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
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
                                Text(movie.duration.toString() + ' min',
                                    style: MTextStyles.BodyText),
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
        builder: (ctx) => Scaffold(
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
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  offset: Offset(-6.0, -6.0),
                                  spreadRadius: -1,
                                  blurRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  offset: Offset(6.0, 6.0),
                                  blurRadius: 5,
                                  spreadRadius: -5,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(20.0),
                              color: MColors.PrimaryColor,
                            ),
                            margin: EdgeInsets.fromLTRB(20, 40, 20, 20),
//                                    color: MColors.SecondaryColor,
                            child: ListView(
//                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  height: 80,
                                  padding: EdgeInsets.all(10),
                                  margin: EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                    color: MColors.PrimaryColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.1),
                                        offset: Offset(-3.0, -3.0),
                                        blurRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        offset: Offset(3.0, 3.0),
                                        blurRadius: 2,
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      Text(movie.title,
                                          style: MTextStyles.ExpandedTitle),
                                      Row(
                                        children: <Widget>[
                                          Text(movie.year.toString(),
                                              style: MTextStyles.BodyText),
                                          SizedBox(width: 15,),
                                          Text(movie.duration.toString() + ' min',
                                              style: MTextStyles.BodyText),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
//                                LinearProgressIndicator(
//                                  value: movie.rating / 100,
//                                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.red),
//                                  backgroundColor: Colors.cyanAccent,
//                                ),
                                Row(
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(bottom: 15),
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.1),
                                            offset: Offset(-4.0, -4.0),
                                            blurRadius: 4,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.4),
                                            offset: Offset(4.0, 4.0),
                                            blurRadius: 2,
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8.0),
                                        child: CachedNetworkImage(
                                          imageUrl: imageBaseUrl + movie.posterPath,
                                          height: 180,
                                          fit: BoxFit.fill,
                                          width: 120,
//                                        placeholder: (context, url) => CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                          height: 180,
                                          margin: EdgeInsets.only(left: 15),
                                          padding: EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Text(movie.tagline,
                                                  style: MTextStyles.BodyText),
                                              Text(movie.genres.join(' ,'),
                                                  style: MTextStyles.BodyText),
                                              Text(movie.countries,
                                                  style: MTextStyles.BodyText)
                                            ],
                                          )
                                      ),
                                    ),
                                  ],
                                ),
                            Container(
                                margin: EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.2),
                                      offset: Offset(-4.0, -4.0),
                                      blurRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      offset: Offset(4.0, 4.0),
                                      blurRadius: 8,
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: LinearPercentIndicator(
                                  width: MediaQuery.of(context).size.width - 85,
                                  animation: true,
                                  lineHeight: 25.0,
                                  animationDuration: 2000,
                                  percent: 0.9,
                                  center: new Text(
                                    "70.0%",
                                    style:
                                    new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                                  ),
                                  linearStrokeCap: LinearStrokeCap.roundAll,
                                  progressColor: Colors.greenAccent,
                                )),
                                Text(movie.overview, style: MTextStyles.BodyText)
                              ],
                            ),
                          ),
                        ))),
              ),
            ))));
  }
}
