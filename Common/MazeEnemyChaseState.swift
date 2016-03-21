import Foundation
import GameplayKit

class MazeEnemyChaseState: MazeEnemyState {

    var ruleSystem:GKRuleSystem!
    var _hunting: Bool = false
    var scatterTarget: GKGridGraphNode!

    var hunting: Bool {
        get {
            return _hunting
        }
        set {
            if (_hunting != newValue) {
                if (!newValue) {
                    let positions = self.game.random.arrayByShufflingObjectsInArray(self.game.level.enemyStartPositions)
                    self.scatterTarget = positions.first as! GKGridGraphNode
                }
            }
            _hunting = newValue
        }
    }
    
    func isHunting() -> Bool {
        return hunting
    }
    

    override init(game: MazeGame, entity: MazeEntity) {
        super.init(game: game, entity: entity)
    
        self.ruleSystem = GKRuleSystem()
        
        let playerFar = NSPredicate(format: "$distanceToPlayer.floatValue >= 10.0")
        ruleSystem.addRule(GKRule(predicate: playerFar, assertingFact:"hunt", grade:1.0))
        
        let playerNear = NSPredicate(format: "$distanceToPlayer.floatValue < 10.0")
        ruleSystem.addRule(GKRule(predicate: playerNear, retractingFact:"hunt", grade:1.0))
    }
    
    func pathToPlayer() -> [GKGridGraphNode] {
        let graph = self.game.level.pathfindingGraph
        let playerNode = graph.nodeAtGridPosition(self.game.player.gridPosition!)
        return self.pathToNode(playerNode!)
    }

//MARK:- GKState Life Cycle

    func isValidNextState<T>(stateClass: T.Type) -> Bool {
        return stateClass is MazeEnemyFleeState.Type
    }
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        // Set the enemy sprite to its normal appearance, undoing any changes that happened in other states.
        let component = self.entity.componentForClass(MazeSpriteComponent.self)!
        component.useNormalAppearance()
    }
        
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        // If the enemy has reached its target, choose a new target.
        let position = self.entity.gridPosition!
        if let scatterTarget = self.scatterTarget {
            if (position.x == scatterTarget.gridPosition.x && position.y == scatterTarget.gridPosition.y) {
                self.hunting = true
            }
        }
        
        let distanceToPlayer = self.pathToPlayer().count
        self.ruleSystem.state["distanceToPlayer"] = distanceToPlayer
        
        self.ruleSystem.reset()
        self.ruleSystem.evaluate()
        
        self.hunting = self.ruleSystem.gradeForFact("hunt") > 0.0
        if self.hunting {
            self.startFollowingPath(self.pathToPlayer())
        } else {
            self.startFollowingPath(self.pathToNode(self.scatterTarget!))
        }
    }

}