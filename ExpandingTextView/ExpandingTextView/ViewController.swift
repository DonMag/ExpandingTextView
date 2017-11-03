//
//  ViewController.swift
//  ExpandingTextView
//
//  Created by Don Mag on 11/3/17.
//  Copyright © 2017 DonMag. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	@IBOutlet weak var theStackView: UIStackView!
	
	@IBOutlet weak var theTopView: UILabel!
	@IBOutlet weak var theTextView: UITextView!
	@IBOutlet weak var theBottomView: UILabel!
	
	private var observerContext = 0
	private var isInsideObserver: Bool = false
	private var isKeyboardShowing: Bool = false
	private var elementsHeight: CGFloat = 0.0

	// this will be set / updated each time the keyboard is shown
	private var maxTextViewHeight: CGFloat = 240.0;
	
	// this is a less-than-or-equal-to constraint - updated when the keyboard is shown
	@IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
	
	
	let rightButtonItem = UIBarButtonItem.init(
		title: "Done",
		style: .done,
		target: self,
		action: #selector(rightButtonAction(sender:))
	)
	
	func rightButtonAction(sender: UIBarButtonItem) {
		theTextView.resignFirstResponder()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// generate 7 lines of text to pre-fill the text view
		var s = ""
		for i in 1...16 {
			s += "\(i)\n"
		}
		s += "end of text"
		
		theTextView.text = s
		
		// setup the keyboard show/hide notifications
		setupKeyboardHandlers()
		
		// start observing changes to the text view's contentSize
		theTextView.addObserver(self, forKeyPath: "contentSize", options: [.new, .old], context: &observerContext)
		
		if self.navigationController != nil {
			self.navigationItem.rightBarButtonItem = rightButtonItem
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if !isKeyboardShowing {
			if let window = self.view.window?.frame {
				elementsHeight = 0
				
				// add top view's height
				elementsHeight += theTopView.frame.height
				
				// add bottom view's height
				elementsHeight += theBottomView.frame.height
				
				// add stack view's Y offset
				elementsHeight += theStackView.frame.origin.y
				
				// 3 views in the stack view, so add 2 x Spacing
				elementsHeight += theStackView.spacing * 2
				
				// add stack view's Spacing again, for some "padding" below the bottom view
				elementsHeight += theStackView.spacing
				
				// subtract keyboard height + otherSpace from window height to get max text view height before scrolling
				maxTextViewHeight = window.height - elementsHeight
				
				// update the text view's height constraint
				textViewHeightConstraint.constant = maxTextViewHeight
				theTextView.setNeedsUpdateConstraints()
			}
		}
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard context == &observerContext else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			return
		}
		
		if (object as? UITextView) == self.theTextView {
			
			// prevent recursion
			if !isInsideObserver {
				
				isInsideObserver = true
				
				if let newSize = change?[.newKey] as? CGSize {
					
					// set scroll enabled:
					//		true if content is taller than text view max height
					//		false if shorter
					theTextView.isScrollEnabled = newSize.height >= maxTextViewHeight

					// because we are changing isScrollEnabled *after* the contentSize has changed,
					// this will trigger another auto-layout pass to update the frame
					theTextView.setNeedsUpdateConstraints()
				}
				
			}
			
			isInsideObserver = false
			
		}
		
	}
	
	
	
	func setupKeyboardHandlers() {
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(kbWillShow(notification:)),
		                                       name: Notification.Name.UIKeyboardWillShow,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(kbWillHide(notification:)),
		                                       name: Notification.Name.UIKeyboardWillHide,
		                                       object: nil)
	}
	
	func kbWillShow(notification: Notification) {
		isKeyboardShowing = true
		
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
			let window = self.view.window?.frame {
			
			elementsHeight = 0
			
			// add top view's height
			elementsHeight += theTopView.frame.height
			
			// add bottom view's height
			elementsHeight += theBottomView.frame.height
			
			// add stack view's Y offset
			elementsHeight += theStackView.frame.origin.y
			
			// 3 views in the stack view, so add 2 x Spacing
			elementsHeight += theStackView.spacing * 2
			
			// add stack view's Spacing again, for some "padding" below the bottom view
			elementsHeight += theStackView.spacing
			
			// subtract keyboard height + otherSpace from window height to get max text view height before scrolling
			maxTextViewHeight = window.height - (keyboardSize.height + elementsHeight)
			
			// update the text view's height constraint
			textViewHeightConstraint.constant = maxTextViewHeight
			
			// this will trigger another auto-layout pass to update the frame
			theTextView.setNeedsUpdateConstraints()

		}
	}
	
	func kbWillHide(notification: Notification) {
		isKeyboardShowing = false
	}
}
