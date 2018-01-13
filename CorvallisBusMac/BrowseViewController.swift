
import Cocoa

class BrowseViewController: NSViewController {
    let manager = CorvallisBusManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // TODO: is this of any use?
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case NSStoryboardSegue.Identifier(rawValue: "BusMapEmbed"):
            let destination = segue.destinationController as! BusMapViewController
            destination.dataSource = manager
        default:
            break
        }
    }
}

