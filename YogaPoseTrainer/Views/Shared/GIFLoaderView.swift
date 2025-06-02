//
//  GIFLoaderView.swift
//  YogaPoseTrainer
//
//  Created by Arun Mudaliar on 31/05/25.
//
import SwiftUI

struct GIFLoaderView: View {
    let gifName: String
    let isLoading: Bool
    
    var body: some View {
        if isLoading {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                // Centered GIF loader
                GIFView(name: gifName)
                    .frame(width: 100, height: 100)
            }
            // Block all interactions below the loader
            .transition(.opacity)
            .zIndex(1)
        }
    }
}


