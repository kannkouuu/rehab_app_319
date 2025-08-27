import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'coordinates_translator.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

String DetectResult = '';
String SecondModelResult = ''; // 第二個模型的檢測結果

class LabelDetectorPainter extends CustomPainter {
  LabelDetectorPainter(
      this.labels,
      this.faces,
      this.rotation,
      this.imageSize,
      this.cameraLensDirection,
      [this.roiRect,  // 可選參數：ROI矩形
        this.secondModelLabels] // 可選參數：第二個模型的結果
      );

  final List<ImageLabel> labels;
  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final Rect? roiRect; // ROI矩形
  final List<ImageLabel>? secondModelLabels; // 第二個模型的標籤

  @override
  void paint(Canvas canvas, Size size) {
    // 繪製第一個模型的標籤結果
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 23,
          textDirection: TextDirection.ltr),
    );
    builder.pushStyle(ui.TextStyle(color: Colors.lightBlue[900]));
    for (final ImageLabel label in labels) {
      label.label == "normal"? builder.addText('nonface'):
      builder.addText('${label.label}');
      DetectResult = label.label;
    }
    builder.pop();

    canvas.drawParagraph(
      builder.build()
        ..layout(ui.ParagraphConstraints(
          width: size.width,
        )),
      const Offset(0, 0),
    );

    // 繪製第二個模型的結果（如果有）
    if (secondModelLabels != null && secondModelLabels!.isNotEmpty) {
      final ui.ParagraphBuilder secondBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
            textAlign: TextAlign.center,
            fontSize: 23,
            textDirection: TextDirection.ltr),
      );
      secondBuilder.pushStyle(ui.TextStyle(color: Colors.green[900]));

      // 在ROI區域下方顯示第二個模型的結果
      secondBuilder.addText('ROI: ');
      for (final ImageLabel label in secondModelLabels!) {
        secondBuilder.addText('${label.label} (${label.confidence.toStringAsFixed(2)})');
        SecondModelResult = label.label; // 存儲第二個模型的結果
      }
      secondBuilder.pop();

      canvas.drawParagraph(
        secondBuilder.build()
          ..layout(ui.ParagraphConstraints(
            width: size.width,
          )),
        Offset(0, 30), // 在主標籤下方顯示
      );
    }

    // 繪製ROI框（如果有）
    if (roiRect != null) {
      final Paint roiPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.green;

      canvas.drawRect(roiRect!, roiPaint);
    }

    // 繪製臉部檢測結果
    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.red;
    final Paint paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..color = Colors.blue;

    for (final Face face in faces) {
      final left = translateX(
        face.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        face.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        face.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        face.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint1,
      );

      void paintContour(FaceContourType type) {
        final contour = face.contours[type];
        if (contour?.points != null) {
          for (final Point point in contour!.points) {
            canvas.drawCircle(
                Offset(
                  translateX(
                    point.x.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                  translateY(
                    point.y.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                ),
                1,
                paint1);
          }
        }
      }

      void paintLandmark(FaceLandmarkType type) {
        final landmark = face.landmarks[type];
        if (landmark?.position != null) {
          canvas.drawCircle(
              Offset(
                translateX(
                  landmark!.position.x.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
                translateY(
                  landmark.position.y.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
              ),
              2,
              paint2);
        }
      }

      for (final type in FaceContourType.values) {
        paintContour(type);
      }

      for (final type in FaceLandmarkType.values) {
        paintLandmark(type);
      }
    }
  }

  @override
  bool shouldRepaint(LabelDetectorPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.secondModelLabels != secondModelLabels;
  }
}