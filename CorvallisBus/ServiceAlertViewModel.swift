import Foundation

struct ServiceAlertViewModel {
    var title: String
    var description: String
    var link: String
    
    /// Uniquely identifies the service alert.
    /// Currently a concatenation of the link and publish date.
    var id: String
    
    var isRead: Bool
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    static func fromServiceAlert(serviceAlert: ServiceAlert, isRead: Bool) -> ServiceAlertViewModel {
        let dateString = dateFormatter.string(from: serviceAlert.publishDate)
        
        let alert = ServiceAlertViewModel(
            title: serviceAlert.title,
            description: dateString,
            link: serviceAlert.link,
            id: serviceAlert.id,
            isRead: isRead)
        
        return alert
    }
}
