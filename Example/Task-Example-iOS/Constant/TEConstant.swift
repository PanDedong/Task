//
//  TEConstant.swift
//  Task-Example-iOS
//
//  Created by Panda on 2019/7/2.
//  Copyright © 2019 Panda. All rights reserved.
//

import Foundation
import UIKit

struct TEConstant {
	struct URLRequest {
		static let host = "https://httpbin.org"
		
		static func commonParameters() -> [String : CustomStringConvertible] {
			return [
				"os": "iOS",
				"osv": UIDevice.current.systemVersion,
			]
		}
		
		static func url(_ path: String) -> String {
			let path = (path.first == "/") ? path : ("/" + path)
			return TEConstant.URLRequest.host + path
		}
	}
}
