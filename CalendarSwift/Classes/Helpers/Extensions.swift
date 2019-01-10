//
//  Extensions.swift
//  CalendarSwift
//
//  Created by Ievgen Iefimenko on 1/4/19.
//

import UIKit


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
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self)!
    }
}



