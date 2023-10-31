//
//  Extensions.swift
//  CalendarSwift
//
//  Created by Ievgen Iefimenko on 1/4/19.
//

import UIKit

public extension Date {

    var firstDayOfTheMonth: Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year,.month], from: self))!
    }
    
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
}

public extension Calendar {
    
    func weekDay(date: Date) -> Int {
        
        var dayOfWeek = self.component(.weekday, from: date) + 1 - self.firstWeekday
        if dayOfWeek <= 0 {
            dayOfWeek += 7
        }
        return dayOfWeek
    }

    func weekdayStandart(date: Date) -> Int {
        return self.component(.weekday, from: date)
    }
    
}

//get date from string
public extension String {
    
    var date: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self)
    }
}



