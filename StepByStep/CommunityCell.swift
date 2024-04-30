//
//  CommunityCell.swift
//  StepByStep
//
//  Created by 엄현호 on 2023/05/29.
//

import UIKit
import Alamofire

class CommunityCell: UITableViewCell {
    
    @IBOutlet weak var upCount: UILabel!
    @IBOutlet weak var routineTime: UILabel!
    @IBOutlet weak var routineDisc: UILabel!
    @IBOutlet weak var routineName: UILabel!
    @IBOutlet weak var upButton: UIButton!
    
    var count: Int = 0
    var idx: Int = 0
    var isLiked = false
    var postIndex: Int = 0 // Index of the post in the postList array
    
    let DB = DAO.shareInstance()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(with post: Post) {
        idx = post.idx
        if let isLiked = DB.getPostLikedStatus(idx) {
            if isLiked {
                self.isLiked = true
                print("게시물이 좋아요 상태입니다.")
            } else {
                self.isLiked = false
                print("게시물이 좋아요 상태가 아닙니다.")
            }
        } else {
            self.isLiked = false
            print("해당하는 게시물이 존재하지 않습니다.")
        }
        
        let newImage = UIImage(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
        upButton.setImage(newImage, for: .normal)
        upButton.setImage(newImage, for: .highlighted)
        upButton.setImage(newImage, for: .selected)
    }
    
    @IBAction func upBtn(_ sender: Any) {
        isLiked.toggle()
        if isLiked {
            let url = "http://182.214.25.240:8080/api/shareRoutine/shareCountPlus/\(idx)"
            
            let parameters: [String: Any] = [
                "idx": self.idx
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
                    print("좋아요 카운트 플러스 PATCH 성공")
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
            count += 1
            DB.updatePost(idx, isLiked)
        } else {
            let url = "http://182.214.25.240:8080/api/shareRoutine/shareCountMinus/\(idx)"
            
            let parameters: [String: Any] = [
                "idx": self.idx
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
                    print("좋아요 카운트 마이너스 PATCH 성공")
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
            count -= 1
            DB.updatePost(idx, isLiked)
        }
        
        upCount.text = "\(count)"
        
        // 버튼 이미지 변경
        let button = sender as? UIButton
        let newImage = UIImage(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
        button?.setImage(newImage, for: .normal)
        button?.setImage(newImage, for: .highlighted)
        button?.setImage(newImage, for: .selected)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
