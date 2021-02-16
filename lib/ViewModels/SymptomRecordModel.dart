import 'dart:typed_data';

import 'package:stripes_app/Enums/CurrentState.dart';
import 'package:stripes_app/Models/QuestionData.dart';
import 'package:stripes_app/ViewModels/BaseModel.dart';

import 'UserData.dart';

class SymptomRecordModel extends BaseModel {
  String _type = "";

  String _description = "";

  List<Response> _responses = [];

  Uint8List _image;

  bool _onSubmit = false;

  bool get onSubmit => _onSubmit;

  readyForSubmit() {
    _onSubmit = true;
    setState(CurrentState.Complete);
  }

  setType(String type) {
    _type = type;
  }

  setImage(Uint8List image){

  }

  addResponse(Response response) {
    _responses.add(response);
  }

  addResponses(List<Response> responses) {
    _responses.addAll(responses);
  }

  setDescription(String description) {
    _description = description;
  }

  List<SymptomData> submit(
      int _entries, DateTime _endDate, DateTime _startDate) {
    if (_entries == 1) {
      SymptomData data = SymptomData(
          _endDate.millisecondsSinceEpoch, _type, _responses, _description, "", image: _image);
      return [data];
    }
    List<SymptomData> allData = [];
    final int diff = _endDate.difference(_startDate).inMilliseconds;
    final Duration _duration = Duration(
        milliseconds:
            (diff.roundToDouble() /(_entries-1).roundToDouble()).round());
    for (int i = 0; i < _entries; i++) {
      SymptomData data = SymptomData(
          _startDate.millisecondsSinceEpoch + (_duration.inMilliseconds * i),
          _type,
          _responses,
          _description, "", image: _image);
      allData.add(data);
    }
    return allData;
  }
}
