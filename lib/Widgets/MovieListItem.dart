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
          height: selected ? 500.0 : 120.0,
          margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
          color: Color(0xff393e46),
          duration: Duration(milliseconds: 200),
        ),
      ),
    );
  }

}