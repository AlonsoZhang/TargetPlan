//
//  main.swift
//  TargetPlan
//
//  Created by Alonso on 07/03/2018.
//  Copyright © 2018 Alonso. All rights reserved.
//

import Foundation

let panagram = Panagram()
if CommandLine.argc < 2 {
    //TODO: Handle interactive mode
} else {
    panagram.staticMode()
}
