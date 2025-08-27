import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../trainmouth/trainmouth_widget.dart';
import '../../main.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // 添加這個 import 來檢測平台
import '../../utils/ios_audio_processor.dart'; // 重新啟用這個 import

/// **第一個畫面：讓使用者選擇 PA、TA、KA**
class speech extends StatefulWidget {
  const speech({super.key});

  @override
  State<speech> createState() => _speechState();
}

class _speechState extends State<speech> {
  // 用於追蹤已完成的音素測試
  final Map<String, int> completedPhonemes = {"PA": 0, "TA": 0, "KA": 0};

  void _navigateToDetectionScreen(BuildContext context, String phoneme) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SoundDetectionScreen(
          selectedPhoneme: phoneme,
          onComplete: (wordCount) {
            // 測試完成後更新狀態
            setState(() {
              completedPhonemes[phoneme] = wordCount;
            });
          },
        ),
      ),
    );
  }

  // 檢查是否已完成所有測試
  bool _allTestsCompleted() {
    return completedPhonemes.values.every((count) => count > 0);
  }

  // 上傳結果並顯示對話框
  void _uploadResults(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _UploadDialog(completedPhonemes: completedPhonemes);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        title: const Text(
          "發音練習",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87), // 確保返回按鈕是黑色的
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30), // 調整底部間距
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "請依序完成以下三個音節測試。\n每個測試持續10秒，請盡可能多次且清晰地發出指定音節。",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 使用 ListView 來放置按鈕，使其更具擴展性
            ListView(
              shrinkWrap: true, // 讓 ListView 只佔用所需空間
              physics: const NeverScrollableScrollPhysics(), // 在此佈局中不需要滾動
              children: [
                _buildPhonemeButton(context, "PA"),
                const SizedBox(height: 15),
                _buildPhonemeButton(context, "TA"),
                const SizedBox(height: 15),
                _buildPhonemeButton(context, "KA"),
              ],
            ),
            const Spacer(), // 使用 Spacer 將按鈕推至底部
            // 顯示已完成的測試
            if (!_allTestsCompleted())
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Text(
                  "已完成：${completedPhonemes.entries.where((e) => e.value > 0).map((e) => e.key).join('、')}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _allTestsCompleted() ? () => _uploadResults(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _allTestsCompleted() ? "查看並上傳結果" : "完成所有測試以上傳",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        _allTestsCompleted() ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 新的卡片式按鈕設計
  Widget _buildPhonemeButton(BuildContext context, String phoneme) {
    final bool isCompleted = completedPhonemes[phoneme]! > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => _navigateToDetectionScreen(context, phoneme),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Row(
            children: [
              // 左側圓形標示
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF2ECC71)
                      : const Color(0xFF4A90E2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    phoneme,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // 中間的文字說明
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "音節 ${phoneme} 測試",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isCompleted ? "已完成" : "點擊開始測試",
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            isCompleted ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 右側的圖示
              if (isCompleted)
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 28,
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 上傳對話框元件
class _UploadDialog extends StatefulWidget {
  final Map<String, int> completedPhonemes;

  const _UploadDialog({required this.completedPhonemes});

  @override
  State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog> {
  bool isUploading = true;
  bool uploadSuccess = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _performUpload();
  }

  Future<void> _performUpload() async {
    try {
      await endout9(completedPhonemes: widget.completedPhonemes);
      setState(() {
        isUploading = false;
        uploadSuccess = true;
      });
    } catch (e) {
      setState(() {
        isUploading = false;
        uploadSuccess = false;
        errorMessage = '上傳失敗，請檢查您的網路連線';
      });
      print("Error uploading results: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUploading) ...[
              const Text(
                "測試完成！",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 15),
              Text(
                'PA: ${widget.completedPhonemes["PA"]} / TA: ${widget.completedPhonemes["TA"]} / KA: ${widget.completedPhonemes["KA"]}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A90E2),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                "正在上傳結果，請稍候...",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ] else if (uploadSuccess) ...[
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2ECC71),
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                "上傳成功！",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 15),
              Text(
                'PA: ${widget.completedPhonemes["PA"]} / TA: ${widget.completedPhonemes["TA"]} / KA: ${widget.completedPhonemes["KA"]}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A90E2),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 關閉對話框
                  Navigator.pop(context);
                  Navigator.pop(context);
                  // // 返回到根頁面，然後導航到 TrainmouthWidget
                  // Navigator.popUntil(context, (route) => route.isFirst);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TrainmouthWidget()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "返回",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                "上傳失敗",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 15),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isUploading = true;
                        uploadSuccess = false;
                        errorMessage = '';
                      });
                      _performUpload();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "重試",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // 關閉對話框
                      // 返回到根頁面，然後導航到 TrainmouthWidget
                      Navigator.popUntil(context, (route) => route.isFirst);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TrainmouthWidget()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF4A90E2)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "返回",
                      style: TextStyle(
                        color: Color(0xFF4A90E2),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// **第二個畫面：偵測聲音**
class SoundDetectionScreen extends StatefulWidget {
  final String selectedPhoneme;
  final Function(int) onComplete; // 新增回調函數，用於報告完成狀態

  const SoundDetectionScreen({
    super.key,
    required this.selectedPhoneme,
    required this.onComplete,
  });

  @override
  State<SoundDetectionScreen> createState() => _SoundDetectionScreenState();
}

class _SoundDetectionScreenState extends State<SoundDetectionScreen>
    with SingleTickerProviderStateMixin {
  NoiseMeter? _noiseMeter;
  IOSAudioProcessor? _iosAudioProcessor; // 重新啟用 iOS 音訊處理器
  StreamSubscription<NoiseReading>? _noiseSubscription;
  StreamSubscription<double>? _iosAudioSubscription; // iOS 音訊訂閱
  bool _isListening = false;
  double _soundLevel = 0.0;
  int _wordCount = 0;
  bool _hasAddedWord = false;

  // 平台特定的音量閾值和檢測參數
  double _dBThreshold = Platform.isIOS ? 75.0 : 75.0; // 調整 Android 預設閾值為 75.0

  // 新增：iOS 特定的音節檢測參數
  DateTime? _lastDetectionTime;
  bool _isCurrentlyLoud = false;

  // 動畫控制
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // 倒數計時
  Timer? _countdownTimer;
  int _remainingTime = 10; // 設定倒數 10 秒

  @override
  void initState() {
    super.initState();
    _initializePlatformSpecificSettings(); // 添加平台特定初始化
    _requestPermissions();

    /// 請求麥克風權限

    // 動畫：讓氣泡變大縮小
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 動畫時間 500ms
      lowerBound: 1.0,
      upperBound: 2, // 放大 2 倍
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.3).animate(_animationController);

    ///開始後大小
  }

  // 添加平台特定設置初始化
  void _initializePlatformSpecificSettings() {
    if (Platform.isIOS) {
      print('iOS 平台：使用優化的音量閾值設定');
      // iOS 可能需要更精確的調整
    } else {
      print('Android 平台：使用 noise_meter 3.0.1 優化設定');
      print('Android 預設閾值: $_dBThreshold dB');
      // 針對 noise_meter 3.0.1 的特殊設定
    }
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.microphone.status;

    // Android 加強權限檢查
    if (!Platform.isIOS) {
      print('Android 權限檢查: 當前狀態 $status');

      if (!status.isGranted) {
        print('Android 請求麥克風權限...');
        status = await Permission.microphone.request();
        print('Android 權限請求結果: $status');
      }

      // 檢查權限是否真的被授予
      if (!status.isGranted) {
        print('Android 權限被拒絕，無法進行音訊檢測');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要麥克風權限才能進行音節檢測'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('Android 麥克風權限已授予');
      }
    }

    // iOS 特殊處理：確保權限狀態穩定
    if (Platform.isIOS && status.isGranted) {
      await Future.delayed(const Duration(milliseconds: 300));
      print('iOS 權限確認完成');
    }
  }

  void _startListening() {
    if (_isListening) return;

    _resetValues(); // 重置計數與變數

    if (Platform.isIOS) {
      _startIOSAudioProcessing();
    } else {
      _startAndroidAudioProcessing();
    }

    _startCountdown();
    setState(() => _isListening = true);
    print(
        '開始音量偵測 - 平台: ${Platform.isIOS ? "iOS (原生)" : "Android"}, 閾值: $_dBThreshold dB');
  }

  // 新增：iOS 原生音訊處理
  void _startIOSAudioProcessing() {
    print('啟動 iOS 原生音訊處理...');
    _iosAudioProcessor ??= IOSAudioProcessor();

    try {
      _iosAudioSubscription = _iosAudioProcessor!.volumeStream.listen(
        (volume) {
          _updateVolumeDetection(volume);
        },
        onError: (error) {
          print('iOS 音訊流錯誤: $error');
          _restartIOSAudioProcessing();
        },
        onDone: () {
          print('iOS 音訊流結束');
        },
      );

      _iosAudioProcessor!.startListening().then((_) {
        print('iOS 音訊處理器啟動成功');
      }).catchError((error) {
        print('iOS 音訊處理器啟動失敗: $error');
        _stopListening();
      });
    } catch (e) {
      debugPrint('iOS 音訊處理啟動失敗: $e');
      _stopListening();
    }
  }

  // 新增：重新啟動 iOS 音訊處理
  void _restartIOSAudioProcessing() {
    print('嘗試重新啟動 iOS 音訊處理...');
    if (_isListening && Platform.isIOS) {
      _iosAudioProcessor?.stopListening().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isListening) {
            _startIOSAudioProcessing();
          }
        });
      });
    }
  }

  // Android 音訊處理 - 改善版本
  void _startAndroidAudioProcessing() {
    print('啟動 Android 音訊處理 (noise_meter 3.0.1)...');

    try {
      // 檢查權限狀態
      Permission.microphone.status.then((status) {
        if (!status.isGranted) {
          print('Android 音訊處理失敗：麥克風權限未授予');
          _stopListening();
          return;
        }

        // 權限正常，初始化 NoiseMeter
        _initializeNoiseMeter();
      });
    } catch (e) {
      print('Android 音訊處理啟動失敗: $e');
      _showAndroidError('音訊處理啟動失敗: $e');
      _stopListening();
    }
  }

  // 新增：Android NoiseMeter 初始化方法
  void _initializeNoiseMeter() {
    try {
      print('初始化 Android NoiseMeter...');
      _noiseMeter ??= NoiseMeter();

      _noiseSubscription = _noiseMeter!.noise.listen(
        (NoiseReading noiseEvent) {
          // 檢查數據有效性
          if (noiseEvent.meanDecibel.isNaN ||
              noiseEvent.meanDecibel.isInfinite) {
            print('Android 接收到無效音量數據: ${noiseEvent.meanDecibel}');
            return;
          }

          // 更新音量檢測
          _updateVolumeDetection(noiseEvent.meanDecibel);
        },
        onError: (error) {
          print('Android 噪音偵測錯誤: $error');
          _showAndroidError('音訊檢測錯誤: $error');
          _stopListening();
        },
        onDone: () {
          print('Android 音訊流結束');
        },
      );

      print('Android NoiseMeter 初始化成功');
    } catch (e) {
      print('Android NoiseMeter 初始化失敗: $e');
      _showAndroidError('音訊初始化失敗: $e');
      _stopListening();
    }
  }

  // 新增：Android 錯誤顯示方法
  void _showAndroidError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Android 音訊錯誤: $message'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _stopListening() {
    if (Platform.isIOS) {
      _iosAudioSubscription?.cancel();
      _iosAudioSubscription = null;
      _iosAudioProcessor?.stopListening();
    } else {
      // Android 清理 - 加強版本
      print('停止 Android 音訊處理...');
      try {
        _noiseSubscription?.cancel();
        _noiseSubscription = null;
        _noiseMeter = null;
        print('Android 音訊處理已清理');
      } catch (e) {
        print('Android 音訊清理錯誤: $e');
      }
    }

    _countdownTimer?.cancel();
    setState(() {
      _isListening = false;
      _animationController.reverse();
    });
  }

  void _resetValues() {
    setState(() {
      _wordCount = 0;
      _soundLevel = 0.0;
      _hasAddedWord = false;
      _remainingTime = 10; // 重置倒數

      // 重置 iOS 特定變數
      _lastDetectionTime = null;
      _isCurrentlyLoud = false;
    });
  }

  // 新增：統一的音量檢測方法
  void _updateVolumeDetection(double currentVolume) {
    setState(() {
      _soundLevel = currentVolume;

      if (Platform.isIOS) {
        _detectSyllableIOS(currentVolume);
      } else {
        _detectSyllableAndroid(currentVolume);
      }
    });
  }

  // Android 音節檢測邏輯 - 改善版本
  void _detectSyllableAndroid(double currentVolume) {
    // 數據有效性檢查
    if (currentVolume.isNaN || currentVolume.isInfinite) {
      print('Android 接收到無效音量: $currentVolume');
      return;
    }

    // 音量範圍檢查 (noise_meter 3.0.1 通常輸出 0-120 dB)
    if (currentVolume < 0 || currentVolume > 150) {
      print('Android 音量超出正常範圍: $currentVolume dB (noise_meter 3.0.1)');
      return;
    }

    // noise_meter 3.0.1 特殊處理：過濾異常低值
    if (currentVolume < 30.0) {
      // 可能是背景噪音或靜音，不進行檢測
      return;
    }

    if (currentVolume > _dBThreshold) {
      if (!_hasAddedWord) {
        _wordCount++;
        _hasAddedWord = true;
        print(
            'Android (noise_meter 3.0.1) 偵測到音節 #$_wordCount，當前音量: ${currentVolume.toStringAsFixed(1)} dB，閾值: ${_dBThreshold.toStringAsFixed(1)} dB');
      }
      _animationController.forward();
    } else {
      _hasAddedWord = false;
      _animationController.reverse();
    }
  }

  // 簡化的 iOS 音節檢測邏輯 - 使用原始振幅
  void _detectSyllableIOS(double currentVolume) {
    DateTime now = DateTime.now();
    bool isLoudNow = currentVolume > _dBThreshold;

    // 極簡邊緣檢測：直接比較當前和前一個狀態
    if (isLoudNow && !_isCurrentlyLoud) {
      // 上升邊緣：新音節開始
      if (_lastDetectionTime == null ||
          now.difference(_lastDetectionTime!).inMilliseconds > 150) {
        _wordCount++;
        _lastDetectionTime = now;
        _isCurrentlyLoud = true;
        print(
            'iOS 原始振幅音節檢測 (#$_wordCount): ${currentVolume.toStringAsFixed(1)} dB');
        _animationController.forward();
      }
    } else if (!isLoudNow && _isCurrentlyLoud) {
      // 下降邊緣：音節結束
      _isCurrentlyLoud = false;
      _animationController.reverse();
    }
  }

  // **開始倒數計時**
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 1) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        _finishTest(); // 完成測試
      }
    });
  }

  // 完成測試，返回上一畫面
  void _finishTest() {
    _stopListening();
    // 回調通知完成了測試並傳遞字數
    widget.onComplete(_wordCount);
    Navigator.pop(context); // 返回上一畫面
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text("正在測試：${widget.selectedPhoneme}"),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              _buildTopInfoPanel(),
              const Spacer(),
              _buildAnimatedBubble(),
              const Spacer(),
              _buildThresholdSlider(),
              const SizedBox(height: 20),
              _buildStartStopButton(),
            ],
          ),
        ),
      ),
    );
  }

  // UI 組件：頂部資訊面板
  Widget _buildTopInfoPanel() {
    return Row(
      children: [
        Expanded(child: _buildCountdownTimer()),
        const SizedBox(width: 20),
        Expanded(child: _buildWordCountDisplay()),
      ],
    );
  }

  // UI 組件：發音動畫氣泡
  Widget _buildAnimatedBubble() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A9BEE), Color(0xFF4A90E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2)
                          .withOpacity(0.4 - (_scaleAnimation.value - 1) / 2),
                      blurRadius: 15 + (_scaleAnimation.value - 1) * 10,
                      spreadRadius: (_scaleAnimation.value - 1) * 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.selectedPhoneme,
                    style: const TextStyle(
                      fontSize: 70,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        Text(
          _isListening ? "請對著麥克風大聲發音！" : "點擊「開始測試」以進行錄音",
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // UI 組件：開始/停止按鈕
  Widget _buildStartStopButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isListening ? _stopListening : _startListening,
        icon: Icon(_isListening ? Icons.stop_circle_outlined : Icons.mic,
            color: Colors.white),
        label: Text(
          _isListening ? '停止測試' : '開始測試',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isListening ? Colors.redAccent : const Color(0xFF4A90E2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // UI 組件：倒數計時器
  Widget _buildCountdownTimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.timer_outlined, color: Colors.black54, size: 20),
              SizedBox(width: 8),
              Text(
                "剩餘時間",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _remainingTime / 10.0,
                  strokeWidth: 7,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFF76B6B)),
                ),
                Center(
                  child: Text(
                    "$_remainingTime",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF76B6B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UI 組件：音節計數顯示
  Widget _buildWordCountDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.record_voice_over_outlined,
                  color: Colors.black54, size: 20),
              SizedBox(width: 8),
              Text(
                "音節數量",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: Center(
              child: Text(
                "$_wordCount",
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                  height: 1.1, // Adjust line height to center better
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI 組件：偵測門檻滑桿
  Widget _buildThresholdSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "偵測靈敏度 (${Platform.isIOS ? 'iOS' : 'Android'})",
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                ),
                Text(
                  _isListening ? "測試中無法調整" : "可左右滑動調整",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 顯示當前即時音量和平台資訊
          Column(
            children: [
              Text(
                '當前音量: ${_soundLevel.toStringAsFixed(1)} dB',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _soundLevel > _dBThreshold
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _soundLevel > _dBThreshold
                      ? Colors.green
                      : Colors.black87,
                ),
              ),
              Text(
                '平台建議範圍: ${Platform.isIOS ? "50-90" : "55-95"} dB', // 調整 Android 建議範圍
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4A90E2),
              inactiveTrackColor: Colors.blue[100],
              trackShape: const RoundedRectSliderTrackShape(),
              trackHeight: 4.0,
              thumbColor: const Color(0xFF4A90E2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
              overlayColor: const Color(0xFF4A90E2).withAlpha(32),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
            ),
            child: Slider(
              value: _dBThreshold.clamp(Platform.isIOS ? 50.0 : 55.0,
                  Platform.isIOS ? 90.0 : 95.0), // 調整 Android 範圍
              min: Platform.isIOS ? 50.0 : 55.0, // 調整 Android 最小值
              max: Platform.isIOS ? 90.0 : 95.0, // 調整 Android 最大值
              divisions: Platform.isIOS ? 20 : 20, // 每2dB一個刻度
              label: _dBThreshold.toStringAsFixed(0),
              onChanged: _isListening
                  ? null // 測試進行中不可調整
                  : (value) {
                      setState(() {
                        ///更新 _dBThreshold 的數值
                        _dBThreshold = value;
                        print(
                            '調整音量閾值: $_dBThreshold dB (${Platform.isIOS ? "iOS" : "Android noise_meter 3.0.1"})'); // 加入版本資訊
                      });
                    },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('正在清理音訊資源...');

    // 先停止監聽，確保所有訂閱都被取消
    _stopListening();

    // 平台特定清理
    if (Platform.isIOS) {
      _iosAudioProcessor?.dispose(); // 保持 iOS 清理不變
    } else {
      // Android 特定清理
      print('清理 Android 音訊資源...');
      try {
        _noiseSubscription?.cancel();
        _noiseSubscription = null;
        _noiseMeter = null;
        print('Android 音訊資源清理完成');
      } catch (e) {
        print('Android 資源清理錯誤: $e');
      }
    }

    // 清理動畫控制器
    try {
      _animationController.dispose();
    } catch (e) {
      print('動畫控制器清理錯誤: $e');
    }

    // 清理計時器
    _countdownTimer?.cancel();
    _countdownTimer = null;

    print('音訊資源清理完成');
    super.dispose();
  }
}

Future<void> endout9({required Map<String, int> completedPhonemes}) async {
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd').format(now);
  var url;
  if (Face_Detect_Number == 9) {
    //抿嘴
    url = Uri.parse(ip + "train_mouthok.php");
    print("初階,吞嚥");
  }
  String final_Phonemes =
      "${completedPhonemes["PA"]}/ ${completedPhonemes["TA"]}/ ${completedPhonemes["KA"]}";
  final responce = await http.post(url, body: {
    "time": formattedDate,
    "account": FFAppState().accountnumber.toString(),
    "action": FFAppState().mouth.toString(), //動作
    "degree": "初階",
    "parts": "吞嚥",
    "times": "1", //動作
    "rsst_test_times": "",
    "PA_TA_KA": final_Phonemes,
    "coin_add": "5",
  });
  if (responce.statusCode == 200) {
    print("ok");
  } else {
    print(responce.statusCode);
    print("no");
  }
}
