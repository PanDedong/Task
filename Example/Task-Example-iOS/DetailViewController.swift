//
//  DetailViewController.swift
//  Task-Example-iOS
//
//  Created by Panda on 2019/7/2.
//  Copyright © 2019 Panda. All rights reserved.
//

import UIKit
import Task

class DetailViewController: UIViewController, TaskResponder {
	var taskContainer: TaskContainer?
	var segueIdentifier: String!
	
	@IBOutlet var requestResultTextView: UITextView!
	@IBOutlet var loadingIndicator: UIActivityIndicatorView!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		switch segueIdentifier {
		case "httpbin":
			httpbinPostTest()
		case "simulation":
			requestSimulation()
		default:
			break
		}
		
	}
	
	func requestSimulation() {
		loadingIndicator.startAnimating()
		UserInfoTask.asyncExecute(UserInfoTask.Parameters(postParameters: UserInfoTask.Parameters.PostParameters(token: "testToken"))) { [weak self] (task) in
			guard let strongSelf = self else {
				return
			}
			strongSelf.loadingIndicator.stopAnimating()
			if task.error != nil {
				strongSelf.requestResultTextView.text = task.error?.description ?? "request failed"
			} else {
				strongSelf.requestResultTextView.text = task.result.debugDescription
			}
		}
	}
	
	func httpbinPostTest() {
		let parameters = HttpbinPostTestParameters(query1: "value1", query2: "value2", query3: "value3")
		
		//		HttpbinPostTestTask.asyncExecute(parameters) { [weak self] (task) in
		//			self?.httpbinPostTestResponse(task: task)
		//		}
		
		// If you use this method, request would be cancel when viewController deinit.
		HttpbinPostTestTask.asyncExecute(
			parameters: parameters,
			responder: self,
			completion:DetailViewController.httpbinPostTestResponse)
		loadingIndicator.startAnimating()
	}
	
	func httpbinPostTestResponse(task: HttpbinPostTestTask) {
		loadingIndicator.stopAnimating()
		if task.error != nil {
			requestResultTextView.text = task.error?.description ?? "request failed"
		} else {
			requestResultTextView.text = task.result.debugDescription
		}
	}
}
