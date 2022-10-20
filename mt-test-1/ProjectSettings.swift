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
    
    static let globalShaders: [String] = [
        "combineModelAndBackground"
    ]
    
    static let globalTextures: [String:String] = [
        "calibrationImage": "jpg",
        "noise": "png"
    ]
}
