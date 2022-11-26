//
//  EvaluationGameUI.swift
//  mt-test-1
//
//  Created by Kevin Bein on 18.11.22.
//

import SwiftUI
import Combine
import RealityKit

/*struct EvaluationUIViewController: UIViewControllerRepresentable {
    
    // @Binding var frame: ARFrame?
    
    func makeUIView(context: Context) -> EvaluationUIView {
        let evaluationUIView = EvaluationUIView.shared
        context.coordinator.view = evaluationUIView
        // evaluationUIView.session.delegate = context.coordinator
        return evaluationUIView
    }
    
    func updateUIView(_ uiView: EvaluationUIView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        // Coordinator(frame: _frame)
        Coordinator()
    }
    
    class Coordinator: NSObject {
        // @Binding var frame: ARFrame?
        
        var view: EvaluationUIView?
        
        //init(frame: Binding<ARFrame?>) {
        override init() {
            super.init()
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleButtonStartEvaluationPressed(_:)), name: Notification.Name("ButtonStartEvaluationPressed"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handlePickerEvaluationPresetChanged(_:)), name: Notification.Name("PickerEvaluationPresetChanged"), object: nil)
        }
        
        var evaluationCount = 10
        var evaluationTimer: Timer?
        
        @objc func updateEvaluationCounter() {
            evaluationCount -= 1
            
            if (evaluationCount <= 0) {
                evaluationTimer?.invalidate()
            }
            Log.print("Updated evaluation counter: \(evaluationCount)")
        }
        
        @objc public func handleButtonStartEvaluationPressed(_ notification: Notification) {
            guard let view = self.view else { return }
            
            evaluationTimer?.invalidate()
            evaluationCount = 10 + 1
            evaluationTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateEvaluationCounter), userInfo: nil, repeats: true)
            
            Log.print("handleButtonStartEvaluationPressed")
        }
        
        @objc func handlePickerEvaluationPresetChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? String else { return }
            let activeEvaluationPreset = MainUIView.EvaluationPreset(rawValue: value)
            Log.print("handlePickerEvaluationPresetChanged", value)
            
            guard let view = self.view else { return }
            
            switch activeEvaluationPreset {
            case .spatialAwareness:
                Log.print("start evaluation of spatial awareness")
            default:
                break
            }
        }
    }
}
*/
