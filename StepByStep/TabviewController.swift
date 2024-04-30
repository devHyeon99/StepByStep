//
//  ViewController.swift
//  StepByStep
//
//  Created by Yune gim on 2023/05/09.
//

import UIKit
import FMDB

class TabviewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        openDB()
        // Do any additional setup after loading the view.
    }
    
    func openDB(){
        let DB : DAO = DAO.shareInstance()
        DB.initData()
        DB.test_DBconnect()
        //DB.delete()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
