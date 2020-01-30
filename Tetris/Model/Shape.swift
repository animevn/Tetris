import SpriteKit

let block0 = 0
let block1 = 1
let block2 = 2
let block3 = 3
let numberOfShapeTypes:UInt32 = 7
let numberOfAngles:UInt32 = 4

enum ShapeType:Int, Codable{
    
    case SquareShape = 0
    case LineShape = 1
    case TShape = 2
    case LShape = 3
    case JShape = 4
    case ZShape = 5
    case SShape = 6
    
    static func random()->ShapeType{
        return ShapeType(rawValue: Int(arc4random_uniform(numberOfShapeTypes)))!
    }
}

enum Angle:Int, CustomStringConvertible, Codable{
    case Zero = 0, Ninety, OneEighty, TwoSeventy
    
    var description: String{
        switch self{
        case .Zero:
            return "0"
        case .Ninety:
            return "90"
        case .OneEighty:
            return "180"
        case .TwoSeventy:
            return "270"
        }
    }
    
    static func random()->Angle{
        return Angle(rawValue: Int(arc4random_uniform(numberOfAngles)))!
    }
    
    //rotate angle one step back or forth
    static func rotate(angle:Angle, clockwise:Bool)->Angle{
        
        var newAngle = angle.rawValue + (clockwise ? 1 : -1)
        
        if newAngle > Angle.TwoSeventy.rawValue{
            newAngle = Angle.Zero.rawValue
        }else if newAngle < Angle.Zero.rawValue{
            newAngle = Angle.TwoSeventy.rawValue
        }
        return Angle(rawValue: newAngle)!
    }
}

class Shape{
    
    let color:BlockColor
    var blocks = [Block]()
    var angle:Angle
    var type:ShapeType
    var column:Int
    var row:Int
    
    init(column:Int, row:Int, angle:Angle, color:BlockColor, type:ShapeType){
        self.angle = angle
        self.color = color
        self.column = column
        self.row = row
        self.type = type
        
        //initialize blocks of shape
        guard let unwrap = blocksPositions(type: type)[angle] else {return}
        self.blocks = unwrap.map{
            return Block(column: self.column + $0.collumDiff,
                         row: self.row + $0.rowDiff,
                         color: self.color)
        }
    }
    
    //simple init
    convenience init(column:Int, row:Int){
        self.init(column: column, row: row,
                  angle: Angle.random(),
                  color: BlockColor.random(), type: ShapeType.random())
    }
    
    //shift Shape by column
    func shiftShapeByColumn(column:Int, row:Int){
        
        //shift shape by column
        self.column += column
        self.row += row
        
        //and change blocks position accordingly
        for block in blocks{
            block.column += column
            block.row += row
        }
    }
    
    //get a shape by angle
    func rotateShape(angle:Angle){
        
        //when rotate shape, position of shape is the same, only blocks positions changes
        guard let unwrap = blocksPositions(type: type)[angle] else {return}
        
        for (index, diff) in unwrap.enumerated(){
            blocks[index].column = column + diff.collumDiff
            blocks[index].row = row + diff.rowDiff
        }
    }
    
    //rotate clockwise one step
    func rotateClockwise(){
        let newAngle = Angle.rotate(angle: angle, clockwise: true)
        rotateShape(angle: newAngle)
        angle = newAngle
    }
    
    //rotate counter clockwise one step
    func rotateCounterClockwise(){
        let newAngle = Angle.rotate(angle: angle, clockwise: false)
        rotateShape(angle: newAngle)
        angle = newAngle
    }
    
    //lower shape, mean that we move shape to next row
    func lowerShapeByOneRow(){
        shiftShapeByColumn(column: 0, row: 1)
    }
    
    //raise shape, or move shape to last row
    func raiseShapeByOneRow(){
        shiftShapeByColumn(column: 0, row: -1)
    }

    //move shape left by one column
    func shiftShapeLeftByOneColumn(){
        shiftShapeByColumn(column: -1, row: 0)
    }
    
    //move shape right by one column
    func shiftShapeRightByOneColumn(){
        shiftShapeByColumn(column: 1, row: 0)
    }
    
    //move shape to position
    func MoveShapeTo(column:Int, row:Int){
        //change position of shape
        self.column = column
        self.row = row
        
        //change blocks position accordingly
        rotateShape(angle: angle)
    }
}

//return differrent of position blocks from shape block of each angle
extension Shape{
    
    func blocksPositions(type:ShapeType)->[Angle:[(collumDiff:Int, rowDiff:Int)]]{
        
        switch type{
            /*
             Square shape does not rotate, so the easiest
             
                    | 0x| 1 |
                    | 2 | 3 |
             
             x is the position of shape
             
             */
        case .SquareShape:
            return [
                Angle.Zero: [(0, 0), (1, 0), (0, 1), (1, 1)],
                Angle.Ninety: [(0, 0), (1, 0), (0, 1), (1, 1)],
                Angle.OneEighty: [(0, 0), (1, 0), (0, 1), (1, 1)],
                Angle.TwoSeventy: [(0, 0), (1, 0), (0, 1), (1, 1)]
            ]
            
            /*
             Second easiest shape, line shape have only 2 position
             
             angle 0 and 180:
             
                    | 0x|
                    | 1 |
                    | 2 |
                    | 3 |
             
             angle 90 and 270:
             
                | 0 | 1x| 2 | 3 |
             
             x is position of shape
             */
        case .LineShape:
            return [
                Angle.Zero: [(0, 0), (0, 1), (0, 2), (0, 3)],
                Angle.Ninety: [(-1, 0), (0, 0), (1, 0), (2, 0)],
                Angle.OneEighty: [(0, 0), (0, 1), (0, 2), (0, 3)],
                Angle.TwoSeventy: [(-1, 0), (0, 0), (1, 0), (2, 0)]
            ]
            
            /*
             The TShape
             
             angle 0
                      x
                | 0 | 1 | 2 |
                    | 3 |
             
             angle 90
                    | 0x|
                | 3 | 1 |
                    | 2 |
             angle 180
                      x
                    | 3 |
                | 2 | 1 | 0 |
             
             angle 270
                    | 2x|
                    | 1 | 3 |
                    | 0 |
             
             x is position of shape
             */
        case .TShape:
            return [
                Angle.Zero: [(-1, 1), (0, 1), (1, 1), (0, 2)],
                Angle.Ninety: [(0, 0), (0, 1), (0, 2), (-1, 1)],
                Angle.OneEighty: [(1, 2), (0, 2), (-1, 2), (0, 1)],
                Angle.TwoSeventy: [(0, 2), (0, 1), (0, 0), (1, 1)]
            ]
            
            /*
             The LShape
             
             angle 0
                | 0 | x
                | 1 |
                | 2 | 3 |
             
             angle 90
                      x
                | 2 | 1 | 0 |
                | 3 |
             
             angle 180
                | 3 | 2x|
                    | 1 |
                    | 0 |
             angle 270
                      x
                        | 3 |
                | 0 | 1 | 2 |
             
             
             x is position of shape
             */
        case .LShape:
            return [
                Angle.Zero: [(-1, 0), (-1, 1), (-1, 2), (0, 2)],
                Angle.Ninety: [(1, 1), (0, 1), (-1, 1), (-1, 2)],
                Angle.OneEighty: [(0, 2), (0, 1), (0, 0), (-1, 0)],
                Angle.TwoSeventy: [(-1, 2), (0, 2), (1, 2), (1, 1)]
            ]
            
            /*
             The JShape
             angle 0
                      x | 0 |
                        | 1 |
                    | 3 | 2 |
             angle 90
                      x
                | 3 |
                | 2 | 1 | 0 |
             
             angle 180
                | 2 | 3x|
                | 1 |
                | 0 |
             angle 270
                      x
                | 0 | 1 | 2 |
                        | 3 |
             
             x is position of shape
             */
        case .JShape:
            return [
                Angle.Zero: [(1, 0), (1, 1), (1, 2), (0, 2)],
                Angle.Ninety: [(1, 2), (0, 2), (-1, 2), (-1, 1)],
                Angle.OneEighty: [(-1, 2), (-1, 1), (-1, 0), (0, 0)],
                Angle.TwoSeventy: [(-1, 1), (0, 1), (1, 1), (1, 2)]
            ]
            
            
            /*
             The ZShape
             angle 0 and 180:
                      x | 3 |
                    | 1 | 2 |
                    | 0 |
             
             angle 90 and 270
                      x
                | 0 | 1 |
                    | 2 | 3 |
             
             x is position of shape
             */
        case .ZShape:
            return [
                Angle.Zero: [(0, 2), (0, 1), (1, 1), (1, 0)],
                Angle.Ninety: [(-1, 1), (0, 1), (0, 2), (1, 2)],
                Angle.OneEighty: [(0, 2), (0, 1), (1, 1), (1, 0)],
                Angle.TwoSeventy: [(-1, 1), (0, 1), (0, 2), (1, 2)]
            ]
            
            /*
             The SShape
             angle 0 and 180:
                    | 0 | x
                    | 1 | 2 |
                        | 3 |
             
             angle 90 and 270
                          x
                        | 1 | 0 |
                    | 3 | 2 |
             
             x is position of shape
             */
        case .SShape:
            return [
                Angle.Zero: [(-1, 0), (-1, 1), (0, 1), (0, 2)],
                Angle.Ninety: [(1, 1), (0, 1), (0, 2), (-1, 2)],
                Angle.OneEighty: [(-1, 0), (-1, 1), (0, 1), (0, 2)],
                Angle.TwoSeventy: [(1, 1), (0, 1), (0, 2), (-1, 2)]
            ]
        }
    }
    
    
    func bottomBlocksPositions(type:ShapeType)->[Angle:[Block]]{
        
        switch type{
        case .SquareShape:
            return [
                Angle.Zero: [blocks[block2], blocks[block3]],
                Angle.Ninety: [blocks[block2], blocks[block3]],
                Angle.OneEighty: [blocks[block2], blocks[block3]],
                Angle.TwoSeventy: [blocks[block2], blocks[block3]]
            ]
            
        case .LineShape:
            return [
                Angle.Zero: [blocks[block3]],
                Angle.Ninety: blocks,
                Angle.OneEighty: [blocks[block3]],
                Angle.TwoSeventy: blocks
            ]
            
        case .TShape:
            return [
                Angle.Zero: [blocks[block0], blocks[block2], blocks[block3]],
                Angle.Ninety: [blocks[block2], blocks[block3]],
                Angle.OneEighty: [blocks[block0], blocks[block1], blocks[block2]],
                Angle.TwoSeventy: [blocks[block0], blocks[block3]]
            ]
            
        case .LShape:
            return [
                Angle.Zero: [blocks[block2], blocks[block3]],
                Angle.Ninety: [blocks[block0], blocks[block2], blocks[block3]],
                Angle.OneEighty: [blocks[block0], blocks[block3]],
                Angle.TwoSeventy: [blocks[block0], blocks[block1],blocks[block2]]
            ]
            
        case .JShape:
            return [
                Angle.Zero: [blocks[block2], blocks[block3]],
                Angle.Ninety: [blocks[block0], blocks[block1], blocks[block2]],
                Angle.OneEighty: [blocks[block0], blocks[block3]],
                Angle.TwoSeventy: [blocks[block0], blocks[block1],blocks[block3]]
            ]
            
        case .ZShape:
            return  [
                Angle.Zero: [blocks[block0], blocks[block2]],
                Angle.Ninety: [blocks[block0], blocks[block2], blocks[block3]],
                Angle.OneEighty: [blocks[block0], blocks[block2]],
                Angle.TwoSeventy: [blocks[block0], blocks[block2],blocks[block3]]
            ]
            
        case .SShape:
            return [
                Angle.Zero: [blocks[block1], blocks[block3]],
                Angle.Ninety: [blocks[block0], blocks[block2], blocks[block3]],
                Angle.OneEighty: [blocks[block1], blocks[block3]],
                Angle.TwoSeventy: [blocks[block0], blocks[block2],blocks[block3]]
            ]
        }
    }
    
    func bottumBlocksByAngle(angle:Angle)->[Block]{
        guard let bottomsBlocksByAngle = bottomBlocksPositions(type: type)[angle] else {return []}
        return bottomsBlocksByAngle
    }
}


//save to Json

struct ShapeJson:Codable{
    var blocks:[BlockJson]
    var column:Int
    var row:Int
    var angle:Angle
    var type:ShapeType
}

//this is to convert to codable protocol
extension Shape{
    
    static func shapeToJson(shape:Shape)->ShapeJson{
        let blocksJson:[BlockJson] = shape.blocks.map{
            return Block.blockToJson(block: $0)
        }
        return ShapeJson(blocks: blocksJson, column: shape.column,
                         row: shape.row, angle: shape.angle, type: shape.type)
        
    }
    
    static func shapeJsonToShape(shape:ShapeJson)->Shape{
        let blocks = shape.blocks.map{
            return Block.blockJsonToBlock(block: $0)
        }
        let newShape = Shape(column: shape.column,
                             row: shape.row, angle: shape.angle,
                             color: blocks.first!.color, type: shape.type)
        newShape.blocks = blocks
        return newShape
    }
    
}




























