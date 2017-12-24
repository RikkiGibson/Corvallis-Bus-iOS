import Foundation

struct ServiceAlert {
    var title: String
    var publishDate: Date
    var link: String
    
    /// Uniquely identifies the service alert.
    /// Currently a concatenation of the link and publish date.
    var id: String

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    static func fromDictionary(_ data: [String : AnyObject]) -> ServiceAlert? {
        guard let title = data["title"] as? String,
            let link = data["link"] as? String,
            let publishDateString = data["publishDate"] as? String,
            let publishDate = dateFormatter.date(from: publishDateString) else {
                
            return nil
        }
        
        return ServiceAlert(title: title, publishDate: publishDate, link: link, id: link + " " + publishDateString)
    }
}
