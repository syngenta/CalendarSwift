//
//  CalendarView.swift
//  CalendarSwift
//
//  Created by Ievgen Iefimenko on 1/4/19.
//

import UIKit

public protocol MonthViewDelegate: class {
    func didChangeMonth(monthIndex: Int, year: Int)
}

public class MonthView: UIView {
    var monthsArr = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    var currentMonthIndex = 0
    var currentYear: Int = 0
    var delegate: MonthViewDelegate?
    var style = Style()
    
    
    func updateMonthView(selectedDate: Date, df: DateFormatter? = nil) {
        
        let imageRight = self.drawImage(name: "chevronRight.png")
        let imageLeft =  self.drawImage(name: "chevronLeft.png")
        
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
        lblName.text="\(monthsArr[currentMonthIndex].capitalized) \(currentYear)"
        
        self.btnRight.setImage(imageRight, for: .normal)
        self.btnRight.setBackgroundImage(nil, for: .selected)
        self.btnRight.setTitleColor(self.style.monthViewBtnRightColor, for: .normal)
        self.addSubview(btnRight)
        btnRight.topAnchor.constraint(equalTo: topAnchor).isActive=true
        btnRight.rightAnchor.constraint(equalTo: rightAnchor).isActive=true
        btnRight.widthAnchor.constraint(equalToConstant: 70).isActive=true
        btnRight.heightAnchor.constraint(equalTo: heightAnchor).isActive=true
        
        self.btnLeft.setImage(imageLeft, for: .normal)
        self.btnLeft.setTitleColor(self.style.monthViewBtnLeftColor, for: .normal)
        self.addSubview(btnLeft)
        btnLeft.topAnchor.constraint(equalTo: topAnchor).isActive=true
        btnLeft.leftAnchor.constraint(equalTo: leftAnchor).isActive=true
        btnLeft.widthAnchor.constraint(equalToConstant: 70).isActive=true
        btnLeft.heightAnchor.constraint(equalTo: heightAnchor).isActive=true
        
        guard let df = df else {
            return
        }
        self.monthsArr = df.monthSymbols
        lblName.text="\(monthsArr[currentMonthIndex].capitalized) \(currentYear)"
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
    
    class func loadImage(name: String) -> UIImage? {
        let podBundle = Bundle(for: self)
        if let url = podBundle.url(forResource: "CalendarSwift", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return UIImage(named: name, in: bundle, compatibleWith: nil)
        }
        return nil
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
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(btnLeftRightAction(sender:)), for: .touchUpInside)
        btn.tintColor = .lightGray
        btn.imageEdgeInsets.right = -23

        btn.contentHorizontalAlignment = .center
        return btn
    }()
    
    let btnLeft: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(btnLeftRightAction(sender:)), for: .touchUpInside)
        btn.tintColor = .lightGray
        btn.imageEdgeInsets.left = -23
        btn.contentHorizontalAlignment = .center
        return btn
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func drawImage(name: String) -> UIImage {
        let podBundle = Bundle(for: self.classForCoder).bundlePath
        let pathUrl = URL(fileURLWithPath: podBundle).appendingPathComponent(name).path
        let im = UIImage(contentsOfFile: pathUrl)
        return im!
    }
}
