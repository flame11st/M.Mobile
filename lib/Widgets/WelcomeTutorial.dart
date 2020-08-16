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
  int maxIndex = 4;

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
      children: <Widget>[
        Text(
          'MovieDiary was created to help you simply manage your '
          'watchlist movies and also store the history of viewed movies.',
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
                'To add new Movie or TV Show to your watchlist tap on the Add icon which placed on bottom bar:',
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
                    image: AssetImage("Assets/AddButton.png"),
                  )),
              SizedBox(
                height: 20,
              ),
              Text(
                'Then find Movie which you want to watch and tap to "Add to watchlist button"',
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
                    image: AssetImage("Assets/Search.png"),
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
                    image: AssetImage("Assets/Watchlist.png"),
                  ))
            ],
          ),
          Column(
            children: <Widget>[
              Text(
                'After watching movie you can rate it. '
                '\nTap to "More" button on the right side of Movie and choose rate',
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
                    image: AssetImage("Assets/MovieRate.png"),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Filters button placed at the bottom left corner',
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
              image: AssetImage("Assets/FilterButton.png"),
            )),
        SizedBox(
          height: 10,
        ),
        Text(
          'You can filter Watchlist items by type.'
          '\nViewed movies you can also filter by rate',
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
              image: AssetImage("Assets/Filters.png"),
            )),
      ],
    ));

    final fifthStep = Container(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'You can expand Movie by tap it:',
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
              image: AssetImage("Assets/ExpandedMovie.png"),
            )),
        SizedBox(
          height: 10,
        ),
        Text(
          'To compress movie you can tap anywhere on it.',
          style: Theme.of(context).textTheme.headline5,
        ),
      ],
    ));

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
        child: Stepper(
          type: StepperType.vertical,
          steps: [
            Step(
              isActive: currentIndex == 0,
              state: currentIndex == 0 ? StepState.editing : StepState.complete,
              title: Text(
                'Welcome to MovieDiary!',
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
                'Add movies to Watchlist',
                style: Theme.of(context).textTheme.headline2,
              ),
              content: secondStep,
            ),
            Step(
                title: Text(
                  'Rate movie after watching',
                  style: Theme.of(context).textTheme.headline2,
                ),
                content: thirdStep,
                state: currentIndex == 2
                    ? StepState.editing
                    : currentIndex > 2 ? StepState.complete : StepState.indexed,
                isActive: currentIndex == 2),
            Step(
                isActive: currentIndex == 3,
                title: Text(
                  "Filters",
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
                title: Text("Expanded movie", style: Theme.of(context).textTheme.headline2,),
                content: fifthStep,
                state: currentIndex == 4
                    ? StepState.editing
                    : currentIndex > 4 ? StepState.complete : StepState.indexed)
          ],
          currentStep: currentIndex,
          onStepTapped: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          controlsBuilder: (BuildContext context,
                  {VoidCallback onStepContinue, VoidCallback onStepCancel}) =>
              Container(
            margin: EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
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
        ),
      ),
    );
  }
}
