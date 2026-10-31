import AVFoundation

/// The two herdr alert sounds: "done" and "request". Mixes with
/// other audio and respects the silent switch (ambient category).
@MainActor
enum Sounds {
    private static var player: AVAudioPlayer?

    static func play(_ name: String) {
        let file = name == "done" ? "done" : "request"
        guard let url = Bundle.main.url(forResource: file, withExtension: "mp3") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}
