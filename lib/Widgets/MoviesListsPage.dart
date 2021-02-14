import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:mmobile/Enums/MovieListType.dart';
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
    // final moviesState = Provider.of<MoviesState>(context);
    // final moviesLists = moviesState.moviesLists
    //     .where((element) => element.movieListType == type)
    //     .toList();
    //
    // moviesLists.sort((a, b) => a.order > b.order ? 1 : 0);
    //
    // if (moviesLists.isEmpty) return SizedBox();
    //
    // final moviesList = moviesLists[order];
    return GestureDetector(
      onTap: () => Navigator.of(context).push(_createRoute(moviesList)),
      child: MCard(
          child: Container(
              child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            moviesList.name,
            style: Theme.of(context).textTheme.headline5,
          ),
          Icon(
            Icons.arrow_forward,
            color: Theme.of(context).hintColor,
          ),
        ],
      ))),
    );
  }

  addNewList(List<MoviesList> personalLists) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    final order = getMaxListOrder(personalLists) + 1;

    showDialog<String>(
        context: context,
        builder: (BuildContext context1) => AlertDialog(
              backgroundColor: Theme.of(context).primaryColor,
              contentTextStyle: Theme.of(context).textTheme.headline5,
              content: Container(
                  height: 100,
                  margin: EdgeInsets.all(0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'Enter movies list name:',
                          style: Theme.of(context).textTheme.headline2,
                        ),
                        TextFormField(
                          validator: (value) => nameController.text.isEmpty
                              ? "Please enter name"
                              : personalLists.any((element) =>
                                      element.name == nameController.text)
                                  ? "List with the same name already exists"
                                  : null,
                          controller: nameController,
                          decoration: InputDecoration(
                            contentPadding:
                                EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                          ),
                        )
                      ],
                    ),
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

    final externalLists = moviesState.moviesLists
        .where((element) => element.movieListType == MovieListType.external)
        .toList();

    final personalLists = moviesState.moviesLists
        .where((element) => element.movieListType == MovieListType.personal)
        .toList();

    externalLists.sort((a, b) => a.order > b.order ? 1 : 0);
    personalLists.sort((a, b) => a.order > b.order ? 1 : 0);

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
              Icon(FontAwesome5.imdb),
              SizedBox(
                width: 7,
              ),
              Text(
                'External',
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
              Icon(Icons.person),
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

    return WillPopScope(
        onWillPop: () {
          Navigator.of(context).pop();

          userState.shouldRequestReview = true;
          return;
        },
        child: Scaffold(
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
                              if (moviesState.moviesLists.length == 0)
                                SizedBox(
                                  height: 40,
                                ),
                              if (moviesState.moviesLists.length == 0)
                                Center(child: CircularProgressIndicator()),
                              if (moviesState.moviesLists.length > 0)
                                for (int i = 0; i < externalLists.length; i++)
                                  getMovieListWidget(
                                      externalLists[i], MovieListType.external),
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
                                  if (moviesState.moviesLists.isEmpty)
                                    SizedBox(
                                      height: 40,
                                    ),
                                  if (moviesState.moviesLists.length == 0)
                                    Center(child: CircularProgressIndicator()),
                                  if (moviesState.moviesLists.isNotEmpty &&
                                      personalLists.isEmpty)
                                    Text(
                                      "You haven't created any personal list.\n"
                                          "Please tap the 'Add' button to create a new one.",
                                      style: TextStyle(fontSize: 17, height: 2),
                                    ),
                                  if (moviesState.moviesLists.length > 0)
                                    for (int i = 0;
                                        i < personalLists.length;
                                        i++)
                                      getMovieListWidget(personalLists[i],
                                          MovieListType.personal),
                                ],
                              ))),
                      Align(
                          alignment: Alignment(0.83, 0.92),
                          child: Container(
                              height: 60.0,
                              width: 60.0,
                              child: FittedBox(
                                child: FloatingActionButton(
                                  onPressed: () {
                                    addNewList(personalLists);
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
              ),
            )));
  }
}
