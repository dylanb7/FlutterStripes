import 'package:flutter/cupertino.dart';

class IconSelectButton extends StatefulWidget {



  @override
  State<StatefulWidget> createState() {
    return _IconSelectButtonState();
  }

}

class _IconSelectButtonState extends State<IconSelectButton> {

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

}

class SelectionData {
  final IconData data;
  final String title;

  SelectionData(this.data, this.title);
}