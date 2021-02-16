import 'package:stripes_app/Enums/CurrentState.dart';
import 'package:stripes_app/ViewModels/BaseModel.dart';
import 'package:stripes_app/ViewModels/UserData.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class VisualizeModel extends BaseModel {

  init(UserData data) {
    setState(CurrentState.Waiting);


    setState(CurrentState.Complete);
  }

  setSpan(DateTime span) {

  }

  correlationCoefficient() {

  }

}

class GraphableStamp {

}