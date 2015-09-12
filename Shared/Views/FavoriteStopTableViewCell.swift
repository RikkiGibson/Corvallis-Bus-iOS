//
//  FavoriteStopTableViewCell.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/21/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

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
        
        labelFirstRoute.backgroundColor = UIColor.lightGrayColor()
        labelFirstRoute.layer.cornerRadius = 5
        labelFirstRoute.clipsToBounds = true
        
        labelSecondRoute.backgroundColor = UIColor.clearColor()
        labelSecondRoute.layer.cornerRadius = 5
        labelSecondRoute.clipsToBounds = true
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
