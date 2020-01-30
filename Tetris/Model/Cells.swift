class Cells<T>{
    
    let columns:Int
    let rows:Int
    var cells:[T?]
    
    init(columns:Int, rows:Int){
        self.columns = columns
        self.rows = rows
        cells = Array<T?>(repeating: nil, count: self.columns * self.rows)
    }
    
    //getter setter
    subscript(column:Int, row:Int)->T?{
        get{
            return cells[(row * self.columns) + column]
        }
        set {
            cells[(row * self.columns) + column] = newValue
        }
    }
}


