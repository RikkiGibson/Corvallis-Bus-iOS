
import Cocoa

class BrowseViewController: NSViewController {
    let manager = CorvallisBusManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // TODO: is this of any use?
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case "BusMapEmbed":
            let destination = segue.destinationController as! BusMapViewController
            destination.dataSource = manager
        default:
            break
        }
    }
}

