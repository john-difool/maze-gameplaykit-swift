import Foundation
import SpriteKit
import GameplayKit


class MazeSpriteComponent : GKComponent {

    var sprite: MazeSpriteNode!
    
    var defaultColor: SKColor!

    init(defaultColor color: SKColor) {
        super.init()
        defaultColor = color
    }
    
//MARK:- Appearance
    
    var _pulseEffectEnabled: Bool?

    var pulseEffectEnabled: Bool {
        get {
            return _pulseEffectEnabled!
        }
        set(pulseEffectEnabled) {
            _pulseEffectEnabled = pulseEffectEnabled
            if (pulseEffectEnabled) {
                let grow = SKAction.scaleBy(1.5, duration:0.5)
                let sequence = SKAction.sequence([grow, grow.reversedAction()])
                self.sprite.runAction(SKAction.repeatActionForever(sequence), withKey:"pulse")
            } else {
                self.sprite.removeActionForKey("pulse")
                self.sprite.runAction(SKAction.scaleTo(1.0, duration:0.5))
            }
        }
    }
    
    func useNormalAppearance() {
        if let sprite = self.sprite {
            sprite.color = self.defaultColor!
        }
    }
    
    func useFleeAppearance() {
        self.sprite.color = SKColor.whiteColor()
    }
    
    func useDefeatedAppearance() {
        self.sprite.runAction(SKAction.scaleTo(0.25, duration:0.25))
    }


//MARK:- Movement
    
    var _nextGridPosition: vector_int2 = vector_int2()
    
    var nextGridPosition: vector_int2 {
        get {
            return _nextGridPosition
        }
        set(nextGridPosition) {
            if (_nextGridPosition.x != nextGridPosition.x || _nextGridPosition.y != nextGridPosition.y) {
                _nextGridPosition = nextGridPosition
    
                let action = SKAction.moveTo((self.sprite.scene as! MazeScene).pointForGridPosition(nextGridPosition), duration:0.35)
                let update = SKAction.runBlock({ _ in
                    (self.entity as! MazeEntity).gridPosition = nextGridPosition
                })
    
                self.sprite.runAction(SKAction.sequence([action, update]), withKey:"move")
            }
        }
    }
    
    func warpToGridPosition(gridPosition: vector_int2) {
        let fadeOut = SKAction.fadeOutWithDuration(0.5)
        let warp = SKAction.moveTo((self.sprite.scene as! MazeScene).pointForGridPosition(gridPosition), duration:0.5)
        let fadeIn = SKAction.fadeInWithDuration(0.5)
        let update = SKAction.runBlock({ _ in
            (self.entity as! MazeEntity).gridPosition = gridPosition
        })
        self.sprite.runAction(SKAction.sequence([fadeOut, update, warp, fadeIn]))
    }
    
    func followPath(path: [GKGridGraphNode], completion completionHandler: ()->Void) {
        // Ignore the first node in the path -- it's the starting position.
        let dropFirst = path.dropFirst()
        var sequence = [SKAction]()
        
        for node in dropFirst {
            let point = (self.sprite.scene as! MazeScene).pointForGridPosition(node.gridPosition)
            sequence.append(SKAction.moveTo(point, duration:0.15))
            sequence.append(SKAction.runBlock({ _ in
                (self.entity as! MazeEntity).gridPosition = node.gridPosition
            }))
        }
        
        sequence.append(SKAction.runBlock(completionHandler))
        self.sprite.runAction(SKAction.sequence(sequence))
    }

}
