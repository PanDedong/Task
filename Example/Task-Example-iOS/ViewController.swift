//
//  ViewController.swift
//  Task-Example-iOS
//
//  Created by Panda on 2019/7/1.
//  Copyright © 2019 Panda. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let detailViewController = segue.destination as? DetailViewController
		{
			switch segue.identifier! {
			case "httpbin":
				detailViewController.segueIdentifier = "httpbin"
			case "simulation":
				detailViewController.segueIdentifier = "simulation"
			default:
				break
			}
		}
	}
}

