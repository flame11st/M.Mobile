import 'package:flutter/material.dart';

class MMoviesAnimatedList extends StatelessWidget {
  final GlobalKey<AnimatedListState>? listKey;
  final List<dynamic> movies;
  final dynamic buildItemFunction;
  final bool isPremium;
  final ScrollController? scrollController;
  final EdgeInsets padding;

  const MMoviesAnimatedList({
    super.key,
    this.listKey,
    required this.movies,
    required this.buildItemFunction,
    required this.isPremium,
    this.scrollController,
    this.padding = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      shrinkWrap: true,
      controller: scrollController,
      padding: padding,
      key: listKey,
      initialItemCount: movies.length,
      itemBuilder: (context, index, animation) {
        return buildItemFunction(
          movies[index],
          animation,
          isPremium: isPremium,
          context: context,
        );
      },
    );
  }
}
