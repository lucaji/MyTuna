//
//  StuffLogger.swift
//  MyTuna
//
//  Created by Luca Cipressi on 02/01/2018.
//  Copyright (c) 2017-2021 Luca Cipressi - lucaji.github.io - lucaji@mail.ru . All rights reserved.
//

import Foundation

public class StuffLogger {
    
    public enum logLevel: Int {
        case info = 1
        case debug = 2
        case warn = 3
        case error = 4
        case fatal = 5
        case none = 6
        
        public func description() -> String {
            switch self {
            case .info:
                return "❓"
            case .debug:
                return "✳️"
            case .warn:
                return "⚠️"
            case .error:
                return "🚫"
            case .fatal:
                return "🆘"
            case .none:
                return ""
            }
        }
    }
    
    public static var minimumLogLevel: logLevel = .info
    
    public static func print<T>(_ object: T, _ level: logLevel = .debug, filename: String = #file, line: Int = #line, funcname: String = #function) {
        #if DEBUG
        if level.rawValue >= StuffLogger.minimumLogLevel.rawValue {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss:SSS"
            let process = ProcessInfo.processInfo
            let threadId = "?"
            let file = URL(string: filename)?.lastPathComponent ?? ""
            Swift.print("\(level.description()) .\(level) ⏱ \(dateFormatter.string(from: Foundation.Date())) 📱 \(process.processName) [\(process.processIdentifier):\(threadId)] 📂 \(file)(\(line)) ⚙️ \(funcname) ➡️ \(object)")
        }
        #endif
    }

    public static func println<T>(_ object: T, _ level: logLevel = .debug, filename: String = #file, line: Int = #line, funcname: String = #function) {
        #if DEBUG
        if level.rawValue >= StuffLogger.minimumLogLevel.rawValue {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss:SSS"
            let process = ProcessInfo.processInfo
            let threadId = "?"
            let file = URL(string: filename)?.lastPathComponent ?? ""
            Swift.print("\n\(level.description()) .\(level) ⏱ \(dateFormatter.string(from: Foundation.Date())) 📱 \(process.processName) [\(process.processIdentifier):\(threadId)] 📂 \(file)(\(line)) ⚙️ \(funcname) ➡️\r\t\(object)")
        }
        #endif
    }

}
