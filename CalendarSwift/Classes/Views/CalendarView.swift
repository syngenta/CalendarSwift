//
//  CalendarView.swift
//  CalendarSwift
//
//  Created by Ievgen Iefimenko on 1/4/19.
//

import UIKit

public struct Style {
    public var monthViewBackgroundColor = UIColor.white
    public var monthViewBtnRightColor = UIColor.black
    public var monthViewBtnLeftColor = UIColor.black
    public var monthViewTitleColor = UIColor.black
    public var bgColor = UIColor.white
    public var activeCellLblColor = UIColor.black
    public var activeCellLblColorHighlighted = UIColor.white
    public var notActiveCellLblColor = UIColor.white
    public var indicatorCellColor = UIColor(red: 23/255, green: 174/255, blue: 123/255, alpha: 1.0)
    public var weekdaysLblColor = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1.0)
    public var weekdaysBackgroundColor = UIColor.white
    
    public var yearBackgroundColor = UIColor.white
    public var yearSelectedColor = UIColor.black
    public var yearDeselectedColor = UIColor.black
    
    public var switcherBackgroundColor = UIColor.white
    public var switcherIndicatorColor = UIColor(red: 23/255, green: 174/255, blue: 123/255, alpha: 1.0)
    public var switcherNormalTitleColor = UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1.0)
    public var switcherSelectedTitleColor = UIColor.white
    public var switcherIndicatorWidth: CGFloat = 150
    
    public var monthTitleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    public var weekDaysFont = UIFont.systemFont(ofSize: 12, weight: .medium)
    public var monthDaysFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    public var yearSelectedFont = UIFont.systemFont(ofSize: 26, weight: .medium)
    public var yearUnselectedFont = UIFont.systemFont(ofSize: 20)
    public var switcherTitleFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    
    public var language = "en"
}

public protocol CalendarViewDelegate: class {
    
    func calendarDateChanged(date: Date)
    func calendarContentHeightChanged(height: CGFloat)
}

public extension CalendarViewDelegate {
    
    func calendarDateChanged(date: Date) {}
    func calendarContentHeightChanged(height: CGFloat) {}
}

public class CalendarView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public var minYear = 1970
    public var maxYear = Date().year + 100
    public var style = Style()
    public var selectedDate = Date()
    public var selectedYearDelay: Double = 0.0
    public weak var delegate: CalendarViewDelegate?
    
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
    private var timer = Timer()
    private var needCallDelegate = false
    private let cellHeight: CGFloat = 44
    private let cellSpacing: CGFloat = 8.0
    private let daysInWeek: CGFloat = 7.0
    private var calendarHeight: CGFloat {
        let weeksCount = (CGFloat(itemsCount) / daysInWeek).rounded(.awayFromZero)
        let collectionHeight = cellHeight * weeksCount + cellSpacing * weeksCount
        return myCollectionView.frame.minY + collectionHeight
    }
    private var itemsCount: Int {
        guard numOfDaysInMonth.count > currentMonthIndex-1 else {
            return 0
        }
        return numOfDaysInMonth[currentMonthIndex-1] + firstWeekDayOfMonth - 1
    }
    
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
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.delegate?.calendarContentHeightChanged(height: calendarHeight)
    }
    
    @objc public func rotated() {
        DispatchQueue.main.async { [weak self] in
            self?.myCollectionView.reloadData()
        }
    }
    
    public func setupCalendar() {
        self.setUpSettings()
        self.selectDate(date: self.selectedDate)
        self.setupViews()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsCount
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

        let today = Date()
        if self.currentYear == today.year && self.currentMonthIndex == today.month {
            let cellFullDate = "\(self.currentYear)-\(self.currentMonthIndex)-\(calcDate)".date
            if DateFormatter().calendar.compare(cellFullDate, to: today, toGranularity: .day) == .orderedSame {
                cell.lbl.textColor = needSelect ? self.style.activeCellLblColorHighlighted : self.style.indicatorCellColor
            }
        }
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
        if self.needCallDelegate {
            self.delegate?.calendarDateChanged(date: newDate)
        }
        self.needCallDelegate = true
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
        let width = collectionView.frame.width / daysInWeek
        return CGSize(width: width, height: cellHeight)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    private func getFirstWeekDay() -> Int {
        let firstMonthDate = "\(self.currentYear)-\(self.currentMonthIndex)-01".self.date.firstDayOfTheMonth
        let dayFormatted = self.df.calendar.weekDay(date: firstMonthDate)
        let dayStandart = self.df.calendar.weekdayStandart(date: firstMonthDate)
        self.isSundayFirst = dayFormatted == dayStandart
        
        return dayFormatted
    }
    
    private func setupViews() {
        
        self.segmenView = ScrollSegmentView()
        self.segmenView?.language = "\(self.style.language.prefix(2))"
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
        segmenView.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor, constant: 15).isActive = true
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
        monthView.topAnchor.constraint(equalTo: segmenView.bottomAnchor, constant: 8).isActive = true
        monthView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        monthView.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
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
        weekdaysView.topAnchor.constraint(equalTo: monthView.bottomAnchor, constant: 8).isActive = true
        weekdaysView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        weekdaysView.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
        weekdaysView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        
        self.addSubview(self.myCollectionView)
        self.myCollectionView.topAnchor.constraint(equalTo: weekdaysView.bottomAnchor, constant: 15).isActive = true
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

extension CalendarView: MonthViewDelegate {
    
    public func didChangeMonth(monthIndex: Int, year: Int) {
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
        self.delegate?.calendarContentHeightChanged(height: calendarHeight)
        self.validateMinMaxDate()
        if self.presentMonthIndex == self.currentMonthIndex, self.currentYear == self.presentYear {
            self.needCallDelegate = false
            self.selectDate(date: self.selectedDate)
        }
    }
}

extension CalendarView: ScrollSegmentDelegate {
    
    func segmentSelected(index: Int) {
        self.timer.invalidate()
        if index == 0 {
            if self.currentYear != self.presentYear {
                self.needCallDelegate = false
                self.selectDate(date: self.selectedDate)
            }
            UIView.animate(withDuration: 0.2, animations: {
                self.pickerView.alpha = 0.0
            }) { (finished) in
                self.pickerView.removeFromSuperview()
            }
        } else {
            
            guard let segmenView = self.segmenView else {
                return
            }
            self.pickerView.alpha = 0.0
            self.pickerView.backgroundColor = self.style.yearBackgroundColor
            
            self.addSubview(self.pickerView)
            UIView.animate(withDuration: 0.2) {
                self.pickerView.alpha = 1.0
            }
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
}

extension CalendarView: UIPickerViewDelegate, UIPickerViewDataSource {
    
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
        pickerView.subviews.forEach { if $0.subviews.count == 0 { $0.isHidden = true } }
        pickerLabel.textAlignment = .center
        return pickerLabel
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.timer.invalidate()
        var counter = 0
        let calendar = Calendar.current
        let dateComponents: DateComponents? = calendar.dateComponents([.year, .month, .day], from: self.selectedDate)
        
        guard let year = Int(self.yearsArray[row]), var dc = dateComponents else {
            return
        }
        dc.year = year
        guard let newDate: Date = calendar.date(from: dc), self.presentYear != year else {
            return
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: self.selectedYearDelay, repeats: true) { [weak self] (timer) in
            counter += 1
            if counter > 1 {
                self?.selectedDate = newDate
                self?.presentYear = year
                self?.delegate?.calendarDateChanged(date: newDate)
                pickerView.reloadAllComponents()
                self?.timer.invalidate()
            }
        }
    }
}
