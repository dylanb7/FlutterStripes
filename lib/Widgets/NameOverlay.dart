import 'package:flutter/cupertino.dart';

class NameOverlay extends StatelessWidget {
  final Widget child;
  final String title;
  final double topOpacity;

  const NameOverlay(
      this.child, this.title, {this.topOpacity = 0.9});

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Stack(children: <Widget>[
      Opacity(opacity: 1-topOpacity, child: child),
      IgnorePointer(
        child: Opacity(
            opacity: topOpacity,
            child: Container(
              alignment: Alignment.center,
              color: Color.fromARGB(100, 0, 0, 0),
              child: Center(
                child: Text(title,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            )),
      ),
    ]));
  }
}
