//
//  FavoritesPlaceholder.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 12/22/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import UIKit

final class FavoritesPlaceholder : UIView {
    var handler: (() -> Void)?
    @IBAction func runHandler(_ sender: Any) {
        if let handler = handler {
            handler()
        } else {
            fatalError("No button press handler attached to favorites placeholder")
        }
    }
}
