//
//  PoseDetectionViewController.swift
//  YogaPoseTrainer
//
//  Created by Arun Mudaliar on 01/06/25.
//
import UIKit
import AVFoundation
import Vision
import Combine

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onCameraReady: (() -> Void)?
    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    var posePublisher = PassthroughSubject<(String, CGPoint), Never>()
    private var skeletonLayer = CAShapeLayer()
    let jointConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.neck, .nose),
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        
        
        skeletonLayer.frame = view.bounds
        skeletonLayer.strokeColor = UIColor.systemGreen.cgColor
        skeletonLayer.lineWidth = 3
        skeletonLayer.fillColor = UIColor.clear.cgColor
        skeletonLayer.name = "SkeletonLayer"

        view.layer.addSublayer(skeletonLayer)
        
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("No front camera found")
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            print("Camera input error: \(error)")
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        // TODO Later
//        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
//        previewLayer.connection?.isVideoMirrored = true
        
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.onCameraReady?()
            }
        }
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        detectPose(pixelBuffer: pixelBuffer)
    }
    
    private func detectPose(pixelBuffer: CVPixelBuffer) {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
            guard let observations = request.results, let firstObservation = observations.first else { return }
            
            let points = try firstObservation.recognizedPoints(.all)
            let filteredPoints = points.filter { $0.value.confidence > 0.5 }
            
            var jointPositions = [VNHumanBodyPoseObservation.JointName: CGPoint]()
            for (jointName, point) in filteredPoints {
                jointPositions[jointName] = CGPoint(x: point.x, y: 1 - point.y) // flip y for SwiftUI coordinate space if needed
            }
            
            analyzePose(joints: jointPositions)
            
        } catch {
            print("Vision request error: \(error)")
        }
    }
    
    private func analyzePose(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        if let poseName = YogaPoseDetector.shared.detectYogaPose(joints: joints),
           let nosePoint = joints[.nose] {
            // Send pose name and nose position
            print("Detected pose: \(poseName), nose: \(nosePoint)")
            DispatchQueue.main.async {
                self.posePublisher.send((poseName, nosePoint))
                self.drawSkeleton(joints: joints)
            }
        } else {
            print("No matching pose detected")
            DispatchQueue.main.async {
                self.posePublisher.send(("No Pose Detected", CGPoint(x: 0.5, y: 0.1)))
                self.drawSkeleton(joints: joints)
            }
        }

    }
    
    func convertPoint(_ point: CGPoint, in view: UIView) -> CGPoint {
        return previewLayer.layerPointConverted(fromCaptureDevicePoint: point)
    }

    private func drawSkeleton(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        let path = UIBezierPath()
        let radius: CGFloat = 4.0

        for (jointA, jointB) in jointConnections {
            guard let pointA = joints[jointA], let pointB = joints[jointB] else { continue }

            let start = previewLayer.layerPointConverted(fromCaptureDevicePoint: pointA)
            let end = previewLayer.layerPointConverted(fromCaptureDevicePoint: pointB)

            path.move(to: start)
            path.addLine(to: end)
        }

        // Optional joint dots
        for (_, point) in joints {
            let converted = previewLayer.layerPointConverted(fromCaptureDevicePoint: point)
            path.move(to: converted)
            path.addArc(withCenter: converted, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        }

        DispatchQueue.main.async {
            self.skeletonLayer.path = path.cgPath
            self.skeletonLayer.strokeColor = UIColor.systemGreen.cgColor
            self.skeletonLayer.lineWidth = 2
            self.skeletonLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.4).cgColor
        }
    }
}
