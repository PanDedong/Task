//
//  HttpbinPostTest.swift
//  Task-Example-iOS
//
//  Created by Panda on 2019/7/2.
//  Copyright © 2019 Panda. All rights reserved.
//

import Foundation
import Task

struct HttpbinPostTestParameters: Encodable {
	var query1: String
	var query2: String
	var query3: String
}

struct HttpbinPostTestResult: Decodable {
	var headers: Dictionary<String, String>
	var form: Dictionary<String, String>
	var origin: String
}

class HttpbinPostTestTask: Task<HttpbinPostTestParameters, HttpbinPostTestResult, URLRequestTask.Error> {
	
	override func main() throws {
		let requestParameters = URLRequestTask.Parameters (
			url: TEConstant.URLRequest.url("post"),
			body: .keyValue(pairs: parameters.toDictionary()!)
		)
		
		try URLRequestTask.syncExecute(requestParameters, parent: self, completion: { (childTask) in
			if let data = childTask.result?.data {
				try self.result = JSONDecoder().decode(ResultType.self, from: data)
			} else {
				throw URLRequestTask.Error(code: -1, description: "request faild", userInfo: nil)
			}
		})
	}
}
