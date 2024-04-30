import UIKit
import Alamofire

struct Post{
    let idx: Int
    let name: String
    let disc: String
    let start: String
    let end: String
    let like_cnt: Int
}

var Postdata: [Post] = []

class Community: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var email: String?
    var name: String?
    var mbti: String?
    
    var postList = Postdata
    var DB = DAO.shareInstance()
    
    let user = iPhoneController()
    
    let cellName = "CommunityCell"
    let cellReuseIdentifier = "communityCell"
    
    @IBOutlet weak var mbtiLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getuser()
        registerXib()
        tableviewUI() // 테이블뷰 그림자 UI 등 설정
        setupRefreshControl()
    }
    
    func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    // Pull to Refresh 액션 메서드
    @objc func refreshData() {
        getuser() // 새로고침 시 getUser() 호출
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return postList.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        return footerView
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! CommunityCell
        let target = postList[indexPath.section]
        cell.routineName.text = target.name
        cell.routineDisc.text = target.disc
        cell.routineTime.text = "\(target.start) ~ \(target.end)"
        cell.upCount.text = "\(target.like_cnt)"
        cell.count = target.like_cnt
        cell.idx = target.idx
        cell.configure(with: target)
        cell.selectionStyle = .none
        return cell
    }
    
    private func registerXib() {
        let nibName = UINib(nibName: cellName, bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    private func tableviewUI(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear.withAlphaComponent(0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.layer.shadowColor = UIColor.gray.cgColor //색상
        tableView.layer.shadowOpacity = 0.3 //alpha값
        tableView.layer.shadowRadius = 5 //반경
        tableView.layer.shadowOffset = CGSize(width: 2, height: 2) //위치조정
        tableView.layer.masksToBounds = false //내부에 속한 요소들이 UIView 밖을 벗어날 때, 잘라낼 것인지. 그림자는 밖에 그려지는 것이므로 false 로 설정
        tableView.reloadData()
    }
    
    func getuser(){
        postList = []
        user.getUser { email, profile, name in
            DispatchQueue.main.async {
                self.email = email
                self.name = name
                let thisUser = self.DB.GetUser(self.email!)
                if let mbti = thisUser.0{
                    self.mbti = mbti
                    self.mbtiLabel.text = "\(mbti)의 공간"
                }
                print("mbti:", self.mbti!)
                let url = "http://182.214.25.240:8080/api/shareRoutine/selectMbti"
                
                let parameters: [String: Any] = [
                    "mbti": "\(self.mbti!)",
                    "email": "\(self.email!)"
                ]
                
                AF.request(url,
                           method: .get,
                           parameters: parameters,
                           encoding: URLEncoding.default,
                           headers: ["Content-Type":"application/json", "Accept":"application/json"])
                .validate(statusCode: 200..<300)
                .responseJSON { response in
                    switch response.result {
                    case .success(let userData):
                        print("success")
                        if let jsonArray = userData as? [[String: Any]] {
                            for item in jsonArray {
                                if let idx = item["idx"] as? Int,
                                   let name = item["itemName"] as? String,
                                   let disc = item["itemDisc"] as? String,
                                   let start = item["start"] as? String,
                                   let end = item["end"] as? String,
                                   let likeCnt = item["like_cnt"] as? Int {
                                    let post = Post(idx: idx, name: name, disc: disc, start: start, end: end, like_cnt: likeCnt)
                                    self.postList.append(post)
                                }
                            }
                            self.tableView.refreshControl?.endRefreshing()
                            self.tableView.reloadData()
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
                            print("네트워크에 연결되어 있지 않거나 서버가 열려있지 않아서 처리할 수 없습니다.")
                        }
                    }
                }
            }
        }
    }
}

/*
 class CommunityPost: UIViewController, UITextViewDelegate {
 var email: String?
 var mbti: String?
 var img: String?
 var name: String?
 
 let DB = DAO.shareInstance()
 
 let placeholderText = "루틴에 대해서 설명해주세요."
 
 @IBOutlet weak var postTitle: UITextField!
 @IBOutlet weak var contentText: UITextView!
 
 private lazy var dateFormatter: DateFormatter = {
 let formatter = DateFormatter()
 formatter.dateFormat = "yyyy-MM-dd"
 return formatter
 }()
 
 override func viewDidLoad() {
 super.viewDidLoad()
 contentText.delegate = self
 configureTextView()
 swipeRecognizer()
 }
 
 @IBAction func writeCancel(_ sender: UIButton) {
 dismiss(animated: true, completion: nil)
 }
 
 @IBAction func writeDone(_ sender: UIButton) {
 guard let title = postTitle.text, !title.isEmpty else {
 showAlert()
 return
 }
 
 if contentText.text == placeholderText {
 showAlert()
 return
 }
 
 let currentDate = Date()
 let dateString = dateFormatter.string(from: currentDate)
 
 DB.InsertCommunityPost(email!, mbti!, name!, img!, title, dateString, contentText.text, 0)
 dismiss(animated: true, completion: nil)
 }
 
 func showAlert() {
 let alertController = UIAlertController(title: "알림", message: "작성하지 않은 부분을 채워주세요.", preferredStyle: .alert)
 
 alertController.view.layer.cornerRadius = 5.0
 alertController.preferredContentSize = CGSize(width: 300, height: 150)
 alertController.modalPresentationStyle = .overCurrentContext
 
 present(alertController, animated: true) {
 DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
 alertController.dismiss(animated: true, completion: nil)
 }
 }
 }
 
 func swipeRecognizer() {
 let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture(_:)))
 swipeRight.direction = .right
 view.addGestureRecognizer(swipeRight)
 }
 
 @objc func respondToSwipeGesture(_ gesture: UIGestureRecognizer) {
 if let swipeGesture = gesture as? UISwipeGestureRecognizer, swipeGesture.direction == .right {
 dismiss(animated: true, completion: nil)
 }
 }
 
 func configureTextView() {
 contentText.text = placeholderText
 contentText.textColor = .systemGray2
 }
 
 func textViewDidBeginEditing(_ textView: UITextView) {
 if textView.text == placeholderText {
 textView.text = ""
 textView.textColor = .black
 }
 }
 
 func textViewDidEndEditing(_ textView: UITextView) {
 if textView.text.isEmpty {
 textView.text = placeholderText
 textView.textColor = .lightGray
 }
 }
 }
 */
