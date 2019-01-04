//
//  ViewController.swift
//  CalendarSwift
//
//  Created by raketenok@gmail.com on 01/04/2019.
//  Copyright (c) 2019 raketenok@gmail.com. All rights reserved.
//

import UIKit


class ViewController: UIViewController, CalendarViewDelegate1 {

    
    
    @IBOutlet weak var calendar: CalendarView1!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.calendar.style.language = "uk"
        self.calendar.delegate = self
        self.calendar.setupCalendar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func calendarDateChanged(date: Date) {
        print(date)
    }

}




public struct Style {
    var monthViewBackgroundColor = UIColor.white
    var monthViewBtnRightColor = UIColor.black
    var monthViewBtnLeftColor = UIColor.black
    var monthViewTitleColor = UIColor.black
    
    var bgColor = UIColor.white
    var activeCellLblColor = UIColor.black
    var activeCellLblColorHighlighted = UIColor.white
    var notActiveCellLblColor = UIColor.white
    var indicatorCellColor = UIColor.lightGray
    
    var weekdaysLblColor = UIColor.black
    var weekdaysBackgroundColor = UIColor.white
    
    var yearBackgroundColor = UIColor.white
    var yearSelectedColor = UIColor.black
    var yearDeselectedColor = UIColor.black
    
    var switcherBackgroundColor = UIColor.white
    var switcherIndicatorColor = UIColor(white: 0.95, alpha: 1)
    var switcherNormalTitleColor = UIColor.lightGray
    var switcherSelectedTitleColor = UIColor.darkGray
    var switcherIndicatorWidth: CGFloat = 150
    
    var monthTitleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    var weekDaysFont = UIFont.systemFont(ofSize: 12, weight: .medium)
    var monthDaysFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    var yearSelectedFont = UIFont.systemFont(ofSize: 26, weight: .medium)
    var yearUnselectedFont = UIFont.systemFont(ofSize: 20)
    var switcherTitleFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    
    var language = "en"
}

public protocol CalendarViewDelegate1: class {
    
    func calendarDateChanged(date: Date)
}


public class CalendarView1: UIView , UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public var minYear = 1970
    public var maxYear = Date().year + 100
    public var style = Style()
    public var selectedDate = Date()
    public weak var delegate: CalendarViewDelegate1?
    
    private var numOfDaysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31]
    private var currentMonthIndex: Int = 0
    private var currentYear: Int = 0
    private var presentMonthIndex = 0
    private var presentYear = 0
    private var todaysDate = 0
    private var firstWeekDayOfMonth = 0   //(Sunday-Saturday 1-7)
    private var yearsArray = [String]()
    private var segmenView: ScrollSegmentView?
    private var monthView: MonthView?
    private var weekdaysView: WeekdaysView?
    private let pickerView = UIPickerView()
    private var selectedIndexPath = IndexPath()
    private var isSundayFirst = true
    private var df = DateFormatter()
    
    let myCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let myCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        myCollectionView.showsHorizontalScrollIndicator = false
        myCollectionView.translatesAutoresizingMaskIntoConstraints = false
        myCollectionView.backgroundColor = UIColor.clear
        myCollectionView.allowsMultipleSelection = false
        return myCollectionView
    }()
    
    //MARK:- life cycle
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public func setupCalendar() {
        self.setUpSettings()
        self.selectDate(date: self.selectedDate)
        self.setupViews()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.numOfDaysInMonth[self.currentMonthIndex-1] + self.firstWeekDayOfMonth - 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! DayCell
        cell.backgroundColor = UIColor.clear
        cell.lbl.font = self.style.monthDaysFont
        cell.lbl.textColor = self.style.activeCellLblColor
        
        guard indexPath.item > self.firstWeekDayOfMonth - 2 else {
            cell.isHidden=true
            return cell
        }
        
        let calcDate = indexPath.row - self.firstWeekDayOfMonth + 2
        cell.isHidden = false
        cell.lbl.text = "\(calcDate)"
        let needSelect = self.selectedIndexPath == indexPath && self.currentMonthIndex == self.presentMonthIndex && self.presentYear == self.currentYear
        cell.lbl.textColor = needSelect ? self.style.activeCellLblColorHighlighted : self.style.activeCellLblColor
        cell.selectedIndicator.backgroundColor = needSelect ? self.style.indicatorCellColor : .clear
        
        return cell
    }
    
    private func setUpSettings() {
        
        self.backgroundColor = self.style.bgColor
        self.df.locale = Locale(identifier: self.style.language)
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        self.myCollectionView.delegate = self
        self.myCollectionView.dataSource = self
        self.myCollectionView.register(DayCell.self, forCellWithReuseIdentifier: "Cell")
        self.yearsArray.removeAll()
        
        for i in self.minYear...self.maxYear {
            self.yearsArray.append("\(i)")
        }
        
        if Bundle.main.path(forResource: self.style.language, ofType: "lproj") != nil {
            Bundle.setLanguage(self.style.language)
        } else {
            Bundle.setLanguage("en")
        }
    
    }
    
    private func initializeView() {
        self.currentMonthIndex = Calendar.current.component(.month, from: self.selectedDate)
        self.currentYear = Calendar.current.component(.year, from: self.selectedDate)
        self.todaysDate = Calendar.current.component(.day, from: self.selectedDate)
        self.firstWeekDayOfMonth = self.getFirstWeekDay()
        
        //for leap years, make february month of 29 days
        if self.currentMonthIndex == 2 && self.currentYear % 4 == 0 {
            self.numOfDaysInMonth[self.currentMonthIndex-1] = 29
        }
        //end
        self.presentMonthIndex = self.currentMonthIndex
        self.presentYear = self.currentYear
    }
    
    private func selectDate(date: Date) {
        self.myCollectionView.reloadData()
        self.selectedDate = date
        self.initializeView()
        self.monthView?.updateMonthView(selectedDate: self.selectedDate)
        self.validateMinMaxDate()
        let indexPath = IndexPath(item: self.firstWeekDayOfMonth + self.todaysDate - 2, section: 0)
        self.myCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.collectionView(self.myCollectionView, didSelectItemAt: indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
        guard let cell = collectionView.cellForItem(at: indexPath) as? DayCell else {
            return
        }
        cell.lbl.textColor = self.style.activeCellLblColorHighlighted
        cell.selectedIndicator.backgroundColor = self.style.indicatorCellColor
        let selectedDay = -(self.firstWeekDayOfMonth - indexPath.item - 1) + 1
        let newDate = "\(self.currentYear)-\(self.currentMonthIndex)-\(selectedDay)".date
        self.presentMonthIndex = self.currentMonthIndex
        self.presentYear = self.currentYear
        self.selectedDate = newDate
        self.selectedIndexPath = indexPath
        self.delegate?.calendarDateChanged(date: newDate)
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? DayCell else {
            return
        }
        cell.selectedIndicator.backgroundColor = .clear
        cell.backgroundColor = UIColor.clear
        cell.lbl.textColor = self.style.activeCellLblColor
        collectionView.reloadData()
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width/7 - 8
        let height: CGFloat = 44
        return CGSize(width: width, height: height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
    
    private func getFirstWeekDay() -> Int {
        let firstMonthDate = "\(self.currentYear)-\(self.currentMonthIndex)-01".self.date.firstDayOfTheMonth
        let dayFormatted = firstMonthDate.weekday
        let dayStandart = firstMonthDate.weekdayStandart
        self.isSundayFirst = dayFormatted == dayStandart
        
        return dayFormatted
    }
    
    private func setupViews() {
        
        self.segmenView = ScrollSegmentView()
        guard let segmenView = self.segmenView else {
            return
        }
        segmenView.backgroundColor = self.style.switcherBackgroundColor
        segmenView.style.indicatorColor = self.style.switcherIndicatorColor
        segmenView.style.normalTitleColor = self.style.switcherNormalTitleColor
        segmenView.style.selectedTitleColor = self.style.switcherSelectedTitleColor
        segmenView.style.selectedIndicatorWidth = self.style.switcherIndicatorWidth
        segmenView.style.titleFont = self.style.switcherTitleFont
        
        segmenView.translatesAutoresizingMaskIntoConstraints = false
        segmenView.setupViews()
        self.addSubview(segmenView)
        segmenView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor, constant: 20).isActive = true
        segmenView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        segmenView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        segmenView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        segmenView.delegate = self
        
        self.monthView = MonthView()
        guard let monthView = self.monthView else {
            return
        }
        monthView.style = self.style
        monthView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(monthView)
        monthView.topAnchor.constraint(equalTo: segmenView.bottomAnchor, constant: 10).isActive = true
        monthView.leftAnchor.constraint(equalTo: self.layoutMarginsGuide.leftAnchor, constant: 21).isActive = true
        monthView.rightAnchor.constraint(equalTo: self.layoutMarginsGuide.rightAnchor, constant: -21).isActive = true
        monthView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        monthView.delegate = self
        monthView.updateMonthView(selectedDate: self.selectedDate, df: self.df)
        
        self.weekdaysView = WeekdaysView()
        guard let weekdaysView = weekdaysView else {
            return
        }
        weekdaysView.style = self.style
        weekdaysView.translatesAutoresizingMaskIntoConstraints = false
        weekdaysView.setupViews(isSundayFirst: self.isSundayFirst, df: self.df)
        self.addSubview(weekdaysView)
        weekdaysView.topAnchor.constraint(equalTo: monthView.bottomAnchor, constant: 10).isActive = true
        weekdaysView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        weekdaysView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
        weekdaysView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        
        self.addSubview(self.myCollectionView)
        self.myCollectionView.topAnchor.constraint(equalTo: weekdaysView.bottomAnchor, constant: 20).isActive = true
        self.myCollectionView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        self.myCollectionView.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
        self.myCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    fileprivate func validateMinMaxDate() {
        
        var leftEnable = false
        var rightEnable = false
        
        if self.currentYear >= self.minYear {
            leftEnable = true
            if self.currentMonthIndex == 1, self.currentYear == self.minYear {
                leftEnable = false
            }
        }
        if self.currentYear <= maxYear {
            rightEnable = true
            if self.currentMonthIndex == 12, self.currentYear == self.maxYear {
                rightEnable = false
            }
        }
        self.monthView?.btnLeft.isEnabled = leftEnable
        self.monthView?.btnRight.isEnabled = rightEnable
    }
    
}

extension CalendarView1: MonthViewDelegate {
    
    func didChangeMonth(monthIndex: Int, year: Int) {
        self.currentMonthIndex = monthIndex + 1
        self.currentYear = year
        
        //for leap year, make february month of 29 days
        if monthIndex == 1 {
            if self.currentYear % 4 == 0 {
                self.numOfDaysInMonth[monthIndex] = 29
            } else {
                self.numOfDaysInMonth[monthIndex] = 28
            }
        }
        //end
        self.firstWeekDayOfMonth = getFirstWeekDay()
        self.myCollectionView.reloadData()
        self.validateMinMaxDate()
        if self.presentMonthIndex == self.currentMonthIndex, self.currentYear == self.presentYear {
            self.selectDate(date: self.selectedDate)
        }
    }
}

extension CalendarView1: ScrollSegmentDelegate {
    
    func segmentSelected(index: Int) {
        if index == 0 {
            self.selectDate(date: self.selectedDate)
            self.pickerView.removeFromSuperview()
        } else {
            
            guard let segmenView = self.segmenView else {
                return
            }
            self.pickerView.backgroundColor = self.style.yearBackgroundColor
            self.addSubview(self.pickerView)
            self.pickerView.topAnchor.constraint(equalTo: segmenView.bottomAnchor, constant: 0).isActive = true
            self.pickerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            self.pickerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            self.pickerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            self.pickerView.translatesAutoresizingMaskIntoConstraints = false
            for (index, year) in self.yearsArray.enumerated() {
                if let yearInt = Int(year), yearInt == self.currentYear {
                    self.pickerView.selectRow(index, inComponent: 0, animated: false)
                    return
                }
            }
        }
    }
    
    func scrollSegmentsLoaded() {
        
    }
}

extension CalendarView1: UIPickerViewDelegate, UIPickerViewDataSource {
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return  1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.yearsArray.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let pickerLabel = UILabel()
        guard self.yearsArray.count > row else {
            return pickerLabel
        }
        
        if self.yearsArray[row] == "\(self.presentYear)" {
            pickerLabel.attributedText = NSAttributedString(string: self.yearsArray[row], attributes: [NSAttributedStringKey.font: self.style.yearSelectedFont, NSAttributedStringKey.foregroundColor: self.style.yearSelectedColor])
        } else {
            pickerLabel.attributedText = NSAttributedString(string: self.yearsArray[row], attributes: [NSAttributedStringKey.font: self.style.yearUnselectedFont, NSAttributedStringKey.foregroundColor: self.style.yearDeselectedColor])
        }
        pickerView.subviews[1].isHidden = true
        pickerView.subviews[2].isHidden = true
        pickerLabel.textAlignment = .center
        return pickerLabel
    }
    
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let calendar = Calendar.current
        let dateComponents: DateComponents? = calendar.dateComponents([.year, .month, .day], from: self.selectedDate)
        
        guard let year = Int(self.yearsArray[row]), var dc = dateComponents else {
            return
        }
        dc.year = year
        guard let newDate: Date = calendar.date(from: dc)  else {
            return
        }
        self.selectedDate = newDate
        self.presentYear = year
        self.delegate?.calendarDateChanged(date: newDate)
        pickerView.reloadAllComponents()
    }
}


class WeekdaysView: UIView {
    
    var style = Style()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    func setupViews(isSundayFirst: Bool, df: DateFormatter) {
        self.backgroundColor = self.style.weekdaysBackgroundColor
        addSubview(myStackView)
        myStackView.topAnchor.constraint(equalTo: topAnchor).isActive=true
        myStackView.leftAnchor.constraint(equalTo: leftAnchor).isActive=true
        myStackView.rightAnchor.constraint(equalTo: rightAnchor).isActive=true
        myStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive=true
        
        let weekdays = df.veryShortWeekdaySymbols
        var formattedWeekdays = weekdays
        
        if !isSundayFirst {
            let sunday = weekdays!.first
            formattedWeekdays!.remove(at: 0)
            formattedWeekdays!.append(sunday!)
        }
        
        for i in 0..<7 {
            let lbl = UILabel()
            lbl.text = formattedWeekdays![i]
            lbl.textAlignment = .center
            lbl.font = self.style.weekDaysFont
            lbl.textColor = self.style.weekdaysLblColor
            myStackView.addArrangedSubview(lbl)
        }
    }
    
    let myStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DayCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        self.setupViews()
    }
    
    func setupViews() {
        
        self.selectedIndicator.layer.masksToBounds = true
        self.selectedIndicator.layer.cornerRadius = self.frame.size.height / 2
        self.selectedIndicator.backgroundColor = .clear
        self.selectedIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(self.selectedIndicator)
        
        self.selectedIndicator.widthAnchor.constraint(equalToConstant: self.frame.size.height).isActive = true
        self.selectedIndicator.heightAnchor.constraint(equalToConstant: self.frame.size.height).isActive = true
        self.selectedIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.selectedIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        addSubview(self.lbl)
        self.lbl.topAnchor.constraint(equalTo: topAnchor).isActive = true
        self.lbl.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        self.lbl.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        self.lbl.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    
    var selectedIndicator = UIView()
    
    
    let lbl: UILabel = {
        let label = UILabel()
        label.text = "00"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



struct ScrollSegmentStyle {
    
    public var indicatorColor = UIColor(white: 0.95, alpha: 1)
    public var titlePendingHorizontal: CGFloat = 15
    public var titlePendingVertical: CGFloat = 14
    public var titleFont = UIFont.boldSystemFont(ofSize: 14)
    public var normalTitleColor = UIColor.lightGray
    public var selectedTitleColor = UIColor.darkGray
    public var selectedIndicatorWidth: CGFloat = 150
    public init() {}
}

protocol ScrollSegmentDelegate: class {
    func segmentSelected(index: Int)
    func scrollSegmentsLoaded()
}

class ScrollSegmentView: UIControl {
    
    public weak var delegate: ScrollSegmentDelegate?
    
    public var style = {
        return ScrollSegmentStyle()
    }()
    
    public var titles = {
        return [NSLocalizedString("date", comment: ""), NSLocalizedString("year", comment: "")]
    }()
    
    private var titleLabels: [UILabel] = []
    private var constraintIndWidth = NSLayoutConstraint()
    private var constraintIndLeft = NSLayoutConstraint()
    
    public private(set) var selectedIndex = 0
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        view.bounces = true
        view.isPagingEnabled = false
        view.scrollsToTop = false
        view.contentInset = UIEdgeInsets.zero
        view.contentOffset = CGPoint.zero
        view.scrollsToTop = false
        return view
    }()
    
    private var indicator: UIView = {
        let ind = UIView()
        ind.translatesAutoresizingMaskIntoConstraints = false
        ind.layer.masksToBounds = true
        return ind
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    @objc private func rotated() {
        DispatchQueue.main.async { [weak self] in
            guard let self_ = self else {
                return
            }
            self?.setIndicatorFrame(indexLabel: self_.selectedIndex)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        let segmentsStack = UIStackView()
        segmentsStack.translatesAutoresizingMaskIntoConstraints = false
        segmentsStack.translatesAutoresizingMaskIntoConstraints = false
        segmentsStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        segmentsStack.isLayoutMarginsRelativeArrangement = true
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.scrollView)
        let topConstraint =  self.scrollView.topAnchor.constraint(equalTo: self.topAnchor)
        let leftConstraint =  self.scrollView.leftAnchor.constraint(equalTo: self.leftAnchor)
        let rightConstraint =  self.scrollView.rightAnchor.constraint(equalTo: self.rightAnchor)
        let bottomConstraint =  self.scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        
        self.scrollView.addSubview(self.indicator)
        self.scrollView.addSubview(segmentsStack)
        let h = segmentsStack.heightAnchor.constraint(equalTo: self.scrollView.heightAnchor)
        let centerY = segmentsStack.centerYAnchor.constraint(equalTo: self.scrollView.centerYAnchor)
        let topConstraint1 = segmentsStack.topAnchor.constraint(equalTo: self.scrollView.topAnchor)
        let leftConstraint1 = segmentsStack.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor)
        let rightConstraint1 = segmentsStack.rightAnchor.constraint(equalTo: self.scrollView.rightAnchor)
        let bottomConstraint1 = segmentsStack.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor)
        NSLayoutConstraint.activate([topConstraint, leftConstraint, rightConstraint, bottomConstraint, topConstraint1, leftConstraint1, rightConstraint1, bottomConstraint1, h, centerY])
        
        guard self.titles.count > 0  else {
            return
        }
        // Set titles
        let font = self.style.titleFont
        
        let coverH: CGFloat = font.lineHeight + self.style.titlePendingVertical
        segmentsStack.axis = .horizontal
        segmentsStack.spacing = self.style.titlePendingHorizontal
        segmentsStack.alignment = .fill
        segmentsStack.distribution = .fillEqually
        segmentsStack.spacing = self.style.titlePendingHorizontal
        self.scrollView.isScrollEnabled = false
        self.indicator.backgroundColor = self.style.indicatorColor
        for (index, title) in self.titles.enumerated() {
            let backLabel = UILabel()
            backLabel.text = title
            backLabel.tag = index
            backLabel.text = title
            backLabel.textColor = self.style.normalTitleColor
            backLabel.font = self.style.titleFont
            backLabel.textAlignment = .center
            self.titleLabels.append(backLabel)
            segmentsStack.addArrangedSubview(backLabel)
        }
        
        let coverX = self.titleLabels[selectedIndex].frame.origin.x
        let coverW = self.titleLabels[selectedIndex].frame.size.width
        
        self.constraintIndWidth = NSLayoutConstraint(item: self.indicator,
                                                     attribute: .width,
                                                     relatedBy: .lessThanOrEqual,
                                                     toItem: nil,
                                                     attribute: .notAnAttribute,
                                                     multiplier: 1,
                                                     constant: coverW)
        
        self.constraintIndLeft = NSLayoutConstraint(item: self.indicator,
                                                    attribute: .leading,
                                                    relatedBy: .equal,
                                                    toItem: self.scrollView,
                                                    attribute: .leading,
                                                    multiplier: 1,
                                                    constant: coverX)
        NSLayoutConstraint(item: self.indicator,
                           attribute: .height,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1,
                           constant: coverH).isActive = true
        self.indicator.centerYAnchor.constraint(equalTo: self.scrollView.centerYAnchor).isActive = true
        self.constraintIndWidth.isActive = true
        self.constraintIndLeft.isActive = true
        self.indicator.layer.cornerRadius = coverH/2
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScrollSegmentView.handleTapGesture(_:)))
        self.addGestureRecognizer(tapGesture)
        segmentsStack.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        DispatchQueue.main.async {
            self.setSelectIndex(index: 0, animated: false)
            self.delegate?.scrollSegmentsLoaded()
        }
    }
    
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let x = gesture.location(in: self).x + scrollView.contentOffset.x
        for (i, label) in titleLabels.enumerated() {
            if x >= label.frame.minX && x <= label.frame.maxX {
                if self.selectedIndex != i {
                    self.delegate?.segmentSelected(index: i)
                }
                setSelectIndex(index: i, animated: true)
                sendActions(for: UIControl.Event.valueChanged)
                break
            }
        }
    }
    
    public func setSelectIndex(index: Int, animated: Bool = true) {
        
        guard index >= 0 , index < titleLabels.count else { return }
        self.selectedIndex = index
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.setIndicatorFrame(indexLabel: index)
                self.layoutIfNeeded()
            })
        } else {
            self.setIndicatorFrame(indexLabel: index)
            self.layoutIfNeeded()
        }
        self.scrollView.frame = self.bounds
    }
    
    private func setIndicatorFrame( indexLabel: Int) {
        
        let currentLabel = titleLabels[indexLabel]
        let leftInset = currentLabel.center.x - self.style.selectedIndicatorWidth/2
        self.constraintIndWidth.constant = self.style.selectedIndicatorWidth
        self.constraintIndLeft.constant = leftInset
        self.indicator.center.y = currentLabel.center.y
        for (index, label) in self.titleLabels.enumerated() {
            label.textColor = index == indexLabel ? style.selectedTitleColor : style.normalTitleColor
        }
    }
}


protocol MonthViewDelegate: class {
    func didChangeMonth(monthIndex: Int, year: Int)
}

class MonthView: UIView {
    var monthsArr = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    var currentMonthIndex = 0
    var currentYear: Int = 0
    var delegate: MonthViewDelegate?
    var style = Style()
    
    func updateMonthView(selectedDate: Date, df: DateFormatter? = nil) {
        
        self.currentMonthIndex = Calendar.current.component(.month, from: selectedDate) - 1
        self.currentYear = Calendar.current.component(.year, from: selectedDate)
        
        self.backgroundColor = self.style.monthViewBackgroundColor
        self.lblName.textColor = self.style.monthViewTitleColor
        self.lblName.font = self.style.monthTitleFont
        self.addSubview(lblName)
        lblName.topAnchor.constraint(equalTo: topAnchor).isActive = true
        lblName.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        lblName.widthAnchor.constraint(equalToConstant: 150).isActive = true
        lblName.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        lblName.text="\(monthsArr[currentMonthIndex]) \(currentYear)"
        
        self.btnRight.setTitleColor(self.style.monthViewBtnRightColor, for: .normal)
        self.addSubview(btnRight)
        btnRight.topAnchor.constraint(equalTo: topAnchor).isActive=true
        btnRight.rightAnchor.constraint(equalTo: rightAnchor).isActive=true
        btnRight.widthAnchor.constraint(equalToConstant: 50).isActive=true
        btnRight.heightAnchor.constraint(equalTo: heightAnchor).isActive=true
        
        self.btnLeft.setTitleColor(self.style.monthViewBtnLeftColor, for: .normal)
        self.addSubview(btnLeft)
        btnLeft.topAnchor.constraint(equalTo: topAnchor).isActive=true
        btnLeft.leftAnchor.constraint(equalTo: leftAnchor).isActive=true
        btnLeft.widthAnchor.constraint(equalToConstant: 50).isActive=true
        btnLeft.heightAnchor.constraint(equalTo: heightAnchor).isActive=true
        
        guard let df = df else {
            return
        }
        self.monthsArr = df.monthSymbols
        lblName.text="\(monthsArr[currentMonthIndex]) \(currentYear)"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor=UIColor.clear
    }
    
    @objc private func btnLeftRightAction(sender: UIButton) {
        if sender == btnRight {
            currentMonthIndex += 1
            if currentMonthIndex > 11 {
                currentMonthIndex = 0
                currentYear += 1
            }
        } else {
            currentMonthIndex -= 1
            if currentMonthIndex < 0 {
                currentMonthIndex = 11
                currentYear -= 1
            }
        }
        lblName.text="\(monthsArr[currentMonthIndex].capitalized) \(currentYear)"
        delegate?.didChangeMonth(monthIndex: currentMonthIndex, year: currentYear)
    }
    
    
    let lblName: UILabel = {
        let lbl = UILabel()
        lbl.text = "Default Month Year text"
        lbl.textAlignment = .center
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    let btnRight: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "chevronRight"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(btnLeftRightAction(sender:)), for: .touchUpInside)
        btn.tintColor = .lightGray
        btn.contentHorizontalAlignment = .right
        return btn
    }()
    
    let btnLeft: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "chevronLeft"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(btnLeftRightAction(sender:)), for: .touchUpInside)
        btn.tintColor = .lightGray
        btn.contentHorizontalAlignment = .left
        return btn
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


public extension Date {
    var weekday: Int {
        
        let calendar = Calendar.current
        var dayOfWeek = calendar.component(.weekday, from: self) + 1 - calendar.firstWeekday
        if dayOfWeek <= 0 {
            dayOfWeek += 7
        }
        return dayOfWeek
    }
    
    var weekdayStandart: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    
    var firstDayOfTheMonth: Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year,.month], from: self))!
    }
    
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
}

//get date from string
public extension String {
    
    var date: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-DD"
        return formatter.date(from: self)!
    }
}


public var bundleKey: UInt8 = 0

public class AnyLanguageBundle: Bundle {
    
    override public func localizedString(forKey key: String,
                                  value: String?,
                                  table tableName: String?) -> String {
        
        guard let path = objc_getAssociatedObject(self, &bundleKey) as? String,
            let bundle = Bundle(path: path) else {
                
                return super.localizedString(forKey: key, value: value, table: tableName)
        }
        
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

public extension Bundle {
    
    class func setLanguage(_ language: String) {
        
        defer {
            
            object_setClass(Bundle.main, AnyLanguageBundle.self)
        }
        
        objc_setAssociatedObject(Bundle.main, &bundleKey, Bundle.main.path(forResource: language, ofType: "lproj"), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
}
