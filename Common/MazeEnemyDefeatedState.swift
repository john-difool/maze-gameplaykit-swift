import Foundation
import GameplayKit

class MazeEnemyDefeatedState: MazeEnemyState {
    
    var respawnPosition: GKGridGraphNode?

    override init(game: MazeGame, entity: MazeEntity) {
        super.init(game: game, entity: entity)
    }
    
//MARK:- GKState Life Cycle

    func isValidNextState<T>(stateClass: T.Type) -> Bool {
        return stateClass is MazeEnemyRespawnState.Type
    }
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        // Change the enemy sprite's appearance to indicate defeat.
        let component = self.entity.componentForClass(MazeSpriteComponent.self)!
        component.useDefeatedAppearance()
        
        // Use pathfinding to find a route back to this enemy's starting position.
        let graph = self.game.level.pathfindingGraph!
        let enemyNode = graph.nodeAtGridPosition(self.entity.gridPosition!)
        let path = graph.findPathFromNode(enemyNode!, toNode: self.respawnPosition!) as! [GKGridGraphNode]
        component.followPath(path, completion: { _ in
            self.stateMachine!.enterState(MazeEnemyRespawnState.self)
        })
    }
}
