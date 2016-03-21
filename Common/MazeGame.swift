import Foundation
import SpriteKit
import GameplayKit

enum ContactCategory: UInt32 {
    case Player = 1, Enemy  = 2
}

@objc
class MazeGame: NSObject, MazeSceneDelegate, SKSceneDelegate, SKPhysicsContactDelegate {
    
    var level: MazeLevel!
    var enemies: [MazeEntity]!
    var player: MazeEntity!
    var intelligenceSystem: GKComponentSystem!
    var prevUpdateTime: NSTimeInterval = 0
    
    var _powerupTimeRemaining: CFTimeInterval = 0

    private var _playerDirection: MazePlayerDirection = .None

    private var _hasPowerup: Bool = false

    override init() {
        super.init()
        random = GKRandomSource()
        level = MazeLevel()
        
        // Create player entity with display and control components.
        player = MazeEntity()
        player.gridPosition = level.startPosition.gridPosition
        player.addComponent(MazeSpriteComponent(defaultColor: SKColor.cyanColor()))
        player.addComponent(MazePlayerControlComponent(level: level))
        
        // Create enemy entities with display and AI components.
        let colors = [SKColor.redColor(), SKColor.greenColor(), SKColor.yellowColor(), SKColor.magentaColor()]
        intelligenceSystem = GKComponentSystem(componentClass: MazeIntelligenceComponent.self)
        var enemies = [MazeEntity]()
        for (index, node) in level.enemyStartPositions.enumerate() {
            let enemy = MazeEntity()
            enemy.gridPosition = node.gridPosition
            enemy.addComponent(MazeSpriteComponent(defaultColor: colors[index]))
            enemy.addComponent(MazeIntelligenceComponent(game: self, enemy: enemy, startingPosition: node))
            intelligenceSystem.addComponentWithEntity(enemy)
            enemies.append(enemy)
        }
        self.enemies = enemies
    }
    
    // Random source shared by various game mechanics.
    var random: GKRandomSource!

    lazy var scene: MazeScene = {
        let scene: MazeScene = MazeScene(size: CGSizeMake(CGFloat(self.level.width) * MazeCellWidth, CGFloat(self.level.height) * MazeCellWidth))
            scene.delegate = self
            scene.physicsWorld.gravity = CGVectorMake(0, 0)
            scene.physicsWorld.contactDelegate = self
        return scene
    }()
    
    var hasPowerup: Bool {
        get {
            return _hasPowerup
        }
        set {
            let powerupDuration = NSTimeInterval(10)
            if newValue != _hasPowerup {
                var nextState: AnyClass
                if (newValue) {
                    nextState = MazeEnemyFleeState.self
                } else {
                    nextState = MazeEnemyChaseState.self
                }
                
                for component in self.intelligenceSystem.components as! [MazeIntelligenceComponent] {
                    component.stateMachine.enterState(nextState)
                }
                self.powerupTimeRemaining = powerupDuration
                _hasPowerup = newValue
            }
        }
    }
    
    var powerupTimeRemaining: CFTimeInterval {
        get {
            return _powerupTimeRemaining
        }
        set {
            _powerupTimeRemaining = newValue
            if (_powerupTimeRemaining < 0) {
                self.hasPowerup = false
            }
        }
    }

    
//MARK:- MazeSceneDelegate (SKSceneDelegate)
    
    func scene(scene: MazeScene, didMoveToView view: SKView) {
        scene.backgroundColor = SKColor.blackColor()
    
        // Generate maze.
        let maze = SKNode()
        let cellSize = CGSizeMake(MazeCellWidth, MazeCellWidth)
        let graph = self.level.pathfindingGraph!
        for i in 0..<self.level.width {
            for j in 0..<self.level.height {
                if graph.nodeAtGridPosition(vector_int2(Int32(i), Int32(j))) != nil {
				// Make nodes for traversable areas; leave walls as background color.
                    let node = SKSpriteNode(color: SKColor.grayColor(), size: cellSize)
                    node.position = CGPointMake(CGFloat(i) * MazeCellWidth + MazeCellWidth / 2, CGFloat(j) * MazeCellWidth  + MazeCellWidth / 2)
                    maze.addChild(node)
                }
            }
        }
        scene.addChild(maze)
    
        // Add player entity to scene.
        let playerComponent = self.player.componentForClass(MazeSpriteComponent.self)!
        
        let sprite = MazeSpriteNode(color: SKColor.cyanColor(), size:cellSize)
        sprite.owner = playerComponent
        sprite.position = scene.pointForGridPosition(self.player.gridPosition!)
        sprite.zRotation = CGFloat(M_PI_4)
        sprite.xScale = CGFloat(M_SQRT1_2)
        sprite.yScale = CGFloat(M_SQRT1_2)
        
        let body = SKPhysicsBody(circleOfRadius: MazeCellWidth/2)
        body.categoryBitMask = ContactCategory.Player.rawValue
        body.contactTestBitMask = ContactCategory.Enemy.rawValue
        body.collisionBitMask = 0
        sprite.physicsBody = body
        playerComponent.sprite = sprite
        scene.addChild(playerComponent.sprite!)
        
        // Add enemy entities to scene.
        for entity in self.enemies! {
            let enemyComponent = entity.componentForClass(MazeSpriteComponent.self)!
            enemyComponent.sprite = MazeSpriteNode(color: enemyComponent.defaultColor!, size: cellSize)
            enemyComponent.sprite.owner = enemyComponent
            enemyComponent.sprite.position = scene.pointForGridPosition(entity.gridPosition!)
        
            let body = SKPhysicsBody(circleOfRadius: MazeCellWidth/2)
            body.categoryBitMask = ContactCategory.Enemy.rawValue
            body.contactTestBitMask = ContactCategory.Player.rawValue
            body.collisionBitMask = 0
            enemyComponent.sprite.physicsBody = body
            
            scene.addChild(enemyComponent.sprite!)
        }
    }
    
    func update(currentTime: NSTimeInterval, forScene scene: SKScene) {
        // Track the time delta since the last update.
        if (self.prevUpdateTime < 0) {
            self.prevUpdateTime = currentTime
        }
        let dt = currentTime - self.prevUpdateTime
        self.prevUpdateTime = currentTime
        
        // Track remaining time on the powerup.
        self.powerupTimeRemaining -= dt
        
        // Update components with the new time delta.
        self.intelligenceSystem.updateWithDeltaTime(dt)
        self.player.updateWithDeltaTime(dt)
    }
    
//MARK:- SKPhysicsContactDelegate
    
    func didBeginContact(contact: SKPhysicsContact) {
        var enemyNode: MazeSpriteNode!
        if (contact.bodyA.categoryBitMask == ContactCategory.Enemy.rawValue) {
            enemyNode = contact.bodyA.node as? MazeSpriteNode
        } else if (contact.bodyB.categoryBitMask == ContactCategory.Enemy.rawValue) {
            enemyNode = contact.bodyB.node as? MazeSpriteNode
        }
        assert(enemyNode != nil, "Expected player-enemy/enemy-player collision")
    
        // If the player contacts an enemy that's in the Chase state, the player is attacked.
        let entity = enemyNode.owner.entity as! MazeEntity
        let aiComponent = entity.componentForClass(MazeIntelligenceComponent.self)!
        if aiComponent.stateMachine.currentState is MazeEnemyChaseState {
            self.playerAttacked()
        } else {
            // Otherwise, that enemy enters the Defeated state only if in a state that allows that transition.
            aiComponent.stateMachine.enterState(MazeEnemyDefeatedState.self)
        }
    }
    
    func playerAttacked() {
        // Warp player back to starting point.
        let spriteComponent = self.player.componentForClass(MazeSpriteComponent.self)!
        spriteComponent.warpToGridPosition(self.level.startPosition.gridPosition)
        
        // Reset the player's direction controls upon warping.
        let controlComponent = self.player.componentForClass(MazePlayerControlComponent.self)!
        controlComponent.direction = .None
        controlComponent.attemptedDirection = .None
    }
    
    var playerDirection: MazePlayerDirection {
        get {
            // Forward directional input from the control component.
            let component = self.player.componentForClass( MazePlayerControlComponent.self)!
            return component.direction
        }
        set(playerDirection) {
            // Forward directional input to the control component.
            let component = self.player.componentForClass(MazePlayerControlComponent.self)!
            component.attemptedDirection = playerDirection
        }
    }
}