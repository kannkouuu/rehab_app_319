import 'dart:async';
import 'dart:io' as io;
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../main.dart';
import '../../trainmouth/trainmouth_widget.dart';
import '../../vision_detector_views/label_detector_view/camera_view_roi.dart';
import '../../vision_detector_views/label_detector_view/painters/label_detector_painter_ROI.dart';
import '../../vision_detector_views/label_detector_view/roi_processor.dart'; // 引入ROI處理器
import 'package:audioplayers/audioplayers.dart'; //播放音檔
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 繪製ROI框的Painter
class ROIPainter extends CustomPainter {
  final Rect roi;

  ROIPainter(this.roi);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(roi, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class tongue_depresser extends StatefulWidget {
  @override
  State<tongue_depresser> createState() => _ImageLabelViewState();
}

class _ImageLabelViewState extends State<tongue_depresser> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  late ImageLabeler _imageLabeler;
  late ImageLabeler _secondImageLabeler; // 第二個模型的標籤檢測器
  bool _canProcess = false;
  bool _isBusy = false;
  Detector_tongue_depresser smile = Detector_tongue_depresser();
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;

  // 存儲最新的相機圖像和相機描述
  CameraImage? _lastCameraImage;
  CameraDescription? _cameraDescription;

  // 用於存儲當前螢幕尺寸
  Size? _cachedScreenSize;

  // 標記是否是第一次構建
  bool _isFirstBuild = true;

  // 獲取調整後的ROI矩形 - 統一的ROI框定義方法
  Rect getAdjustedRoiRect(Size screenSize) {
    return Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height * 0.6),
      width: 300,
      height: 150,
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeLabeler();
  }

  @override
  void dispose() {
    _canProcess = false;
    _imageLabeler.close();
    _secondImageLabeler.close(); // 關閉第二個模型
    smile.TimerBool = false; //關閉timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 獲取當前UI上下文的螢幕尺寸
    final screenSize = MediaQuery.of(context).size;

    // 更新緩存的螢幕尺寸
    _cachedScreenSize = screenSize;

    // 如果是第一次構建，初始化ROI矩形
    if (_isFirstBuild) {
      _isFirstBuild = false;
      // 延遲更新ROI矩形，確保在下一幀可用
      Future.microtask(() {
        if (mounted) {
          setState(() {
            // 延遲更新ROI矩形，確保在下一幀可用
          });
        }
      });
    }

    // 使用當前屏幕尺寸調整ROI矩形位置
    final adjustedRoiRect = getAdjustedRoiRect(screenSize);

    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: <Widget>[
        CameraView(
          title: 'Image Labeler',
          customPaint: _customPaint,
          text: _text,
          onImage: processImage,
          onCameraImage: (cameraImage) async {
            // 儲存最新的相機圖像以便處理ROI
            _lastCameraImage = cameraImage;
            if (_cameraDescription == null) {
              _cameraDescription = await _findCamera();
            }
          },
        ),
        // 畫出ROI框
        CustomPaint(
          painter: ROIPainter(adjustedRoiRect),
        ),

        if (!smile.ChangeUI) ...[
          Positioned(
              //倒數計時
              top: 180,
              child: Container(
                height: 120,
                width: 100,
                child: AutoSizeText(
                  "${smile.TimerText}",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    backgroundColor: Colors.transparent,
                    fontSize: 100,
                    color: Colors.amber,
                    inherit: false,
                  ),
                ),
              )),
          Positioned(
            //開始前提醒視窗
            bottom: 100.0,
            child: Container(
              width: 1000,
              padding: EdgeInsets.all(10),
              alignment: Alignment.center,
              decoration: new BoxDecoration(
                color: Color.fromARGB(132, 255, 255, 255),
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
              ),
              child: AutoSizeText(
                smile.StartRemindText,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: TextStyle(
                  backgroundColor: Colors.transparent,
                  fontSize: 25,
                  color: Colors.black,
                  height: 1.2,
                  inherit: false,
                ),
              ),
            ),
          ).animate().slide(duration: 500.ms),
          if (smile.buttom_false)
            Positioned(
                //復健按鈕
                bottom: 15.0,
                child: Container(
                  height: 80,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                      padding: EdgeInsets.all(15),
                      backgroundColor: Color.fromARGB(250, 255, 190, 52),
                    ),
                    child: AutoSizeText("Start!",
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 35,
                          color: Colors.white,
                        )),
                    onPressed: () {
                      smile.Started();
                    },
                  ),
                )).animate().slide(duration: 500.ms),
        ] else if (!smile.EndDetector) ...[
          Positioned(
              //表情emoji
              bottom: 15.0,
              child: Container(
                height: 1300,
                child: Image(
                    width: 100, height: 100, image: AssetImage(smile.faceImg)),
              )).animate().slide(duration: 500.ms),
          Positioned(
            //計數器UI
            bottom: 10,
            right: -10,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: new BoxDecoration(
                color: Color.fromARGB(250, 65, 64, 64),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(20),
                  right: Radius.circular(0),
                ),
              ),
              width: 100,
              height: 90,
              child: AutoSizeText(
                "次數\n${smile.FinishCounter}/${smile.FinishTarget}",
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  color: Color.fromARGB(250, 255, 190, 52),
                  height: 1.2,
                  inherit: false,
                ),
              ),
            ),
          ),
          if (smile.timerui)
            Positioned(
              //計時器UI
              bottom: 10,
              left: -10,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: new BoxDecoration(
                  color: Color.fromARGB(250, 65, 64, 64),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(0),
                    right: Radius.circular(20),
                  ),
                ),
                width: 100,
                height: 90,
                child: AutoSizeText(
                  "秒數\n${smile.FaceTimeCounter}/${smile.FaceTimeTarget}",
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 25,
                    color: Color.fromARGB(250, 255, 190, 52),
                    height: 1.2,
                    inherit: false,
                  ),
                ),
              ),
            ),
          Positioned(
            //提醒視窗
            bottom: 100,
            child: Container(
              padding: EdgeInsets.all(30),
              decoration: new BoxDecoration(
                color: Color.fromARGB(127, 65, 64, 64),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(30),
                  right: Radius.circular(30),
                ),
              ),
              width: 220,
              height: 100,
              child: AutoSizeText(
                "${smile.TargetRemind}",
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  height: 1.2,
                  inherit: false,
                ),
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scaleXY(end: 1.2, duration: 0.2.seconds),
        ],
        if (smile.EndDetector)
          Positioned(
            //退出視窗
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: new BoxDecoration(
                    color: Color.fromARGB(200, 65, 64, 64),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  width: 300,
                  height: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AutoSizeText(
                        "恭喜完成!!",
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 50,
                          color: Colors.white,
                          inherit: false,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                          padding: EdgeInsets.all(15),
                          backgroundColor: Color.fromARGB(250, 255, 190, 52),
                        ),
                        child: AutoSizeText(
                          "返回",
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          endout14();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ).animate().slide(duration: 500.ms),
      ],
    );
  }

  void _initializeLabeler() async {
    // 初始化第一個模型
    final path = 'assets/ml/pursed_lips.tflite';
    final modelPath = await _getModel(path);
    final options = LocalLabelerOptions(modelPath: modelPath);
    _imageLabeler = ImageLabeler(options: options);

    // 初始化第二個模型
    final secondPath = 'assets/ml/pursed_v3.tflite';
    final secondModelPath = await _getModel(secondPath);
    final secondOptions = LocalLabelerOptions(modelPath: secondModelPath);
    _secondImageLabeler = ImageLabeler(options: secondOptions);

    _canProcess = true;
  }

  // 找到相機描述
  Future<CameraDescription?> _findCamera() async {
    try {
      for (var camera in cameras) {
        if (camera.lensDirection == _cameraLensDirection) {
          return camera;
        }
      }
      return cameras.isNotEmpty ? cameras[0] : null;
    } catch (e) {
      print('查找相機失敗: $e');
      return null;
    }
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });

    // 使用緩存的螢幕尺寸，避免直接訪問BuildContext
    final screenSize = _cachedScreenSize ?? Size(400, 800);

    // 使用屏幕尺寸調整ROI矩形位置
    final adjustedRoiRect = getAdjustedRoiRect(screenSize);

    // 處理整個圖像的標籤
    final labels = await _imageLabeler.processImage(inputImage);
    final faces = await _faceDetector.processImage(inputImage);

    // 處理第二個模型 (ROI內的圖像)
    final secondModelLabels = await processROI(inputImage);

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = LabelDetectorPainter(
        labels,
        faces,
        inputImage.metadata!.rotation,
        inputImage.metadata!.size,
        _cameraLensDirection,
        adjustedRoiRect, // 使用調整後的ROI框
        secondModelLabels, // 傳遞第二個模型的結果
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Labels found: ${labels.length}\n\n';
      for (final label in labels) {
        text += 'Label: ${label.label}, '
            'Confidence: ${label.confidence.toStringAsFixed(2)}\n\n';
      }

      text += 'ROI Labels: ${secondModelLabels.length}\n\n';
      for (final label in secondModelLabels) {
        text += 'ROI Label: ${label.label}, '
            'Confidence: ${label.confidence.toStringAsFixed(2)}\n\n';
      }

      _text = text;
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {
        // 更新ROI矩形
        // roiRect = adjustedRoiRect;
      });
    }
  }

  // 處理ROI內的圖像
  Future<List<ImageLabel>> processROI(InputImage inputImage) async {
    try {
      // 檢查是否有影像大小和旋轉資訊
      if (inputImage.metadata?.size == null ||
          inputImage.metadata?.rotation == null) {
        return [];
      }

      // 如果是來自相機的輸入，嘗試使用相機圖像處理ROI
      if (inputImage.type == InputImageType.bytes &&
          _lastCameraImage != null &&
          _cameraDescription != null) {
        // 使用緩存的螢幕尺寸，避免直接訪問BuildContext
        final screenSize = _cachedScreenSize ?? Size(400, 800);

        // 使用屏幕尺寸調整ROI矩形位置
        final adjustedRoiRect = getAdjustedRoiRect(screenSize);

        InputImage? roiInputImage;

        // 根據平台選擇合適的處理方法
        if (io.Platform.isIOS) {
          print('使用 iOS 特定的 ROI 處理方法');
          // 使用 iOS 特定的 ROI 處理器
          roiInputImage = await ROIProcessor.createROIInputImageForIOS(
            _lastCameraImage!,
            adjustedRoiRect,
            _cameraDescription!,
            screenSize: screenSize,
          );
        } else {
          print('使用通用的 ROI 處理方法');
          // 使用通用的 ROI 處理器
          roiInputImage = await ROIProcessor.createROIInputImage(
            _lastCameraImage!,
            adjustedRoiRect,
            _cameraDescription!,
            screenSize: screenSize,
          );
        }

        // 如果成功處理ROI，使用第二個模型處理ROI圖像
        if (roiInputImage != null) {
          final result = await _secondImageLabeler.processImage(roiInputImage);
          print(
              'ROI 模型檢測結果: ${result.map((e) => '${e.label}(${e.confidence.toStringAsFixed(2)})').join(', ')}');
          return result;
        } else {
          print('ROI 處理失敗，返回空結果');
          return [];
        }
      }

      // 如果無法處理ROI，回退到處理整個圖像
      print('回退到處理整個圖像');
      return await _secondImageLabeler.processImage(inputImage);
    } catch (e) {
      print('處理ROI時出錯: $e');
      return [];
    }
  }

  Future<String> _getModel(String assetPath) async {
    //取得模型
    if (io.Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(dirname(path)).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }
}

class Detector_tongue_depresser {
  int FaceTimeCounter = 0; //復健動作持續秒數
  int FaceTimeTarget = 30; //復健動作秒數目標
  int FinishCounter = 0; //復健動作實作次數
  int FinishTarget = 5; //復健動作實作次數目標
  bool StartedDetector = false; //偵測
  bool EndDetector = false; //跳轉
  bool TimerBool = true; //倒數計時器
  bool ChangeUI = false; //改變UI介面
  bool DetectReset = false; //復歸判定
  bool buttom_false = true; //按下按鈕消失
  bool timerui = true;
  bool DetectorED = false;

  // 添加狀態維持相關變數，為每個模型分別設置時間戳
  String lastDetectResult = '';
  String lastSecondModelResult = '';
  DateTime? lastDetectTime1; // 第一個模型的時間戳
  DateTime? lastDetectTime2; // 第二個模型的時間戳
  int stateHoldDuration = 500; // 狀態維持時間，單位毫秒

  // 添加第二個模型 'non' 檢測的延遲重置機制
  DateTime? firstNonDetectionTime; // 首次檢測到 'non' 的時間
  int nonDetectionDelay = 3000; // 'non' 檢測延遲時間，3秒（毫秒）
  bool shouldResetCounter = false; // 是否應該重置計時器

  String TargetRemind = '請抿嘴壓筆\n將筆移到綠框內'; //目標提醒
  String TimerText = ''; //倒數文字
  String StartRemindText = '請將臉部拍攝於畫面內\n並維持鏡頭穩定\n準備完成請按「Start」';
  String TargetText = 'pursed_lips'; //目標特徵
  String SecondTargetExclusion = 'non'; // 第二個模型排除的特徵，任何不是'non'的結果都視為有效
  String faceImg = 'assets/images/non.png';
  final AudioCache player = AudioCache();
  final AudioPlayer _audioPlayer = AudioPlayer(); //撥放音檔
  String _languagePreference = 'chinese'; // 預設為中文

  Future<void> initialize() async {
    await _loadLanguagePreference();
  }

  // 從 SharedPreferences 載入語言偏好設定
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _languagePreference = prefs.getString('language_preference') ?? 'chinese';
  }

  // 獲取音頻目錄路徑
  String getAudioPath() {
    // 根據語言偏好選擇目錄
    if (_languagePreference == 'taiwanese') {
      return 'taigi_pose_audios'; // 台語
    } else {
      return 'pose_audios'; // 預設中文
    }
  }

  String getAudioDataForm() {
    // 根據語言偏好選擇目錄
    if (_languagePreference == 'taiwanese') {
      return 'wav'; // 台語
    } else {
      return 'mp3'; // 預設中文
    }
  }

  // 取得真正的檢測結果（考慮狀態維持）
  String getStableDetectResult() {
    // 如果當前結果是目標特徵，直接返回
    if (DetectResult == TargetText) {
      lastDetectResult = TargetText;
      lastDetectTime1 = DateTime.now();
      return TargetText;
    }

    // 如果之前檢測到目標特徵，且在維持時間內，繼續返回目標特徵
    if (lastDetectResult == TargetText && lastDetectTime1 != null) {
      final currentTime = DateTime.now();
      final difference =
          currentTime.difference(lastDetectTime1!).inMilliseconds;

      if (difference < stateHoldDuration) {
        print("第一個模型狀態維持中: ${lastDetectResult}");
        return TargetText;
      }
    }

    // 否則返回當前實際檢測到的結果
    lastDetectResult = DetectResult;
    lastDetectTime1 = DateTime.now();
    return DetectResult;
  }

  // 取得第二個模型的穩定結果（考慮延遲重置機制）
  String getStableSecondModelResult() {
    final currentTime = DateTime.now();

    // 如果當前結果不是排除的特徵
    if (SecondModelResult != SecondTargetExclusion) {
      lastSecondModelResult = SecondModelResult;
      lastDetectTime2 = currentTime;
      // 重置 'non' 檢測相關狀態
      firstNonDetectionTime = null;
      shouldResetCounter = false;
      return SecondModelResult;
    }

    // 如果當前檢測到 'non'
    if (SecondModelResult == SecondTargetExclusion) {
      // 如果這是第一次檢測到 'non'，記錄時間
      if (firstNonDetectionTime == null) {
        firstNonDetectionTime = currentTime;
        print("第二個模型首次檢測到 'non'，開始 3 秒延遲計時");
      } else {
        // 檢查是否已經超過延遲時間
        final timeSinceFirstNon =
            currentTime.difference(firstNonDetectionTime!).inMilliseconds;
        if (timeSinceFirstNon >= nonDetectionDelay) {
          shouldResetCounter = true;
          print("第二個模型 'non' 檢測延遲時間已到，標記需要重置計時器");
        }
      }
    }

    // 如果之前檢測到有效特徵，且在維持時間內，繼續返回該特徵
    if (lastSecondModelResult != SecondTargetExclusion &&
        lastDetectTime2 != null) {
      final difference =
          currentTime.difference(lastDetectTime2!).inMilliseconds;

      if (difference < stateHoldDuration) {
        print("第二個模型狀態維持中: ${lastSecondModelResult}");
        return lastSecondModelResult;
      }
    }

    // 否則返回當前實際檢測到的結果
    lastSecondModelResult = SecondModelResult;
    lastDetectTime2 = currentTime;
    return SecondModelResult;
  }

  void FaceDetector() {
    //偵測判定
    // 獲取穩定的檢測結果
    final stableDetectResult = getStableDetectResult();
    final stableSecondModelResult = getStableSecondModelResult();

    if (this.StartedDetector) {
      DetectorED = true;
      this.TargetRemind = "請抿嘴壓筆到綠框內";

      // 打印當前的偵測結果，用於調試
      print("raw - 第一個模型: ${DetectResult}, 第二個模型: ${SecondModelResult}");
      print(
          "stable - 第一個模型: ${stableDetectResult}, 第二個模型: ${stableSecondModelResult}");

      if (stableDetectResult != TargetText ||
          stableSecondModelResult == SecondTargetExclusion) {
        faceImg = 'assets/images/non.png';
      }

      if (this.FaceTimeCounter == this.FaceTimeTarget) {
        //秒數達成
        this.StartedDetector = false;
        this.FinishCounter++;
        this.FaceTimeCounter = 0;
        this.TargetRemind = "達標!";
        this.sounder(this.FinishCounter);
      }

      // 確保兩個模型都檢測到目標時才增加計數
      if (stableDetectResult == TargetText &&
          stableSecondModelResult != SecondTargetExclusion &&
          this.StartedDetector) {
        //每秒目標
        this.FaceTimeCounter++;
        print(
            "同時滿足條件! 第一個模型: ${stableDetectResult}, 第二個模型: ${stableSecondModelResult}");
        print("計時器: ${this.FaceTimeCounter}");
        this.TargetRemind = "請保持住!";
      } else {
        // 檢查是否需要重置計時器（基於延遲機制）
        if (shouldResetCounter || stableDetectResult != TargetText) {
          // 重置計時器
          this.FaceTimeCounter = 0;

          // 重置延遲標記
          if (shouldResetCounter) {
            shouldResetCounter = false;
            firstNonDetectionTime = null;
            print("延遲重置: 計時器歸零（3秒後）");
          }
        }

        // 打印不滿足條件的原因
        if (stableDetectResult != TargetText) {
          print("不滿足條件: 第一個模型 ${stableDetectResult} != ${TargetText}");
        }
        if (stableSecondModelResult == SecondTargetExclusion) {
          if (firstNonDetectionTime != null && !shouldResetCounter) {
            final elapsed = DateTime.now()
                .difference(firstNonDetectionTime!)
                .inMilliseconds;
            final remaining = (nonDetectionDelay - elapsed) / 1000;
            print("檢測到 'non'，延遲重置中... 剩餘 ${remaining.toStringAsFixed(1)} 秒");
          } else {
            print(
                "不滿足條件: 第二個模型檢測到排除特徵 ${stableSecondModelResult} == ${SecondTargetExclusion}");
          }
        }
      }
    } else if (DetectorED) {
      //預防空值被訪問
      if (stableDetectResult != TargetText ||
          stableSecondModelResult == SecondTargetExclusion) {
        //確認復歸
        this.StartedDetector = true;

        // 重置延遲機制相關狀態
        firstNonDetectionTime = null;
        shouldResetCounter = false;
      } else {
        this.TargetRemind = "請放鬆";
      }
    }
  }

  void FaceTargetDone() {
    //完成任務後發出退出信號
    if (this.FinishCounter == this.FinishTarget) {
      this.EndDetector = true;
    }
  }

  void SetTimer() {
    Timer.periodic(
      //觸發偵測timer
      const Duration(seconds: 1),
      (timer) {
        FaceDetector(); //偵測目標是否完成動作
        FaceTargetDone(); //偵測目標是否完成指定次數
        if (!this.TimerBool) {
          print("cancel timer");
          timer.cancel();
        }
      },
    );
  }

  void StartDetect() {
    ChangeUI = true;
    StartedDetector = true;
    print('Start Detector is true');
    SetTimer();
  }

  void Started() {
    int Number = 5;
    buttom_false = false;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      TimerText = "${Number--}";
      if (Number < 0) {
        print("cancel timer");
        timer.cancel();
        TimerText = " ";
        StartDetect();
      }
    });
  }

  Future<void> sounder(int counter) async {
    await _loadLanguagePreference(); // 確保獲取最新設定
    String audioPath = '${getAudioPath()}/${counter}.${getAudioDataForm()}';
    await _audioPlayer.play(AssetSource(audioPath));
  }
}

Future<void> endout14() async {
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd').format(now);
  var url;
  if (Face_Detect_Number == 14) {
    //抿嘴
    url = Uri.parse(ip + "train_mouthok.php");
    print("初階,吞嚥");
  }
  final responce = await http.post(url, body: {
    "time": formattedDate,
    "account": FFAppState().accountnumber.toString(),
    "action": "抿壓舌板", //動作
    "degree": "初階",
    "parts": "吞嚥",
    "times": "1", //動作
    "coin_add": "5",
  });
  if (responce.statusCode == 200) {
    print("ok");
  } else {
    print(responce.statusCode);
    print("no");
  }
}
