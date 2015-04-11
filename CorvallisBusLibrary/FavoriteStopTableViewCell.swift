//
//  TodayTableViewCell.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/21/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

let GRAY_ROUTE_COLOR = UIColor.lightGrayColor()
let CLEAR_COLOR = UIColor.clearColor()

final class FavoriteStopTableViewCell: UITableViewCell {
    @IBOutlet weak var labelStopName: UILabel!
    
    @IBOutlet weak var labelFirstRoute: BusRouteLabel!
    @IBOutlet weak var labelFirstArrival: UILabel!
    
    @IBOutlet weak var labelSecondRoute: BusRouteLabel!
    @IBOutlet weak var labelSecondArrival: UILabel!
    
    @IBOutlet weak var labelDistance: UILabel!
    @IBOutlet weak var locationImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.labelFirstRoute.layer.backgroundColor = DEFAULT_ROUTE_COLOR.CGColor
        self.labelFirstRoute.layer.cornerRadius = 5
        self.labelFirstRoute.clipsToBounds = true
        
        self.labelSecondRoute.layer.backgroundColor = CLEAR_COLOR.CGColor
        self.labelSecondRoute.layer.cornerRadius = 5
        self.labelSecondRoute.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func updateFirstRoute(named name: String?, arrivals: [BusArrival], color: UIColor?, fallbackToGrayColor: Bool) {
        var color = color
        if name == nil {
            color = fallbackToGrayColor ? GRAY_ROUTE_COLOR : CLEAR_COLOR
        } else { // if there is a route name but no color was provided, use the default instead of gray
            color = color ?? DEFAULT_ROUTE_COLOR
        }
        
        UIView.animateWithDuration(0.2) {
            self.labelFirstRoute.layer.backgroundColor = color?.CGColor
            return
        }
        self.labelFirstRoute.text = name
        self.labelFirstArrival.text = friendlyMapArrivals(arrivals)
    }
    
    func updateSecondRoute(named name: String?, arrivals: [BusArrival], color: UIColor?) {
        
        UIView.animateWithDuration(0.2) {
            self.labelSecondRoute.layer.backgroundColor = name == nil ? CLEAR_COLOR.CGColor :
                color?.CGColor ?? DEFAULT_ROUTE_COLOR.CGColor
        }
        self.labelSecondRoute.text = name
        self.labelSecondArrival.text = name == nil ? "" : friendlyMapArrivals(arrivals)
    }
}
