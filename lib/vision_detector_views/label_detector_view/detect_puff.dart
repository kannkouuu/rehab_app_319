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
import 'camera_view.dart';
import 'painters/label_detector_painter.dart';
import 'package:audioplayers/audioplayers.dart'; //播放音檔
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

//
//                       _oo0oo_
//                      o8888888o
//                      88" . "88
//                      (| -_- |)
//                      0\  =  /0
//                    ___/`---'\___
//                  .' \\|     |// '.
//                 / \\|||  :  |||// \
//                / _||||| -:- |||||- \
//               |   | \\\  -  /// |   |
//               | \_|  ''\---/''  |_/ |
//               \  .-\__  '-'  ___/-. /
//             ___'. .'  /--.--\  `. .'___
//          ."" '<  `.___\_<|>_/___.' >' "".
//         | | :  `- \`.;`\ _ /`;.`/ - ` : | |
//         \  \ `_.   \_ __\ /__ _/   .-` /  /
//     =====`-.____`.___ \_____/___.-`___.-'=====
//                       `=---='
//
//
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                 菩提本無樹   明鏡亦非台
//                 本来無BUG   何必常修改
//
// import 'painters/face_detector_painter.dart';
// from tflite_support import flatbuffers
// from tflite_support import metadata as _metadata
// from tflite_support import metadata_schema_py_generated as _metadata_fb
//
// """ ... """
// """Creates the metadata for an image classifier."""
//
// # Creates model info.
// model_meta = _metadata_fb.ModelMetadataT()
// model_meta.name = "MobileNetV1 image classifier"
// model_meta.description = ("Identify the most prominent object in the "
// "image from a set of 1,001 categories such as "
// "trees, animals, food, vehicles, person etc.")
// model_meta.version = "v1"
// model_meta.author = "TensorFlow"
// model_meta.license = ("Apache License. Version 2.0 "
// "http://www.apache.org/licenses/LICENSE-2.0.")

class puff extends StatefulWidget {
  @override
  State<puff> createState() => _ImageLabelViewState();
}

class _ImageLabelViewState extends State<puff> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );

  late ImageLabeler _imageLabeler;
  bool _canProcess = false;
  bool _isBusy = false;
  Detector_Puff smile = Detector_Puff();
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    _initializeLabeler();
    // 初始化語言偏好設定
    smile.initialize();
  }

  @override
  void dispose() {
    _canProcess = false;
    _imageLabeler.close();
    _faceDetector.close();
    smile.TimerBool = false; //關閉timer
    smile.stopAudio(); //停止音訊播放
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: <Widget>[
        CameraView(
          title: 'Image Labeler',
          customPaint: _customPaint,
          text: _text,
          onImage: processImage,
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
                color: Color.fromARGB(250, 65, 64, 64),
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
                          endout13();
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
    // uncomment next line if you want to use the default model
    // _imageLabeler = ImageLabeler(options: ImageLabelerOptions());

    // uncomment next lines if you want to use a local model
    // make sure to add tflite model to assets/ml
    // final path = 'assets/ml/PUFF.tflite';
    final path = 'assets/ml/PUFFv2.tflite';
    final modelPath = await _getModel(path);
    final options = LocalLabelerOptions(modelPath: modelPath);
    print("init");
    _imageLabeler = ImageLabeler(options: options);

    // uncomment next lines if you want to use a remote model
    // make sure to add model to firebase
    // final modelName = 'bird-classifier';
    // final response =
    //     await FirebaseImageLabelerModelManager().downloadModel(modelName);
    // print('Downloaded: $response');
    // final options =
    //     FirebaseLabelerOption(confidenceThreshold: 0.5, modelName: modelName);
    // _imageLabeler = ImageLabeler(options: options);

    _canProcess = true;
  }

  Future<void> processImage(InputImage inputImage) async {
    //顯示label與閥值
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final labels = await _imageLabeler.processImage(inputImage);
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = LabelDetectorPainter(
        labels,
        faces,
        inputImage.metadata!.rotation,
        inputImage.metadata!.size,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Labels found: ${labels.length}\n\n';
      for (final label in labels) {
        text += 'Label: ${label.label}, '
            'Confidence: ${label.confidence.toStringAsFixed(2)}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
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
    print("mode get");
    return file.path;
  }
}

class Detector_Puff {
  int FaceTimeCounter = 0; //復健動作持續秒數
  int FaceTimeTarget = 10; //復健動作秒數目標
  int FinishCounter = 0; //復健動作實作次數
  int FinishTarget = 10; //復健動作實作次數目標
  bool StartedDetector = false; //偵測
  bool EndDetector = false; //跳轉
  bool TimerBool = true; //倒數計時器
  bool ChangeUI = false; //改變UI介面
  bool DetectReset = false; //復歸判定
  bool buttom_false = true; //按下按鈕消失
  bool timerui = true;
  bool DetectorED = false;
  bool sound = true;
  String TargetRemind = '請保持臉頰鼓起'; //目標提醒
  String TimerText = ''; //倒數文字
  String StartRemindText = '請將臉部拍攝於畫面內\n並維持鏡頭穩定\n準備完成請按「Start」';
  String TargetText = 'puff'; //目標特徵
  String faceImg = 'assets/images/non.png'; //目標特徵
  final AudioCache player = AudioCache();
  final AudioPlayer _audioPlayer = AudioPlayer(); //撥放音檔
  String _languagePreference = 'chinese'; // 預設為中文
  bool _isLanguageLoaded = false; // 新增：標記語言是否已載入

  Future<void> initialize() async {
    await _loadLanguagePreference();
    _isLanguageLoaded = true; // 標記語言已載入
  }

  // 從 SharedPreferences 載入語言偏好設定
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _languagePreference = prefs.getString('language_preference') ?? 'chinese';
  }

  // 確保語言偏好設定已載入的方法
  Future<void> _ensureLanguageLoaded() async {
    if (!_isLanguageLoaded) {
      await _loadLanguagePreference();
      _isLanguageLoaded = true;
    }
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
    if (_languagePreference == 'taiwanese') {
      return 'wav'; // 台語
    } else {
      return 'mp3'; // 預設中文
    }
  }

  void FaceDetector() {
    _loadLanguagePreference();
    //偵測判定
    if (this.StartedDetector) {
      DetectorED = true;
      this.TargetRemind = "請保持臉頰鼓起";
      if (DetectResult != TargetText) {
        faceImg = 'assets/images/non.png';
      } else {
        faceImg = 'assets/images/${DetectResult}.png';
      }
      if (this.FaceTimeCounter == this.FaceTimeTarget) {
        //秒數達成
        this.StartedDetector = false;
        this.FinishCounter++;
        this.FaceTimeCounter = 0;
        this.TargetRemind = "達標!";
        this.sounder(this.FinishCounter);
        sound = false;
      }
      if (DetectResult == 'puff' && this.StartedDetector) {
        //每秒目標
        // faceImg = 'assets/images/puff.png';
        this.FaceTimeCounter++;
        print(this.FaceTimeCounter);
        this.TargetRemind = "請保持住!";
        sound = true;
      } else {
        //沒有保持
        // faceImg = 'assets/images/non.png';
        this.FaceTimeCounter = 0;
        this.sounder(999);
      }
    } else if (DetectorED) {
      //預防空值被訪問
      if (DetectResult != 'puff') {
        //確認復歸
        // faceImg = 'assets/images/non.png';
        this.StartedDetector = true;
      } else {
        this.TargetRemind = "請回復上一步";
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
    sound = true;
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

  void sounder(int counter) async {
    await _ensureLanguageLoaded(); // 確保語言設定已載入
    if (counter == 999 && sound) {
      if (getAudioPath() == "pose_audios") {
        await _audioPlayer.play(AssetSource('audios/keepPuff.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('audios/taigi_keepPuff.wav'));
      }
      sound = false;
    } else {
      String audioPath = '${getAudioPath()}/${counter}.${getAudioDataForm()}';
      await _audioPlayer.play(AssetSource(audioPath));
    }
  }

  // 停止音訊播放
  void stopAudio() {
    _audioPlayer.stop();
  }
}

Future<void> endout13() async {
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd').format(now);
  var url;
  if (Face_Detect_Number == 13) {
    //微笑
    url = Uri.parse(ip + "train_mouthok.php");
    print("初階,吞嚥");
  }
  final responce = await http.post(url, body: {
    "time": formattedDate,
    "account": FFAppState().accountnumber.toString(),
    "action": FFAppState().mouth.toString(), //動作
    "degree": "初階",
    "parts": "吞嚥",
    "times": "1", //動作次數 會累加
    "coin_add": "5",
  });
  if (responce.statusCode == 200) {
    print("ok");
  } else {
    print(responce.statusCode);
    print("no");
  }
}
