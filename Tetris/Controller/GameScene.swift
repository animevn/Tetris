import SpriteKit

class GameScene: SKScene {
    
    let gameLayer = SKSpriteNode()
    let shapeLayer = SKSpriteNode()
    var background = SKSpriteNode()
    var layerPosition:CGPoint?
    var blockSize:CGFloat?
    
    var updateCurrentShape:(()->Void)?
    var timeIntervalMillis = TimeInterval(650)
    var lastUpdate:Date?
    
    var textureCached = [String:SKTexture]()
    var lbScore = SKLabelNode()
    var lbLevel = SKLabelNode()
    var lbHigh1 = SKLabelNode()
    var lbHigh2 = SKLabelNode()
    var lbHigh3 = SKLabelNode()
    var lbHigh4 = SKLabelNode()
    var lbHigh5 = SKLabelNode()
    
    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0, y: 1)
        let temp = getSize(width: Int((scene?.size.width)!), height: Int((scene?.size.height)!))
        blockSize = (temp.x - 20)/15
        self.layerPosition = CGPoint(x: 5, y: -10 - temp.head)
        
        self.background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 0, y: 0)
        background.anchorPoint = CGPoint(x: 0, y: 1)
        background.scale(to: size)
        addChild(background)
        
        addChild(gameLayer)
        createLabels()
        
        let gameTexture = SKTexture(imageNamed: "gameboard")
        let gameboard = SKSpriteNode(
            texture: gameTexture,
            size: CGSize(width: blockSize!*CGFloat(numOfColums),
                         height: blockSize!*CGFloat(numOfRows)))
        
        gameboard.anchorPoint = CGPoint(x: 0, y: 1)
        gameboard.position = layerPosition!
        shapeLayer.addChild(gameboard)
        
        
        shapeLayer.anchorPoint = CGPoint(x: 0, y: 1)
        gameLayer.addChild(shapeLayer)
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let lastUpdate = lastUpdate else {return}
        
        let deltaTime = lastUpdate.timeIntervalSinceNow * -1000
        if deltaTime > timeIntervalMillis{
            self.startUpdate()
            updateCurrentShape?()
        }
    }
    
    func startUpdate(){
        lastUpdate = Date()
    }
    
    func stopUpdate(){
        lastUpdate = nil
    }
    
    //very important func, it return real location of node (block)
    private func positionForNode(column:Int, row:Int)->CGPoint{
        let x = layerPosition!.x + (CGFloat(column)*blockSize!)
        let y = layerPosition!.y - (CGFloat(row)*blockSize!)
        return CGPoint(x: x, y: y)
    }
    
    //very important func, it return real location of node (block)
    private func positionForBlock(column:Int, row:Int)->CGPoint{
        let x = layerPosition!.x + ((CGFloat(column)*blockSize!) + blockSize!/2)
        let y = layerPosition!.y - ((CGFloat(row)*blockSize!) + blockSize!/2)
        return CGPoint(x: x, y: y)
    }
    
    //create label
    private func createLabels(){
        
        createLabel(title: "SCORE", color: .green, column: 13, row: 6)
        modifyLabel(label: lbScore, text: "99999", color: .green, column: 13, row: 7)
        
        createLabel(title: "LEVEL", color: .orange, column: 13, row: 9)
        modifyLabel(label: lbLevel, text: "99999", color: .orange, column: 13, row: 10)
        
        createLabel(title: "HIGHSCORE", color: .green, column: 13, row: 12)
        modifyLabel(label: lbHigh1, text: "", color: .orange, column: 13, row: 13)
        modifyLabel(label: lbHigh2, text: "", color: .orange, column: 13, row: 14)
        modifyLabel(label: lbHigh3, text: "", color: .orange, column: 13, row: 15)
        modifyLabel(label: lbHigh4, text: "", color: .orange, column: 13, row: 16)
        modifyLabel(label: lbHigh5, text: "", color: .orange, column: 13, row: 17)
    }
    
    //create label title
    private func createLabel(title:String, color:UIColor, column:Int, row:Int){
        let label = SKLabelNode()
        label.text = title
        label.horizontalAlignmentMode = .center
        label.fontColor = color
        label.fontSize = 18
        label.fontName = "MarkerFelt-Wide"
        label.position = positionForNode(column: column, row: row)
        gameLayer.addChild(label)
    }
    
    private func modifyLabel(label: SKLabelNode, text:String, color:UIColor, column:Int, row:Int){
        label.text = text
        label.horizontalAlignmentMode = .center
        label.fontColor = color
        label.fontSize = 18
        label.fontName = "MarkerFelt-Wide"
        label.position = positionForNode(column: column, row: row)
        gameLayer.addChild(label)
    }
    
    
    //this func add shape to preview pane
    func addShapeToPreview(shape:Shape, completion:@escaping ()->Void){
        
        for block in shape.blocks{
            var texture = textureCached[block.color.description]
            if texture == nil{
                texture = SKTexture(imageNamed: block.color.description)
                textureCached[block.color.description] = texture
            }
            
            let blockSprite = SKSpriteNode(texture: texture)
            blockSprite.scale(to: CGSize(width: blockSize!, height: blockSize!))
            blockSprite.position = positionForBlock(column: block.column, row: block.row)
            shapeLayer.addChild(blockSprite)
            block.blockNode = blockSprite
            
            blockSprite.alpha = 0
            
            let moveAction = SKAction.move(
                to: positionForBlock(column: block.column, row: block.row),
                duration: 0.1)
            moveAction.timingMode = .easeOut
            
            let fadeAction = SKAction.fadeAlpha(to: 1, duration: 0.4)
            fadeAction.timingMode = .easeOut
            
            blockSprite.run(SKAction.group([
                moveAction,
                fadeAction 
                ]))
        }
        
        run(SKAction.wait(forDuration: 0.2), completion: completion)
    }
    
    //move shape
    func moveShapeToPosition(shape:Shape, completion:@escaping ()->Void){
        
        for block in shape.blocks{
            guard let blockSprite = block.blockNode else {return}
            let moveTo = positionForBlock(column: block.column, row: block.row)
            let moveToAction = SKAction.move(to: moveTo, duration: 0.2)
            moveToAction.timingMode = .easeOut
            blockSprite.run(moveToAction)
        }
        run(SKAction.wait(forDuration: 0.2), completion: completion)
    }
    
    //draw shape
    func reDrawShape(shape:Shape, completion:@escaping ()->Void){
        for block in shape.blocks{
            let blockSprite = block.blockNode!
            let moveTo = positionForBlock(column: block.column, row: block.row)
            let moveToAction = SKAction.move(to: moveTo, duration: 0.05)
            moveToAction.timingMode = .easeOut
            
            if block == shape.blocks.last!{
                blockSprite.run(moveToAction, completion: completion)
            }else{
                blockSprite.run(moveToAction)
            }
        }
    }
    
    func moveLoadShapeToPosition(shape:Shape, completion:@escaping ()->Void){
        
        for block in shape.blocks{
            var texture = textureCached[block.color.description]
            if texture == nil{
                texture = SKTexture(imageNamed: block.color.description)
                textureCached[block.color.description] = texture
            }
            
            let blockSprite = SKSpriteNode(texture: texture)
            blockSprite.scale(to: CGSize(width: blockSize!, height: blockSize!))
            blockSprite.position = positionForBlock(column: block.column, row: block.row)
            shapeLayer.addChild(blockSprite)
            block.blockNode = blockSprite
            
            let moveTo = positionForBlock(column: block.column, row: block.row)
            let moveToAction = SKAction.move(to: moveTo, duration: 0.2)
            moveToAction.timingMode = .easeOut
            blockSprite.run(moveToAction)
        }
        run(SKAction.wait(forDuration: 0.2), completion: completion)
    }
    
    //draw filled blocks
    func drawFilledCells(filledCells:[[Block]]){
        for row in filledCells{
            for block in row{
                var texture = textureCached[block.color.description]
                if texture == nil{
                    texture = SKTexture(imageNamed: block.color.description)
                    textureCached[block.color.description] = texture
                }
                
                let blockSprite = SKSpriteNode(texture: texture)
                blockSprite.scale(to: CGSize(width: blockSize!, height: blockSize!))
                blockSprite.position = positionForBlock(column: block.column, row: block.row)
                shapeLayer.addChild(blockSprite)
                block.blockNode = blockSprite
            }
        }
    }
    
    //remove shape in preview pane when gameover
    func removeShape(shape:Shape){
        for block in shape.blocks{
            let blockSprite = block.blockNode!
            blockSprite.removeFromParent()
        }
    }
    
    //longest func in this app
    func animateRows(filledRows:[[Block]], remnants:[[Block]], completion:@escaping ()->Void){
        
        //animate filledRow
        for fillRow in filledRows{
            for (rowIdx, block) in fillRow.enumerated().reversed(){
                let newPosition = positionForBlock(column: 11, row: block.row)
                let blockNode = block.blockNode
                let delay = TimeInterval(rowIdx)*0.02
                let distance = newPosition.x - blockNode!.position.x
                let duration = TimeInterval((distance/blockSize!) * 0.02)
                
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeIn
                
                blockNode?.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    moveAction,
                    SKAction.fadeOut(withDuration: 0.01),
                    SKAction.removeFromParent()
                    ]))
            }
        }
        
        //lower remain blocks
        if remnants.count > 0{
            for (idx, row) in remnants.enumerated(){
                for block in row{
                    let newPosition = positionForBlock(column: block.column, row: block.row)
                    let blockNode = block.blockNode!
                    
                    //create a delay , sow the lesser the row, the more delay
                    let delay = 0.2 + TimeInterval(idx)*0.02
                    
                    //distance from blockNode to new Position
                    let distance = blockNode.position.y - newPosition.y
                    
                    //duration for block to travel to new position, basically mean that time to
                    //travel a block is 0.1 sec - which is total of delay for each column and each row
                    let duration = TimeInterval((distance/blockSize!) * 0.02)
                    
                    let moveAction = SKAction.move(to: newPosition, duration: duration)
                    moveAction.timingMode = .easeOut
                    
                    //move node
                    blockNode.run(SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        moveAction
                        ]))
                }
            }
        }
        
        //wait for drop all remnants and run new action (closure)
        run(SKAction.wait(forDuration: 0.2), completion: completion)
    }
    
}

//make detail size of each kind of Iphone: width, height, and statusbar distance
func getSize(width:Int, height:Int)->(x:CGFloat, y:CGFloat, head:CGFloat){
    
    switch (width, height) {
        
    //XSMax, XR portrait : status bar = 44, bottom bar = 34
    case (414, 896):
        return (414, 896 - 44 - 34, 44)
        
    //X, XS portrait : status bar = 44, bottom bar = 34
    case (375, 812):
        return (375, 812 - 44, 44)
        
    //6 Plus, 6S Plus, 7 Plus, 8 Plus portrait : status bar = 18
    case (414, 736):
        return (414, 736 - 18, 18)
        
    //6, 6S, 7, 8 portrait : status bar = 20
    case (375, 667):
        return (375, 667 - 20, 20)
        
    //SE portrait : status bar = 20
    case (320, 568):
        return (320, 568 - 20, 20)
        
    //default value which never used
    default:
        return (CGFloat(width), CGFloat(height - 50), 20)
    }
}
