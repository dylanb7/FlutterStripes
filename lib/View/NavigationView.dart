import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stripes_app/Enums/CurrentState.dart';
import 'package:stripes_app/Utility/TextStyles.dart';
import 'package:stripes_app/ViewModels/UserData.dart';

import 'BaseView.dart';
import 'Dashboard.dart';
import 'Export.dart';
import 'Edit.dart';

class NavigationView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NavigationViewState();
  }
}

class _NavigationViewState extends State<NavigationView> {
  int _currentIndex = 1;

  final Map<int, Widget> screens = {
    0: Edit(),
    1: Dashboard(Dashboard.dashboardKey),
    2: Export(),
  };

  final List<String> headers = ["Edit", "Record", "Export"];

  @override
  Widget build(BuildContext context) {
    return BaseView<UserData>(
      onModelReady: (model) {
        model.init();
      },
      builder: (context, model, widget) {
        final double top = MediaQuery.of(context).size.height * 0.05;
        return progressOverlay(Scaffold(
                backgroundColor: Theme.of(context).primaryColor,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(
                          top: top,
                          left: top / 2,
                          right: top / 2,
                          bottom: top / 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                              child: Text(
                            headers[_currentIndex],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 35,
                            ),
                          )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25.0),
                            topRight: Radius.circular(25.0),
                          ),
                        ),
                        child: screens[_currentIndex],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: model.state == CurrentState.Waiting
                    ? Container()
                    : BottomNavigationBar(
                        items: [
                          BottomNavigationBarItem(
                              icon: Icon(Icons.edit), label: "Edit"),
                          BottomNavigationBarItem(
                              icon: Icon(Icons.dashboard), label: "Record"),
                          BottomNavigationBarItem(
                              icon: Icon(Icons.send), label: "Export")
                        ],
                        onTap: (index) => _navTapped(index),
                        currentIndex: _currentIndex,
                      ),
              ), model.state == CurrentState.Waiting, context);
      },
    );
  }

  Widget progressOverlay(Widget under, bool isLoading, BuildContext context) {
    return Stack(
      overflow: Overflow.visible,
      children: [
        IgnorePointer(
          ignoring: isLoading,
          child: under,
        ),
        isLoading
            ? Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.white70,
                child: Center(
                    child: Container(
                        constraints:
                            BoxConstraints(maxWidth: 100, maxHeight: 100),
                        child: CircularProgressIndicator())))
            : Container()
      ],
    );
  }

  _navTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
