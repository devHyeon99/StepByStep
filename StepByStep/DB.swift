//
//  DB.swift
//  StepByStep
//
//  Created by 엄현호 on 2023/05/14.
//

import Foundation
import UIKit
import FMDB

class DAO: NSObject {
    // #. 싱글턴 객체 정의
    struct staticInstance {
        static var instance: DAO?
    }
    // 1. FMDB 정의
    var database:FMDatabase!
    let fileManager:FileManager = FileManager.default
    
    //MARK:-
    //MARK:- #. 클래스 함수 생성
    class func shareInstance() ->(DAO) {
        if (staticInstance.instance == nil) {
            staticInstance.instance = DAO()
            staticInstance.instance?.initData()
        }
        
        return staticInstance.instance!
    }
    
    //MARK:-
    //MARK:- 1. 기본적인 데이터를 확인하고 생성한다.
    func initData() {
        // 1. doc 폴더 만들기.
        let documentsPath1 = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let logsPath = documentsPath1.appendingPathComponent("doc")
        print(logsPath!)
        do {
            try FileManager.default.createDirectory(atPath: logsPath!.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
        
        // 2. 해당 폴더에 sqlite 생성해주기.
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("doc/StepBystep.sqlite")
        
        // FMDB 쓸때 기존에 파일을 만들어서 생성한 다음에 오픈을 해주었는데,
        // 이렇게 만들지 않은 상태에서 URL 로 생성 하니
        // 없으면 자동으로 생성해서 열어주고
        // 있으면 있는거 열어줌.
        database = FMDatabase(url: fileURL)
    }
    
    func InsertUser(_ email : String, _ profile : String, _ name : String, _ mbti : String, _ level : String, _ exp : String){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        do {
            try database.executeUpdate("create table IF NOT EXISTS User(email text, profile text, name text, mbti text, level text, exp text)", values: nil)
            
            try database.executeUpdate("insert into User (email, profile, name, mbti, level, exp) values (?, ?, ?, ?, ?, ?)", values: [email, profile, name, mbti, level, exp])
            
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        print("유저 입력 완료")
        database.close()
    }
    func UpdateUser(_ email : String, _ level : String, _ exp : String){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        do {
            let updateQuery = "UPDATE User SET level = ?, exp = ? WHERE email = ?"
            try database.executeUpdate(updateQuery, values: [level, exp, email])
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        print("유저 업데이트 완료")
        database.close()
    }
    func GetUser(_ email: String) -> (String?, String?, String?) {
        guard database.open() else {
            print("Unable to open database")
            return (nil, nil, nil)
        }
        do {
            let rs = try database.executeQuery("SELECT * FROM User WHERE email = ?",  values: [email])
            var mbti: String?
            var level: String?
            var exp: String?
            
            while rs.next() {
                mbti = rs.string(forColumn: "mbti")
                level = rs.string(forColumn: "level")
                exp = rs.string(forColumn: "exp")
            }
            database.close()
            return (mbti, level, exp)
        } catch {
            print("Failed: \(error.localizedDescription)")
            database.close()
            return (nil, nil, nil)
        }
    }
    
    func InsertDiary(_ email : String, _ date : String, _ title : String, _ mood : String, _ content : String){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        do {
            try database.executeUpdate("create table IF NOT EXISTS Diary(email text, date text, title text, mood text, content text)", values: nil)
            
            try database.executeUpdate("insert into Diary (email, date, title, mood, content) values (?, ?, ?, ?, ?)", values: [email, date, title, mood, content])
            
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        print("유저 입력 완료")
        database.close()
    }
    func GetDiary(_ email: String) -> [(String, String, String, String)] {
        guard database.open() else {
            print("Unable to open database")
            return []
        }
        
        var records: [(String, String, String, String)] = []
        
        do {
            let rs = try database.executeQuery("SELECT * FROM Diary WHERE email = ?", values: [email])
            
            while rs.next() {
                if let date = rs.string(forColumn: "date"),
                   let title = rs.string(forColumn: "title"),
                   let mood = rs.string(forColumn: "mood"),
                   let content = rs.string(forColumn: "content") {
                    records.append((date, title, mood, content))
                }
            }
            database.close()
        } catch {
            print("Failed: \(error.localizedDescription)")
            database.close()
        }
        
        return records
    }
    func InsertChallange(_ email : String,_ title : String){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        do {
            try database.executeUpdate("create table IF NOT EXISTS Challange(email text, title text)", values: nil)
            
            try database.executeUpdate("insert into Challange (email, title) values (?, ?)", values: [email, title])
            
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        print("챌린지 입력 완료")
        database.close()
    }
    func deleteChallange(_ email: String, _ title: String) {
        guard database.open() else {
            print("Unable to open database")
            return
        }
        
        do {
            try database.executeUpdate("DELETE FROM Challange WHERE email = ? AND title = ?", values: [email, title])
        } catch {
            print("Failed to delete: \(error.localizedDescription)")
        }
        
        print("챌린지 삭제 완료")
        database.close()
    }
    func GetChallange(_ email: String) -> [String] {
        guard database.open() else {
            print("데이터베이스를 열 수 없습니다.")
            return []
        }
        var challangeList: [String] = []
        do {
            let rs = try database.executeQuery("SELECT * FROM Challange WHERE email = ?", values: [email])
            
            while rs.next() {
                if let title = rs.string(forColumn: "title") {
                    challangeList.append(title)
                }
            }
            database.close()
        } catch {
            print("오류 발생: \(error.localizedDescription)")
            database.close()
        }
        return challangeList
    }
    
    func InsertChallangeComplete(_ email : String,_ title : String, _ date : String){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        do {
            try database.executeUpdate("create table IF NOT EXISTS ChallangeComplete(email text, title text, date text)", values: nil)
            
            try database.executeUpdate("insert into ChallangeComplete (email, title, date) values (?, ?, ?)", values: [email, title, date])
            
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        print("챌린지 입력 완료")
        database.close()
    }
    func GetChallangeComplete(_ email: String) -> [(String, String)] {
        guard database.open() else {
            print("데이터베이스를 열 수 없습니다.")
            return []
        }
        var completeList: [(String, String)] = []
        do {
            let rs = try database.executeQuery("SELECT * FROM ChallangeComplete WHERE email = ?", values: [email])
            
            while rs.next() {
                if let title = rs.string(forColumn: "title"),
                   let date = rs.string(forColumn: "date"){
                    completeList.append((title, date))
                }
            }
            database.close()
        } catch {
            print("오류 발생: \(error.localizedDescription)")
            database.close()
        }
        
        return completeList
    }
    
    // 커뮤니티 관련 DB
    func getPostLikedStatus(_ postIndex: Int) -> Bool? {
        guard database.open() else {
            print("Unable to open database")
            return nil
        }
        
        var isLiked: Bool?
        
        do {
            let query = "SELECT isLiked FROM Post WHERE postIndex = ?"
            let resultSet = try database.executeQuery(query, values: [postIndex])
            
            if resultSet.next() {
                let isLikedValue = resultSet.int(forColumn: "isLiked")
                isLiked = isLikedValue == 1 ? true : false
            }
        } catch {
            print("Failed to fetch post liked status: \(error.localizedDescription)")
        }
        
        database.close()
        return isLiked
    }

    func updatePost(_ postIndex: Int, _ isLiked: Bool) {
        guard database.open() else {
            print("Unable to open database")
            return
        }
        
        do {
            try database.executeUpdate("CREATE TABLE IF NOT EXISTS Post (postIndex INTEGER PRIMARY KEY, isLiked INTEGER)", values: nil)
            
            let query = "SELECT COUNT(*) FROM Post WHERE postIndex = ?"
            let resultSet = try database.executeQuery(query, values: [postIndex])
            
            if resultSet.next(), resultSet.int(forColumnIndex: 0) > 0 {
                // 이미 엔트리가 있는 경우 업데이트
                try database.executeUpdate("UPDATE Post SET isLiked = ? WHERE postIndex = ?", values: [isLiked ? 1 : 0, postIndex])
            } else {
                // 엔트리가 없는 경우 새로 삽입
                try database.executeUpdate("INSERT INTO Post (postIndex, isLiked) VALUES (?, ?)", values: [postIndex, isLiked ? 1 : 0])
            }
        } catch {
            print("Failed to update post: \(error.localizedDescription)")
        }
        database.close()
    }
    
    func test_DB(){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        
        do {
            try database.executeUpdate("create table IF NOT EXISTS User(email text, name text, mbti text)", values: nil)
            // 입력시 사용될 녀석.
            //            try database.executeUpdate("insert into info (order_num, badge, date, plus_one, title) values (?, ?, ?, ?, ?)", values: ["1", true, "2012-05-31", true, "사귄날"])
            try database.executeUpdate("insert into User (email, profile, name, mbti) values (?, ?, ?)", values: ["jinung5@kakao.com", "profile","엄현호", "ENFP"])
            //
            let rs = try database.executeQuery("select * from User", values: nil)
            while rs.next() {
                let email = rs.string(forColumn: "email")
                let profile = rs.string(forColumn: "profile")
                let name = rs.string(forColumn: "name")
                let mbti = rs.string(forColumn: "mbti")
                
                print("================")
                print("email = \(email!)")
                print("profile = \(profile!)")
                print("name = \(name!)")
                print("mbti = \(mbti!)")
            }
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        database.close()
    }
    
    // 루틴, 투두 데이터 베이스 정보
    
    func insertRoutines(){
        
    }
    
    func insertRoutineItem(_ day : String, _ name : String, _ discription : String, _ start_time : String, _ end_time : String){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        do {
            //database.executeUpdate는 next필요없음
            //database.executeQuerys는 next필요함
            try database.executeUpdate("insert into RoutineItem (day, name, discription, date, start_time, end_time ) values (?, ?, ?, ?, ?, ?)", values: [day, name, discription, "test2", start_time, end_time ])
            
            //            let rs = try database.executeQuery("select * from RoutineItem", values: nil)
            //
            //            while rs.next() {
            //                let day = rs.string(forColumn: "day")
            //                let name = rs.string(forColumn:"name")
            //                let discription = rs.string(forColumn: "discription")
            //                let date = rs.string(forColumn: "date")
            //                let start_time = rs.string(forColumn: "start_time")
            //                let end_time = rs.string(forColumn: "end_time")
            //
            //                print("================")
            //                print("day = \(day!)")
            //                print("name = \(name!)")
            //                print("discription = \(discription!)")
            //                print("date = \(date!)")
            //                print("start_time = \(start_time!)")
            //                print("end_time = \(end_time!)")
            //            }
            
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        print("insert routine complete")
        database.close()
    }
    
    func insertTodoItem(_ name : String, _ discription : String, _ start_time : String, _ end_time : String){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        do {
            //database.executeUpdate는 next필요없음
            //database.executeQuerys는 next필요함
            try database.executeUpdate("insert into TodoItem(name, discription, date, start_time, end_time ) values (?, ?, ?, ?, ?)", values: [name, discription, "test2", start_time, end_time ])
            
            //            let rs = try database.executeQuery("select * from RoutineItem", values: nil)
            //
            //            while rs.next() {
            //                let day = rs.string(forColumn: "day")
            //                let name = rs.string(forColumn:"name")
            //                let discription = rs.string(forColumn: "discription")
            //                let date = rs.string(forColumn: "date")
            //                let start_time = rs.string(forColumn: "start_time")
            //                let end_time = rs.string(forColumn: "end_time")
            //
            //                print("================")
            //                print("day = \(day!)")
            //                print("name = \(name!)")
            //                print("discription = \(discription!)")
            //                print("date = \(date!)")
            //                print("start_time = \(start_time!)")
            //                print("end_time = \(end_time!)")
            //            }
            
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        print("insert routine complete")
        database.close()
    }
    
    func getRoutineItem(_ day : String, _ name : String, _ discription : String, _ start_time : String, _ end_time : String){
        
    }
    
    func updateRoutineItem(_ day : String, _ name : String, _ disc : String, _ nameRp : String, _ discRp : String, _ Start : String, _ End : String){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        do {
            //database.executeUpdate는 next필요없음
            //database.executeQuerys는 next필요함
            try database.executeUpdate("update RoutineItem set name = ?, discription = ? , start_time = ?, end_time = ? where day = ? AND name = ? AND discription = ?", values : [nameRp, discRp, Start, End, day, name, disc ])
            
            //            let rs = try database.executeQuery("select * from RoutineItem", values: nil)
            //
            //            while rs.next() {
            //                let day = rs.string(forColumn: "day")
            //                let name = rs.string(forColumn:"name")
            //                let discription = rs.string(forColumn: "discription")
            //                let date = rs.string(forColumn: "date")
            //                let start_time = rs.string(forColumn: "start_time")
            //                let end_time = rs.string(forColumn: "end_time")
            //
            //                print("================")
            //                print("day = \(day!)")
            //                print("name = \(name!)")
            //                print("discription = \(discription!)")
            //                print("date = \(date!)")
            //                print("start_time = \(start_time!)")
            //                print("end_time = \(end_time!)")
            //            }
            
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        print("insert routine complete")
        database.close()
        

    }
    
    func getRoutine(_ day : String) -> Routine{
        let nilitem : RoutineItem = RoutineItem.init(
            itemName: "루틴을 추가해 주세요",
            itemDisc: "⁉️",
            start: "00",
            end: "00")
        let nilday = day
        
        let nilRoutine = Routine(routines: [nilitem], day: nilday)
        
        var tmp : Routine? = nil
        
        guard database.open() else {
            print("Unable to open database")
            return tmp!
        }
        do{
            let rs = try database.executeQuery("select * from RoutineItem where day = ? order by start_time ASC ",  values: [day])
            
            
            while rs.next(){
                let day = rs.string(forColumn: "day")
                let name = rs.string(forColumn:"name")
                let discription = rs.string(forColumn: "discription")
                let date = rs.string(forColumn: "date")
                let start_time = rs.string(forColumn: "start_time")
                let end_time = rs.string(forColumn: "end_time")
                
                let item : RoutineItem = RoutineItem.init(
                    itemName: name!,
                    itemDisc: discription!,
                    start: start_time!,
                    end: end_time!)
                
                if(tmp == nil){
                    tmp = Routine(routines: [item], day: day!)
                }else{
                    tmp?.day = day!
                    tmp?.routines.append(item)
                }
                
                print("================")
                print("day = \(day!)")
                print("name = \(name!)")
                print("discription = \(discription!)")
                print("date = \(date!)")
                print("start_time = \(start_time!)")
                print("end_time = \(end_time!)")
                
            }
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        database.close()
        if let tmp = tmp {
            return tmp
        }else{
            return nilRoutine
        }
    }
    
    
    func getTodo(_ todoName : String, _ todoDisc : String) -> TodoItem{
        //name TEXT, discription TEXT, date Text, start_time TEXT, end_time TEXT, oneOff TEXT
        let tmp : TodoItem = TodoItem.init(
            todo_name: "error",
            todo_disc: "erorr",
            start_date: "error",
            end_date: "error")
        var item : TodoItem?
        
        guard database.open() else {
            print("Unable to open database")
            return tmp
        }
        do{
            let rs = try database.executeQuery("select * from TodoItem where name = ? AND discription = ?",  values: [todoName , todoDisc])
            
            
            while rs.next(){
                let name = rs.string(forColumn:"name")
                let discription = rs.string(forColumn: "discription")
                let date = rs.string(forColumn: "date")
                let start_time = rs.string(forColumn: "start_time")
                let end_time = rs.string(forColumn: "end_time")
                
                item = TodoItem.init(
                    todo_name: name!,
                    todo_disc: discription!,
                    start_date: start_time!,
                    end_date: end_time!)
                
                print("================")
                print("name = \(name!)")
                print("discription = \(discription!)")
                print("date = \(date!)")
                print("start_time = \(start_time!)")
                print("end_time = \(end_time!)")
                
            }
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        database.close()
        guard let item  = item else{return tmp}
        return item
    }
    
    func getTodos() -> Todos{
        let nilitem : TodoItem = TodoItem.init(
            todo_name: "투두를 추가해 주세요",
            todo_disc: "⁉️",
            start_date: "00",
            end_date: "")
        
        let nilRoutine = Todos(todo: [nilitem])
        
        var tmp : Todos? = nil
        
        guard database.open() else {
            print("Unable to open database")
            return tmp!
        }
        do{
            let rs = try database.executeQuery("select * from TodoItem order by start_time DESC ",  values: [])
            
            
            while rs.next(){
                let name = rs.string(forColumn:"name")
                let discription = rs.string(forColumn: "discription")
                let date = rs.string(forColumn: "date")
                let start_time = rs.string(forColumn: "start_time")
                let end_time = rs.string(forColumn: "end_time")
                
                let item : TodoItem = TodoItem.init(
                    todo_name: name!,
                    todo_disc: discription!,
                    start_date: start_time!,
                    end_date: "")
                
                if(tmp == nil){
                    tmp = Todos(todo: [item])
                }else{
                    tmp?.todo.append(item)
                }
                
                //            let item : RoutineItem = RoutineItem.init(
                //                itemName: name!,
                //                itemDisc: discription!,
                //                start: start_time!,
                //                end: end_time!)
                //
                //            if(tmp == nil){
                //                tmp = Routine(Routine: [item], day: day!)
                //            }else{
                //                tmp?.day = day!
                //                tmp?.Routine.append(item)
                //            }
                
                
                print("================")
                print("name = \(name!)")
                print("discription = \(discription!)")
                print("date = \(date!)")
                print("start_time = \(start_time!)")
                print("end_time = \(end_time!)")
                
            }
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        database.close()
        if let tmp = tmp {
            return tmp
        }else{
            return nilRoutine
        }
    }
    
    func deleteRoutineItem(_ day : String, _ name : String, _ disc : String){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        //"select * from RoutineItem where day = ?",  values: [day])
        do {
            print("item del start", day,name,disc)
            try database.executeUpdate("delete from RoutineItem where day = ? AND name = ? AND discription = ? ", values: [day, name, disc])
        }catch {
            print("failed: \(error.localizedDescription)")
        }
        print("item del ended")

        database.close()
    }
    
    func deleteTodoItem(_ name : String, _ disc : String){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        //"select * from RoutineItem where day = ?",  values: [day])
        do {
            print("item del start",name,disc)
            try database.executeUpdate("delete from TodoItem where name = ? AND discription = ?", values: [name, disc])
        }catch {
            print("failed: \(error.localizedDescription)")
        }
        print("item del ended")

        database.close()
    }
    
    func updateTodoItem( _ name : String, _ disc : String, _ Start : String ){
        
        guard database.open() else {
            print("Unable to open database")
            return
        }
        do {
            //database.executeUpdate는 next필요없음
            //database.executeQuerys는 next필요함
            try database.executeUpdate("update TodoItem set start_time = ? where name = ? AND discription = ?", values : [Start, name, disc])
            
            //            let rs = try database.executeQuery("select * from RoutineItem", values: nil)
            //
            //            while rs.next() {
            //                let day = rs.string(forColumn: "day")
            //                let name = rs.string(forColumn:"name")
            //                let discription = rs.string(forColumn: "discription")
            //                let date = rs.string(forColumn: "date")
            //                let start_time = rs.string(forColumn: "start_time")
            //                let end_time = rs.string(forColumn: "end_time")
            //
            //                print("================")
            //                print("day = \(day!)")
            //                print("name = \(name!)")
            //                print("discription = \(discription!)")
            //                print("date = \(date!)")
            //                print("start_time = \(start_time!)")
            //                print("end_time = \(end_time!)")
            //            }
            
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        print("insert routine complete")
        database.close()
        

    }
    
    func countRoutines(_ day: String) -> Int {
        guard database.open() else {
            print("Unable to open database")
            return 0
        }
        defer {
            database.close()
        }
        
        var count = 0
        
        do {
            let query = "SELECT COUNT(*) AS count FROM RoutineItem WHERE day = ?"
            let rs = try database.executeQuery(query, values: [day])
            
            while rs.next() {
                count = Int(rs.int(forColumn: "count"))
            }
        } catch {
            print("Failed: \(error.localizedDescription)")
        }
        
        return count
    }

    func countTodoItems() -> Int {
        guard database.open() else {
            print("Unable to open database")
            return 0
        }
        defer {
            database.close()
        }
        
        var count = 0
        
        do {
            let query = "SELECT COUNT(*) AS count FROM TodoItem"
            let rs = try database.executeQuery(query, values: nil)
            
            while rs.next() {
                count = Int(rs.int(forColumn: "count"))
            }
        } catch {
            print("Failed: \(error.localizedDescription)")
        }
        
        return count
    }

    
    func test_DBconnect(){
        guard database.open() else {
            print("Unable to open database")
            return
        }
        
        do {
            try database.executeUpdate("create table IF NOT EXISTS RoutineItem(day TEXT, name TEXT, discription TEXT, date text, start_time TEXT, end_time TEXT)", values: nil)
            
            try database.executeUpdate("create table IF NOT EXISTS TodoItem(name TEXT, discription TEXT, date Text, start_time TEXT, end_time TEXT, oneOff TEXT)", values: nil)
            
            // 입력시 사용될 녀석.
            //            try database.executeUpdate("insert into info (order_num, badge, date, plus_one, title) values (?, ?, ?, ?, ?)", values: ["1", true, "2012-05-31", true, "사귄날"])
            //try database.executeUpdate("insert into RoutineItem (day, name, discription, date, start_time, end_time ) values (?, ?, ?, ?, ?, ?)", values: ["test", "test", "test", "test", "test", "test" ])
            //
            let rs = try database.executeQuery("select * from RoutineItem", values: nil)
            
            while rs.next() {
                let day = rs.string(forColumn: "day")
                let name = rs.string(forColumn:"name")
                let discription = rs.string(forColumn: "discription")
                let date = rs.string(forColumn: "date")
                let start_time = rs.string(forColumn: "start_time")
                let end_time = rs.string(forColumn: "end_time")
                
                print("================")
                print("day = \(day!)")
                print("name = \(name!)")
                print("discription = \(discription!)")
                print("date = \(date!)")
                print("start_time = \(start_time!)")
                print("end_time = \(end_time!)")
            }
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        
        database.close()
    }
}
