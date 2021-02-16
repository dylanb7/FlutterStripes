
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stripes_app/Locator.dart';
import 'package:stripes_app/Models/Routes.dart';
import 'package:firebase_core/firebase_core.dart';

import 'Utility/rgbToMaterial.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setUpLocator();
  Sqflite.setDebugModeOn(true);
  runApp(Stripes());
}

class Stripes extends StatelessWidget {

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Stripes',
            home: Navigator(
              key: navigatorKey,
              initialRoute: Routes.login,
              onGenerateRoute: Routes.generateRoute,
            ),
            theme: ThemeData(
              primarySwatch: from(Color.fromRGBO(13, 53, 159, 1)),//from(Colors.orange.shade600),
              visualDensity: VisualDensity.compact,
            ),
          );
        }
        return Container(width: 100, height: 100,child: CircularProgressIndicator());
      },
    );
  }
}
