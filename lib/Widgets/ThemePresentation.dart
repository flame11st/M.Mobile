import 'package:flutter/material.dart';
import 'package:fluttericon/web_symbols_icons.dart';
import 'package:mmobile/Objects/MTheme.dart';
import 'Shared/MCard.dart';

class ThemePresentation extends StatelessWidget {
  final MTheme theme;
  final bool isCurrent;

  const ThemePresentation({Key key, this.theme, this.isCurrent}) : super(key: key);

  getMovieItem(Color color) {
    return Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: MCard(
          color: theme.colorTheme.secondaryColor,
          padding: 0,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    bottomLeft: Radius.circular(25)),
                child: Container(
                  height: 70,
                  width: 50,
                  color: color,
                ),
              ),
              Expanded(
                  child: Container(
                      padding: EdgeInsets.only(left: 5),
                      height: 70,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Movie title',
                            style: TextStyle(
                                color: theme.colorTheme.additionalColor,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '2020         120min',
                            style: TextStyle(
                                color: theme.colorTheme.fontsColor,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Action, Adventure, Science Fiction',
                            style: TextStyle(
                                color: theme.colorTheme.fontsColor,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      )))
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPanel = Container(
        height: 40,
        width: double.infinity,
//            margin: EdgeInsets.all(5),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.9),
              blurRadius: 1,
            ),
          ],
          color: theme.colorTheme.primaryColor,
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorTheme.additionalColor,
          ),
          child: Icon(Icons.search, color: theme.colorTheme.primaryColor, size: 25,),
        ));

    return Column(
      children: [
        SizedBox(
          height: 10,
        ),
        Text(
         isCurrent ? '${theme.name} (Current)' : theme.name,
          style: TextStyle(fontSize: 18, color: Theme.of(context).hintColor),
        ),
        SizedBox(
          height: 10,
        ),
        Expanded(
            child: Container(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
          decoration: BoxDecoration(
              color: theme.colorTheme.primaryColor,
              border: Border.all(width: 1, color: Theme.of(context).hintColor)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.playlist_play,
                            color: theme.colorTheme.additionalColor,
                          ),
                          SizedBox(
                            width: 7,
                          ),
                          Text(
                            'Watchlist',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: theme.colorTheme.additionalColor),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            WebSymbols.ok,
                            color: theme.colorTheme.fontsColor,
                            size: 13,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            ' Viewed',
                            style: TextStyle(
                              color: theme.colorTheme.fontsColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  getMovieItem(Colors.cyan),
                  getMovieItem(Colors.pink),
                  getMovieItem(Colors.yellow),
                ],
              ),
              bottomPanel
            ],
          ),
        ))
      ],
    );
  }
}
