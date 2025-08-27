import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// 非同步圖像轉換的輔助類
class _ImageConversionParams {
  final int width;
  final int height;
  final List<Uint8List> planeBytes;
  final List<int> bytesPerRow;
  final ImageFormatGroup formatGroup;

  _ImageConversionParams({
    required this.width,
    required this.height,
    required this.planeBytes,
    required this.bytesPerRow,
    required this.formatGroup,
  });

  // 從CameraImage創建參數對象
  static _ImageConversionParams fromCameraImage(CameraImage cameraImage) {
    return _ImageConversionParams(
      width: cameraImage.width,
      height: cameraImage.height,
      planeBytes: cameraImage.planes.map((plane) => plane.bytes).toList(),
      bytesPerRow:
          cameraImage.planes.map((plane) => plane.bytesPerRow).toList(),
      formatGroup: cameraImage.format.group,
    );
  }
}

// BGRA8888轉換的isolate函數
img.Image? _convertBGRA8888ToRGBIsolate(_ImageConversionParams params) {
  try {
    print('BGRA8888格式詳情: planes數量=${params.planeBytes.length}');

    if (params.planeBytes.isEmpty) {
      print('BGRA8888: 沒有足夠的平面數據');
      return null;
    }

    final buffer = params.planeBytes[0];
    final bytesPerRow = params.bytesPerRow[0];

    print('BGRA8888平面資訊: bytesPerRow=$bytesPerRow, buffer長度=${buffer.length}');
    print('計算的理論行寬: ${params.width * 4}, 實際行寬: $bytesPerRow');

    // 創建RGB圖像
    final image = img.Image(width: params.width, height: params.height);

    // BGRA8888格式：每個像素4個字節，順序為B-G-R-A
    // 注意：iOS的bytesPerRow可能包含填充字節，不一定等於width*4
    for (int row = 0; row < params.height; row++) {
      for (int col = 0; col < params.width; col++) {
        // 使用bytesPerRow來計算每行的起始位置，避免填充字節問題
        final int rowStartIndex = row * bytesPerRow;
        final int pixelIndex = rowStartIndex + (col * 4);

        if (pixelIndex + 3 < buffer.length) {
          final int b = buffer[pixelIndex] & 0xFF; // Blue
          final int g = buffer[pixelIndex + 1] & 0xFF; // Green
          final int r = buffer[pixelIndex + 2] & 0xFF; // Red
          // Alpha 通道通常不使用: buffer[pixelIndex + 3]

          image.setPixelRgb(col, row, r, g, b);
        } else {
          print(
              '像素索引超出範圍: row=$row, col=$col, pixelIndex=$pixelIndex, bufferLength=${buffer.length}');
          image.setPixelRgb(col, row, 0, 0, 0);
        }
      }
    }

    print('BGRA8888轉RGB成功完成');
    return image;
  } catch (e) {
    print('BGRA8888轉RGB失敗: $e');
    return null;
  }
}

// NV21轉換的isolate函數
img.Image? _convertNV21ToRGBIsolate(_ImageConversionParams params) {
  try {
    print('NV21格式詳情: planes數量=${params.planeBytes.length}');

    if (params.planeBytes.isEmpty) {
      print('NV21: 沒有足夠的平面數據');
      return null;
    }

    final buffer = params.planeBytes[0];
    final bytesPerRow = params.bytesPerRow[0];

    print('NV21平面資訊: bytesPerRow=$bytesPerRow, buffer長度=${buffer.length}');

    // 創建RGB圖像
    final image = img.Image(width: params.width, height: params.height);

    // 計算Y數據和UV數據的分界點
    final int ySize = params.width * params.height;
    final int uvStart = ySize; // UV數據從Y數據後開始

    // NV21轉RGB的計算
    for (int row = 0; row < params.height; row++) {
      for (int col = 0; col < params.width; col++) {
        final int yIndex = row * params.width + col;
        final int uvRow = row ~/ 2;
        final int uvCol = col ~/ 2;
        final int uvIndex = uvStart + (uvRow * params.width + uvCol * 2);

        if (yIndex < buffer.length &&
            uvIndex + 1 < buffer.length &&
            yIndex < ySize) {
          final int y = buffer[yIndex] & 0xFF;
          final int v = buffer[uvIndex] & 0xFF;
          final int u = buffer[uvIndex + 1] & 0xFF;

          final int r = (y + 1.402 * (v - 128)).round().clamp(0, 255);
          final int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128))
              .round()
              .clamp(0, 255);
          final int b = (y + 1.772 * (u - 128)).round().clamp(0, 255);

          image.setPixelRgb(col, row, r, g, b);
        } else {
          if (yIndex < buffer.length) {
            final int gray = buffer[yIndex] & 0xFF;
            image.setPixelRgb(col, row, gray, gray, gray);
          }
        }
      }
    }

    print('NV21轉RGB成功完成');
    return image;
  } catch (e) {
    print('NV21轉RGB失敗: $e');
    return null;
  }
}

// YUV420轉換的isolate函數
img.Image? _convertYUV420ToRGBIsolate(_ImageConversionParams params) {
  try {
    if (params.planeBytes.length < 3) return null;

    final yBuffer = params.planeBytes[0];
    final uBuffer = params.planeBytes[1];
    final vBuffer = params.planeBytes[2];

    final yBytesPerRow = params.bytesPerRow[0];
    final uBytesPerRow = params.bytesPerRow[1];

    final image = img.Image(width: params.width, height: params.height);

    for (int row = 0; row < params.height; row++) {
      for (int col = 0; col < params.width; col++) {
        final int yIndex = row * yBytesPerRow + col;
        final int uvRow = row ~/ 2;
        final int uvCol = col ~/ 2;
        final int uvIndex = uvRow * uBytesPerRow + uvCol;

        if (yIndex < yBuffer.length &&
            uvIndex < uBuffer.length &&
            uvIndex < vBuffer.length) {
          final int y = yBuffer[yIndex] & 0xFF;
          final int u = uBuffer[uvIndex] & 0xFF;
          final int v = vBuffer[uvIndex] & 0xFF;

          final int r = (y + 1.402 * (v - 128)).round().clamp(0, 255);
          final int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128))
              .round()
              .clamp(0, 255);
          final int b = (y + 1.772 * (u - 128)).round().clamp(0, 255);

          image.setPixelRgb(col, row, r, g, b);
        }
      }
    }

    return image;
  } catch (e) {
    print('YUV420轉RGB失敗: $e');
    return null;
  }
}

// 灰度轉換的isolate函數
img.Image? _convertToGrayscaleIsolate(_ImageConversionParams params) {
  try {
    if (params.planeBytes.isEmpty) return null;

    final yBuffer = params.planeBytes[0];
    final yBytesPerRow = params.bytesPerRow[0];

    final image = img.Image(width: params.width, height: params.height);

    for (int y = 0; y < params.height; y++) {
      for (int x = 0; x < params.width; x++) {
        final int yIndex = y * yBytesPerRow + x;

        if (yIndex < yBuffer.length) {
          final int gray = yBuffer[yIndex] & 0xFF;
          image.setPixelRgb(x, y, gray, gray, gray);
        }
      }
    }

    return image;
  } catch (e) {
    print('灰度轉換失敗: $e');
    return null;
  }
}

// ROI 圖像處理類別，用於裁剪和處理感興趣區域的圖像
class ROIProcessor {
  // 從 InputImage 中創建 ROI 區域的 InputImage
  static Future<InputImage?> processROI(InputImage inputImage, Rect roi,
      CameraLensDirection cameraLensDirection) async {
    try {
      // 如果是文件路徑，我們可以讀取圖像並裁剪
      if (inputImage.type == InputImageType.file) {
        final file = io.File(inputImage.filePath!);
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) return null;

        // 計算實際要裁剪的區域（考慮縮放和旋轉）
        final int x =
            (roi.left * image.width / inputImage.metadata!.size.width).round();
        final int y =
            (roi.top * image.height / inputImage.metadata!.size.height).round();
        final int width =
            (roi.width * image.width / inputImage.metadata!.size.width).round();
        final int height =
            (roi.height * image.height / inputImage.metadata!.size.height)
                .round();

        // 裁剪圖像
        final croppedImage = img.copyCrop(
          image,
          x: x,
          y: y,
          width: width,
          height: height,
        );

        // 將裁剪後的圖像保存為臨時文件
        final tempDir = await getTemporaryDirectory();
        final tempFile = io.File('${tempDir.path}/roi_image.jpg');
        await tempFile.writeAsBytes(img.encodeJpg(croppedImage));

        // 創建新的 InputImage
        return InputImage.fromFilePath(tempFile.path);
      }

      return null;
    } catch (e) {
      print('ROI 處理失敗: $e');
      return null;
    }
  }

  // 從相機圖像創建用於顯示的ROI圖像
  static Future<Image?> createDisplayableROIImage(
      CameraImage cameraImage, Rect roi, CameraDescription camera,
      {Size? screenSize}) async {
    try {
      // 使用一個簡單方法：只取Y平面（亮度）創建灰度圖像
      final imgLib = await _convertCamToImage(cameraImage);
      if (imgLib == null) return null;

      // 使用傳入的螢幕尺寸或預設值
      final actualScreenWidth = screenSize?.width ?? 400.0;
      final actualScreenHeight = screenSize?.height ?? 800.0;

      // 保留原始圖像尺寸，不強制調整為螢幕尺寸，避免比例失真
      print('顯示用 - 原始相機圖像尺寸: ${imgLib.width}x${imgLib.height}');
      img.Image originalImage = imgLib;

      // 根據相機旋轉調整圖像
      final rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      img.Image rotatedImage = originalImage;

      if (rotation == InputImageRotation.rotation90deg) {
        rotatedImage = img.copyRotate(originalImage, angle: 90);
      } else if (rotation == InputImageRotation.rotation180deg) {
        rotatedImage = img.copyRotate(originalImage, angle: 180);
      } else if (rotation == InputImageRotation.rotation270deg) {
        rotatedImage = img.copyRotate(originalImage, angle: 270);
      }

      // 根據鏡頭方向進行水平翻轉
      if (camera.lensDirection == CameraLensDirection.front) {
        rotatedImage = img.flipHorizontal(rotatedImage);
      }

      print(
          'ROI矩形: left=${roi.left}, top=${roi.top}, width=${roi.width}, height=${roi.height}');
      print(
          '旋轉後圖像尺寸: width=${rotatedImage.width}, height=${rotatedImage.height}');

      // 計算統一的縮放比例，保持ROI框的原始長寬比
      double scaleX = rotatedImage.width / actualScreenWidth;
      double scaleY = rotatedImage.height / actualScreenHeight;

      // 使用統一的縮放比例來保持ROI框的原始比例
      double uniformScale = (scaleX + scaleY) / 2.0;

      print('顯示用 - 原始縮放比例: scaleX=$scaleX, scaleY=$scaleY');
      print('顯示用 - 統一縮放比例: $uniformScale');

      // 使用統一縮放比例來定位ROI，保持原始比例
      final int roiX =
          (roi.left * uniformScale).toInt().clamp(0, rotatedImage.width - 1);
      final int roiY =
          (roi.top * uniformScale).toInt().clamp(0, rotatedImage.height - 1);
      final int roiWidth = (roi.width * uniformScale)
          .toInt()
          .clamp(1, rotatedImage.width - roiX);
      final int roiHeight = (roi.height * uniformScale)
          .toInt()
          .clamp(1, rotatedImage.height - roiY);

      print(
          '計算後的ROI裁剪區域: x=$roiX, y=$roiY, width=$roiWidth, height=$roiHeight');

      // 在旋轉後的圖像上標記ROI位置（用於調試）
      img.Image markedImage = img.copyResize(rotatedImage,
          width: rotatedImage.width, height: rotatedImage.height);

      // 在圖像上畫一個紅色邊框顯示ROI位置
      for (int x = roiX; x < roiX + roiWidth; x++) {
        if (x >= 0 && x < markedImage.width) {
          if (roiY >= 0 && roiY < markedImage.height)
            markedImage.setPixelRgb(x, roiY, 255, 0, 0);
          int bottomY = roiY + roiHeight - 1;
          if (bottomY >= 0 && bottomY < markedImage.height)
            markedImage.setPixelRgb(x, bottomY, 255, 0, 0);
        }
      }

      for (int y = roiY; y < roiY + roiHeight; y++) {
        if (y >= 0 && y < markedImage.height) {
          if (roiX >= 0 && roiX < markedImage.width)
            markedImage.setPixelRgb(roiX, y, 255, 0, 0);
          int rightX = roiX + roiWidth - 1;
          if (rightX >= 0 && rightX < markedImage.width)
            markedImage.setPixelRgb(rightX, y, 255, 0, 0);
        }
      }

      // 裁剪ROI
      final croppedImage = img.copyCrop(
        rotatedImage,
        x: roiX,
        y: roiY,
        width: roiWidth,
        height: roiHeight,
      );

      // 將裁剪後的圖像調整為224x224尺寸（與模型輸入保持一致）
      final resizedDisplayImage = img.copyResize(
        croppedImage,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      // 保存為臨時文件
      final tempDir = await getTemporaryDirectory();

      // 保存調試圖像（帶有ROI標記的完整圖像）
      final debugImageFile = io.File(
          '${tempDir.path}/debug_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await debugImageFile.writeAsBytes(img.encodeJpg(markedImage));

      // 保存裁剪並調整尺寸後的ROI
      final tempFile = io.File(
          '${tempDir.path}/display_roi_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(resizedDisplayImage));

      // 返回Flutter圖像Widget
      return Image.file(tempFile);
    } catch (e) {
      print('創建可顯示的ROI圖像失敗: $e');
      return null;
    }
  }

  // 從相機圖像中裁剪ROI並創建InputImage
  static Future<InputImage?> createROIInputImage(
      CameraImage cameraImage, Rect roi, CameraDescription camera,
      {Size? screenSize}) async {
    try {
      // 轉換為標準圖像格式
      final imgLib = await _convertCamToImage(cameraImage);
      if (imgLib == null) return null;

      // 使用傳入的螢幕尺寸或預設值
      final actualScreenWidth = screenSize?.width ?? 400.0;
      final actualScreenHeight = screenSize?.height ?? 800.0;

      // 保留原始圖像尺寸，不強制調整為螢幕尺寸，避免比例失真
      print('原始相機圖像尺寸: ${imgLib.width}x${imgLib.height}');
      print('螢幕尺寸: ${actualScreenWidth.toInt()}x${actualScreenHeight.toInt()}');
      print('ROI框尺寸 (UI坐標): ${roi.width}x${roi.height}');

      // 不調整圖像尺寸，保持原始比例
      img.Image originalImage = imgLib;

      // 根據相機旋轉調整圖像
      final rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      print('相機感測器方向: ${camera.sensorOrientation}度');
      img.Image rotatedImage = originalImage;

      if (rotation == InputImageRotation.rotation90deg) {
        rotatedImage = img.copyRotate(originalImage, angle: 90);
        print('圖像旋轉90度');
      } else if (rotation == InputImageRotation.rotation180deg) {
        rotatedImage = img.copyRotate(originalImage, angle: 180);
        print('圖像旋轉180度');
      } else if (rotation == InputImageRotation.rotation270deg) {
        rotatedImage = img.copyRotate(originalImage, angle: 270);
        print('圖像旋轉270度');
      }

      // 根據鏡頭方向進行水平翻轉
      if (camera.lensDirection == CameraLensDirection.front) {
        rotatedImage = img.flipHorizontal(rotatedImage);
        print('前置相機，進行水平翻轉');
      }

      print('旋轉翻轉後圖像尺寸: ${rotatedImage.width}x${rotatedImage.height}');

      // 計算統一的縮放比例，使用較小的比例來保持ROI框的原始長寬比
      double scaleX = rotatedImage.width / actualScreenWidth;
      double scaleY = rotatedImage.height / actualScreenHeight;

      // 使用統一的縮放比例來保持ROI框的原始比例
      double uniformScale = (scaleX + scaleY) / 2.0; // 使用平均值

      print('原始縮放比例: scaleX=$scaleX, scaleY=$scaleY');
      print('統一縮放比例: $uniformScale');

      // 使用統一縮放比例來定位ROI，保持原始比例
      final int roiX =
          (roi.left * uniformScale).toInt().clamp(0, rotatedImage.width - 1);
      final int roiY =
          (roi.top * uniformScale).toInt().clamp(0, rotatedImage.height - 1);
      final int roiWidth = (roi.width * uniformScale)
          .toInt()
          .clamp(1, rotatedImage.width - roiX);
      final int roiHeight = (roi.height * uniformScale)
          .toInt()
          .clamp(1, rotatedImage.height - roiY);

      // 裁剪ROI
      final croppedImage = img.copyCrop(
        rotatedImage,
        x: roiX,
        y: roiY,
        width: roiWidth,
        height: roiHeight,
      );

      // 將裁剪後的圖像調整為224x224尺寸（深度學習模型標準輸入尺寸）
      final resizedImage = img.copyResize(
        croppedImage,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      print(
          'ROI圖像調整: 原始尺寸 ${croppedImage.width}x${croppedImage.height} -> 224x224');

      // 保存為臨時文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = io.File(
          '${tempDir.path}/roi_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(resizedImage));

      // 創建InputImage
      return InputImage.fromFilePath(tempFile.path);
    } catch (e) {
      print('創建ROI輸入圖像失敗: $e');
      return null;
    }
  }

  // 將相機圖像轉換為彩色RGB圖像（非同步處理）
  static Future<img.Image?> _convertCamToImage(CameraImage cameraImage) async {
    try {
      if (cameraImage.planes.isEmpty) return null;

      // 檢查相機圖像格式並使用非同步處理
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        print('使用YUV420彩色轉換（非同步）');
        return await _convertYUV420ToRGBAsync(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.nv21) {
        print('使用NV21彩色轉換（非同步）');
        return await _convertNV21ToRGBAsync(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        print('使用BGRA8888彩色轉換（非同步，iOS格式）');
        return await _convertBGRA8888ToRGBAsync(cameraImage);
      } else {
        print('不支援的圖像格式: ${cameraImage.format.group}，使用灰度處理（非同步）');
        return await _convertToGrayscaleAsync(cameraImage);
      }
    } catch (e) {
      print('相機圖像轉換失敗: $e');
      return null;
    }
  }

  // BGRA8888非同步轉換方法
  static Future<img.Image?> _convertBGRA8888ToRGBAsync(
      CameraImage cameraImage) async {
    final params = _ImageConversionParams.fromCameraImage(cameraImage);
    return await compute(_convertBGRA8888ToRGBIsolate, params);
  }

  // NV21非同步轉換方法
  static Future<img.Image?> _convertNV21ToRGBAsync(
      CameraImage cameraImage) async {
    final params = _ImageConversionParams.fromCameraImage(cameraImage);
    return await compute(_convertNV21ToRGBIsolate, params);
  }

  // YUV420非同步轉換方法
  static Future<img.Image?> _convertYUV420ToRGBAsync(
      CameraImage cameraImage) async {
    final params = _ImageConversionParams.fromCameraImage(cameraImage);
    return await compute(_convertYUV420ToRGBIsolate, params);
  }

  // 灰度非同步轉換方法
  static Future<img.Image?> _convertToGrayscaleAsync(
      CameraImage cameraImage) async {
    final params = _ImageConversionParams.fromCameraImage(cameraImage);
    return await compute(_convertToGrayscaleIsolate, params);
  }

  // 將BGRA8888轉換為RGB彩色圖像 (iOS格式) - 保留原始同步版本作為備用
  static img.Image? _convertBGRA8888ToRGB(CameraImage cameraImage) {
    try {
      final width = cameraImage.width;
      final height = cameraImage.height;

      print('BGRA8888格式詳情: planes數量=${cameraImage.planes.length}');

      // BGRA8888格式通常只有一個平面，每個像素4個字節 (BGRA)
      if (cameraImage.planes.length < 1) {
        print('BGRA8888: 沒有足夠的平面數據');
        return null;
      }

      final plane = cameraImage.planes[0];
      final buffer = plane.bytes;
      final bytesPerRow = plane.bytesPerRow;

      print(
          'BGRA8888平面資訊: bytesPerRow=$bytesPerRow, buffer長度=${buffer.length}');
      print('計算的理論行寬: ${width * 4}, 實際行寬: $bytesPerRow');

      // 創建RGB圖像
      final image = img.Image(width: width, height: height);

      // BGRA8888格式：每個像素4個字節，順序為B-G-R-A
      // 注意：iOS的bytesPerRow可能包含填充字節
      for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
          // 使用bytesPerRow來計算每行的起始位置，避免填充字節問題
          final int rowStartIndex = row * bytesPerRow;
          final int pixelIndex = rowStartIndex + (col * 4);

          if (pixelIndex + 3 < buffer.length) {
            // BGRA順序讀取
            final int b = buffer[pixelIndex] & 0xFF; // Blue
            final int g = buffer[pixelIndex + 1] & 0xFF; // Green
            final int r = buffer[pixelIndex + 2] & 0xFF; // Red
            // Alpha 通道通常不使用: buffer[pixelIndex + 3]

            // 設置RGB像素值
            image.setPixelRgb(col, row, r, g, b);
          } else {
            // 如果索引超出範圍，設置為黑色
            print(
                '像素索引超出範圍: row=$row, col=$col, pixelIndex=$pixelIndex, bufferLength=${buffer.length}');
            image.setPixelRgb(col, row, 0, 0, 0);
          }
        }
      }

      print('BGRA8888轉RGB成功完成');
      return image;
    } catch (e) {
      print('BGRA8888轉RGB失敗: $e');
      // 如果轉換失敗，回退到灰度模式
      return _convertToGrayscale(cameraImage);
    }
  }

  // 將NV21轉換為RGB彩色圖像
  static img.Image? _convertNV21ToRGB(CameraImage cameraImage) {
    try {
      final width = cameraImage.width;
      final height = cameraImage.height;

      print('NV21格式詳情: planes數量=${cameraImage.planes.length}');

      // NV21格式通常只有一個平面，包含Y數據和交錯的VU數據
      if (cameraImage.planes.length < 1) {
        print('NV21: 沒有足夠的平面數據');
        return null;
      }

      final plane = cameraImage.planes[0];
      final buffer = plane.bytes;
      final bytesPerRow = plane.bytesPerRow;

      print('NV21平面資訊: bytesPerRow=$bytesPerRow, buffer長度=${buffer.length}');

      // 創建RGB圖像
      final image = img.Image(width: width, height: height);

      // 計算Y數據和UV數據的分界點
      final int ySize = width * height;
      final int uvStart = ySize; // UV數據從Y數據後開始

      // NV21轉RGB的計算
      for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
          // Y數據索引
          final int yIndex = row * width + col;

          // UV數據索引（每2x2像素共享一對UV值，且VU交錯）
          final int uvRow = row ~/ 2;
          final int uvCol = col ~/ 2;
          final int uvIndex =
              uvStart + (uvRow * width + uvCol * 2); // *2是因為VU交錯

          if (yIndex < buffer.length &&
              uvIndex + 1 < buffer.length &&
              yIndex < ySize) {
            // 獲取YUV值
            final int y = buffer[yIndex] & 0xFF;
            final int v = buffer[uvIndex] & 0xFF; // V在前
            final int u = buffer[uvIndex + 1] & 0xFF; // U在後

            // YUV轉RGB公式
            final int r = (y + 1.402 * (v - 128)).round().clamp(0, 255);
            final int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128))
                .round()
                .clamp(0, 255);
            final int b = (y + 1.772 * (u - 128)).round().clamp(0, 255);

            image.setPixelRgb(col, row, r, g, b);
          } else {
            // 如果索引超出範圍，使用灰度值
            if (yIndex < buffer.length) {
              final int gray = buffer[yIndex] & 0xFF;
              image.setPixelRgb(col, row, gray, gray, gray);
            }
          }
        }
      }

      print('NV21轉RGB成功完成');
      return image;
    } catch (e) {
      print('NV21轉RGB失敗: $e');
      // 如果轉換失敗，回退到灰度模式
      return _convertToGrayscale(cameraImage);
    }
  }

  // 將YUV420轉換為RGB彩色圖像
  static img.Image? _convertYUV420ToRGB(CameraImage cameraImage) {
    try {
      final width = cameraImage.width;
      final height = cameraImage.height;

      // 獲取YUV平面
      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];

      final yBuffer = yPlane.bytes;
      final uBuffer = uPlane.bytes;
      final vBuffer = vPlane.bytes;

      // 創建RGB圖像
      final image = img.Image(width: width, height: height);

      // YUV420轉RGB的計算
      for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
          final int yIndex = row * yPlane.bytesPerRow + col;

          // UV平面的索引計算（YUV420中UV是2x2子採樣）
          final int uvRow = row ~/ 2;
          final int uvCol = col ~/ 2;
          final int uvIndex =
              uvRow * uPlane.bytesPerRow + uvCol * (uPlane.bytesPerPixel ?? 1);

          if (yIndex < yBuffer.length &&
              uvIndex < uBuffer.length &&
              uvIndex < vBuffer.length) {
            // 獲取YUV值
            final int y = yBuffer[yIndex] & 0xFF;
            final int u = uBuffer[uvIndex] & 0xFF;
            final int v = vBuffer[uvIndex] & 0xFF;

            // YUV轉RGB公式
            final int r = (y + 1.402 * (v - 128)).round().clamp(0, 255);
            final int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128))
                .round()
                .clamp(0, 255);
            final int b = (y + 1.772 * (u - 128)).round().clamp(0, 255);

            image.setPixelRgb(col, row, r, g, b);
          }
        }
      }

      return image;
    } catch (e) {
      print('YUV420轉RGB失敗: $e');
      return null;
    }
  }

  // 備用的灰度轉換方法
  static img.Image? _convertToGrayscale(CameraImage cameraImage) {
    try {
      final width = cameraImage.width;
      final height = cameraImage.height;
      final yPlane = cameraImage.planes[0];
      final yBuffer = yPlane.bytes;

      // 創建灰度圖像
      final image = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yPlane.bytesPerRow + x;

          // 確保索引在有效範圍內
          if (yIndex < yBuffer.length) {
            final int gray = yBuffer[yIndex] & 0xFF;
            image.setPixelRgb(x, y, gray, gray, gray);
          }
        }
      }

      return image;
    } catch (e) {
      print('灰度轉換失敗: $e');
      return null;
    }
  }

  // 新增: iOS 專用的顯示 ROI 圖像方法 - 修正座標轉換
  static Future<Image?> createDisplayableROIImageForIOS(
      CameraImage cameraImage, Rect roi, CameraDescription camera,
      {Size? screenSize}) async {
    try {
      print('=== iOS 顯示用 ROI 圖像處理開始 ===');

      // 轉換為標準圖像格式
      final imgLib = await _convertCamToImage(cameraImage);
      if (imgLib == null) {
        print('iOS 顯示用 ROI 處理失敗: 圖像轉換返回 null');
        return null;
      }

      // 使用傳入的螢幕尺寸或預設值
      final actualScreenWidth = screenSize?.width ?? 400.0;
      final actualScreenHeight = screenSize?.height ?? 800.0;

      print('iOS 顯示用 - 轉換後圖像尺寸: ${imgLib.width}x${imgLib.height}');
      print(
          'iOS 顯示用 - 螢幕尺寸: ${actualScreenWidth.toInt()}x${actualScreenHeight.toInt()}');
      print(
          'iOS 顯示用 - 原始ROI框 (UI坐標): ${roi.left}, ${roi.top}, ${roi.width}x${roi.height}');

      img.Image processedImage = imgLib;

      // 根據相機感測器方向和鏡頭方向進行座標轉換
      final int sensorOrientation = camera.sensorOrientation;
      final bool isFrontCamera =
          camera.lensDirection == CameraLensDirection.front;

      print('iOS 顯示用 - 相機感測器方向: ${sensorOrientation}度, 前置相機: $isFrontCamera');

      // 根據 iOS 前置相機的特性進行處理
      if (isFrontCamera && sensorOrientation == 270) {
        // iOS 前置相機通常是 270 度，需要逆時針旋轉 90 度
        processedImage = img.copyRotate(imgLib, angle: -90);
        print('iOS 顯示用 - 前置相機逆時針旋轉90度');
      } else if (!isFrontCamera && sensorOrientation == 90) {
        // iOS 後置相機通常是 90 度，需要順時針旋轉 90 度
        processedImage = img.copyRotate(imgLib, angle: 90);
        print('iOS 顯示用 - 後置相機順時針旋轉90度');
      }

      // 前置相機需要水平翻轉
      if (isFrontCamera) {
        processedImage = img.flipHorizontal(processedImage);
        print('iOS 顯示用 - 前置相機水平翻轉');
      }

      print(
          'iOS 顯示用 - 處理後圖像尺寸: ${processedImage.width}x${processedImage.height}');

      // 計算正確的座標轉換
      // 對於 iOS 前置相機，需要特殊的座標映射
      double imageWidth = processedImage.width.toDouble();
      double imageHeight = processedImage.height.toDouble();

      // 計算縮放比例 - 考慮圖像可能被裁剪以適應螢幕比例
      double scaleX = imageWidth / actualScreenWidth;
      double scaleY = imageHeight / actualScreenHeight;

      // 使用較小的縮放比例以確保完整顯示
      double scale = math.min(scaleX, scaleY);

      print('iOS 顯示用 - 縮放比例: scaleX=$scaleX, scaleY=$scaleY, 選用=$scale');

      // 計算圖像在螢幕上的實際顯示區域
      double displayImageWidth = imageWidth / scale;
      double displayImageHeight = imageHeight / scale;

      // 計算圖像在螢幕上的偏移量（居中顯示）
      double offsetX = (actualScreenWidth - displayImageWidth) / 2;
      double offsetY = (actualScreenHeight - displayImageHeight) / 2;

      print('iOS 顯示用 - 圖像顯示區域: ${displayImageWidth}x$displayImageHeight');
      print('iOS 顯示用 - 圖像偏移量: offsetX=$offsetX, offsetY=$offsetY');

      // 將 UI 座標轉換為圖像座標
      double adjustedRoiLeft = (roi.left - offsetX) * scale;
      double adjustedRoiTop = (roi.top - offsetY) * scale;
      double adjustedRoiWidth = roi.width * scale;
      double adjustedRoiHeight = roi.height * scale;

      print(
          'iOS 顯示用 - 調整後ROI座標: left=$adjustedRoiLeft, top=$adjustedRoiTop, width=$adjustedRoiWidth, height=$adjustedRoiHeight');

      // 轉換為整數並確保在圖像邊界內
      final int roiX =
          adjustedRoiLeft.toInt().clamp(0, processedImage.width - 10);
      final int roiY =
          adjustedRoiTop.toInt().clamp(0, processedImage.height - 10);
      final int roiWidth =
          adjustedRoiWidth.toInt().clamp(10, processedImage.width - roiX);
      final int roiHeight =
          adjustedRoiHeight.toInt().clamp(10, processedImage.height - roiY);

      print(
          'iOS 顯示用 - 最終ROI整數座標: x=$roiX, y=$roiY, width=$roiWidth, height=$roiHeight');

      // 在圖像上標記ROI位置
      img.Image markedImage = img.Image.from(processedImage);
      _drawROIRectangle(markedImage, roiX, roiY, roiWidth, roiHeight);

      // 裁剪ROI
      final croppedImage = img.copyCrop(
        processedImage,
        x: roiX,
        y: roiY,
        width: roiWidth,
        height: roiHeight,
      );

      print('iOS 顯示用 - ROI 裁剪成功: ${croppedImage.width}x${croppedImage.height}');

      // 保存調試圖像
      final tempDir = await getTemporaryDirectory();

      // 保存帶標記的完整圖像
      final debugMarkedFile = io.File(
          '${tempDir.path}/ios_display_marked_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await debugMarkedFile.writeAsBytes(img.encodeJpg(markedImage));
      print('iOS 顯示用 - 標記圖像已保存至: ${debugMarkedFile.path}');

      // 保存裁剪後的ROI圖像
      final tempFile = io.File(
          '${tempDir.path}/ios_display_roi_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(croppedImage));
      print('iOS 顯示用 - ROI 圖像已保存至: ${tempFile.path}');

      return Image.file(
        tempFile,
        fit: BoxFit.cover,
      );
    } catch (e, stackTrace) {
      print('iOS 顯示用 ROI 處理失敗: $e');
      print('錯誤堆疊: $stackTrace');
      return null;
    }
  }

  // iOS 特定的 ROI 處理增強方法 - 修正座標轉換
  static Future<InputImage?> createROIInputImageForIOS(
      CameraImage cameraImage, Rect roi, CameraDescription camera,
      {Size? screenSize}) async {
    try {
      print('=== iOS ROI 處理開始 ===');
      print('相機圖像格式: ${cameraImage.format.group}');
      print('相機圖像尺寸: ${cameraImage.width}x${cameraImage.height}');
      print('平面數量: ${cameraImage.planes.length}');

      if (cameraImage.planes.isNotEmpty) {
        final plane = cameraImage.planes[0];
        print('第一個平面資訊:');
        print('  - bytesPerRow: ${plane.bytesPerRow}');
        print('  - bytesPerPixel: ${plane.bytesPerPixel}');
        print('  - buffer長度: ${plane.bytes.length}');
        print('  - 理論buffer長度: ${cameraImage.width * cameraImage.height * 4}');
      }

      // 轉換為標準圖像格式
      final imgLib = await _convertCamToImage(cameraImage);
      if (imgLib == null) {
        print('iOS ROI 處理失敗: 圖像轉換返回 null');
        return null;
      }

      print('轉換後圖像尺寸: ${imgLib.width}x${imgLib.height}');

      // 使用傳入的螢幕尺寸或預設值
      final actualScreenWidth = screenSize?.width ?? 400.0;
      final actualScreenHeight = screenSize?.height ?? 800.0;

      print('螢幕尺寸: ${actualScreenWidth.toInt()}x${actualScreenHeight.toInt()}');
      print('ROI框尺寸 (UI坐標): ${roi.width}x${roi.height}');
      print('ROI框位置 (UI坐標): (${roi.left}, ${roi.top})');

      img.Image processedImage = imgLib;

      // 根據相機感測器方向和鏡頭方向進行座標轉換
      final int sensorOrientation = camera.sensorOrientation;
      final bool isFrontCamera =
          camera.lensDirection == CameraLensDirection.front;

      print('相機感測器方向: ${sensorOrientation}度, 前置相機: $isFrontCamera');

      // 根據 iOS 前置相機的特性進行處理
      if (isFrontCamera && sensorOrientation == 270) {
        // iOS 前置相機通常是 270 度，需要逆時針旋轉 90 度
        processedImage = img.copyRotate(imgLib, angle: -90);
        print('前置相機逆時針旋轉90度');
      } else if (!isFrontCamera && sensorOrientation == 90) {
        // iOS 後置相機通常是 90 度，需要順時針旋轉 90 度
        processedImage = img.copyRotate(imgLib, angle: 90);
        print('後置相機順時針旋轉90度');
      }

      // 前置相機需要水平翻轉
      if (isFrontCamera) {
        processedImage = img.flipHorizontal(processedImage);
        print('前置相機水平翻轉');
      }

      print('處理後圖像尺寸: ${processedImage.width}x${processedImage.height}');

      // 計算正確的座標轉換
      double imageWidth = processedImage.width.toDouble();
      double imageHeight = processedImage.height.toDouble();

      // 計算縮放比例 - 考慮圖像可能被裁剪以適應螢幕比例
      double scaleX = imageWidth / actualScreenWidth;
      double scaleY = imageHeight / actualScreenHeight;

      // 使用較小的縮放比例以確保完整顯示
      double scale = math.min(scaleX, scaleY);

      print('縮放比例: scaleX=$scaleX, scaleY=$scaleY, 選用=$scale');

      // 計算圖像在螢幕上的實際顯示區域
      double displayImageWidth = imageWidth / scale;
      double displayImageHeight = imageHeight / scale;

      // 計算圖像在螢幕上的偏移量（居中顯示）
      double offsetX = (actualScreenWidth - displayImageWidth) / 2;
      double offsetY = (actualScreenHeight - displayImageHeight) / 2;

      print('圖像顯示區域: ${displayImageWidth}x$displayImageHeight');
      print('圖像偏移量: offsetX=$offsetX, offsetY=$offsetY');

      // 將 UI 座標轉換為圖像座標
      double adjustedRoiLeft = (roi.left - offsetX) * scale;
      double adjustedRoiTop = (roi.top - offsetY) * scale;
      double adjustedRoiWidth = roi.width * scale;
      double adjustedRoiHeight = roi.height * scale;

      print(
          '調整後ROI座標: left=$adjustedRoiLeft, top=$adjustedRoiTop, width=$adjustedRoiWidth, height=$adjustedRoiHeight');

      // 轉換為整數並確保在圖像邊界內
      final int roiX =
          adjustedRoiLeft.toInt().clamp(0, processedImage.width - 10);
      final int roiY =
          adjustedRoiTop.toInt().clamp(0, processedImage.height - 10);
      final int roiWidth =
          adjustedRoiWidth.toInt().clamp(10, processedImage.width - roiX);
      final int roiHeight =
          adjustedRoiHeight.toInt().clamp(10, processedImage.height - roiY);

      print('最終ROI整數座標: x=$roiX, y=$roiY, width=$roiWidth, height=$roiHeight');
      print(
          '圖像邊界檢查: 圖像=${processedImage.width}x${processedImage.height}, ROI右下角=(${roiX + roiWidth}, ${roiY + roiHeight})');

      // 安全性檢查
      if (roiX + roiWidth > processedImage.width ||
          roiY + roiHeight > processedImage.height ||
          roiWidth < 10 ||
          roiHeight < 10) {
        print('iOS ROI 警告: ROI 超出邊界或尺寸太小，使用中心區域');

        // 使用圖像中心的固定尺寸區域
        final int centerX = processedImage.width ~/ 2;
        final int centerY = processedImage.height ~/ 2;
        final int fallbackWidth = math.min(200, processedImage.width - 20);
        final int fallbackHeight = math.min(100, processedImage.height - 20);

        final int fallbackX = (centerX - fallbackWidth ~/ 2)
            .clamp(0, processedImage.width - fallbackWidth);
        final int fallbackY = (centerY - fallbackHeight ~/ 2)
            .clamp(0, processedImage.height - fallbackHeight);

        print(
            '使用備用ROI座標: x=$fallbackX, y=$fallbackY, width=$fallbackWidth, height=$fallbackHeight');

        final croppedImage = img.copyCrop(
          processedImage,
          x: fallbackX,
          y: fallbackY,
          width: fallbackWidth,
          height: fallbackHeight,
        );

        // 調整為224x224尺寸
        final resizedImage = img.copyResize(
          croppedImage,
          width: 224,
          height: 224,
          interpolation: img.Interpolation.linear,
        );

        // 保存調試圖像
        final tempDir = await getTemporaryDirectory();

        final tempFile = io.File(
            '${tempDir.path}/ios_roi_fallback_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(img.encodeJpg(resizedImage));

        print('iOS ROI 備用處理完成，圖像已保存: ${tempFile.path}');
        return InputImage.fromFilePath(tempFile.path);
      }

      // 正常裁剪流程
      final croppedImage = img.copyCrop(
        processedImage,
        x: roiX,
        y: roiY,
        width: roiWidth,
        height: roiHeight,
      );

      print('iOS ROI 正常裁剪成功: ${croppedImage.width}x${croppedImage.height}');

      // 調整為224x224尺寸
      final resizedImage = img.copyResize(
        croppedImage,
        width: 224,
        height: 224,
        interpolation: img.Interpolation.linear,
      );

      // 保存調試圖像
      final tempDir = await getTemporaryDirectory();

      // 保存原始處理圖像用於調試
      final debugOriginalFile = io.File(
          '${tempDir.path}/debug_ios_processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await debugOriginalFile.writeAsBytes(img.encodeJpg(processedImage));
      print('iOS 調試: 處理後圖像已保存至 ${debugOriginalFile.path}');

      // 在原圖上標記ROI位置
      img.Image markedImage = img.Image.from(processedImage);
      _drawROIRectangle(markedImage, roiX, roiY, roiWidth, roiHeight);

      final debugMarkedFile = io.File(
          '${tempDir.path}/debug_ios_marked_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await debugMarkedFile.writeAsBytes(img.encodeJpg(markedImage));
      print('iOS 調試: 標記圖像已保存至 ${debugMarkedFile.path}');

      final tempFile = io.File(
          '${tempDir.path}/ios_roi_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(resizedImage));

      print('iOS ROI 圖像已保存: ${tempFile.path}');
      return InputImage.fromFilePath(tempFile.path);
    } catch (e, stackTrace) {
      print('iOS ROI 處理失敗: $e');
      print('堆疊追蹤: $stackTrace');
      return null;
    }
  }

  // 新增: 在圖像上繪製ROI矩形的輔助方法
  static void _drawROIRectangle(
      img.Image image, int x, int y, int width, int height) {
    try {
      // 繪製紅色邊框
      final red = img.ColorRgb8(255, 0, 0);

      // 繪製上邊框
      for (int i = x; i < x + width && i < image.width; i++) {
        if (y >= 0 && y < image.height) {
          image.setPixel(i, y, red);
        }
      }

      // 繪製下邊框
      for (int i = x; i < x + width && i < image.width; i++) {
        int bottomY = y + height - 1;
        if (bottomY >= 0 && bottomY < image.height) {
          image.setPixel(i, bottomY, red);
        }
      }

      // 繪製左邊框
      for (int i = y; i < y + height && i < image.height; i++) {
        if (x >= 0 && x < image.width) {
          image.setPixel(x, i, red);
        }
      }

      // 繪製右邊框
      for (int i = y; i < y + height && i < image.height; i++) {
        int rightX = x + width - 1;
        if (rightX >= 0 && rightX < image.width) {
          image.setPixel(rightX, i, red);
        }
      }
    } catch (e) {
      print('繪製ROI矩形時出錯: $e');
    }
  }
}
