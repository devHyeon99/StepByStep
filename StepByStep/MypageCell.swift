//
//  MypageCell.swift
//  StepByStep
//
//  Created by 엄현호 on 2023/05/15.
//
// http://yoonbumtae.com/?p=3418 참고

import UIKit

struct ImageInfo {
    let date: String
    var title: String
    var mood: String
    var content: String
    var img: UIImage?
    
    init(date: String, title: String, mood: String, content: String, img: UIImage?) {
        self.date = date
        self.title = title
        self.mood = mood
        self.content = content
        self.img = img
    }
}

class MypageCell: UICollectionViewCell {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    func update(info: ImageInfo) {
        imgView.image = info.img
        dateLabel.text = info.date
    }
}

class ImageViewModel {
    var imageInfoList: [ImageInfo] = [
        //ImageInfo(date: "2023-05-12", title: "", mood: "", content: "", img: UIImage(named: "2023-05-12.jpeg")),
        //ImageInfo(date: "2023-05-15", title: "Title 2", mood: "Sad", content: "Content 2", img: UIImage(named: "2023-05-12.jpeg"))
    ]
    
    var countOfImageList: Int {
        return imageInfoList.count
    }
    
    func imageInfo(at index: Int) -> ImageInfo {
        return imageInfoList[index]
    }
}
