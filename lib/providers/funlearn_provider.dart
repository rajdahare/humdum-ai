import 'package:flutter/material.dart';

class FunLearnProvider extends ChangeNotifier {
  String _subject = 'Math';
  int _score = 0;

  String get subject => _subject;
  int get score => _score;

  void setSubject(String s) {
    _subject = s;
    notifyListeners();
  }

  void addScore(int delta) {
    _score += delta;
    notifyListeners();
  }
}


