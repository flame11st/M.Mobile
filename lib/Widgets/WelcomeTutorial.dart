import 'package:flutter/material.dart';
import 'package:mmobile/Widgets/Shared/MButton.dart';
import 'package:provider/provider.dart';

import 'Providers/UserState.dart';

class WelcomeTutorial extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new WelcomeTutorialState();
  }
}

class WelcomeTutorialState extends State<WelcomeTutorial> {
  int currentIndex = 0;
  int maxIndex = 5;

  next() {
    if (currentIndex < maxIndex) {
      setState(() {
        currentIndex++;
      });
    }
  }

  previous() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  finish() {
    final userState = Provider.of<UserState>(context);

    userState.changeShowTutorialField(false);
  }

  @override
  Widget build(BuildContext context) {
    var buttonWidth = (MediaQuery.of(context).size.width / 2) - 80;
    var buttonHeight = 40.0;

    final firstStep = Container(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Text(
          'Welcome to MovieDiary!',
          style: Theme.of(context).textTheme.headline2,
        ),
        SizedBox(
          height: 20,
        ),
        Text(
          'MovieDiary was created to help you manage your '
          'Watchlist movies and also store the history of viewed movies.',
          style: Theme.of(context).textTheme.headline5,
        ),
        SizedBox(
          height: 20,
        ),
        Text(
          'This is a small tutorial that will'
          ' introduce you to the general functions.',
          style: Theme.of(context).textTheme.headline5,
        )
      ],
    ));

    final secondStep = Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Column(
            children: <Widget>[
              Text(
                'Add movies to Watchlist',
                style: Theme.of(context).textTheme.headline2,
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                'To add new Movie or TV Show to your watchlist please tap on the "Add" button which placed on the bottom bar:',
                style: Theme.of(context).textTheme.headline5,
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          width: 2, color: Theme.of(context).accentColor)),
                  child: Image(
                    image: AssetImage("Assets/bottom_panel.jpg"),
                  )),
              SizedBox(
                height: 20,
              ),
              Text(
                'Then find Movie which you want to watch and tap to "Add to watchlist" button',
                style: Theme.of(context).textTheme.headline5,
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          width: 2, color: Theme.of(context).accentColor)),
                  child: Image(
                    image: AssetImage("Assets/search.jpg"),
//            width: 150,
                  ))
            ],
          ),
        ],
      ),
    );

    final thirdStep = Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            children: <Widget>[
              Text(
                'Rate movie after watching',
                style: Theme.of(context).textTheme.headline2,
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                'The movies added to watchlist placed on the first tab:',
                style: Theme.of(context).textTheme.headline5,
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          width: 2, color: Theme.of(context).accentColor)),
                  child: Image(
                    image: AssetImage("Assets/watchlist_tab.jpg"),
                  ))
            ],
          ),
          Column(
            children: <Widget>[
              SizedBox(
                height: 10,
              ),
              Text(
                'After watching you can rate the movie. '
                '\nTap to "Rate" button on the right side of the Movie and choose rate',
                style: Theme.of(context).textTheme.headline5,
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          width: 2, color: Theme.of(context).accentColor)),
                  child: Image(
                    image: AssetImage("Assets/rate_movie.jpg"),
//            width: 150,
                  )),
            ],
          ),
        ],
      ),
    );

    final fourthStep = Container(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Filters",
          style: Theme.of(context).textTheme.headline2,
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          '"Filters" button placed at the bottom left corner',
          style: Theme.of(context).textTheme.headline5,
        ),
        SizedBox(
          height: 10,
        ),
        Container(
            decoration: BoxDecoration(
                border:
                    Border.all(width: 2, color: Theme.of(context).accentColor)),
            child: Image(
              image: AssetImage("Assets/bottom_panel_filter.jpg"),
            )),
        SizedBox(
          height: 10,
        ),
        Text(
          'You can filter movies by type, rate, genre and viewing date',
          style: Theme.of(context).textTheme.headline5,
        ),
        SizedBox(
          height: 10,
        ),
        Container(
            decoration: BoxDecoration(
                border:
                    Border.all(width: 2, color: Theme.of(context).accentColor)),
            child: Image(
              height: MediaQuery.of(context).size.height - 370,
              image: AssetImage("Assets/filters.jpg"),
            )),
      ],
    ));

    final fifthStep = Container(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text(
          "Expanded movie",
          style: Theme.of(context).textTheme.headline2,
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          'You can expand Movie by tapping on it:',
          style: Theme.of(context).textTheme.headline5,
        ),
        SizedBox(
          height: 10,
        ),
        Container(
            decoration: BoxDecoration(
                border:
                    Border.all(width: 2, color: Theme.of(context).accentColor)),
            child: Image(
              height: MediaQuery.of(context).size.height - 280,
              image: AssetImage("Assets/expanded_movie.jpg"),
            )),
        SizedBox(
          height: 10,
        ),
        Text(
          'To compress movie you can tap anywhere.',
          style: Theme.of(context).textTheme.headline5,
        ),
      ],
    ));

    final sixthStep = Container(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text(
          "All in one",
          style: Theme.of(context).textTheme.headline2,
        ),
        SizedBox(
          height: 10,
        ),
        Container(
            decoration: BoxDecoration(
                border:
                    Border.all(width: 2, color: Theme.of(context).accentColor)),
            child: Image(
              height: MediaQuery.of(context).size.height - 220,
              image: AssetImage("Assets/finalize.jpg"),
            )),
      ],
    ));

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      bottomNavigationBar: Container(
        alignment: Alignment.topCenter,
        height: 50,
        margin: EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            if (currentIndex == 0)
              SizedBox(
                width: buttonWidth,
              ),
            if (currentIndex != 0)
              MButton(
                prependIcon: Icons.arrow_back,
                width: buttonWidth,
                active: true,
                height: buttonHeight,
                text: 'Previous',
                onPressedCallback: () => previous(),
              ),
            if (currentIndex != maxIndex)
              MButton(
                appendIcon: Icons.arrow_forward,
                width: buttonWidth,
                active: true,
                text: 'Next',
                height: buttonHeight,
                onPressedCallback: () => next(),
              ),
            if (currentIndex == maxIndex)
              MButton(
                appendIcon: Icons.flag,
                width: buttonWidth,
                active: true,
                text: 'Finish',
                height: buttonHeight,
                onPressedCallback: () => finish(),
              ),
          ],
        ),
      ),
      body: Container(
        margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
        child: Stepper(
            type: StepperType.horizontal,
            steps: [
              Step(
                isActive: currentIndex == 0,
                state:
                    currentIndex == 0 ? StepState.editing : StepState.complete,
                title: Text(
                  '',
                  style: Theme.of(context).textTheme.headline2,
                ),
                content: firstStep,
              ),
              Step(
                isActive: currentIndex == 1,
                state: currentIndex == 1
                    ? StepState.editing
                    : currentIndex > 1 ? StepState.complete : StepState.indexed,
                title: Text(
                  '',
                  style: Theme.of(context).textTheme.headline2,
                ),
                content: secondStep,
              ),
              Step(
                  title: Text(
                    '',
                    style: Theme.of(context).textTheme.headline2,
                  ),
                  content: thirdStep,
                  state: currentIndex == 2
                      ? StepState.editing
                      : currentIndex > 2
                          ? StepState.complete
                          : StepState.indexed,
                  isActive: currentIndex == 2),
              Step(
                  isActive: currentIndex == 3,
                  title: Text(
                    "",
                    style: Theme.of(context).textTheme.headline2,
                  ),
                  content: fourthStep,
                  state: currentIndex == 3
                      ? StepState.editing
                      : currentIndex > 3
                          ? StepState.complete
                          : StepState.indexed),
              Step(
                  isActive: currentIndex == 4,
                  title: Text(
                    "",
                    style: Theme.of(context).textTheme.headline2,
                  ),
                  content: fifthStep,
                  state: currentIndex == 4
                      ? StepState.editing
                      : currentIndex > 4
                          ? StepState.complete
                          : StepState.indexed),
              Step(
                  isActive: currentIndex == 5,
                  title: Text(
                    "",
                    style: Theme.of(context).textTheme.headline2,
                  ),
                  content: sixthStep,
                  state: currentIndex == 5
                      ? StepState.editing
                      : currentIndex > 5
                      ? StepState.complete
                      : StepState.indexed)
            ],
            currentStep: currentIndex,
            onStepTapped: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            controlsBuilder: (BuildContext context,
                    {VoidCallback onStepContinue, VoidCallback onStepCancel}) =>
                Text("")),
      ),
    );
  }
}
