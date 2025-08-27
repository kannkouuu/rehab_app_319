import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var audioProcessor: IOSAudioProcessor?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    // 註冊原生音訊處理器
    setupAudioProcessor(controller: controller)
    
    // 註冊音訊轉換器
    setupAudioConverter(controller: controller)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupAudioProcessor(controller: FlutterViewController) {
    print("AppDelegate: 設置音訊處理器...")
    
    audioProcessor = IOSAudioProcessor()
    
    let methodChannel = FlutterMethodChannel(name: "ios_audio_processor", binaryMessenger: controller.binaryMessenger)
    let eventChannel = FlutterEventChannel(name: "ios_audio_processor_stream", binaryMessenger: controller.binaryMessenger)
    
    methodChannel.setMethodCallHandler { [weak self] (call, result) in
      print("AppDelegate: 接收到方法調用: \(call.method)")
      
      switch call.method {
      case "startAudioProcessing":
        do {
          try self?.audioProcessor?.startAudioProcessing()
          result(nil)
          print("AppDelegate: 音訊處理啟動成功")
        } catch {
          let flutterError = FlutterError(code: "AUDIO_ERROR", message: error.localizedDescription, details: nil)
          result(flutterError)
          print("AppDelegate: 音訊處理啟動失敗: \(error)")
        }
      case "stopAudioProcessing":
        self?.audioProcessor?.stopAudioProcessing()
        result(nil)
        print("AppDelegate: 音訊處理停止完成")
      default:
        result(FlutterMethodNotImplemented)
        print("AppDelegate: 未實現的方法: \(call.method)")
      }
    }
    
    eventChannel.setStreamHandler(audioProcessor)
    print("AppDelegate: 音訊處理器設置完成")
  }
  
  private func setupAudioConverter(controller: FlutterViewController) {
    print("AppDelegate: 設置音訊轉換器...")
    
    let converterChannel = FlutterMethodChannel(name: "audio_converter", binaryMessenger: controller.binaryMessenger)
    
    converterChannel.setMethodCallHandler { (call, result) in
      print("AppDelegate: 接收到音訊轉換調用: \(call.method)")
      
      switch call.method {
      case "convertM4AToWAV":
        guard let arguments = call.arguments as? [String: Any],
              let inputPath = arguments["inputPath"] as? String,
              let outputPath = arguments["outputPath"] as? String,
              let sampleRate = arguments["sampleRate"] as? Int else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
          return
        }
        
        print("AppDelegate: 開始轉換 M4A 到 WAV")
        print("輸入檔案: \(inputPath)")
        print("輸出檔案: \(outputPath)")
        print("採樣率: \(sampleRate)")
        
        self.convertM4AToWAV(inputPath: inputPath, outputPath: outputPath, sampleRate: sampleRate) { success in
          DispatchQueue.main.async {
            result(success)
          }
        }
        
      default:
        result(FlutterMethodNotImplemented)
        print("AppDelegate: 未實現的音訊轉換方法: \(call.method)")
      }
    }
    
    print("AppDelegate: 音訊轉換器設置完成")
  }
  
  private func convertM4AToWAV(inputPath: String, outputPath: String, sampleRate: Int, completion: @escaping (Bool) -> Void) {
    print("開始執行 M4A 到 WAV 轉換...")
    
    let inputURL = URL(fileURLWithPath: inputPath)
    let outputURL = URL(fileURLWithPath: outputPath)
    
    // 檢查輸入檔案是否存在
    guard FileManager.default.fileExists(atPath: inputPath) else {
      print("錯誤：輸入檔案不存在: \(inputPath)")
      completion(false)
      return
    }
    
    do {
      // 創建 AVAsset 讀取 M4A 檔案
      let asset = AVAsset(url: inputURL)
      
      // 檢查 asset 是否有效
      guard asset.isReadable else {
        print("錯誤：無法讀取音訊檔案")
        completion(false)
        return
      }
      
      // 獲取音訊軌道
      guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
        print("錯誤：檔案中沒有音訊軌道")
        completion(false)
        return
      }
      
      // 創建 AVAssetReader
      let assetReader = try AVAssetReader(asset: asset)
      
      // 設定輸出格式為 PCM
      let outputSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsNonInterleaved: false
      ]
      
      let assetReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
      assetReader.add(assetReaderOutput)
      
      // 開始讀取
      assetReader.startReading()
      
      // 收集所有 PCM 數據
      var pcmData = Data()
      
      while assetReader.status == .reading {
        if let sampleBuffer = assetReaderOutput.copyNextSampleBuffer() {
          if let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
            var length: Int = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            
            let status = CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
            
            if status == noErr, let pointer = dataPointer {
              // 正確的型別轉換：Int8 -> UInt8
              let uint8Pointer = pointer.withMemoryRebound(to: UInt8.self, capacity: length) { $0 }
              pcmData.append(uint8Pointer, count: length)
            }
          }
          CMSampleBufferInvalidate(sampleBuffer)
        }
      }
      
      if assetReader.status == .completed {
        print("成功讀取 PCM 數據，大小: \(pcmData.count) 位元組")
        
        // 創建 WAV 頭部
        let wavHeader = self.createWAVHeader(dataSize: pcmData.count, sampleRate: sampleRate, channels: 1, bitsPerSample: 16)
        
        // 組合 WAV 檔案
        var wavData = Data()
        wavData.append(wavHeader)
        wavData.append(pcmData)
        
        // 寫入檔案
        try wavData.write(to: outputURL)
        
        print("成功轉換並儲存 WAV 檔案: \(outputPath)")
        print("WAV 檔案大小: \(wavData.count) 位元組")
        completion(true)
        
      } else {
        print("錯誤：讀取音訊檔案失敗，狀態: \(assetReader.status.rawValue)")
        if let error = assetReader.error {
          print("讀取錯誤詳情: \(error.localizedDescription)")
        }
        completion(false)
      }
      
    } catch {
      print("音訊轉換過程出錯: \(error.localizedDescription)")
      completion(false)
    }
  }
  
  private func createWAVHeader(dataSize: Int, sampleRate: Int, channels: Int, bitsPerSample: Int) -> Data {
    var header = Data()
    
    // RIFF 標頭
    header.append("RIFF".data(using: .ascii)!)
    header.append(withUnsafeBytes(of: UInt32(dataSize + 36).littleEndian) { Data($0) })
    header.append("WAVE".data(using: .ascii)!)
    
    // fmt 子區段
    header.append("fmt ".data(using: .ascii)!)
    header.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // fmt 區段大小
    header.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })  // 格式類型 (PCM)
    header.append(withUnsafeBytes(of: UInt16(channels).littleEndian) { Data($0) }) // 聲道數
    header.append(withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) }) // 採樣率
    
    // 位元組率 = 採樣率 * 聲道數 * 位元深度 / 8
    let byteRate = sampleRate * channels * bitsPerSample / 8
    header.append(withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Data($0) })
    
    // 資料區塊對齊 = 聲道數 * 位元深度 / 8
    let blockAlign = channels * bitsPerSample / 8
    header.append(withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Data($0) })
    
    // 位元深度
    header.append(withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Data($0) })
    
    // data 子區段
    header.append("data".data(using: .ascii)!)
    header.append(withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Data($0) })
    
    return header
  }
}