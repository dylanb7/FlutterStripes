import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stripes_app/Utility/TextStyles.dart';

class PictureFetcherPopUp extends StatefulWidget {
  final PictureListener listener;

  PictureFetcherPopUp(this.listener);

  @override
  State<StatefulWidget> createState() {
    return _PictureFetcherPopUpState();
  }
}

class _PictureFetcherPopUpState extends State<PictureFetcherPopUp> {
  CameraController controller;
  List cameras;
  int cameraIndex;
  String imagePath;
  bool isConfirming = false;

  @override
  void initState() {
    super.initState();
    availableCameras().then((all) {
      cameras = all;
      if (cameras.isNotEmpty) {
        setState(() {
          cameraIndex = 0;
        });
        _initController(cameras[cameraIndex]).then((value) {});
      }
    }).catchError((e) {});
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
          content: Builder(
            builder: (context) {
              final bool isInitialized =
                  controller != null && controller.value.isInitialized;
              final double width =
                  isInitialized ? size.width * 0.9 : size.width / 2;
              final double cameraHeight = isInitialized
                  ? (width / controller.value.aspectRatio)
                  : size.height / 2;
              final double topBarSize = size.height / 14;
              final double height = isInitialized
                  ? cameraHeight + topBarSize
                  : width / size.aspectRatio;
              return Container(
                  width: width,
                  height: height,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topBarSize, child: _topBar(context)),
                      Expanded(
                          child: FittedBox(
                            fit: BoxFit.contain,
                              child: isConfirming
                                  ? _imagePreview(context)
                                  : _cameraPreview(context)))
                    ],
                  ));
            },
          ),
          actions: [_toggleCamera(), _captureButton(context)],
          actionsPadding: EdgeInsets.symmetric(horizontal: 10),
          contentPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
        ));
  }

  Widget _topBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        isConfirming
            ? IconButton(
                onPressed: () {
                  setState(() {
                    isConfirming = false;
                  });
                },
                icon: Icon(Icons.arrow_back),
              )
            : Container(),
        Text(
          isConfirming ? "Confirm Image" : "Take Image",
          style: TextStyles.subHeader,
        ),
        IconButton(
          onPressed: () {
            widget.listener.setPath("");
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.close),
        )
      ],
    );
  }

  Future _initController(CameraDescription desc) async {
    if (controller != null) await controller.dispose();
    controller =
        CameraController(desc, ResolutionPreset.high, enableAudio: false);
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) controller.dispose();
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {}
    if (mounted) setState(() {});
  }

  Widget _cameraPreview(BuildContext context) {
    if (controller == null || !controller.value.isInitialized)
      return Align(
          alignment: Alignment.center,
          child: Container(
              constraints: BoxConstraints(maxHeight: 200),
              child: Column(children: [
                Spacer(),
                Container(
                    constraints: BoxConstraints(maxWidth: 100, maxHeight: 100),
                    child: CircularProgressIndicator()),
                RaisedButton(
                  child: Text(
                    "Cancel",
                  ),
                  onPressed: () => {
                    controller?.dispose(),
                    Navigator.of(context).pop(),
                  },
                )
              ])));
    return Container(height: 100 ,child: AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    ));
  }

  Widget _toggleCamera() {
    if (cameras == null || cameras.isEmpty || isConfirming) return Container();
    CameraDescription selected = cameras[cameraIndex];
    CameraLensDirection dir = selected.lensDirection;
    return FlatButton.icon(
        onPressed: _onSwitchCamera,
        icon: Icon(_getCameraLensIcon(dir)),
        label: Text(
            "${dir.toString().substring(dir.toString().indexOf('.') + 1)}"));
  }

  _onSwitchCamera() {
    cameraIndex = cameraIndex < cameras.length - 1 ? cameraIndex + 1 : 0;
    CameraDescription selectedCamera = cameras[cameraIndex];
    _initController(selectedCamera);
  }

  IconData _getCameraLensIcon(CameraLensDirection dir) {
    switch (dir) {
      case CameraLensDirection.back:
        return Icons.camera_rear;
      case CameraLensDirection.front:
        return Icons.camera_front;
      case CameraLensDirection.external:
        return Icons.camera;
      default:
        return Icons.device_unknown;
    }
  }

  Widget _captureButton(BuildContext context) {
    if (cameras == null || cameras.isEmpty || isConfirming) return Container();
    return FlatButton.icon(
        onPressed: () => _onCapture(context),
        icon: Icon(Icons.camera),
        label: Text("Capture"));
  }

  _onCapture(BuildContext context) async {
    String path = await _capture(context);
    if (path == "") return;
    setState(() {
      isConfirming = true;
    });
  }

  Future<String> _capture(BuildContext context) async {
    try {
      final String path =
          join((await getTemporaryDirectory()).path, "${DateTime.now()}.png");
      await controller.takePicture(path);
      widget.listener.setPath(path);
      return path;
    } catch (e) {
      return "";
    }
  }

  Widget _imagePreview(BuildContext context) {
    final Image image = Image(
      image: FileImage(File(widget.listener.path)),
      fit: BoxFit.contain,
    );
    return Container(height: 200, width: 100,child: Flex(
      direction: Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(flex: 9,child: image),
        Flexible(flex: 1,child: RaisedButton(
          child: Text("Select"),
          onPressed: () {
            controller?.dispose();
            Navigator.of(context).pop();
          },
        ))
      ],
    ));
  }
}

class PictureListener {
  String _path = "";

  String get path => _path;

  setPath(String path) => _path = path;
}
