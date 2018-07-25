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
    var resultDic = [String: Any]()
    var tempDic = [String:Any]()
    var includestr = ""
    var excludestr = ""
    var startstr = ""
    var endstr = ""
    var logformatstr = ""
    var finaltitle = ""
    func staticMode() {
        let argCount = CommandLine.argc
        let argument = CommandLine.arguments[1]
        let (option, value) = getOption(argument.substring(from: 1))
        switch option {
        case .locallog:
            if argCount == 5 {
                doPlan(mode: "local")
            }else if argCount == 6 {
                docsvPlan(mode: "local")
            }else{
                consoleIO.writeMessage("Wrong arguments for option \(option.rawValue)", to: .error)
            }
        case .temperlog:
            if argCount == 5 {
                doPlan(mode: "temper")
            }else if argCount == 6 {
                docsvPlan(mode: "temper")
            }else{
                consoleIO.writeMessage("Wrong arguments for option \(option.rawValue)", to: .error)
            }
        case .help:
            consoleIO.printUsage()
        case .unknown:
            consoleIO.writeMessage("Unknown option \(value)")
            consoleIO.printUsage()
        }
    }
    
    func doPlan(mode:String) {
        let logdateformat = CommandLine.arguments[2]
        let starttime = CommandLine.arguments[3]
        let overtime = CommandLine.arguments[4]
        var tmpdir = ""
        if mode == "temper" {
            tmpdir = findStringInString(str: run(cmd: "set"), pattern: "(?<=TMPDIR=).*")
        }else if mode == "local"{
            let Docpaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
            tmpdir = "\(Docpaths[0])/"
        }
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
//                for logpath in enumeratorAtPath! {
//                    var newlogpath = logpath as! String
//                    newlogpath = newlogpath.replacingOccurrences(of: ":", with: "\\:")
//                    newlogpath = newlogpath.replacingOccurrences(of: " ", with: "\\ ")
//                    tarfile.append(" \(newlogpath)")
//                }
                tarfile.append(" \(tmpdir)")
            }else{
                for logpath in enumeratorAtPath! {
                    //print(logpath)
                    if (mode == "temper" && (logpath as! String).contains(".zip")) || (mode == "local" ){
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
                tarfile = "cd \(tmpdir);tar -cvf \(targetfolder).tar /GH_Config/files/restoreinfo.txt \(tarfile) "
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
    
    func docsvPlan(mode:String) {
        let logdateformat = CommandLine.arguments[2]
        let starttime = CommandLine.arguments[3]
        let overtime = CommandLine.arguments[4]
        var tmpdir = ""
        if mode == "temper" {
            tmpdir = findStringInString(str: run(cmd: "set"), pattern: "(?<=TMPDIR=).*")
        }else if mode == "local"{
            let Docpaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
            tmpdir = "\(Docpaths[0])/"
        }
        if tmpdir.count > 0{
            let url = URL(fileURLWithPath: tmpdir)
            let manager = FileManager.default
            let enumeratorAtPath = manager.enumerator(atPath: url.path)
            let vaultPath = "/vault/data_collection/test_station_config/gh_station_info.json";
            var stationtype = "station"
            if manager.fileExists(atPath: vaultPath){
                do {
                    let vaultstring = try String.init(contentsOf: URL(fileURLWithPath:vaultPath), encoding: String.Encoding.utf8)
                    stationtype = findStringInString(str: vaultstring, pattern: "(?<=\"STATION_ID\" : \").*(?=\")")
                    let shortstationtype = findStringInString(str: vaultstring, pattern: "(?<=\"STATION_TYPE\" : \").*(?=\")")
                    let Downloadpaths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true) as NSArray
                    let manager = FileManager.default
                    let file = "\(Downloadpaths[0])/getLogData.plist"
                    if manager.fileExists(atPath: file) {
                        let GetlogdataPlist = NSDictionary(contentsOfFile: "\(Downloadpaths[0])/getLogData.plist") as! [String : Any]
                        let stationDic = GetlogdataPlist[shortstationtype] as! [String : Any]
                        includestr = stationDic["IncludeString"] as! String
                        excludestr = stationDic["ExcludeString"] as! String
                        startstr = stationDic["StartString"] as! String
                        endstr = stationDic["EndString"] as! String
                        logformatstr = stationDic["LogFormat"] as! String
                    }else{
                        consoleIO.writeMessage("getLogData.plist not exist", to: .error)
                    }
                } catch {
                    consoleIO.writeMessage("\(error as! String)", to: .error)
                }
            }
            finaltitle = "\(stationtype).\(starttime).\(overtime)"
            if logdateformat == "None"{
            }else{
                if self.checkformat() {
                    for logpath in enumeratorAtPath! {
                        if(mode == "local"){
                            let datereg = findStringInString(str: (logpath as! String), pattern: logdateformat)
                            if datereg.count > 0{
                                if judgeintime(target: datereg, start: starttime, end: overtime){
                                    let tmpData = NSData.init(contentsOfFile: "\(tmpdir)\(logpath)")
                                    if (tmpData != nil) {
                                        let content = String.init(data: tmpData! as Data, encoding: String.Encoding.utf8)
                                        if (content != nil) {
                                            self.dealwithlog(log: content!, path: logpath as! String)
                                        }else{
                                            //self.showmessage(inputString: "No string: \(logpath)")
                                        }
                                    }else{
                                        //self.showmessage(inputString: "\n========================================\nFolder: \(logpath)")
                                    }
                                }
                            }
                        }
                    }
                    if self.writelog() {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyyMMddHHmmss"
                        print("\(dateFormatter.string(from: Date())) Finish search and write log pass!")
                    }
                }
            }
        }
    }
    
    func checkformat() -> Bool {
        var result = true
        var startstring = startstr
        var endstring = endstr
        let startarr = startstring.components(separatedBy: "$")
        let endarr = endstring.components(separatedBy: "$")
        if startarr.count != endarr.count {
            consoleIO.writeMessage("Start string count (\(startarr.count)) ≠ End string count (\(endarr.count))", to: .error)
            result = false
        }
        for starteach in startarr {
            let starteacharr = starteach.components(separatedBy: "++")
            if starteacharr.count != 2{
                if starteach == "CheckUOP"{
                    startstring = startstring.replacingOccurrences(of: starteach, with: "SET SN++-25$Func Call : Check_UOP++-25", options: NSString.CompareOptions.caseInsensitive, range:nil)
                }else if starteach.contains("Item["){
                    let itemstr = self.findStringInString(str: starteach, pattern: "(?<=\\[).*?(?=\\])")
                    let itemnum = Int(itemstr) ?? 0
                    if itemnum != 0 {
                        if starteach.contains("Query") {
                            startstring = startstring.replacingOccurrences(of: starteach, with: "========== Start Test Item [\(String(describing: itemnum))]++-25$Func Call: AEQuerySFC++-25", options: NSString.CompareOptions.caseInsensitive, range:nil)
                        }else{
                            startstring = startstring.replacingOccurrences(of: starteach, with: "========== Start Test Item [\(String(describing: itemnum))]++-25$========== Start Test Item [\(String(describing: itemnum+1))]++-25", options: NSString.CompareOptions.caseInsensitive, range:nil)
                        }
                    }else{
                        consoleIO.writeMessage("Format item[] is wrong", to: .error)
                        result = false
                    }
                }else{
                    consoleIO.writeMessage("Start string ++ format is wrong", to: .error)
                    result = false
                }
            }
        }
        for endeach in endarr {
            let endeacharr = endeach.components(separatedBy: "++")
            if endeacharr.count != 2{
                if endeach == "CheckUOP"{
                    endstring = endstring.replacingOccurrences(of: endeach, with: "SET SN++-2$Func Call : Check_UOP++-2", options: NSString.CompareOptions.caseInsensitive, range:nil)
                }else if endeach.contains("Item["){
                    let itemstr = self.findStringInString(str: endeach, pattern: "(?<=\\[).*?(?=\\])")
                    let itemnum = Int(itemstr) ?? 0
                    if itemnum != 0 {
                        if endeach.contains("Query") {
                            endstring = endstring.replacingOccurrences(of: endeach, with: "========== Start Test Item [\(String(describing: itemnum))]++-2$Func Call: AEQuerySFC++-2", options: NSString.CompareOptions.caseInsensitive, range:nil)
                        }else{
                            endstring = endstring.replacingOccurrences(of: endeach, with: "========== Start Test Item [\(String(describing: itemnum))]++-2$========== Start Test Item [\(String(describing: itemnum+1))]++-2", options: NSString.CompareOptions.caseInsensitive, range:nil)
                        }
                    }else{
                        consoleIO.writeMessage("Format item[] is wrong", to: .error)
                        result = false
                    }
                }else{
                    consoleIO.writeMessage("End string ++ format is wrong", to: .error)
                    result = false
                }
            }
        }
        let newstartarr = startstring.components(separatedBy: "$")
        let newendarr = endstring.components(separatedBy: "$")
        if newstartarr.count != newendarr.count {
            consoleIO.writeMessage("Final Start string count (\(startarr.count)) ≠ End string count (\(endarr.count))", to: .error)
            result = false
        }
        
        var formatstring = logformatstr
        let formatarr = formatstring.components(separatedBy: "$")
        let titlearray = self.findArrayInString(str: formatstring , pattern: "(?<=\\().*?(?=\\))")
        if formatarr.count != titlearray.count {
            consoleIO.writeMessage("Logformat count (\(formatarr.count)) ≠ Title count (\(titlearray.count))", to: .error)
            result = false
        }
        formatstring = regexdealwith(string: formatstring, pattern: "\\(.*?\\)", dict: [:])
        if result {
            tempDic["FormatString"] = formatstring
            tempDic["StartString"] = startstring
            tempDic["EndString"] = endstring
            tempDic["TitleArray"] = titlearray
            //consoleIO.writeMessage("Final data:\nStartString: \(String(describing: tempDic["StartString"]!))\nEndString: \(String(describing: tempDic["EndString"]!))\nFormatString: \(String(describing: tempDic["FormatString"]!))\nTitleArray: \(String(describing: tempDic["TitleArray"]!))")
        }
        return result
    }
    
    func dealwithlog(log: String, path: String){
        let patharr: Array = path.components(separatedBy: "/")
        let logname = patharr[patharr.count - 1]
        let includearr = includestr.components(separatedBy: "$")
        for containstr in includearr {
            if log.contains(containstr)||includestr == "" {
                //print(logname)
            }else{
                consoleIO.writeMessage("Include out(\(containstr)):\(logname)")
                return
            }
        }
        let excludearr = excludestr.components(separatedBy: "$")
        for notcontainstr in excludearr {
            if log.contains(notcontainstr) {
                consoleIO.writeMessage("Exclude out(\(notcontainstr)):\(logname)")
                return
            }else{
                //print(logname)
            }
        }
        let startarr = startstr.components(separatedBy: "$")
        let endarr = endstr.components(separatedBy: "$")
        var middleDic = [String: Any]()
        var logstring = log
        for starteach in startarr.enumerated() {
            let starteacharr = starteach.1.components(separatedBy: "++")
            if let startrange = logstring.range(of: starteacharr[0]) {
                let startoffsetnum = (Int(starteacharr[1]) ?? Int("0"))!
                let finalstartrange = logstring.index(startoffsetnum >= 0 ? startrange.upperBound : startrange.lowerBound, offsetBy: startoffsetnum)
                let logstring2 = String(logstring[finalstartrange...])
                let endeacharr = endarr[starteach.0].components(separatedBy: "++")
                logstring = logstring2
                if let endrange = logstring2.range(of: endeacharr[0]) {
                    let endoffsetnum = (Int(endeacharr[1]) ?? Int("0"))!
                    let finalendrange = logstring2.index(endoffsetnum > 0 ? endrange.upperBound : endrange.lowerBound, offsetBy: endoffsetnum)
                    let keystring = String(logstring2[..<finalendrange])
                    //处理最后数据的展现形式
                    //                    if keystring.count > 0{
                    //                        keystring = self.findStringInString(str: keystring, pattern: "[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}")
                    //                    }
                    middleDic["\(starteach.0)"] = keystring
                }
            }
            resultDic[logname] = middleDic
        }
    }
    
    func writelog() -> Bool {
        var result = true
        let paths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true) as NSArray
        let formatstring = tempDic["FormatString"] as? String ?? ""
        var csvstring = "SN"
        var resultarray = [String]()
        for title in tempDic["TitleArray"] as? [String] ?? [String]() {
            csvstring.append(",\(title)")
        }
        csvstring.append("\n")
        let formatarr = formatstring.components(separatedBy: "$")
        for eachcsv in resultDic.keys {
            csvstring.append(eachcsv)
            var midstr = String()
            for eachformat in formatarr {
                let each = regexdealwith(string: eachformat, pattern: "\\[.*?\\]", dict: resultDic[eachcsv] as! [String:Any])
                let finaleach = calc(string: each)
                csvstring.append(",\(finaleach)")
                midstr.append(" \(finaleach)")
            }
            midstr = midstr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if midstr != "" {
                resultarray.append(midstr)
            }
            csvstring.append("\n")
        }
        let creatfile = "\(paths[0])/\(finaltitle).csv"
        do {
            try csvstring.write(toFile: creatfile, atomically: true, encoding: String.Encoding.utf8)
        } catch  {
            consoleIO.writeMessage( "Error to write csv", to: .error)
            result = false
        }
        if result {
            consoleIO.writeMessage("\(paths[0])/\(finaltitle).csv")
        }
        return result
    }
    
    func regexdealwith(string:String, pattern:String, dict:[String:Any]) -> String
    {
        var result = ""
        let resultArray = self.findArrayInString(str: string , pattern: pattern)
        var tmpString = string
        for str in resultArray
        {
            var tmpStr = str
            tmpStr.remove(at: tmpStr.startIndex)
            tmpStr.remove(at: tmpStr.index(before: tmpStr.endIndex))
            if let value = dict[tmpStr]
            {
                tmpString = tmpString.replacingOccurrences(of: str, with: value as! String)
            }else
            {
                tmpString = tmpString.replacingOccurrences(of: str, with: "")
            }
        }
        result.append(tmpString)
        result = result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return result
    }
    
    func calc(string:String) -> String {
        var finalstring = string
        if string.contains("to") {
            let stringarr = string.components(separatedBy: "to")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            var timeNumber = Double()
            let regexstr = "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}$"
            if stringarr[0] =~ regexstr && stringarr[1] =~ regexstr {
                timeNumber = dateFormatter.date(from: "\(stringarr[1])" )!.timeIntervalSince1970-dateFormatter.date(from: "\(stringarr[0])" )!.timeIntervalSince1970
                finalstring = String(format: "%.3f",timeNumber)
            }else{
                if stringarr[0] =~ regexstr || stringarr[1] =~ regexstr {
                    finalstring = ""
                    if stringarr[0] != "" && stringarr[1] != "" {
                        consoleIO.writeMessage("Date format is error.\(stringarr[0]) to \(stringarr[1])", to: .error)
                    }
                }else if string == "to"{
                    finalstring = ""
                }
            }
        }
        return finalstring
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
        }else if target.count == 19 {
            targetdateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
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

import Foundation
struct MyRegex {
    let regex: NSRegularExpression?
    init(_ pattern: String) {
        regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }
    
    func match(input: String) -> Bool {
        if let matches = regex?.matches(in: input,options: [],range: NSMakeRange(0, (input as NSString).length)) {
            return matches.count > 0
        }
        else {
            return false
        }
    }
}

precedencegroup ComparisonPrecedence{
    associativity: none
    higherThan: LogicalConjunctionPrecedence
}
infix operator =~ : ComparisonPrecedence

func =~ (lhs: String, rhs: String) -> Bool {
    return MyRegex(rhs).match(input: lhs)
}
