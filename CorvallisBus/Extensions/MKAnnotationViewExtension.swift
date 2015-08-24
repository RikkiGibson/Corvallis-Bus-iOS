//
//  MKAnnotationViewExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/24/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

let greenOvalImage = UIImage(named: "greenoval")
let greenOvalHighlightedImage = UIImage(named: "greenoval-highlighted")
let greenOvalDeemphasizedImage = UIImage(named: "greenoval-deemphasized")
let goldOvalImage = UIImage(named: "goldoval")
let goldOvalHighlightedImage = UIImage(named: "goldoval-highlighted")
let goldOvalDeemphasizedImage = UIImage(named: "goldoval-deemphasized")

extension MKAnnotationView {
    func updateWithBusStopAnnotation(annotation: BusStopAnnotation, isSelected: Bool) {
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.85)
        
        let isFavorite = annotation.isFavorite
        let isDeemphasized = annotation.isDeemphasized
        if isSelected {
            layer.zPosition = 5
            image = isFavorite ? goldOvalHighlightedImage : greenOvalHighlightedImage
        } else if isDeemphasized {
            layer.zPosition = isFavorite ? 2 : 1
            image = isFavorite ? goldOvalDeemphasizedImage : greenOvalDeemphasizedImage
        } else {
            layer.zPosition = isFavorite ? 4 : 3
            image = isFavorite ? goldOvalImage : greenOvalImage
        }
    }
}
