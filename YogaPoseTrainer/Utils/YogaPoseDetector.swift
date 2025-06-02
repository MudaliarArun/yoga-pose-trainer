//
//  YogaPoseDetector.swift
//  YogaPoseTrainer
//
//  Created by Arun Mudaliar on 01/06/25.
//

import Vision

class YogaPoseDetector {
    static let shared = YogaPoseDetector()
    
    private let poses: [YogaPose]
    
    private init() {
        poses = YogaPoseDetector.createPoses()
    }
    
    func detectYogaPose(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> String? {
        for pose in poses {
            if pose.matches(joints: joints) {
                return pose.name
            }
        }
        return nil
    }
    
    private static func angleBetweenPoints(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
        let v1 = CGVector(dx: p1.x - p2.x, dy: p1.y - p2.y)
        let v2 = CGVector(dx: p3.x - p2.x, dy: p3.y - p2.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let mag1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy)
        let mag2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
        guard mag1 > 0 && mag2 > 0 else { return 0 }
        let angle = acos(dot / (mag1 * mag2))
        return angle * 180 / .pi
    }
    
    private static func verticalDistance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return abs(p1.y - p2.y)
    }
    
    private static func horizontalDistance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return abs(p1.x - p2.x)
    }
    
    private static func createPoses() -> [YogaPose] {
        return [
            // Stronger Warrior II check - both legs and arms, angles stricter
            YogaPose(
                name: "Warrior II",
                checks: [
                    { joints in
                        // Left knee ~90°, Right leg straight (knee angle > 160)
                        guard let leftHip = joints[.leftHip],
                              let leftKnee = joints[.leftKnee],
                              let leftAnkle = joints[.leftAnkle],
                              let rightHip = joints[.rightHip],
                              let rightKnee = joints[.rightKnee],
                              let rightAnkle = joints[.rightAnkle] else { return false }
                        let leftKneeAngle = angleBetweenPoints(leftHip, leftKnee, leftAnkle)
                        let rightKneeAngle = angleBetweenPoints(rightHip, rightKnee, rightAnkle)
                        let leftKneeOK = abs(leftKneeAngle - 90) < 15
                        let rightKneeOK = rightKneeAngle > 160
                        return leftKneeOK && rightKneeOK
                    },
                    { joints in
                        // Left arm straight ~180°
                        guard let leftShoulder = joints[.leftShoulder],
                              let leftElbow = joints[.leftElbow],
                              let leftWrist = joints[.leftWrist] else { return false }
                        let leftArmAngle = angleBetweenPoints(leftShoulder, leftElbow, leftWrist)
                        return abs(leftArmAngle - 180) < 20
                    },
                    { joints in
                        // Right arm straight ~180°
                        guard let rightShoulder = joints[.rightShoulder],
                              let rightElbow = joints[.rightElbow],
                              let rightWrist = joints[.rightWrist] else { return false }
                        let rightArmAngle = angleBetweenPoints(rightShoulder, rightElbow, rightWrist)
                        return abs(rightArmAngle - 180) < 20
                    }
                ]
            ),
            
            // Tree Pose - lifted foot near opposite inner thigh & leg bent enough
            YogaPose(
                name: "Tree Pose",
                checks: [
                    { joints in
                        // Right ankle y > right knee y (lifted)
                        guard let rightAnkle = joints[.rightAnkle],
                              let rightKnee = joints[.rightKnee],
                              let rightHip = joints[.rightHip],
                              let leftHip = joints[.leftHip] else { return false }
                        // Ankle higher than knee (lifted leg)
                        let ankleAboveKnee = rightAnkle.y < rightKnee.y
                        // Distance from right ankle to left inner thigh (leftHip) should be small (foot near inner thigh)
                        let dist = sqrt(pow(rightAnkle.x - leftHip.x, 2) + pow(rightAnkle.y - leftHip.y, 2))
                        return ankleAboveKnee && dist < 0.15
                    },
                    { joints in
                        // Standing leg fairly straight (left leg)
                        guard let leftHip = joints[.leftHip],
                              let leftKnee = joints[.leftKnee],
                              let leftAnkle = joints[.leftAnkle] else { return false }
                        let kneeAngle = angleBetweenPoints(leftHip, leftKnee, leftAnkle)
                        return kneeAngle > 160
                    }
                ]
            ),
            
            // Plank - body roughly straight line (shoulder, hip, ankle almost aligned vertically)
            YogaPose(
                name: "Plank Pose",
                checks: [
                    { joints in
                        guard let leftShoulder = joints[.leftShoulder],
                              let leftHip = joints[.leftHip],
                              let leftAnkle = joints[.leftAnkle] else { return false }
                        let shoulderHipYDiff = verticalDistance(leftShoulder, leftHip)
                        let hipAnkleYDiff = verticalDistance(leftHip, leftAnkle)
                        // Distances should be small, meaning points are aligned horizontally (x values similar)
                        let shoulderHipXDiff = abs(leftShoulder.x - leftHip.x)
                        let hipAnkleXDiff = abs(leftHip.x - leftAnkle.x)
                        return shoulderHipXDiff < 0.1 && hipAnkleXDiff < 0.1 &&
                               shoulderHipYDiff > 0.2 && hipAnkleYDiff > 0.2
                    }
                ]
            ),
            
            // Downward Dog - hips high, legs and arms extended, forming an inverted V
            YogaPose(
                name: "Downward Dog",
                checks: [
                    { joints in
                        guard let leftHip = joints[.leftHip],
                              let leftWrist = joints[.leftWrist],
                              let leftAnkle = joints[.leftAnkle],
                              let rightWrist = joints[.rightWrist],
                              let rightAnkle = joints[.rightAnkle] else { return false }
                        
                        // Hips higher than wrists & ankles (y smaller since coordinate flipped)
                        let hipsHigherThanWrists = leftHip.y < leftWrist.y && leftHip.y < rightWrist.y
                        let hipsHigherThanAnkles = leftHip.y < leftAnkle.y && leftHip.y < rightAnkle.y
                        
                        // Wrists apart, ankles apart (wide stance)
                        let wristDistance = abs(leftWrist.x - rightWrist.x)
                        let ankleDistance = abs(leftAnkle.x - rightAnkle.x)
                        
                        return hipsHigherThanWrists && hipsHigherThanAnkles && wristDistance > 0.25 && ankleDistance > 0.25
                    }
                ]
            )
        ]
    }
}
