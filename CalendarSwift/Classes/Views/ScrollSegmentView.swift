//
//  ScrollSegmentView.swift
//  CalendarSwift
//
//  Created by Ievgen Iefimenko on 12/12/18.

import UIKit

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
