import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Providers/UserState.dart';

class LoadingAnimation extends StatelessWidget {
  getText(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    var result = userState.androidVersion == 1 || userState.androidVersion > 7
        ? '𝓜𝓸𝓿𝓲𝓮𝓓𝓲𝓪𝓻𝔂'
        : userState.androidVersion == 0 ? '𝓜𝓸𝓿𝓲𝓮𝓓𝓲𝓪𝓻𝔂' : 'MovieDiary';
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage("Assets/mdIcon_V_with_effect.png"), width: 130,),
            Text(
              getText(context),
              style: TextStyle(fontSize: 40, color: Theme.of(context).accentColor),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 50,
        height: 50,
        color: Theme.of(context).primaryColor,
        child: CircularProgressIndicator(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
