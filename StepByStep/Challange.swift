//
//  Challange.swift
//  StepByStep
//
//  Created by 엄현호 on 2023/05/23.
//

import UIKit
import Alamofire

struct Goal: Codable {
    let title: String
}

var goalData: [Goal] = []

class Challange: UIViewController, UITableViewDelegate, UITableViewDataSource, ChallangeCellDelegate {
    // 데이터 불러오기
    var GoalList = goalData
    var CompleteCount = 0
    var DB = DAO.shareInstance()
    
    let user = iPhoneController()
    let mypage = Mypage()
    let cellName = "ChallangeCell"
    let cellReuseIdentifier = "goalCell"
    
    @IBOutlet weak var firstView: UIView!
    @IBOutlet weak var complete: UILabel!
    @IBOutlet weak var progress: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstView.layer.shadowColor = UIColor.gray.cgColor
        firstView.layer.shadowOpacity = 1.0
        firstView.layer.shadowOffset = CGSize.zero
        firstView.layer.shadowRadius = 3
        registerXib()
        user.getEmail { email in
            DispatchQueue.main.async {
                self.getChallange()
            }
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear.withAlphaComponent(0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.layer.shadowColor = UIColor.lightGray.cgColor //색상
        tableView.layer.shadowOpacity = 0.3 //alpha값
        tableView.layer.shadowRadius = 5 //반경
        tableView.layer.shadowOffset = CGSize(width: 2, height: 2) //위치조정
        tableView.layer.masksToBounds = false //내부에 속한 요소들이 UIView 밖을 벗어날 때, 잘라낼 것인지. 그림자는 밖에 그려지는 것이므로 false 로 설정
        // Do any additional setup after loading the view.
    }
    
    // Section 당 Row의 수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Section의 수
    func numberOfSections(in tableView: UITableView) -> Int {
        return GoalList.count
    }
    
    // 간격설정
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! ChallangeCell
        let target = GoalList[indexPath.section]
        
        cell.GoalLabel?.text = target.title
        cell.selectionStyle = .none
        cell.delegate = self // 셀의 대리자(delegate) 설정
        progress.text = "\(GoalList.count)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // 오른쪽에 만들기
        let delete = UIContextualAction(style: .normal, title: "Delete") { (action, view, completion) in
            // 삭제 로직 구현
            self.deleteCell(at: indexPath)
            completion(true)
        }
        
        // 커스텀 이미지 생성
        let imageSize = CGSize(width: 50, height: 50)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        let image = renderer.image { context in
            let fillColor = UIColor.systemPink // 배경색
            let cornerRadius = CGFloat(10) // 둥근 모서리의 반지름
            
            let rect = CGRect(origin: .zero, size: imageSize)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            
            fillColor.setFill()
            path.fill()
            
            let trashImage = UIImage(systemName: "trash")?.withTintColor(.white, renderingMode: .alwaysTemplate)
            let trashSize = CGSize(width: 24, height: 24)
            
            let imageOrigin = CGPoint(x: (imageSize.width - trashSize.width) / 2, y: (imageSize.height - trashSize.height) / 2 )
            let imageRect = CGRect(origin: imageOrigin, size: trashSize)
            
            trashImage?.draw(in: imageRect)
        }
        
        // 액션에 커스텀 이미지 설정
        delete.image = image
        delete.backgroundColor = UIColor.white
        // actions 배열 인덱스 0이 왼쪽에 붙어서 나옴
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    // 셀 스와이프로 삭제하는 함수
    func deleteCell(at indexPath: IndexPath) {
        let selectedCell = GoalList[indexPath.section]
        let title = selectedCell.title

        let url = "http://182.214.25.240:8080/api/challenge/delete/\(self.user.email)/\(title)"

        let parameters: [String: Any] = [
            "email": self.user.email,
            "title": title
        ]
        
        var urlComponents = URLComponents(string: url)
        urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
        
        guard let deleteURL = urlComponents?.url else {
            print("Invalid URL")
            return
        }
        
        AF.request(deleteURL,
                   method: .delete,
                   encoding: URLEncoding.default,
                   headers: ["Content-Type": "application/json", "Accept": "application/json"])
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .success:
                    print("DELETE 성공")
                    self.DB.deleteChallange(self.user.email, title)
                    self.GoalList.remove(at: indexPath.section)
                    self.tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
                    self.progress.text = "\(self.GoalList.count)"
                case .failure(let error):
                    // 에러 처리
                    if let statusCode = response.response?.statusCode {
                        // 상태 코드에 따른 분기 처리
                        if statusCode == 404 {
                            // 예: 404 에러 처리
                            print("서버를 찾을 수 없습니다.")
                        } else if statusCode == 500 {
                            // 예: 500 에러 처리
                            print("서버 내부 오류가 발생했습니다.")
                        } else {
                            // 기타 상태 코드에 대한 처리
                            print("Error: \(error.errorDescription ?? "")")
                        }
                    } else {
                        // 네트워크 에러 처리
                        print("네트워크에 연결되어 있지 않거나 서버가 열려있지 않아서 처리할 수 없습니다.")
                    }
                }
            }
    }
    
    private func registerXib() {
        let nibName = UINib(nibName: cellName, bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    // ChaalangeCell에서 완료 버튼 함수
    func didTapDeleteButton(in cell: ChallangeCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            ChallangeComplete(at: indexPath)
        }
    }
    
    // 챌린지 완료시 EXP 증가 알림창 띄움. 1초동안 타이머 설정하여서
    func showExpupAlert() {
        let alertController = UIAlertController(title: "챌린지 완료보상", message: "EXP+10 획득", preferredStyle: .alert)
        
        // 테두리 Radius 설정
        alertController.view.layer.cornerRadius = 5.0
        // 알림창 크기 조정
        alertController.preferredContentSize = CGSize(width: 300, height: 150)
        // 알림창 위치 조정
        alertController.modalPresentationStyle = .overCurrentContext
        
        // 알림창이 사라지도록 타이머 설정
        let duration: TimeInterval = 1.0 // 알림창이 보여지는 시간(초) 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alertController.dismiss(animated: true) {
            }
        }
        present(alertController, animated: true, completion: nil)
    }
    
    // 셀 완료후 삭제 하는 부분 완료 Count 증가
    func ChallangeComplete(at indexPath: IndexPath) {
        let selectedGoal = GoalList[indexPath.section]
        let selectedTitle = selectedGoal.title
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentDate)
        
        let url = "http://182.214.25.240:8080/api/challenge/update/\(self.user.email)/\(selectedTitle)"
        
        let parameters: [String: Any] = [
            "email": self.user.email,
            "title": selectedTitle
        ]
        
        var urlComponents = URLComponents(string: url)
        urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
        
        guard let patchedURL = urlComponents?.url else {
            print("Invalid URL")
            return
        }
        
        AF.request(patchedURL,
                   method: .patch,
                   headers: ["Content-Type": "application/x-www-form-urlencoded"])
        .validate(statusCode: 200..<300)
        .responseJSON { response in
            switch response.result {
            case .success:
                print("챌린지 완료 PATCH 성공")
                self.GoalList.remove(at: indexPath.section)
                self.tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
                self.progress.text = "\(self.GoalList.count)"
                self.CompleteCount += 1
                self.complete.text = "\(self.CompleteCount)"
                
                self.DB.deleteChallange(self.user.email, selectedTitle)
                self.DB.InsertChallangeComplete(self.user.email, selectedTitle, dateString)
                self.mypage.expAdd()
                self.showExpupAlert()
            case .failure(let error):
                // 에러 처리
                if let statusCode = response.response?.statusCode {
                    // 상태 코드에 따른 분기 처리
                    if statusCode == 404 {
                        // 예: 404 에러 처리
                        print("서버를 찾을 수 없습니다.")
                    } else if statusCode == 500 {
                        // 예: 500 에러 처리
                        print("서버 내부 오류가 발생했습니다.")
                    } else {
                        // 기타 상태 코드에 대한 처리
                        print("Error: \(error.errorDescription ?? "")")
                    }
                } else {
                    // 네트워크 에러 처리
                    print("네트워크에 연결되어 있지 않거나 서버가 열려있지 않아서 처리할 수 없습니다.")
                }
            }
        }
    }
    
    // 이메일에 저장된 챌린지 불러옴
    func getChallange() {
        let url = "http://182.214.25.240:8080/api/challenge/incomplete"
        let parameters: [String: Any] = [
            "email": self.user.email
        ]
        
        let request = AF.request(url,
                   method: .get,
                   parameters: parameters,
                   encoding: URLEncoding.default,
                   headers: ["Content-Type":"application/json", "Accept":"application/json"])
        request.validate(statusCode: 200..<300)
        request.responseJSON { response in
            switch response.result {
            case .success(let data):
                if let dataArray = data as? [[String: Any]] {
                    for item in dataArray {
                        if let title = item["title"] as? String{
                            let newGoal = Goal(title: title)
                            self.addNewGoal(newGoal)
                        }
                    }
                }
                let thisUser = self.DB.GetChallangeComplete(self.user.email)
                for _ in thisUser {
                    self.CompleteCount += 1
                }
                self.complete.text = "\(self.CompleteCount)"
            case .failure(let error):
                // 에러 처리
                if let statusCode = response.response?.statusCode {
                    // 상태 코드에 따른 분기 처리
                    if statusCode == 404 {
                        // 예: 404 에러 처리
                        print("서버를 찾을 수 없습니다.")
                    } else if statusCode == 500 {
                        // 예: 500 에러 처리
                        print("서버 내부 오류가 발생했습니다.")
                    } else {
                        // 기타 상태 코드에 대한 처리
                        print("Error: \(error.errorDescription ?? "")")
                    }
                } else {
                    // 네트워크 에러 처리
                    print("네트워크 연결에 문제가 있습니다. 동기화된 DB 정보를 불러옵니다. ")
                    let challangeList = self.DB.GetChallange(self.user.email)
                    for title in challangeList {
                        let newGoal = Goal(title: title)
                        self.addNewGoal(newGoal)
                    }
                    let thisUser = self.DB.GetChallangeComplete(self.user.email)
                    for _ in thisUser {
                        self.CompleteCount += 1
                    }
                    self.complete.text = "\(self.CompleteCount)"
                }
            }
        }
        // 타임아웃 설정 1초안에 연결 안 될시에 네트워크 에러로 간주 데이터 베이스 정보 불러옴
        let timeoutInterval: TimeInterval = 1 // 1초
        request.task?.resume() // 타임아웃 설정을 위해 요청을 직접 재개
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval) {
            if request.task?.state == .running {
                request.task?.cancel()
            }
        }
    }
    
    // 목표 추가 버튼
    @IBAction func addGoal(_ sender: UIButton) {
        let alert = UIAlertController(title: "새로운 목표 설정", message: "추가할 목표의 타이틀을 정해주세요.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "추가", style: .default) { (ok) in
            if self.checkForDuplicateTitle((alert.textFields?[0].text)!) {
                self.showDuplicationAlert() {
                    self.addGoal(sender)
                }
                return
            }
            
            let url = "http://182.214.25.240:8080/api/challenge/save"
            let parameters: [String: Any] = [
                "email": self.user.email,
                "title": (alert.textFields?[0].text)!
            ]
            
            AF.request(url,
                       method: .post,
                       parameters: parameters,
                       encoding: URLEncoding.httpBody,
                       headers: ["Content-Type": "application/x-www-form-urlencoded"])
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .success:
                    print("챌린지 POST 성공")
                    let newGoal = Goal(title: (alert.textFields?[0].text)!)
                    self.addNewGoal(newGoal)
                    self.DB.InsertChallange(self.user.email, (alert.textFields?[0].text)!)
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        // 상태 코드에 따른 분기 처리
                        if statusCode == 404 {
                            // 예: 404 에러 처리
                            print("서버를 찾을 수 없습니다.")
                        } else if statusCode == 500 {
                            // 예: 500 에러 처리
                            print("서버 내부 오류가 발생했습니다.")
                        } else {
                            // 기타 상태 코드에 대한 처리
                            print("Error: \(error.errorDescription ?? "")")
                        }
                    } else {
                        // 네트워크 에러 처리
                        print("네트워크에 연결되어 있지 않거나 서버가 열려있지 않아서 처리할 수 없습니다.")
                    }
                }
            }
        }
        
        let cancel = UIAlertAction(title: "취소", style: .cancel) { (cancel) in
            //code
        }
        
        alert.addAction(cancel)
        alert.addAction(ok)
        alert.addTextField { (TitleTextField) in
            TitleTextField.textColor = UIColor.darkGray
            TitleTextField.placeholder = "타이틀을 입력하세요."
        }
        self.present(alert, animated: true, completion: nil)
    }
    func addNewGoal(_ goal: Goal) {
        GoalList.append(goal)
        tableView.reloadData()
    }
    
    // 챌린지 목록 중복 체크 미완료, 완료목록 전부 체크
    func checkForDuplicateTitle(_ title: String) -> Bool {
        let challangeList = self.DB.GetChallange(self.user.email)
        let completeList = self.DB.GetChallangeComplete(self.user.email)
        
        for existingTitle in challangeList {
            if existingTitle == title {
                return true
            }
        }
        
        for (existingTitle, _) in completeList {
            if existingTitle == title {
                return true
            }
        }
        
        return false
    }
    
    // 중복알림
    func showDuplicationAlert(completion: @escaping () -> Void) {
        let alertController = UIAlertController(title: "알림", message: "이미 같은 이름의 도전과제가 존재하거나 완료한 도전과제입니다.", preferredStyle: .alert)
        
        // 테두리 Radius 설정
        alertController.view.layer.cornerRadius = 5.0
        // 알림창 크기 조정
        alertController.preferredContentSize = CGSize(width: 300, height: 150)
        // 알림창 위치 조정
        alertController.modalPresentationStyle = .overCurrentContext
        
        // 알림창이 사라지도록 타이머 설정
        let duration: TimeInterval = 1.0 // 알림창이 보여지는 시간(초) 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alertController.dismiss(animated: true) {
                completion()
            }
        }
        present(alertController, animated: true, completion: nil)
    }
    
    // 완료 목록 확인 버튼
    @IBAction func CompleteListbtn(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "IphoneMain", bundle: nil)
        if let nextVC = storyboard.instantiateViewController(withIdentifier: "CompleteView") as? CompleteView {
            nextVC.modalPresentationStyle = .fullScreen
            nextVC.email = self.user.email // 이메일 정보 넘겨줌
            present(nextVC, animated: true, completion: nil)
        }
    }
}

struct Complete {
    let title: String
    let date: String
}

var data: [Complete] = []

class CompleteView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var email: String?
    var completeList = data
    let cellName = "CompleteCell"
    let cellReuseIdentifier = "completeCell"
    var DB = DAO.shareInstance()
    
    @IBOutlet weak var completeCount: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func Close(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerXib()
        getList()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear.withAlphaComponent(0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.layer.shadowColor = UIColor.lightGray.cgColor //색상
        tableView.layer.shadowOpacity = 0.3 //alpha값
        tableView.layer.shadowRadius = 5 //반경
        tableView.layer.shadowOffset = CGSize(width: 2, height: 2) //위치조정
        tableView.layer.masksToBounds = false //내부에 속한 요소들이 UIView 밖을 벗어날 때, 잘라낼 것인지. 그림자는 밖에 그려지는 것이므로 false 로 설정
    }
    // Section 당 Row의 수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Section의 수
    func numberOfSections(in tableView: UITableView) -> Int {
        return completeList.count
    }
    
    // 간격 설정 footer기준
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10 // 하단 간격을 원하는 값으로 수정
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! CompleteCell
        let target = completeList[indexPath.section]
        
        cell.titleLabel?.text = target.title
        cell.dateLabel?.text = target.date
        cell.selectionStyle = .none
        return cell
    }
    
    private func registerXib() {
        let nibName = UINib(nibName: cellName, bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    func getList() {
        let url = "http://182.214.25.240:8080/api/challenge/complete"
        let parameters: [String: Any] = [
            "email": self.email!
        ]
        
        let request = AF.request(url,
                   method: .get,
                   parameters: parameters,
                   encoding: URLEncoding.default,
                   headers: ["Content-Type":"application/json", "Accept":"application/json"])
        request.validate(statusCode: 200..<300)
        request.responseJSON { response in
            switch response.result {
            case .success(let data):
                if let dataArray = data as? [[String: Any]] {
                    for item in dataArray {
                        if let title = item["title"] as? String,
                        let date = item["completeDate"] as? String{
                            let complete = Complete(title: title, date: date)
                            self.completeList.append(complete)
                        }
                    }
                }
            case .failure(let error):
                if let statusCode = response.response?.statusCode {
                    // 상태 코드에 따른 분기 처리
                    if statusCode == 404 {
                        // 예: 404 에러 처리
                        print("서버를 찾을 수 없습니다.")
                    } else if statusCode == 500 {
                        // 예: 500 에러 처리
                        print("서버 내부 오류가 발생했습니다.")
                    } else {
                        // 기타 상태 코드에 대한 처리
                        print("Error: \(error.errorDescription ?? "")")
                    }
                } else {
                    // 네트워크 에러 처리
                    print("네트워크 연결에 문제가 있습니다. 동기화된 DB 정보를 불러옵니다. ")
                    let thisUser = self.DB.GetChallangeComplete(self.email!)
                    for completeList in thisUser {
                        let title = completeList.0
                        let date = completeList.1
                        let complete = Complete(title: title, date: date)
                        self.completeList.append(complete)
                    }
                }
            }
            self.tableView.reloadData()
            self.completeCount.text = "완료한 과제 : \(self.completeList.count)"
        }
        // 타임아웃 설정 1초안에 연결 안 될시에 네트워크 에러로 간주 데이터 베이스 정보 불러옴
        let timeoutInterval: TimeInterval = 1 // 1초
        request.task?.resume() // 타임아웃 설정을 위해 요청을 직접 재개
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval) {
            if request.task?.state == .running {
                request.task?.cancel()
            }
        }
    }
}

/**
 func getList2(){
     let url = "http://182.214.25.240:8080/api/challenge/complete"
     let parameters: [String: Any] = [
         "email": self.email!
     ]
     AF.request(url,
                method: .get,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: ["Content-Type":"application/json", "Accept":"application/json"])
     .validate(statusCode: 200..<300)
     .responseDecodable(of: [completeChallange].self) { response in
         
         if let JsonParsedData = response.value{
             for item in JsonParsedData {
                 print(item)
                 let complete = Complete(title: item.title, date: item.completeDate)
                 print("??",complete)
                 self.completeList.append(complete)
                 }
             }
         print("Data:",self.completeList)
         self.tableView.reloadData()
         self.completeCount.text = "완료한 과제: \(self.completeList.count)"
         }
     print("hi")
     /*{ response in
         switch response.result {
         case .success(let data):
             print("??ㄹㅁㅈㄷㅁㅈ 일단 석세스존에는 들어오는데")
             print("data.= " , data)
             if let dataArray = data as? [[String: Any]] {
                 for item in dataArray {
                     if let title = item["title"] as? String,
                        let date = item["completeDate"] as? String{
                         print("들어오나")
                         let complete = Complete(title: title, date: date)
                         self.completeList.append(complete)
                     }
                 }
             }
         case .failure(let error):
             print("Error: \(error.errorDescription ?? "")")
         }
     }*/
     
     DispatchQueue.main.async {
         /*
         let thisUser = self.DB.GetChallangeComplete(self.email!)
         for completeList in thisUser {
             let title = completeList.0
             let date = completeList.1
             let complete = Complete(title: title, date: date)
             self.completeList.append(complete)
         }
         */
         self.tableView.reloadData() // 메인 스레드에서 테이블 뷰 새로고침
         self.completeCount.text = "완료한 과제: \(self.completeList.count)"
     }
 }

 **/
