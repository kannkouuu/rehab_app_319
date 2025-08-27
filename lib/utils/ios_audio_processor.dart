import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';

class IOSAudioProcessor {
  static const MethodChannel _methodChannel =
      MethodChannel('ios_audio_processor');
  static const EventChannel _eventChannel =
      EventChannel('ios_audio_processor_stream');

  StreamSubscription? _subscription;
  StreamController<double>? _volumeController;
  bool _isListening = false;

  Stream<double> get volumeStream {
    _volumeController ??= StreamController<double>.broadcast();
    return _volumeController!.stream;
  }

  Future<void> startListening() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('此處理器僅支援 iOS');
    }

    if (_isListening) {
      print('iOS 原始振幅處理器已在運行中');
      return;
    }

    try {
      print('正在啟動 iOS 原始振幅處理器...');

      // 啟動原生音訊處理
      await _methodChannel.invokeMethod('startAudioProcessing');

      // 監聽原生音量數據
      _subscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic data) {
          if (data is double) {
            _processRawVolumeData(data);
          } else if (data is int) {
            _processRawVolumeData(data.toDouble());
          } else {
            print('接收到非數值類型數據: $data (${data.runtimeType})');
          }
        },
        onError: (error) {
          print('iOS 原始音訊流錯誤: $error');
          _handleStreamError(error);
        },
        onDone: () {
          print('iOS 原始音訊流已結束');
          _isListening = false;
        },
      );

      _isListening = true;
      print('iOS 原始振幅處理器啟動成功');
    } catch (e) {
      print('啟動 iOS 原始振幅處理器失敗: $e');
      _isListening = false;
      rethrow;
    }
  }

  void _handleStreamError(dynamic error) {
    print('處理原始音訊流錯誤: $error');
    _isListening = false;
  }

  void _processRawVolumeData(double rawVolume) {
    // 檢查數據有效性
    if (rawVolume.isNaN || rawVolume.isInfinite) {
      print('接收到無效原始音量數據: $rawVolume');
      return;
    }

    // 直接使用原始數據，不進行任何平滑處理
    try {
      _volumeController?.add(rawVolume);
    } catch (e) {
      print('發送原始音量數據到控制器時出錯: $e');
    }
  }

  Future<void> stopListening() async {
    print('正在停止 iOS 原始振幅處理器...');

    await _subscription?.cancel();
    _subscription = null;

    try {
      await _methodChannel.invokeMethod('stopAudioProcessing');
      print('原生原始音訊處理已停止');
    } catch (e) {
      print('停止 iOS 原始振幅處理器失敗: $e');
    }

    _isListening = false;
    print('iOS 原始振幅處理器已停止');
  }

  bool get isListening => _isListening;

  void dispose() {
    print('釋放 iOS 原始振幅處理器資源...');
    stopListening();
    _volumeController?.close();
    _volumeController = null;
  }
}
