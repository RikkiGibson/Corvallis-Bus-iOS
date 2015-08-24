//
//  FavoriteStopTableViewCell.swift
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
        
        // TODO: should the background color be set in the layer like this?
        self.labelFirstRoute.layer.backgroundColor = GRAY_ROUTE_COLOR.CGColor
        self.labelFirstRoute.layer.cornerRadius = 5
        self.labelFirstRoute.clipsToBounds = true
        
        self.labelSecondRoute.layer.backgroundColor = CLEAR_COLOR.CGColor
        self.labelSecondRoute.layer.cornerRadius = 5
        self.labelSecondRoute.clipsToBounds = true
    }
    
    func updateFirstRoute(named name: String?, arrivals: [BusArrival], color: UIColor) {
        
        UIView.animateWithDuration(0.2) {
            self.labelFirstRoute.layer.backgroundColor = color.CGColor
        }
        self.labelFirstRoute.text = name
        self.labelFirstArrival.text = friendlyMapArrivals(arrivals)
    }
    
    func updateSecondRoute(named name: String?, arrivals: [BusArrival], color: UIColor) {
        
        UIView.animateWithDuration(0.2) {
            self.labelSecondRoute.layer.backgroundColor = color.CGColor
        }
        self.labelSecondRoute.text = name
        self.labelSecondArrival.text = name == nil ? "" : friendlyMapArrivals(arrivals)
    }
    
    func update(viewModel: FavoriteStopViewModel) {
        labelStopName.text = viewModel.stopName
        
        labelFirstRoute.backgroundColorActual = viewModel.firstRouteColor
        labelFirstRoute.text = viewModel.firstRouteName
        labelFirstArrival.text = viewModel.firstRouteArrivals
        
        labelSecondRoute.backgroundColorActual = viewModel.secondRouteColor
        labelSecondRoute.text = viewModel.secondRouteName
        labelSecondArrival.text = viewModel.secondRouteArrivals
        
        locationImage.hidden = !viewModel.isNearestStop
        labelDistance.text = viewModel.distanceFromUser
    }
    
}
