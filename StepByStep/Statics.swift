//
//  Statics.swift
//  StepByStep
//
//  Created by 엄현호 on 2023/06/08.
//

import UIKit
import Charts

class Statics: UIViewController {
    
    @IBOutlet weak var todoCount: UILabel!
    @IBOutlet weak var totalCount: UILabel!
    @IBOutlet weak var myBarChartView: BarChartView!
    
    // 구분값
    var dayData: [String] = ["월", "화", "수", "목", "금", "토", "일"]
    // 데이터
    var priceData: [Int]! = [UserDefaults.standard.integer(forKey: "월"), UserDefaults.standard.integer(forKey: "화"), UserDefaults.standard.integer(forKey: "수"), UserDefaults.standard.integer(forKey: "목"), UserDefaults.standard.integer(forKey: "금"), UserDefaults.standard.integer(forKey: "토"), UserDefaults.standard.integer(forKey: "일")]
    
    let userDef = UserDefaults.standard
    var DB = DAO.shareInstance()

    override func viewDidLoad() {
        super.viewDidLoad()
        setChart()
        setCount()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        priceData = [
            userDef.integer(forKey: "월"),
            userDef.integer(forKey: "화"),
            userDef.integer(forKey: "수"),
            userDef.integer(forKey: "목"),
            userDef.integer(forKey: "금"),
            userDef.integer(forKey: "토"),
            userDef.integer(forKey: "일")
        ]
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.reloadChart()
            self.setCount()
        }
    }
    
    func setCount() {
        self.totalCount.text = "미완료 루틴 목록 \n\n월: \(DB.countRoutines("월"))     화: \(DB.countRoutines("화"))     수: \(DB.countRoutines("수"))     목: \(DB.countRoutines("목"))     금: \(DB.countRoutines("금"))     토: \(DB.countRoutines("토"))     일: \(DB.countRoutines("일"))"
        let todoItemCount = DB.countTodoItems()
        let sucess = userDef.integer(forKey: "투두완료")
        let fail = userDef.integer(forKey: "투두실패")
        self.todoCount.text = "미완료: \(todoItemCount)    완료: \(sucess)    실패: \(fail)"
    }
    // 그래프 리로드
    func reloadChart() {
        // 생성한 함수 사용해서 데이터 적용
        self.setBarData(barChartView: self.myBarChartView, barChartDataEntries: self.entryData(values: self.priceData))
    }
    
    func setChart() {
        // 더블클릭 불가
        self.myBarChartView.doubleTapToZoomEnabled = false
        // 선택 불가
        self.myBarChartView.highlightPerTapEnabled = false
        // 기본 문구
        self.myBarChartView.noDataText = "출력 데이터가 없습니다."
        // 기본 문구 폰트
        self.myBarChartView.noDataFont = .systemFont(ofSize: 20)
        // 기본 문구 색상
        self.myBarChartView.noDataTextColor = .lightGray
        // 차트 기본 뒷 배경색
        self.myBarChartView.backgroundColor = .white
        // 구분값 보이기
        self.myBarChartView.xAxis.labelPosition = .bottom
        self.myBarChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: dayData)
        // 구분값 모두 보이기
        self.myBarChartView.xAxis.setLabelCount(priceData.count, force: false)
        // 범례 삭제
        self.myBarChartView.legend.enabled = false
        // 생성한 함수 사용해서 데이터 적용
        self.setBarData(barChartView: self.myBarChartView, barChartDataEntries: self.entryData(values: self.priceData))
        
        // 뒤에 배경 다 삭제
        self.myBarChartView.rightAxis.enabled = false
        self.myBarChartView.leftAxis.enabled = false
        self.myBarChartView.drawBordersEnabled = false
        self.myBarChartView.xAxis.drawGridLinesEnabled = false
        self.myBarChartView.leftAxis.drawAxisLineEnabled = false
        self.myBarChartView.xAxis.drawAxisLineEnabled = false
    }
    // 데이터셋 만들고 차트에 적용하기
    func setBarData(barChartView: BarChartView, barChartDataEntries: [BarChartDataEntry]) {
        // 데이터 셋 만들기
        let barChartdataSet = BarChartDataSet(entries: barChartDataEntries, label: "")
        barChartdataSet.colors = [UIColor.systemYellow]
        
        // 차트 데이터 만들기
        let barChartData = BarChartData(dataSet: barChartdataSet)
        
        // 데이터 차트에 적용
        barChartView.data = barChartData
    }
    
    // entry 만들기
    func entryData(values: [Int]) -> [BarChartDataEntry] {
        var barDataEntries: [BarChartDataEntry] = []
        for i in 0..<values.count {
            let value = Int(values[i]) // 소수점 이하 자릿수 없이 정수로 변환
            let barDataEntry = BarChartDataEntry(x: Double(i), y: Double(value))
            barDataEntries.append(barDataEntry)
        }
        return barDataEntries
    }
}
