//
//  MacUtils.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 6/11/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import Foundation

func parseColor(obj: AnyObject?) -> Color? {
    if let colorString = obj as? String where colorString.characters.count == 6 {
        var colorHex: UInt32 = 0
        NSScanner(string: colorString).scanHexInt(&colorHex)
        return Color(red: CGFloat(colorHex >> 16 & 0xFF) / 255.0,
                       green: CGFloat(colorHex >> 8 & 0xFF) / 255.0,
                       blue: CGFloat(colorHex & 0xFF) / 255.0, alpha: 1.0)
    } else {
        return nil
    }
}
