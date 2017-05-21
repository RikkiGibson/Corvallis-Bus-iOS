//
//  MKAnnotationViewExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/24/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

let greenNeedleImage = UIImage(named: "green-needle")
let greenNeedleHighlightedImage = UIImage(named: "green-needle-highlighted")
let greenNeedleDeemphasizedImage = UIImage(named: "green-needle-deemphasized")
let goldNeedleImage = UIImage(named: "gold-needle")
let goldNeedleHighlightedImage = UIImage(named: "gold-needle-highlighted")
let goldNeedleDeemphasizedImage = UIImage(named: "gold-needle-deemphasized")

let arrowImage = UIImage(named: "ListCurrentLoc")

extension MKAnnotationView {
    func updateWithBusStopAnnotation(_ annotation: BusStopAnnotation, isSelected: Bool, animated: Bool) {
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        isEnabled = true
        
        let isFavorite = annotation.isFavorite
        let isDeemphasized = annotation.isDeemphasized
        if isSelected {
            layer.zPosition = 5
            image = isFavorite ? goldNeedleHighlightedImage : greenNeedleHighlightedImage
        } else if isDeemphasized {
            layer.zPosition = isFavorite ? 2 : 1
            image = isFavorite ? goldNeedleDeemphasizedImage : greenNeedleDeemphasizedImage
        } else {
            layer.zPosition = isFavorite ? 4 : 3
            image = isFavorite ? goldNeedleImage : greenNeedleImage
        }
        
        let newTransform = isSelected
            ? CGAffineTransform(rotationAngle: CGFloat(annotation.stop.bearing)).concatenating(CGAffineTransform(scaleX: 1.3, y: 1.3))
            : CGAffineTransform(rotationAngle: CGFloat(annotation.stop.bearing))
        if animated {
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = newTransform
            })
        } else {
            transform = newTransform
        }
    }
}
