import 'dart:collection';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stripes_app/Utility/TextStyles.dart';
import 'package:stripes_app/View/Dashboard.dart';
import 'package:stripes_app/ViewModels/UserData.dart';
import 'package:provider/provider.dart';
import 'package:stripes_app/Widgets/ScreenOverlay.dart';

import 'DateTimePickerWidget.dart';

class AddUserPopUp extends StatefulWidget {

  final ScreenOverlayController controller;

  AddUserPopUp(this.controller);

  @override
  State<StatefulWidget> createState() {
    return _AddUserPopUpState();
  }
}

class _AddUserPopUpState extends State<AddUserPopUp> {
  final String _username = "Username";
  final String _name = "Name";
  final String _gender = "Gender";

  LinkedHashMap<String, bool> _fields;

  Map<String, TextEditingController> _controllers;

  DateTimeListener listener = DateTimeListener();

  @override
  void initState() {
    super.initState();
    _fields = LinkedHashMap.of({
      _username: false,
      _name: false,
      _gender: false,
    });

    _controllers = {
      _username: _getController(_username),
      _name: _getController(_name),
      _gender: _getController(_gender),
    };
  }

  TextEditingController _getController(String name) {
    TextEditingController controller = TextEditingController();
    controller.addListener(() {
      setState(() {
        if (_fields[name]) _fields[name] = false;
      });
    });
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
            elevation: 10,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
            content: Container(
              width: size.width * 0.9,
              height: size.height * 0.6,
              child: SingleChildScrollView(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(),
                        FittedBox(
                            fit: BoxFit.fill,
                            child: Text(
                              "User Info",
                              style: TextStyles.screenHeader,
                            )),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            widget.controller.setShowing(false);
                          },
                        ),
                      ]),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ..._fields.keys.map((key) {
                              return TextField(
                                decoration: InputDecoration(
                                    hintText: key,
                                    errorStyle: TextStyles.textFieldError,
                                    errorText:
                                        _fields[key] ? "Required Field" : null),
                                controller: _controllers[key],
                              );
                            }),
                            Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Center(
                                    child: Text(
                                  "Date of birth",
                                  style: TextStyles.subHeader,
                                ))),
                            DateTimePickerWidget(
                              listener,
                              earliestDateFromStart: Duration(days: 20000),
                            ),
                            Divider(
                              height: 3,
                              indent: 5,
                              endIndent: 5,
                              color: Colors.grey.shade700,
                            ),
                            RaisedButton(
                              child: Text(
                                "Add User",
                                style: TextStyles.subHeader,
                              ),
                              onPressed: () => onSubmit(context),
                            )
                          ])),
                ],
              )),
            )));
  }

  onSubmit(BuildContext context) {
    List<String> invalid = [];
    for (String key in _controllers.keys) {
      if (!isValid(context, _controllers[key].text, key)) invalid.add(key);
    }
    if (invalid.isEmpty) {
      User user = User(
          _controllers[_username].text,
          _controllers[_name].text,
          _controllers[_gender].text,
          10);
      Dashboard.dashboardKey.currentState.addUser(user);
      widget.controller.setShowing(false);
    } else {
      setState(() {
        for (String key in invalid) {
          _fields[key] = true;
        }
      });
    }
  }

  bool isValid(BuildContext context, String input, String name) {
    if (input.isEmpty) return false;
    if (input == _username &&
        Provider.of<UserData>(context, listen: false)
            .getUsers()
            .contains(input)) return false;
    return true;
  }
}
