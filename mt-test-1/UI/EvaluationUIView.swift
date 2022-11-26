//
//  EvaluationUIView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 19.11.22.
//

import Foundation
import UIKit
import SwiftUI

struct EvaluationUIView: View {
    //static let shared = EvaluationUIView()
    
    init() {
        //NotificationCenter.default.addObserver(self, selector: #selector(handleButtonStartEvaluationPressed(_:)), name: Notification.Name("ButtonStartEvaluationPressed"), object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(handlePickerEvaluationPresetChanged(_:)), name: Notification.Name("PickerEvaluationPresetChanged"), object: nil)
    }
    
    @State var evaluationMethod: MainUIView.EvaluationPreset?
    @State var countdownIsActive = false
    @State var countdown = 10
    
    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let safeAreaHeightTop = UIApplication.shared.keyWindow?.safeAreaInsets.top
        let safeAreaHeightBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom
        
        Group {
            VStack {
                if countdownIsActive {
                    Text("Start in \(countdown)").font(.largeTitle)
                } else {
                    EmptyView()
                }
            }
            .padding(50)
            .foregroundColor(.white)
            .background(.black.opacity(ProjectSettings.uiBackgroundOpacity))
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PickerEvaluationPresetChanged"))) { object in
            countdownIsActive = false
            countdown = 10
            // let activeEvaluationPreset = MainUIView.EvaluationPreset(rawValue: value)
            evaluationMethod
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ButtonStartEvaluationPressed"))) { object in
            countdownIsActive = true
        }
        .onReceive(countdownTimer) { _ in
            if countdownIsActive {
                countdown -= 1
                if countdown <= 0 {
                    countdownIsActive = false
                    countdown = 10
                }
            }
        }
    }
}

struct EvaluationUIView_Previews: PreviewProvider {
    static var previews: some View {
        EvaluationUIView()
            .previewDisplayName("EvaluationUIView")
            .previewInterfaceOrientation(.portrait)
            .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
    }
}
