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
                          color: Colors.white.withOpacity(0.15),
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
                            padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  offset: Offset(-4.0, -4.0),
//                                  spreadRadius: -1,
                                  blurRadius: 12,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  offset: Offset(6.0, 6.0),
                                  blurRadius: 12,
//                                  spreadRadius: -5,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(20.0),
                              color: MColors.PrimaryColor,
                            ),
                            margin: EdgeInsets.fromLTRB(12, 40, 12, 20),
//                                    color: MColors.SecondaryColor,
                            child: ListView(
//                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  height: 100,
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
                                              movie.duration.toString() +
                                                  ' min',
                                              style: MTextStyles.BodyText),
                                        ],
                                      ),
                                      Text(movie.genres.join(' ,'),
                                          style: MTextStyles.BodyText)
                                    ],
                                  ),
                                ),
                                Text(movie.tagline,
                                    style: MTextStyles.BodyText),
                                Row(
                                  children: <Widget>[
                                    Container(
                                      margin: EdgeInsets.only(bottom: 15),
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            offset: Offset(-4.0, -4.0),
                                            blurRadius: 4,
                                          ),
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.4),
                                            offset: Offset(4.0, 4.0),
                                            blurRadius: 2,
                                          ),
                                        ],
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              imageBaseUrl + movie.posterPath,
                                          height: 160,
                                          fit: BoxFit.fill,
                                          width: 100,
//                                        placeholder: (context, url) => CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                          height: 160,
                                          margin: EdgeInsets.only(left: 10),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Text(
                                                  movie.actors
                                                      .map(
                                                          (actor) => actor.name)
                                                      .join(' ,'),
                                                  style: MTextStyles.BodyText),
                                              Text(movie.countries,
                                                  style: MTextStyles.BodyText)
                                            ],
                                          )),
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
                                      width: MediaQuery.of(context).size.width -
                                          90,
                                      animation: true,
                                      lineHeight: 25.0,
                                      animationDuration: 2000,
                                      percent: 0.9,
                                      center: new Text(
                                        "70%",
                                        style: new TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.0),
                                      ),
                                      linearStrokeCap: LinearStrokeCap.roundAll,
                                      progressColor: Colors.greenAccent,
                                    )),
                                    DefaultTabController(
                                            length: 2,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: MColors.PrimaryColor,
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
                                              child: Column(
                                                children: <Widget>[
                                                  Container(
                                                    height: 50,
                                                    width: 250,
                                                    child: TabBar(
                                                      tabs: [
                                                        for (final tab in ["First","Second"]) Tab(text: tab),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 250,
                                                    height: 200,
                                                    child: TabBarView(
                                                      children: [
                                                        for (final tab in ["First","Second"])
                                                          Center(
                                                            child: Text(tab),
                                                          ),
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            )
                                    )
//                                Text(movie.overview,
//                                    style: MTextStyles.BodyText)
                              ],
                            ),
                          ),
                        ))),
              ),
            ))));
  }
}
