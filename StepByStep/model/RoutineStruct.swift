//
//  Routines.swift
//  StepByStep
//
//  Created by Yune gim on 2023/05/07.
//

//import Foundation

struct Routines : Codable{
    var Routines : [Routine]
}

struct Routine : Codable{
    var routines : [RoutineItem]
    var day : String
}

struct RoutineItem: Codable {
    var itemName : String
    var itemDisc : String
    var start : String
    var end : String
}
