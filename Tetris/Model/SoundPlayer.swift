import AVFoundation

class SoundPlayer{
    
    private var player:AVAudioPlayer?
    
    init(filename:String, type:String, loop:Int) throws{
        if let source = Bundle.main.path(forResource: filename, ofType: type){
            let file = URL(fileURLWithPath: source)
            player = try AVAudioPlayer(contentsOf: file)
            player?.numberOfLoops = loop
            player?.prepareToPlay()
        }else{
            throw SoundPlayerError.Error
        }
    }
    
    func play(){
        player?.play()
    }
    
    func stop(){
        player?.stop()
    }
}

enum SoundPlayerError:Error{
    case Error
}
