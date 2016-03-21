import Foundation
import GameplayKit

class MazeEnemyState : GKState {

    weak var game: MazeGame!
    var entity: MazeEntity!

    init(game: MazeGame, entity: MazeEntity) {
        super.init()
        self.game = game
        self.entity = entity
    }

//MARK:- Path Finding & Following
    
    func pathToNode(node: GKGridGraphNode) -> [GKGridGraphNode] {
        let graph = self.game.level.pathfindingGraph
        let enemyNode = graph.nodeAtGridPosition(self.entity.gridPosition!)
        let path = graph.findPathFromNode(enemyNode!, toNode: node) as? [GKGridGraphNode]
        return path!
    }
    
    func startFollowingPath(path: [GKGridGraphNode]) {
        /*
         Set up a move to the first node on the path, but
         no farther because the next update will recalculate the path.
        */
        if (path.count > 1) {
            let firstMove = path[1] // path[0] is the enemy's current position.
            let component = self.entity.componentForClass(MazeSpriteComponent.self)!
            component.nextGridPosition = firstMove.gridPosition
        }
    }

}
