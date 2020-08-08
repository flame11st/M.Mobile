import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';

class MTextField extends StatelessWidget {
  final controller;
  final text;

  MTextField({this.controller, this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 15),
            child: Text(
              text,
              style: MTextStyles.Title,
            ),
          ),
          Container(
              margin: EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.25),
                    offset: Offset(-4.0, -4.0),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    offset: Offset(6.0, 6.0),
                    blurRadius: 8,
                  ),
                ],
                borderRadius: BorderRadius.circular(32.0),
                color: Theme.of(context).primaryColor,
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0))),
              ))
        ]);
  }
}
