import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'audio_processor.dart';

class SwallowDetector {
  late final OrtSession _session;
  bool _initialized = false;

  final double _threshold      = 0.7;  // 吞嚥判定閾值
  final double _minStartTime   = 2.5;  // 忽略前 2.5 秒
  final double _cooldownPeriod = 1;  // 冷卻期長度

  // 新增確認相關參數
  final int _maxConfirmationWindows = 4;  // 最大確認窗口數（包括候選窗口）
  final int _requiredConfirmations = 2;   // 需要的最小確認次數（包括候選窗口）

  /// 初始化 ONNX Runtime 環境並載入模型
  Future<void> init() async {
    if (_initialized) return;
    // 1) 初始化 ORT 環境（無回傳值）
    OrtEnv.instance.init();

    // 2) 讀取模型 bytes
    final raw = await rootBundle.load(
        'assets/model/rsst_integrated_2k2_cnn_att2_2_ir9.onnx'
    );
    final modelBytes = raw.buffer.asUint8List();

    // 3) 建立 Session
    _session = OrtSession.fromBuffer(
      modelBytes,
      OrtSessionOptions(),
    );
    _initialized = true;
  }

  /// 針對一系列 AudioSegment 執行吞嚥偵測
  Future<Map<String, dynamic>> detectSwallows(
      List<AudioSegment> segments
      ) async {
    await init();

    List<double> swallowTimes = [];
    List<double> swallowProbs = [];
    bool inCooldown = false;
    double cooldownEnd = 0.0;

    for (int i = 0; i < segments.length; i++) {
      var seg = segments[i];
      final ts = seg.startTime;
      if (ts < _minStartTime) continue;
      if (inCooldown && ts < cooldownEnd) continue;
      inCooldown = false;

      // 1) 讀取並解析 PCM
      final bytes = await File(seg.path).readAsBytes();
      final wavInfo = AudioProcessor.parseWavHeader(bytes);
      final pcm = bytes.sublist(wavInfo['headerSize'] as int);
      final floatData = AudioProcessor.convertPcmToFloat(
        pcm,
        wavInfo['channels'] as int,
        wavInfo['bitsPerSample'] as int,
      );
      final List<double> dbl = floatData.toList();

      // 2) 建立輸入張量
      final tensor = OrtValueTensor.createTensorWithDataList(
        Float32List.fromList(dbl.map((e) => e.toDouble()).toList()),
        [1, dbl.length],
      );

      // 3) 非同步推論
      final inputs = <String, OrtValue>{'input': tensor};
      final runOpts = OrtRunOptions();
      final outputs = await _session.runAsync(runOpts, inputs) ?? [];
      runOpts.release();

      if (outputs.isEmpty) {
        tensor.release();
        throw Exception('模型無輸出');
      }

      // 4) 取回結果並 sigmoid
      final outVal = outputs[0] as OrtValueTensor;
      final resultData = outVal.value as List<dynamic>;
      double raw;

      // 檢查實際類型並正確提取值
      if (resultData[0] is List) {
        // 如果是嵌套列表，提取第一個元素
        raw = (resultData[0] as List<dynamic>)[0].toDouble();
      } else if (resultData[0] is num) {
        // 如果直接是數字，直接轉換
        raw = (resultData[0] as num).toDouble();
      } else {
        // 記錄未知類型情況
        throw Exception('意外的模型輸出類型: ${resultData[0].runtimeType}');
      }

      final prob = 1 / (1 + math.exp(-raw));

      // 5) 釋放資源
      tensor.release();
      outVal.release();

      // 新增: 候選確認機制
      // 如果當前概率超過閾值，檢查後續窗口
      if (prob > _threshold) {
        // 計算確認窗口的範圍（包括當前窗口）
        int endIdx = math.min(i + _maxConfirmationWindows, segments.length);

        // 確認計數（當前窗口已經算一次）
        int confirmationCount = 1;

        // 檢查後續窗口
        for (int j = i + 1; j < endIdx; j++) {
          var confirmSeg = segments[j];

          // 對確認窗口進行推論
          try {
            double confirmProb = await _inferProbability(confirmSeg);

            if (confirmProb > _threshold) {
              confirmationCount++;
            }
          } catch (e) {
            print('確認窗口推論出錯 (時間=${confirmSeg.startTime.toStringAsFixed(2)}秒): $e');
            continue;
          }
        }

        // 如果確認次數達到要求
        if (confirmationCount >= _requiredConfirmations) {
          swallowTimes.add(ts);
          swallowProbs.add(prob);

          // 設置冷卻期
          inCooldown = true;
          cooldownEnd = ts + _cooldownPeriod;

          print('確認吞嚥: 時間=${ts.toStringAsFixed(2)}秒, 概率=${prob.toStringAsFixed(4)}, 確認次數=$confirmationCount');
        } else {
          print('候選吞嚥未確認: 時間=${ts.toStringAsFixed(2)}秒, 確認次數=$confirmationCount (需要$_requiredConfirmations次)');
        }

        // 跳過已經檢查過的窗口，避免重複處理
        i = endIdx - 1;
      }
    }

    return {
      'swallowTimes': swallowTimes,
      'swallowProbs': swallowProbs,
      'swallowCount': swallowTimes.length,
    };
  }

  // 新增: 輔助方法，對單個音頻段進行推論
  Future<double> _inferProbability(AudioSegment seg) async {
    // 讀取並解析 PCM
    final bytes = await File(seg.path).readAsBytes();
    final wavInfo = AudioProcessor.parseWavHeader(bytes);
    final pcm = bytes.sublist(wavInfo['headerSize'] as int);
    final floatData = AudioProcessor.convertPcmToFloat(
      pcm,
      wavInfo['channels'] as int,
      wavInfo['bitsPerSample'] as int,
    );
    final List<double> dbl = floatData.toList();

    // 建立輸入張量
    final tensor = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList(dbl.map((e) => e.toDouble()).toList()),
      [1, dbl.length],
    );

    // 非同步推論
    final inputs = <String, OrtValue>{'input': tensor};
    final runOpts = OrtRunOptions();
    final outputs = await _session.runAsync(runOpts, inputs) ?? [];
    runOpts.release();

    if (outputs.isEmpty) {
      tensor.release();
      throw Exception('模型無輸出');
    }

    // 取回結果並 sigmoid
    final outVal = outputs[0] as OrtValueTensor;
    final resultData = outVal.value as List<dynamic>;
    double raw;

    // 檢查實際類型並正確提取值
    if (resultData[0] is List) {
      raw = (resultData[0] as List<dynamic>)[0].toDouble();
    } else if (resultData[0] is num) {
      raw = (resultData[0] as num).toDouble();
    } else {
      throw Exception('意外的模型輸出類型: ${resultData[0].runtimeType}');
    }

    final prob = 1 / (1 + math.exp(-raw));

    // 釋放資源
    tensor.release();
    outVal.release();

    return prob;
  }

  /// 釋放資源
  void dispose() {
    if (_initialized) {
      _session.release();
      OrtEnv.instance.release();
    }
  }
}