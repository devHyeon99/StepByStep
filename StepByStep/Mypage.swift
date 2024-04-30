//
//  UITabBarController.swift
//  StepByStep
//
//  Created by 엄현호 on 2023/05/15.
//

import Foundation
import UIKit
import KakaoSDKUser
import Alamofire
import SystemConfiguration

class Mypage: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    let viewModel = ImageViewModel() // 뷰 모델 변수 추가
    let diaryview = DiaryView()
    let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    private let emitterLayer = CAEmitterLayer()
    private var isAnimationRunning = true
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var profile: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var mbti: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var badge: UIImageView!
    
    var email: String = ""
    var level = 0
    var DB = DAO.shareInstance()
    var currentExperience: CGFloat = 0.0
    var experienceBar: ExperienceBarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        User()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let thisUser = self.DB.GetUser(self.email)
        if let level = thisUser.1, let exp = thisUser.2 {
            if let intValue = Int(level){
                self.level = intValue
            } else {
                return
            }
            if let floatValue = Float(exp) {
                let cgValue = CGFloat(floatValue)
                currentExperience = cgValue
            }
            expBarUpdate()
        }
    }
    
    func expBarUpdate() {
        if let experienceBar = experienceBar {
            // 경험치 바 업데이트 및 다시 그리기
            DispatchQueue.main.async {
                experienceBar.updateExperience(self.currentExperience) { [weak self] _ in
                    self!.level += 1
                    self!.currentExperience = 0.0
                    self!.levelLabel.text = "Level: \(self!.level)"
                    let exp = "\(self!.currentExperience)"
                    let lv = "\(self!.level)"
                    self!.DB.UpdateUser(self!.email, lv, exp)
                    // 뱃지 업데이트 ?
                    if self!.level >= 5 && self!.level < 15 {
                        self!.badge.image = UIImage(named: "bronze.png")
                    } else if self!.level >= 15 && self!.level < 30 {
                        self!.badge.image = UIImage(named: "silver.png")
                    } else if self!.level >= 30 {
                        self!.badge.image = UIImage(named: "gold.png")
                    }
                    self!.levelUp()
                    self!.levelUpAlert()
                    self!.patchexp()
                }
            }
        } else {
            print("no")
        }
    }
    
    // 레벨업 애니메이션
    func levelUp() {
        let cell = CAEmitterCell()
        cell.contents = UIImage(named: "levelup.png")!.cgImage
        cell.birthRate = 5
        cell.lifetime = 10
        cell.scale = 0.5
        cell.yAcceleration = 100
        cell.alphaSpeed = -0.2
        
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: view.frame.width,
                                          height: view.frame.height)
        emitterLayer.emitterPosition = CGPoint(x: view.center.x,
                                               y: .zero)
        emitterLayer.emitterCells = [cell]
        
        view.layer.addSublayer(emitterLayer)
    }
    
    // 레벨업 알트창 2초 유지되면서 애니메이션 자동으로 꺼지도록 됨.
    func levelUpAlert() {
        let alertController = UIAlertController(title: "레벨업", message: "레벨업을 축하드립니다.", preferredStyle: .alert)
        
        // 테두리 Radius 설정
        alertController.view.layer.cornerRadius = 5.0
        // 알림창 크기 조정
        alertController.preferredContentSize = CGSize(width: 300, height: 150)
        // 알림창 위치 조정
        alertController.modalPresentationStyle = .overCurrentContext
        
        // 알림창이 사라지도록 타이머 설정
        let duration: TimeInterval = 2.0 // 알림창이 보여지는 시간(초) 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alertController.dismiss(animated: true) {
                self.emitterLayer.birthRate = 0
            }
        }
        present(alertController, animated: true, completion: nil)
    }
    
    // exp 증가
    func expAdd() {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter() // DispatchGroup에 진입
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print(error)
            }
            else {
                _ = user
                self.email = (user?.kakaoAccount?.email)!
                let thisUser = self.DB.GetUser(self.email)
                if let level = thisUser.1, let exp = thisUser.2 {
                    if let intValue = Int(level){
                        self.level = intValue
                    } else {
                        dispatchGroup.leave() // DispatchGroup에서 빠져나옴
                        return
                    }
                    if let floatValue = Float(exp) {
                        let cgValue = CGFloat(floatValue)
                        self.currentExperience = cgValue
                    }
                }
                dispatchGroup.leave() // DispatchGroup에서 빠져나옴
            }
        }
        dispatchGroup.notify(queue: .main) {
            self.currentExperience += 10.0
            let exp = "\(self.currentExperience)"
            let lv = "\(self.level)"
            self.DB.UpdateUser(self.email, lv, exp)
            self.patchexp()
        }
    }
    
    func patchexp() {
        let url = "http://182.214.25.240:8080/api/user/userLevel/\(self.email)"

        let parameters: [String: Any] = [
            "level": "\(self.level)",
            "exp": "\(self.currentExperience)"
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = jsonData
            
            AF.request(request)
                .validate(statusCode: 200..<300)
                .responseJSON { response in
                    switch response.result {
                    case .success:
                        print("레벨, EXP PATCH 성공")
                    case .failure(let error):
                        print("error: \(error.errorDescription ?? "")")
                    }
                }
        } catch {
            print("JSON 데이터 생성 오류: \(error)")
        }
    }
    
    // Diary 작성 View present
    @IBAction func Write(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "IphoneMain", bundle: nil)
        if let mypageWriteVC = storyboard.instantiateViewController(withIdentifier: "MypageWrite") as? MypageWrite {
            mypageWriteVC.modalPresentationStyle = .fullScreen
            mypageWriteVC.mypageViewController = self
            present(mypageWriteVC, animated: true, completion: nil)
        }
    }
    
    // 유저 정보 가져오는 부분 닉네임, 프로필, 이메일
    func User (){
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print("에러:", error)
                DispatchQueue.main.async {
                    self.email = UserDefaults.standard.object(forKey: "email") as! String
                    self.name.text = UserDefaults.standard.object(forKey: "name") as? String
                    self.profile.image = UIImage(systemName: "xmark.circle")
                }
                self.getDiary()
            }
            else {
                _ = user
                if let userProfile = user?.kakaoAccount?.profile?.profileImageUrl,
                   let userEmail = user?.kakaoAccount?.email,
                   let userNickname = user?.kakaoAccount?.profile?.nickname{
                    print("userProfile",userProfile)
                    print("userEmail",userEmail)
                    print("userNickname",userNickname)
                    self.email = userEmail
                    self.name.text = userNickname
                    self.profile.load(url: (user?.kakaoAccount?.profile?.profileImageUrl)!)
                    self.getDiary()
                }
            }
        }
    }
    
    // 유저가 작성한 다이어리 가져오는 부분 및 엠비티아이랑, 레벨, 경험치
    func getDiary(){
        let serverURL = "http://182.214.25.240:8080/api"
        checkServerReachability(urlString: serverURL) { isReachable in
            if isReachable {
                print("Server is reachable1234")
                // 서버에 연결 가능한 경우 처리
                let url = "http://182.214.25.240:8080/api/memoir/Preview"
                let parameters: [String: Any] = [
                    "email": self.email
                ]
                
                AF.request(url,
                           method: .get,
                           parameters: parameters,
                           encoding: URLEncoding.default,
                           headers: ["Content-Type":"application/json", "Accept":"application/json"])
                .validate(statusCode: 200..<300)
                .responseJSON { response in
                    
                    /** 서버로부터 받은 데이터 활용 */
                    switch response.result {
                    case .success(let userData):
                        if let json = userData as? [String: Any],
                           let mbti = json["mbti"] as? String,
                           let level = json["level"] as? String,
                           let exp = json["exp"] as? String,
                           let previewList = json["previewList"] as? [[String: Any]] {
                            self.mbti.text = "MBTI: \(mbti)"
                            if let intValue = Int(level){
                                self.level = intValue
                                self.levelLabel.text = "Level: \(self.level)"
                                if self.level >= 5 && self.level < 15 {
                                    self.badge.image = UIImage(named: "bronze.png")
                                } else if self.level >= 15 && self.level < 30 {
                                    self.badge.image = UIImage(named: "silver.png")
                                } else if self.level >= 30 {
                                    self.badge.image = UIImage(named: "gold.png")
                                }
                            } else { return }
                            if let floatValue = Float(exp) {
                                let cgValue = CGFloat(floatValue)
                                self.currentExperience = cgValue
                                if let floatValue = Float(exp) {
                                    let cgValue = CGFloat(floatValue)
                                    self.currentExperience = cgValue
                                    
                                    // 경험치 바의 크기 설정 및 생성
                                    let maximumExperience: CGFloat = 100.0
                                    let barWidth: CGFloat = 180.0
                                    let barHeight: CGFloat = 20.0
                                    let barTopMargin: CGFloat = 120.0
                                    let barLeadingMargin: CGFloat = 75.0

                                    let barFrame = CGRect(x: 0, y: 0, width: barWidth, height: barHeight)
                                    self.experienceBar = ExperienceBarView(frame: barFrame, maximumExperience: maximumExperience, currentExperience: self.currentExperience)
                                    self.experienceBar.translatesAutoresizingMaskIntoConstraints = false
                                    self.view.addSubview(self.experienceBar)

                                    // 경험치 바의 제약조건을 설정
                                    let constraints = [
                                        self.experienceBar.widthAnchor.constraint(equalToConstant: barWidth),
                                        self.experienceBar.heightAnchor.constraint(equalToConstant: barHeight),
                                        self.experienceBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: barTopMargin),
                                        self.experienceBar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: barLeadingMargin)
                                    ]
                                    NSLayoutConstraint.activate(constraints)
                                    
                                } else { return }
                            }
                            for item in previewList {
                                if let memoirDate = item["memoirDate"] as? String,
                                   let previewImg = item["previewImg"] as? String {
                                    print("Memoir Date: \(memoirDate)")
                                    print("Preview Image: \(previewImg)")
                                    let imgurl = "http://182.214.25.240:8080/api/memoir/img/\(self.email)/\(memoirDate)/\(previewImg)"
                                    if let imgURL = URL(string: imgurl) {
                                        self.loadImageFromURL(url: imgURL) { [weak self] image in
                                            guard let self = self, let image = image else {
                                                return
                                            }
                                            let newImageInfo = ImageInfo(date: "\(memoirDate)", title: "", mood: "", content: "", img: image)
                                            self.viewModel.imageInfoList.append(newImageInfo)
                                            self.reloadCollectionView()
                                        }
                                    }
                                }
                            }
                        }
                    case .failure(let error):
                        /** 그렇지 않은 경우 */
                        print("error : \(error.errorDescription!)")
                    }
                }
            } else {
                print("Server is unreachable")
                // 서버에 연결 불가능한 경우 처리
                let thisUser = self.DB.GetUser(self.email)
                if let mbti = thisUser.0, let level = thisUser.1, let exp = thisUser.2 {
                    print("MBTI: \(mbti), Level: \(level), Exp: \(exp)")
                    self.mbti.text = "MBTI: \(mbti)"
                    self.levelLabel.text = "Level: \(level)"
                    if let intValue = Int(level){
                        self.level = intValue
                        if self.level >= 5 && self.level < 15 {
                            self.badge.image = UIImage(named: "bronze.png")
                        } else if self.level >= 15 && self.level < 30 {
                            self.badge.image = UIImage(named: "silver.png")
                        } else if self.level >= 30 {
                            self.badge.image = UIImage(named: "gold.png")
                        }
                    } else { return }
                    if let floatValue = Float(exp) {
                        let cgValue = CGFloat(floatValue)
                        self.currentExperience = cgValue
                        
                        // 경험치 바의 크기 설정 및 생성
                        let maximumExperience: CGFloat = 100.0
                        let barWidth: CGFloat = 180.0
                        let barHeight: CGFloat = 20.0
                        let barTopMargin: CGFloat = 120.0
                        let barLeadingMargin: CGFloat = 75.0

                        let barFrame = CGRect(x: 0, y: 0, width: barWidth, height: barHeight)
                        self.experienceBar = ExperienceBarView(frame: barFrame, maximumExperience: maximumExperience, currentExperience: self.currentExperience)
                        self.experienceBar.translatesAutoresizingMaskIntoConstraints = false
                        self.view.addSubview(self.experienceBar)

                        // 경험치 바의 제약조건을 설정
                        let constraints = [
                            self.experienceBar.widthAnchor.constraint(equalToConstant: barWidth),
                            self.experienceBar.heightAnchor.constraint(equalToConstant: barHeight),
                            self.experienceBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: barTopMargin),
                            self.experienceBar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: barLeadingMargin)
                        ]
                        NSLayoutConstraint.activate(constraints)
                        
                    } else { return }
                }
                let thisUserDiary = self.DB.GetDiary(self.email)
                for record in thisUserDiary {
                    let date = record.0
                    let title = record.1
                    let mood = record.2
                    let content = record.3
                    
                    let newImageInfo = ImageInfo(date: "\(date)", title: "\(title)", mood: "\(mood)", content: "\(content)", img: UIImage(named: "imageError.png"))
                    self.viewModel.imageInfoList.append(newImageInfo)
                }
                self.reloadCollectionView()
            }
        }
    }
    
    // 이미지 URL 다운로드 및 처리
    func loadImageFromURL(url: URL, completion: @escaping (UIImage?) -> Void) {
        AF.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                let image = UIImage(data: data)
                completion(image)
            case .failure:
                completion(nil)
            }
        }
    }
    
    // 컬렉션 뷰 리로드 함수
    func reloadCollectionView() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    // 컬렉션 뷰 구성 설정 부분
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 컬렉션 뷰에 총 몇개의 셀을 표시할 것인지 구현
        return viewModel.countOfImageList
    }
    // 컬렉션 뷰 업데이트
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // dequeReusableCell은 재활용 가능한 셀을 큐(queue)의 형태로 추가/제거합니다.
        // for:는 셀의 위치를 ​​지정하는 색인 ​​경로입니다.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? MypageCell else {
            return UICollectionViewCell()
        }
        let imageInfo = viewModel.imageInfo(at: indexPath.item) // indexPath.item을 기준으로 뷰모델에서 ImageInfo 가져옴
        cell.update(info: imageInfo) // 해당 셀을 업데이트
        return cell
    }
    // 셀이 선택되었을 때 이벤트
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageInfo = viewModel.imageInfo(at: indexPath.item)
        print(imageInfo)
        
        let storyboard = UIStoryboard(name: "IphoneMain", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "DiaryView") as! DiaryView
        nextVC.modalPresentationStyle = .fullScreen
        nextVC.Diarydate = imageInfo.date
        nextVC.Dimage = imageInfo.img
        
        let serverURL = "http://182.214.25.240:8080/api"
        checkServerReachability(urlString: serverURL) { isReachable in
            if isReachable {
                print("Server is reachable")
                // 서버에 연결 가능한 경우 처리
                let url = "http://182.214.25.240:8080/api/memoir/select"
                let parameters: [String: Any] = [
                    "email": self.email,
                    "date": imageInfo.date
                ]
                
                AF.request(url,
                           method: .get,
                           parameters: parameters,
                           encoding: URLEncoding.default,
                           headers: ["Content-Type":"application/json", "Accept":"application/json"])
                .validate(statusCode: 200..<300)
                .responseJSON { response in
                    /** 서버로부터 받은 데이터 활용 */
                    switch response.result {
                    case .success(let userData):
                        if let json = userData as? [String: Any],
                           let title = json["title"] as? String,
                           let mood = json["mood"] as? String,
                           let comment = json["comment"] as? String,
                           let imgList = json["imgUrl"] as? [String] {
                            nextVC.Dtitle = title
                            nextVC.content = comment
                            nextVC.MoodText = mood
                            let dispatchGroup = DispatchGroup()
                            for imgUrl in imgList {
                                dispatchGroup.enter()
                                print("Image URL: \(imgUrl)")
                                let encodedImgUrl = imgUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                let imgurl2 = "http://182.214.25.240:8080/api/memoir/img/\(self.email)/\(imageInfo.date)/\(encodedImgUrl)"
                                if let imgURL = URL(string: imgurl2) {
                                    self.loadImageFromURL(url: imgURL) { [weak self] image in
                                        guard let self = self, let image = image else {
                                            print("error")
                                            dispatchGroup.leave()
                                            return
                                        }
                                        print("\(image)")
                                        nextVC.images.append(image)
                                        dispatchGroup.leave()
                                    }
                                } else {
                                    dispatchGroup.leave()
                                }
                            }
                            dispatchGroup.notify(queue: .main) {
                                self.present(nextVC, animated: true, completion: nil)
                            }
                        }
                    case .failure(let error):
                        /** 그렇지 않은 경우 */
                        print("error : \(error.errorDescription!)")
                    }
                }
            } else {
                print("Server is unreachable")
                // 서버에 연결 불가능한 경우 처리
                nextVC.Dtitle = imageInfo.title
                nextVC.MoodText = imageInfo.mood
                nextVC.content = imageInfo.content
                nextVC.images.append(imageInfo.img!)
                self.present(nextVC, animated: true, completion: nil)
            }
        }
    }
    
    // 컬렉션 뷰 사이즈 조절
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        let height = collectionView.frame.height
        let itemsPerRow: CGFloat = 2
        let widthPadding = sectionInsets.left * (itemsPerRow + 1)
        let itemsPerColumn: CGFloat = 3
        let heightPadding = sectionInsets.top * (itemsPerColumn + 1)
        let cellWidth = (width - widthPadding) / itemsPerRow
        let cellHeight = (height - heightPadding) / itemsPerColumn
        
        return CGSize(width: cellWidth, height: cellHeight)
        
    }
    // 컬렉션 뷰 마지막
    
    // 서버 체크 : 타임아웃 1초로 걸어둠. 서버만 열려있으면 타이머 무효화 되고 서버랑 연결됨. 그 이상은 너무 느려서 별로였음//
    func checkServerReachability(urlString: String, completion: @escaping (Bool) -> Void) {
        let request = AF.request(urlString)
        
        // 서버 연결 확인을 위한 타이머 설정
        let timeoutInterval: TimeInterval = 1 // 3초로 설정 (원하는 시간으로 변경 가능)
        // 타이머 생성
        let timer = Timer(timeInterval: timeoutInterval, repeats: false) { _ in
            request.cancel() // 요청 취소
        }
        // 타이머를 현재 실행 루프에 추가
        RunLoop.main.add(timer, forMode: .common)
        // 네트워크 요청 수행
        request.response { response in
            timer.invalidate() // 타이머 무효화
            switch response.result {
            case .success(_):
                print("yes")
                completion(true) // 서버에 연결 가능
            case .failure(_):
                print("no")
                completion(false) // 서버에 연결 불가능
            }
        }
    }
}

// 일기 작성 클래스
struct Diary {
    let date: String
    let title: String
    let mood: Mood
    let content: String
}

// 기분 열거형
enum Mood: String {
    case happy = "행복"
    case sad = "슬픔"
    case calm = "우울"
    case angry = "화남"
}

class MypageWrite: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate, UITextViewDelegate{
    
    @IBOutlet weak var Contenttext: UITextView!
    @IBOutlet weak var Titletext: UITextField!
    @IBOutlet weak var Selectimage: UIImageView!
    
    let imagePicker = UIImagePickerController()
    let imageViewModel = ImageViewModel()
    let placeholderText = "내용을 입력하세요."
    
    var DB = DAO.shareInstance()
    var newImage: UIImage? = nil
    var mypageViewController: Mypage?
    var mood: Mood?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Contenttext.delegate = self
        configureTextView()
        hideKeyboard()
        print("다이어리 작성 뷰")
    }
    
    @IBAction func WriteCancle(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func Photobtn(_ sender: UIButton) {
        imagePicker.delegate = self // picker delegate
        imagePicker.sourceType = .photoLibrary // 앨범에서 사진 가져옴
        imagePicker.allowsEditing = true // 수정 가능 여부
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func Happybtn(_ sender: UIButton) {
        self.mood = .happy
        selectAlert(mood: .happy)
    }
    @IBAction func Sadbtn(_ sender: UIButton) {
        self.mood = .sad
        selectAlert(mood: .sad)
    }
    @IBAction func Calmbtn(_ sender: UIButton) {
        self.mood = .calm
        selectAlert(mood: .calm)
    }
    @IBAction func Angrybtn(_ sender: UIButton) {
        self.mood = .angry
        selectAlert(mood: .angry)
    }
    
    @IBAction func WriteDone(_ sender: UIButton) {
        guard let titleText = Titletext.text else {
            showAlert()
            return
        }
        guard let selectedMood = mood else {
            showAlert()
            return
        }
        guard let diaryContent = Contenttext.text else {
            showAlert()
            return
        }
        guard let email = mypageViewController?.email else { return }
        if newImage == nil {
            showAlert()
            return
        }
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let curdate = dateFormatter.string(from: currentDate)
        
        let thisUserDiary = self.DB.GetDiary(email)
        for record in thisUserDiary {
            let date = record.0
            if date == curdate {
                print("이미 오늘 작성함.")
                duplicateAlert()
                return
            }
        }
        
        let serverURL = "http://182.214.25.240:8080/api"
        mypageViewController?.checkServerReachability(urlString: serverURL) { isReachable in
            if isReachable {
                // 서버 열려있을때만 게시글 작성 가능 서버 DB랑 로컬 DB랑 달라지면 안 되기 때문에 보는거는 서버 오프일때 가능
                
                let newDiary = self.writeDiary(title: titleText, mood: selectedMood, content: diaryContent)
                let newImageInfo = ImageInfo(date: newDiary.date, title: newDiary.title, mood: newDiary.mood.rawValue, content: newDiary.content, img: self.newImage)
                
                self.sendTextAndImageToServer(email: email, date: newDiary.date, title: newDiary.title, mood: newDiary.mood.rawValue, comment: newDiary.content, image: self.newImage!)
                self.DB.InsertDiary(email, newDiary.date, newDiary.title, newDiary.mood.rawValue, newDiary.content)
                
                if let mypageVC = self.mypageViewController {
                    mypageVC.viewModel.imageInfoList.append(newImageInfo)
                    mypageVC.reloadCollectionView()
                }
                self.dismiss(animated: true, completion: nil)
            } else {
                print("Server is unreachable")
                /* 테스트용 주석 풀지않기
                let newDiary = self.writeDiary(title: titleText, mood: selectedMood, content: diaryContent)
                let newImageInfo = ImageInfo(date: newDiary.date, title: newDiary.title, mood: newDiary.mood.rawValue, content: newDiary.content, img: self.newImage)
                if let mypageVC = self.mypageViewController {
                    mypageVC.viewModel.imageInfoList.append(newImageInfo)
                    mypageVC.reloadCollectionView()
                }
                self.dismiss(animated: true, completion: nil)
                 */
            }
        }
    }
    
    // 중복 알림
    func duplicateAlert() {
        let alertController = UIAlertController(title: "알림", message: "오늘 다이어리는 이미 작성하셨습니다.", preferredStyle: .alert)
        
        // 테두리 Radius 설정
        alertController.view.layer.cornerRadius = 5.0
        // 알림창 크기 조정
        alertController.preferredContentSize = CGSize(width: 300, height: 150)
        // 알림창 위치 조정
        alertController.modalPresentationStyle = .overCurrentContext
        
        // 알림창이 사라지도록 타이머 설정
        let duration: TimeInterval = 1.5 // 알림창이 보여지는 시간(초) 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alertController.dismiss(animated: true) {
            }
        }
        present(alertController, animated: true, completion: nil)
    }
    
    // 빈 텍스트 알림
    func showAlert() {
        let alertController = UIAlertController(title: "알림", message: "작성하지 않은 부분을 채워주세요.", preferredStyle: .alert)
        
        // 테두리 Radius 설정
        alertController.view.layer.cornerRadius = 5.0
        // 알림창 크기 조정
        alertController.preferredContentSize = CGSize(width: 300, height: 150)
        // 알림창 위치 조정
        alertController.modalPresentationStyle = .overCurrentContext
        
        // 알림창이 사라지도록 타이머 설정
        let duration: TimeInterval = 1.5 // 알림창이 보여지는 시간(초) 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alertController.dismiss(animated: true) {
            }
        }
        present(alertController, animated: true, completion: nil)
    }
    
    // 기분 선택 알림
    func selectAlert(mood: Mood) {
        let alertController = UIAlertController(title: "알림", message: "\(mood.rawValue)을 선택하셨습니다.", preferredStyle: .alert)
        
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
    
    func writeDiary(title: String, mood: Mood, content: String) -> Diary {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: currentDate)
        
        let diary = Diary(date: date, title: title, mood: mood, content: content)
        return diary
    }
    
    // 이미지 선택후 가져오는 부분
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var newImage: UIImage? = nil // update 할 이미지
        
        if let possibleImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            newImage = possibleImage // 수정된 이미지가 있을 경우
        } else if let possibleImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            newImage = possibleImage // 원본 이미지가 있을 경우
        }
        
        Selectimage.image = newImage
        self.newImage = newImage
        picker.dismiss(animated: true, completion: nil) // picker를 닫아줌
    }
    
    // 다이어리 쓴 내용들 이미지랑 함께 서버로 보냄
    func sendTextAndImageToServer(email: String, date: String, title: String, mood: String, comment: String, image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            return
        }
        
        let url = "http://182.214.25.240:8080/api/memoir/saveContent"
        
        let parameters: [String: Any] = [
            "memoirContent": [
                "email": email,
                "date": date,
                "title": title,
                "mood": mood,
                "comment": comment
            ]
        ]
        
        AF.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                if let data = try? JSONSerialization.data(withJSONObject: value) {
                    multipartFormData.append(data, withName: key)
                }
            }
            
            multipartFormData.append(imageData, withName: "image", fileName: "\(date).jpg", mimeType: "image/jpeg")
        }, to: url).response { response in
            switch response.result {
            case .success:
                print("Data uploaded successfully")
            case .failure(let error):
                print("Error uploading data: \(error)")
            }
        }
    }
    
    // placeholder 유사 구현
    // UITextView 설정
    func configureTextView() {
        Contenttext.text = placeholderText
        Contenttext.textColor = UIColor.lightGray
    }
    
    // placeholder 표시
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    // placeholder 복구
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholderText
            textView.textColor = UIColor.lightGray
        }
    }
}

// 일기 작성한거 보여주는 뷰 클래스
class DiaryView: UIViewController, UIScrollViewDelegate{
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var TitleLabel: UILabel!
    @IBOutlet weak var Content: UITextView!
    @IBOutlet weak var MoodLabel: UILabel!
    @IBOutlet weak var ScrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var Diarydate: String?
    var content: String?
    var Dtitle: String?
    var Dimage: UIImage?
    var MoodText: String?
    
    var images = [UIImage]()
    var imageViews = [UIImageView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SetText()
        ScrollView.delegate = self
        addContentScrollView()
        setPageControl()
    }
    
    @IBAction func Close(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func SetText(){
        //옵셔널 바인딩으로 안전하게 값을 꺼낸 뒤 dataLabel의 text로 넣습니다
        if let date = Diarydate,
           let content = content,
           let Dtitle = Dtitle,
           let MoodText = MoodText {
            dateLabel.text = date
            Content.text = content
            TitleLabel.text = Dtitle
            MoodLabel.text = MoodText
        }
    }
    
    private func addContentScrollView() {
        for i in 0..<images.count {
            let imageView = UIImageView()
            let xPos = ScrollView.frame.width * CGFloat(i)
            imageView.frame = CGRect(x: xPos, y: 0, width: ScrollView.bounds.width, height: ScrollView.bounds.height)
            imageView.image = images[i]
            ScrollView.addSubview(imageView)
            ScrollView.contentSize.width = imageView.frame.width * CGFloat(i + 1)
        }
    }
    
    // 페이지 갯수를 이미지 갯수만큼 설정
    private func setPageControl() {
        pageControl.numberOfPages = images.count
    }
    // 현재 선택된 페이지를 파라미터로 받은 currentPage로 설정
    private func setPageControlSelectedPage(currentPage:Int) {
        pageControl.currentPage = currentPage
    }
    // setPageContrrolSelectedPage에 현재 인덱스를 넣어줍니다.
    func scrollViewDidScroll(_ ScrollView: UIScrollView) {
        let value = ScrollView.contentOffset.x/ScrollView.frame.size.width
        setPageControlSelectedPage(currentPage: Int(round(value)))
    }
}

// rect, draw 이용해서 경험치바 생성 클래스
class ExperienceBarView: UIView {
    private let maximumExperience: CGFloat
    private var currentExperience: CGFloat
    
    init(frame: CGRect, maximumExperience: CGFloat, currentExperience: CGFloat) {
        self.maximumExperience = maximumExperience
        self.currentExperience = currentExperience
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 배경을 흰색으로
        let backgroundColor = UIColor.white
        backgroundColor.setFill()
        UIRectFill(rect)
        
        // 경험치 바의 테두리
        let cornerRadius: CGFloat = 5.0 // 테두리의 둥글기 정도를 설정
        let borderPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        let borderColor = UIColor.lightGray
        borderColor.setStroke()
        borderPath.lineWidth = 0.5
        borderPath.stroke()
        
        // 현재 경험치에 대한 바 그림 게이지
        let currentExperienceRatio = currentExperience / maximumExperience
        let barWidth = rect.width * currentExperienceRatio
        let barHeight = rect.height
        let barRect = CGRect(x: 0, y: 0, width: barWidth, height: barHeight)
        let barColor = UIColor.systemYellow
        
        let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: cornerRadius)
        barColor.setFill()
        barPath.fill()
        
        // 배경에 currentExperience 값을 표시
        let text = "\(currentExperience)%"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(x: (rect.width - textSize.width) / 2, y: (rect.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        text.draw(in: textRect, withAttributes: attributes)
    }
    
    func updateExperience(_ newExperience: CGFloat, completion: ((Bool) -> Void)? = nil) {
        if (newExperience >= maximumExperience) {
            currentExperience = 0
            completion?(true) // 완료 클로저 호출하여 100이 되었음을 알림
        } else {
            currentExperience = newExperience
        }
        setNeedsDisplay() // 경험치 바를 다시 그리도록 요청합니다.
    }
}


// 이미지 받아오는 메서드
extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

/*
 func getMbti() {
 let url = "http://182.214.25.240:8080/api/user/userInfo"
 let parameters: [String: Any] = [
 "email": self.email
 ]
 
 AF.request(url,
 method: .get,
 parameters: parameters,
 encoding: URLEncoding.default,
 headers: ["Content-Type":"application/json", "Accept":"application/json"])
 .validate(statusCode: 200..<300)
 .responseJSON { response in
 
 /** 서버로부터 받은 데이터 활용 */
 switch response.result {
 case .success(let userData):
 if let json = userData as? [String: Any],
 let mbti = json["mbti"] as? String {
 print("MBTI: \(mbti)")
 self.mbti.text = "MBTI: \(mbti)"
 }
 case .failure(let error):
 /** 그렇지 않은 경우 */
 print("error : \(error.errorDescription!)")
 }
 }
 }
 */
