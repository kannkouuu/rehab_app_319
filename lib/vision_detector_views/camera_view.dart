import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../main.dart';

enum ScreenMode { liveFeed }

bool forntcamra = true;
class CameraView extends StatefulWidget {
  CameraView(
      {Key? key,
      required this.title,
      required this.customPaint,
      this.text,
      required this.onImage,
      this.onScreenModeChanged,
      this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final String title;
  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final Function(ScreenMode mode)? onScreenModeChanged;
  final CameraLensDirection initialDirection;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  int _cameraIndex = -1;
  bool _changingCameraLens = false;

  @override
  void initState() {
    super.initState();
    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == widget.initialDirection) {
          _cameraIndex = i;
          break;
        }
      }
    }
    if (_cameraIndex != -1 && cameras.length > 1 && _cameraIndex < cameras.length - 1){
      _cameraIndex++;
    }
    _startLiveFeed();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    forntcamra = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar:
          AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Colors.black,
              ),
              color:Colors.black,
              onPressed: () { Navigator.pop(context); },),

            title: Text(widget.title,style: TextStyle(color: Colors.black,),),
            backgroundColor: Color.fromARGB(255, 18, 255, 247),
            centerTitle: true,
          ),*/
      body: _body(),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget? _floatingActionButton() {
    if (cameras.length == 1) return null;
    return Container(
        decoration: new BoxDecoration(
          color: Color.fromARGB(150, 255, 255, 255),
          borderRadius: BorderRadius.all(Radius.circular(50.0)),),
        height: 70.0,
        width: 70.0,
        child: FloatingActionButton(
          backgroundColor: Color(0xffffff),
          onPressed: _switchLiveCamera,
          child: Icon(
            Platform.isIOS
                ? Icons.flip_camera_ios_outlined
                : Icons.flip_camera_android_outlined,
            size: 40,
            color: Colors.black,
          ),
        ));
  }

  Widget _body() {
    Widget body;
    body = _liveFeedBody();
    return body;
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }

    final orientation = MediaQuery.of(context).orientation;
    final screenSize = MediaQuery.of(context).size;
    // Assuming _controller.value.aspectRatio is the camera's native preview aspect ratio (e.g., landscape width/height)
    final cameraAspectRatio = _controller!.value.aspectRatio; 

    double scale;

    if (orientation == Orientation.portrait) {
      // 與原先相同：portrait 以寬度為基準覆蓋高度
      scale = screenSize.aspectRatio * cameraAspectRatio;
    } else {
      // landscape 以高度為基準覆蓋寬度 -> 等同於 (螢幕寬高比 / 相機寬高比)
      scale = screenSize.aspectRatio / cameraAspectRatio;
    }

    // 確保 scale >= 1，以達到 BoxFit.cover 的效果
    if (scale < 1) {
      scale = 1 / scale;
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: scale,
            child: Center(
              child: _changingCameraLens
                  ? Center(
                      child: const Text('Changing camera lens'),
                    )
                  : CameraPreview(_controller!),
            ),
          ),
          if (widget.customPaint != null)
            orientation == Orientation.landscape 
              ? Transform.flip(
                  flipX: true,
                  child: Transform.scale(
                    scale: scale,
                    child: widget.customPaint!,
                  ),
                )
              : Transform.scale(
                  scale: scale,
                  child: widget.customPaint!,
                ),
        ],
      ),
    );
  }

  Widget _buildLandscapeCustomPaint() => widget.customPaint!;

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      // Set to ResolutionPreset.high. Do NOT set it to ResolutionPreset.max because for some phones does NOT work.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % cameras.length;
    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
    if(forntcamra){
      forntcamra = false;
    }else{
      forntcamra = true;
    }
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get camera rotation
    final camera = cameras[_cameraIndex];
    // 依照 ML Kit 推薦公式計算 rotationDegrees
    final deviceOrientation = _controller?.value.deviceOrientation;

    int deviceRotationDegrees;
    switch (deviceOrientation) {
      case DeviceOrientation.portraitUp:
        deviceRotationDegrees = 0;
        break;
      case DeviceOrientation.landscapeLeft: // home 鍵在右
        deviceRotationDegrees = 270;
        break;
      case DeviceOrientation.portraitDown:
        deviceRotationDegrees = 180;
        break;
      case DeviceOrientation.landscapeRight: // home 鍵在左
        deviceRotationDegrees = 90;
        break;
      default:
        deviceRotationDegrees = 0;
    }

    int rotationDegrees;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationDegrees = (camera.sensorOrientation + deviceRotationDegrees) % 360;
    } else {
      rotationDegrees = (camera.sensorOrientation - deviceRotationDegrees + 360) % 360;
    }

    final rotation = InputImageRotationValue.fromRawValue(rotationDegrees);
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
}
