import 'package:flutter/material.dart';

class MTextField extends StatefulWidget{
    @override
    State<StatefulWidget> createState() {
        return MTextFieldState();
    }
}

class MTextFieldState extends State<MTextField> {
    @override
    Widget build(BuildContext context) {
        return TextField(
            decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
              hintText: "hint",
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
        );
    }
}

