import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';
import 'Shared/FilterButton.dart';

class MoviesFilter extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        final moviesState = Provider.of<MoviesState>(context);

        return Container(
                height: 200,
                color: Theme
                        .of(context)
                        .primaryColor,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                                FilterIcon(
                                    icon: Icons.movie,
                                    text: 'Movies',
                                    isActive: moviesState.moviesOnly,
                                    onPressedCallback: () {
                                        moviesState.changeMoviesOnlyFilter();
                                    },
                                ),
                                FilterIcon(
                                    icon: Icons.tv,
                                    text: 'TV',
                                    isActive: moviesState.tvOnly,
                                  onPressedCallback: () {
                                    moviesState.changeTVOnlyFilter();
                                  },
                                ),
                                FilterIcon(
                                    icon: Icons.thumb_up,
                                    text: 'Liked',
                                    isActive: moviesState.likedOnly,
                                ),
                                FilterIcon(
                                    icon: Icons.thumb_down,
                                    text: 'Not Liked',
                                    isActive: moviesState.notLikedOnly,
                                ),
                            ],
                        ),
                    ],
                ));
    }
}
