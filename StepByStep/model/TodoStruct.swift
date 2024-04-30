//
//  TodoStruct.swift
//  StepByStep
//
//  Created by Yune gim on 2023/05/08.
//

//import Foundation
//create table IF NOT EXISTS TodoItem(name TEXT, discription TEXT, date Text, start_time TEXT, end_time TEXT, oneOff TEXT)

struct Todos : Codable{
    var todo : [TodoItem]
}

struct TodoItem: Codable {
    var todo_name : String
    var todo_disc : String
    var start_date : String
    var end_date : String
}
