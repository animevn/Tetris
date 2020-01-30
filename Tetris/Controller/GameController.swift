import UIKit
import SpriteKit

class GameController: UIViewController{
  
    var scene:GameScene!
    var tetris:Tetris!
    var panPoint:CGPoint?
    var player:SoundPlayer?
    var saveController:SaveController?
    
    private var highScore = [0, 0, 0, 0, 0, 0]
    private let highScore1 = "highScore1"
    private let highScore2 = "highScore2"
    private let highScore3 = "highScore3"
    private let highScore4 = "highScore4"
    private let highScore5 = "highScore5"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
   
    //func for play sound every where, should be better than skaction, sometimes skaction return
    //errors.
    private func playSound(file:String){
        do{
            self.player = try SoundPlayer(filename: file, type: "mp3", loop: 0)
            self.player?.play()
        }catch{
            print("error \(file)")
        }
    }
}


extension GameController:UIGestureRecognizerDelegate{
    
    //swipe up
    @IBAction func didSwipeUp(_ sender: UISwipeGestureRecognizer) {
        scene.stopUpdate()
        view.isUserInteractionEnabled = false
        save()
    }
    
    //long tap
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        scene.stopUpdate()
        view.isUserInteractionEnabled = false
        pause()
    }
    
    //tap action
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        tetris.rotateShape()
    }
    
    //swipe down action
    @IBAction func didSwipe(_ sender: UISwipeGestureRecognizer) {
        tetris.dropShape()
    }
    
    //pan action
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        
        let currentPoint = sender.translation(in: self.view)
        
        if let originalPoint = panPoint{
            if abs(currentPoint.x - originalPoint.x) > scene.blockSize! * 0.85 {
                if sender.velocity(in: self.view).x > 0{
                    tetris.moveShapeRight()
                    panPoint = currentPoint
                }else{
                    tetris.moveShapeLeft()
                    panPoint = currentPoint
                }
            }
        }
        //at start, set panpoint, so first touch wont pan the shape
        else if sender.state == UIGestureRecognizer.State.began{
            panPoint = currentPoint
        }
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer is UISwipeGestureRecognizer{
            return true
        }else if gestureRecognizer is UIPanGestureRecognizer{
            if otherGestureRecognizer is UITapGestureRecognizer{
                return true
            }
        }
        return false
    }
}


extension GameController:TetrisDelegate{
    
    func gameDidBegin(tetris: Tetris) {
        tetris.score = 0
        tetris.level = 1
        loadLabels(tetris: tetris)
        
        //set delta time
        scene.timeIntervalMillis = returnInterval(level: tetris.level)
        
        view.isUserInteractionEnabled = true
        scene.addShapeToPreview(shape: tetris.nextShape!, completion: {})
        scene.moveLoadShapeToPosition(shape: tetris.currentShape!, completion: {
            self.scene.startUpdate()
        })
    }
    
    func gameDidLoadSave(tetris: Tetris) {
        loadLabels(tetris: tetris)
        scene.timeIntervalMillis = returnInterval(level: tetris.level)
        scene.addShapeToPreview(shape: tetris.nextShape!, completion: {})
        scene.moveLoadShapeToPosition(shape: tetris.currentShape!, completion: {
            self.scene.startUpdate()
        })
    }
    
    //while shape moving just draw shapenode 
    func gameShapeDidMove(tetris: Tetris) {
        scene.reDrawShape(shape: tetris.currentShape!, completion: {})
    }
    
    //do things when shape land on bottum or others filled blocks
    func gameShapeDidLand(tetris: Tetris) {
        //stop update time
        scene.stopUpdate()
        view.isUserInteractionEnabled = false
        
        //get filled rows and remains blocks
        let animate = tetris.getFilledRows()
        
        //if filled rows number > 1 then animate
        if animate.filledRows.count > 0{
            scene.lbScore.text = "\(tetris.score)"
            scene.animateRows(
                filledRows: animate.filledRows,
                remnants: animate.remnants,
                completion: {self.createShapePair()})
            playSound(file: "bomb")
        }
        //if not, then simple create new pair of currentshape and nextshape
        else{
            createShapePair()
        }
    }
    
    //create a pair of currentShape and nextShape, and start update time so game can run
    private func createShapePair(){
        let shapePair = tetris.newNextShape()
        if let currentShape = shapePair.currentShape{
            scene.addShapeToPreview(shape: shapePair.nextShape!, completion: {})
            scene.moveShapeToPosition(shape: currentShape, completion: {
                self.view.isUserInteractionEnabled = true
                self.scene.startUpdate()
            })
        }
    }
    
    
    func gameShapeDidDrop(tetris: Tetris) {
        scene.stopUpdate()
        
        //draw shape at position and treat it as normal shape, so just lower it for landing
        //phase kicks in
        scene.reDrawShape(shape: tetris.currentShape!, completion: {
            tetris.lowerShape()
        })
        playSound(file: "drop")
    }
    
    func gameDidEnd(tetris: Tetris) {
        //stop game
        scene.stopUpdate()
        
        //disable user interact
        view.isUserInteractionEnabled = false
        playSound(file: "gameover")
        
        //put current score into array highscore and sort it.
        highScore[0] = tetris.score
        highScore = highScore.sorted()
        
        //store five highest score
        UserDefaults.standard.set(highScore[5], forKey: highScore1)
        UserDefaults.standard.set(highScore[4], forKey: highScore2)
        UserDefaults.standard.set(highScore[3], forKey: highScore3)
        UserDefaults.standard.set(highScore[2], forKey: highScore4)
        UserDefaults.standard.set(highScore[1], forKey: highScore5)
        
        //write score to label again
        if highScore[5] > 0 {
            scene.lbHigh1.text = "\(highScore[5])"
        }
        
        if highScore[4] > 0 {
            scene.lbHigh2.text = "\(highScore[4])"
        }
        
        if highScore[3] > 0 {
            scene.lbHigh3.text = "\(highScore[3])"
        }
        
        if highScore[2] > 0 {
            scene.lbHigh4.text = "\(highScore[2])"
        }
        
        if highScore[1] > 0 {
            scene.lbHigh5.text = "\(highScore[1])"
        }
        //remove blocks in preview
        scene.removeShape(shape: tetris.currentShape!)
        tetris.currentShape = nil
        tetris.nextShape = nil
        //then next wil
        //simply fall down and let go all blocks in view
        scene.animateRows(
            filledRows: tetris.getAllFilledCells(),
            remnants: [],
            completion: {
                self.playAgain()
        })
//        tetris.clearCells()
    }
    
    //kicks in when level up, so its kind of listener
    func gameDidLevelUp(tetris: Tetris) {
        scene.lbLevel.text = "\(tetris.level)"
        playSound(file: "levelup")
        scene.timeIntervalMillis = returnInterval(level: tetris.level)
    }
    
    private func loadLabels(tetris: Tetris){
        scene.lbScore.text = "\(tetris.score)"
        scene.lbLevel.text = "\(tetris.level)"
        
        //restore scorelist to array highScore
        highScore[5] = UserDefaults.standard.integer(forKey: highScore1)
        highScore[4] = UserDefaults.standard.integer(forKey: highScore2)
        highScore[3] = UserDefaults.standard.integer(forKey: highScore3)
        highScore[2] = UserDefaults.standard.integer(forKey: highScore4)
        highScore[1] = UserDefaults.standard.integer(forKey: highScore5)
        
        //and set value to label
        if highScore[5] > 0 {
            scene.lbHigh1.text = "\(highScore[5])"
        }
        
        if highScore[4] > 0 {
            scene.lbHigh2.text = "\(highScore[4])"
        }
        
        if highScore[3] > 0 {
            scene.lbHigh3.text = "\(highScore[3])"
        }
        
        if highScore[2] > 0 {
            scene.lbHigh4.text = "\(highScore[2])"
        }
        
        if highScore[1] > 0 {
            scene.lbHigh5.text = "\(highScore[1])"
        }
    }
    
    
    private func playAgain(){
        let alert = UIAlertController(
            title: "Wow!!!",
            message: "Your score is \(tetris.score) . Play again?",
            preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: {_ in
            self.tetris.beginGame()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: {_ in
            self.dismiss(animated: true, completion: nil)
            if self.saveController != nil{
                let transition: CATransition = CATransition()
                transition.duration = 0
//                transition.timingFunction =
//                    CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
//                transition.type = kCATransitionReveal
//                transition.subtype = kCATransitionFromBottom
                self.view.window!.layer.add(transition, forKey: nil)
                self.saveController?.dismiss(animated: false, completion: nil)
            }
        })
        
        alert.addAction(ok)
        alert.addAction(cancel)
        
        //remove current presenter
        if let presented = self.presentedViewController{
            presented.removeFromParent()
        }
        
        //if presenter is not there, present alert
        if presentedViewController == nil{
            present(alert, animated: true, completion: nil)
        }
    }
    
    //alert when pause game
    private func pause(){
        let alert = UIAlertController(
            title: "Pause",
            message: "Continue or Exit?",
            preferredStyle: .alert)
        
        let menu = UIAlertAction(title: "Exit", style: .default, handler: {_ in
            self.tetris.clearCells()
            self.dismiss(animated: true, completion: nil)
            if self.saveController != nil{
                let transition: CATransition = CATransition()
//                transition.duration = 0
//                transition.timingFunction =
//                    CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
//                transition.type = kCATransitionReveal
//                transition.subtype = kCATransitionFromBottom
                self.view.window!.layer.add(transition, forKey: nil)
                self.saveController?.dismiss(animated: true, completion: nil)
            }
        })
        let resume = UIAlertAction(title: "Continue", style: .default, handler: {_ in
            self.scene.startUpdate()
            self.view.isUserInteractionEnabled = true
        })
        
        alert.addAction(resume)
        alert.addAction(menu)
        
        //if presenter is not there, present alert
        if presentedViewController == nil{
            present(alert, animated: true, completion: nil)
        }
    }
    
    //alert when save game
    private func save(){
        let alert = UIAlertController(
            title: "Save Game",
            message: "Save game or not?",
            preferredStyle: .alert)
        
        let resume = UIAlertAction(title: "Save", style: .default, handler: {_ in
            self.tetris.storeSaveTetris(tetris: self.tetris)
            self.saveController?.tableView.reloadData()
            self.scene.startUpdate()
            self.view.isUserInteractionEnabled = true
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: {_ in
            self.scene.startUpdate()
            self.view.isUserInteractionEnabled = true
        })
        
        alert.addAction(resume)
        alert.addAction(cancel)
        
        //if presenter is not there, present alert
        if presentedViewController == nil{
            present(alert, animated: true, completion: nil)
        }
    }
    
    private func returnInterval(level:Int)->TimeInterval{
        switch level{
        case 1:
            return TimeInterval(650)
        case 2:
            return TimeInterval(600)
        case 3:
            return TimeInterval(550)
        case 4:
            return TimeInterval(500)
        case 5:
            return TimeInterval(450)
        case 6:
            return TimeInterval(400)
        case 7:
            return TimeInterval(350)
        case 8:
            return TimeInterval(325)
        case 9:
            return TimeInterval(300)
        case 10:
            return TimeInterval(275)
        case 11:
            return TimeInterval(250)
        case 12:
            return TimeInterval(225)
        case 13:
            return TimeInterval(200)
        case 14:
            return TimeInterval(175)
        case 15:
            return TimeInterval(150)
        case 16:
            return TimeInterval(125)
        case 17:
            return TimeInterval(100)
        case 18:
            return TimeInterval(75)
        case 19:
            return TimeInterval(50)
        default:
            return TimeInterval(50)
        }
    }
}




