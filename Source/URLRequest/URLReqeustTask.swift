//
//  URLReqeustTask.swift
//  Task
//
//  Created by Panda on 2019/7/1.
//  Copyright © 2019 Panda. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == CustomStringConvertible {
	public func URLEncode() -> String {
		var paramsArray = Array<String>()
		self.forEach { (key, value) in
			let kv = (key.URLEncode() ?? "") + "=" + (value.description.URLEncode() ?? "")
			paramsArray.append(kv)
		}
		return paramsArray.joined(separator: "&")
	}
}

extension String {
	public func URLEncode() -> String? {
		return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.init(charactersIn: "!*'();:@&=+$,/?%#[]~").inverted)
	}
	
	public func URLString(with urlParams: Dictionary<String, CustomStringConvertible>?) -> String {
		guard let params = urlParams, !params.isEmpty else { return self }
		let joinFlag = self.contains("?") ? "&" : "?"
		return self + joinFlag + params.URLEncode()
	}
}

public class URLRequestTask: Task<URLRequestTask.Parameters, URLRequestTask.Result, URLRequestTask.Error> {
	public struct Parameters {
		public enum HttpBody {
			case keyValue(pairs: Dictionary<String, CustomStringConvertible>)
			case multipart(formData: Array<FormData>)
			case custom(body: Data, contentType: String)
		}
		
		public var url: String
		public var headers: Dictionary<String, CustomStringConvertible>?
		public var getParameters: Dictionary<String, CustomStringConvertible>?
		public var body: HttpBody?
		
		public init(url: String, headers: Dictionary<String, CustomStringConvertible>? = nil, getParameters: Dictionary<String, CustomStringConvertible>? = nil, body: HttpBody? = nil) {
			self.url = url
			self.headers = headers
			self.getParameters = getParameters
			self.body = body
		}
		
		public func buildRequest() -> URLRequest? {
			guard let url = URL(string: url.URLString(with: getParameters)) else {
				return nil
			}
			var urlRequest = URLRequest(url: url)
			urlRequest.allHTTPHeaderFields = headers?.mapValues({ $0.description })
			urlRequest.httpMethod = (body != nil) ? "post" : "get"
			
			switch body {
			case let .keyValue(pairs)?:
				urlRequest.httpBody = pairs.URLEncode().data(using: String.Encoding.utf8)
			case let .multipart(formData)?:
				let boundary = "D3JKIOU8743NMNFQWERTYUIO12345678BNM"
				urlRequest.httpBody = formData.mutipartFormData(boundary)
				urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
				urlRequest.setValue(String(formData.count), forHTTPHeaderField: "Content-Length")
			case let .custom(body, contentType)?:
				urlRequest.httpBody = body
				urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
			case .none: break
			}
			
			return urlRequest
		}
	}
	
	public struct Result {
		public var data: Data?
		public var URLResponse: HTTPURLResponse?
		public var error: Swift.Error?
	}
	
	public struct Error: TaskError {
		public var code: Int
		public var description: String
		public var userInfo: Dictionary<AnyHashable, Any>?
		public init(code: Int, description: String, userInfo: Dictionary<AnyHashable, Any>?) {
			self.code = code
			self.description = description
			self.userInfo = userInfo
		}
	}
	
	private var urlRequest: URLRequest?
	private var urlSessionTask: URLSessionTask?
	
	required init(_ parameters: Parameters) {
		super.init(parameters)
		urlRequest = parameters.buildRequest()
		urlRequest?.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
		urlRequest?.timeoutInterval = 18
	}
	
	override public func main() throws {
		guard let urlRequest = urlRequest else {
			throw Error(code: -1, description: "invaild url", userInfo: nil)
		}
		
		let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
		urlSessionTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
			self.result = Result(data: data, URLResponse: (response as? HTTPURLResponse), error: error)
			semaphore.signal()
		}
		urlSessionTask?.resume()
		 let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
		
		#if DEBUG
		print("""
			====================RequestTask====================
			url:\(String(describing: self.parameters.url))\n
			getParameters:\(String(describing: self.parameters.getParameters ?? [:]))\n
			postParameters:\(String(describing: self.parameters.body ?? Parameters.HttpBody.keyValue(pairs: [:])))\n
			---------------------
			error:\(String(describing: self.result?.error))\n
			urlResponse:\(String(describing: self.result?.URLResponse))\n
			data:\(String(describing: try? JSONSerialization.jsonObject(with: self.result?.data ?? Data(), options: [])))\n
			===================================================
			""")
		#endif
	}
	
	override public func wantCancel() {
		super.wantCancel()
		urlSessionTask?.cancel()
		#if DEBUG
		print("task canceled")
		#endif
	}
}
