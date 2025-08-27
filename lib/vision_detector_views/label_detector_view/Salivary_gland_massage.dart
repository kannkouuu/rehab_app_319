import 'dart:async';
import 'dart:math';
import '../body_view/assembly.dart';
import 'package:audioplayers/audioplayers.dart'; //播放音檔
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../app_state.dart';
import '../../trainmouth/trainmouth_widget.dart';
import '../camera_view.dart';
import '../painters/pose_painter.dart';
import 'package:http/http.dart' as http;
import '/main.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Salivary_gland_massage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<Salivary_gland_massage> {
  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  salivary_gland_massage Det = salivary_gland_massage();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _canProcess = false;
    _poseDetector.close();
    Det.posecounter = 0; // 使用 Det 物件的 posecounter 屬性
    // Det.stopReminder();
    // Det.stopReminder2();
    posedata.clear(); // 清空 pose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: <Widget>[
        CameraView(
          //相機view
          title: 'Pose',
          customPaint: _customPaint,
          text: _text,
          onImage: (inputImage) {
            processImage(inputImage);
          },
        ),
        Positioned(
          // 顎下腺動作提示 - 螢幕高度10%位置
          top: MediaQuery.of(context).size.height * 0.1,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Color.fromARGB(200, 255, 190, 52),
              borderRadius: BorderRadius.all(Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: AutoSizeText(
              "請做顎下腺動作",
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                inherit: false,
              ),
            ),
          ),
        ),
        Positioned(
          top: 170, // 根據你的UI調整位置
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                  color: Color.fromARGB(180, 255, 190, 52), width: 3),
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Center(
              child: Icon(
                Icons.face,
                size: 50,
                color: Color.fromARGB(120, 255, 190, 52),
              ),
            ),
          ),
        ),
        if (!Det.changeUI) ...[
          Positioned(
              //倒數計時
              top: 180,
              child: Container(
                height: 120,
                width: 100,
                child: AutoSizeText(
                  "${Det.mathText}",
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
                Det.mindText,
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
          if (Det.buttom_false)
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
                      Det.startd();
                    },
                  ),
                )).animate().slide(duration: 500.ms),
        ] else if (!Det.endDetector) ...[
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
                "次數\n${Det.posecounter}/${Det.poseTarget}",
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
          // if (Det.timerui)
          //   Positioned(
          //     //計時器UI
          //     bottom: 10,
          //     left: -10,
          //     child: Container(
          //       padding: EdgeInsets.all(10),
          //       decoration: new BoxDecoration(
          //         color: Color.fromARGB(250, 65, 64, 64),
          //         borderRadius: BorderRadius.horizontal(
          //           left: Radius.circular(0),
          //           right: Radius.circular(20),
          //         ),
          //       ),
          //       width: 100,
          //       height: 90,
          //       child: AutoSizeText(
          //         "秒數\n${Det.posetimecounter}/${Det.posetimeTarget}",
          //         textAlign: TextAlign.center,
          //         maxLines: 2,
          //         style: TextStyle(
          //           fontSize: 25,
          //           color: Color.fromARGB(250, 255, 190, 52),
          //           height: 1.2,
          //           inherit: false,
          //         ),
          //       ),
          //     ),
          //   ),
          Positioned(
            //提醒視窗 - 更細的設計
            bottom: 200,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              decoration: new BoxDecoration(
                color: Color.fromARGB(60, 65, 64, 64),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: AutoSizeText(
                "${Det.orderText}",
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  height: 1.2,
                  inherit: false,
                ),
              ),
            ),
          ),
          // 添加 press.png 圖片在原本秒數位置
          Positioned(
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
              width: 200,
              height: 160,
              child: Center(
                child: Image.asset(
                  'assets/images/press.png',
                  fit: BoxFit.contain, // 保持原始比例
                ),
              ),
            ),
          )
        ],
        if (Det.endDetector)
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
                          endout12();
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

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final poses = await _poseDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = PosePainter(
          poses, inputImage.metadata!.size, inputImage.metadata!.rotation);
      _customPaint = CustomPaint(painter: painter);
    } else {
      _text = 'Poses found: ${poses.length}\n\n';
      // TODO: set _customPaint to draw landmarks on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}

class salivary_gland_massage {
  static const double THRESHOLD = 50000; // 距離閾值
  int posetimecounter = 0; //復健動作持續秒數
  int posetimeTarget = 3; //復健動作持續秒數目標
  int posecounter = 0; //復健動作實作次數
  int poseTarget = 10; //目標次數設定
  bool startdDetector = false; //偵測
  bool endDetector = false; //跳轉
  bool DetectorED = false;
  bool timerbool = true; //倒數計時器
  double? Standpoint_X = 0;
  double? Standpoint_Y = 0;
  double? Standpoint_bodymind_x = 0; //身體終點
  double? Standpoint_bodymind_y = 0; //身體終點
  String orderText = ""; //目標提醒
  String mathText = ""; //倒數文字
  bool buttom_false = true; //按下按鈕消失
  bool changeUI = false;
  bool right_side = true;
  bool timerui = true;
  bool sound = true;
  String mindText = "請將全身拍攝於畫面內\n並維持手機直立\n準備完成請按「Start」";
  String instructionText = "請挺胸";
  final AudioCache player = AudioCache();
  final AudioPlayer _audioPlayer = AudioPlayer(); //播放音檔
  Timer? reminderTimer; // 用於定時提示
  Timer? reminderTimer2; // 用於定時提示
  Timer? reminderTimer3; // 用於定時提示
  List<double> noseZHistory = [];
  List<double> leftHandZHistory = [];
  List<double> rightHandZHistory = [];
  int poseStage = 0; // 跟蹤動作階段
  double? initialY; // 記錄初始Y位置
  double? initialRightHandY; // 右手初始Y座標
  double? initialLeftHandY; // 左手初始Y座標
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
    if (_languagePreference == 'taiwanese') {
      return 'wav'; // 台語
    } else {
      return 'mp3'; // 預設中文
    }
  }

  void startd() {
    //倒數計時
    int counter = 5;
    buttom_false = false;
    Timer.periodic(
      //觸發偵測timer
      const Duration(seconds: 1),
      (timer) {
        mathText = "${counter--}";
        if (counter < 0) {
          print("cancel timer");
          timer.cancel();
          mathText = " ";
          startD();
        }
      },
    );
  }

  void startD() {
    //開始辨識

    this.changeUI = true;
    this.startdDetector = true;
    print("startdDetector be true");
    setStandpoint();
    settimer();
  }

  void poseDetector() {
    double midY = (posedata[19]! + posedata[23]!) / 2;
    double midY2 = (posedata[21]! + posedata[25]!) / 2;
    double rightHandY = posedata[39]!;
    double leftHandY = posedata[41]!;

    if (this.endDetector) {
      // stopReminder(); // 如果已結束檢測，停止提醒
      return;
    }

    bool DetectorED =
        ddistance(posedata[38]!, posedata[39]!, posedata[18]!, midY) <
                THRESHOLD // 右手接近脖子上下
            &&
            ddistance(posedata[40]!, posedata[41]!, posedata[20]!, midY2) <
                THRESHOLD; // 左手接近脖子上下

    if (this.startdDetector) {
      if (this.poseStage == 0) {
        // 預備動作 - 將手放在指定位置
        this.orderText = "請將雙手放在指定位置";
        if (DetectorED && this.startdDetector) {
          this.orderText = "開始上下移動雙手";
          this.poseStage = 1; // 進入移動階段
          this.initialY = (rightHandY + leftHandY) / 2; // 記錄起始Y位置
          this.sounder(0); // 提示音
        }
      } else if (this.poseStage == 1) {
        // 檢測手部的Y軸移動
        double currentY = (rightHandY + leftHandY) / 2;

        // 在指定區域內移動
        if (DetectorED) {
          // 檢測是否有足夠的移動
          if ((currentY - this.initialY!).abs() >= 10) {
            // 記錄當前完成一次移動
            this.posecounter++;
            this.orderText = "做得好!";
            this.sounder(this.posecounter);

            // 更新初始位置為當前位置，繼續檢測下一次移動
            this.initialY = currentY;
          }
        } else {
          // 如果手不在指定位置，提示使用者
          this.orderText = "請保持雙手在指定位置";
        }
      }
    } else if (DetectorED) {
      this.startdDetector = true;
      this.poseStage = 0; // 確保從預備階段開始
    }
  }

  void setStandpoint() {
    //設定基準點(左上角為(0,0)向右下)
    this.Standpoint_X = posedata[22]! - 10;
    this.Standpoint_Y = posedata[23]! - 40;
    this.Standpoint_X = posedata[24]! - 10;
    this.Standpoint_Y = posedata[25]! - 40;
    this.Standpoint_bodymind_x = (posedata[22]! + posedata[24]!) / 2;
    this.Standpoint_bodymind_y = (posedata[23]! + posedata[25]!) / 2;
  }

  void posetargetdone() {
    //完成任務後發出退出信號
    if (this.posecounter == this.poseTarget) {
      this.endDetector = true;
      // stopReminder(); // 完成任務時停止提醒
      // stopReminder2();
      // stopReminder3();
      sound = false;
    }
  }

  double yDistance(double x1, double y1, double x2, double y2) {
    return (y2 - y1).abs();
  }

  double xDistance(double x1, double y1, double x2, double y2) {
    return (x2 - x1).abs();
  }

  double ddistance(double x1, double y1, double x2, double y2) {
    return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2); // 計算平方距離
  }

  void settimer() {
    Timer.periodic(
      //觸發偵測timer
      const Duration(seconds: 1),
      (timer) {
        poseDetector(); //偵測目標是否完成動作
        posetargetdone(); //偵測目標是否完成指定次數
        if (!this.timerbool) {
          print("cancel timer");
          timer.cancel();
          // stopReminder();
          // stopReminder2();
          // stopReminder3();
        }
      },
    );
  }

  void sounder(int counter) {
    _loadLanguagePreference();
    if (counter == 999 && sound && startdDetector) {
      _audioPlayer.play(
          AssetSource('${getAudioPath()}/upper/shrug.${getAudioDataForm()}'));
      sound = false;
      // startReminder();
    } else
      _audioPlayer.play(
          AssetSource('${getAudioPath()}/${counter}.${getAudioDataForm()}'));
  }
}

Future<void> endout12() async {
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd').format(now);
  var url;
  if (Face_Detect_Number == 12) {
    url = Uri.parse(ip + "train_mouthok.php");
    print("初階,吞嚥");
  }
  final responce = await http.post(url, body: {
    "time": formattedDate,
    "account": FFAppState().accountnumber.toString(),
    "action": FFAppState().mouth.toString(), //動作
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
