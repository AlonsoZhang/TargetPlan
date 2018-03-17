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
    case help = "h"
    case unknown
    
    init(value: String) {
        switch value {
        case "l": self = .locallog
        case "t": self = .temperlog
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
                    let paths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true) as NSArray
                    let vaultPath = "/vault/data_collection/test_station_config/gh_station_info.json";
                    var stationtype = "station"
                    if manager.fileExists(atPath: vaultPath){
                        do {
                            let vaultstring = try String.init(contentsOf: URL(fileURLWithPath:vaultPath), encoding: String.Encoding.utf8)
                            stationtype = findStringInString(str: vaultstring, pattern: "(?<=\"STATION_ID\" : \").*(?=\")")
                        } catch {
                            print(error)
                        }
                    }
                    var targetfolder = "\(paths[0])/\(stationtype)-\(starttime)-\(overtime)"
                    var tarfile = ""
                    if logdateformat == "None"{
                        targetfolder = "\(paths[0])/\(stationtype)"
                        for logpath in enumeratorAtPath! {
                            var newlogpath = logpath as! String
                            newlogpath = newlogpath.replacingOccurrences(of: ":", with: "\\:")
                            newlogpath = newlogpath.replacingOccurrences(of: " ", with: "\\ ")
                            tarfile.append(" \(newlogpath)")
                        }
                    }else{
                        for logpath in enumeratorAtPath! {
                            if (logpath as! String).contains(".zip"){
                                let datereg = findStringInString(str: (logpath as! String), pattern: logdateformat)
                                if datereg.count > 0{
                                    if judgeintime(target: datereg, start: starttime, end: overtime)
                                    {
                                        var newlogpath = logpath as! String
                                        newlogpath = newlogpath.replacingOccurrences(of: ":", with: "\\:")
                                        newlogpath = newlogpath.replacingOccurrences(of: " ", with: "\\ ")
                                        tarfile.append(" \(newlogpath)")
                                    }
                                }
                            }
                        }
                    }
                    
                    if tarfile.count > 0{
                        createFile(name:"long.sh", fileBaseUrl: URL(fileURLWithPath: paths[0] as! String))
                        let longfilePath = "\(paths[0])/long.sh"
                        tarfile = "cd \(tmpdir);tar -cvf \(targetfolder).tar \(tarfile)"
                        try! tarfile.write(toFile: longfilePath, atomically: true, encoding: String.Encoding.utf8)
                        run(cmd: "sh \(longfilePath)")
                        run(cmd: "rm \(longfilePath)")
                        consoleIO.writeMessage("\(targetfolder).tar")
                        //let aaa = run(cmd: "cd \(tmpdir);tar -cvf \(targetfolder).tar \(tarfile)")
                    }else{
                        consoleIO.writeMessage("No file match regex or time rule")
                    }
                }
            }
        case .help:
            consoleIO.printUsage()
        case .unknown:
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
        if target.count == 23 {
            targetdateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        }else if target.count == 15 {
            targetdateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        }else{
            return false
        }
        
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
    
    func createFile(name:String, fileBaseUrl:URL){
        let manager = FileManager.default
        let file = fileBaseUrl.appendingPathComponent(name)
        let exist = manager.fileExists(atPath: file.path)
        if !exist {
            manager.createFile(atPath: file.path,contents:nil,attributes:nil)
        }
    }
}

