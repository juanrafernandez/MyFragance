//
//  CurvedHeaderShape.swift
//  PerfBeta
//
//  Created by ES00571759 on 14/4/25.
//


import SwiftUI

struct CurvedHeaderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Start top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // Line to top-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // Line to bottom-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // Add the curve to bottom-left
        // Control points determine the curve's shape. Adjust these!
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX / 2, y: rect.maxY + 40) // Control point below the middle-left
            // Experiment with the control point Y value (+40) to change the curve depth
            // You might need addCurve for a more S-like shape if desired
        )
        // Close the path
        path.closeSubpath()
        return path
    }
}
