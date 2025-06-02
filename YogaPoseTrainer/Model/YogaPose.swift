//
//  YogaPose.swift
//  YogaPoseTrainer
//
//  Created by Arun Mudaliar on 01/06/25.
//

import Vision

struct YogaPose {
    let name: String
    let checks: [( [VNHumanBodyPoseObservation.JointName: CGPoint] ) -> Bool]
    
    func matches(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> Bool {
        for check in checks {
            if !check(joints) { return false }
        }
        return true
    }

    
}
