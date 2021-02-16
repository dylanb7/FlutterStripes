
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stripes_app/Utility/Transitions.dart';
import 'package:stripes_app/View/Login.dart';
import 'package:stripes_app/View/NavigationView.dart';

class Routes {
  static const String login = "/";
  static const String dashboard = "/dashboard";
  static const String picturePreview = "/picturePreview";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch(settings.name) {
      case login:
        return PageRouteBuilder(
          pageBuilder: (_,__,___)=>Login()
        );
      case dashboard:
        return ScaleRoute(widget: NavigationView());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text("Route does not exist"),),
          )
        );
    }
  }
}