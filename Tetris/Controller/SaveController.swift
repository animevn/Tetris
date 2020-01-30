import UIKit
import SpriteKit

class SaveController:UITableViewController {
    
    var tetris:Tetris!
    var allFilledCells = [[Block]]()
    var skView:SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //enable edit row
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //swipe to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            tableView.beginUpdates()
            tetris.deleteSaveTetris(position: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
    
    //define number of row
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tetris.loadSaveTetris().allSave.count
    }
    
    //define cell content
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let row = tetris.loadSaveTetris().allSave
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMM-YY HH:mm"
        let date = dateFormatter.string(from: row[indexPath.row].date)
        cell.textLabel?.text =  "\(date) | score: \(row[indexPath.row].score) " +
                                "| level: \(row[indexPath.row].level)"
        
        return cell
    }
    
    //define action when click row
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = tetris.loadSaveTetris().allSave
        let row = data[indexPath.row]
        tetris.currentShape = Shape.shapeJsonToShape(shape: row.currentShape!)
        tetris.nextShape = Shape.shapeJsonToShape(shape: row.nextShape!)
        tetris.score = row.score
        tetris.level = row.level
        
        for row in row.allFilledCells{
            var rowFilledCells = [Block]()
            for block in row{
                let newBlock = Block.blockJsonToBlock(block: block)
                tetris.cells[block.column, block.row] = newBlock
                rowFilledCells.append(newBlock)
            }
            allFilledCells.append(rowFilledCells)
        }
        performSegue(withIdentifier: "playsave", sender: self)
    }
    
    //prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard   let identifier = segue.identifier,
            let destination = segue.destination as? GameController
            else {return}
        
        if identifier == "playsave"{
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
            
            destination.scene.drawFilledCells(filledCells: allFilledCells)
            destination.tetris.loadSaveData()
            destination.saveController = self
            
        }
    }
    
    //press to return to Menuview
    @IBAction func back(_ sender: UIBarButtonItem) {

        dismiss(animated: true, completion: nil)
    }
}





















