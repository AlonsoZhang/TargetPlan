//
//  Panagram.swift
//  TargetPlan
//
//  Created by Alonso on 07/03/2018.
//  Copyright © 2018 Alonso. All rights reserved.
//

import Foundation

enum OptionType: String {
    case locallog = "l"
    case temperlog = "t"
    case palindrome = "p"
    case anagram = "a"
    case help = "h"
    case unknown
    
    init(value: String) {
        switch value {
        case "l": self = .locallog
        case "t": self = .temperlog
        case "a": self = .anagram
        case "p": self = .palindrome
        case "h": self = .help
        default: self = .unknown
        }
    }
}

extension String {
    public func substring(from index: Int) -> String {
        if self.count > index {
            let startIndex = self.index(self.startIndex, offsetBy: index)
            let subString = self[startIndex..<self.endIndex]
            return String(subString)
        } else {
            return self
        }
    }
}

class Panagram {
    let consoleIO = ConsoleIO()
    func staticMode() {
        let argCount = CommandLine.argc
        let argument = CommandLine.arguments[1]
        let (option, value) = getOption(argument.substring(from: 1))
        switch option {
        case .locallog:
           consoleIO.printUsage()
        case .temperlog:
            if argCount != 5 {
                if argCount > 5 {
                    consoleIO.writeMessage("Too many arguments for option \(option.rawValue)", to: .error)
                } else {
                    consoleIO.writeMessage("Too few arguments for option \(option.rawValue)", to: .error)
                }
                consoleIO.printUsage()
            }else {
                let logdateformat = CommandLine.arguments[2]
                let starttime = CommandLine.arguments[3]
                let overtime = CommandLine.arguments[4]
                let tmpdir = findStringInString(str: run(cmd: "set"), pattern: "(?<=TMPDIR=).*")
                if tmpdir.count > 0{
                    let url = URL(fileURLWithPath: tmpdir)
                    let manager = FileManager.default
                    let enumeratorAtPath = manager.enumerator(atPath: url.path)
                    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
                    let targetfolder = "\(paths[0])/\(starttime)-\(overtime)"
                    var mkdir = true
                    for logpath in enumeratorAtPath! {
                        if (logpath as! String).contains(".zip"){
                            let datereg = findStringInString(str: (logpath as! String), pattern: "\\d{8}-\\d{6}")
                            if datereg.count > 0{
//                                if judgeintime(target: datereg, start: starttime, end: overtime)
//                                {
//                                    //run(cmd: "cp \(tmpdir)\(logpath) \(targetfolder)")
//                                    print(logpath)
//                                }
                                print(logpath)
//                                run(cmd: "cp \(tmpdir)\(logpath) \(targetfolder)")
                                if mkdir{
                                    mkdir = false
                                    run(cmd: "mkdir \(targetfolder)")
                                }
                                
                                //print(logpath)
                            }
                        }
                    }
                }
            }
            
            
        case .anagram:
            //2
            if argCount != 4 {
                if argCount > 4 {
                    consoleIO.writeMessage("Too many arguments for option \(option.rawValue)", to: .error)
                } else {
                    consoleIO.writeMessage("Too few arguments for option \(option.rawValue)", to: .error)
                }
                consoleIO.printUsage()
            } else {
                //3
                let first = CommandLine.arguments[2]
                let second = CommandLine.arguments[3]
                
                if first.isAnagramOf(second) {
                    consoleIO.writeMessage("\(second) is an anagram of \(first)")
                } else {
                    consoleIO.writeMessage("\(second) is not an anagram of \(first)")
                }
            }
        case .palindrome:
            //4
            if argCount != 3 {
                if argCount > 3 {
                    consoleIO.writeMessage("Too many arguments for option \(option.rawValue)", to: .error)
                } else {
                    consoleIO.writeMessage("Too few arguments for option \(option.rawValue)", to: .error)
                }
                consoleIO.printUsage()
            } else {
                //5
                let s = CommandLine.arguments[2]
                let isPalindrome = s.isPalindrome()
                consoleIO.writeMessage("\(s) is \(isPalindrome ? "" : "not ")a palindrome")
            }
        //6
        case .help:
            consoleIO.printUsage()
        case .unknown:
            //7
            consoleIO.writeMessage("Unknown option \(value)")
            consoleIO.printUsage()
        }
    }
    
    func getOption(_ option: String) -> (option:OptionType, value: String) {
        return (OptionType(value: option), option)
    }
    
    var error: NSDictionary?
    @discardableResult
    func run(cmd:String) -> String {
        let des = NSAppleScript(source: "do shell script \"\(cmd)\"")!.executeAndReturnError(&error)
        if error != nil {
            return String(describing: error!)
        }
        if des.stringValue != nil {
            return des.stringValue!
        }else{
            return ""
        }
    }
    
    func judgeintime(target:String,start:String,end:String) -> Bool
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        let targetdateFormatter = DateFormatter()
        targetdateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        
        let afterstarttime = Int(targetdateFormatter.date(from:target)!.timeIntervalSince1970-dateFormatter.date(from:start)!.timeIntervalSince1970)
        let beforeendtime = Int(dateFormatter.date(from:end)!.timeIntervalSince1970-targetdateFormatter.date(from:target)!.timeIntervalSince1970)
        if afterstarttime > 0 && beforeendtime > 0 {
            return true
        }else{
            return false
        }
    }
    
    
    func findArrayInString(str:String , pattern:String ) -> [String]
    {
        do {
            var stringArray = [String]();
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res = regex.matches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.count))
            for checkingRes in res
            {
                let tmp = (str as NSString).substring(with: checkingRes.range)
                stringArray.append(tmp.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            }
            return stringArray
        }
        catch
        {
            consoleIO.writeMessage("findArrayInString Regex error", to: .error)
            return [String]()
        }
    }
    
    func findStringInString(str:String , pattern:String ) -> String
    {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res = regex.firstMatch(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.count))
            if let checkingRes = res
            {
                return ((str as NSString).substring(with: checkingRes.range)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            return ""
        }
        catch
        {
            consoleIO.writeMessage("findStringInString Regex error", to: .error)
            return ""
        }
    }
}
