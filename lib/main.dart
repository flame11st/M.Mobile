import 'package:flutter/material.dart';
import 'package:mmobile/Variables/Variables.dart';
import 'package:provider/provider.dart';
import 'Widgets/MHome.dart';
import 'Widgets/MState.dart';


void main() {
    runApp(
        ChangeNotifierProvider(
            builder: (context) => MState(),
            child: MaterialApp(
                title: 'MovieDiary',
                home: MHome(),
        ))
    );
}