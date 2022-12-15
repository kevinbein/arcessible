//
//  Environment.swift
//  mt-test-1
//
//  Created by Kevin Bein on 24.04.22.
//

struct ProjectSettings {
    static let appName = "A[R]ccess"
    static let authorName = "Kevin Bein"
    static let authorEmail = "mail@kevinbein.de"
    
    static let uiBackgroundOpacity = 0.2
    
    static let evaluationStartCountdown = 5 // 10
    static let evaluationStorageKey = "EvaluationStorage"
    
    static let initialWorkMode = MainUIView.WorkMode.evaluation
    static let initialModel = MainUIView.Model.mansion
    static let initialCorrection = MainUIView.Correction.none //bgGrayscale
    static let initialSimulation = MainUIView.Simulation.none
    static let initialEvaluationPreset = MainUIView.EvaluationPreset.game
    
    static let replayScene: ReplaySceneSetup.ReplayScene? = .motionRoomHome3
    
    static let globalShaders: [String] = [
        "combineModelAndBackground",
        "capturedImageColorspaceConverter"
    ]
    
    static let globalTextures: [String:String] = [:
        //"calibrationImage": "jpg",
        //"noise": "png"
    ]
}
 
