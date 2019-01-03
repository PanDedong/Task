//
//  Task.swift
//  Task
//
//  Created by PanDedong on 2018/2/8.
//

import Foundation
import UIKit

open class Task<ParametersType, ResultType, ErrorType: TaskError>: TaskProtocol {
	public var runner: TaskRunner?
	
	public var parameters: ParametersType
	public var result: ResultType?
	public var error: ErrorType?
	
	public required init(_ parameters: ParametersType) {
		self.parameters = parameters
	}
	
	open func main() throws {}
	
	open func wantCancel() {
		self.runner?.childTasks.forEach({ $0.wantCancel() })
	}
	
	deinit {
		#if DEBUG
		print("\(self) deinit")
		#endif
	}
}

public protocol TaskProtocol: TaskRunnable {
	associatedtype ParametersType
	associatedtype ResultType
	associatedtype ErrorType: TaskError
	
	var parameters: ParametersType { get set }
	var result: ResultType? { get set }
	var error: ErrorType? { get set }
	
	init(_ parameters: ParametersType)
}

extension TaskProtocol {
	private func execute() throws {
		do {
			if self.runner?.isCanceled ?? false {
				throw TaskCancelError.init()
			}
			try self.main()
			self.asyncChildTaskCompletionNotify {}
		} catch {
			if let parentTask = self.runner?.parentTask {
				if parentTask.runner?.group != nil {
					self.error = (error as? Self.ErrorType) ?? Self.ErrorType.init(code: -1, description: "系统错误", userInfo: nil)
				} else {
					throw error
				}
				
			} else {
				self.error = (error as? Self.ErrorType) ?? Self.ErrorType.init(code: -1, description: "系统错误", userInfo: nil)
			}
		}
	}
	
	private static func task(_ parameters: ParametersType) -> Self {
		let task = Self.init(parameters)
		task.runner = TaskRunner.init()
		task.runner?.task = task
		return task
	}
	
	public static func addResponder<R: TaskResponder>(_ responder: R, completion: @escaping (R) -> (Self) -> ()) {
		TaskManager.addResponder(.init(taskType: "\(type(of: self))", responder: responder, completion: { [weak responder] (task) in
			guard let sResponder = responder else { return }
			completion(sResponder)(task as! Self)
		}))
	}
	
	public static func asyncExecute<R: TaskResponder>(parameters: Self.ParametersType, responder: R, completion: @escaping (R) -> (Self) -> ()) {
		let task = self.task(parameters)
		
		weak var responder = responder
		if responder?.taskContainer == nil { responder?.taskContainer = TaskContainer.init() }
		
		let responderContext = TaskRunContext.init(taskType: "\(type(of: type(of: task)))", task:  task, responder: responder) { [weak responder] (task) in
			guard let sResponder = responder else { return }
			completion(sResponder)(task as! Self)
		}
		
		responder?.taskContainer?.addTask(responderContext)
		
		
		DispatchQueue.global(qos: .default).async {
			try? task.execute()
			if task.runner?.isCanceled ?? false { return }
			DispatchQueue.main.async {
				responderContext.completion(task)
				TaskManager.defaultManager.managerQueue.async {
					responder?.taskContainer?.tasks.removeValue(forKey: responderContext.taskType)
				}
				TaskManager.response(for: task)
			}
		}
	}
	
	public static func asyncExecute(_ parameters: Self.ParametersType, completion: @escaping (Self) -> ()) {
		let task = self.task(parameters)
		
		DispatchQueue.global(qos: .default).async {
			try? task.execute()
			if task.runner?.isCanceled ?? false { return }
			DispatchQueue.main.async {
				completion(task)
				TaskManager.response(for: task)
			}
		}
	}
	
	public static func asyncExecute<T: TaskRunnable>(_ parameters: Self.ParametersType, parent: T, completion: @escaping (Self) -> ()) {
		let task = self.task(parameters)
		task.runner?.parentTask = parent
		parent.runner?.childTasks.append(task)
		if task.runner?.parentTask?.runner?.group == nil {
			task.runner?.parentTask?.runner?.group = DispatchGroup()
		}
		
		DispatchQueue.global().async(group: task.runner?.parentTask?.runner?.group) {
			try? task.execute()
			if task.runner?.isCanceled ?? false { return }
			completion(task)
		}
	}
	
	public func asyncChildTaskCompletionNotify(_ block: @escaping () -> ()) {
		if self.runner?.group == nil { return; }
		let semaphore = DispatchSemaphore.init(value: 0)
		self.runner?.group?.notify(queue: DispatchQueue.global(), work: DispatchWorkItem(block: {
			semaphore.signal()
		}))
		semaphore.wait()
		block()
		self.runner?.group = nil
	}
	
	public static func syncExecute<T: TaskRunnable>(_ parameters: Self.ParametersType, parent: T, completion: @escaping (Self) throws -> ()) throws {
		let task = self.task(parameters)
		task.runner?.parentTask = parent
		parent.runner?.childTasks.append(task)
		try task.execute()
		try completion(task)
	}
}

public protocol TaskError: Error {
	var code: Int { get }
	var description: String { get }
	var userInfo: Dictionary<AnyHashable, Any>? { get }
	
	init(code: Int, description: String, userInfo: Dictionary<AnyHashable, Any>?)
}

public struct TaskCancelError: Error {}

public protocol TaskRunnable: AnyObject {
	var runner: TaskRunner? { get set }
	
	func main() throws
	
	func wantCancel()
}

public class TaskRunner {
	fileprivate weak var parentTask: TaskRunnable?
	fileprivate var childTasks: [TaskRunnable] = []
	fileprivate var group: DispatchGroup?
	fileprivate var isCanceled: Bool = false {
		didSet {
			if isCanceled {
				self.task?.wantCancel()
			}
		}
	}
	
	fileprivate weak var task: TaskRunnable?
}

public protocol TaskResponder: AnyObject {
    var taskContainer: TaskContainer? { get set }
}

public class TaskContainer {
	fileprivate var tasks: [String: TaskRunContext] = [:]
	
	fileprivate func addTask(_ context: TaskRunContext) {
		TaskManager.defaultManager.managerQueue.sync {
			if let oldContext = self.tasks[context.taskType] { oldContext.task?.runner?.isCanceled = true }
			self.tasks[context.taskType] = context
		}
	}
	
	deinit {
		#if DEBUG
		print("TaskContainer deinit")
		#endif
		tasks.values.forEach { (taskRunContext) in
			taskRunContext.task?.runner?.isCanceled = true
		}
	}
}

private class TaskRunContext {
	weak var weakResponder: TaskResponder?
	var completion: (TaskRunnable) -> ()
	var taskType: String
	weak var task: TaskRunnable?
	init(taskType: String, task: TaskRunnable? = nil, responder: TaskResponder?, completion: @escaping (TaskRunnable) -> ()) {
		self.taskType = taskType
		self.weakResponder = responder
		self.completion = completion
		self.task = task
	}
}

private class TaskManager {
	static let defaultManager = TaskManager()
	var responderContexts: [String: [TaskRunContext]] = [:]
	var managerQueue = DispatchQueue.init(label: "TaskManagerQueue")
	
	static func addResponder(_ responder: TaskRunContext) {
		defaultManager.managerQueue.sync {
			var contexts = defaultManager.responderContexts[responder.taskType] ?? []
			contexts.append(responder)
			defaultManager.responderContexts[responder.taskType] = contexts
		}
	}
	
	static func response(for task: TaskRunnable) {
		defaultManager.managerQueue.sync {
			let contexts = defaultManager.responderContexts["\(type(of: type(of: task)))"] ?? []
			if contexts.count == 0 { return }
			contexts.forEach({ (responderContext) in
				guard responderContext.weakResponder != nil else { return }
				DispatchQueue.main.async {
					responderContext.completion(task)
				}
			})
		}
	}
}
