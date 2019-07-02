//
//  TETools.swift
//  Task-Example-iOS
//
//  Created by Panda on 2019/7/2.
//  Copyright © 2019 Panda. All rights reserved.
//

import Foundation

extension Encodable {
	func toDictionary() -> Dictionary<String, CustomStringConvertible>? {
		guard let data = try? JSONEncoder().encode(self) else { return nil }
		return data.toDictionary()
	}
	func toJSONString() -> String? {
		guard let data = try? JSONEncoder().encode(self) else { return nil }
		return String.init(data: data, encoding: .utf8)
	}
}

extension Data {
	func toDictionary() -> Dictionary<String, CustomStringConvertible>? {
		guard let obj = try? JSONSerialization.jsonObject(with: self, options: .mutableContainers), let jsonAny = obj as? [String: Any] else { return nil }
		return (jsonAny as? Dictionary<String, CustomStringConvertible>)
	}
}
