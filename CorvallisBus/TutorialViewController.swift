//
//  TutorialViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/6/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

class TutorialViewController : UIViewController, UIPageViewControllerDataSource {
    let viewModels = [TutorialViewModel(title: "foo", image: UIImage(named: "ListCurrentLoc")!), TutorialViewModel(title: "bar", image: UIImage(named: "goldoval")!)]
    var viewControllers = [TutorialContentViewController]()
    var pageViewController: UIPageViewController!
    
    override func viewDidLoad() {
        pageViewController = storyboard!.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
        pageViewController!.dataSource = self
        
        viewControllers = viewModels.map{ viewModel in
            let contentViewController = storyboard!.instantiateViewControllerWithIdentifier("TutorialContentViewController") as! TutorialContentViewController
            contentViewController.viewModel = viewModel
            return contentViewController
        }
        
        pageViewController.setViewControllers([viewControllers[0]], direction: .Forward, animated: true, completion: nil)
        
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMoveToParentViewController(self)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let contentController = viewController as? TutorialContentViewController,
            let index = viewControllers.indexOf(contentController) where index < viewControllers.count-1 else {
                return nil
        }
        return viewControllers[index + 1]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let contentController = viewController as? TutorialContentViewController,
            let index = viewControllers.indexOf(contentController) where index > 0 else {
                return nil
        }
        return viewControllers[index - 1]
    }
    
    @IBAction func done() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}