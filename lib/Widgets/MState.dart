import 'package:flutter/material.dart';

class MState with ChangeNotifier {
    bool isUserAuthorized = false;

    void setIsUserAuthorized(bool value) {
        isUserAuthorized = value;
        notifyListeners();
    }
}