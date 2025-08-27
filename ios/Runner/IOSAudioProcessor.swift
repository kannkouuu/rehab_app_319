import Foundation
import AVFoundation
import Flutter

class IOSAudioProcessor: NSObject, FlutterStreamHandler {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var eventSink: FlutterEventSink?
    private var isProcessing = false
    
    // 音量計算參數 - 使用原始振幅
    private let bufferSize: AVAudioFrameCount = 1024 // 使用更標準的緩衝區大小
    
    // 除錯用計數器
    private var bufferCount = 0
    
    // 振幅轉換參數
    private let amplitudeMultiplier: Float = 1000.0 // 減少放大倍數
    private let baseLevel: Float = 50.0 // 調整基準音量
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("IOSAudioProcessor: 開始監聽原始音訊振幅")
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("IOSAudioProcessor: 取消監聽音訊振幅")
        stopAudioProcessing()
        self.eventSink = nil
        return nil
    }
    
    func startAudioProcessing() throws {
        print("IOSAudioProcessor: 啟動原始振幅檢測...")
        
        guard !isProcessing else {
            print("IOSAudioProcessor: 振幅檢測已在運行中")
            return
        }
        
        // 簡化音訊會話配置
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // 使用更簡單的配置
            try audioSession.setCategory(.record, mode: .default, options: [])
            
            // 使用系統預設的採樣率和緩衝區大小
            try audioSession.setActive(true)
            
            print("IOSAudioProcessor: 簡化音訊會話配置完成")
            
        } catch {
            print("IOSAudioProcessor: 音訊會話配置失敗: \(error)")
            throw error
        }
        
        // 設定音訊引擎
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "IOSAudioProcessor", code: -1, userInfo: [NSLocalizedDescriptionKey: "無法創建音訊引擎"])
        }
        
        inputNode = audioEngine.inputNode
        let recordingFormat = inputNode?.outputFormat(forBus: 0)
        
        print("IOSAudioProcessor: 音訊格式 - 採樣率: \(recordingFormat?.sampleRate ?? 0), 聲道: \(recordingFormat?.channelCount ?? 0)")
        
        // 使用系統預設格式，不強制設定特定參數
        inputNode?.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] (buffer, time) in
            self?.processRawAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isProcessing = true
            bufferCount = 0
            print("IOSAudioProcessor: 原始振幅檢測啟動成功")
        } catch {
            print("IOSAudioProcessor: 音訊引擎啟動失敗: \(error)")
            throw error
        }
    }
    
    private func processRawAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        bufferCount += 1
        
        // 檢查緩衝區有效性
        guard let channelData = buffer.floatChannelData?[0],
              buffer.frameLength > 0 else {
            return
        }
        
        let frameCount = Int(buffer.frameLength)
        
        // 計算RMS振幅（更穩定的方法）
        var rmsAmplitude: Float = 0.0
        
        for i in 0..<frameCount {
            let sample = channelData[i]
            rmsAmplitude += sample * sample
        }
        
        // RMS計算
        rmsAmplitude = sqrt(rmsAmplitude / Float(frameCount))
        
        // 轉換為分貝
        let volumeLevel: Float
        if rmsAmplitude > 0.0001 {
            // 使用標準的分貝轉換公式
            volumeLevel = 20.0 * log10(rmsAmplitude * amplitudeMultiplier) + baseLevel
        } else {
            volumeLevel = 0.0
        }
        
        // 限制範圍在 0-120 分貝之間
        let clampedVolume = max(0.0, min(120.0, volumeLevel))
        
        // 發送到 Flutter
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(Double(clampedVolume))
        }
        
        // 除錯：每隔一段時間印出詳細資訊
        if bufferCount % 100 == 0 {
            print("IOSAudioProcessor: 檢測 #\(bufferCount) - RMS:\(rmsAmplitude), 分貝:\(clampedVolume)")
        }
    }
    
    func stopAudioProcessing() {
        print("IOSAudioProcessor: 停止原始振幅檢測...")
        
        guard isProcessing else {
            print("IOSAudioProcessor: 振幅檢測未在運行")
            return
        }
        
        // 移除 tap
        inputNode?.removeTap(onBus: 0)
        
        // 停止音訊引擎
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        isProcessing = false
        bufferCount = 0
        
        // 停用音訊會話
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("IOSAudioProcessor: 音訊會話已停用")
        } catch {
            print("IOSAudioProcessor: 停用音訊會話失敗: \(error)")
        }
        
        print("IOSAudioProcessor: 原始振幅檢測已完全停止")
    }
}
