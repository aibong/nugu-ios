//
//  MicInputProvider.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 03/05/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import AVFoundation

import NuguCore.ObjcExceptionCatcher

public class MicInputProvider: AudioProvidable {
    public var isRunning: Bool {
        return audioEngine.isRunning
    }
    
    public var audioFormat: AVAudioFormat?
    private let audioBus = 0
    private var streamWriter: AudioStreamWritable?
    private let audioEngine = AVAudioEngine()
    private let audioQueue = DispatchQueue(label: "romain_mic_input_audio_queue")
    
    public init(inputFormat: AVAudioFormat? = nil) {
        guard inputFormat != nil else {
            self.audioFormat = AVAudioFormat(commonFormat: MicInputConst.defaultFormat,
                                             sampleRate: MicInputConst.defaultSampleRate,
                                             channels: MicInputConst.defaultChannelCount,
                                             interleaved: MicInputConst.defaultInterLeavingSetting)
            return
        }
        
        self.audioFormat = inputFormat
    }
    
    public func start(streamWriter: AudioStreamWritable) throws {
        guard audioEngine.isRunning == false else {
            log.warning("audio engine is already running")
            return
        }
        
        try beginTappingMicrophone(streamWriter: streamWriter)
        
        // when audio session interrupted, audio engine will be stopped automatically. so we have to handle it.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioSessionInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(engineConfigurationChange),
                                               name: .AVAudioEngineConfigurationChange,
                                               object: nil)
    }
    
    public func stop() {
        log.debug("try to stop")
        
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVAudioEngineConfigurationChange, object: nil)
        
        streamWriter?.finish()
        streamWriter = nil
        
        audioEngine.inputNode.removeTap(onBus: audioBus)
        audioEngine.stop()
    }
    
    private func beginTappingMicrophone(streamWriter: AudioStreamWritable) throws {
        log.debug("begin tapping to engine's input node")
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: audioBus)
        
        guard let recordingFormat = audioFormat else {
            log.error("cannot make audioFormat")
            throw MicInputError.audioFormatError
        }
        
        log.info("convert from: \(inputFormat) to: \(recordingFormat)")
        guard let formatConverter = AVAudioConverter(from: inputFormat, to: recordingFormat) else {
            log.error("cannot make audio converter")
            throw MicInputError.resamplerError(source: inputFormat, dest: recordingFormat)
        }
        
        self.streamWriter = streamWriter
        
        if let error = ObjcExceptionCatcher.objcTry({ [weak self] in
            guard let self = self else { return }
            
            inputNode.removeTap(onBus: self.audioBus)
            inputNode.installTap(onBus: self.audioBus, bufferSize: AVAudioFrameCount(inputFormat.sampleRate/10), format: inputFormat) { [weak self] (buffer, _) in
                guard let self = self else { return }
                
                self.audioQueue.sync {
                    let convertedFrameCount = AVAudioFrameCount((Double(buffer.frameLength) / inputFormat.sampleRate) * recordingFormat.sampleRate)
                    guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat, frameCapacity: convertedFrameCount) else {
                        log.error("cannot make pcm buffer")
                        return
                    }

                    var error: NSError?
                    formatConverter.convert(to: pcmBuffer, error: &error) { _, outStatus in
                        outStatus.pointee = AVAudioConverterInputStatus.haveData
                        return buffer
                    }
                    
                    guard error == nil else {
                        log.error("audio convert error: \(error!)")
                        return
                    }

                    do {
                        try self.streamWriter?.write(pcmBuffer)
                    } catch {
                        log.error(error)
                        inputNode.removeTap(onBus: self.audioBus)
                    }
                }
            }
        }) {
            log.error("installTap error: \(error)\n" +
                "\t\trequested format: \(inputFormat)\n" +
                "\t\tengine output format: \(audioEngine.inputNode.outputFormat(forBus: audioBus))\n" +
                "\t\tinput format: \(audioEngine.inputNode.inputFormat(forBus: audioBus))")
            log.error("\n\t\t\(AVAudioSession.sharedInstance().category)\n" +
                "\t\t\(AVAudioSession.sharedInstance().categoryOptions)\n" +
                "\t\taudio session sampleRate: \(AVAudioSession.sharedInstance().sampleRate)")
            
            throw error
        }
        
        // installTap() must be called before prepare() or start() on iOS 11.
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            log.error(error.localizedDescription)
        }
    }
    
    @objc func audioSessionInterruption(notification: Notification) {
        log.debug("audioSessionInterruption")
        
        guard let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        if type == .ended {
            guard let optionsValue =
                info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                    return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                try? audioEngine.start()
            }
        }
    }
    
    /// recover when the audio engine is stopped by OS.
    @objc func engineConfigurationChange(notification: Notification) {
        log.debug("engineConfigurationChange - \(notification)")
        
        guard audioEngine.isRunning == false else { return }
        guard let streamWriter = streamWriter else { return }
        
        try? beginTappingMicrophone(streamWriter: streamWriter)
        
    }
}
