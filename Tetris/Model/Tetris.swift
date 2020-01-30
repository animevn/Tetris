import Foundation

//number of rows and columns
let numOfColums = 10
let numOfRows = 20

let startColumn = 4
let startRow = 0

//preview pane
let previewColumn = 12
let previewRow = 0

//score and level
let pointsPerLevel = 10
let levelThreshold = 300

//create applicationSupportDirectory in local
private let appSupportDirectory:URL = {
    let url = FileManager().urls(
        for: FileManager.SearchPathDirectory.applicationSupportDirectory,
        in: FileManager.SearchPathDomainMask.userDomainMask).first!
    
    //if that directory is not there, create it
    if !FileManager().fileExists(atPath: url.path){
        do{
            try FileManager().createDirectory(at: url, withIntermediateDirectories: false)
        }catch{
            print("error create directory")
        }
    }
    return url
}()

//create file named "saves" in directory
private let saveFile = appSupportDirectory.appendingPathComponent("saves")


//protocol of for delegate in gamecontroller
protocol TetrisDelegate{
    func gameDidBegin(tetris:Tetris)
    func gameShapeDidMove(tetris:Tetris)
    func gameShapeDidLand(tetris:Tetris)
    func gameShapeDidDrop(tetris:Tetris)
    func gameDidEnd(tetris:Tetris)
    func gameDidLevelUp(tetris:Tetris)
    func gameDidLoadSave(tetris:Tetris)
}


class Tetris{
    
    var delegate:TetrisDelegate?
    var score:Int
    var level:Int
    var timeInterval:TimeInterval?
    
    var currentShape:Shape?
    var nextShape:Shape?
    var cells:Cells<Block>
    
    //we only init this one time in menu for the whole game
    init(){
        score = 0
        level = 1
        currentShape = nil
        nextShape = nil
        cells = Cells(columns: numOfColums, rows: numOfRows)
    }
    
    //using this for clear all cells, not using now
    func clearCells(){
        cells = Cells(columns: numOfColums, rows: numOfRows)
    }
    
    //begin Game, create nextShape (for preview pane)
    func beginGame(){
        //create random current shape and next shape
        if currentShape == nil{
            currentShape = Shape(column: startColumn, row: startRow)
        }
        
        if nextShape == nil{
            nextShape = Shape(column: previewColumn, row: previewRow)
        }
        //put delegate here to do sth in game begin
        delegate?.gameDidBegin(tetris: self)
    }
    
    func endGame(){
        delegate?.gameDidEnd(tetris: self)
    }
    
    func loadSaveData(){
        delegate?.gameDidLoadSave(tetris: self)
    }

    //a func to detect if shape touch bottom or filled cells
    func detectTouch()->Bool{
        //unwrap currentShape
        guard let unwrap = currentShape else {return false}
        
        //check bottum block of current shape to find if it touch bottum (row 19) or
        // or if the cell below block is filled
        for block in unwrap.bottumBlocksByAngle(angle: unwrap.angle){
            if block.row == numOfRows - 1 || cells[block.column, block.row + 1] != nil{
                return true
            }
        }
        return false
    }
    
    //check if move is legal
    func detectIllegalMove()->Bool{
        guard let unwrap = currentShape else {return false}
        
        //if column and row out of bound (row < 0 and row > 19, column < 0 and column > 9)
        for block in unwrap.blocks{
            if block.column < 0 || block.column >= numOfColums
                || block.row < 0 || block.row >= numOfRows{
                
                return true
            }
            //if the cell is filled
            else if cells[block.column, block.row] != nil{
                return true
            }
        }
        return false
    }
    
    //this func run after func begin create a random next shape
    //basically it will return a pair of currentShape and nextShape
    func newNextShape()->(currentShape:Shape?, nextShape:Shape?){
        
        //set nextShape to currentShape
        currentShape = nextShape
        
        //get new random shape for nextShape and move nextShape to preview pane
        nextShape = Shape(column: previewColumn, row: previewRow)
        
        //move currentShape to start position
        currentShape?.MoveShapeTo(column: startColumn, row: startRow)
        
        //check if currentShape is illegal or not
        if detectIllegalMove(){
            endGame()
            //return nil, remove all current shape
            return (nil, nil)
        }
        
        return (currentShape, nextShape)
    }
    
    //if shape land ok, the write position to filledCells
    func settleShape(){
        guard let currentShape = currentShape else {return}
        
        for block in currentShape.blocks{
            cells[block.column, block.row] = block
        }
        //delete currentShape
        self.currentShape = nil
        delegate?.gameShapeDidLand(tetris: self)
    }
    
    //All these func are needed to control shape
    ////////////////////////////////////////////
    
    //normal func to lower shape
    func lowerShape(){
        guard let currentShape = currentShape else {return}
        
        //move currentshape down one row
        currentShape.lowerShapeByOneRow()
        
        //if detect illegal move
        if detectIllegalMove(){
            
            //then move back to original position
            currentShape.raiseShapeByOneRow()
            
            //if still illegal at orginal position, that mean the view is full so endgame
            if detectIllegalMove(){
                endGame()
            }
            //if not illegal that mean currentShape touch other filled cell, settle the shape there
            else{
                settleShape()
            }
        }
        //if not illegal move so put delegate here
        else{
            delegate?.gameShapeDidMove(tetris: self)
            
            //if detechTouch then settle currentShape
            if detectTouch(){
                settleShape()
            }
        }
    }
    
    //this func use for swipe action to drop currentShape fast
    func dropShape(){
        guard let currentShape = currentShape else {return}
        
        //while shape not touch then keep it lower fast
        while !detectIllegalMove(){
            currentShape.lowerShapeByOneRow()
        }
        //if detect illegal move then will move back to last ok position
        //mean that we get shape out of drop state and will treat shape
        //as usual in next line of code
        currentShape.raiseShapeByOneRow()
        
        //call delegate to do with shape as usual, that is to lowerShape,
        //to settleShape and other procedures for shape to land
        delegate?.gameShapeDidDrop(tetris: self)
        
    }
    
    //this func to rotate shape
    func rotateShape(){
        guard let currentShape = currentShape else {return}
        
        //rotate clockwise
        currentShape.rotateClockwise()
        //if detect illegal move then rotate back
        if detectIllegalMove(){
            currentShape.rotateCounterClockwise()
            return
        }
        //call delegate for shape continue to move
        delegate?.gameShapeDidMove(tetris: self)
    }
    
    func moveShapeLeft(){
        guard let currentShape = currentShape else {return}
        currentShape.shiftShapeLeftByOneColumn()
        if detectIllegalMove(){
            currentShape.shiftShapeRightByOneColumn()
            return
        }
        delegate?.gameShapeDidMove(tetris: self)
    }
    
    func moveShapeRight(){
        guard let currentShape = currentShape else {return}
        currentShape.shiftShapeRightByOneColumn()
        if detectIllegalMove(){
            currentShape.shiftShapeLeftByOneColumn()
            return
        }
        delegate?.gameShapeDidMove(tetris: self)
    }
    
    //get current filled cells in game and keep cells the same status
    func getCurrentFilledCells()->[[Block]]{
        
        var filledCells = [[Block]]()
        for row in 0..<numOfRows{
            // a list for each row, will be clear when iterate to nex row
            var rowCells = [Block]()
            for column in 0..<numOfColums{
                
                //if cell is nill the iterate to next column
                guard let block = cells[column, row] else {continue}
                //else append cell value to rowcells and delete value in cell
                rowCells.append(block)
            }
            if rowCells.count > 0{
                filledCells.append(rowCells)
            }
            
        }
        return filledCells
    }
    
    //get all filledcells in game and delete those cells
    func getAllFilledCells()->[[Block]]{
        //a list to store result
        
        var filledCells = [[Block]]()
        for row in 0..<numOfRows{
            // a list for each row, will be clear when iterate to nex row
            var rowCells = [Block]()
            for column in 0..<numOfColums{
                
                //if cell is nill the iterate to next column
                guard let block = cells[column, row] else {continue}
                
                //else append cell value to rowcells and delete value in cell
                rowCells.append(block)
                cells[column, row] = nil
            }
            filledCells.append(rowCells)
        }
        return filledCells
    }
    
    //return filled rows and remnant blocks, which
    //will fall down when clearing the filled rows
    func getFilledRows()->(filledRows:[[Block]], remnants:[[Block]]){
        
        //create empty list to store filled rows
        var filledRows = [[Block]]()
        var remnants = [[Block]]()
        
        for row in 0..<numOfRows{
            
            //a list to store filled rows
            var rowCells = [Block]()
            for column in 0..<numOfColums{
                
                //only append the non empty cell
                guard let block = cells[column, row] else {continue}
                
                rowCells.append(block)
            }

            if rowCells.count == numOfColums{
                
                filledRows.append(rowCells)
                
                //delete all row in cells
                for block in rowCells{
                    cells[block.column, block.row] = nil
                }
                
                //move all block in remnantblocks up one row
                if remnants.count > 0 {
                    for row in remnants.reversed(){
                        for block in row{
                            cells[block.column, block.row + 1] = cells[block.column, block.row]
                            cells[block.column, block.row] = nil
                            block.row += 1
                        }
                    }
                }
                
            }else if rowCells.count > 0{
                remnants.append(rowCells)
            }
        }
        
        //if filledrows is nil the remants is nil also, so return empty list
        if filledRows.count == 0{
            return ([], [])
        }
        
        //settle score and lever
        score += filledRows.count * pointsPerLevel * level
        if score > level*levelThreshold{
            level += 1
            //do somthing here in gamecontroller
            delegate?.gameDidLevelUp(tetris: self)
        }
        
          return(filledRows, remnants)
    }
    
    //delete save item
    func deleteSaveTetris(position:Int){
        
        //load data
        let data = loadData()
        
        //create empty list
        var saveTetris = SaveTetris(allSave: [])
        
        //try to decode data
        do{
            let temp = try JSONDecoder().decode(SaveTetris.self, from: data)
            //set list to decode result
            saveTetris = temp
        }catch{
            print("decoder error")
        }
        
        //remove item at position and create new save list
        var array = saveTetris.allSave
        array.remove(at: position)
        saveTetris = SaveTetris(allSave: array)
        
        //create new empty data
        var newData = Data()
        do{
            let jsonData = try JSONEncoder().encode(saveTetris)
            newData = jsonData
        }catch{
            print("error")
        }
        
        //convert data to text and write to local
        let save = String(data: newData, encoding: .utf8)
        do{
            try save?.write(to: saveFile, atomically: true, encoding: .utf8)
        }catch{
            print("error save")
        }
        
    }
    
    //store data to local
    func storeSaveTetris(tetris:Tetris){
        //convert to Json template
        let tempCurrent = Shape.shapeToJson(shape: tetris.currentShape!)
        let tempNext = Shape.shapeToJson(shape: tetris.nextShape!)
        let tempAll = tetris.getCurrentFilledCells().map{
            $0.map{
                return Block.blockToJson(block: $0)
            }
        }
        //create Json object
        let tetrisJson = TetrisJson(allFilledCells: tempAll,
                                    currentShape: tempCurrent,
                                    nextShape: tempNext,
                                    score:tetris.score,
                                    level:tetris.level,
                                    date:Date())
        
        //load current local save list
        var saveTetris = loadSaveTetris()
        
        //append new save
        saveTetris.allSave.append(tetrisJson)
        
        //create new data object
        var data = Data()
        
        //endcode new save
        do{
            let jsonData = try JSONEncoder().encode(saveTetris)
            data = jsonData
        }catch{
            print("error")
        }
        
        //write new save file to local
        let save = String(data: data, encoding: .utf8)
        do{
            try save?.write(to: saveFile, atomically: true, encoding: .utf8)
        }catch{
            print("error save")
        }
    }
    
    //decode data
    func loadSaveTetris()->SaveTetris{
        
        let data = loadData()
        //create savetetris object with empty array
        var saveTetris = SaveTetris(allSave: [])
        do{
            let temp = try JSONDecoder().decode(SaveTetris.self, from: data)
            saveTetris = temp
        }catch{
            print("decoder error")
            //this mean that data is empty, so return nil
        }
        return saveTetris
    }
    
    //load string and turn to data
    private func loadData()->Data{
        
        var string = ""
        do {
            string = try String(contentsOf: saveFile, encoding: .utf8)
        }catch{
            print("error read")
        }
        return Data(string.utf8)
    }
    
}

struct TetrisJson:Codable{
    
    var allFilledCells:[[BlockJson]]
    var currentShape:ShapeJson?
    var nextShape:ShapeJson?
    var score:Int
    var level:Int
    var date:Date
}

struct SaveTetris:Codable{
    var allSave:[TetrisJson]
}





















