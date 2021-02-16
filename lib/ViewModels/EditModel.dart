import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:stripes_app/Enums/CurrentState.dart';
import 'package:stripes_app/ViewModels/BaseModel.dart';
import 'package:stripes_app/ViewModels/UserData.dart';

class EditModel extends BaseModel {

  UserData userData;

  List<Stamped> _stamps;

  bool Function(Stamped) condition = (stamp) => true;

  init(UserData data, BuildContext context) {
    this.userData = data;
    this._stamps = data.getSorted(DataType.ordered());
    setState(CurrentState.Complete);
  }

  Future<bool> delete(int stamp) async {
    setState(CurrentState.Waiting);
    try {
      await userData.remove(stamp);
      _stamps.removeWhere((element) => element.stamp == stamp);
      setState(CurrentState.Complete);
      return true;
    }catch (e) {
      setState(CurrentState.Complete);
      return false;
    }
  }

  Future<bool> edit(Stamped stamp, Map<String, String> changes) async {
    setState(CurrentState.Waiting);
    try {
      bool res = await userData.edit(stamp, changes);
      _stamps = userData.getSorted(DataType.ordered());
      setState(CurrentState.Complete);
      return res;
    }catch (e) {
      setState(CurrentState.Complete);
      return false;
    }
  }

  Future<Uint8List> getImage(Stamped stamped) async {
    String url = "";
    if(stamped is SymptomData)
      url = stamped.url;
    return await userData.storageInstance.refFromURL(url).getData();
  }

  setCondition(bool Function(Stamped) func) {
    condition = func;
    setState(CurrentState.Complete);
  }

  List<Stamped> get stamps => List.of(_stamps.where((element) => condition(element)));

  List<Stamped> get allStamps => List.of(_stamps.reversed);


}