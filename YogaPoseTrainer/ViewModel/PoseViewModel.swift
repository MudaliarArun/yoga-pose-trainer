//
//  PoseViewModel.swift
//  YogaPoseTrainer
//
//  Created by Arun Mudaliar on 01/06/25.
//

import SwiftUI
import Combine

class PoseViewModel: ObservableObject {
    @Published var poseName: String = "No Pose Detected"
    @Published var headPosition: CGPoint = CGPoint(x: 0.5, y: 0.1) // default top-center
    
    private var cancellable: AnyCancellable?
    
    func attach(cameraVC: CameraViewController) {
        cancellable = cameraVC.posePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] (pose: String, pos: CGPoint) in
                self?.poseName = pose
                self?.headPosition = pos
            }
    }
}
