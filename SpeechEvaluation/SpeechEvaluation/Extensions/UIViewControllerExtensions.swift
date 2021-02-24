//
//  UIViewControllerExtensions.swift
//

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIViewController {
    func showAlertOnWindow(title: String? = nil, message: String? = nil, titles: [String] = ["OK"], completionHanlder: ((_ title: String) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title ?? "", message: message, preferredStyle: UIAlertController.Style.alert)
        for title in titles {
            alert.addAction(UIAlertAction(title: title, style: UIAlertAction.Style.default, handler: { (action) in
                completionHanlder?(title)
            }))
        }
        present(alert, animated: true, completion: nil)
    }
}

extension UIViewController {
    
    func showToast(message : String, font: UIFont, color: UIColor) {
        
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 100, y: self.view.frame.size.height / 2, width: 200, height: 35))
        toastLabel.backgroundColor = color//UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 2.0, delay: 0.2, options: .curveEaseIn, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
//    func showToast(message : String, font: UIFont, color: UIColor) {
//        
//        
//        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 100, y: self.view.frame.size.height-50, width: 200, height: 35))
//        toastLabel.backgroundColor = color//UIColor.black.withAlphaComponent(0.6)
//        toastLabel.textColor = UIColor.white
//        toastLabel.font = font
//        toastLabel.textAlignment = .center;
//        toastLabel.text = message
//        toastLabel.alpha = 1.0
//        toastLabel.layer.cornerRadius = 10;
//        toastLabel.clipsToBounds  =  true
//        
//        let transform = CGAffineTransform(translationX: 0, y: toastLabel.frame.height + 15)
//        toastLabel.alpha = 1.0
//        toastLabel.transform = transform
//        
//        self.view.addSubview(toastLabel)
//        
//        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseIn, animations: {
//            toastLabel.alpha = 0.0
//            toastLabel.transform = .identity
//        }, completion: {(isCompleted) in
//            toastLabel.removeFromSuperview()
//        })
//        
//        //        UIView.animate(withDuration: 2.0, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .curveLinear, animations: {
//        //
//        //            toastLabel.alpha = 0.0
//        //            toastLabel.transform = .identity
//        //        }, completion: {(completion) in
//        //            toastLabel.removeFromSuperview()
//        //        })
//        
//    }
    

    // Screen width.
    public var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    // Screen height.
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    
    func addChildViewControllerWithView(_ childViewController: UIViewController, toView view: UIView? = nil) {
      let view: UIView = view ?? self.view
      childViewController.removeFromParent()
      childViewController.willMove(toParent: self)
      addChild(childViewController)
      childViewController.didMove(toParent: self)
      childViewController.view.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(childViewController.view)
      view.addConstraints([
        NSLayoutConstraint(item: childViewController.view!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: childViewController.view!, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: childViewController.view!, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: childViewController.view!, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
      ])
      view.layoutIfNeeded()
    }
    
    func addChildPageViewControllerWithView(_ childViewController: UIViewController, toView view: UIView? = nil) {
      let view: UIView = view ?? self.view
      childViewController.removeFromParent()
      childViewController.willMove(toParent: self)
      addChild(childViewController)
      childViewController.didMove(toParent: self)
      childViewController.view.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(childViewController.view)
      view.addConstraints([
        NSLayoutConstraint(item: childViewController.view!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 80),
        NSLayoutConstraint(item: childViewController.view!, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: childViewController.view!, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: childViewController.view!, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
      ])
      view.layoutIfNeeded()
    }
    
    func removeChildViewController(_ childViewController: UIViewController) {
      childViewController.removeFromParent()
      childViewController.willMove(toParent: nil)
      childViewController.removeFromParent()
      childViewController.didMove(toParent: nil)
      childViewController.view.removeFromSuperview()
      view.layoutIfNeeded()
    }

}
