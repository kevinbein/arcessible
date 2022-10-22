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
    
    static let initialModel = MainUIView.Model.mansion
    static let initialCorrection = MainUIView.Correction.edgeEnhancement
    static let initialSimulation = MainUIView.Simulation.none
    
    static let globalShaders: [String] = [
        "combineModelAndBackground",
        "capturedImageColorspaceConverter"
    ]
    
    static let globalTextures: [String:String] = [
        "calibrationImage": "jpg",
        "noise": "png"
    ]
}
