//
//  MKAnnotationViewExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 6/12/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import Foundation
import MapKit

let greenOvalImage = NSImage(named: "greenoval")
let greenOvalHighlightedImage = NSImage(named: "greenoval-highlighted")
let greenOvalDeemphasizedImage = NSImage(named: "greenoval-deemphasized")
let goldOvalImage = NSImage(named: "goldoval")
let goldOvalHighlightedImage = NSImage(named: "goldoval-highlighted")
let goldOvalDeemphasizedImage = NSImage(named: "goldoval-deemphasized")

let arrowImage = NSImage(named: "ListCurrentLoc")

extension MKAnnotationView {
    func update(with busStopAnnotation: BusStopAnnotation, isSelected: Bool) {
        let isFavorite = busStopAnnotation.isFavorite
        let isDeemphasized = busStopAnnotation.isDeemphasized
        if isSelected {
            layer!.zPosition = 5
            image = isFavorite ? goldOvalHighlightedImage : greenOvalHighlightedImage
        } else if isDeemphasized {
            layer!.zPosition = isFavorite ? 2 : 1
            image = isFavorite ? goldOvalDeemphasizedImage : greenOvalDeemphasizedImage
        } else {
            layer!.zPosition = isFavorite ? 4 : 3
            image = isFavorite ? goldOvalImage : greenOvalImage
        }
    }
}
