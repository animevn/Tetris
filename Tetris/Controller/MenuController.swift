import UIKit
import SpriteKit

class MenuController:UIViewController{
    
    private var player:SoundPlayer?
    var tetris:Tetris!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tetris = Tetris()
        
        DispatchQueue.main.async {
            do{
                self.player = try SoundPlayer(filename: "theme", type: "mp3", loop: -1)
            }catch{
                print("sound error")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.player?.play()
        })
    }
    
    @IBAction func bnPlay(_ sender: UIButton) {
        performSegue(withIdentifier: "game", sender: self)
    }
    
    @IBAction func bnCenter(_ sender: UIButton) {
        performSegue(withIdentifier: "save", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard   let identifier = segue.identifier else {return}
        
        
        if let destination = segue.destination as? GameController{
            if identifier == "game"{
                
                let skView = destination.view as! SKView
                if destination.scene == nil{
                    destination.scene = GameScene()
                }
                destination.scene.size = skView.frame.size
                destination.scene.scaleMode = .aspectFill
                skView.presentScene(destination.scene)
                skView.showsFPS = true
                skView.showsNodeCount = true
                
                destination.tetris = tetris
                destination.scene.updateCurrentShape = destination.tetris.lowerShape
                destination.tetris.delegate = destination.self
                destination.tetris.beginGame()
                destination.tetris.delegate = destination.self
                
            }
        }
        
        if let destination = segue.destination as? SaveController{
            destination.tetris = tetris
        }
        
    }

}










