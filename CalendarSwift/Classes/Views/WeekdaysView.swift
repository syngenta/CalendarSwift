//
//  CalendarView.swift
//  CalendarSwift
//
//  Created by Ievgen Iefimenko on 1/4/19.
//
import UIKit

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
