import UIKit

/// A view that overlays a dotted human face guide for photo alignment in CropView.
class FaceGuideOverlayView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        
        // Set up dotted line style
        context.setLineWidth(2)
        context.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.6).cgColor)
        let dashPattern: [CGFloat] = [4, 4]
        context.setLineDash(phase: 0, lengths: dashPattern)

        // Example: Draw a simple stylized face outline (oval), eyes, nose, mouth
        let faceRect = CGRect(x: rect.midX - rect.width * 0.18, y: rect.midY - rect.height * 0.28, width: rect.width * 0.36, height: rect.height * 0.56)
        let facePath = UIBezierPath(ovalIn: faceRect)
        context.addPath(facePath.cgPath)

        // Eyes
        let eyeRadius = rect.width * 0.03
        let leftEyeCenter = CGPoint(x: rect.midX - rect.width * 0.07, y: rect.midY - rect.height * 0.09)
        let rightEyeCenter = CGPoint(x: rect.midX + rect.width * 0.07, y: rect.midY - rect.height * 0.09)
        context.addEllipse(in: CGRect(x: leftEyeCenter.x - eyeRadius, y: leftEyeCenter.y - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2))
        context.addEllipse(in: CGRect(x: rightEyeCenter.x - eyeRadius, y: rightEyeCenter.y - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2))

        // Nose (vertical line)
        context.move(to: CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.06))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.04))

        // Mouth (arc)
        let mouthRect = CGRect(x: rect.midX - rect.width * 0.06, y: rect.midY + rect.height * 0.09, width: rect.width * 0.12, height: rect.height * 0.04)
        context.addArc(center: CGPoint(x: mouthRect.midX, y: mouthRect.midY), radius: mouthRect.width / 2, startAngle: .pi * 0.1, endAngle: .pi * 0.9, clockwise: false)

        context.strokePath()
        context.restoreGState()
    }
}
