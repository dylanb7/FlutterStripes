
import 'package:stripes_app/ViewModels/UserData.dart';

class Question {
  String id;
  String text;
  String type;
  bool hasSeverity;
  bool hasLocation;

  Question(this.id, this.text, this.type, this.hasSeverity, this.hasLocation);

  String toString() {
    return "$id";
  }

}

class Response {
  Question question;
  double severity;
  String location;

  Response(this.question, {this.severity, this.location});

  Response.fromString(String response) {
    List<String> res = response.split("|");
    question = fromString(res[0]);
    severity = res[1] == "null" ? null : double.parse(res[1]);
    location = res[2];
  }

  Question fromString(String s) {

    return idToQuestion[s];
  }

  String toString() {
    return "${question.toString()}|$severity|$location";
  }

}

Map<String, Question> idToQuestion = {
  "1": Question("1", "Abdominal Pain", SymptomType.pain, true, true),
  "2" : Question("2", "Nausea", SymptomType.reflux, true, false),
  "3" : Question("3", "Severe gastrointestinal pain lasting 2 hours or longer that interrupts participation in all activities", SymptomType.bm, false, false),
  "4" : Question("4", "Average BM type(1-7)", SymptomType.bm, true, false),
  "6" : Question("6", "Pain with BM", SymptomType.bm, true, false),
  "7" : Question("7", "Rush to the bathroom for BM", SymptomType.bm, true, false),
  "8" : Question("8", "Straining with BM", SymptomType.bm, true, false),
  "9" : Question("9", "Black Tarry BM", SymptomType.bm, false, false),
  "10" : Question("10", "Spit up", SymptomType.reflux, true, false),
  "11" : Question("11", "Regurgitated", SymptomType.reflux, true, false),
  "12" : Question("12", "Experienced Retching", SymptomType.reflux, true, false),
  "13" : Question("13", "Vomiting", SymptomType.reflux, true, false),
  "14" : Question("14", "Tilted head to side and arched back", SymptomType.pain, false, false),
  "15" : Question("15", "Missed activities due to pain", SymptomType.pain, false, false),
  "16" : Question("16", "Missed activities due to reflux", SymptomType.reflux, false, false),
  "17" : Question("17", "Missed activities due to BMs", SymptomType.bm, false, false),
  "18" : Question("18", "Applied pressure to abdomen with hands or furniture", SymptomType.pain, false, true),
  "19" : Question("19", "Choked, gagged coughed or made sound (gurgling) with throat during or after swallowing or meals", SymptomType.reflux, false, false),
  "20" : Question("20", "Refused foods they once ate", SymptomType.reflux, false, false),
  "21" : Question("21", "Sleep Disturbance", SymptomType.other, true, false),
  "22" : Question("22", "Aggressive Behavior", SymptomType.other, true, false),
};

List<Question> questionForType(String type) {
  if(type == SymptomType.bm){
    return [
      idToQuestion["6"],
      idToQuestion["7"],
      idToQuestion["8"],
      idToQuestion["9"],
      idToQuestion["17"],
    ];
  } else if(type == SymptomType.pain) {
    return [
      idToQuestion["1"],
      idToQuestion["3"],
      idToQuestion["14"],
      idToQuestion["15"],
      idToQuestion["18"],
    ];
  } else if(type == SymptomType.reflux) {
    return [
      idToQuestion["2"],
      idToQuestion["10"],
      idToQuestion["11"],
      idToQuestion["12"],
      idToQuestion["13"],
      idToQuestion["16"],
      idToQuestion["19"],
      idToQuestion["20"],
    ];
  } else if(type == SymptomType.other) {
    return [
      idToQuestion["21"],
      idToQuestion["22"],
    ];
  }
  return List();
}