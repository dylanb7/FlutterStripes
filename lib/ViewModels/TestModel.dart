import 'package:charts_flutter/flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:stripes_app/Enums/CurrentState.dart';
import 'package:stripes_app/ViewModels/BaseModel.dart';

class TestState {
  static final String start = "start";
  static final String finishedEating = "finishedEating";
  static final String middleLogs = "middleLogs";

}

class TestModel extends BaseModel {

  final FirebaseFirestore store = FirebaseFirestore.instance;

  final FirebaseAuth auth = FirebaseAuth.instance;

  static final TestModel testModel = TestModel._internal();

  bool initialized = false;

  String _currentState = TestState.start;

  final String _coll = "TestData";
  
  final String _stateField = "TestState";

  final String _percentConsumed = "PercentConsumed";
  
  TestModel._internal() {
    setState(CurrentState.Waiting);
  }

  factory TestModel() {
    return testModel;
  }

  init() async {
    if(initialized)
      return;
    await store.collection(_coll).doc(auth.currentUser.uid).set({_stateField : _currentState});
    initialized = true;
    setState(CurrentState.Complete);
  }

  @override
  // ignore: must_call_super
  dispose() {
    return;
  }

  cancelTest() {
    _currentState = TestState.start;
    store.collection(_coll).doc(auth.currentUser.uid).update({_stateField : _currentState});
  }

  startTest() {
    setState(CurrentState.Waiting);
    _currentState = TestState.finishedEating;
    store.collection(_coll).doc(auth.currentUser.uid).update({_stateField : _currentState}).catchError((err){
      _currentState = TestState.start;
      setState(CurrentState.Complete);
    }).whenComplete(() => setState(CurrentState.Complete));
  }

  finishedEating(double percent) {
    setState(CurrentState.Waiting);
    _currentState = TestState.middleLogs;
    store.collection(_coll).doc(auth.currentUser.uid).update({_stateField : _currentState, _percentConsumed : "$percent"}).catchError((err){
      _currentState = TestState.finishedEating;
      setState(CurrentState.Complete);
    }).whenComplete(() => setState(CurrentState.Complete));
  }

  logEntry(int time, String type, FileImage pic) async {
    if (state == CurrentState.Complete) {}
  }

  String get currentState => _currentState;

}
