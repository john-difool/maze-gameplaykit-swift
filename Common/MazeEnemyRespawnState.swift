import Foundation
import GameplayKit


class MazeEnemyRespawnState: MazeEnemyState {

    var timeRemaining: NSTimeInterval  = 0.0

    override init(game: MazeGame, entity: MazeEntity) {
        super.init(game: game, entity: entity)
    }

//MARK:- GKState Life Cycle

    func isValidNextState<T>(stateClass: T.Type) -> Bool {
        return stateClass is MazeEnemyChaseState.Type
    }
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        let defaultRespawnTime = NSTimeInterval(10)
        self.timeRemaining = defaultRespawnTime
        
        let component = self.entity.componentForClass(MazeSpriteComponent.self)!
        component.pulseEffectEnabled = true
    }
        
    override func willExitWithNextState(nextState: GKState?) {
        // Restore the sprite's original appearance.
        let component = self.entity.componentForClass(MazeSpriteComponent.self)!
        component.pulseEffectEnabled = false
    }
        
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        self.timeRemaining = NSTimeInterval(Double(self.timeRemaining) - Double(seconds))
        if (self.timeRemaining < 0) {
            self.stateMachine!.enterState(MazeEnemyChaseState.self)
        }
    }

}
