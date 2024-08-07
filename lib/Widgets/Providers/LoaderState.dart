import 'package:flutter/material.dart';

class LoaderState with ChangeNotifier {
    bool isLoaderVisible = true;

    setIsLoaderVisible(bool value) async {
      if (isLoaderVisible == value) return;

      await new Future.delayed(const Duration(milliseconds: 1));

      isLoaderVisible = value;

      notifyListeners();
    }
}