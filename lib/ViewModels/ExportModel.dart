import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:stripes_app/Enums/CurrentState.dart';
import 'package:stripes_app/Models/QuestionData.dart';
import 'package:stripes_app/ViewModels/BaseModel.dart';
import 'package:stripes_app/ViewModels/UserData.dart';
import 'package:csv/csv.dart';

class ExportModel extends BaseModel {
  String _csvData;

  List<List<dynamic>> _listCsv;

  List<String> orderedCSVKeys = [
    "Date",//0
    "Data Type",//1
    "Sub Type",//2
    "Description",//3
    "Question",//4
    "Severity",//5
    "Location",//6
    "Height",//7
    "Weight",//8
    "BMI"//9
  ];

  String _currentName;

  init(UserData data, BuildContext context) {
    setState(CurrentState.Waiting);
    User current = data.getCurrent();
    _currentName = current.username;
    List<LinkedHashMap> csvMap = [];
    for (Stamped data in current.sortedStamps()) {
      LinkedHashMap dict = LinkedHashMap<String, String>();
      final dateString = timeString(data, context);
      dict[orderedCSVKeys[0]] = dateString;
      if (data is SymptomData) {
        SymptomData symptom = data;
        final String type = "Symptom";
        final String subType = symptom.type;
        for(Response res in symptom.responses) {
          LinkedHashMap sub = LinkedHashMap<String, String>();
          sub[orderedCSVKeys[0]] = dateString;
          sub[orderedCSVKeys[1]] = type;
          sub[orderedCSVKeys[2]] = subType;
          sub[orderedCSVKeys[4]] = res.question.text;
          sub[orderedCSVKeys[5]] = res.severity != null ? "${res.severity}" : null;
          sub[orderedCSVKeys[6]] = res.location;
          csvMap.add(sub);
        }
      } else if (data is LifestyleData) {
        LifestyleData lifestyle = data;
        dict[orderedCSVKeys[1]] = "Lifestyle";
        dict[orderedCSVKeys[2]] = lifestyle.type;
        String descString = "";
        for(String desc in lifestyle.description){
          descString += "$desc, ";
        }
        dict[orderedCSVKeys[3]] = descString.substring(0, descString.length-1);
        csvMap.add(dict);

      } else if (data is BMIData) {
        BMIData bmi = data;
        dict[orderedCSVKeys[1]] = "BMI";
        dict[orderedCSVKeys[7]] = "${bmi.feet}'${bmi.inches}";
        dict[orderedCSVKeys[8]] = "${bmi.pounds}";
        dict[orderedCSVKeys[9]] = "${bmi.bmi()}";
        csvMap.add(dict);
      } else if (data is TestData) {
        TestData test = data;
        dict[orderedCSVKeys[1]] = "Test";
        dict[orderedCSVKeys[2]] = test.type;
        csvMap.add(dict);
      }
    }

    _csvData = "";

    for(String header in orderedCSVKeys) {
      _csvData+="$header,";
    }
    _csvData = _csvData.substring(0, _csvData.length-1);
    _csvData+="\r\n";
    for(LinkedHashMap data in csvMap) {
      for(String type in orderedCSVKeys) {
        if(data[type] == null || (data[type] as String).isEmpty)
          _csvData+="N/A,";
        else
          _csvData+="${data[type]},";
      }
      _csvData = _csvData.substring(0, _csvData.length-1);
      _csvData+="\r\n";
    }
    _listCsv = CsvToListConverter().convert(_csvData);
    setState(CurrentState.Complete);
  }

  List<List<dynamic>> get listCsv => _listCsv;
  
  String get csvData => _csvData;

  String get currentName => _currentName;
  
}
