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
  @override
  State<StatefulWidget> createState() {
    return MoviesListsPageState();
  }
}

class MoviesListsPageState extends State<MoviesListsPage>
    with SingleTickerProviderStateMixin {
  TabController tabController;
  final serviceAgent = new ServiceAgent();
  final nameController = TextEditingController();
  bool submitButtonActive = false;
  final _formKey = GlobalKey<FormState>();

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

  // getMovieListWidget(int order, MovieListType type) {
    getMovieListWidget(int order) {
    final moviesState = Provider.of<MoviesState>(context);
    // final moviesList = moviesState.moviesLists.singleWhere(
    //     (element) => element.order == order && element.movieListType == type);
    final moviesList = moviesState.moviesLists.singleWhere(
        (element) => element.order == order);

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

  // addNewList() {
  //   final moviesState = Provider.of<MoviesState>(context);
  //   final userState = Provider.of<UserState>(context);
  //
  //   showDialog<String>(
  //       context: context,
  //       builder: (BuildContext context1) => AlertDialog(
  //             backgroundColor: Theme.of(context).primaryColor,
  //             contentTextStyle: Theme.of(context).textTheme.headline5,
  //             content: Container(
  //                 height: 100,
  //                 margin: EdgeInsets.all(0),
  //                 child: Form(
  //                   key: _formKey,
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                     children: [
  //                       Text(
  //                         'Enter movies list name:',
  //                         style: Theme.of(context).textTheme.headline2,
  //                       ),
  //                       TextFormField(
  //                         validator: (value) => nameController.text.isNotEmpty
  //                             ? null
  //                             : "Please enter name",
  //                         controller: nameController,
  //                         decoration: InputDecoration(
  //                           contentPadding:
  //                               EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
  //                         ),
  //                       )
  //                     ],
  //                   ),
  //                 )),
  //             actions: [
  //               MButton(
  //                 active: true,
  //                 text: 'Add',
  //                 parentContext: context,
  //                 onPressedCallback: () {
  //                   if (_formKey.currentState != null &&
  //                       _formKey.currentState.validate()) {
  //                     var order = moviesState.moviesLists
  //                         .where((element) =>
  //                             element.movieListType == MovieListType.personal)
  //                         .length;
  //
  //                     moviesState.moviesLists.add(new MoviesList(
  //                         name: nameController.text,
  //                         movieListType: MovieListType.personal,
  //                         order: order));
  //
  //                     serviceAgent.createUserMoviesList(
  //                         userState.userId, nameController.text, order);
  //
  //                     Navigator.of(context1).pop();
  //                   }
  //                 },
  //               ),
  //               SizedBox(
  //                 width: 10,
  //               ),
  //               MButton(
  //                 active: true,
  //                 text: 'Cancel',
  //                 parentContext: context,
  //                 onPressedCallback: () => Navigator.of(context1).pop(),
  //               )
  //             ],
  //           ));
  // }

  @override
  Widget build(BuildContext context) {
    final moviesState = Provider.of<MoviesState>(context);
    final userState = Provider.of<UserState>(context);

    // final headingRow = AppBar(
    //   title: TabBar(
    //     controller: tabController,
    //     indicatorColor: Theme.of(context).accentColor,
    //     labelColor: Theme.of(context).accentColor,
    //     unselectedLabelColor: Theme.of(context).hintColor,
    //     tabs: [
    //       Tab(
    //           child: Row(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: <Widget>[
    //           Icon(FontAwesome5.imdb),
    //           SizedBox(
    //             width: 7,
    //           ),
    //           Text(
    //             'External',
    //             style: TextStyle(
    //               fontSize: 18,
    //               fontWeight: FontWeight.w500,
    //             ),
    //           )
    //         ],
    //       )),
    //       Tab(
    //           child: Row(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: <Widget>[
    //           Icon(Icons.person),
    //           SizedBox(
    //             width: 5,
    //           ),
    //           Text(
    //             'Personal',
    //             style: TextStyle(
    //               fontSize: 18,
    //               fontWeight: FontWeight.w500,
    //             ),
    //           )
    //         ],
    //       )),
    //     ],
    //   ),
    // );

    final headingField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.format_list_bulleted,
              size: 25,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Movies Lists',
              style: Theme.of(context).textTheme.headline5,
            )
          ],
        ),
      ],
    );

    return WillPopScope(
        onWillPop: () {
          Navigator.of(context).pop();

          userState.shouldRequestReview = true;
          return;
        },
        // child: Scaffold(
        //     backgroundColor: Theme.of(context).primaryColor,
        //     appBar: headingRow,
        //     body: Container(
        //       color: Theme.of(context).primaryColor,
        //       child: TabBarView(
        //         controller: tabController,
        //         children: [
        //           SingleChildScrollView(
        //               child: Container(
        //                   padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
        //                   color: Theme.of(context).primaryColor,
        //                   child: Column(
        //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //                     children: <Widget>[
        //                       if (moviesState.moviesLists.length == 0)
        //                         SizedBox(
        //                           height: 40,
        //                         ),
        //                       if (moviesState.moviesLists.length == 0)
        //                         Center(child: CircularProgressIndicator()),
        //                       if (moviesState.moviesLists.length > 0)
        //                         for (int i = 0;
        //                             i <
        //                                 moviesState.moviesLists
        //                                     .where((element) =>
        //                                         element.movieListType ==
        //                                         MovieListType.external)
        //                                     .length;
        //                             i++)
        //                           getMovieListWidget(i, MovieListType.external),
        //                     ],
        //                   ))),
        //           Stack(
        //             children: [
        //               SingleChildScrollView(
        //                   child: Container(
        //                       padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
        //                       color: Theme.of(context).primaryColor,
        //                       child: Column(
        //                         mainAxisAlignment:
        //                             MainAxisAlignment.spaceBetween,
        //                         children: <Widget>[
        //                           if (moviesState.moviesLists.length == 0)
        //                             SizedBox(
        //                               height: 40,
        //                             ),
        //                           if (moviesState.moviesLists.length == 0)
        //                             Center(child: CircularProgressIndicator()),
        //                           if (moviesState.moviesLists.length > 0)
        //                             for (int i = 0;
        //                                 i <
        //                                     moviesState.moviesLists
        //                                         .where((element) =>
        //                                             element.movieListType ==
        //                                             MovieListType.personal)
        //                                         .length;
        //                                 i++)
        //                               getMovieListWidget(
        //                                   i, MovieListType.personal),
        //                         ],
        //                       ))),
        //               Align(
        //                   alignment: Alignment(0.83, 0.92),
        //                   child: Container(
        //                       height: 60.0,
        //                       width: 60.0,
        //                       child: FittedBox(
        //                         child: FloatingActionButton(
        //                           onPressed: () {
        //                             addNewList();
        //                           },
        //                           child: const Icon(
        //                             Icons.add,
        //                             size: 35,
        //                           ),
        //                           backgroundColor:
        //                               Theme.of(context).accentColor,
        //                           foregroundColor:
        //                               Theme.of(context).primaryColor,
        //                         ),
        //                       )))
        //             ],
        //           )
        //         ],
        //       ),
        //     ))
      child: Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          appBar: AppBar(
            title: headingField,
          ),
          body: SingleChildScrollView(child: Container(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
              color: Theme.of(context).primaryColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (moviesState.moviesLists.length == 0)
                    SizedBox(height: 40,),
                  if (moviesState.moviesLists.length == 0)
                    Center(child: CircularProgressIndicator()),
                  if (moviesState.moviesLists.length > 0)
                    for (int i = 0; i < moviesState.moviesLists.length; i++)
                      getMovieListWidget(i),
                ],
              )))
      )
    );

  }
}
