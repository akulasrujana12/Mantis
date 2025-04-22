//
//  CropAuxiliaryIndicatorView.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright 2018 Echo. All rights reserved.
//

import UIKit

final class CropAuxiliaryIndicatorView: UIView, CropAuxiliaryIndicatorViewProtocol {
    private var borderNormalColor = UIColor.white
    private var borderHintColor = UIColor.white
    private var cornerHandleColor = UIColor.white
    private var edgeLineHandleColor = UIColor.white
    private let cornerHandleLength = CGFloat(20.0)
    private let edgeLineHandleLength = CGFloat(30.0)
    private let handleThickness = CGFloat(3.0)
    private let borderThickness = CGFloat(1.0)
    private let hintLineThickness = CGFloat(2.0)

    private var hintLine = UIView()
    private var tappedEdge: CropViewAuxiliaryIndicatorHandleType = .none
    private var gridMainColor = UIColor.white
    private var gridSecondaryColor = UIColor.lightGray
    private var disableCropBoxDeformation = false
    private var style: CropAuxiliaryIndicatorStyleType = .normal
    
    var cropBoxHotAreaUnit: CGFloat = 42
    
    var gridHidden = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var showFaceGuide = true {
        didSet {
            setNeedsDisplay()
        }
    }

    var gridLineNumberType: GridLineNumberType = .crop
    
    private var borderLine: UIView = UIView()
    private var cornerHandles: [UIView] = []
    private var edgeLineHandles: [UIView] = []
    
    var accessibilityHelperViews: [UIView] = []
    
    override var frame: CGRect {
        didSet {
            if !cornerHandles.isEmpty {
                layoutLines()
                handleIndicatorHandleTouched(with: tappedEdge)
            }
        }
    }
    
    init(frame: CGRect, config: CropAuxiliaryIndicatorConfig = CropAuxiliaryIndicatorConfig()) {
        super.init(frame: frame)
        clipsToBounds = false
        backgroundColor = .clear
        
        cropBoxHotAreaUnit = config.cropBoxHotAreaUnit
        disableCropBoxDeformation = config.disableCropBoxDeformation
        style = config.style
        
        borderNormalColor = config.borderNormalColor
        borderHintColor = config.borderHintColor
        cornerHandleColor = config.cornerHandleColor
        edgeLineHandleColor = config.edgeLineHandleColor
        gridMainColor = config.gridMainColor
        gridSecondaryColor = config.gridSecondaryColor
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
    }
    
    private func createNewLine(withNormalColor normalColor: UIColor = .white) -> UIView {
        let view = UIView()
        view.frame = .zero
        
        if style == .normal {
            view.backgroundColor = normalColor
        } else {
            view.backgroundColor = .clear
        }
        
        addSubview(view)
        
        return view
    }
    
    private func setup() {
        borderLine = createNewLine()
        borderLine.layer.backgroundColor = UIColor.clear.cgColor
        borderLine.layer.borderWidth = borderThickness
        
        if style == .normal {
            borderLine.layer.borderColor = borderNormalColor.cgColor
            hintLine.backgroundColor = borderHintColor
        } else {
            borderLine.layer.borderColor = UIColor.clear.cgColor
            hintLine.backgroundColor = .clear
        }
        
        for _ in 0..<8 {
            cornerHandles.append(createNewLine(withNormalColor: cornerHandleColor))
        }
        
        for _ in 0..<4 {
            edgeLineHandles.append(createNewLine(withNormalColor: edgeLineHandleColor))
        }
        
        setupAccessibilityHelperViews()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if !cornerHandles.isEmpty {
            layoutLines()
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var result = false
        
        accessibilityHelperViews.forEach {
            let convertedPoint = $0.convert(point, from: self)
            result = result || $0.point(inside: convertedPoint, with: event)
        }
        
        return result
    }
    
    override func draw(_ rect: CGRect) {
        guard showFaceGuide, let context = UIGraphicsGetCurrentContext() else { return }

        let w = rect.width
        let h = rect.height
        let centerX = w / 2.0

        // === 1. Simple oval silhouette from top-of-head to chin ===
        let path = UIBezierPath()

        let topY = h * 0.28
        let bottomY = h * 0.75
        let ovalHeight = bottomY - topY
        let ovalWidth = ovalHeight * 0.75
        let originX = (w - ovalWidth) / 2

        let ovalRect = CGRect(x: originX, y: topY, width: ovalWidth, height: ovalHeight)
        path.append(UIBezierPath(ovalIn: ovalRect))

        context.setLineWidth(2)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.9).cgColor)
        context.setLineDash(phase: 0, lengths: [4, 4])
        context.addPath(path.cgPath)
        context.strokePath()

        // === 2. Horizontal dotted lines ===
        func drawDottedLine(yRatio: CGFloat, label: String) {
            let y = h * yRatio
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: 0, y: y))
            linePath.addLine(to: CGPoint(x: w, y: y))
            context.setLineDash(phase: 0, lengths: [6, 4])
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(1.5)
            context.addPath(linePath.cgPath)
            context.strokePath()

            // Label
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white
            ]
            let labelSize = label.size(withAttributes: attributes)
            label.draw(at: CGPoint(x: 12, y: y - labelSize.height - 2), withAttributes: attributes)
        }

        drawDottedLine(yRatio: 0.05, label: "Top of Head")
        drawDottedLine(yRatio: 0.35, label: "Eyes")
        drawDottedLine(yRatio: 0.75, label: "Chin")

        // === 3. Vertical center line ===
        let centerLine = UIBezierPath()
        centerLine.move(to: CGPoint(x: centerX, y: 0))
        centerLine.addLine(to: CGPoint(x: centerX, y: h))
        context.setLineDash(phase: 0, lengths: [4, 4])
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
        context.addPath(centerLine.cgPath)
        context.strokePath()

        // === 4. Footer Label ===
        let footer = "51mmx51mm"
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        let footerSize = footer.size(withAttributes: attr)
        footer.draw(at: CGPoint(x: (w - footerSize.width) / 2, y: h - footerSize.height - 8), withAttributes: attr)
    }
    
    private func layoutLines() {
        guard bounds.isEmpty == false else {
            return
        }
        
        layoutOuterLines()
        
        guard !disableCropBoxDeformation else {
            return
        }
        
        layoutCornerHandles()
        layoutEdgeLineHandles()
        layoutAccessibilityHelperViews()
    }
        
    private func layoutOuterLines() {
        borderLine.frame = CGRect(x: -borderThickness,
                                  y: -borderThickness,
                                  width: bounds.width + 2 * borderThickness,
                                  height: bounds.height + 2 * borderThickness)
        borderLine.layer.backgroundColor = UIColor.clear.cgColor
        borderLine.layer.borderWidth = borderThickness
        if style == .normal {
            borderLine.layer.borderColor = borderNormalColor.cgColor
        } else {
            borderLine.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    private func layoutCornerHandles() {
        let topLeftHorizontalLayerFrame = CGRect(x: -handleThickness, y: -handleThickness, width: cornerHandleLength, height: handleThickness)
        let topLeftVerticalLayerFrame = CGRect(x: -handleThickness, y: -handleThickness, width: handleThickness, height: cornerHandleLength)
        
        let horizontalDistanceForHCorner = bounds.width + 2 * handleThickness - cornerHandleLength
        let verticalDistanceForHCorner = bounds.height + handleThickness
        let horizontalDistanceForVCorner = bounds.width + handleThickness
        let verticalDistanceForVCorner = bounds.height + 2 * handleThickness - cornerHandleLength
        
        for (index, line) in cornerHandles.enumerated() {
            guard let lineType = CropAuxiliaryIndicatorView.CornerHandleType(rawValue: index) else {
                continue
            }
            switch lineType {
            case .topLeftHorizontal:
                line.frame = topLeftHorizontalLayerFrame
            case .topLeftVertical:
                line.frame = topLeftVerticalLayerFrame
            case .topRightHorizontal:
                line.frame = topLeftHorizontalLayerFrame.offsetBy(dx: horizontalDistanceForHCorner, dy: 0)
            case .topRightVertical:
                line.frame = topLeftVerticalLayerFrame.offsetBy(dx: horizontalDistanceForVCorner, dy: 0)
            case .bottomRightHorizontal:
                line.frame = topLeftHorizontalLayerFrame.offsetBy(dx: horizontalDistanceForHCorner, dy: verticalDistanceForHCorner)
            case .bottomRightVertical:
                line.frame = topLeftVerticalLayerFrame.offsetBy(dx: horizontalDistanceForVCorner, dy: verticalDistanceForVCorner)
            case .bottomLeftHorizontal:
                line.frame = topLeftHorizontalLayerFrame.offsetBy(dx: 0, dy: verticalDistanceForHCorner)
            case .bottomLeftVertical:
                line.frame = topLeftVerticalLayerFrame.offsetBy(dx: 0, dy: verticalDistanceForVCorner)
            }
        }
    }
    
    private func layoutEdgeLineHandles() {
        for (index, line) in edgeLineHandles.enumerated() {
            guard let lineType = CropAuxiliaryIndicatorView.EdgeLineHandleType(rawValue: index) else {
                continue
            }
            
            switch lineType {
            case .top:
                line.frame = CGRect(x: bounds.width / 2 - edgeLineHandleLength / 2,
                                    y: -handleThickness,
                                    width: edgeLineHandleLength,
                                    height: handleThickness)
            case .right:
                line.frame = CGRect(x: bounds.width,
                                    y: bounds.height / 2 - edgeLineHandleLength / 2,
                                    width: handleThickness,
                                    height: edgeLineHandleLength)
            case .bottom:
                line.frame = CGRect(x: bounds.width / 2 - edgeLineHandleLength / 2,
                                    y: bounds.height,
                                    width: edgeLineHandleLength,
                                    height: handleThickness)
            case .left:
                line.frame = CGRect(x: -handleThickness,
                                    y: bounds.height / 2 - edgeLineHandleLength / 2,
                                    width: handleThickness,
                                    height: edgeLineHandleLength)
            }
        }
    }
            
    func handleIndicatorHandleTouched(with tappedEdge: CropViewAuxiliaryIndicatorHandleType) {
        guard tappedEdge != .none  else {
            return
        }
        
        self.tappedEdge = tappedEdge
        
        gridHidden = false
        gridLineNumberType = .crop
        
        func handleHintLine() {
            guard [.top, .bottom, .left, .right].contains(tappedEdge) else {
                return
            }
            
            if hintLine.superview == nil {
                addSubview(hintLine)
            }
            
            switch tappedEdge {
            case .top:
                hintLine.frame = CGRect(x: borderLine.frame.minX,
                                        y: borderLine.frame.minY,
                                        width: borderLine.frame.width,
                                        height: hintLineThickness)
            case .bottom:
                hintLine.frame = CGRect(x: borderLine.frame.minX,
                                        y: borderLine.frame.maxY - hintLineThickness,
                                        width: borderLine.frame.width,
                                        height: hintLineThickness)
            case .left:
                hintLine.frame = CGRect(x: borderLine.frame.minX,
                                        y: borderLine.frame.minY,
                                        width: hintLineThickness,
                                        height: borderLine.frame.height)
            case .right:
                hintLine.frame = CGRect(x: borderLine.frame.maxX - hintLineThickness,
                                        y: borderLine.frame.minY,
                                        width: hintLineThickness,
                                        height: borderLine.frame.height)
            default:
                break
            }
        }
        
        handleHintLine()
    }
    
    func handleEdgeUntouched() {
        gridHidden = true
        hintLine.removeFromSuperview()
        tappedEdge = .none
    }
}

extension CropAuxiliaryIndicatorView {
    private enum CornerHandleType: Int {
        case topLeftVertical = 0
        case topLeftHorizontal
        case topRightVertical
        case topRightHorizontal
        case bottomRightVertical
        case bottomRightHorizontal
        case bottomLeftVertical
        case bottomLeftHorizontal
    }
    
    private enum EdgeLineHandleType: Int {
        case top = 0
        case right
        case bottom
        case left
    }
}
