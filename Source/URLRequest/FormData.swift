//
//  RequestFormData.swift
//  
//
//  Created by Panda on 2019/1/7.
//  Copyright © 2019 Panda. All rights reserved.
//

import Foundation

public enum FormData: Comparable {
	case KeyValue(name: String, value: String)
	case FormData(name: String, fileName: String, contentType: String, data: Data)
	
	public static func < (lhs: FormData, rhs: FormData) -> Bool {
		switch (lhs, rhs) {
		case (.KeyValue(_, _), _):
			return true
		default:
			return false
		}
	}
	
	public func utf8Data(with boundary: String) -> Data {
		var utf8Data = Data()
		switch self {
		case let .KeyValue(name, value):
			utf8Data.append("--\(boundary)\r\n".data(using: .utf8)!)
			utf8Data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
			utf8Data.append((value + "\r\n").data(using: .utf8)!)
		case let .FormData(name, fileName, contentType, data):
			utf8Data.append("--\(boundary)\r\n".data(using: .utf8)!)
			utf8Data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
			utf8Data.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
			utf8Data.append(data + "\r\n".data(using: .utf8)!)
		}
		return utf8Data
	}
}

extension Array where Element == FormData {
	public func mutipartFormData(_ boundary: String) -> Data {
		if self.count == 0 { return Data() }

		var formData = self.sorted().reduce(Data(), { $0 + $1.utf8Data(with: boundary) })
		formData.append("--\(boundary)--".data(using: .utf8)!)
		return formData
	}
}
