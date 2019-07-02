//
//  UserInfoTask.swift
//  Task-Example-iOS
//
//  Created by Panda on 2019/7/2.
//  Copyright © 2019 Panda. All rights reserved.
//

import Foundation

class UserInfoTask: TEURLRequestTask<UserInfoTask.Parameters, UserInfoTask.Result> {
	struct Parameters: TEURLRequestParameters {
		struct PostParameters: Codable {
			var token: String
		}
		
		var postParameters: PostParameters?
		
		func urlPath() -> String {
			return "/user/userinfo"
		}
	}
	
	struct Result: Decodable {
		var name: String
		var age: String
		var phone: String
	}
}
