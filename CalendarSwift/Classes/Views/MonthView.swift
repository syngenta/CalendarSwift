//
//  MonthView.swift
//  myCalender2
//
//  Created by Muskan on 10/22/17.
//  Copyright © 2017 akhil. All rights reserved.
//

import UIKit

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

