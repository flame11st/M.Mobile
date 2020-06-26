import 'package:flutter/material.dart';

class MovieListItem extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MovieListItemState();
  }
}

class MovieListItemState extends State<MovieListItem> {
  bool selected = false;

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selected = !selected;
        });
      },
      child: Center(
        child: AnimatedContainer(
          height: selected ? 250.0 : 75.0,
          margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
          color: Colors.black26,
          duration: Duration(milliseconds: 200),
        ),
      ),
    );
  }

}