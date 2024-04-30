import UIKit
import DropDown
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser
import KakaoSDKShare
import Alamofire

class MBTIQuestion {
    let text: String
    let answers: [String]
    var selectedAnswer: Int?
    
    init(text: String, answers: [String]) {
        self.text = text
        self.answers = answers
    }
}

class iPhoneController: UIViewController {
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answer1Button: UIButton!
    @IBOutlet weak var answer2Button: UIButton!
    @IBOutlet weak var TextMbti: UITextField!
    
    var DB = DAO.shareInstance()
    var questions: [MBTIQuestion] = []
    var questionIndex: Int = 0
    var selectedAnswers: [Int] = []
    
    let dropDown = DropDown()
    let itemList = ["ISTJ", "ISFJ", "INFJ", "INTJ", "ISTP", "ISFP","INFP","INTP",
                    "ESTP","ESFP","ENFP","ENTP","ESTJ","ESFJ","ENFJ","ENTJ"]
    var email: String = ""
    var profile: String = ""
    var name: String = ""
    var mbti: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(view)
        }
        initUI()
        setDropdown()
        hideKeyboard()
        
        questions = [
            MBTIQuestion(text: "당신은 어디서 에너지를 더 충전하나요?", answers: ["사람들과 어울리며", "혼자 있는 곳에서"]),
            MBTIQuestion(text: "새로운 사람들과 어울릴 때 어떤 선호도가 있나요?", answers: ["적극적으로 말을 걸어요", "기다리다가 다른 사람이 말을 걸어요"]),
            MBTIQuestion(text: "결정을 내릴 때 어떤 기준을 따라 결정하시나요?", answers: ["논리적인 이유를 따져서", "감정적인 기준을 따라서"]),
            MBTIQuestion(text: "평소에 어떤 유형의 책이나 TV 프로그램을 좋아하나요?", answers: ["과학, 기술, 역사 등 학문적인 것", "예술, 감성, 문학 등 예술적인 것"]),
            MBTIQuestion(text: "새로운 아이디어가 생겼을 때 나는?", answers: ["현재 진행 중인 일에 충실해야 한다고 생각한다", "새로운 아이디어에 대해 호기심이 생긴다"]),
            MBTIQuestion(text: "당신이 다른 사람들과 대화할 때 주로 어떤 방식으로 이끌어 나가나요?", answers: ["내가 말하는 주제에 대해 깊이 있게 이야기한다", "상대방의 의견을 듣고 이야기하는 데 집중한다"]),
            MBTIQuestion(text: "일을 처리하는 방식에 있어서 어떤 유형이 좋은가요?", answers: ["계획적으로 처리하는 것", "즉흥적으로 처리하는 것"]),
            MBTIQuestion(text: "새로운 환경에서 어떤 태도를 보이시나요?", answers: ["호기심이 많아 적극적으로 탐험한다", "조금 더 신중한 태도를 보인다"]),
            MBTIQuestion(text: "문제 해결에 있어서 나는?", answers: ["보통 상황에 적용할 수 있는 원리를 찾는다", "특별한 방법으로 접근한다"]),
            MBTIQuestion(text: "당신이 어떤 음악을 좋아하나요?", answers: ["원래 좋아하는 장르나 가수의 음악을 듣는다", "새로운 음악을 탐색하며 다양한 장르를 즐긴다"]),
            MBTIQuestion(text: "계획을 수립할 때 나는?", answers: ["미리 계획을 세워 실행한다", "상황에 따라 적응하며 융통성 있게 대처한다"])
        ]
        
        showQuestion()
    }
    
    func showQuestion() {
        guard let question = questions[safe: questionIndex],
              let questionLabel = questionLabel,
              let answer1Button = answer1Button,
              let answer2Button = answer2Button else {
            return
        }
        questionLabel.text = question.text
        answer1Button.setTitle(question.answers[0], for: .normal)
        answer2Button.setTitle(question.answers[1], for: .normal)
    }
    
    
    @IBAction func answer1Tapped(_ sender: UIButton) {
        questions[questionIndex].selectedAnswer = 0
        nextQuestion()
    }
    
    @IBAction func answer2Tapped(_ sender: UIButton) {
        questions[questionIndex].selectedAnswer = 1
        nextQuestion()
    }
    
    func nextQuestion() {
        selectedAnswers.append(questions[questionIndex].selectedAnswer!)
        questionIndex += 1
        
        if questionIndex < questions.count {
            showQuestion()
        } else {
            // 모든 질문에 대한 답변을 선택한 경우 결과 확인 버튼을 활성화합니다.
            questionLabel.text = "검사가 종료되었습니다.\n원래 화면으로 돌아가 MBTI를 선택해주세요."
            answer1Button.isEnabled = false
            answer2Button.isEnabled = false
            
            // MBTI 검사 결과 계산
            let result = calculateResult()
            let alertController = UIAlertController(title: "알림", message: "당신의 성격 유형은 \(result)입니다.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // MBTI 검사 결과 계산 함수
    func calculateResult() -> String {
        var answers = [Int](repeating: 0, count: 8)
        for question in questions {
            if let selectedAnswer = question.selectedAnswer {
                if question.text.contains("어디서 에너지를 더 충전하나요?") {
                    answers[selectedAnswer] += 1
                } else if question.text.contains("새로운 사람들과 어울릴 때 어떤 선호도가 있나요?") {
                    answers[selectedAnswer] += 1
                } else if question.text.contains("결정을 내릴 때 어떤 기준을 따라 결정하시나요?") {
                    answers[selectedAnswer + 4] += 1
                } else if question.text.contains("평소에 어떤 유형의 책이나 TV 프로그램을 좋아하나요?") {
                    answers[selectedAnswer + 2] += 1
                } else if question.text.contains("새로운 아이디어가 생겼을 때 나는?") {
                    answers[selectedAnswer + 2] += 1
                } else if question.text.contains("당신이 다른 사람들과 대화할 때 주로 어떤 방식으로 이끌어 나가나요?") {
                    answers[selectedAnswer + 4] += 1
                } else if question.text.contains("일을 처리하는 방식에 있어서 어떤 유형이 좋은가요?") {
                    answers[selectedAnswer + 6] += 1
                } else if question.text.contains("새로운 환경에서 어떤 태도를 보이시나요?") {
                    answers[selectedAnswer + 6] += 1
                } else if question.text.contains("문제 해결에 있어서 나는?") {
                    answers[selectedAnswer + 4] += 1
                } else if question.text.contains("당신이 어떤 음악을 좋아하나요?") {
                    answers[selectedAnswer + 2] += 1
                } else if question.text.contains("계획을 수립할 때 나는?") {
                    answers[selectedAnswer + 6] += 1
                }
            }
        }
        
        var result = ""
        if answers[0] >= answers[1] {
            result += "E"
        } else {
            result += "I"
        }
        
        if answers[2] >= answers[3] {
            result += "S"
        } else {
            result += "N"
        }
        
        if answers[4] >= answers[5] {
            result += "T"
        } else {
            result += "F"
        }
        
        if answers[6] >= answers[7] {
            result += "J"
        } else {
            result += "P"
        }
        
        return result
    }
    
    
    // Drop Down 부분
    @IBAction func dropbt(_ sender: UIButton) {
        dropDown.show()
    }
    
    // DropDown UI 커스텀
    func initUI() {
        DropDown.appearance().textColor = UIColor.black // 아이템 텍스트 색상
        DropDown.appearance().selectedTextColor = UIColor.red // 선택된 아이템 텍스트 색상
        DropDown.appearance().backgroundColor = UIColor.white // 아이템 팝업 배경 색상
        DropDown.appearance().selectionBackgroundColor = UIColor.lightGray // 선택한 아이템 배경 색상
        DropDown.appearance().setupCornerRadius(8)
        dropDown.dismissMode = .automatic // 팝업을 닫을 모드 설정
        if let textMbti = TextMbti {
            textMbti.isUserInteractionEnabled = false
            textMbti.text = "선택해주세요."
            TextMbti.tintColor = UIColor.gray
        } // 힌트 텍스트
    }
    
    // 드롭다운박스 아이템 리스트 연결 및 처리하는 부분
    func setDropdown() {
        // dataSource로 ItemList를 연결
        dropDown.dataSource = itemList
        
        // anchorView를 통해 UI와 연결
        dropDown.anchorView = self.TextMbti
        
        // View를 갖리지 않고 View아래에 Item 팝업이 붙도록 설정
        if let TextMbti = TextMbti{
            dropDown.bottomOffset = CGPoint(x: 0, y: -dropDown.anchorView!.plainView.bounds.height)
            // Item 선택 시 처리
            dropDown.selectionAction = { [weak self] (index, item) in
                //선택한 Item을 TextField에 넣어준다.
                self!.TextMbti.text = item
            }
        }
    }
    
    @IBAction func MbtiSubmit(_ sender: UIButton) {
        if let mbti = TextMbti.text, mbti != "선택해주세요." {
            print("MBTI를 \(mbti)로 선택하셨습니다.")
            DB.InsertUser(email,profile,name,mbti,"1","0.0")
            self.sendUser(email,profile,name,mbti,"1","0.0") // 서버로 유저 정보 전송
            let storyboard = UIStoryboard(name: "IphoneMain", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainStoryboard")
            tabBarController.modalPresentationStyle = .fullScreen
            self.present(tabBarController, animated: false, completion: nil)
        } else {
            let alertController = UIAlertController(title: "알림", message: "MBTI를 선택해주세요.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    // DropDown 부분 끝
    
    @IBAction func Loginbt(_ sender: UIButton) {
        kakaoLogin()
    }
    
    // 카카오톡 로그인 부분
    func kakaoLogin(){
        if (AuthApi.hasToken()) {
            UserApi.shared.accessTokenInfo { (accessTokenInfo , error) in
                if let error = error {
                    if let sdkError = error as? SdkError, sdkError.isInvalidTokenError() == true  {
                        //로그인 필요
                        self.kakaoLoginWithKakaoAcc()
                    }
                    else {
                        //기타 에러
                    }
                }
                else {
                    print("이미 로그인 하셨습니다")
                    let storyboard = UIStoryboard(name: "IphoneMain", bundle: nil)
                    let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainStoryboard")
                    tabBarController.modalPresentationStyle = .fullScreen
                    self.present(tabBarController, animated: false, completion: nil)
                }
            }
        }
        else {
            //로그인 필요
            print("첫 로그인")
            self.kakaoLoginWithKakaoAcc()
        }
    }
    
    // 카카오 로그인 화면창 생기면서 로그인 시작 부분
    func kakaoLoginWithKakaoAcc(){
        UserApi.shared.loginWithKakaoAccount {(oauthToken, error) in
            if let error = error {
                print(error)
            }
            else {
                print("loginWithKakaoAccount() success.")
                //do something
                _ = oauthToken
                self.registAcc()
            }
        }
    }
    
    // 로그인 완료하고 유저 정보 가져온다음 MBTI화면으로 넘어가는 부분
    func registAcc(){
        print("registAcc")
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print(error)
            }
            else {
                print("me() success.")
                
                //do something
                _ = user
                if let userProfile = user?.kakaoAccount?.profile?.profileImageUrl,
                   let userEmail = user?.kakaoAccount?.email,
                   let userNickname = user?.kakaoAccount?.profile?.nickname{
                    print("userProfile",userProfile)
                    print("userEmail",userEmail)
                    print("userNickname",userNickname) // 닉네임?
                    self.email = userEmail
                    self.profile = userProfile.absoluteString
                    self.name = userNickname
                    let userDefaults = UserDefaults.standard
                    userDefaults.set(self.email, forKey: "email")
                    userDefaults.set(self.name, forKey: "name")
                    userDefaults.set(self.profile, forKey: "profile")
                    userDefaults.synchronize()
                }
                
                // 비동기적으로 실행하도록 예약 0.5초 뒤에.. 데이터가 제대로 안 넘겨지는거 같아서 추가
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let storyboard = UIStoryboard(name: "IphoneMain", bundle: nil)
                    let viewController = storyboard.instantiateViewController(withIdentifier: "MbtiStoryboard") as! iPhoneController
                    viewController.email = self.email
                    viewController.profile = self.profile
                    viewController.name = self.name
                    viewController.modalPresentationStyle = .fullScreen
                    self.present(viewController, animated: false, completion: nil)
                    
                }
            }
        }
    }
    
    /**
     url : 먼저 첫 번째 파라미터로 요청할 url을 담는다.
     method : 어떤 request method를 사용할 것인지를 나타낸다.
     parameters : POST 메서드와 같이 request body를 사용할 때 전달할 값을 담는다.
     encoding : 인코딩 방식을 정한다.
     headers : 부가적인 정보를 나타낸다. 위에서는 송/수신 데이터 타입(JSON)을 나타낸다.
     validate : 유효성을 검사한다. state code 값이 20x일 때가 송/수신이 원활하게 된 경우.
     responseJSON : 응답 json 데이터이다.
     **/
    // 승철이 서버로 이메일이랑 프로필 주소 보내는거 테스트 부분?
    func sendUser(_ email : String, _ profileImg : String, _ name : String, _ mbti : String, _ level : String, _ exp : String){
        let urlString = "http://182.214.25.240:8080/"
        var request = URLRequest(url: URL(string: urlString+"api/user/SignUp")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        // POST 로 보낼 정보
        let params = [ "email" : email, "name" : name, "imgUrl" : profileImg, "mbti" : mbti, "level" : level, "exp" : exp]
        
        // httpBody 에 parameters 추가
        do {
            try request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            print("http Body Error")
        }
        AF.request(request).responseString { (response) in
            switch response.result {
            case .success:
                print("POST 성공")
            case .failure(let error):
                print("error : \(error.errorDescription!)")
            }
        }
    }
    
    // 뭐하는 부분이지?
    @IBAction func press_service_out(_ sender: Any) {
        
        UserApi.shared.unlink {(error) in
            if let error = error {
                print(error)
            }
            else {
                print("unlink() success.")
            }
        }
    }
    // 카톡 로그인 마지막
    
    func getEmail(completion: @escaping (String) -> Void) {
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print(error)
            }
            else {
                let userEmail = user?.kakaoAccount?.email
                self.email = userEmail!
                completion(self.email)
            }
        }
    }
    func getUser(completion: @escaping (String, String, String) -> Void) {
        UserApi.shared.me() {(user, error) in
            if let error = error {
                print(error)
            }
            else {
                let userEmail = user?.kakaoAccount?.email
                let userNickname = user?.kakaoAccount?.profile?.nickname
                let userProfile = user?.kakaoAccount?.profile?.profileImageUrl
                self.profile = userProfile!.absoluteString
                self.name = userNickname!
                self.email = userEmail!
                completion(self.email, self.profile, self.name)
            }
        }
    }
}

// Object 테두리 설정할 수 있도록 Inspectable 시키는 부분
extension UIView {
    @IBInspectable var borderColor: UIColor {
        get {
            let color = self.layer.borderColor ?? UIColor.clear.cgColor
            return UIColor(cgColor: color)
        }
        
        set {
            self.layer.borderColor = newValue.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        
        set {
            self.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        
        set {
            self.layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var shadowRadius : CGFloat {
        //그림자의 퍼짐정도
        get{
            return self.layer.shadowRadius
        }
        
        
        set{
            self.layer.shadowRadius = newValue
        }
        
    }
    
    @IBInspectable var shadowOpacity : Float {
        //그림자의 투명도 0 - 1 사이의 값을 가짐
        get{
            return self.layer.shadowOpacity
        }
        
        set{
            self.layer.shadowOpacity = newValue
        }
        
    }
    
    @IBInspectable var shadowColor : UIColor {
        //그림자의 색
        get{
            if let shadowColor = self.layer.shadowColor {
                return UIColor(cgColor: shadowColor)
            }
            return UIColor.clear
        }
        set{
            //그림자의 색이 지정됬을 경우
            self.layer.shadowOffset = CGSize(width: 0, height: 0)
            //shadowOffset은 빛의 위치를 지정해준다. 북쪽에 있으면 남쪽으로 그림지가 생기는 것
            self.layer.shadowColor = newValue.cgColor
            //그림자의 색을 지정
        }
        
    }
    
    @IBInspectable var maskToBound : Bool{
        
        get{
            return self.layer.masksToBounds
        }
        
        set{
            self.layer.masksToBounds = newValue
        }
        
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

