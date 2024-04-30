//
//  RoutineTodo.swift
//  StepByStep
//
//  Created by 엄현호 on 2023/06/01.
//

import UIKit
import Charts
import AVFoundation
import Alamofire

class RoutineTodo: UIViewController, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UISheetPresentationControllerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var currentTavleView : Int!
    
    @IBOutlet var DayBtns: [UIButton]!
    @IBOutlet var delBoxShowBtn: UIButton!
    @IBOutlet var addItemBtn: UIButton!
    @IBOutlet weak var chart: PieChartView!
    
    @IBOutlet var RoutineAndTodoTable: UITableView!
    @IBOutlet var RoutineTodoSeg: UISegmentedControl!
    
    var indexOfOneAndOnlySelectedBtn: Int?
    var check = 0
    var delBtnChecked : Bool = false
    
    let mypage = Mypage()
    var DB = DAO.shareInstance()
    var routine : Routine?
    var todos : Todos?
    var imgFromCam : UIImage?
    
    var imgItemName : String?
    
    let serverIP = "http://182.214.25.240:8080/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentTavleView = 0 // 현재 뷰 상태 나타내는 인덱스?
        
        for index in DayBtns.indices {
            DayBtns[index].layer.borderWidth = 0.5
            DayBtns[index].layer.borderColor = UIColor.lightGray.cgColor
            DayBtns[index].circleButton = true
        }
        
        hideKeyboard()
        tableSet()
        RoutineAndTodoTable.delegate = self
        RoutineAndTodoTable.dataSource = self
        
        RoutineAndTodoTable.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("reload")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.getRoutine_reload()
        }
    }
    
    @IBAction func selectDay(_ sender: UIButton) {
        if indexOfOneAndOnlySelectedBtn != nil{
            if !sender.isSelected {
                for unselectIndex in DayBtns.indices {
                    DayBtns[unselectIndex].isSelected = false
                }
                sender.isSelected = true
                indexOfOneAndOnlySelectedBtn = DayBtns.firstIndex(of: sender)
                check = sender.tag
                
            } else {
                sender.isSelected = false
                indexOfOneAndOnlySelectedBtn = nil
                routine = nil
                RoutineAndTodoTable.reloadData()
                check = 0
            }
            
        } else {
            sender.isSelected = true
            indexOfOneAndOnlySelectedBtn = DayBtns.firstIndex(of: sender)
            check = sender.tag
        }
        if(sender.isSelected){
            print("요일 선택됨")
            getRoutine_reload()
        }
        print("dd",sender.isSelected, indexOfOneAndOnlySelectedBtn ?? 0)
        print("check: \(check)")
    }
    
    @IBAction func SwitchRoutuneTodo(_ sender: UISegmentedControl) {
        currentTavleView = sender.selectedSegmentIndex
        getRoutine_reload()
    }
    
    @IBAction func addItemBtnPressed(_ sender: Any) {
        
        if(self.indexOfOneAndOnlySelectedBtn==nil){
            let alert = UIAlertController(title: "알림", message: "요일을 선택하세요", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default) { [self] action in
            })
            self.present(alert, animated: true, completion: nil)
            return
        }
        if(currentTavleView == 0){
            let vc = UIStoryboard(name: "IphoneMain", bundle: nil).instantiateViewController(withIdentifier: "ItemAddPopupView") as! AddItemPopupView
            vc.indexOfOneAndOnlySelectedBtn = self.indexOfOneAndOnlySelectedBtn
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true, completion: nil)
        }else{
            let vc = UIStoryboard(name: "IphoneMain", bundle: nil).instantiateViewController(withIdentifier: "TodoAddPopupView") //as! AddItemPopupView
            //vc.indexOfOneAndOnlySelectedBtn = self.indexOfOneAndOnlySelectedBtn
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func delBoxShowBtnPressed(_ sender: Any) { //셀 삭제박스 활성화
        if(currentTavleView == 0){
            let firstIdx = IndexPath(row: 0, section: 0)
            if(RoutineAndTodoTable.visibleCells.isEmpty ||
               ((RoutineAndTodoTable.cellForRow(at: firstIdx) as! testCell).discLabel.text == "⁉️") ){//삭제불가
                let alert = UIAlertController(title: "알림", message: "삭제할수 있는 항목이 없습니다.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default) { [self] action in
                })
                self.present(alert, animated: true, completion: nil)
                return
            }
            if(delBtnChecked == false){//처음 삭제버튼 클릭
                for cell  in RoutineAndTodoTable.visibleCells {
                    (cell as! testCell).delCehckBox.isHidden = false
                }
                delBtnChecked = true
            }else{//삭제더블체크
                let alert = UIAlertController(title: "알림", message: "정말 삭제하시겠습니까??", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "취소", style: .default) { [self] action in
                    for cell in RoutineAndTodoTable.visibleCells {
                        (cell as! testCell).delCehckBox.isHidden = true
                    }
                })
                alert.addAction(UIAlertAction(title: "확인", style: .default) { [self] action in
                    
                    var idxs : [IndexPath] = .init()
                    for cell in RoutineAndTodoTable.visibleCells{
                        let delCell = (cell as! testCell)
                        if(delCell.delCehckBox.isChecked){
                            let delIdx = RoutineAndTodoTable.indexPath(for: cell)
                            idxs.append(delIdx!)
                            DB.deleteRoutineItem((DayBtns[indexOfOneAndOnlySelectedBtn!].titleLabel?.text)!, delCell.nameLabel.text!, delCell.discLabel.text!)
                            deleteRoutineItemFromServer( (DayBtns[indexOfOneAndOnlySelectedBtn!].titleLabel?.text)!, delCell.nameLabel.text!, delCell.discLabel.text! )
                        }
                    }
                    print("삭제 대상 : ", idxs)
                    for item in idxs{
                        let item = item as IndexPath
                        print("행 : ", item.row)
                        print("섹션 : " , item.section)
                    }
                    
                    
                    for cell  in RoutineAndTodoTable.visibleCells {
                        (cell as! testCell).delCehckBox.isHidden = true
                    }
                    getRoutine_reload()
                    
                })
                self.present(alert, animated: true, completion: nil)
                delBtnChecked = false
            }
            
        }else if(currentTavleView == 1){
            
            let firstIdx = IndexPath(row: 0, section: 0)
            
            if(RoutineAndTodoTable.visibleCells.isEmpty ||
               ((RoutineAndTodoTable.cellForRow(at: firstIdx) as! testCell).discLabel.text == "⁉️") ){//삭제불가
                let alert = UIAlertController(title: "알림", message: "삭제할수 있는 항목이 없습니다.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default) { [self] action in
                })
                self.present(alert, animated: true, completion: nil)
                return
            }
            if(delBtnChecked == false){//처음 삭제버튼 클릭
                for cell  in RoutineAndTodoTable.visibleCells {
                    (cell as! testCell).delCehckBox.isHidden = false
                }
                delBtnChecked = true
            }else{//삭제더블체크
                let alert = UIAlertController(title: "알림", message: "정말 삭제하시겠습니까??", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "취소", style: .default) { [self] action in
                    //취소처리...
                    
                    
                    for cell in RoutineAndTodoTable.visibleCells {
                        (cell as! testCell).delCehckBox.isHidden = true
                    }
                })
                alert.addAction(UIAlertAction(title: "확인", style: .default) { [self] action in
                    
                    var idxs : [IndexPath] = .init()
                    for cell in RoutineAndTodoTable.visibleCells{
                        let delCell = (cell as! testCell)
                        if(delCell.delCehckBox.isChecked){
                            let delIdx = RoutineAndTodoTable.indexPath(for: cell)
                            idxs.append(delIdx!)
                            DB.deleteTodoItem(delCell.nameLabel.text!, delCell.discLabel.text!)
                            deleteTodoItemFromServer(delCell.nameLabel.text!, delCell.discLabel.text!)
                        }
                    }
                    print("삭제 대상 : ", idxs)
                    for item in idxs{
                        let item = item as IndexPath
                        print("행 : ", item.row)
                        print("섹션 : " , item.section)
                    }
                    
                    //RoutuneAndTodoTable.deleteRows(at: idxs, with: .fade)
                    
                    for cell  in RoutineAndTodoTable.visibleCells {
                        (cell as! testCell).delCehckBox.isHidden = true
                    }
                    getRoutine_reload()
                    
                })
                self.present(alert, animated: true, completion: nil)
                delBtnChecked = false
            }
            
            /*
             for cell  in RoutuneAndTodoTable.visibleCells {
             (cell as! testCell).delCehckBox.isHidden = true
             }
             */
        }
        
    }
    
    // 차트 관련
    
    func setChart(dataPoints: [String], values: [Double]) {
        chart.rotationEnabled = false
        chart.highlightPerTapEnabled = false
        chart.noDataText = "날짜를 선택해서 데이터를 불러와주세요."
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry1 = PieChartDataEntry(value: values[i], label: dataPoints[i] , data:  dataPoints[i] as AnyObject)
            dataEntries.append(dataEntry1)
        }
        
        let pieChartDataSet = PieChartDataSet(entries: dataEntries, label: "Units Sold")
        pieChartDataSet.drawValuesEnabled = false
        //pieChartDataSet.valueLinePart1Length = 0.4
        //pieChartDataSet.valueLinePart2Length = 0
        //pieChartDataSet.xValuePosition = .outsideSlice
        pieChartDataSet.valueTextColor = .black
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        
        chart.data = pieChartData
        chart.legend.enabled = false
        
        var colors: [UIColor] = []
        
        for _ in 0..<dataPoints.count {
            let red = Double(arc4random_uniform(156)+100)
            let green = Double(arc4random_uniform(56)+200)
            let blue = 255
            
            let color = UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
            
            colors.append(color)
        }
        
        pieChartDataSet.colors = colors
        
    }
    
    // 테이블뷰 관련 //
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(currentTavleView == 0){
            guard let routine = routine else { return 0}
            
            return routine.routines.count
        }else if(currentTavleView == 1){
            
            guard let todos = todos else { return 0}
            
            return todos.todo.count
        }else{
            
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension // 셀의 높이를 자동으로 계산하도록 설정합니다.
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "testCell") as! testCell
        cell.layer.cornerRadius = 10
        
        if(currentTavleView == 0){
            if let routine = routine{
                cell.nameLabel.text = routine.routines[indexPath.row].itemName
                cell.discLabel.text = routine.routines[indexPath.row].itemDisc
                cell.timeLabel.text = routine.routines[indexPath.row].start + " ~ " + routine.routines[indexPath.row].end
                cell.selectionStyle = .none
                
            }
            
        }else if(currentTavleView == 1){
            
            if let todos = todos{
                cell.nameLabel.text = todos.todo[indexPath.row].todo_name
                cell.discLabel.text = todos.todo[indexPath.row].todo_disc
                
                
                print(todos.todo[indexPath.row].start_date)
                if(todos.todo[indexPath.row].start_date == nil){
                    return cell
                }
                let lastDate = todos.todo[indexPath.row].start_date.toDate(withFormat: "yyyy-MM-dd", "en_US")
                print(lastDate)
                let state = lastDate?.getDateState(fromDate: Date())
                let distance = lastDate?.getDateDistance(fromDate: Date())
                if(distance == "0" ){
                    cell.timeLabel.text = "D" + state! + "day"
                }else{
                    cell.timeLabel.text = "D" + state! + distance!
                }
                cell.selectionStyle = .none
                
            }
        }else{
            
        }
        return cell
        
    }
    
    func tableSet(){
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        RoutineAndTodoTable.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: RoutineAndTodoTable)
            if let indexPath = RoutineAndTodoTable.indexPathForRow(at: touchPoint) {
                let cell = (RoutineAndTodoTable.cellForRow(at: indexPath)) as! testCell
                if(currentTavleView == 0){
                    if(cell.discLabel.text != "⁉️"){
                        //액션시트로 메뉴 띄욱,, 근데 맘에안듬
                        let actionSheetControllerIOS8: UIAlertController = UIAlertController(title: "", message: "Option to select", preferredStyle: .actionSheet)
                        
                        let cancelActionButton = UIAlertAction(title: "완료", style: .default) { [self] _ in
                            print("성공")
                            self.imgItemName = cell.nameLabel.text
                            self.DB.deleteRoutineItem( (DayBtns[indexOfOneAndOnlySelectedBtn!].titleLabel?.text)!,cell.nameLabel.text!, cell.discLabel.text!)
                            self.getRoutine_reload()
                            self.itemDoSuccess()
                        }
                        actionSheetControllerIOS8.addAction(cancelActionButton)
                        
                        let saveActionButton = UIAlertAction(title: "실패", style: .default)
                        { _ in
                            print("실패")
                            self.itemDoFailed(cell)
                        }
                        actionSheetControllerIOS8.addAction(saveActionButton)
                        
                        let deleteActionButton = UIAlertAction(title: "수정", style: .default)
                        { _ in
                            self.itemEdit(cell: cell)
                            print("수정")
                        }
                        actionSheetControllerIOS8.addAction(deleteActionButton)
                        
                        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
                        { _ in
                            print("취소")
                        }
                        actionSheetControllerIOS8.addAction(cancelAction)
                        
                        if UIDevice.current.userInterfaceIdiom == .pad { //디바이스 타입이 iPad일때
                            if let popoverController = actionSheetControllerIOS8.popoverPresentationController {
                                // ActionSheet가 표현되는 위치를 저장해줍니다.
                                popoverController.sourceView = self.view
                                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.height * 4 / 5 , width: 0, height: 0)
                                popoverController.permittedArrowDirections = []
                                self.present(actionSheetControllerIOS8, animated: true, completion: nil)
                            }
                        } else {
                            self.present(actionSheetControllerIOS8, animated: true, completion: nil)
                        }
                        
                        
                        
                    }
                }else if(currentTavleView == 1){
                    if(cell.discLabel.text != "⁉️"){
                        //액션시트로 메뉴 띄욱,, 근데 맘에안듬
                        let actionSheetControllerIOS8: UIAlertController = UIAlertController(title: "", message: "Option to select", preferredStyle: .actionSheet)
                        
                        let cancelActionButton = UIAlertAction(title: "완료", style: .default) { _ in
                            print("투두 성공")
                            self.imgItemName = cell.nameLabel.text
                            let todoItem = self.DB.getTodo(cell.nameLabel.text!, cell.discLabel.text!)
                            self.DB.deleteTodoItem(cell.nameLabel.text!, cell.discLabel.text!)
                            self.deleteTodoItemFromServer(todoItem.todo_name, todoItem.todo_disc)
                            self.getRoutine_reload()
                            var count = UserDefaults.standard.integer(forKey: "투두완료")
                            count += 1
                            UserDefaults.standard.set(count, forKey: "투두완료")
                            UserDefaults.standard.synchronize()
                            self.mypage.expAdd()
                            self.showExpupAlert()
                        }
                        actionSheetControllerIOS8.addAction(cancelActionButton)
                        
                        let saveActionButton = UIAlertAction(title: "실패", style: .default)
                        { _ in
                            print("투두 실패")
                            self.DB.deleteTodoItem(cell.nameLabel.text!, cell.discLabel.text!)
                            self.getRoutine_reload()
                            var count = UserDefaults.standard.integer(forKey: "투두실패")
                            count += 1
                            UserDefaults.standard.set(count, forKey: "투두실패")
                            UserDefaults.standard.synchronize()
                        }
                        actionSheetControllerIOS8.addAction(saveActionButton)
                        
                        let deleteActionButton = UIAlertAction(title: "하루 미루기", style: .default)
                        { _ in
                            self.postponeTodo(cell.nameLabel.text!, cell.discLabel.text!)
                            print("투두 미루기")
                        }
                        actionSheetControllerIOS8.addAction(deleteActionButton)
                        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
                        { _ in
                            print("취소")
                        }
                        actionSheetControllerIOS8.addAction(cancelAction)
                        if UIDevice.current.userInterfaceIdiom == .pad { //디바이스 타입이 iPad일때
                            if let popoverController = actionSheetControllerIOS8.popoverPresentationController {
                                // ActionSheet가 표현되는 위치를 저장해줍니다.
                                popoverController.sourceView = self.view
                                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.height * 4 / 5 , width: 0, height: 0)
                                popoverController.permittedArrowDirections = []
                                self.present(actionSheetControllerIOS8, animated: true, completion: nil)
                            }
                        } else {
                            self.present(actionSheetControllerIOS8, animated: true, completion: nil)
                        }
                        
                        
                        
                    }
                }
                
            }
        }
    }
    
    func showExpupAlert() {
        let alertController = UIAlertController(title: "루틴, 투두 완료보상", message: "EXP+10 획득", preferredStyle: .alert)
        
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
    
    // 이건 뭐지?
    func itemtodata(){
        let calendar = Calendar.current
        let items = DB.getRoutine((DayBtns[indexOfOneAndOnlySelectedBtn!].titleLabel?.text)!).routines
        
        var labels = [String]()
        var datas = [Double]()
        var i = 0
        var space = 0
        var idx = 0
        
        while i <= 1440 {
            if(i == 1440){
                datas.append(Double(space))
                labels.append("")
            }
            if (items[idx].start.toDate(withFormat: "HH:mm") == nil) {
                chart.clear()
                return
            }
            
            let comp = calendar.dateComponents( [.hour, .minute], from: items[idx].start.toDate(withFormat: "HH:mm")!)
            
            let hour = comp.hour ?? 0
            let minute = comp.minute ?? 0
            let finalMinut:Int = (hour * 60) + minute
            
            let comp2 = calendar.dateComponents([.hour, .minute], from: items[idx].end.toDate(withFormat: "HH:mm")!)
            let hour2 = comp2.hour ?? 0
            let minute2 = comp2.minute ?? 0
            let finalMinut2:Int = (hour2 * 60) + minute2
            
            if( i == finalMinut){
                datas.append( Double(space) )
                space = 0
                labels.append("")
                let name = items[idx].itemName
                let desc = items[idx].itemName
                let start = items[idx].start
                let end = items[idx].end
                
                labels.append( name
                               // + "\n" + desc + "\n" + start + "~" + end
                )
                datas.append(Double(finalMinut2 - finalMinut))
                i = finalMinut2
                if( (idx + 1) < items.count){
                    idx += 1
                }
            }
            space += 1
            i += 1
        }
        
        print("labels : ",labels )
        print("datas : ", datas )
        
        setChart(dataPoints: labels, values: datas)
    }
    
    func getRoutine_reload(){
        if let indexOfOneAndOnlySelectedBtn = indexOfOneAndOnlySelectedBtn{
            routine = DB.getRoutine((DayBtns[indexOfOneAndOnlySelectedBtn].titleLabel?.text)!)
            todos = DB.getTodos()
            RoutineAndTodoTable.reloadData()
            itemtodata()
        }
    }
    
    func itemDoSuccess(){
        let day = "\(String(describing: DayBtns[indexOfOneAndOnlySelectedBtn!].titleLabel!.text!))"
        let userDef = UserDefaults.standard
        var count = UserDefaults.standard.integer(forKey: day)
        print(count)
        count += 1
        print(count)
        userDef.set(count, forKey: day)
        userDef.synchronize()
        self.mypage.expAdd()
        self.showExpupAlert()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.2) {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    print("Camera: 권한 허용")
                    self.openCam()
                } else {
                    print("Camera: 권한 거부")
                }
            })
        }
    }
    
    func itemDoFailed( _ cell : testCell){
        DB.deleteRoutineItem((DayBtns[indexOfOneAndOnlySelectedBtn!].titleLabel?.text)! , cell.nameLabel.text!, cell.discLabel.text!)
        self.getRoutine_reload()
    }
    
    func itemEdit(cell : testCell){
        let vc = UIStoryboard(name: "IphoneMain", bundle: nil).instantiateViewController(withIdentifier: "EditItemView") as! EditItemVC
    
        vc.name = cell.nameLabel.text;
        vc.disc = cell.discLabel.text;
        vc.time = cell.timeLabel.text;
        vc.day = (DayBtns[indexOfOneAndOnlySelectedBtn!].titleLabel?.text)!
        
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)
    }
    
    func openCam(){
        DispatchQueue.main.async {
            let camera = UIImagePickerController()
            camera.sourceType = .camera
            camera.allowsEditing = true //정방향으로 편집
            camera.cameraDevice = .rear
            camera.cameraCaptureMode = .photo
            camera.delegate = self
            self.present(camera, animated: true, completion: nil)
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {//사진 찍었을 때
        
        if let image = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerEditedImage")] as? UIImage {
            self.uploadingImg_toServer(image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //사진 캔슬했을 때
        picker.dismiss(animated: true, completion: nil)
    }
    
    // 서버 관련 부분
    
    func postponeTodo(_ todo_name : String, _ todo_disc : String){
        let item = DB.getTodo(todo_name, todo_disc)
        let new_date = Calendar.current.date(byAdding: .day, value: 0, to: item.start_date.toDate(withFormat: "yyyy-MM-dd", "en_US")!)!.toString("yyyy-MM-dd")
        
        DB.updateTodoItem(todo_name, todo_disc, new_date)
        
        updateDate_todoServer(todo_name,todo_disc, item.start_date,item.start_date,todo_name, todo_disc,new_date,new_date)
        self.getRoutine_reload()
    }
    
    func updateDate_todoServer(_ todo_name: String,
    _ todo_disc : String,
    _ end_date: String,
    _ start_date : String,
    _ todo_nameRp : String,
    _ todo_discRp: String,
    _ end_dateRp : String,
    _ start_dateRp : String){
        
        let email:String = UserDefaults.standard.object(forKey: "email") as! String
        let urlString = serverIP+"api/todo/update/" + email
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        //request.httpBody = data
        
        
        let params = [       "todo_name": todo_name,
                             "todo_disc": todo_disc,
                             "end_date": end_date,
                             "start_date": start_date,
                             "todo_nameRp": todo_nameRp,
                             "todo_discRp": todo_discRp,
                             "end_dateRp": end_dateRp,
                             "start_dateRp": start_dateRp ]
        
        
        do {
            try request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
            
            //try request.httpBody?.append(JSONSerialization.data(withJSONObject: params, options: []))
            
        } catch {
            print("http Body Error")
        }
        
        AF.request(request).responseString { (response) in
            switch response.result {
            case .success:
                print("투두 성공")
            case .failure(let error):
                print("error : \(error.errorDescription!)")
            }
        }
    }
    
    func uploadingImg_toServer(_ image : UIImage){
        //Toilet: g160j-1618823856
        //let url = "https://ptsv2.com/t/g160j-1618823856/post"
        let img = image//= UIImage(named: "img")!
        //imageView.image = img
        let data = img.jpegData(compressionQuality: 0.9)
        //let comment = "greeting"
        let email:String = UserDefaults.standard.object(forKey: "email") as! String
        let urlString = serverIP + "api/memoir/save?email=" + email + "&date=" + Date().toString("yyyy-MM-dd") + "&itemName=" + imgItemName!
        
        print("img url String : ", urlString)
        
        let header : HTTPHeaders = [
            "Content-Type" : "multipart/form-data",
        ]
        
        AF.upload(multipartFormData: { multipartFormData in
            do{
                let ImgFile = try data
                multipartFormData.append( ImgFile! ,//AudioFile as Data, // the audio as Data
                                          withName: "image", // nodejs-> multer.single('mp3')
                                          fileName: self.imgItemName! //String.uniqueFilename(withPrefix: "routinr-img") +
                                          + ".jpeg", // name of the file
                                          mimeType: "image/jpeg")
            }catch{
                print("error ocurred")
            }
        }, to: urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!, method: .post, headers: header ).uploadProgress(queue: .main, closure: { progress in
            //Current upload progress of file
            print("Upload Progress: \(progress.fractionCompleted)")
        })
        .responseString { (response) in
            switch response.result {
            case .success:
                print("POST 성공")
            case .failure(let error):
                print("🚫 Alamofire Request Error\nCode:\(error._code), Message: \(error.errorDescription!)")
            }
        }
    }
    
    
    func todoSuccess_toServer(_ todo_name : String, _ todo_disc : String, _ end_date : String, _ start_date : String ){
        
        let email:String = UserDefaults.standard.object(forKey: "email") as! String
        let urlString = serverIP+"api/todo/save/" + email
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        //request.httpBody = data
        
        
        let params = [       "todo_name": todo_name,
                             "todo_disc": todo_disc,
                             "end_date": end_date,
                             "start_date": start_date ]
        
        
        do {
            try request.httpBody = JSONSerialization.data(withJSONObject: [params], options: [])
            
            //try request.httpBody?.append(JSONSerialization.data(withJSONObject: params, options: []))
            
        } catch {
            print("http Body Error")
        }
        
        AF.request(request).responseString { (response) in
            switch response.result {
            case .success:
                print("투두 성공")
            case .failure(let error):
                print("error : \(error.errorDescription!)")
            }
        }
    }
    
    func deleteRoutineItemFromServer(_ day : String, _ name : String, _ disc : String){
        
        let email:String = UserDefaults.standard.object(forKey: "email") as! String
        let urlString = serverIP + "api/routine/delete/" + email
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let params = [  "item_name": name,
                        "item_disc": disc,
                        "day": day]
        
        
        do {
            try request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
            
            //try request.httpBody?.append(JSONSerialization.data(withJSONObject: params, options: []))
            
        } catch {
            print("http Body Error")
        }
        
        AF.request(request).responseString { (response) in
            switch response.result {
            case .success:
                print("루틴 삭제 성공")
            case .failure(let error):
                print("error : \(error.errorDescription!)")
            }
        }
        
    }
    
    func deleteTodoItemFromServer(_ name : String, _ disc : String){
        
        let email:String = UserDefaults.standard.object(forKey: "email") as! String
        let urlString = serverIP + "api/todo/complete/" + email
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let params = [  "todo_name": name,
                        "todo_disc": disc]
        
        
        do {
            try request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
            
            //try request.httpBody?.append(JSONSerialization.data(withJSONObject: params, options: []))
            
        } catch {
            print("http Body Error")
        }
        
        AF.request(request).responseString { (response) in
            switch response.result {
            case .success:
                print("투두 삭제 성공")
            case .failure(let error):
                print("error : \(error.errorDescription!)")
            }
        }
    }
}

extension UIButton {
    var circleButton: Bool {
        set {
            if newValue {
                self.layer.cornerRadius = 0.5 * self.bounds.size.width
                self.clipsToBounds = true
            } else {
                self.layer.cornerRadius = 0
            }
        } get {
            return false
        }
    }
}

class ButtonWithHighlight: UIButton {
    
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            backgroundColor = UIColor.yellow
            super.isHighlighted = newValue
        }
    }
    
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1.0, height: 1.0))
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
        
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(backgroundImage, for: state)
    }
}

/// 체크박스
class CheckBox: UIButton {
    
    /// 체크박스 이미지
    var checkBoxResouces = OnOffResources(
        onImage: UIImage(systemName: DefaultResource.checkedImage),
        offImage: UIImage(systemName: DefaultResource.notCheckedImage)
    ) {
        didSet {
            self.setChecked(isChecked)
        }
    }
    
    enum DefaultResource {
        static let notCheckedImage = "circle"
        static let checkedImage = "checkmark.circle"
    }
    
    /// 체크 상태 변경
    var isChecked: Bool = false {
        didSet {
            guard isChecked != oldValue else { return }
            self.setChecked(isChecked)
        }
    }
    
    /// 이미지 직접 지정 + init
    init(resources: OnOffResources) {
        super.init(frame: .zero)
        self.checkBoxResouces = resources
        commonInit()
    }
    
    /// 일반적인 init + checkBoxResources 변경
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        self.setImage(checkBoxResouces.offImage, for: .normal)
        
        self.addTarget(self, action: #selector(check), for: .touchUpInside)
        self.isChecked = false
    }
    
    @objc func check(_ sender: UIGestureRecognizer) {
        isChecked.toggle()
    }
    
    /// 이미지 변경
    private func setChecked(_ isChecked: Bool) {
        if isChecked == true {
            self.setImage(checkBoxResouces.onImage, for: .normal)
        } else {
            self.setImage(checkBoxResouces.offImage, for: .normal)
        }
    }
    
    class OnOffResources {
        
        let onImage: UIImage?
        let offImage: UIImage?
        
        init(onImage: UIImage?, offImage: UIImage?) {
            self.onImage = onImage
            self.offImage = offImage
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
    public func getDateState(fromDate: Date) -> String {
        var strDateMessage: String = ""
        let result:ComparisonResult = self.compare(fromDate)
        switch result {
        case .orderedAscending:
            strDateMessage = "+"
            break
        case .orderedDescending:
            strDateMessage = "-"
            break
        case .orderedSame:
            strDateMessage = ""
            break
        default:
            strDateMessage = "error"
            break
        }
        return strDateMessage
    }
    
    public func getDateDistance(fromDate : Date) -> String {
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd"
        
        let interval = self.timeIntervalSince(fromDate)
        
        let days = abs(Int(interval / 86400))
        print("\(days) 일 차이 난다") //4일
        
        return String(days)
        
    }
    
}

extension String {
    
    func createRandomStr(length: Int) -> String {
        let str = (0 ..< length).map{ _ in self.randomElement()! }
        return String(str)
    }
    
    /**
     Generates a unique string that can be used as a filename for storing data objects that need to ensure they have a unique filename. It is guranteed to be unique.
     
     - parameter prefix: The prefix of the filename that will be added to every generated string.
     - returns: A string that will consists of a prefix (if available) and a generated unique string.
     */
    static func uniqueFilename(withPrefix prefix: String? = nil) -> String {
        let uniqueString = ProcessInfo.processInfo.globallyUniqueString
        
        if prefix != nil {
            return "\(prefix!)-\(uniqueString)"
        }
        
        return uniqueString
    }
}

