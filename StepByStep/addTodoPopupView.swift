//
//  addItemPopupView.swift
//  StepByStep
//
//  Created by Yune gim on 2023/05/28.
//

import Foundation
import UIKit
import Alamofire
import KakaoSDKUser
import FMDB


class addTodoPopupView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let serverIP = "http://182.214.25.240:8080/"
    
    @IBOutlet weak var acceptBtn: UIButton!
    
    @IBOutlet var itemNameText: UITextField!
    @IBOutlet var itemDiscText: UITextField!
    @IBOutlet var startTime: UIDatePicker!
    @IBOutlet var endTime: UIDatePicker!
    
    @IBOutlet var addItemBtn: UIButton!
    
    @IBOutlet var ItemTable: UITableView!
    
    var check = 0
    var data : Todos?
    var DB = DAO.shareInstance()

    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboard()
        ItemTable.delegate = self
        ItemTable.dataSource = self
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = data?.todo.count{
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(indexPath.row)
        let cell = ItemTable.dequeueReusableCell(withIdentifier: "TodoCell") as! TodoCell
        
        cell.TodoItemNameLabel.text = data?.todo[indexPath.row].todo_name
        cell.TodoItemDiscLabel.text = data?.todo[indexPath.row].todo_disc
        cell.TodoTimeLabel.text = (data?.todo[indexPath.row].start_date)!
        
        return cell
        
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismissView()
    }
    
    @objc func dismissView(){
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func addItemBtnPressed(_ sender: Any) {
        
        if let itemNametext = itemNameText.text,
            let itemDisc = itemDiscText.text,
            let start = startTime{
            
            let item : TodoItem = TodoItem(
                todo_name: itemNametext,
                todo_disc: itemDisc,
                start_date: start.toString("yyyy-MM-dd"),
                end_date : start.toString("yyyy-MM-dd")
                )
            //테이블뷰에 적재하는 로직 시작
            if(data == nil){
                data = Todos(todo: [item])
            }else{
                data?.todo.append(item)
            }
            
            print("item = ", item)
            
            ItemTable.reloadData()
            
//            print(data)
//            //아이템을 서버로 전송
//            if let data = try? JSONEncoder().encode(data?.todo) {
//                 print("data = \(String(decoding: data, as: UTF8.self))")
//                 postTest(data)
//             }
        }
    }
    
    @IBAction func saveBtnPressed(_ sender: Any) {
        
        for item  in ItemTable.visibleCells {
            let itemCell = (item as! TodoCell)
            if let itemNametext = itemCell.TodoItemNameLabel.text,
                    let itemDisc = itemCell.TodoItemDiscLabel.text,
                    let time =  itemCell.TodoTimeLabel.text
                {
                    DB.insertTodoItem(itemNametext, itemDisc, time, time)
                    }
            }
                    //아이템을 서버로 전송
                    if let data = try? JSONEncoder().encode(data?.todo) {
                         print("data = \(String(decoding: data, as: UTF8.self))")
                         postTest(data)
                     }
        dismissView()
        
    }
    
    
    func postTest(_ data : Data ){

        let email:String = UserDefaults.standard.object(forKey: "email") as! String
        let urlString = serverIP + "api/todo/save/" + email
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        //request.httpBody = data
        
        
        
        do {
            try request.httpBody = data
            
            //try request.httpBody?.append(JSONSerialization.data(withJSONObject: params, options: []))
            
        } catch {
            print("http Body Error")
        }
        
        AF.request(request).responseString { (response) in
            switch response.result {
            case .success:
                print("투두 삽입 성공")
            case .failure(let error):
                print("error : \(error.errorDescription!)")
            }
        }
        
    }
    
    
}

extension Date {

    /**
     # dateCompare
     - Parameters:
        - fromDate: 비교 대상 Date
     - Note: 두 날짜간 비교해서 과거(Future)/현재(Same)/미래(Past) 반환
    */
    public func dateCompare(fromDate: Date) -> String {
        var strDateMessage:String = ""
        let result:ComparisonResult = self.compare(fromDate)
        switch result {
        case .orderedAscending:
            strDateMessage = "Future"
            break
        case .orderedDescending:
            strDateMessage = "Past"
            break
        case .orderedSame:
            strDateMessage = "Same"
            break
        default:
            strDateMessage = "Error"
            break
        }
        return strDateMessage
    }
}

