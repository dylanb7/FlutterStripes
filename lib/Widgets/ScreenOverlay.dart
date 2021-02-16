import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScreenOverlay extends StatelessWidget {
  final Widget background;

  final ScreenOverlayController controller;

  ScreenOverlay(this.background, this.controller);

  ScreenOverlayController get overlayController => controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScreenOverlayController>(
        create: (context) => controller,
        child: Stack(
          overflow: Overflow.visible,
          children: [
            Consumer<ScreenOverlayController>(
              builder: (context, model, widget) {
                return IgnorePointer(
                    ignoring: model.isShowing, child: background);
              },
            ),
            BackdropFilter(filter: ImageFilter.blur(sigmaX: 6,sigmaY: 6),child: Consumer<ScreenOverlayController>(
              builder: (context, model, widget) {
                return model.isShowing && controller.popUp != null
                    ? controller.popUp
                    : Container();
              },
            ))
          ],
        ));
  }
}

class ScreenOverlayController extends ChangeNotifier {
  bool _isShowing = false;

  Widget _popUp;

  bool get isShowing => _isShowing;

  setShowing(bool isShowing, [Function onChange]) {
    _isShowing = isShowing;
    notifyListeners();
    if(onChange != null)
      onChange();
  }

  Widget get popUp => _popUp;

  setPopup(Widget popUp) {
    _popUp = popUp;
    setShowing(true);
  }

}
