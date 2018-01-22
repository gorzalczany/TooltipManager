//MIT License
//
//Copyright (c) 2018 Michał Gorzałczany
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

import UIKit

class Tooltip {
    let innerView : UIView
    let pointingPoint: CGPoint
    let pointingView : UIView
    let tag : String
    
    init(pointingView:UIView, innerView:UIView, pointingPoint:CGPoint? = nil, tag : String = "NaN") {
        self.innerView = innerView
        self.pointingView = pointingView
        self.tag = tag
        if let point = pointingPoint {
            self.pointingPoint = point
        } else {
            self.pointingPoint = pointingView.center
        }
    }
}

protocol TooltipManagerDelegate: class {
    func tooltipManager(manager: TooltipManager, wantToShowTooltip tooltip: Tooltip)
}

final class TooltipManager: UIViewController {
    
    private var touchView: UIView!
    private var currentTooltip: UIView?
    private(set) var parentView: UIView!
    fileprivate var tooltips = [Tooltip]()
    var shouldGoNext = true
    weak var delegate : TooltipManagerDelegate?
    
    convenience init(fromView: UIView) {
        self.init()
        self.parentView = fromView
    }
    
    func showTooltips(fromViewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) {
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
        fromViewController?.present(self, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nextTooltip()
        configureView()

        let selector = #selector(tapped as () -> Void)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: selector)
        tap.cancelsTouchesInView = false
        touchView.addGestureRecognizer(tap)
    }
    
    @objc private func tapped() {
        currentTooltip?.removeFromSuperview()
        if let tooltip = tooltips.first {
            delegate?.tooltipManager(manager: self, wantToShowTooltip: tooltip)
        }
        nextTooltip()
    }
    
    func pause() {
        shouldGoNext = false
    }
    
    func resume() {
        shouldGoNext = true
        nextTooltip()
    }
    
    func addTooltip(_ tooltip: Tooltip){
        tooltips.append(tooltip)
    }
    
    func addTooltip(message : String, forView: UIView) {
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        let tooltip = Tooltip(pointingView: forView, innerView: label)
        tooltips.append(tooltip)
    }
    
    private func nextTooltip() {
        guard shouldGoNext else {return}
        if let tooltip = tooltips.first {
            drawTooltip(tooltip)
            tooltips.removeFirst()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func drawTooltip(_ tooltip: Tooltip) {
        
        let bubbleView = TooltipView()
        currentTooltip = bubbleView
        
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        tooltip.innerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(bubbleView)
        bubbleView.addSubview(tooltip.innerView)
        bubbleView.backgroundColor = UIColor.clear
        
        tooltip.innerView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8).isActive = true
        tooltip.innerView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8).isActive = true
        tooltip.innerView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8).isActive = true
        tooltip.innerView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8).isActive = true
        
        //let rect = view.convert(tooltip.pointingView.frame, from: tooltip.pointingView.superview)
        let point = view.convert(tooltip.pointingPoint, from: tooltip.pointingView.superview)
        
        let quater = Double(self.view.frame.size.width/4)
        var arrow : TooltipArrowDirection!
        
        let above : Bool = point.y >= view.frame.size.height/2
        
        switch Double(point.x) {
        case 0.0 ... quater:
            arrow = !above ? .TopLeft : .BottomLeft
        case quater ... 3*quater:
            arrow = !above ? .TopCenter : .BottomCenter
        case 3*quater ... 4*quater:
            arrow = !above ? .TopRight : .BottomRight
        default:
            break
        }
        
        if above {
            bubbleView.bottomAnchor.constraint(equalTo: view.topAnchor, constant: point.y-3).isActive = true
        } else {
            bubbleView.topAnchor.constraint(equalTo: view.topAnchor, constant: point.y+3).isActive = true
        }
        
        switch arrow! {
        case .TopLeft, .BottomLeft:
            bubbleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: point.x-3).isActive = true
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -8).isActive = true
        case .TopRight, .BottomRight:
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: view.leadingAnchor, constant: point.x+3).isActive = true
        case .TopCenter, .BottomCenter, .None:
            bubbleView.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: point.x).isActive = true
        }
        
        bubbleView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.5).isActive = true
        bubbleView.arrowDirection = arrow
    }
    
    private func configureView() {
        view.backgroundColor = UIColor.clear
        
        touchView = UIView()
        
        touchView.translatesAutoresizingMaskIntoConstraints = false
        
        // backgroundView View
        view.addSubview(touchView)
        view.addConstraints([
            NSLayoutConstraint(item: touchView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: touchView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: touchView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: touchView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0),
            ])
    }
}
