//
//  SplashView.swift
//  YogaPoseTrainer
//
//  Created by Arun Mudaliar on 01/06/25.
//
import SwiftUI

struct SplashView: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            ContentView()// Replace with your actual view
        } else {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                GIFView(name: "meditation")
                    .frame(width: 120, height: 120)
            }
            .onAppear {
                // Simulate loading time (e.g., permission, setup)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

