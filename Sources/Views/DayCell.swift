//
//  DayCell.swift
//  CalendarSwift
//
//  Created by Ievgen Iefimenko on 1/4/19.
//

import UIKit

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
