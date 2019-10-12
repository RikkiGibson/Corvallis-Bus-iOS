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
        
        labelFirstRoute.layer.cornerRadius = 6
        labelFirstRoute.clipsToBounds = true
        
        labelSecondRoute.layer.cornerRadius = 6
        labelSecondRoute.clipsToBounds = true
        
        // Ideally, we would check the background color, but for now checking OS version will have to do.
        if #available(iOS 13.0, *) {
            labelStopName.textColor = UIColor.label
            labelFirstRoute.textColor = UIColor.white
            labelSecondRoute.textColor = UIColor.white
            labelFirstArrival.textColor = UIColor.label
            labelSecondArrival.textColor = UIColor.label
            labelDistance.textColor = UIColor.secondaryLabel
        }
        else if #available(iOSApplicationExtension 10.0, *) {
            labelStopName.textColor = UIColor.black
            labelFirstArrival.textColor = UIColor.black
            labelSecondArrival.textColor = UIColor.black
            labelDistance.textColor = UIColor.darkGray
        } else {
            // iOS 9. Test this
            locationImage.image = UIImage(named: "ListCurrentLocWhite")
        }
    }
    
    func update(_ viewModel: FavoriteStopViewModel) {
        labelStopName.text = viewModel.stopName
        
        labelFirstRoute.backgroundColorActual = viewModel.firstRouteColor
        labelFirstRoute.text = viewModel.firstRouteName
        labelFirstArrival.text = viewModel.firstRouteArrivals
        
        labelSecondRoute.backgroundColorActual = viewModel.secondRouteColor
        labelSecondRoute.text = viewModel.secondRouteName
        labelSecondArrival.text = viewModel.secondRouteArrivals
        
        locationImage.isHidden = !viewModel.isNearestStop
        labelDistance.text = viewModel.distanceFromUser
    }
    
}
