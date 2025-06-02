//
//  GifView.swift
//  YogaPoseTrainer
//
//  Created by Arun Mudaliar on 31/05/25.
//
import SwiftUI
import UIKit

struct GIFView: UIViewRepresentable {
    let name: String
    
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        
        let imageView = UIImageView()
        imageView.image = UIImage.gif(name: name)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
        
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}
