import 'package:flutter/material.dart';

class MMoviesAnimatedList extends StatelessWidget {
  final listKey;
  final movies;
  final buildItemFunction;
  final isPremium;

  const MMoviesAnimatedList({Key key, this.listKey, this.movies, this.buildItemFunction, this.isPremium})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: AnimatedList(
        shrinkWrap: true,
        padding: EdgeInsets.only(bottom: 90),
        key: listKey,
        initialItemCount: movies.length,
        itemBuilder: (context, index, animation) {
          if (movies.length <= index) return null;

          return buildItemFunction(
              movies[index], animation,
              isPremium: isPremium,
              context: context);
        },
      ),
    );
  }
}
