import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mmobile/Enums/MovieListType.dart';
import 'package:mmobile/Helpers/ad_manager.dart';
import 'package:mmobile/Objects/MoviesList.dart';
import 'package:mmobile/Services/ServiceAgent.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:mmobile/Widgets/MoviesListPage.dart';
import 'package:mmobile/Widgets/Providers/UserState.dart';
import 'package:mmobile/Widgets/Shared/MCard.dart';
import 'package:mmobile/Widgets/Shared/MIconButton.dart';
import 'package:provider/provider.dart';
import 'Providers/MoviesState.dart';
import 'Shared/MButton.dart';

class MoviesListsPage extends StatefulWidget {
  final initialPageIndex;

  MoviesListsPage({this.initialPageIndex});

  @override
  State<StatefulWidget> createState() {
    return MoviesListsPageState(initialPageIndex);
  }
}

class MoviesListsPageState extends State<MoviesListsPage>
    with SingleTickerProviderStateMixin {
  TabController tabController;
  final serviceAgent = new ServiceAgent();
  final nameController = TextEditingController();
  bool submitButtonActive = false;
  final _formKey = GlobalKey<FormState>();
  int initialPageIndex = 0;

  MoviesListsPageState(this.initialPageIndex);

  @override
  void initState() {
    super.initState();
    tabController = new TabController(vsync: this, length: 2);

    nameController.addListener(setSubmitButtonActive);
  }

  @override
  void dispose() {
    tabController.dispose();

    super.dispose();
  }

  void setSubmitButtonActive() {
    setState(() {
      submitButtonActive = nameController.text.length > 0;
    });
  }

  Route _createRoute(MoviesList moviesList) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          MoviesListPage(moviesList: moviesList),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  getMovieListWidget(MoviesList moviesList, MovieListType type) {
    String imageBaseUrl =
        "https://moviediarystorage.blob.core.windows.net/movies";
    final borderRadius = Platform.isIOS ? 10.0 : 4.0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => MoviesListPage(moviesList: moviesList))),
      child: MCard(
          padding: 0,
          child: Container(
              height: 80,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                image: DecorationImage(
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(
                          moviesList.listMovies.isNotEmpty ? 0.3 : 0.0),
                      BlendMode.dstATop),
                  image: moviesList.listMovies.isNotEmpty
                      ? NetworkImage(
                          imageBaseUrl + moviesList.listMovies.first.posterPath)
                      : AssetImage("Assets/emptyList.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                          moviesList.name,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          moviesList.listMovies.length.toString() +
                              " item" +
                              (moviesList.listMovies.length == 1 ? "" : "s"),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      ])),
                  Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ))),
    );
  }

  addNewList() {
    final moviesState = Provider.of<MoviesState>(context, listen: false);
    final userState = Provider.of<UserState>(context, listen: false);

    final order = getMaxListOrder(moviesState.personalMoviesLists) + 1;

    showDialog<String>(
        context: context,
        builder: (BuildContext context1) => AlertDialog(
              contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              backgroundColor: Theme.of(context).primaryColor,
              contentTextStyle: Theme.of(context).textTheme.headline5,
              content: Container(
                  height: 90,
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(0),
                  child: Form(
                    key: _formKey,
                    child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: Theme.of(context).accentColor),
                        child: TextFormField(
                          validator: (value) => nameController.text.isEmpty
                              ? "Please enter name"
                              : moviesState.personalMoviesLists.any((element) =>
                                      element.name == nameController.text)
                                  ? "List with the same name already exists"
                                  : null,
                          controller: nameController,
                          decoration: InputDecoration(
                              contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              labelText: "Enter movies list name",
                              hintStyle: Theme.of(context).textTheme.headline5),
                        )),
                  )),
              actions: [
                MButton(
                  active: true,
                  text: 'Add',
                  parentContext: context,
                  onPressedCallback: () async {
                    if (_formKey.currentState != null &&
                        _formKey.currentState.validate()) {
                      moviesState.addMoviesList(nameController.text, order);

                      if (!userState.isIncognitoMode) {
                        serviceAgent.state = userState;

                        await serviceAgent.createUserMoviesList(
                            userState.userId, nameController.text, order);
                      }

                      nameController.clear();

                      Navigator.of(context1).pop();
                    }
                  },
                ),
                SizedBox(
                  width: 10,
                ),
                MButton(
                  active: true,
                  text: 'Cancel',
                  parentContext: context,
                  onPressedCallback: () => Navigator.of(context1).pop(),
                )
              ],
            ));
  }

  int getMaxListOrder(List<MoviesList> lists) {
    var order = lists.length == 0
        ? 0
        : lists
            .reduce((curr, next) => curr.order > next.order ? curr : next)
            .order;

    return order;
  }

  @override
  Widget build(BuildContext context) {
    if (initialPageIndex != null && initialPageIndex != 0) {
      tabController.animateTo(initialPageIndex);

      initialPageIndex = 0;
    }

    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    moviesState.externalMoviesLists.sort((a, b) => a.order > b.order ? 1 : 0);
    moviesState.personalMoviesLists.sort((a, b) => a.order > b.order ? 1 : 0);

    final headingRow = AppBar(
      title: TabBar(
        controller: tabController,
        indicatorColor: Theme.of(context).accentColor,
        labelColor: Theme.of(context).accentColor,
        unselectedLabelColor: Theme.of(context).hintColor,
        tabs: [
          Tab(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(FontAwesome5.empire),
              SizedBox(
                width: 7,
              ),
              Text(
                'General',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          )),
          Tab(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(FontAwesome5.jedi_order),
              SizedBox(
                width: 5,
              ),
              Text(
                'Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          )),
        ],
      ),
    );

    return Scaffold(
        appBar: AdManager.bannerVisible && AdManager.bannersReady
            ? AppBar(
                title: Center(
                  child: AdManager.getBannerWidget(AdManager.listsBannerAd),
                ),
                automaticallyImplyLeading: false,
                elevation: 0.7,
              )
            : PreferredSize(preferredSize: Size(0, 0), child: Container()),
        body: Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            appBar: headingRow,
            body: Container(
                color: Theme.of(context).primaryColor,
                child: TabBarView(
                  controller: tabController,
                  children: [
                    SingleChildScrollView(
                        child: Container(
                            padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
                            color: Theme.of(context).primaryColor,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                if (moviesState.externalMoviesLists.isEmpty)
                                  SizedBox(
                                    height: 40,
                                  ),
                                if (moviesState.externalMoviesLists.isEmpty)
                                  Center(child: CircularProgressIndicator()),
                                if (moviesState.externalMoviesLists.isNotEmpty)
                                  for (int i = 0;
                                      i <
                                          moviesState
                                              .externalMoviesLists.length;
                                      i++)
                                    getMovieListWidget(
                                        moviesState.externalMoviesLists[i],
                                        MovieListType.external),
                              ],
                            ))),
                    Stack(
                      children: [
                        SingleChildScrollView(
                            child: Container(
                                padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
                                color: Theme.of(context).primaryColor,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    if (moviesState.externalMoviesLists.isEmpty)
                                      SizedBox(
                                        height: 40,
                                      ),
                                    if (moviesState.externalMoviesLists.isEmpty)
                                      Center(
                                          child: CircularProgressIndicator()),
                                    if (moviesState
                                            .externalMoviesLists.isNotEmpty &&
                                        moviesState.personalMoviesLists.isEmpty)
                                      Text(
                                        "You haven't created any personal list.\n"
                                        "Please tap the 'Add' button to create a new one.",
                                        style:
                                            TextStyle(fontSize: 17, height: 2),
                                      ),
                                    if (moviesState.personalMoviesLists.length >
                                        0)
                                      for (int i = 0;
                                          i <
                                              moviesState
                                                  .personalMoviesLists.length;
                                          i++)
                                        getMovieListWidget(
                                            moviesState.personalMoviesLists[i],
                                            MovieListType.personal),
                                  ],
                                ))),
                        Align(
                            alignment: Alignment(0.83, 0.92),
                            child: Container(
                                height: 55.0,
                                width: 55.0,
                                child: FittedBox(
                                  child: FloatingActionButton(
                                    onPressed: () {
                                      addNewList();
                                    },
                                    child: const Icon(
                                      Icons.add,
                                      size: 35,
                                    ),
                                    backgroundColor:
                                        Theme.of(context).accentColor,
                                    foregroundColor:
                                        Theme.of(context).primaryColor,
                                  ),
                                )))
                      ],
                    )
                  ],
                ))));
  }
}
