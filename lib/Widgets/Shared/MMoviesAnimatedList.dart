import 'package:flutter/material.dart';

class MMoviesAnimatedList extends StatelessWidget {
  final listKey;
  final movies;
  final buildItemFunction;
  final isPremium;
  final scrollController;

  const MMoviesAnimatedList({super.key, this.listKey, this.movies, this.buildItemFunction, this.isPremium, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: AnimatedList(
        shrinkWrap: true,
        controller: scrollController,
        padding: EdgeInsets.only(bottom: 90),
        key: listKey,
        initialItemCount: movies.length,
        itemBuilder: (context, index, animation) {
          // if (movies.length > index) return null;

          return buildItemFunction(
              movies[index], animation,
              isPremium: isPremium,
              context: context);
        },
      ),
    );
  }
}
