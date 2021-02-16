

import 'package:flutter/cupertino.dart';
import 'package:stripes_app/Enums/CurrentState.dart';

class BaseModel extends ChangeNotifier {
  CurrentState _state = CurrentState.Waiting;

  CurrentState get state => _state;

  void setState(CurrentState viewState) {
    _state = viewState;
    notifyListeners();
  }

}