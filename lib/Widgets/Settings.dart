import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';

class Settings extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return  Hero(
            tag: 'settings',
            child: Material(child: Container(
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    padding: EdgeInsets.all(20),
                    color: Theme.of(context).primaryColor,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                    Icon(Icons.settings, size: 30,),
                                    SizedBox(
                                        width: 10,
                                    ),
                                    Text('Settings', style: MTextStyles.BodyText,)
                                ],
                            ),
                            RaisedButton(
                                child: Text('Close'),
                                onPressed: () => Navigator.of(context).pop(),
                            )
                        ],
                    )
            ))
    );
  }
}