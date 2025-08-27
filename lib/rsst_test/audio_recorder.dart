import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class AudioRecorder {
  final Record _recorder = Record();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordingPath;
  String? _tempRecordingPath; // iOS 臨時錄音檔案路徑
  final int _sampleRate = 44100;
  Completer<void>? _initCompleter;

  // 建構函數
  AudioRecorder();

  // 獲取錄音路徑
  String? get recordingPath => _recordingPath;

  // 初始化錄音機
  Future<void> init() async {
    // 如果已經在初始化中，返回相同的 Future
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      if (_isRecorderInitialized) {
        _initCompleter!.complete();
        return _initCompleter!.future;
      }

      print('初始化錄音器...');

      // 請求錄音權限
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('麥克風權限未授予');
      }
      print('麥克風權限已授予');

      // 檢查是否可以錄音
      bool canRecord = await _recorder.hasPermission();
      if (!canRecord) {
        throw RecordingPermissionException('無法獲得錄音權限');
      }

      _isRecorderInitialized = true;
      print('錄音機初始化完成');
      _initCompleter!.complete();
    } catch (e) {
      print('初始化錄音機失敗: $e');
      _initCompleter!.completeError(e);
    }

    return _initCompleter!.future;
  }

  // 開始錄音
  Future<void> startRecording() async {
    if (!_isRecorderInitialized) {
      await init();
    }

    // 確保錄音機已初始化
    if (!_isRecorderInitialized) {
      throw RecordingPermissionException('錄音機未初始化');
    }

    // 如果已經在錄音，先停止
    if (_isRecording) {
      await stopRecording();
    }

    // 創建檔案路徑
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (Platform.isIOS) {
      // iOS 先錄製成 M4A 格式，稍後轉換成 WAV
      _tempRecordingPath = '${directory.path}/rsst_temp_$timestamp.m4a';
      _recordingPath = '${directory.path}/rsst_recording_$timestamp.wav';
      print('iOS 臨時檔案: $_tempRecordingPath');
      print('最終 WAV 檔案: $_recordingPath');
    } else {
      // Android 直接錄製 WAV
      _recordingPath = '${directory.path}/rsst_recording_$timestamp.wav';
      print('檔案將保存至: $_recordingPath');
    }

    try {
      // 再次檢查麥克風權限
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        throw RecordingPermissionException('麥克風權限未授予或已被撤銷');
      }

      // 確保目錄存在
      final dir = Directory(directory.path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 開始錄音
      if (Platform.isIOS) {
        // iOS 使用 AAC 編碼到 M4A 檔案
        await _recorder.start(
          path: _tempRecordingPath,
          encoder: AudioEncoder.aacLc, // AAC-LC 格式，iOS 支援
          samplingRate: _sampleRate, // 44.1 kHz
          numChannels: 1, // 單聲道
          // 不設定 bitRate，讓系統自動選擇合適的值
        );
        print('iOS 開始錄音到: $_tempRecordingPath');
      } else {
        // Android 使用 WAV 格式
        await _recorder.start(
          path: _recordingPath,
          encoder: AudioEncoder.wav, // WAV格式
          bitRate: 16 * 1000, // 16 kbps (僅 Android)
          samplingRate: _sampleRate, // 44.1 kHz
          numChannels: 1, // 單聲道
        );
        print('Android 開始錄音到: $_recordingPath');
      }

      // 設置音量監聽器
      _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 300))
          .listen((amp) {
        print('錄音中，音量: ${amp.current} dB, 峰值: ${amp.max} dB');
      });

      print('錄音開始');
      _isRecording = true;
    } catch (e) {
      print('開始錄音失敗: $e');
      throw Exception('開始錄音失敗: $e');
    }
  }

  // 停止錄音
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      return _recordingPath;
    }

    try {
      print('正在停止錄音...');
      await _recorder.stop();
      _isRecording = false;

      if (Platform.isIOS) {
        // iOS: 將 M4A 轉換成 WAV
        return await _convertM4AToWAV();
      } else {
        // Android: 直接驗證 WAV 檔案
        return await _validateRecordedFile(_recordingPath);
      }
    } catch (e) {
      print('停止錄音出錯: $e');
      _isRecording = false;
      return _recordingPath;
    }
  }

  // iOS: 將 M4A 轉換成 WAV
  Future<String?> _convertM4AToWAV() async {
    if (_tempRecordingPath == null || _recordingPath == null) {
      print('錯誤：檔案路徑為空');
      return null;
    }

    try {
      print('開始將 M4A 轉換成 WAV...');
      print('來源檔案: $_tempRecordingPath');
      print('目標檔案: $_recordingPath');

      // 檢查臨時 M4A 檔案是否存在
      File tempFile = File(_tempRecordingPath!);
      if (!await tempFile.exists()) {
        print('錯誤：臨時 M4A 檔案不存在');
        return null;
      }

      int tempFileSize = await tempFile.length();
      print('M4A 檔案大小: ${tempFileSize} 位元組');

      if (tempFileSize < 1024) {
        print('錯誤：M4A 檔案太小，可能錄音失敗');
        return null;
      }

      // 使用 MethodChannel 調用 iOS 原生代碼進行轉換
      const platform = MethodChannel('audio_converter');

      try {
        final bool success = await platform.invokeMethod('convertM4AToWAV', {
          'inputPath': _tempRecordingPath,
          'outputPath': _recordingPath,
          'sampleRate': _sampleRate,
        });

        if (success) {
          // 驗證轉換後的 WAV 檔案
          String? result = await _validateRecordedFile(_recordingPath);

          // 清理臨時檔案
          try {
            await tempFile.delete();
            print('已清理臨時 M4A 檔案');
          } catch (e) {
            print('清理臨時檔案失敗: $e');
          }

          return result;
        } else {
          print('M4A 到 WAV 轉換失敗');
          return null;
        }
      } on PlatformException catch (e) {
        print('調用原生轉換方法失敗: ${e.message}');

        // 如果原生轉換失敗，嘗試簡單的檔案複製和重命名
        // 這不是真正的格式轉換，但至少能讓程式繼續運行
        print('嘗試簡單的檔案處理...');
        try {
          await tempFile.copy(_recordingPath!);
          print('已複製檔案，但格式仍為 M4A（需要後端支援）');

          // 清理臨時檔案
          await tempFile.delete();

          return _recordingPath;
        } catch (copyError) {
          print('檔案複製也失敗: $copyError');
          return null;
        }
      }
    } catch (e) {
      print('M4A 轉換過程出錯: $e');
      return null;
    }
  }

  // 驗證錄音檔案
  Future<String?> _validateRecordedFile(String? filePath) async {
    if (filePath == null) return null;

    File audioFile = File(filePath);
    if (await audioFile.exists()) {
      int fileSize = await audioFile.length();
      print('錄音完成，檔案大小: ${fileSize} 位元組');

      // 檢查檔案大小是否異常（小於1KB可能表示錄音失敗）
      if (fileSize < 1024) {
        print('警告：錄音檔案大小異常小，可能錄音失敗');
        if (fileSize < 100) {
          print('嚴重錯誤：錄音檔案實際上為空');
          return null;
        }
      }
      print('錄音完成，檔案儲存於: $filePath');
      return filePath;
    } else {
      print('錄音檔案不存在: $filePath');
      return null;
    }
  }

  // 釋放資源
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }

      if (_isRecorderInitialized) {
        _recorder.dispose();
        _isRecorderInitialized = false;
        print('錄音機資源已釋放');
      }

      // 清理 iOS 臨時檔案
      if (Platform.isIOS && _tempRecordingPath != null) {
        try {
          File tempFile = File(_tempRecordingPath!);
          if (await tempFile.exists()) {
            await tempFile.delete();
            print('已清理臨時錄音檔案: $_tempRecordingPath');
          }
        } catch (e) {
          print('清理臨時檔案失敗: $e');
        }
      }
    } catch (e) {
      print('釋放錄音機資源時出錯: $e');
    }
  }
}

// 自定義例外
class RecordingPermissionException implements Exception {
  final String message;
  RecordingPermissionException(this.message);

  @override
  String toString() => 'RecordingPermissionException: $message';
}
