import Foundation

import AVFoundation

import Flutter



// 這是我們的主要處理類，負責音訊處理和與 Flutter 的溝通

class AudioStreamHandler: NSObject, FlutterStreamHandler {

    

    private var eventSink: FlutterEventSink?

    

    // 音訊引擎相關

    private let engine = AVAudioEngine()

    private var isRecording = false

    

    // 負責計算 dB 值的計量器

    private var audioMeter = AudioMeter()



    // FlutterStreamHandler 的必要方法：當 Flutter 開始監聽時調用

    func onListen(withArguments arguments: Any?, eventSink events: FlutterEventSink) -> FlutterError? {

        self.eventSink = events

        return nil

    }



    // FlutterStreamHandler 的必要方法：當 Flutter 取消監聽時調用

    func onCancel(withArguments arguments: Any?) -> FlutterError? {

        self.eventSink = nil

        return nil

    }

    

    // 開始錄音並串流音量數據

    func start() {

        guard !isRecording else { return }

        

        // 1. 設定音訊會話 (這是關鍵！)

        // 我們使用 .measurement 模式來關閉系統的自動音訊處理 (如 AGC)

        let audioSession = AVAudioSession.sharedInstance()

        do {

            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .allowBluetooth])

            try audioSession.setActive(true)

        } catch {

            print("無法設定 AVAudioSession: \(error)")

            return

        }

        

        // 2. 獲取音訊輸入節點並安裝一個 "Tap"

        let inputNode = engine.inputNode

        let inputFormat = inputNode.outputFormat(forBus: 0)

        

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) {

            (buffer: AVAudioPCMBuffer, when: AVAudioTime) in

            

            // 3. 計算音量

            let level = self.audioMeter.process(buffer: buffer)

            

            // 4. 將數據發送回 Flutter

            // 我們需要在主執行緒上執行 eventSink

            DispatchQueue.main.async {

                self.eventSink?(level)

            }

        }

        

        // 5. 準備並啟動音訊引擎

        engine.prepare()

        do {

            try engine.start()

            isRecording = true

        } catch {

            print("無法啟動 AVAudioEngine: \(error)")

        }

    }

    

    // 停止錄音

    func stop() {

        guard isRecording else { return }

        

        engine.stop()

        engine.inputNode.removeTap(onBus: 0)

        

        do {

            // 停用音訊會話

            try AVAudioSession.sharedInstance().setActive(false)

        } catch {

            print("無法停用 AVAudioSession: \(error)")

        }

        

        isRecording = false

    }

}



// 一個輔助類，用於從音訊緩衝區計算分貝值

private class AudioMeter {

    private var averagePower: Float = 0.0

    private let meterTable = MeterTable()



    func process(buffer: AVAudioPCMBuffer) -> Float {

        guard let channelData = buffer.floatChannelData else { return 0.0 }

        

        let channelCount = Int(buffer.format.channelCount)

        let frameLength = Int(buffer.frameLength)

        

        var rms: Float = 0.0

        for channel in 0..<channelCount {

            var channelRms: Float = 0.0

            let data = channelData[channel]

            for i in 0..<frameLength {

                channelRms += (data[i] * data[i])

            }

            rms += (channelRms / Float(frameLength))

        }

        

        let avgRms = rms / Float(channelCount)

        let power = 20 * log10(sqrt(avgRms))

        

        // 進行平滑處理，防止數值劇烈跳動

        let mixingFactor: Float = 0.95

        averagePower = (averagePower * mixingFactor) + (power * (1.0 - mixingFactor))

        

        // 使用 MeterTable 轉換為一個更合理的 dB 值 (0-160)

        let db = meterTable.valueFor(power: averagePower)

        

        // 簡單轉換為 0-120 範圍，使其與 noise_meter 的輸出更相似

        // 這裡的轉換是經驗性的，您可能需要根據測試進行調整

        let finalDB = (db + 160.0) * (120.0 / 160.0)

        

        return finalDB > 0 ? finalDB : 0

    }

}



// 蘋果官方提供的一個輔助類，用於將內部功率值轉換為對數的 dB 值

private class MeterTable {

    private let minDb: Float = -160.0

    private var table = [Float]()

    private let tableSize = 400

    private var scaleFactor: Float



    init() {

        let dbResolution = minDb / Float(tableSize - 1)

        scaleFactor = 1.0 / dbResolution

        

        for i in 0..<tableSize {

            let decibels = Float(i) * dbResolution

            let amp = powf(10.0, 0.05 * decibels)

            table.append(amp)

        }

    }



    func valueFor(power: Float) -> Float {

        if power < minDb {

            return 0.0

        }

        if power >= 0.0 {

            return 1.0

        }

        let index = Int(power * scaleFactor)

        if index < tableSize {

            return table[index]

        }

        return 0.0

    }

}