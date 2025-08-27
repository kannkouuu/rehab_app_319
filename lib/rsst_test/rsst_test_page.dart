import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'audio_recorder.dart';
import 'rsst_result_page.dart';

class RsstTestPage extends StatefulWidget {
  const RsstTestPage({Key? key}) : super(key: key);

  @override
  _RsstTestPageState createState() => _RsstTestPageState();
}

class _RsstTestPageState extends State<RsstTestPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _unfocusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer(); //播放音檔

  bool _isPreparationPhase = true; // 準備階段
  bool _isRecording = false; // 正在錄音
  bool _isProcessing = false; // 正在處理
  bool _showFinalResult = false; // 顯示最終結果
  bool _earlyRecordingStarted = false; // 提前開始錄音的標記

  int _preparationCounter = 5; // 準備倒數計時
  int _recordingCounter = 30; // 錄音倒數計時
  int _swallowCount = 0; // 吞嚥次數（簡化版本中固定為5）
  String? _recordingPath; // 錄音檔案路徑

  Timer? _preparationTimer;
  Timer? _recordingTimer;
  AudioRecorder audioRecorder = AudioRecorder(); // 錄音模組

  @override
  void initState() {
    super.initState();
    // 延遲100毫秒再開始倒數，避免界面渲染問題
    Future.delayed(Duration(milliseconds: 100), _initTest);
  }

  void _initTest() {
    if (!mounted) return;

    // 確保重新設定計數器初始值
    setState(() {
      _preparationCounter = 5;
    });

    // 開始準備倒數計時
    _preparationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _preparationCounter--;
      });

      // 當倒數到2秒時開始錄音，但倒數計時繼續
      if (_preparationCounter == 2 && !_earlyRecordingStarted) {
        _earlyRecordingStarted = true;
        _startRecordingEarly();
      }

      // 當倒數到0時，切換到錄音界面
      if (_preparationCounter <= 0) {
        timer.cancel();
        _switchToRecordingPhase();
      }
    });
  }

  // 提前開始錄音，但保持在準備階段界面
  void _startRecordingEarly() async {
    // 初始化錄音機
    try {
      await audioRecorder.init();
      await audioRecorder.startRecording();
      print('成功提前開始錄音，當前倒數：$_preparationCounter 秒');
    } catch (e) {
      print('提前錄音初始化失敗: $e');
      _showErrorDialog('錄音初始化失敗，請檢查麥克風權限。');
      return;
    }
  }

  // 切換到錄音界面
  void _switchToRecordingPhase() {
    if (!mounted) return;

    // 播放提示音
    try {
      _audioPlayer.play(AssetSource('audios/start_beep.mp3'));
    } catch (e) {
      print('無法播放開始提示音: $e');
    }

    setState(() {
      _isPreparationPhase = false;
      _isRecording = true;
      _recordingCounter = 30; // 確保重設為30秒
    });

    // 如果尚未開始錄音，才初始化錄音
    if (!_earlyRecordingStarted) {
      _startRecording();
    } else {
      // 已經在錄音了，只需啟動倒數計時
      _startRecordingTimer();
    }
  }

  void _startRecording() async {
    if (!mounted) return;

    // 開始錄音
    try {
      await audioRecorder.init();
      await audioRecorder.startRecording();
      print('成功開始錄音，將持續 $_recordingCounter 秒');
    } catch (e) {
      print('錄音初始化失敗: $e');
      _showErrorDialog('錄音初始化失敗，請檢查麥克風權限。');
      return;
    }

    _startRecordingTimer();
  }

  // 開始錄音倒數計時器
  void _startRecordingTimer() {
    // 開始錄音倒數計時
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _recordingCounter--;
      });

      if (_recordingCounter <= 0) {
        timer.cancel();
        _stopRecording();
      }
    });
  }

  void _stopRecording() async {
    if (!mounted) return;

    // 停止計時器（如果仍在運行）
    _recordingTimer?.cancel();

    // 播放結束提示音
    try {
      await _audioPlayer.play(AssetSource('audios/start_beep.mp3'));
    } catch (e) {
      print('無法播放結束提示音: $e');
    }

    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    // 停止錄音
    try {
      _recordingPath = await audioRecorder.stopRecording();
      print('錄音完成，儲存路徑: $_recordingPath');

      if (_recordingPath != null) {
        // 簡化處理：固定設定吞嚥次數為5
        setState(() {
          _swallowCount = 5;
          _isProcessing = false;
          _showFinalResult = true;
        });

        // 轉到結果頁面（音檔處理將在結果頁面自動進行）
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RsstResultPage(
                  swallowCount: _swallowCount,
                  recordingPath: _recordingPath,
                  isFromUpload: false,
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('停止錄音失敗: $e');
      _showErrorDialog('停止錄音失敗，請重試。');
      return;
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('錯誤'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 返回上一頁
              },
              child: Text('確定'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    if (_preparationTimer != null && _preparationTimer!.isActive) {
      _preparationTimer!.cancel();
    }
    if ((_isRecording || _earlyRecordingStarted) &&
        _recordingTimer != null &&
        _recordingTimer!.isActive) {
      _recordingTimer!.cancel();
      audioRecorder.stopRecording();
    }
    audioRecorder.dispose();
    _unfocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_unfocusNode),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFF90BDF9),
        appBar: AppBar(
          backgroundColor: Color(0xFF90BDF9),
          title: Text(
            'RSST 測驗進行中',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 22,
                ),
          ),
          centerTitle: true,
          elevation: 2,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 1,
            decoration: BoxDecoration(
              color: Color(0xFF90BDF9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPreparationPhase) _buildPreparationPhase(),
                if (_isRecording) _buildRecordingPhase(),
                if (_isProcessing) _buildProcessingPhase(),
                if (_showFinalResult) _buildFinalResultPhase(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreparationPhase() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Color(0xFFF4DB60),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$_preparationCounter',
              style: FlutterFlowTheme.of(context).displayLarge.override(
                    fontFamily: 'Poppins',
                    color: Color(0xFFC50D1C),
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ).animate().scale(duration: 400.ms),
        SizedBox(height: 40),
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                color: Color(0x33000000),
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoSizeText(
                _earlyRecordingStarted ? '錄音已開始！' : '準備開始測驗',
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      fontFamily: 'Poppins',
                      color: _earlyRecordingStarted
                          ? Colors.red
                          : Color(0xFFC50D1C),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 15),
              AutoSizeText(
                _earlyRecordingStarted
                    ? '錄音已開始！請將手機保持在頸部右側\n倒數結束後測驗繼續進行'
                    : '請將手機放在頸部右側\n準備就緒後將在倒數結束時開始錄音',
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
              ),
            ],
          ),
        ).animate().fade(duration: 400.ms),

        // 提前錄音的指示器
        if (_earlyRecordingStarted)
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '錄音中',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 500.ms)
              .fadeOut(duration: 500.ms)
              .then()
      ],
    );
  }

  Widget _buildRecordingPhase() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 60,
                ),
                Text(
                  '$_recordingCounter',
                  style: FlutterFlowTheme.of(context).displayMedium.override(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scaleXY(begin: 1.0, end: 1.05, duration: 800.ms)
            .then(duration: 800.ms),
        SizedBox(height: 40),
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                color: Color(0x33000000),
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoSizeText(
                '請開始吞嚥',
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      fontFamily: 'Poppins',
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 15),
              AutoSizeText(
                '請盡可能多次地吞嚥\n保持手機穩定並靠近頸部',
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          icon: Icon(Icons.stop, color: Colors.white),
          label: Text(
            '停止測驗',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: _stopRecording,
        ),
      ],
    );
  }

  Widget _buildProcessingPhase() {
    return Column(
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4DB60)),
          strokeWidth: 5,
        ),
        SizedBox(height: 30),
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: AutoSizeText(
            '正在處理錄音...\n這可能需要一點時間',
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 20,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalResultPhase() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Color(0x33000000),
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoSizeText(
            '測驗完成！',
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  fontFamily: 'Poppins',
                  color: Color(0xFFC50D1C),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 20),
          AutoSizeText(
            '正在前往結果頁面...',
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
          ),
        ],
      ),
    );
  }
}
