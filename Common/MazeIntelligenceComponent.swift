import Foundation
import GameplayKit


class MazeIntelligenceComponent : GKComponent {

    var stateMachine: GKStateMachine

    init(game: MazeGame, enemy: MazeEntity, startingPosition origin: GKGridGraphNode) {
        let chase = MazeEnemyChaseState(game: game, entity: enemy)
        let flee = MazeEnemyFleeState(game: game, entity: enemy)
        let defeated = MazeEnemyDefeatedState(game: game, entity: enemy)
        defeated.respawnPosition = origin
        let respawn = MazeEnemyRespawnState(game:game, entity:enemy)
        stateMachine = GKStateMachine(states: [chase, flee, defeated, respawn])
        stateMachine.enterState(MazeEnemyChaseState.self)
    }
    
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        self.stateMachine.updateWithDeltaTime(seconds)
    }

}

