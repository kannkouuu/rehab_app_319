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

class head_turn extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<head_turn> {
  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  Detector_head_turn Det = Detector_head_turn();

  @override
  void initState() {
    super.initState();
    // 初始化語言偏好設定
    Det.initialize();
  }

  @override
  void dispose() async {
    _canProcess = false;
    _poseDetector.close();

    // 停止所有計時器和提醒
    Det.stopReminder();
    Det.stopReminder2();

    // 停止所有音頻播放
    Det._isDisposed = true; // 確保在Det類中添加此標誌

    // 在新版本的audioplayers中，AudioCache不再有clearAll方法
    // 而且也沒有fixedPlayer屬性
    // 正確的做法是停止和釋放AudioPlayer
    try {
      await Det._audioPlayer.stop();
      await Det._audioPlayer.dispose();
    } catch (e) {
      print('停止音頻播放失敗: $e');
    }

    // 取消所有可能正在运行的Timer
    if (Det.reminderTimer != null) {
      Det.reminderTimer!.cancel();
      Det.reminderTimer = null;
    }

    if (Det.reminderTimer2 != null) {
      Det.reminderTimer2!.cancel();
      Det.reminderTimer2 = null;
    }

    if (Det.pauseTimer != null) {
      Det.pauseTimer!.cancel();
      Det.pauseTimer = null;
    }

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
          if (Det.timerui)
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
                  "秒數\n${Det.posetimecounter}/${Det.posetimeTarget}",
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
          // 箭頭方向指示器
          Positioned(
            top: 150,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: new BoxDecoration(
                color: Color.fromARGB(200, 255, 190, 52),
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
              width: 100,
              height: 100,
              child: Icon(
                Det.right_side
                    ? Icons.keyboard_arrow_right
                    : Icons.keyboard_arrow_left,
                size: 60,
                color: Colors.white,
              ),
            ),
          ).animate().scale(duration: 500.ms).then().scale(duration: 500.ms),
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
                "${Det.orderText}",
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
                          endout10();
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

class Detector_head_turn {
  int posetimecounter = 0; //復健動作持續秒數
  int posetimeTarget = 5; //復健動作持續秒數目標
  int posecounter = 0; //復健動作實作次數
  int poseTarget = 5; //目標次數設定（左右轉頭各一次為一組）
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
  String instructionText = ""; // 指示文本
  bool buttom_false = true; //按下按鈕消失
  bool changeUI = false;
  bool right_side = true;
  bool timerui = true;
  bool sound = true;
  String mindText = "請將全身拍攝於畫面內\n並維持手機直立\n準備完成請按「Start」";
  final AudioCache player = AudioCache();
  final AudioPlayer _audioPlayer = AudioPlayer(); //播放音檔
  Timer? reminderTimer; // 用於定時提示
  Timer? reminderTimer2; // 用於定時提示
  bool _isDisposed = false;
  String _languagePreference = 'chinese'; // 預設為中文
  bool _isLanguageLoaded = false; // 新增：標記語言是否已載入

  // 新增變數追蹤左右轉頭完成狀態
  bool rightTurnCompleted = false; // 右轉頭是否完成
  bool leftTurnCompleted = false; // 左轉頭是否完成
  bool hasPlayedKeepIt = false; // 是否已播放keepit音頻
  bool hasPlayedInstruction = false; // 是否已播放指示音頻
  bool waitingForRightReturn = false; // 等待右轉頭復歸
  bool waitingForLeftReturn = false; // 等待左轉頭復歸
  bool isPausing = false; // 是否在停頓階段
  Timer? pauseTimer; // 停頓計時器

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
    // 根據語言偏好選擇目錄
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
    //重置完成狀態標記
    this.rightTurnCompleted = false;
    this.leftTurnCompleted = false;
    this.hasPlayedKeepIt = false;
    this.hasPlayedInstruction = false;
    this.waitingForRightReturn = false;
    this.waitingForLeftReturn = false;
    this.isPausing = false;
    print("startdDetector be true");
    setStandpoint();
    settimer();
    // 【步驟1】開始時立即播放右轉頭提示音
    playInstructionAudio();
  }

  void poseDetector() {
    //【重新設計】偵測判定 - 按照新的音頻播放流程
    if (this.startdDetector) {
      DetectorED = true;

      if (right_side) {
        this.orderText = "請向右轉頭";

        // 檢查是否達到右轉頭偵測條件
        bool rightTurnDetected = xDistance(
                    posedata[0]!, posedata[1]!, posedata[24]!, posedata[25]!) <
                120 &&
            xDistance(
                    posedata[4]!, posedata[5]!, posedata[10]!, posedata[11]!) <
                70;

        if (rightTurnDetected) {
          // 【步驟2】偵測到右轉頭成立，播放keepit（只播放一次）
          if (!hasPlayedKeepIt) {
            playKeepItAudio();
            hasPlayedKeepIt = true;
          }

          this.posetimecounter++;
          this.orderText = "請保持住!";

          // 檢查是否完成右轉頭
          if (this.posetimecounter >= this.posetimeTarget) {
            // 【步驟3】右轉頭完成，播放done，進入右轉頭復歸檢測
            this.startdDetector = false;
            this.rightTurnCompleted = true;
            this.waitingForRightReturn = true;
            this.posetimecounter = 0;
            this.orderText = "達標!";
            playDoneAudio();
            this.hasPlayedKeepIt = false; // 重置keepit播放狀態
          }
        } else {
          // 沒有保持正確姿勢，重置計時
          this.posetimecounter = 0;
          this.hasPlayedKeepIt = false; // 重置keepit播放狀態
        }
      } else {
        this.orderText = "請向左轉頭";

        // 檢查是否達到左轉頭偵測條件
        bool leftTurnDetected = xDistance(
                    posedata[0]!, posedata[1]!, posedata[22]!, posedata[23]!) <
                120 &&
            xDistance(
                    posedata[4]!, posedata[5]!, posedata[10]!, posedata[11]!) <
                70;

        if (leftTurnDetected) {
          // 【步驟5】偵測到左轉頭成立，播放keepit（只播放一次）
          if (!hasPlayedKeepIt) {
            playKeepItAudio();
            hasPlayedKeepIt = true;
          }

          this.posetimecounter++;
          this.orderText = "請保持住!";

          // 檢查是否完成左轉頭
          if (this.posetimecounter >= this.posetimeTarget) {
            // 【步驟6】左轉頭完成，播放done，進入左轉頭復歸檢測
            this.startdDetector = false;
            this.leftTurnCompleted = true;
            this.waitingForLeftReturn = true;
            this.posetimecounter = 0;
            this.orderText = "達標!";
            playDoneAudio();
            this.hasPlayedKeepIt = false; // 重置keepit播放狀態
          }
        } else {
          // 沒有保持正確姿勢，重置計時
          this.posetimecounter = 0;
          this.hasPlayedKeepIt = false; // 重置keepit播放狀態
        }
      }
    } else if (DetectorED && !isPausing) {
      // 復歸條件檢測
      bool returnToCenter = false;

      if (waitingForRightReturn) {
        // 右轉頭完成後的復歸檢測
        returnToCenter = xDistance(
                posedata[0]!, posedata[1]!, posedata[24]!, posedata[25]!) >
            160;

        if (returnToCenter) {
          // 右轉頭復歸完成，切換到左轉頭
          this.waitingForRightReturn = false;
          this.rightTurnCompleted = false;
          this.right_side = false;
          this.startdDetector = true;
          this.hasPlayedInstruction = false;
          playInstructionAudio(); // 播放左轉頭指示音
        } else {
          this.orderText = "請面對前方";
        }
      } else if (waitingForLeftReturn) {
        // 左轉頭完成後的復歸檢測
        returnToCenter = xDistance(
                posedata[0]!, posedata[1]!, posedata[22]!, posedata[23]!) >
            160;

        if (returnToCenter) {
          // 左轉頭復歸完成，計數+1，開始1.5秒停頓
          this.waitingForLeftReturn = false;
          this.leftTurnCompleted = false;
          this.posecounter++; // 計數器+1
          this.sounder(this.posecounter); // 播放計數音

          // 開始1.5秒停頓
          startPause();
        } else {
          this.orderText = "請面對前方";
        }
      }
    } else if (isPausing) {
      // 在停頓階段，顯示準備訊息
      this.orderText = "準備下一組...";
    }
  }

  void setStandpoint() {
    //設定基準點(左上角為(0,0)向右下)
    this.Standpoint_X = posedata[22]! - 20;
    this.Standpoint_Y = posedata[23]! - 20;
    this.Standpoint_bodymind_x = (posedata[22]! + posedata[24]!) / 2;
    this.Standpoint_bodymind_y = (posedata[23]! + posedata[25]!) / 2;
  }

  void posetargetdone() {
    //完成任務後發出退出信號
    if (this.posecounter == this.poseTarget) {
      this.endDetector = true;
      stopReminder();
      stopReminder2();
      sound = false;
    }
  }

  double xDistance(double x1, double y1, double x2, double y2) {
    return (x2 - x1).abs();
  }

  double distance(double x1, double y1, double x2, double y2) {
    return sqrt(pow((x1 - x2).abs(), 2) + pow((y1 - y2).abs(), 2));
  }

  double angle(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    double vx1 = x1 - x2;
    double vy1 = y1 - y2;
    double vx2 = x3 - x2;
    double vy2 = y3 - y2;
    double porduct = vx1 * vx2 + vy1 * vy2;
    double result =
        acos(porduct / (distance(x1, y1, x2, y2) * distance(x3, y3, x2, y2))) *
            57.3;
    print(result);
    return result;
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
          stopReminder();
          stopReminder2();
        }
      },
    );
  }

  void sounder(int counter) async {
    if (_isDisposed) return;
    await _ensureLanguageLoaded(); // 確保語言設定已載入

    // 【簡化】只播放計數音
    await _audioPlayer.play(
        AssetSource('${getAudioPath()}/${counter}.${getAudioDataForm()}'));
  }

  // 【保留但簡化】舊版方法，防止其他地方調用出錯
  Future<void> posesounder(bool BOO) async {
    // 此方法已被新的音頻播放邏輯取代，保留以防其他地方調用
  }

  void startReminder() {
    // 此方法已被新的音頻播放邏輯取代
  }

  void stopReminder() {
    reminderTimer?.cancel();
    reminderTimer = null;
  }

  void startReminder2() {
    // 此方法已被新的音頻播放邏輯取代
  }

  void stopReminder2() {
    reminderTimer2?.cancel();
    reminderTimer2 = null;
  }

  // 【新增】開始1.5秒停頓
  void startPause() {
    this.isPausing = true;
    this.orderText = "準備下一組...";

    // 設定1.5秒停頓計時器
    pauseTimer = Timer(Duration(milliseconds: 1500), () {
      // 停頓結束，重置狀態準備下一組
      this.isPausing = false;
      this.right_side = true;
      this.hasPlayedKeepIt = false;
      this.hasPlayedInstruction = false;
      this.startdDetector = true;

      // 播放下一組的右轉頭指示音
      playInstructionAudio();
    });
  }

  // 【新增】播放指示音頻方法
  Future<void> playInstructionAudio() async {
    if (_isDisposed) return;
    await _ensureLanguageLoaded();

    if (right_side) {
      await _audioPlayer.play(AssetSource(
          '${getAudioPath()}/upper/TurnHead_right.${getAudioDataForm()}'));
    } else {
      await _audioPlayer.play(AssetSource(
          '${getAudioPath()}/upper/TurnHead_left.${getAudioDataForm()}'));
    }
    hasPlayedInstruction = true;
  }

  // 【新增】播放保持音頻方法
  Future<void> playKeepItAudio() async {
    if (_isDisposed) return;
    await _ensureLanguageLoaded();

    await _audioPlayer
        .play(AssetSource('${getAudioPath()}/keepit.${getAudioDataForm()}'));
  }

  // 【新增】播放完成音頻方法
  Future<void> playDoneAudio() async {
    if (_isDisposed) return;
    await _ensureLanguageLoaded();

    await _audioPlayer
        .play(AssetSource('${getAudioPath()}/done.${getAudioDataForm()}'));
  }
}

Future<void> endout10() async {
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd').format(now);
  var url;
  if (Face_Detect_Number == 10) {
    //頭側彎
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
