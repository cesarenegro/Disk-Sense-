//
//  AudioManager.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//


//
//  AudioManager.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//

import AVFoundation
import SwiftUI

@MainActor
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @AppStorage("soundEffects") var soundEffectsEnabled = true
    @AppStorage("soundVolume") var soundVolume: Double = 0.5
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    enum SoundEffect: String, CaseIterable {
        case cleanStart = "clean_start"
        case cleanComplete = "clean_complete"
        case error = "error"
        case trash = "trash"
        case scan = "scan"
        case notification = "notification"
        case whoosh = "whoosh"
        
        var fileName: String {
            "\(self.rawValue).mp3"
        }
    }
    
    private init() {
        preloadSounds()
    }
    
    private func preloadSounds() {
        for effect in SoundEffect.allCases {
            // Try to load from main bundle
            if let soundURL = Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()
                    audioPlayers[effect.rawValue] = player
                } catch {
                    print("Failed to load sound: \(effect.rawValue)")
                }
            }
        }
    }
    
    func play(_ effect: SoundEffect) {
        guard soundEffectsEnabled else { return }
        
        if let player = audioPlayers[effect.rawValue] {
            player.volume = Float(soundVolume)
            player.currentTime = 0
            player.play()
        } else {
            // Fallback to system beep
            NSSound.beep()
        }
    }
    
    func stopAll() {
        for player in audioPlayers.values {
            player.stop()
        }
    }
}