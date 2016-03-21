import SpriteKit

let MazeCellWidth = CGFloat(27.0)

protocol MazeSceneDelegate {
    var hasPowerup: Bool { get set }
    var playerDirection: MazePlayerDirection { get set }
    func scene(scene: MazeScene, didMoveToView view: SKView)
}

class MazeScene: SKScene {

    override func didMoveToView(view: SKView) {
        if let game = delegate as? MazeGame {
            game.scene(self, didMoveToView: view)
        }
    }
    
    func pointForGridPosition(position: vector_int2) -> CGPoint {
        return CGPointMake(CGFloat(position.x) * MazeCellWidth + MazeCellWidth / 2, CGFloat(position.y) * MazeCellWidth + MazeCellWidth / 2)
    }

    override func keyDown(theEvent: NSEvent) {
        if let game = delegate as? MazeGame {
            switch (theEvent.keyCode) {
            case 123:
                game.playerDirection = .Left
            case 124:
                game.playerDirection = .Right
            case 125:
                game.playerDirection = .Down
            case 126:
                game.playerDirection = .Up
            case 49:
                game.hasPowerup = true
            default:
                break
            }
        }
    }
}
