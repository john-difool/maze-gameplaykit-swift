import Foundation
import GameplayKit

class MazeEnemyFleeState: MazeEnemyState {

    var target: GKGridGraphNode!

    override init(game: MazeGame, entity: MazeEntity) {
        super.init(game: game, entity: entity)
    }
    
    func isValidNextState<T>(stateClass: T.Type) -> Bool {
        return stateClass is MazeEnemyChaseState.Type ||
            stateClass is MazeEnemyDefeatedState.Type
    }

//MARK:- GKState Life Cycle

    override func didEnterWithPreviousState(previousState: GKState?) {
        let component = self.entity.componentForClass(MazeSpriteComponent.self)!
        component.useFleeAppearance()
    
        // Choose a location to flee towards.
        self.target = self.game.random.arrayByShufflingObjectsInArray(self.game.level.enemyStartPositions!).first as? GKGridGraphNode
    }
    
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        // If the enemy has reached its target, choose a new target.
        let position = self.entity.gridPosition!
        if (position.x == self.target.gridPosition.x && position.y == self.target.gridPosition.y) {
            self.target = self.game.random.arrayByShufflingObjectsInArray(self.game.level.enemyStartPositions!).first as! GKGridGraphNode
        }
        // Flee towards the current target point.
        self.startFollowingPath(self.pathToNode(self.target))
    }

}
