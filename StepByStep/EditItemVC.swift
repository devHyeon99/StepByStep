//
//  EditItemVC.swift
//  StepByStep
//
//  Created by Yune gim on 2023/05/21.
//

import UIKit
import Alamofire
import KakaoSDKUser

class EditItemVC: UIViewController {

    
    let serverIP = "http://182.214.25.240:8080/"

    var name : String!
    var disc : String!
    var time : String!
    var day : String!
    let DB = DAO.shareInstance()

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var discTextField: UITextField!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var endTimePicker: UIDatePicker!
    
    @IBOutlet weak var editCompetBtn: UIButton!
    @IBOutlet weak var editCancelBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboard()
        nameTextField.text = name
        discTextField.text = disc
        let time = time!.split(separator: "~")
        if let start = time[0].description.toDate(withFormat: "HH:mm"), let end = time[1].description.toDate(withFormat: "HH:mm"){
            startTimePicker.date = start
            endTimePicker.date = end
        }

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func completBtnPressed(_ sender: Any) {
        if let nameRp = nameTextField.text, let discRp = discTextField.text{
            DB.updateRoutineItem(day, name, disc, nameRp, discRp , startTimePicker.toString(), endTimePicker.toString())
            postTest(name, disc, day, nameRp, discRp , startTimePicker.toString(), endTimePicker.toString() )
            
//              "item_name": "string",
//            "item_disc": "string",
//            "day": "string",
//            "item_nameRp": "string",
//            "item_discRp": "string",
//            "startRp": "string",
//            "endRp": "string"
        }
        dismiss(animated: true)
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    func postTest(_ item_name : String, _ item_disc : String, _ day : String, _ item_nameRp : String, _ item_discRp : String, _ startRp : String, _ endRp : String ){
        
        //let urlString = "http://10.2.12.85:8080/"
        let email:String = UserDefaults.standard.object(forKey: "email") as! String
        let urlString = serverIP+"api/routine/update/" + email
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        //request.httpBody = data
        
        
        let params = [   "item_name": item_name,
                         "item_disc": item_disc,
                         "day": day,
                         "item_nameRp": item_nameRp,
                         "item_discRp": item_discRp,
                         "startRp": startRp,
                         "endRp": endRp ]
        
        
        do {
            try request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
            
            //try request.httpBody?.append(JSONSerialization.data(withJSONObject: params, options: []))
            
        } catch {
            print("http Body Error")
        }
        
        AF.request(request).responseString { (response) in
            switch response.result {
            case .success:
                print("루틴 변경 성공")
            case .failure(let error):
                print("error : \(error.errorDescription!)")
            }
        }
        
        
        
//        UserApi.shared.me() {(user, error) in
//            if let error = error {
//                print(error)
//            }
//            else {
//                print("me() success.")
//
//                //do something
//                _ = user
//                if let userProfile = user?.kakaoAccount?.profile?.profileImageUrl,
//                   let userEmail = user?.kakaoAccount?.email{
//                    let parameters = ["userID" : userEmail]
//
//                    print("userProfile",userProfile)
//                    print("userEmail",userEmail)
//
//                        AF.request(urlString,
//                                   method: .post,
//                                   parameters: parameters
//                        ).responseString { (response) in
//                            /*
//                             switch response.result {
//                             case .success:
//                             print("POST 성공")
//                             case .failure(let error):
//                             print("error : \(error.errorDescription!)")
//                             }
//                             */
//                            if let JsonParsedData = response.value{
//                                //self.posts = JsonParsedData
//                                print("json result : ", JsonParsedData)
//                                //self.FeedTable.reloadData()
//                            }
//
//                        }
//
//
//                    //self.postTest(profileImg: userProfile, email: userEmail)
//                }
//
//            }
//        }
    }
    
    
    

}

extension String {
    
    func toDate(withFormat format: String = "HH:mm",_ locale : String = "ko_KR")-> Date?{

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: locale)
        dateFormatter.calendar = Calendar(identifier: .gregorian )
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(abbreviation: "KST")

        guard let date = dateFormatter.date(from: self) else{
            return Date()
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: date)


    }
    
    
}
