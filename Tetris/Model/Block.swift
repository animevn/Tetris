import SpriteKit

let numOfColors:UInt32 = 6

enum BlockColor:Int, CustomStringConvertible, Codable{
    
    case Orange = 0, Blue, Purple, Red, Teal, Yellow
    
    var description: String{
        switch self{
        case .Orange:
            return "orange"
        case .Blue:
            return "blue"
        case .Purple:
            return "purple"
        case .Red:
            return "red"
        case .Teal:
            return "teal"
        case .Yellow:
            return "yellow"
        }
    }
    
    static func random()->BlockColor{
        return BlockColor(rawValue: Int(arc4random_uniform(numOfColors)))!
    }
}

class Block:CustomStringConvertible{
    
    let color:BlockColor
    var column:Int
    var row:Int
    
    var blockNode:SKSpriteNode?
    
    var description: String {
        return "\(color) (\(column), \(row))"
    }
    
    static func ==(lhs: Block, rhs: Block) -> Bool {
        return  lhs.column == rhs.column
                && lhs.row == rhs.row
                && lhs.color.rawValue == rhs.color.rawValue
    }
    
    init(column:Int, row:Int, color:BlockColor){
        self.color = color
        self.column = column
        self.row = row
    }
}

struct BlockJson:Codable
{
    var color:BlockColor
    var column:Int
    var row:Int
}

//convert between block and codable
extension Block{

    static func blockToJson(block:Block)->BlockJson{
        return BlockJson(color: block.color, column: block.column, row: block.row)
    }
    
    static func blockJsonToBlock(block:BlockJson)->Block{
        return Block(column: block.column, row: block.row, color: block.color)
    }
}



























