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

// 1. 常數類別
class ShoulderActivitiesConstants {
  static const double SIDE_TILT_THRESHOLD = 80.0;
  static const int DEFAULT_POSE_TARGET = 15; // 改成15次
  static const int DEFAULT_TIME_TARGET = 3; // 改成3秒
  static const double SHOULDER_OFFSET_X = 10.0;
  static const double SHOULDER_OFFSET_Y = 40.0;
  static const int COUNTDOWN_SECONDS = 5;
  static const int REMINDER_INTERVAL_SECONDS = 5;
  static const int KEEP_REMINDER_INTERVAL_SECONDS = 2;
  static const int TILT_REMINDER_INTERVAL_SECONDS = 3;
}

// 2. 動作階段枚舉
enum ShoulderPhase {
  leftRaise, // 左肩抬高
  rightRaise // 右肩抬高
}

// 2. 計時器管理類別
class TimerManager {
  final Map<String, Timer?> _timers = {};

  void startTimer(String key, Duration duration, void Function() callback) {
    stopTimer(key);
    _timers[key] = Timer.periodic(duration, (_) => callback());
  }

  void startCountdownTimer(
      String key, Duration duration, void Function(Timer) callback) {
    stopTimer(key);
    _timers[key] = Timer.periodic(duration, callback);
  }

  void stopTimer(String key) {
    _timers[key]?.cancel();
    _timers[key] = null;
  }

  void stopAllTimers() {
    _timers.values.forEach((timer) => timer?.cancel());
    _timers.clear();
  }

  void dispose() {
    stopAllTimers();
  }
}

// 4. 音訊管理類別
class AudioManager {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _languagePreference = 'chinese';

  Future<void> initialize() async {
    await _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _languagePreference = prefs.getString('language_preference') ?? 'chinese';
  }

  String get audioPath {
    return _languagePreference == 'taiwanese'
        ? 'taigi_pose_audios'
        : 'pose_audios';
  }

  String get audioFormat {
    return _languagePreference == 'taiwanese' ? 'wav' : 'mp3';
  }

  Future<void> playCounterAudio(int counter) async {
    await _loadLanguagePreference();
    await _audioPlayer.play(AssetSource('$audioPath/$counter.$audioFormat'));
  }

  Future<void> playInstructionAudio(String instruction) async {
    await _loadLanguagePreference();
    String audioFile = '';

    switch (instruction) {
      case 'shrug':
        audioFile = 'upper/shrug.$audioFormat';
        break;
      case 'done':
        audioFile = 'done.$audioFormat';
        break;
      case 'keep':
        audioFile = 'keepit.$audioFormat';
        break;
      case 'excessive_roll':
        audioFile = 'upper/Excessive_roll.mp3';
        break;
      case 'l_shoulder_raise':
        audioFile = 'upper/l_shoulder_raise.$audioFormat';
        break;
      case 'r_shoulder_raise':
        audioFile = 'upper/r_shoulder_raise.$audioFormat';
        break;
      default:
        return;
    }

    try {
      await _audioPlayer.play(AssetSource('$audioPath/$audioFile'));
    } catch (e) {
      print('音訊播放錯誤: $audioFile - $e');
      // 如果音訊播放失敗，不影響程式運行
    }
  }

  Future<void> playSpecialAudio(int code, bool shouldPlay) async {
    if (code == 999 && shouldPlay) {
      await playInstructionAudio('shrug');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

class Shoulder_activities extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<Shoulder_activities> {
  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  shoulder_activities Det = shoulder_activities();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() async {
    _canProcess = false;
    _poseDetector.close();
    // 清理 shoulder_activities 中的資源
    Det.dispose();
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
                          endout11();
                          // 確保清理資源
                          Det.dispose();
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

class shoulder_activities {
  int posetimecounter = 0; //復健動作持續秒數
  int posetimeTarget =
      ShoulderActivitiesConstants.DEFAULT_TIME_TARGET; //復健動作持續秒數目標
  int posecounter = 0; //復健動作實作次數
  int poseTarget = ShoulderActivitiesConstants.DEFAULT_POSE_TARGET; //目標次數設定
  bool startdDetector = false; //偵測
  bool endDetector = false; //跳轉
  bool DetectorED = false;
  bool timerbool = true; //倒數計時器
  double? Standpoint_X = 0;
  double? Standpoint_Y = 0;
  double? Standpoint_Left_Y = 0; //左肩基準點
  double? Standpoint_Right_Y = 0; //右肩基準點
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

  // 兩階段循環狀態
  ShoulderPhase currentPhase = ShoulderPhase.leftRaise;
  int phaseCompletionCount = 0; // 完成的階段數（0-1）
  bool justCompletedFullCycle = false; // 剛完成兩個階段循環

  // 使用新的管理類別
  final TimerManager _timerManager = TimerManager();
  final AudioManager _audioManager = AudioManager();

  Future<void> initialize() async {
    await _audioManager.initialize();
  }

  void startd() {
    //倒數計時
    int counter = ShoulderActivitiesConstants.COUNTDOWN_SECONDS;
    buttom_false = false;
    _timerManager.startCountdownTimer(
      'countdown',
      const Duration(seconds: 1),
      (timer) {
        mathText = "${counter--}";
        if (counter < 0) {
          print("cancel timer");
          _timerManager.stopTimer('countdown');
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

    // 初始化第一階段
    this.currentPhase = ShoulderPhase.leftRaise;
    this.phaseCompletionCount = 0;
    updateOrderText();

    // 延遲播放初始指令，確保UI更新完成
    Future.delayed(Duration(milliseconds: 500), () {
      playPhaseInstruction();
    });

    startReminder(); //啟動提示
    startReminder2();
    startReminder3();
  }

  void poseDetector() {
    if (this.endDetector) {
      stopReminder(); // 如果已結束檢測，停止提醒
      return;
    }

    // 檢測側傾過大
    if (distance(
                Standpoint_bodymind_x!,
                Standpoint_bodymind_y!,
                (posedata[22]! + posedata[24]!) / 2,
                (posedata[23]! + posedata[25]!) / 2) >
            ShoulderActivitiesConstants.SIDE_TILT_THRESHOLD &&
        this.startdDetector) {
      this.orderText = "側傾過大";
      stopReminder(); // 動作不正確，停止提醒
      return;
    }

    if (this.startdDetector) {
      DetectorED = true;

      // 根據當前階段檢測對應的肩膀抬高
      bool shoulderReachedTarget = false;
      switch (currentPhase) {
        case ShoulderPhase.leftRaise:
          // 檢測左肩是否抬高到定點
          shoulderReachedTarget = posedata[23]! < this.Standpoint_Left_Y!;
          break;
        case ShoulderPhase.rightRaise:
          // 檢測右肩是否抬高到定點
          shoulderReachedTarget = posedata[25]! < this.Standpoint_Right_Y!;
          break;
      }

      if (shoulderReachedTarget) {
        // 肩膀到達定點，開始計時
        this.posetimecounter++;
        this.orderText = "請保持住!";
        sound = true;
        stopReminder();

        if (this.posetimecounter == this.posetimeTarget) {
          // 維持時間達標，完成當前階段
          this.startdDetector = false;
          this.posetimecounter = 0;
          this.orderText = "達標!";

          // 播放完成音效，然後處理階段切換
          _audioManager.playInstructionAudio('done');

          // 延遲處理階段切換，確保 done 音效播放完畢
          Future.delayed(Duration(seconds: 1), () {
            nextPhase();
          });
        }
      } else {
        // 肩膀未到達定點，重置計時
        this.posetimecounter = 0;
        updateOrderText(); // 更新指令文字
      }
    } else if (DetectorED) {
      // 等待復歸狀態
      bool shoulderReturned = false;
      switch (currentPhase) {
        case ShoulderPhase.leftRaise:
          shoulderReturned = posedata[23]! > this.Standpoint_Left_Y!;
          break;
        case ShoulderPhase.rightRaise:
          shoulderReturned = posedata[25]! > this.Standpoint_Right_Y!;
          break;
      }

      if (shoulderReturned) {
        // 確認復歸
        // 檢查是否是兩個階段都完成後的復歸
        if (justCompletedFullCycle) {
          // 兩個階段完成後的復歸，先播放計數音效，然後播放下一輪第一階段指令
          this.sounder(this.posecounter);
          this.justCompletedFullCycle = false; // 重置標記
          this.orderText = "完成 ${this.posecounter} 次!"; // 顯示完成次數

          // 延遲播放指令音效和開始下一階段檢測
          Future.delayed(Duration(seconds: 2), () {
            if (!endDetector) {
              // 更新UI文字後再播放音訊，確保音訊與當前階段同步
              updateOrderText();
              playPhaseInstruction(); // 播放當前階段指令音效
              // 延遲開始檢測，確保音效播放完畢
              Future.delayed(Duration(milliseconds: 800), () {
                this.startdDetector = true; // 開始下一階段檢測
              });
            }
          });
        } else {
          // 階段內的復歸，更新階段後播放對應指令
          // 先更新UI文字，確保播放的音訊與文字一致
          updateOrderText();
          // 延遲播放音訊，避免與前一個音訊重疊
          Future.delayed(Duration(milliseconds: 300), () {
            playPhaseInstruction(); // 播放當前階段指令音效
            // 延遲開始檢測，確保音效播放完畢
            Future.delayed(Duration(milliseconds: 800), () {
              this.startdDetector = true; // 開始下一階段檢測
            });
          });
        }
      } else {
        this.orderText = "請放下肩膀";
      }
    }
  }

  void setStandpoint() {
    //設定基準點(左上角為(0,0)向右下)
    // 左肩基準點 (pose landmark 23 是左肩Y座標)
    this.Standpoint_Left_Y =
        posedata[23]! - ShoulderActivitiesConstants.SHOULDER_OFFSET_Y;
    // 右肩基準點 (pose landmark 25 是右肩Y座標)
    this.Standpoint_Right_Y =
        posedata[25]! - ShoulderActivitiesConstants.SHOULDER_OFFSET_Y;
    // 身體中心點 (用於檢測側傾)
    this.Standpoint_bodymind_x = (posedata[22]! + posedata[24]!) / 2;
    this.Standpoint_bodymind_y = (posedata[23]! + posedata[25]!) / 2;
  }

  void nextPhase() {
    // 進入下一階段
    phaseCompletionCount++;

    if (phaseCompletionCount >= 2) {
      // 完成兩個階段，標記需要播放計數音效
      this.posecounter++;
      this.phaseCompletionCount = 0;
      this.currentPhase = ShoulderPhase.leftRaise;
      this.justCompletedFullCycle = true; // 標記剛完成循環

      // 檢查是否完成所有目標
      if (this.posecounter >= this.poseTarget) {
        posetargetdone();
        return;
      }

      // 兩個階段完成後，等待復歸再播放計數音效和下一輪指令
      updateOrderText();
    } else {
      // 進入下一階段
      switch (currentPhase) {
        case ShoulderPhase.leftRaise:
          currentPhase = ShoulderPhase.rightRaise;
          break;
        case ShoulderPhase.rightRaise:
          currentPhase = ShoulderPhase.leftRaise;
          break;
      }

      // 不在這裡播放指令音頻，等待復歸後再播放
      updateOrderText();
    }
  }

  void updateOrderText() {
    // 根據當前階段更新指令文字
    switch (currentPhase) {
      case ShoulderPhase.leftRaise:
        this.orderText = "抬起左肩";
        break;
      case ShoulderPhase.rightRaise:
        this.orderText = "抬起右肩";
        break;
    }
  }

  void playPhaseInstruction() {
    // 播放當前階段的指令音頻
    switch (currentPhase) {
      case ShoulderPhase.leftRaise:
        _audioManager.playInstructionAudio('l_shoulder_raise');
        break;
      case ShoulderPhase.rightRaise:
        _audioManager.playInstructionAudio('r_shoulder_raise');
        break;
    }
  }

  void posetargetdone() {
    //完成任務後發出退出信號
    if (this.posecounter == this.poseTarget) {
      this.endDetector = true;
      stopReminder(); // 完成任務時停止提醒
      stopReminder2();
      stopReminder3();
      sound = false;
    }
  }

  double yDistance(double x1, double y1, double x2, double y2) {
    return (y2 - y1).abs();
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
    _timerManager.startTimer(
      'main',
      const Duration(seconds: 1),
      () {
        poseDetector(); //偵測目標是否完成動作
        posetargetdone(); //偵測目標是否完成指定次數
        if (!this.timerbool) {
          print("cancel timer");
          _timerManager.stopTimer('main');
          _timerManager.stopTimer('reminder');
          _timerManager.stopTimer('reminder2');
          _timerManager.stopTimer('reminder3');
        }
      },
    );
  }

  void sounder(int counter) {
    if (counter > 0) {
      // 播放計數音頻
      _audioManager.playCounterAudio(counter);
    }
    // 移除 counter == 999 的邏輯，避免重複播放
  }

  Future<void> posesounder(bool BOO) async {
    // 此方法已不再使用，音頻播放邏輯已重構
    // 保留方法避免編譯錯誤，但內容為空
  }

  void startReminder() {
    // 暫時停用定時提醒功能，避免音頻重疊
    _timerManager.stopTimer('reminder');
  }

  void stopReminder() {
    _timerManager.stopTimer('reminder');
  }

  void startReminder2() {
    // 停用「請保持」語音播放功能
    _timerManager.stopTimer('reminder2');
    // 註釋掉原本的提醒邏輯
    /*
    // 確保之前的計時器被取消
    _timerManager.stopTimer('reminder2');
    int counter = 0; // 新建一個計數器

    _timerManager.startTimer(
        'reminder2',
        Duration(
            seconds: ShoulderActivitiesConstants
                .KEEP_REMINDER_INTERVAL_SECONDS), () async {
      // 檢測當前階段對應肩膀是否到達定點且沒有側傾
      bool shoulderReachedTarget = false;
      switch (currentPhase) {
        case ShoulderPhase.leftRaise:
          shoulderReachedTarget = posedata[23]! < this.Standpoint_Left_Y!;
          break;
        case ShoulderPhase.rightRaise:
          shoulderReachedTarget = posedata[25]! < this.Standpoint_Right_Y!;
          break;
      }

      bool isNotTilting = !(distance(
                  Standpoint_bodymind_x!,
                  Standpoint_bodymind_y!,
                  (posedata[22]! + posedata[24]!) / 2,
                  (posedata[23]! + posedata[25]!) / 2) >
              ShoulderActivitiesConstants.SIDE_TILT_THRESHOLD &&
          this.startdDetector);

      // 播放音訊
      if (shoulderReachedTarget && isNotTilting && this.startdDetector) {
        _audioManager.playInstructionAudio('keep');
      }

      // 每2秒歸零並列印當前計數
      print("計數器歸零前的計數: $counter");
      counter = 0; // 歸零計數器

      // 如果需要，可以在這裡執行其他邏輯
      print("計數器已歸2");
    });
    */
  }

  void stopReminder2() {
    _timerManager.stopTimer('reminder2');
  }

  void startReminder3() {
    // 停用側傾警告語音播放功能
    _timerManager.stopTimer('reminder3');
    // 註釋掉原本的側傾警告邏輯
    /*
    _timerManager.stopTimer('reminder3');
    int counter = 0;

    _timerManager.startTimer(
        'reminder3',
        Duration(
            seconds: ShoulderActivitiesConstants
                .TILT_REMINDER_INTERVAL_SECONDS), () async {
      if (distance(
                  Standpoint_bodymind_x!,
                  Standpoint_bodymind_y!,
                  (posedata[22]! + posedata[24]!) / 2,
                  (posedata[23]! + posedata[25]!) / 2) >
              ShoulderActivitiesConstants.SIDE_TILT_THRESHOLD &&
          this.startdDetector) {
        _audioManager.playInstructionAudio('excessive_roll');
      }

      counter = 0;
    });
    */
  }

  void stopReminder3() {
    _timerManager.stopTimer('reminder3');
  }

  // 添加 dispose 方法來清理所有資源
  void dispose() {
    // 停止所有的計時器
    timerbool = false; // 停止主要的計時器

    // 取消所有計時器
    _timerManager.dispose();

    // 釋放音訊播放器資源
    _audioManager.dispose();

    // 重置狀態
    startdDetector = false;
    endDetector = false;
    DetectorED = false;

    print('shoulder_activities 資源已清理完成');
  }
}

Future<void> endout11() async {
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd').format(now);
  var url;
  if (Face_Detect_Number == 11) {
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
