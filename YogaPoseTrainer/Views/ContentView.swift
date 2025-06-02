//
//  ContentView.swift
//  YogaPoseTrainer
//
//  Created by Arun Mudaliar on 31/05/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel = PoseViewModel()
    @State private var isCameraReady = false
    
    var body: some View {
        ZStack {
            GIFView(name: "meditation").frame(width: 120, height: 120)
            
            CameraView(viewModel: viewModel, isCameraReady: $isCameraReady)
                .edgesIgnoringSafeArea(.all)
            // Overlay the pose name text at head position
            GeometryReader { geo in
                Text(viewModel.poseName)
                    .font(.headline)
                    .foregroundColor(.yellow)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .position(x: viewModel.headPosition.x * geo.size.width,
                              y: (1 - viewModel.headPosition.y) * geo.size.height - 40) // adjust Y to be above head
            }
            .allowsHitTesting(false)
            
            if !isCameraReady {
                GIFView(name: "meditation")
                    .frame(width: 120, height: 120)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
            }
        }
    }
    
}

struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: PoseViewModel
    @Binding var isCameraReady: Bool
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraVC = CameraViewController()
        cameraVC.onCameraReady = {
            isCameraReady = true
        }
        viewModel.attach(cameraVC: cameraVC)  // Attach subscription here
        return cameraVC
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
#Preview {
    ContentView()
}
