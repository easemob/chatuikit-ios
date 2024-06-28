//
//  UIViewFunctionBuilder.swift
//  Pods
//
//  Created by 朱继超 on 2021/4/13.
//

import UIKit

@resultBuilder
public struct UIViewFunctionBuilder {
    public static func buildBlock(_ views: UIView...) -> [UIView] {
        var subviews = [UIView]()
        for view in views {
            subviews.append(view)
        }
        return subviews
    }
}

extension UIView {
    
    public convenience init(@UIViewFunctionBuilder _ builder: () -> [UIView]) {
        self.init()
        let views = builder()
        if let view = views.first {
            if view.frame != .zero {
                self.frame = view.frame
            } else {
                assert(false, "views stack top must has frame")
            }
        }
        self.addSubViews(views)
    }
    
}

extension UIView {
    
    func getTopMostVisibleScrollView() -> UIScrollView? {
        return getAllScrollViews(in: self.window ?? self).filter { $0.isVisibleOnScreen() }.last
    }
    
    private func getAllScrollViews(in view: UIView) -> [UIScrollView] {
        var scrollViews = [UIScrollView]()
        
        if let scrollView = view as? UIScrollView {
            scrollViews.append(scrollView)
        }
        
        for subview in view.subviews {
            scrollViews.append(contentsOf: getAllScrollViews(in: subview))
        }
        
        return scrollViews
    }
}

extension UIScrollView {
    
    func isVisibleOnScreen() -> Bool {
        guard let superview = self.superview else { return false }
        
        let scrollViewFrame = self.convert(self.bounds, to: nil)
        let visibleFrame = UIScreen.main.bounds
        
        return visibleFrame.intersects(scrollViewFrame)
    }
    
    var endScroll: Bool {
        return !self.isDragging && !self.isDecelerating
    }
}
