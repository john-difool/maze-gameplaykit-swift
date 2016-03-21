import Cocoa
import SpriteKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var skView: SKView!
    
    var game: MazeGame!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.game = MazeGame()
        let scene = self.game.scene
        scene.scaleMode = .AspectFit
        
        // Present the scene and configure the SpriteKit view.
        self.skView.presentScene(scene)
        self.skView.ignoresSiblingOrder = true
        self.skView.showsFPS = true
        self.skView.showsNodeCount = true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}
