//
//  ConsoleIO.swift
//  TargetPlan
//
//  Created by Alonso on 07/03/2018.
//  Copyright © 2018 Alonso. All rights reserved.
//

import Foundation

enum OutputType {
    case error
    case standard
}

class ConsoleIO {
    func writeMessage(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print("\(message)")
        case .error:
            fputs("Error: \(message)\n", stderr)
        }
    }
    
    func printUsage() {
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        writeMessage("usage:")
        writeMessage("\(executableName) -t yyyyMMddHHmmss yyyyMMddHHmmss")
        writeMessage("or")
        writeMessage("\(executableName) -l yyyyMMdd yyyyMMdd")
        writeMessage("or")
        writeMessage("\(executableName) -h to show usage information")
    }
}
