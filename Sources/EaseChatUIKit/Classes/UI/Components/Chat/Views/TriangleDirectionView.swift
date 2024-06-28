//
//  TriangleDirectionView.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/6/21.
//

import UIKit

@objc public enum TriangleDirection: UInt8 {
    case left
    case right
}

@objcMembers open class TriangleView: UIView {
    
    public var direction: TriangleDirection = .right
    
    public var color: UIColor = .systemBlue
    
    @MainActor open func setDirection( direction: TriangleDirection,color: UIColor) {
        self.direction = direction
        self.color = color
        setNeedsDisplay()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear // 确保背景透明
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear // 确保背景透明
    }

    open override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let path = UIBezierPath()
        
        switch direction {
        case .left:
            path.move(to: CGPoint(x: 0, y: rect.height / 2))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        case .right:
            path.move(to: CGPoint(x: rect.width, y: rect.height / 2))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        }
        
        path.close()
        
        context.setFillColor(self.color.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
    }
}


