//
//  File.swift
//  
//
//  Created by Evegeny Kalashnikov on 31.10.2023.
//

import UIKit.UIImage

extension UIImage {

    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        .module
        #else
        Bundle(for: CalendarView.self)
        #endif
    }

    static func image(named: String) -> UIImage? {
        Self(named: named, in: bundle, compatibleWith: nil)
    }

    static var chevronLeft: UIImage? { image(named: "chevronLeft") }
    static var chevronRight: UIImage? { image(named: "chevronRight") }
}
