import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';
import 'Shared/FilterButton.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:fluttericon/font_awesome5_icons.dart';

class MoviesFilter extends StatelessWidget {
  selectDateFrom(BuildContext context, MoviesState state) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: state.dateFrom,
      firstDate: state.dateMin,
      lastDate: state.dateMax,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).accentColorBrightness == Brightness.dark
              ? ThemeData.dark()
              : ThemeData.light(), // This will change to light theme.
          child: child,
        );
      },
    );
    if (picked != null && picked != state.dateFrom)
      state.changeDateFromFilter(picked);
  }

  selectDateTo(BuildContext context, MoviesState state) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: state.dateTo,
      firstDate: state.dateMin,
      lastDate: state.dateMax,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).accentColorBrightness == Brightness.dark
              ? ThemeData.dark()
              : ThemeData.light(), // This will change to light theme.
          child: child,
        );
      },
    );
    if (picked != null && picked != state.dateTo)
      state.changeDateToFilter(picked);
  }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final isWatchlist = moviesState.isWatchlist();

    return Container(
        height: isWatchlist ? 100 : 300,
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
            if (!isWatchlist)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Date:',
                  style: Theme.of(context).textTheme.headline5,
                ),
                FilterIcon(
                  icon: Icons.calendar_today,
                  text: DateFormat('yyyy-MM-dd').format(moviesState.dateFrom),
                  isActive: moviesState.isDateFromSelected(),
                  onPressedCallback: () {
                    selectDateFrom(context, moviesState);
                  },
                  textSize: 16,
                ),
                FilterIcon(
                  icon: Icons.calendar_today,
                  text: DateFormat('yyyy-MM-dd').format(moviesState.dateTo),
                  isActive: moviesState.isDateToSelected(),
                  onPressedCallback: () {
                    selectDateTo(context, moviesState);
                  },
                  textSize: 16,
                ),
              ],
            ),
            if (!isWatchlist)
            MButton(
              active: moviesState.isAnyFilterSelected(),
              text: 'Clear all',
              width: 150,
              height: 40,
              onPressedCallback: () => moviesState.clearAllFilters(),
            )
          ],
        ));
  }
}
