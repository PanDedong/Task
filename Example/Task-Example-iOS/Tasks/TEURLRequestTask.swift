//
//  TEURLRequestTask.swift
//  Task-Example-iOS
//
//  Created by Panda on 2019/7/2.
//  Copyright © 2019 Panda. All rights reserved.
//

import Foundation
import Task

protocol TEURLRequestParameters {
	associatedtype PostParametersType: Encodable
	func urlPath() -> String
	var postParameters: PostParametersType? { get }
}

// {"errno": 0, "errmsg": "", "data": {} }
struct TEURLRequestResult<DataType: Decodable>: Decodable {
	var errmsg: String
	var errno: Int
	var data: DataType?
}

class TEURLRequestTask<P: TEURLRequestParameters, R: Decodable>: Task<P, TEURLRequestResult<R>, URLRequestTask.Error> {
	
	func postParameters() -> [String: CustomStringConvertible] {
		var postParameters = TEConstant.URLRequest.commonParameters()
		postParameters = postParameters.merging(parameters.postParameters.toDictionary() ?? [:]){(_, new) in new}
		return postParameters
	}
	
	override func main() throws {
		/*
		let parameters = URLRequestTask.Parameters (
			url: TEConstant.URLRequest.url(self.parameters.urlPath()),
			body: .keyValue(pairs: postParameters())
		)

		try URLRequestTask.syncExecute(parameters, parent: self, completion: { (childTask) in
			if let data = childTask.result?.data {
				try self.result = JSONDecoder().decode(ResultType.self, from: data)
			} else {
				throw URLRequestTask.Error(code: -1, description: "request faild", userInfo: nil)
			}
		})
		*/
		
		// Simulation
		sleep(3)
		let data = try Data.init(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "userinfo", ofType: "json")!, relativeTo: nil))
		self.result = try JSONDecoder().decode(ResultType.self, from: data)
	}
}
