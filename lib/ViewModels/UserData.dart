import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stripes_app/Models/QuestionData.dart';

import 'BaseModel.dart';
import 'package:stripes_app/Enums/CurrentState.dart';

DateTime getTime(Stamped ob) {
  return DateTime.fromMillisecondsSinceEpoch(ob.stamp);
}

String getTimeString(int time, BuildContext context) {
  DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
  return "${date.month}/${date.day}/${date.year} at ${TimeOfDay(hour: date.hour, minute: date.minute).format(context)}";
}

String timeString(Stamped time, BuildContext context) {
  DateTime date = getTime(time);
  return "${date.month}/${date.day}/${date.year} at ${TimeOfDay(hour: date.hour, minute: date.minute).format(context)}";
}

class UserData extends BaseModel {
  Map<String, User> users;

  final storeInstance = FirebaseFirestore.instance;

  final authInstance = FirebaseAuth.instance;

  final storageInstance = FirebaseStorage.instance;

  String currentUser;

  final String mainColl = "UserData";

  final String userColl = "users";

  static final UserData userData = UserData._internal();

  UserData._internal() {
    setState(CurrentState.Waiting);
  }

  factory UserData() {
    return userData;
  }

  Future<void> init() async {
    users = Map();
    try {
      await userRef().get().asStream().forEach((element) {
        element.docs.forEach((element) {
          if (element.exists)
            users["${element.get("username")}"] =
                User.fromMap(Map<String, String>.from(element.data()));
        });
      });
      final List<String> userList = List.of(users.keys, growable: false);
      currentUser = userList.isEmpty ? "" : userList.first;
    } catch (e) {}
    for (String user in users.keys) {
      try {
        for (String type in DataType.ordered()) {
          await userRef().doc(user).collection(type).get().catchError((err) {
            print(err.toString());
          }).then((ref) => {
                ref.docs.forEach((element) {
                  if (element.exists)
                    users[user].add(_deserializeData(element.data(), type));
                })
              });
        }
      } catch (e) {
        print(e.toString());
      }
    }
    setState(CurrentState.Complete);
  }

  User getCurrent() =>
      users.containsKey(currentUser) ? users[currentUser] : null;

  List<String> getUsers() => List.of(users.keys, growable: false);

  CollectionReference userRef() => storeInstance
      .collection(mainColl)
      .doc(authInstance.currentUser.uid)
      .collection(userColl);

  Map<String, String> _serializeData(Stamped stamped) {
    Map<String, String> data;
    if (stamped is SymptomData)
      data = SymptomSerializer().serialize(stamped);
    else if (stamped is LifestyleData)
      data = LifestyleSerializer().serialize(stamped);
    else if (stamped is TestData)
      data = TestSerializer().serialize(stamped);
    else
      data = BMISerializer().serialize(stamped);
    return data;
  }

  Stamped _deserializeData(Map<String, dynamic> data, String type) {
    Stamped stamped;
    if (type == DataType.symptom)
      stamped = SymptomSerializer().deserialize(data);
    else if (type == DataType.lifestyle)
      stamped = LifestyleSerializer().deserialize(data);
    else if (type == DataType.test)
      stamped = TestSerializer().deserialize(data);
    else
      stamped = BMISerializer().deserialize(data);
    return stamped;
  }

  Future<bool> addUser(User user) async {
    final String name = user.username;
    if (users.containsKey(name)) return false;
    setState(CurrentState.Waiting);
    try {
      await userRef().doc(name).set(user.toMap());
      users[name] = user;
      if (users.length == 1) currentUser = name;
      setState(CurrentState.Complete);
      return true;
    } catch (e) {
      setState(CurrentState.Complete);
      return false;
    }
  }

  bool setUser(String username) {
    if (users.containsKey(username) && username != currentUser) {
      currentUser = username;
      setState(CurrentState.Complete);
      return true;
    }
    return false;
  }

  Future<bool> editUser(String username, Map<String, String> edits) async {
    setState(CurrentState.Waiting);
    if (!users.containsKey(username)) return false;
    try {
      await userRef().doc(username).update(edits);
      await userRef().doc(username).get().then((value) => users[username] = User.fromMap(value.data()));
      setState(CurrentState.Complete);
      return true;
    } catch(e) {
      setState(CurrentState.Complete);
      return false;
    }


  }

  Future<bool> removeUser(String username) async {
    if (!users.containsKey(username)) return false;
    setState(CurrentState.Waiting);
    try {
      await userRef().doc(username).delete();
      if (username == currentUser)
        currentUser =
            users.keys.singleWhere((element) => element != username) ?? "";
      users.remove(username);
      setState(CurrentState.Complete);
      return true;
    } catch (e) {
      setState(CurrentState.Complete);
      return false;
    }
  }

  List<T> get<T extends Stamped>() {
    final User current = getCurrent();
    if (current == null) return List();
    if (T == SymptomData) return current.symptomData as List<T>;
    if (T == LifestyleData) return current.lifestyleData as List<T>;
    if (T == BMIData) return current.bmiData as List<T>;
    if (T == TestData) return current.testData as List<T>;
    return List();
  }

  Future<bool> add(Stamped data) async {
    final User current = getCurrent();
    if (current == null) return false;
    setState(CurrentState.Waiting);
    final String _serializedStamp =
        SymptomSerializer()._serializeStamp(data.stamp);
    try {
      if (data is SymptomData) {
        String url;
        if (data.image != null) {
          Reference ref = storageInstance
              .ref("users")
              .child(authInstance.currentUser.uid)
              .child(_serializedStamp);
          await ref.putData(data.image);
          url = await ref.getDownloadURL();
          data.image = null;
        }
        data.url = url;
        await userRef()
            .doc(currentUser)
            .collection(DataType.symptom)
            .doc(_serializedStamp)
            .set(_serializeData(data));
        current.add<SymptomData>(data);
      } else if (data is LifestyleData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.lifestyle)
            .doc(_serializedStamp)
            .set(_serializeData(data));
        current.add<LifestyleData>(data);
      } else if (data is BMIData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.bmi)
            .doc(_serializedStamp)
            .set(_serializeData(data));
        current.add<BMIData>(data);
      } else if (data is TestData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.test)
            .doc(_serializedStamp)
            .set(_serializeData(data));
        current.add<TestData>(data);
      }
      setState(CurrentState.Complete);
      return true;
    } catch (e) {
      setState(CurrentState.Complete);
      return false;
    }
  }

  Future<bool> addMultiple(List<Stamped> stamps) async {
    final User current = getCurrent();
    if (current == null) return false;
    setState(CurrentState.Waiting);
    final WriteBatch batch = storeInstance.batch();
    for (Stamped data in stamps) {
      final String _serializedStamp =
          SymptomSerializer()._serializeStamp(data.stamp);
      if (data is SymptomData) {
        String url;
        if (data.image != null) {
          Reference ref = storageInstance
              .ref("users")
              .child(authInstance.currentUser.uid)
              .child(_serializedStamp);
          await ref.putData(data.image);
          url = await ref.getDownloadURL();
          data.image = null;
        }
        data.url = url;
        batch.set(
            userRef()
                .doc(currentUser)
                .collection(DataType.symptom)
                .doc(_serializedStamp),
            _serializeData(data));
      } else if (data is LifestyleData)
        batch.set(
            userRef()
                .doc(currentUser)
                .collection(DataType.lifestyle)
                .doc(_serializedStamp),
            _serializeData(data));
      else if (data is BMIData)
        batch.set(
            userRef()
                .doc(currentUser)
                .collection(DataType.bmi)
                .doc(_serializedStamp),
            _serializeData(data));
      else if (data is TestData)
        batch.set(
            userRef()
                .doc(currentUser)
                .collection(DataType.test)
                .doc(_serializedStamp),
            _serializeData(data));
    }
    try {
      await batch.commit();
    } catch (e) {
      setState(CurrentState.Complete);
      return false;
    }
    for (Stamped data in stamps) {
      if (data is SymptomData)
        current.add<SymptomData>(data);
      else if (data is LifestyleData)
        current.add<LifestyleData>(data);
      else if (data is BMIData)
        current.add<BMIData>(data);
      else if (data is TestData) current.add<TestData>(data);
    }
    setState(CurrentState.Complete);
    return true;
  }

  Future<bool> remove<T extends Stamped>(int stamp) async {
    final User current = getCurrent();
    if (current == null) return false;
    setState(CurrentState.Waiting);
    final String _serializedStamp = SymptomSerializer()._serializeStamp(stamp);
    try {
      if (T == BMIData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.bmi)
            .doc(_serializedStamp)
            .delete();
        current.bmiData.retainWhere((element) => element.stamp != stamp);
      } else if (T == SymptomData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.symptom)
            .doc(_serializedStamp)
            .delete();
        current.symptomData.retainWhere((element) => element.stamp != stamp);
      } else if (T == LifestyleData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.lifestyle)
            .doc(_serializedStamp)
            .delete();
        current.lifestyleData.retainWhere((element) => element.stamp != stamp);
      } else if (T == TestData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.test)
            .doc(_serializedStamp)
            .delete();
        current.testData.retainWhere((element) => element.stamp != stamp);
      }
      setState(CurrentState.Complete);
      return true;
    } catch (e) {
      setState(CurrentState.Complete);
      return false;
    }
  }

  Future<bool> edit(Stamped stamped, Map<String, String> changes) async {
    final User current = getCurrent();
    if (current == null) return false;
    setState(CurrentState.Waiting);
    final String _serializedStamp =
        SymptomSerializer()._serializeStamp(stamped.stamp);
    try {
      if (stamped is BMIData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.bmi)
            .doc(_serializedStamp)
            .update(changes);
        await userRef()
            .doc(currentUser)
            .collection(DataType.bmi)
            .doc(_serializedStamp)
            .get()
            .then((value) => {
                  current.bmiData[current.bmiData.indexOf(stamped)] =
                      BMISerializer().deserialize(value.data())
                });
      } else if (stamped is SymptomData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.symptom)
            .doc(_serializedStamp)
            .update(changes);
        await userRef()
            .doc(currentUser)
            .collection(DataType.symptom)
            .doc(_serializedStamp)
            .get()
            .then((value) => {
                  current.symptomData[current.symptomData.indexOf(stamped)] =
                      SymptomSerializer().deserialize(value.data())
                });
      } else if (stamped is LifestyleData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.lifestyle)
            .doc(_serializedStamp)
            .update(changes);
        await userRef()
            .doc(currentUser)
            .collection(DataType.lifestyle)
            .doc(_serializedStamp)
            .get()
            .then((value) => {
                  current.lifestyleData[
                          current.lifestyleData.indexOf(stamped)] =
                      LifestyleSerializer().deserialize(value.data())
                });
      } else if (stamped is TestData) {
        await userRef()
            .doc(currentUser)
            .collection(DataType.test)
            .doc(_serializedStamp)
            .update(changes);
        await userRef()
            .doc(currentUser)
            .collection(DataType.test)
            .doc(_serializedStamp)
            .get()
            .then((value) => {
                  current.testData[current.testData.indexOf(stamped)] =
                      TestSerializer().deserialize(value.data())
                });
      }
      setState(CurrentState.Complete);
      return true;
    } catch (e) {
      setState(CurrentState.Complete);
      return false;
    }
  }

  Future<bool> removeMultiple<T extends Stamped>(List<int> stamps) async {
    final User current = getCurrent();
    if (current == null) return false;
    setState(CurrentState.Waiting);
    final WriteBatch batch = storeInstance.batch();
    for (int stamp in stamps) {
      final String _serializedStamp =
          SymptomSerializer()._serializeStamp(stamp);
      if (T == BMIData)
        batch.delete(userRef()
            .doc(currentUser)
            .collection(DataType.bmi)
            .doc(_serializedStamp));
      else if (T == SymptomData)
        batch.delete(userRef()
            .doc(currentUser)
            .collection(DataType.symptom)
            .doc(_serializedStamp));
      else if (T == LifestyleData)
        batch.delete(userRef()
            .doc(currentUser)
            .collection(DataType.lifestyle)
            .doc(_serializedStamp));
      else if (T == TestData)
        batch.delete(userRef()
            .doc(currentUser)
            .collection(DataType.test)
            .doc(_serializedStamp));
    }
    try {
      await batch.commit();
    } catch (e) {
      setState(CurrentState.Complete);
      return false;
    }
    for (int stamp in stamps) {
      if (T == BMIData)
        current.bmiData.retainWhere((element) => element.stamp != stamp);
      else if (T == SymptomData)
        current.symptomData.retainWhere((element) => element.stamp != stamp);
      else if (T == LifestyleData)
        current.lifestyleData.retainWhere((element) => element.stamp != stamp);
      else if (T == TestData)
        current.testData.retainWhere((element) => element.stamp != stamp);
    }
    setState(CurrentState.Complete);
    return true;
  }

  List<Stamped> getSorted(List<String> types) {
    final User current = getCurrent();
    if (current == null) return List();
    List<Stamped> ret = [];
    if (types.contains(DataType.symptom)) ret.addAll(current.symptomData);
    if (types.contains(DataType.lifestyle)) ret.addAll(current.lifestyleData);
    if (types.contains(DataType.test)) ret.addAll(current.testData);
    if (types.contains(DataType.bmi)) ret.addAll(current.bmiData);
    ret.sort((Stamped a, Stamped b) => a.stamp - b.stamp);
    return ret;
  }
}

class User {
  String username;
  String name;
  String gender;
  int dob;
  List<SymptomData> _symptomData = [];
  List<LifestyleData> _lifestyleData = [];
  List<TestData> _testData = [];
  List<BMIData> _bmiData = [];

  User(this.username, this.name, this.gender, this.dob);

  User.fromMap(Map<String, String> map) {
    username = map["username"];
    name = map["name"];
    gender = map["gender"];
    dob = int.parse(map["dob"]);
  }

  Map<String, String> toMap() {
    return {
      "username": username,
      "name": name,
      "gender": gender,
      "dob": "$dob"
    };
  }

  List<SymptomData> get symptomData => _symptomData;

  List<LifestyleData> get lifestyleData => _lifestyleData;

  List<TestData> get testData => _testData;

  List<BMIData> get bmiData => _bmiData;

  void add<T extends Stamped>(T data) {
    if (data is SymptomData)
      _symptomData.insert(0, data);
    else if (data is LifestyleData)
      _lifestyleData.insert(0, data);
    else if (data is BMIData)
      _bmiData.insert(0, data);
    else if (data is TestData) _testData.insert(0, data);
  }

  void remove<T extends Stamped>(int stamp) {
    switch (T) {
      case SymptomData:
        _symptomData.retainWhere((element) => element.stamp != stamp);
        break;
      case LifestyleData:
        _lifestyleData.retainWhere((element) => element.stamp != stamp);
        break;
      case BMIData:
        _bmiData.retainWhere((element) => element.stamp != stamp);
        break;
      case TestData:
        _testData.retainWhere((element) => element.stamp != stamp);
        break;
    }
  }

  List<Stamped> sortedStamps() {
    List<Stamped> stamps = [];
    stamps.addAll(symptomData);
    stamps.addAll(lifestyleData);
    stamps.addAll(bmiData);
    stamps.addAll(testData);
    stamps.sort((a, b) {
      return -a.stamp.compareTo(b.stamp);
    });
    return stamps;
  }
}

abstract class Stamped {
  // ignore: missing_return
  int stamp;
}

class DataType {
  static final String symptom = "Symptom";
  static final String lifestyle = "Lifestyle Changes";
  static final String test = "Test";
  static final String bmi = "BMI";

  static List<String> ordered() => [symptom, lifestyle, test, bmi];
}

class SymptomType {
  static final String bm = "Bowel Movement";
  static final String reflux = "Reflux";
  static final String pain = "Pain";
  static final String other = "Other";

  static List<String> ordered() => [bm, reflux, pain, other];
}

class SymptomData implements Stamped {
  @override
  int stamp;
  final String type;
  String url;
  final List<Response> responses;
  final String description;
  Uint8List image;

  SymptomData(this.stamp, this.type, this.responses, this.description, this.url,
      {this.image});

  @override
  String toString() {
    return super.toString();
  }
}

class SymptomSerializer extends Serializer<SymptomData> {
  String get typeKey => "symptomType";

  String get responsesKey => "responses";

  String get descriptionKey => "description";

  String get imageKey => "image";

  @override
  SymptomData deserialize(Map<String, dynamic> data) {
    bool hasImage = data[imageKey] != "N/A";
    return SymptomData(
        _deserializeStamp("${data[stampKey]}"),
        "${data[typeKey]}",
        "${data[responsesKey]}"
            .split("%")
            .map((res) => Response.fromString(res))
            .toList(),
        "${data[descriptionKey]}",
        hasImage ? "${data[imageKey]}" : null);
  }

  @override
  Map<String, String> serialize(SymptomData data) {
    return {
      stampKey: _serializeStamped(data),
      typeKey: data.type,
      responsesKey: serializeResponses(data.responses),
      descriptionKey: data.description,
      imageKey: data.url.isEmpty ? "N/A" : data.url
    };
  }

  String serializeResponses(List<Response> responses) {
    String res = "";
    for (Response response in responses) {
      res += "$response%";
    }
    return res.substring(0, res.length - 1);
  }
}

class LifestyleType {
  static final String dietaryChange = "Dietary Change";
  static final String moved = "Moved";
  static final String psychiatricHospitalization =
      "Psychiatric Hospitalization";
  static final String medicalIntervention = "Medical Intervention";

  static List<String> ordered() =>
      [dietaryChange, moved, psychiatricHospitalization, medicalIntervention];
}

class LifestyleData implements Stamped {
  @override
  int stamp;
  final String type;
  final List<String> description;

  LifestyleData(this.stamp, this.type, this.description);

  @override
  String toString() {
    return super.toString();
  }
}

class LifestyleSerializer extends Serializer<LifestyleData> {
  String get typeKey => "lifestyleType";

  String get descriptionKey => "description";

  @override
  LifestyleData deserialize(Map<String, dynamic> data) {
    return LifestyleData(_deserializeStamp(data[stampKey]), data[typeKey],
        data[descriptionKey].split(","));
  }

  @override
  Map<String, String> serialize(LifestyleData data) {
    return {
      stampKey: _serializeStamped(data),
      typeKey: data.type,
      descriptionKey: joined(data.description)
    };
  }

  String joined(List<String> desc) {
    String ret = "";
    for (String piece in desc) {
      ret += "$piece,";
    }
    return ret.substring(0, ret.length - 1);
  }
}

class BMIData implements Stamped {
  @override
  int stamp;
  final int pounds;
  final int feet;
  final int inches;

  BMIData(this.stamp, this.pounds, this.feet, this.inches);

  double bmi() {
    final double kilos = pounds.toDouble() * 0.453592;
    final double totalInches = ((feet * 12) + inches.toDouble());
    final double meters = (totalInches == 0 ? 1.0 : totalInches) * 0.0254;
    return ((kilos / (meters * meters)) * 10).roundToDouble() / 10;
  }

  @override
  String toString() {
    return super.toString();
  }
}

class BMISerializer extends Serializer<BMIData> {
  String get poundKey => "pounds";

  String get feetKey => "feet";

  String get inchesKey => "inches";

  @override
  BMIData deserialize(Map<String, dynamic> data) {
    return BMIData(_deserializeStamp(data[stampKey]), int.parse(data[poundKey]),
        int.parse(data[feetKey]), int.parse(data[inchesKey]));
  }

  @override
  Map<String, String> serialize(BMIData data) {
    return {
      stampKey: _serializeStamped(data),
      poundKey: "${data.pounds}",
      feetKey: "${data.feet}",
      inchesKey: "${data.inches}"
    };
  }
}

class TestType {
  static final String blueDye = "Blue Dye";

  static List<String> ordered() => [blueDye];
}

class TestData implements Stamped {
  @override
  int stamp;
  final firstInstanceStamp;
  final int endStamp;
  final String type;
  final String description;

  TestData(this.stamp, this.firstInstanceStamp, this.endStamp, this.type,
      this.description);

  @override
  String toString() {
    return super.toString();
  }
}

class TestSerializer extends Serializer<TestData> {
  @override
  TestData deserialize(Map<String, dynamic> data) {
    // TODO: implement deserialize
    throw UnimplementedError();
  }

  @override
  Map<String, String> serialize(TestData data) {
    // TODO: implement serialize
    throw UnimplementedError();
  }
}

abstract class Serializer<T extends Stamped> {
  final String stampKey = "stamp";

  Map<String, String> serialize(T data);

  T deserialize(Map<String, String> data);

  String _serializeImage(Uint8List provider) {
    return base64Encode(provider);
  }

  Uint8List _deserializeImage(String image) {
    return base64Decode(image);
  }

  String _serializeStamped(T stamped) {
    return _serializeStamp(stamped.stamp);
  }

  String _serializeStamp(int stamp) {
    return "$stamp";
  }

  int _deserializeStamp(String serialized) {
    return int.parse(serialized);
  }
}
