//
//  TutorialViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/6/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

class TutorialViewController : UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    let viewModels = [TutorialViewModel(image: UIImage(named: "tutorial1")!),
        TutorialViewModel(image: UIImage(named: "tutorial2")!),
        TutorialViewModel(image: UIImage(named: "tutorial3")!),
        TutorialViewModel(image: UIImage(named: "tutorial4")!),
        TutorialViewModel(image: UIImage(named: "tutorial5")!),
        TutorialViewModel(image: UIImage(named: "tutorial6")!)]
    
    var viewControllers = [TutorialContentViewController]()
    var pageViewController: UIPageViewController!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        viewControllers = viewModels.map{ viewModel in
            let contentViewController = storyboard!.instantiateViewControllerWithIdentifier("TutorialContentViewController") as! TutorialContentViewController
            contentViewController.viewModel = viewModel
            return contentViewController
        }
        pageControl.numberOfPages = viewControllers.count
        
        pageViewController = segue.destinationViewController as! UIPageViewController
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([viewControllers[0]], direction: .Forward, animated: true, completion: nil)
    }
    
    // MARK: UIPageViewControllerDataSource
    
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
    
    // MARK: UIPageViewControllerDelegate
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        pageControl.currentPage = viewControllers.indexOf(pendingViewControllers[0] as! TutorialContentViewController)!
    }
    
    @IBAction func onPageControlValueChanged(sender: UIPageControl) {
        let oldIndex = viewControllers.indexOf(pageViewController.viewControllers![0] as! TutorialContentViewController)!
        let direction: UIPageViewControllerNavigationDirection = oldIndex < sender.currentPage ? .Forward : .Reverse
        
        pageViewController.setViewControllers([viewControllers[sender.currentPage]], direction: direction, animated: true, completion: nil)
    }
    
    @IBAction func done() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}