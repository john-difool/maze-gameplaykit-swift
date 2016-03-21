import Foundation
import GameplayKit

enum MazePlayerDirection {
    case None, Left, Right, Down, Up
}

class MazePlayerControlComponent: GKComponent {
    
    var nextNode: GKGridGraphNode?
    var level: MazeLevel
    var _direction: MazePlayerDirection = .None
    var attemptedDirection: MazePlayerDirection = .None

    init(level: MazeLevel) {
        self.level = level
    }

    var direction: MazePlayerDirection {
        get {
            return _direction
        }
        set(direction) {
#if false
            var proposedNode: GKGridGraphNode?
            if (direction != .None) { // currently moving
                proposedNode = nodeInDirection(direction, fromNode:self.nextNode!)
            } else {
                let currentNode = self.level.pathfindingGraph.nodeAtGridPosition((self.entity as! MazeEntity).gridPosition!)
                proposedNode = self.nodeInDirection(direction, fromNode: currentNode!)
            }
            if (proposedNode == nil) {
                return
            }
#endif
            _direction = direction
        }
    }
        
    func nodeInDirection(direction: MazePlayerDirection, fromNode node : GKGridGraphNode) -> GKGridGraphNode? {
        var nextPosition: vector_int2
        switch (direction) {
        case .Left: nextPosition = node.gridPosition &+ vector_int2(-1, 0)
        case .Right: nextPosition = node.gridPosition &+ vector_int2(1, 0)
        case .Down: nextPosition = node.gridPosition &+ vector_int2(0, -1)
        case .Up: nextPosition = node.gridPosition &+ vector_int2(0, 1)
        case .None: return nil
        }
        return self.level.pathfindingGraph.nodeAtGridPosition(nextPosition)
    }
            
    func makeNextMove() {
        let currentNode = self.level.pathfindingGraph.nodeAtGridPosition((self.entity as! MazeEntity).gridPosition!)!
        let nextNode = self.nodeInDirection(self.direction, fromNode: currentNode)
        let attemptedNextNode = self.nodeInDirection(self.attemptedDirection, fromNode: currentNode)
        if (attemptedNextNode != nil) {
            // Move in the attempted direction.
            self.direction = self.attemptedDirection
            self.nextNode = attemptedNextNode!
            let component = self.entity!.componentForClass(MazeSpriteComponent.self)!
            component.nextGridPosition = self.nextNode!.gridPosition
        } else if (attemptedNextNode == nil && nextNode != nil) {
            // Keep moving in the same direction.
            self.nextNode = nextNode!
            let component = self.entity!.componentForClass(MazeSpriteComponent.self)!
            component.nextGridPosition = self.nextNode!.gridPosition
        } else {
            // Can't move any more.
            self.direction = .None
        }
    }
                
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        makeNextMove()
    }

}
