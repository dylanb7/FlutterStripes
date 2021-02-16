import 'package:flutter/material.dart';

class TextStyles {
  static TextStyle get screenHeader =>
      TextStyle(fontSize: 40, color: Colors.black54, fontWeight: FontWeight.bold);

  static TextStyle get subHeader =>
      TextStyle(fontSize: 20, color: Colors.black54, fontWeight: FontWeight.bold);

  static TextStyle get descriptor =>
      TextStyle(fontSize: 15, color: Colors.black54);

  static TextStyle get textFieldNormal =>
      TextStyle(fontSize: 14, color: Colors.black54);

  static TextStyle get textFieldError =>
      TextStyle(fontSize: 14, color: Colors.red.shade900, fontWeight: FontWeight.bold);

}
