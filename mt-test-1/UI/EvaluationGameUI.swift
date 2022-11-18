//
//  EvaluationGameUI.swift
//  mt-test-1
//
//  Created by Kevin Bein on 18.11.22.
//

import SwiftUI
import Combine
import RealityKit

struct EvaluationGameUIView: View {
    
    let safeAreaHeightTop = UIApplication.shared.keyWindow?.safeAreaInsets.top
    let safeAreaHeightBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom
    
    @State private var startCountdown: Int = 10
    @State private var timerCountdown: Int = 30
    
    var body: some View {
        Group {
            VStack {
                if startCountdown > 0 {
                    Text("Start in \(startCountdown)").font(.largeTitle)
                } else {
                    EmptyView()
                }
            }
            .padding(50)
            .foregroundColor(.white)
            .background(.black.opacity(ProjectSettings.uiBackgroundOpacity))

            // Footer - Bottom margin
            Rectangle()
                .foregroundColor(.black.opacity(0))
                .frame(height: safeAreaHeightBottom)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct EvaluationUIView_Previews: PreviewProvider {
    static var previews: some View {
        EvaluationGameUIView()
            .previewDisplayName("Evaluation View")
            .previewInterfaceOrientation(.portrait)
            .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
    }
}
