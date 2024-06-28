//
//  MessageBubbleWithArrow.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/9.
//

import UIKit

@objc public enum BubbleTowards: UInt {
    case right
    case left
}

@objcMembers open class MessageBubbleWithArrow: UIView {
    
    public var towards = BubbleTowards.right {
        didSet {
            DispatchQueue.main.async {
                let receiveColor = Theme.style == .dark ? UIColor.theme.primaryColor2:UIColor.theme.primaryColor95
                let sendColor = Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5
                self.bubbleLayer.fillColor = (self.towards == .left ? receiveColor:sendColor).cgColor
                self.bubbleLayer.strokeColor = (self.towards == .left ? receiveColor:sendColor).cgColor
            }
        }
    }
    
    private let bubbleLayer = CAShapeLayer()

    internal override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    @objc required public init(frame: CGRect, forward: BubbleTowards) {
        self.towards = forward
        super.init(frame: frame)
        self.bubbleLayer.lineWidth = 1
        self.bubbleLayer.lineJoin = .round
        self.bubbleLayer.lineCap = .round
        self.layer.insertSublayer(bubbleLayer, at: 0)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // 重新设置气泡路径
        let bubblePath = UIBezierPath()
        bubblePath.usesEvenOddFillRule = true
        bubblePath.lineWidth = 1
        // 气泡的圆角半径
        let cornerRadius: CGFloat = 4
        
        // 气泡的尖角宽度和高度
        let arrowWidth: CGFloat = 6.0
        let arrowHeight: CGFloat = 6.0
        
        let bounds = self.bounds
        let width = CGFloat(ceilf(Float(bounds.width)))
        let height = CGFloat(ceilf(Float(bounds.height)))
        
        if self.towards == .left {
            
            bubblePath.move(to: CGPoint(x: width - cornerRadius, y: 0))
            bubblePath.addLine(to: CGPoint(x: cornerRadius, y: 0))
            bubblePath.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(3 * Double.pi / 2), endAngle: CGFloat(Double.pi), clockwise: false)
            bubblePath.addLine(to: CGPoint(x: 0, y: height - cornerRadius - arrowHeight - 8))
            bubblePath.addLine(to: CGPoint(x: -arrowWidth, y: height - cornerRadius - 8))
            bubblePath.addLine(to: CGPoint(x: 0, y: height - cornerRadius + arrowHeight - 8))
            bubblePath.addLine(to: CGPoint(x: 0, y: height - cornerRadius))
            bubblePath.addArc(withCenter: CGPoint(x: cornerRadius, y: height - cornerRadius), radius: cornerRadius, startAngle: CGFloat(Double.pi), endAngle: CGFloat(Double.pi / 2), clockwise: false)
            bubblePath.addLine(to: CGPoint(x: width - cornerRadius, y: height))
            bubblePath.addArc(withCenter: CGPoint(x: width - cornerRadius, y: height - cornerRadius), radius: cornerRadius, startAngle: CGFloat(Double.pi / 2), endAngle: CGFloat(0), clockwise: false)
            bubblePath.addLine(to: CGPoint(x: width, y: cornerRadius))
            bubblePath.addArc(withCenter: CGPoint(x: width - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(3 * Double.pi / 2), clockwise: false)
        } else {
            bubblePath.move(to: CGPoint(x: cornerRadius, y: 0))
            bubblePath.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
            bubblePath.addArc(withCenter: CGPoint(x: width - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(3 * Double.pi / 2), endAngle: 0, clockwise: true)
            bubblePath.addLine(to: CGPoint(x: width, y: height - cornerRadius - arrowHeight-8))
            bubblePath.addLine(to: CGPoint(x: width + arrowWidth, y: height - cornerRadius-8))
            bubblePath.addLine(to: CGPoint(x: width, y: height - cornerRadius + arrowHeight-8))
            bubblePath.addLine(to: CGPoint(x: width, y: height - cornerRadius))
            bubblePath.addArc(withCenter: CGPoint(x: width - cornerRadius, y: height - cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: CGFloat(Double.pi / 2), clockwise: true)
            bubblePath.addLine(to: CGPoint(x: cornerRadius, y: height))
            bubblePath.addArc(withCenter: CGPoint(x: cornerRadius, y: height - cornerRadius), radius: cornerRadius, startAngle: CGFloat(Double.pi / 2), endAngle: CGFloat(Double.pi), clockwise: true)
            bubblePath.addLine(to: CGPoint(x: 0, y: cornerRadius))
            bubblePath.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(Double.pi), endAngle: CGFloat(3 * Double.pi / 2), clockwise: true)
        }
        
        bubblePath.close()
        self.bubbleLayer.path = bubblePath.cgPath
    }
}
