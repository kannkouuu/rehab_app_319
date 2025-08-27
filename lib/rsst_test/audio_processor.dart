import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fftea/fftea.dart';
import 'package:path/path.dart' as path_util;

class AudioSegment {
  final String path; // 分段音檔的儲存路徑
  final double startTime; // 開始時間（秒）
  final double endTime; // 結束時間（秒）
  final Uint8List? waveformData; // 波形數據（如有）

  AudioSegment({
    required this.path,
    required this.startTime,
    required this.endTime,
    this.waveformData,
  });
}

class AudioProcessor {
  static const int sampleRate = 44100; // 標準採樣率
  static const double windowSize = 0.5; // 窗口大小（秒）
  static const double hopSize = 0.1; // 步長（秒）

  // 巴特沃斯濾波器參數
  static const double butterLowCut = 100.0; // 低頻截止 (Hz)
  static const double butterHighCut = 3500.0; // 高頻截止 (Hz)
  static const int butterOrder = 5; // 濾波器階數

  // 頻譜閘控參數
  static const double noiseReductionStrength = 0.7; // 降噪強度 (0-1)
  static const int fftWindowSize = 2048; // FFT窗口大小

  /// 處理音頻 - 自動執行採樣率調整、降噪和分割
  static Future<Map<String, dynamic>> processAudio(String audioPath) async {
    try {
      // 1. 讀取原始音頻
      File audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('音檔不存在: $audioPath');
      }

      print('開始處理音頻: $audioPath');

      // 2. 讀取WAV文件
      Uint8List fileBytes = await audioFile.readAsBytes();

      // 3. 解析WAV頭部
      Map<String, dynamic> wavInfo = _parseWavHeader(fileBytes);
      int headerSize = wavInfo['headerSize'] as int;
      int originalSampleRate = wavInfo['sampleRate'] as int;
      int channels = wavInfo['channels'] as int;
      int bitsPerSample = wavInfo['bitsPerSample'] as int;

      print(
          '原始音頻信息: 採樣率=$originalSampleRate Hz, 聲道數=$channels, 位元深度=$bitsPerSample bits');

      // 4. 提取PCM數據
      Uint8List pcmData = fileBytes.sublist(headerSize);

      // 5. 檢查和調整採樣率
      Float64List adjustedSamples;
      int effectiveSampleRate = originalSampleRate;

      if (originalSampleRate != sampleRate) {
        print('採樣率不是44.1kHz，正在進行重新採樣...');

        // 將PCM數據轉換為浮點數組
        Float64List originalSamples =
            _convertPcmToFloat(pcmData, channels, bitsPerSample);

        // 進行採樣率轉換
        adjustedSamples =
            _resampleAudio(originalSamples, originalSampleRate, sampleRate);
        effectiveSampleRate = sampleRate; // 更新有效採樣率

        print('重新採樣完成：從 $originalSampleRate Hz 轉換為 $sampleRate Hz');
      } else {
        // 採樣率已經是44.1kHz，直接轉換為浮點數組
        adjustedSamples = _convertPcmToFloat(pcmData, channels, bitsPerSample);
      }

      // 6. 應用降噪處理
      print('應用組合降噪策略：巴特沃斯濾波 + 頻譜閘控');
      Float64List denoisedSamples = await compute(_applyDenoiseCombined, {
        'samples': adjustedSamples,
        'sampleRate': effectiveSampleRate,
        'lowCut': butterLowCut,
        'highCut': butterHighCut,
        'order': butterOrder,
        'noiseReductionStrength': noiseReductionStrength,
        'fftWindowSize': fftWindowSize,
      });

      // 7. 將浮點數組轉回PCM數據
      Uint8List denoisedPcm =
          _convertFloatToPcm(denoisedSamples, channels, bitsPerSample);

      // 8. 保存降噪後的完整音頻
      final tempDir = await getTemporaryDirectory();
      final uuid = Uuid();
      String denoisedFilename = 'denoised_${uuid.v4().toString()}.wav';
      File denoisedFile = File('${tempDir.path}/$denoisedFilename');

      // 9. 創建新的WAV文件頭部（使用標準44.1kHz採樣率）
      Uint8List header = _createWavHeader(
        fileSize: denoisedPcm.length + 36, // 資料大小 + 36 (頭部大小減去RIFF和大小欄位)
        sampleRate: sampleRate, // 使用標準採樣率
        channels: channels,
        bitsPerSample: bitsPerSample,
        dataSize: denoisedPcm.length,
      );

      // 10. 合併頭部和PCM數據並保存
      Uint8List denoisedWav = Uint8List(header.length + denoisedPcm.length);
      denoisedWav.setAll(0, header);
      denoisedWav.setAll(header.length, denoisedPcm);
      await denoisedFile.writeAsBytes(denoisedWav);

      print('降噪完成，降噪後音頻保存在: ${denoisedFile.path}');

      // 11. 分割降噪後的音頻（不限制數量）
      print('開始分割降噪後的音頻');
      List<AudioSegment> segments = await segmentAudio(denoisedFile.path);

      // 12. 返回處理結果
      return {
        'denoisedFilePath': denoisedFile.path,
        'segments': segments,
        'originalFilePath': audioPath,
        'originalSampleRate': originalSampleRate,
        'adjustedSampleRate': sampleRate,
        'channels': channels,
        'bitsPerSample': bitsPerSample,
        'totalSegments': segments.length,
      };
    } catch (e) {
      print('處理音頻時出錯: $e');
      rethrow;
    }
  }

  /// 解析WAV文件頭部
  static Map<String, dynamic> _parseWavHeader(Uint8List fileBytes) {
    if (fileBytes.length < 44) {
      throw Exception('無效的WAV文件 (太短)');
    }

    // 檢查是否是有效的WAV格式
    String riffHeader = String.fromCharCodes(fileBytes.sublist(0, 4));
    String waveHeader = String.fromCharCodes(fileBytes.sublist(8, 12));

    if (riffHeader != 'RIFF' || waveHeader != 'WAVE') {
      throw Exception('無效的WAV格式');
    }

    // 解析基本信息
    int fileSize = fileBytes[4] |
        (fileBytes[5] << 8) |
        (fileBytes[6] << 16) |
        (fileBytes[7] << 24);
    int format = fileBytes[20] | (fileBytes[21] << 8);
    int channels = fileBytes[22] | (fileBytes[23] << 8);
    int sampleRate = fileBytes[24] |
        (fileBytes[25] << 8) |
        (fileBytes[26] << 16) |
        (fileBytes[27] << 24);
    int byteRate = fileBytes[28] |
        (fileBytes[29] << 8) |
        (fileBytes[30] << 16) |
        (fileBytes[31] << 24);
    int blockAlign = fileBytes[32] | (fileBytes[33] << 8);
    int bitsPerSample = fileBytes[34] | (fileBytes[35] << 8);

    // 查找數據塊起始位置
    int headerSize = 44; // 標準WAV頭部大小

    if (String.fromCharCodes(fileBytes.sublist(36, 40)) != 'data') {
      // 如果不是標準布局，找到data塊
      int pos = 36;
      while (pos < fileBytes.length - 8) {
        String chunkId = String.fromCharCodes(fileBytes.sublist(pos, pos + 4));
        int chunkSize = fileBytes[pos + 4] |
            (fileBytes[pos + 5] << 8) |
            (fileBytes[pos + 6] << 16) |
            (fileBytes[pos + 7] << 24);

        if (chunkId == 'data') {
          headerSize = pos + 8;
          break;
        }
        pos += 8 + chunkSize;
      }
    }

    return {
      'fileSize': fileSize,
      'format': format,
      'channels': channels,
      'sampleRate': sampleRate,
      'byteRate': byteRate,
      'blockAlign': blockAlign,
      'bitsPerSample': bitsPerSample,
      'headerSize': headerSize,
    };
  }

  /// 重新採樣音頻
  static Float64List _resampleAudio(
      Float64List samples, int originalSampleRate, int targetSampleRate) {
    // 如果採樣率相同，則直接返回
    if (originalSampleRate == targetSampleRate) {
      return Float64List.fromList(samples);
    }

    // 計算重採樣後的樣本數
    double ratio = targetSampleRate / originalSampleRate;
    int outputLength = (samples.length * ratio).round();
    Float64List result = Float64List(outputLength);

    // 線性插值重採樣
    for (int i = 0; i < outputLength; i++) {
      // 計算在原始信號中的對應位置（連續的）
      double srcPos = i / ratio;

      // 獲取相鄰的兩個樣本
      int pos1 = srcPos.floor();
      int pos2 = pos1 + 1;

      // 確保位置在有效範圍內
      if (pos1 >= samples.length) pos1 = samples.length - 1;
      if (pos2 >= samples.length) pos2 = samples.length - 1;

      // 計算兩個位置之間的小數部分（用於插值）
      double frac = srcPos - pos1;

      // 線性插值
      result[i] = samples[pos1] * (1 - frac) + samples[pos2] * frac;
    }

    return result;
  }

  /// 將PCM數據轉換為浮點數數組進行處理
  static Float64List _convertPcmToFloat(
      Uint8List pcmData, int channels, int bitsPerSample) {
    int bytesPerSample = bitsPerSample ~/ 8;
    int samplesCount = pcmData.length ~/ (bytesPerSample * channels);
    Float64List result = Float64List(samplesCount);

    double maxValue = bitsPerSample == 16 ? 32768.0 : 128.0;

    // 只使用第一個聲道的數據
    for (int i = 0; i < samplesCount; i++) {
      int offset = i * channels * bytesPerSample;
      int sampleValue = 0;

      if (bitsPerSample == 16) {
        if (offset + 1 < pcmData.length) {
          sampleValue = pcmData[offset] | (pcmData[offset + 1] << 8);
          // 處理有符號數
          if (sampleValue > 32767) sampleValue -= 65536;
        }
      } else if (bitsPerSample == 8) {
        sampleValue = pcmData[offset] - 128; // 8位PCM是無符號的
      }

      // 歸一化到 -1.0 到 1.0
      result[i] = sampleValue / maxValue;
    }

    return result;
  }

  /// 將浮點數數組轉回PCM數據
  static Uint8List _convertFloatToPcm(
      Float64List samples, int channels, int bitsPerSample) {
    int bytesPerSample = bitsPerSample ~/ 8;
    Uint8List result = Uint8List(samples.length * channels * bytesPerSample);

    double maxValue = bitsPerSample == 16 ? 32768.0 : 128.0;

    for (int i = 0; i < samples.length; i++) {
      // 限制在-1.0到1.0範圍內
      double sample = math.max(-1.0, math.min(1.0, samples[i]));

      // 縮放到對應範圍
      int sampleValue = (sample * maxValue).round();

      // 處理溢出
      if (bitsPerSample == 16) {
        if (sampleValue < -32768) sampleValue = -32768;
        if (sampleValue > 32767) sampleValue = 32767;

        // 寫入所有聲道 (複製同樣的樣本到所有聲道)
        for (int ch = 0; ch < channels; ch++) {
          int offset = (i * channels + ch) * bytesPerSample;
          result[offset] = sampleValue & 0xFF;
          result[offset + 1] = (sampleValue >> 8) & 0xFF;
        }
      } else if (bitsPerSample == 8) {
        sampleValue += 128; // 轉換回8位無符號
        if (sampleValue < 0) sampleValue = 0;
        if (sampleValue > 255) sampleValue = 255;

        // 寫入所有聲道
        for (int ch = 0; ch < channels; ch++) {
          result[(i * channels + ch)] = sampleValue;
        }
      }
    }

    return result;
  }

  /// 在隔離的計算線程中應用組合降噪處理
  static Float64List _applyDenoiseCombined(Map<String, dynamic> params) {
    Float64List samples = params['samples'] as Float64List;
    int sampleRate = params['sampleRate'] as int;
    double lowCut = params['lowCut'] as double;
    double highCut = params['highCut'] as double;
    int order = params['order'] as int;
    double noiseReductionStrength = params['noiseReductionStrength'] as double;
    int fftWindowSize = params['fftWindowSize'] as int;

    // 1. 首先應用巴特沃斯帶通濾波
    Float64List filteredSamples =
        _butterworthBandpassFilter(samples, sampleRate, lowCut, highCut, order);

    // 2. 然後應用頻譜閘控降噪
    return _spectralGateNoiseReduction(
        filteredSamples, sampleRate, fftWindowSize, noiseReductionStrength);
  }

  /// 應用巴特沃斯帶通濾波器
  static Float64List _butterworthBandpassFilter(Float64List samples,
      int sampleRate, double lowCut, double highCut, int order) {
    // 實現數字巴特沃斯濾波器
    // 我們使用二階節(biquad)分段實現高階濾波器

    // 計算濾波器係數
    double nyquist = sampleRate / 2.0;
    double lowW = 2.0 * math.pi * lowCut / sampleRate;
    double highW = 2.0 * math.pi * highCut / sampleRate;

    // 使用雙線性變換計算濾波器係數
    double K = math.tan(math.pi * (highCut - lowCut) / (2 * sampleRate));
    double norm = 1 / (1 + K / 0.7071 + K * K);

    // 計算二階濾波器係數
    double a0 = K * K * norm;
    double a1 = 2 * a0;
    double a2 = a0;
    double b1 = 2 * (K * K - 1) * norm;
    double b2 = (1 - K / 0.7071 + K * K) * norm;

    // 應用濾波器
    Float64List result = Float64List(samples.length);

    // 初始化延遲線
    double x1 = 0, x2 = 0, y1 = 0, y2 = 0;

    for (int i = 0; i < samples.length; i++) {
      // 應用濾波器係數
      double x0 = samples[i];
      double y0 = a0 * x0 + a1 * x1 + a2 * x2 - b1 * y1 - b2 * y2;

      // 更新延遲線
      x2 = x1;
      x1 = x0;
      y2 = y1;
      y1 = y0;

      result[i] = y0;
    }

    return result;
  }

  /// 應用頻譜閘控降噪
  static Float64List _spectralGateNoiseReduction(Float64List samples,
      int sampleRate, int fftWindowSize, double reductionStrength) {
    int samplesLength = samples.length;
    Float64List result = Float64List(samplesLength);

    // 假設前1秒的音頻是噪聲
    int noiseLength = math.min(samplesLength, (2.5 * sampleRate).round());
    Float64List noiseProfile = samples.sublist(0, noiseLength);

    // 計算噪聲功率頻譜
    Float64List noiseSpectrum =
        _calculateAveragePowerSpectrum(noiseProfile, fftWindowSize);

    // 處理音頻段落
    int hopSize = fftWindowSize ~/ 4; // 75%重疊
    int numFrames = ((samplesLength - fftWindowSize) / hopSize).floor() + 1;

    // 創建Hann窗函數
    Float64List hannWindow = _createHannWindow(fftWindowSize);

    // 使用FFT進行頻譜處理
    var fft = FFT(fftWindowSize);

    // 創建輸出緩衝區，並以0初始化
    Float64List outputBuffer = Float64List(samplesLength + fftWindowSize);
    Float64List normalizationBuffer =
        Float64List(samplesLength + fftWindowSize);

    // 逐幀處理
    for (int frameIndex = 0; frameIndex < numFrames; frameIndex++) {
      int frameStart = frameIndex * hopSize;

      // 準備輸入緩衝區
      Float64List inputFrame = Float64List(fftWindowSize);
      for (int i = 0; i < fftWindowSize; i++) {
        int sampleIndex = frameStart + i;
        if (sampleIndex < samplesLength) {
          inputFrame[i] = samples[sampleIndex] * hannWindow[i];
        }
      }

      // 執行 FFT - 使用 realFft 方法
      Float64x2List complexSpectrum = fft.realFft(inputFrame);

      // 分離幅度和相位
      Float64List magnitudes = Float64List(complexSpectrum.length);
      Float64List phases = Float64List(complexSpectrum.length);

      for (int i = 0; i < complexSpectrum.length; i++) {
        Float64x2 complex = complexSpectrum[i];
        double real = complex.x; // 實部
        double imag = complex.y; // 虛部

        double magnitude = math.sqrt(real * real + imag * imag);
        double phase = math.atan2(imag, real);

        magnitudes[i] = magnitude;
        phases[i] = phase;
      }

      // 應用頻譜閘控
      for (int i = 0; i < magnitudes.length; i++) {
        // 計算信噪比並決定衰減因子
        double signalPower = magnitudes[i] * magnitudes[i];
        double noisePower = i < noiseSpectrum.length ? noiseSpectrum[i] : 0.0;

        double gainFactor = 1.0;
        if (noisePower > 0 && signalPower > 0) {
          double snr = signalPower / noisePower;
          if (snr < 1.0) {
            // 低於噪聲水平的分量被衰減
            gainFactor = math.max(0.0, 1.0 - reductionStrength * (1.0 - snr));
          }
        }

        // 應用衰減
        magnitudes[i] *= gainFactor;
      }

      // 準備逆FFT輸入 - 構建修改後的複數頻譜
      Float64x2List modifiedSpectrum = Float64x2List(complexSpectrum.length);
      for (int i = 0; i < complexSpectrum.length; i++) {
        double magnitude = magnitudes[i];
        double phase = phases[i];

        double real = magnitude * math.cos(phase);
        double imag = magnitude * math.sin(phase);

        modifiedSpectrum[i] = Float64x2(real, imag);
      }

      // 執行逆FFT
      Float64List outputFrame = fft.realInverseFft(modifiedSpectrum);

      // 疊加重構的信號
      for (int i = 0; i < fftWindowSize; i++) {
        int outputIndex = frameStart + i;
        if (outputIndex < outputBuffer.length) {
          outputBuffer[outputIndex] += outputFrame[i] * hannWindow[i];
          normalizationBuffer[outputIndex] += hannWindow[i] * hannWindow[i];
        }
      }
    }

    // 歸一化輸出
    for (int i = 0; i < samplesLength; i++) {
      if (normalizationBuffer[i] > 1e-10) {
        result[i] = outputBuffer[i] / normalizationBuffer[i];
      } else {
        result[i] = 0.0;
      }
    }

    return result;
  }

  /// 計算平均功率頻譜
  static Float64List _calculateAveragePowerSpectrum(
      Float64List samples, int fftSize) {
    var fft = FFT(fftSize);
    // 初始化功率頻譜陣列
    Float64List powerSpectrum = Float64List(fftSize ~/ 2 + 1);

    int hopSize = fftSize ~/ 2;
    int numFrames = ((samples.length - fftSize) / hopSize).floor() + 1;

    // 創建Hann窗函數
    Float64List hannWindow = _createHannWindow(fftSize);

    // 累積功率頻譜
    for (int frameIndex = 0; frameIndex < numFrames; frameIndex++) {
      int frameStart = frameIndex * hopSize;

      // 準備輸入緩衝區
      Float64List inputFrame = Float64List(fftSize);
      for (int i = 0; i < fftSize; i++) {
        int sampleIndex = frameStart + i;
        if (sampleIndex < samples.length) {
          inputFrame[i] = samples[sampleIndex] * hannWindow[i];
        }
      }

      // 執行FFT
      Float64x2List complexSpectrum = fft.realFft(inputFrame);

      // 計算功率頻譜 (處理複數頻譜)
      for (int i = 0; i < complexSpectrum.length; i++) {
        if (i < powerSpectrum.length) {
          Float64x2 complex = complexSpectrum[i];
          double real = complex.x;
          double imag = complex.y;
          powerSpectrum[i] += (real * real + imag * imag);
        }
      }
    }

    // 計算平均值
    if (numFrames > 0) {
      for (int i = 0; i < powerSpectrum.length; i++) {
        powerSpectrum[i] /= numFrames;
      }
    }

    return powerSpectrum;
  }

  /// 創建Hann窗函數
  static Float64List _createHannWindow(int size) {
    Float64List window = Float64List(size);
    for (int i = 0; i < size; i++) {
      window[i] = 0.5 * (1 - math.cos(2 * math.pi * i / (size - 1)));
    }
    return window;
  }

  /// 將音頻分割成指定的窗口大小與步長（不限制數量）
  static Future<List<AudioSegment>> segmentAudio(String audioPath,
      {int? maxSegments}) async {
    try {
      File audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('音檔不存在: $audioPath');
      }

      // 讀取WAV檔案頭部
      Uint8List headerBytes = await audioFile
          .openRead(0, 44)
          .fold<BytesBuilder>(
            BytesBuilder(),
            (builder, bytes) => builder..add(bytes),
          )
          .then((builder) => builder.toBytes());

      // 解析WAV檔案頭部
      Map<String, dynamic> wavInfo = _parseWavHeader(headerBytes);
      int sampleRateValue = wavInfo['sampleRate'] as int;
      int channels = wavInfo['channels'] as int;
      int bitsPerSample = wavInfo['bitsPerSample'] as int;
      int headerSize = wavInfo['headerSize'] as int;

      print('檔案大小: ${wavInfo['fileSize']} 位元組');
      print('取樣率: $sampleRateValue Hz');
      print('聲道數: $channels');
      print('位元深度: $bitsPerSample bits');

      // 計算每個音檔片段的樣本數
      int windowSamples = (windowSize * sampleRateValue).round();
      int hopSamples = (hopSize * sampleRateValue).round();

      // 讀取完整檔案的PCM數據
      Uint8List fileBytes = await audioFile.readAsBytes();
      Uint8List pcmData = fileBytes.sublist(headerSize); // 跳過WAV頭部

      // 計算總樣本數和可以分割的段數
      int bytesPerSample = bitsPerSample ~/ 8 * channels;
      int totalSamples = pcmData.length ~/ bytesPerSample;
      int totalSegments =
          ((totalSamples - windowSamples) / hopSamples).floor() + 1;

      // 檢查是否有分段數限制
      int segmentsToProcess = maxSegments != null
          ? math.min(totalSegments, maxSegments)
          : totalSegments;

      print('總樣本數: $totalSamples');
      print('窗口樣本數: $windowSamples');
      print('步長樣本數: $hopSamples');
      print('總片段數: $totalSegments, 處理片段數: $segmentsToProcess');

      // 創建臨時目錄存儲分割的音檔
      final tempDir = await getTemporaryDirectory();
      final segmentsDir = Directory('${tempDir.path}/audio_segments');
      if (await segmentsDir.exists()) {
        // 清空目錄而不是刪除整個目錄
        await for (var entity in segmentsDir.list()) {
          if (entity is File &&
              path_util.basename(entity.path).startsWith('segment_')) {
            await entity.delete();
          }
        }
      } else {
        await segmentsDir.create(recursive: true);
      }

      // 創建唯一識別碼生成器
      final uuid = Uuid();

      // 開始分割音檔
      List<AudioSegment> segments = [];
      for (int i = 0; i < segmentsToProcess; i++) {
        int startSample = i * hopSamples;
        int endSample = startSample + windowSamples;

        // 確保不超出檔案長度
        if (endSample > totalSamples) {
          endSample = totalSamples;
        }

        // 計算PCM數據的位元組範圍
        int startByte = startSample * bytesPerSample;
        int endByte = endSample * bytesPerSample;

        // 確保不超出PCM數據範圍
        if (startByte >= pcmData.length) break;
        if (endByte > pcmData.length) endByte = pcmData.length;

        // 提取這個時間窗口的PCM數據
        Uint8List segmentPcm =
            Uint8List.fromList(pcmData.sublist(startByte, endByte));

        // 生成新的WAV檔案頭部
        int segmentDataSize = segmentPcm.length;
        Uint8List header = _createWavHeader(
          fileSize: segmentDataSize + 36, // 總檔案大小 = 資料大小 + 36（頭部大小）
          sampleRate: sampleRateValue,
          channels: channels,
          bitsPerSample: bitsPerSample,
          dataSize: segmentDataSize,
        );

        // 合併頭部和PCM數據
        Uint8List segmentWav = Uint8List(header.length + segmentPcm.length);
        segmentWav.setAll(0, header);
        segmentWav.setAll(header.length, segmentPcm);

        // 儲存片段到檔案
        String segmentId = uuid.v4().toString();
        String segmentPath = '${segmentsDir.path}/segment_${i}_$segmentId.wav';
        await File(segmentPath).writeAsBytes(segmentWav);

        // 計算時間資訊
        double startTime = startSample / sampleRateValue;
        double endTime = endSample / sampleRateValue;

        // 提取波形數據供視覺化使用
        Uint8List? waveformData =
            _extractWaveformData(segmentPcm, channels, bitsPerSample, 100);

        // 添加到結果列表
        segments.add(AudioSegment(
          path: segmentPath,
          startTime: startTime,
          endTime: endTime,
          waveformData: waveformData,
        ));

        // 每處理100個片段print一次進度
        if (i % 100 == 0 || i == segmentsToProcess - 1) {
          print('處理分割進度: ${i + 1}/$segmentsToProcess');
        }
      }

      print('總共分割了 ${segments.length} 個片段');
      return segments;
    } catch (e) {
      print('分割音檔時出錯: $e');
      return [];
    }
  }

  // 創建WAV檔案頭部
  static Uint8List _createWavHeader({
    required int fileSize, // 完整檔案大小（位元組）
    required int sampleRate, // 取樣率
    required int channels, // 聲道數
    required int bitsPerSample, // 位元深度
    required int dataSize, // PCM資料大小（位元組）
  }) {
    Uint8List header = Uint8List(44);

    // RIFF 標頭
    header.setAll(0, [0x52, 0x49, 0x46, 0x46]); // "RIFF"
    header[4] = fileSize & 0xFF;
    header[5] = (fileSize >> 8) & 0xFF;
    header[6] = (fileSize >> 16) & 0xFF;
    header[7] = (fileSize >> 24) & 0xFF;

    // WAVE 標頭
    header.setAll(
        8, [0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20]); // "WAVEfmt "

    // 格式區段
    header[16] = 16; // 格式區段大小 (16 for PCM)
    header[17] = 0;
    header[18] = 0;
    header[19] = 0;
    header[20] = 1; // 格式類型 (1 for PCM)
    header[21] = 0;
    header[22] = channels & 0xFF;
    header[23] = (channels >> 8) & 0xFF;

    // 取樣率
    header[24] = sampleRate & 0xFF;
    header[25] = (sampleRate >> 8) & 0xFF;
    header[26] = (sampleRate >> 16) & 0xFF;
    header[27] = (sampleRate >> 24) & 0xFF;

    // 位元組率 = 取樣率 * 位元深度 * 聲道 / 8
    int byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    header[28] = byteRate & 0xFF;
    header[29] = (byteRate >> 8) & 0xFF;
    header[30] = (byteRate >> 16) & 0xFF;
    header[31] = (byteRate >> 24) & 0xFF;

    // 資料區塊對齊 = 位元深度 * 聲道 / 8
    int blockAlign = channels * bitsPerSample ~/ 8;
    header[32] = blockAlign & 0xFF;
    header[33] = (blockAlign >> 8) & 0xFF;

    // 位元深度
    header[34] = bitsPerSample & 0xFF;
    header[35] = (bitsPerSample >> 8) & 0xFF;

    // "data" 子區段
    header.setAll(36, [0x64, 0x61, 0x74, 0x61]); // "data"

    // 資料大小
    header[40] = dataSize & 0xFF;
    header[41] = (dataSize >> 8) & 0xFF;
    header[42] = (dataSize >> 16) & 0xFF;
    header[43] = (dataSize >> 24) & 0xFF;

    return header;
  }

  // 從PCM數據提取波形數據（用於視覺化）
  static Uint8List? _extractWaveformData(
    Uint8List pcmData,
    int channels,
    int bitsPerSample,
    int samplesCount, // 波形數據點數
  ) {
    try {
      // 如果PCM數據過小，則返回null
      if (pcmData.length < channels * (bitsPerSample ~/ 8)) {
        return null;
      }

      int bytesPerSample = bitsPerSample ~/ 8;
      int samplesPerChannel = pcmData.length ~/ (bytesPerSample * channels);

      // 如果樣本點數過少，則返回null
      if (samplesPerChannel < 10) {
        return null;
      }

      // 計算每個視覺化點包含的樣本數
      int samplesPerPoint = (samplesPerChannel / samplesCount).ceil();
      if (samplesPerPoint < 1) samplesPerPoint = 1;

      // 創建波形數據陣列
      Float32List waveform = Float32List(samplesCount);

      // 從PCM數據提取波形（僅使用第一個聲道的數據）
      for (int i = 0; i < samplesCount; i++) {
        int sampleStart = i * samplesPerPoint;
        int sampleEnd =
            math.min(sampleStart + samplesPerPoint, samplesPerChannel);

        if (sampleStart >= samplesPerChannel) break;

        // 計算這個區間的平均振幅
        double sum = 0;
        int count = 0;

        for (int j = sampleStart; j < sampleEnd; j++) {
          // 計算這個樣本在PCM數據中的位置（僅第一聲道）
          int bytePos = j * bytesPerSample * channels;

          // 解析樣本值
          int sampleValue = 0;
          if (bitsPerSample == 16) {
            if (bytePos + 1 < pcmData.length) {
              sampleValue = pcmData[bytePos] | (pcmData[bytePos + 1] << 8);
              // 處理有符號數
              if (sampleValue > 32767) sampleValue -= 65536;
            }
          } else if (bitsPerSample == 8) {
            sampleValue = pcmData[bytePos] - 128; // 8位PCM是無符號的，需要調整
          } else {
            // 不支援的位元深度
            return null;
          }

          // 歸一化到 -1.0 到 1.0
          double normalizedValue =
              sampleValue / (bitsPerSample == 16 ? 32768.0 : 128.0);
          sum += normalizedValue.abs(); // 使用絕對值來計算平均振幅
          count++;
        }

        // 儲存這個點的振幅
        waveform[i] = count > 0 ? (sum / count) : 0;
      }

      // 將float32陣列轉換為uint8陣列以便傳輸
      Uint8List result = Uint8List(waveform.length * 4);
      ByteData byteData = ByteData.view(result.buffer);
      for (int i = 0; i < waveform.length; i++) {
        byteData.setFloat32(i * 4, waveform[i], Endian.little);
      }

      return result;
    } catch (e) {
      print('提取波形數據時出錯: $e');
      return null;
    }
  }

  static Map<String, dynamic> parseWavHeader(Uint8List fileBytes) {
    return _parseWavHeader(fileBytes);
  }

  /// 公開將PCM數據轉換為浮點數數組的方法
  static Float64List convertPcmToFloat(
      Uint8List pcmData, int channels, int bitsPerSample) {
    return _convertPcmToFloat(pcmData, channels, bitsPerSample);
  }

  // 從Uint8List波形數據轉換回Float32List
  static Float32List? waveformFromBytes(Uint8List? bytes) {
    if (bytes == null || bytes.length % 4 != 0) return null;

    int floatsCount = bytes.length ~/ 4;
    Float32List result = Float32List(floatsCount);
    ByteData byteData = ByteData.view(bytes.buffer);

    for (int i = 0; i < floatsCount; i++) {
      result[i] = byteData.getFloat32(i * 4, Endian.little);
    }

    return result;
  }
}
