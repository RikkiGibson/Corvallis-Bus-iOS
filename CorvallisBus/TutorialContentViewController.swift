//
//  TutorialContentViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/6/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

struct TutorialViewModel {
    let title: String
    let image: UIImage
}

class TutorialContentViewController : UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var viewModel: TutorialViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let viewModel = viewModel {
            configure(viewModel)
        }
    }
    
    func configure(viewModel: TutorialViewModel) {
        titleLabel.text = viewModel.title
        imageView.image = viewModel.image
    }
}
