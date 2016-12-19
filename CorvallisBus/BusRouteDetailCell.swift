//
//  BusRouteDetailCell.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 12/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

final class BusRouteDetailCell: UITableViewCell {
    
    @IBOutlet weak var labelRouteName: BusRouteLabel!
    
    @IBOutlet weak var labelEstimate: UILabel!
    
    @IBOutlet weak var labelSchedule: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        labelRouteName.layer.cornerRadius = 8
        labelRouteName.clipsToBounds = true
    }
    
    func update(_ viewModel: RouteDetailViewModel) {
        labelRouteName.text = viewModel.routeName
        labelRouteName.backgroundColorActual = viewModel.routeColor
        labelEstimate.text = viewModel.arrivalsSummary
        labelSchedule.text = viewModel.scheduleSummary
    }
}
