import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';
import 'Shared/FilterButton.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/elusive_icons.dart';

class MoviesFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final isWatchlist = moviesState.isWatchlist();

    return Container(
        height: isWatchlist ? 100 : 160,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
//            Row(
//              mainAxisAlignment: MainAxisAlignment.spaceBetween,
//              children: <Widget>[
//                Text(
//                  'Filters',
//                  style: Theme.of(context).textTheme.headline2,
//                ),
//                IconButton(
//                  icon: Icon(Icons.close),
//                )
//              ],
//            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(
                  'Type:',
                  style: Theme.of(context).textTheme.headline5,
                ),
                FilterIcon(
                  icon: FontAwesome.video,
                  text: 'Movies',
                  isActive: moviesState.moviesOnly,
                  onPressedCallback: () {
                    moviesState.changeMoviesOnlyFilter();
                  },
                ),
                FilterIcon(
                  icon: Icons.tv,
                  text: 'TV shows',
                  isActive: moviesState.tvOnly,
                  onPressedCallback: () {
                    moviesState.changeTVOnlyFilter();
                  },
                ),
              ],
            ),
            if (!isWatchlist)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(
                    'Rate:',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  FilterIcon(
                      icon: Icons.favorite_border,
                      text: 'Liked',
                      isActive: moviesState.likedOnly,
                      onPressedCallback: () {
                        moviesState.changeLikedOnlyFilter();
                      }),
                  FilterIcon(
                      icon: FontAwesome5.ban,
                      text: 'Not Liked',
                      isActive: moviesState.notLikedOnly,
                      onPressedCallback: () {
                        moviesState.changeNotLikedOnlyFilter();
                      }),
                ],
              ),
          ],
        ));
  }
}
